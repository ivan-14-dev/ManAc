from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import get_user_model

from .models import User
from .serializers import (
    UserSerializer, UserCreateSerializer, 
    UserUpdateSerializer, ChangePasswordSerializer
)

User = get_user_model()


class IsGeneralAdmin:
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.is_general_admin


class CanManageUsers:
    """Permission: Only General Admin can manage all users, Department Admin can manage their dept users"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        # Allow safe methods (GET, HEAD, OPTIONS) for all authenticated users
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        # Only admins can create users
        if view.action == 'create':
            return request.user.is_general_admin
        # Only admins can update/delete
        return request.user.is_general_admin or request.user.is_department_admin
    
    def has_object_permission(self, request, view, obj):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        # General admin can do everything
        if request.user.is_general_admin:
            return True
        # Department admin can only manage users in their department
        if request.user.is_department_admin and obj.department == request.user.department:
            return True
        return False


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    permission_classes = [IsAuthenticated, CanManageUsers]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return UserCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return UserUpdateSerializer
        return UserSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return User.objects.all()
        elif user.is_department_admin:
            return User.objects.filter(department=user.department)
        else:
            return User.objects.filter(id=user.id)
    
    @action(detail=True, methods=['post'])
    def change_password(self, request, pk=None):
        user = self.get_object()
        serializer = ChangePasswordSerializer(data=request.data)
        
        if serializer.is_valid():
            if not user.check_password(serializer.validated_data['old_password']):
                return Response(
                    {'error': 'Incorrect old password'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({'message': 'Password updated successfully'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
