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
