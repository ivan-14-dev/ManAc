from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend

from .models import Equipment
from .serializers import EquipmentSerializer, EquipmentListSerializer


class CanManageEquipment:
    """Permission: Only admins can create/update/delete equipment"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        # Allow safe methods (GET, HEAD, OPTIONS) for all authenticated users
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        # Only admins can create equipment
        if view.action == 'create':
            return request.user.is_general_admin or request.user.is_department_admin
        # Only admins can update/delete
        return request.user.is_general_admin or request.user.is_department_admin
    
    def has_object_permission(self, request, view, obj):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        # General admin can do everything
        if request.user.is_general_admin:
            return True
        # Department admin can only manage equipment in their department
        if request.user.is_department_admin and obj.department == request.user.department:
            return True
        return False


class EquipmentViewSet(viewsets.ModelViewSet):
    queryset = Equipment.objects.all()
    permission_classes = [IsAuthenticated, CanManageEquipment]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['category', 'status', 'department']
    search_fields = ['name', 'serial_number', 'barcode']
    
    def get_serializer_class(self):
        if self.action == 'list':
            return EquipmentListSerializer
        return EquipmentSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return Equipment.objects.select_related('department', 'created_by').all()
        elif user.is_department_admin:
            return Equipment.objects.select_related('department', 'created_by').filter(department=user.department)
        else:
            return Equipment.objects.select_related('department', 'created_by').filter(status='available')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def available(self, request):
        queryset = self.get_queryset().filter(status='available')
        serializer = EquipmentListSerializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def history(self, request, pk=None):
        equipment = self.get_object()
        borrowings = equipment.borrowings.all()[:10]
        data = [{
            'id': b.id,
            'borrower_name': b.borrower_name,
            'status': b.status,
            'checkout_date': b.checkout_date,
            'return_date': b.actual_return_date
        } for b in borrowings]
        return Response(data)
    
    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        """Export equipment to CSV format - Admin only"""
        if not request.user.is_admin:
            return Response(
                {'error': 'Only admins can export equipment'},
                status=status.HTTP_403_FORBIDDEN
            )
        import csv
        from django.http import HttpResponse
        from django.utils import timezone
        
        equipment_list = self.get_queryset()
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="equipements_{timezone.now().strftime("%Y%m%d")}.csv"'
        
        writer = csv.writer(response)
        writer.writerow(['ID', 'Nom', 'Numéro série', 'Catégorie', 'Statut', 'Département', 'Quantité totale', 'Quantité disponible', 'Date achat', 'Prix'])
        
        for e in equipment_list:
            writer.writerow([
                e.id,
                e.name,
                e.serial_number,
                e.category,
                e.status,
                e.department.name if e.department else '',
                e.quantity,
                e.available_quantity,
                e.purchase_date.strftime('%Y-%m-%d') if e.purchase_date else '',
                str(e.price) if e.price else '',
            ])
        
        return response
    
    @action(detail=False, methods=['get'])
    def export_pdf(self, request):
        """Export equipment to PDF format - Admin only"""
        if not request.user.is_admin:
            return Response(
                {'error': 'Only admins can export equipment'},
                status=status.HTTP_403_FORBIDDEN
            )
        from fpdf import FPDF
        from django.http import HttpResponse
        from django.utils import timezone
        
        equipment_list = self.get_queryset()
        
        class PDF(FPDF):
            def header(self):
                self.set_font('helvetica', 'B', 15)
                self.cell(0, 10, 'Rapport des Equipements - ManAC', 0, True, 'C')
                self.ln(5)
            
            def footer(self):
                self.set_y(-15)
                self.set_font('helvetica', 'I', 8)
                self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')
        
        pdf = PDF()
        pdf.add_page()
        pdf.set_font('helvetica', 'B', 10)
        
        # Table header
        pdf.set_fill_color(200, 220, 255)
        headers = ['Nom', 'Serie', 'Categorie', 'Statut', 'Depart.', 'Total', 'Dispo']
        col_widths = [45, 35, 30, 25, 35, 15, 15]
        
        for i, header in enumerate(headers):
            pdf.cell(col_widths[i], 10, header, 1, 0, 'C', True)
        pdf.ln()
        
        # Table rows
        pdf.set_font('helvetica', '', 8)
        for e in equipment_list:
            pdf.cell(col_widths[0], 8, (e.name if e.name else '')[:20], 1)
            pdf.cell(col_widths[1], 8, (e.serial_number if e.serial_number else '')[:15], 1)
            pdf.cell(col_widths[2], 8, (e.category if e.category else '')[:12], 1)
            pdf.cell(col_widths[3], 8, (e.status if e.status else '')[:10], 1)
            pdf.cell(col_widths[4], 8, (e.department.name if e.department else '')[:15], 1)
            pdf.cell(col_widths[5], 8, str(e.quantity), 1, 0, 'C')
            pdf.cell(col_widths[6], 8, str(e.available_quantity), 1, 0, 'C')
            pdf.ln()
        
        # Summary
        pdf.ln(10)
        pdf.set_font('helvetica', 'B', 10)
        pdf.cell(0, 10, f'Total des equipements: {len(equipment_list)}', 0, True)
        pdf.cell(0, 10, f'Genere le: {timezone.now().strftime("%d/%m/%Y a %H:%M")}', 0, True)
        
        response = HttpResponse(pdf.output(dest='S').encode('latin-1'), content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="equipements_{timezone.now().strftime("%Y%m%d")}.pdf"'
        return response
