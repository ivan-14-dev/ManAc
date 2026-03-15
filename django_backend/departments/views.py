from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Department
from .serializers import DepartmentSerializer


class CanManageDepartments:
    """Permission: Only General Admin can manage departments"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        # Allow safe methods (GET, HEAD, OPTIONS) for all authenticated users
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        # Only General Admin can create/update/delete departments
        return request.user.is_general_admin
    
    def has_object_permission(self, request, view, obj):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        return request.user.is_general_admin


class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    permission_classes = [IsAuthenticated, CanManageDepartments]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return Department.objects.all()
        elif user.is_department_admin:
            return Department.objects.filter(id=user.department.id)
        return Department.objects.filter(is_active=True)
