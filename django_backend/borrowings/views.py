from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone

from .models import Borrowing
from .serializers import (
    BorrowingSerializer, BorrowingCreateSerializer,
    BorrowingUpdateSerializer
)
from .emails import (
    send_borrowing_request_received_email,
    send_borrowing_approved_email,
    send_borrowing_rejected_email,
    send_borrowing_confirmation_email,
    send_borrowing_returned_email,
    send_borrower_overdue_reminder,
)


class CanManageBorrowings:
    """Permission: Regular users can create/view their own, admins can manage all"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if view.action == 'create':
            return True
        if view.action in ['list', 'retrieve']:
            return True
        return request.user.is_general_admin or request.user.is_department_admin

    def has_object_permission(self, request, view, obj):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        return request.user.is_general_admin or request.user.is_department_admin


@method_decorator(csrf_exempt, name='dispatch')
class BorrowingViewSet(viewsets.ModelViewSet):
    queryset = Borrowing.objects.all()
    serializer_class = BorrowingSerializer
    permission_classes = [IsAuthenticated, CanManageBorrowings]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['status', 'equipment', 'borrower']

    def get_serializer_class(self):
        if self.action == 'create':
            return BorrowingCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return BorrowingUpdateSerializer
        return BorrowingSerializer

    def get_queryset(self):
        user = self.request.user
        qs = Borrowing.objects.select_related(
            'equipment', 'equipment__department', 'borrower', 'approved_by'
        )

        if user.is_general_admin:
            borrowings = qs.all()
        elif user.is_department_admin:
            borrowings = qs.filter(equipment__department=user.department)
        else:
            borrowings = qs.filter(borrower=user)

        # Use a bulk DB update to mark overdue borrowings instead of iterating
        now = timezone.now()
        borrowings.filter(
            status='checked_out',
            expected_return_date__lt=now.date(),
        ).update(status='overdue', updated_at=now)

        return borrowings

    def perform_create(self, serializer):
        borrowing = serializer.save(
            borrower=self.request.user,
            borrower_name=f"{self.request.user.first_name} {self.request.user.last_name}".strip()
                          or self.request.user.username,
            borrower_email=self.request.user.email
        )
        send_borrowing_request_received_email(borrowing)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        borrowing = self.get_object()

        if request.user.is_department_admin:
            if borrowing.equipment.department != request.user.department:
                return Response(
                    {'error': 'You can only approve borrowings from your department'},
                    status=status.HTTP_403_FORBIDDEN
                )

        if borrowing.status != 'pending':
            return Response(
                {'error': 'Can only approve pending borrowings'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if borrowing.equipment.available_quantity < borrowing.quantity:
            return Response(
                {'error': 'Not enough equipment available'},
                status=status.HTTP_400_BAD_REQUEST
            )

        borrowing.status = 'approved'
        borrowing.approved_by = request.user
        borrowing.approval_date = timezone.now()
        borrowing.save()

        # Update equipment availability
        equipment = borrowing.equipment
        equipment.available_quantity -= borrowing.quantity
        if equipment.available_quantity == 0:
            equipment.status = 'checked_out'
        equipment.save()

        send_borrowing_approved_email(borrowing)

        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        borrowing = self.get_object()

        if request.user.is_department_admin:
            if borrowing.equipment.department != request.user.department:
                return Response(
                    {'error': 'You can only reject borrowings from your department'},
                    status=status.HTTP_403_FORBIDDEN
                )

        if borrowing.status != 'pending':
            return Response(
                {'error': 'Can only reject pending borrowings'},
                status=status.HTTP_400_BAD_REQUEST
            )

        borrowing.status = 'rejected'
        borrowing.approved_by = request.user
        borrowing.approval_date = timezone.now()
        borrowing.notes = request.data.get('notes', '') or request.data.get('rejection_reason', '')
        borrowing.save()

        send_borrowing_rejected_email(borrowing)

        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def checkout(self, request, pk=None):
        borrowing = self.get_object()

        if request.user.is_department_admin:
            if borrowing.equipment.department != request.user.department:
                return Response(
                    {'error': 'You can only checkout borrowings from your department'},
                    status=status.HTTP_403_FORBIDDEN
                )

        if borrowing.status != 'approved':
            return Response(
                {'error': 'Can only checkout approved borrowings'},
                status=status.HTTP_400_BAD_REQUEST
            )

        borrowing.status = 'checked_out'
        borrowing.checkout_date = timezone.now()
        borrowing.save()

        if not borrowing.checkout_email_sent:
            if send_borrowing_confirmation_email(borrowing):
                borrowing.checkout_email_sent = True
                borrowing.save(update_fields=['checkout_email_sent'])

        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def return_equipment(self, request, pk=None):
        borrowing = self.get_object()

        if request.user.is_department_admin:
            if borrowing.equipment.department != request.user.department:
                return Response(
                    {'error': 'You can only process returns from your department'},
                    status=status.HTTP_403_FORBIDDEN
                )

        if borrowing.status not in ['approved', 'checked_out', 'overdue']:
            return Response(
                {'error': 'Can only return checked out, approved, or overdue borrowings'},
                status=status.HTTP_400_BAD_REQUEST
            )

        borrowing.status = 'returned'
        borrowing.actual_return_date = timezone.now()
        borrowing.notes = request.data.get('notes', borrowing.notes) or request.data.get('condition_notes', borrowing.notes)
        borrowing.save()

        # Restore equipment availability
        equipment = borrowing.equipment
        equipment.available_quantity += borrowing.quantity
        equipment.status = 'available'
        equipment.save()

        send_borrowing_returned_email(borrowing)

        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def my_borrowings(self, request):
        borrowings = Borrowing.objects.select_related(
            'equipment', 'equipment__department', 'borrower', 'approved_by'
        ).filter(borrower=request.user)
        serializer = BorrowingSerializer(borrowings, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def pending(self, request):
        if not request.user.is_admin:
            return Response(
                {'error': 'Only admins can view pending borrowings'},
                status=status.HTTP_403_FORBIDDEN
            )
        borrowings = self.get_queryset().filter(status='pending')
        serializer = BorrowingSerializer(borrowings, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def overdue(self, request):
        if not request.user.is_admin:
            return Response(
                {'error': 'Only admins can view overdue borrowings'},
                status=status.HTTP_403_FORBIDDEN
            )
        overdue = self.get_queryset().filter(status='overdue')
        serializer = BorrowingSerializer(overdue, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        """Export borrowings to CSV format - Admin only"""
        if not request.user.is_admin:
            return Response(
                {'error': 'Only admins can export borrowings'},
                status=status.HTTP_403_FORBIDDEN
            )
        import csv
        from django.http import HttpResponse

        borrowings = self.get_queryset()
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = (
            f'attachment; filename="emprunts_{timezone.now().strftime("%Y%m%d")}.csv"'
        )

        writer = csv.writer(response)
        writer.writerow([
            'ID', 'Référence', 'Équipement', 'Emprunteur', 'CNI', 'Email',
            'Salle', 'Quantité', 'Statut', 'Date demande', 'Date approbation',
            'Date retrait', 'Date retour prévue', 'Date retour effectif'
        ])

        for b in borrowings:
            writer.writerow([
                b.id,
                b.reference_number,
                b.equipment.name if b.equipment else '',
                b.borrower_name,
                b.borrower_cni,
                b.borrower_email,
                b.destination_room,
                b.quantity,
                b.status,
                b.request_date.strftime('%Y-%m-%d %H:%M') if b.request_date else '',
                b.approval_date.strftime('%Y-%m-%d %H:%M') if b.approval_date else '',
                b.checkout_date.strftime('%Y-%m-%d %H:%M') if b.checkout_date else '',
                b.expected_return_date.strftime('%Y-%m-%d') if b.expected_return_date else '',
                b.actual_return_date.strftime('%Y-%m-%d %H:%M') if b.actual_return_date else '',
            ])

        return response

    @action(detail=False, methods=['get'])
    def export_pdf(self, request):
        """Export borrowings to PDF format - Admin only"""
        if not request.user.is_admin:
            return Response(
                {'error': 'Only admins can export borrowings'},
                status=status.HTTP_403_FORBIDDEN
            )
        from fpdf import FPDF
        from django.http import HttpResponse

        borrowings = self.get_queryset()

        class PDF(FPDF):
            def header(self):
                self.set_font('helvetica', 'B', 15)
                self.cell(0, 10, 'Rapport des Emprunts - ManAC', 0, True, 'C')
                self.ln(5)

            def footer(self):
                self.set_y(-15)
                self.set_font('helvetica', 'I', 8)
                self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

        pdf = PDF()
        pdf.add_page()
        pdf.set_font('helvetica', 'B', 10)

        pdf.set_fill_color(200, 220, 255)
        headers = ['Ref.', 'Equipement', 'Emprunteur', 'Salle', 'Qte', 'Statut', 'Date']
        col_widths = [25, 45, 45, 25, 12, 25, 30]

        for i, header in enumerate(headers):
            pdf.cell(col_widths[i], 10, header, 1, 0, 'C', True)
        pdf.ln()

        pdf.set_font('helvetica', '', 8)
        for b in borrowings:
            pdf.cell(col_widths[0], 8, str(b.reference_number or '')[:10], 1)
            pdf.cell(col_widths[1], 8, (b.equipment.name if b.equipment else '')[:20], 1)
            pdf.cell(col_widths[2], 8, (b.borrower_name or '')[:20], 1)
            pdf.cell(col_widths[3], 8, (b.destination_room or '')[:10], 1)
            pdf.cell(col_widths[4], 8, str(b.quantity), 1, 0, 'C')
            pdf.cell(col_widths[5], 8, b.status[:10], 1)
            pdf.cell(col_widths[6], 8, b.request_date.strftime('%d/%m/%y') if b.request_date else '', 1)
            pdf.ln()

        pdf.ln(10)
        pdf.set_font('helvetica', 'B', 10)
        pdf.cell(0, 10, f'Total des emprunts: {borrowings.count()}', 0, True)
        pdf.cell(0, 10, f'Genere le: {timezone.now().strftime("%d/%m/%Y a %H:%M")}', 0, True)

        response = HttpResponse(
            pdf.output(dest='S').encode('latin-1'),
            content_type='application/pdf'
        )
        response['Content-Disposition'] = (
            f'attachment; filename="emprunts_{timezone.now().strftime("%Y%m%d")}.pdf"'
        )
        return response
