from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from datetime import timedelta

from .models import Borrowing
from .serializers import (
    BorrowingSerializer, BorrowingCreateSerializer,
    BorrowingUpdateSerializer
)
from .emails import (
    send_borrowing_confirmation_email,
    send_borrower_overdue_reminder
)


class CanManageBorrowings:
    """Permission: Regular users can create/view their own, admins can manage all"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        # Allow all authenticated users to create borrowings
        if view.action == 'create':
            return True
        # Allow all authenticated users to view list
        if view.action in ['list', 'retrieve']:
            return True
        # Only admins can update/delete
        return request.user.is_general_admin or request.user.is_department_admin
    
    def has_object_permission(self, request, view, obj):
        # Allow all to view
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        # Only admins can modify
        return request.user.is_general_admin or request.user.is_department_admin


@method_decorator(csrf_exempt, name='dispatch')
class BorrowingViewSet(viewsets.ModelViewSet):
    queryset = Borrowing.objects.all()
    serializer_class = BorrowingSerializer
    permission_classes = [IsAuthenticated, CanManageBorrowings]
    filterset_fields = ['status', 'equipment']
    
    def get_serializer_class(self):
        if self.action == 'create':
            return BorrowingCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return BorrowingUpdateSerializer
        return BorrowingSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return Borrowing.objects.all()
        elif user.is_department_admin:
            return Borrowing.objects.filter(equipment__department=user.department)
        else:
            return Borrowing.objects.filter(borrower=user)
    
    def perform_create(self, serializer):
        serializer.save(
            borrower=self.request.user,
            borrower_name=f"{self.request.user.first_name} {self.request.user.last_name}",
            borrower_email=self.request.user.email
        )
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        borrowing = self.get_object()
        
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
        
        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        borrowing = self.get_object()
        
        if borrowing.status != 'pending':
            return Response(
                {'error': 'Can only reject pending borrowings'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        borrowing.status = 'rejected'
        borrowing.approved_by = request.user
        borrowing.approval_date = timezone.now()
        borrowing.notes = request.data.get('notes', '')
        borrowing.save()
        
        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def checkout(self, request, pk=None):
        borrowing = self.get_object()
        
        if borrowing.status != 'approved':
            return Response(
                {'error': 'Can only checkout approved borrowings'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        borrowing.status = 'checked_out'
        borrowing.checkout_date = timezone.now()
        borrowing.save()
        
        # Send confirmation email
        if not borrowing.checkout_email_sent:
            send_borrowing_confirmation_email(borrowing)
            borrowing.checkout_email_sent = True
            borrowing.save()
        
        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def return_equipment(self, request, pk=None):
        borrowing = self.get_object()
        
        if borrowing.status not in ['approved', 'checked_out']:
            return Response(
                {'error': 'Can only return checked out or approved borrowings'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        borrowing.status = 'returned'
        borrowing.actual_return_date = timezone.now()
        borrowing.notes = request.data.get('notes', borrowing.notes)
        borrowing.save()
        
        # Update equipment availability
        equipment = borrowing.equipment
        equipment.available_quantity += borrowing.quantity
        equipment.status = 'available'
        equipment.save()
        
        serializer = BorrowingSerializer(borrowing)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def my_borrowings(self, request):
        borrowings = Borrowing.objects.filter(borrower=request.user)
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
        overdue = self.get_queryset().filter(
            status='checked_out',
            expected_return_date__lt=timezone.now().date()
        )
        serializer = BorrowingSerializer(overdue, many=True)
        return Response(serializer.data)
