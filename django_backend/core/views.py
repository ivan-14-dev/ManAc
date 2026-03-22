from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from datetime import timedelta

from .models import Activity, StockItem, StockMovement, DailyReport
from .serializers import (
    ActivitySerializer, StockItemSerializer,
    StockMovementSerializer, DailyReportSerializer
)


class ActivityViewSet(viewsets.ModelViewSet):
    """ViewSet for Activity log"""
    queryset = Activity.objects.all()
    serializer_class = ActivitySerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['type', 'user']
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return Activity.objects.all()
        elif user.is_department_admin:
            return Activity.objects.filter(
                department=user.department
            )
        else:
            return Activity.objects.filter(user=user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class CanManageStock:
    """Permission for stock management"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        return request.user.is_general_admin or request.user.is_department_admin
    
    def has_object_permission(self, request, view, obj):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        if request.user.is_general_admin:
            return True
        if request.user.is_department_admin and obj.department == request.user.department:
            return True
        return False


class StockItemViewSet(viewsets.ModelViewSet):
    """ViewSet for Stock Items"""
    queryset = StockItem.objects.all()
    serializer_class = StockItemSerializer
    permission_classes = [IsAuthenticated, CanManageStock]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['category', 'department']
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return StockItem.objects.all()
        elif user.is_department_admin:
            return StockItem.objects.filter(department=user.department)
        else:
            return StockItem.objects.filter(department=user.department)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get items with low stock"""
        queryset = self.get_queryset()
        low_stock_items = queryset.filter(
            quantity__lte=models.F('min_quantity')
        )
        serializer = self.get_serializer(low_stock_items, many=True)
        return Response(serializer.data)


class StockMovementViewSet(viewsets.ModelViewSet):
    """ViewSet for Stock Movements"""
    queryset = StockMovement.objects.all()
    serializer_class = StockMovementSerializer
    permission_classes = [IsAuthenticated, CanManageStock]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['type', 'stock_item', 'user']
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return StockMovement.objects.all()
        elif user.is_department_admin:
            return StockMovement.objects.filter(
                stock_item__department=user.department
            )
        else:
            return StockMovement.objects.filter(user=user)
    
    def perform_create(self, serializer):
        stock_item = serializer.validated_data['stock_item']
        quantity = serializer.validated_data['quantity']
        
        # Get quantity before
        quantity_before = stock_item.quantity
        
        # Calculate new quantity based on movement type
        movement_type = serializer.validated_data['type']
        if movement_type == 'in':
            quantity_after = quantity_before + quantity
        elif movement_type == 'out':
            quantity_after = max(0, quantity_before - quantity)
        else:  # adjustment
            quantity_after = quantity
        
        # Save movement with calculated values
        serializer.save(
            user=self.request.user,
            quantity_before=quantity_before,
            quantity_after=quantity_after
        )
        
        # Update stock item quantity
        stock_item.quantity = quantity_after
        stock_item.save()


class DailyReportViewSet(viewsets.ModelViewSet):
    """ViewSet for Daily Reports"""
    queryset = DailyReport.objects.all()
    serializer_class = DailyReportSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['date']
    http_method_names = ['get', 'head', 'options']  # Read-only
    
    def get_queryset(self):
        user = self.request.user
        if user.is_general_admin:
            return DailyReport.objects.all()
        elif user.is_department_admin:
            return DailyReport.objects.filter(
                department=user.department
            )
        else:
            # Users can only see their own generated reports
            return DailyReport.objects.filter(generated_by=user)
    
    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Generate report for a specific date or today"""
        date_str = request.data.get('date')
        
        if date_str:
            from datetime import datetime
            try:
                date = datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                return Response(
                    {'error': 'Invalid date format. Use YYYY-MM-DD'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        else:
            date = timezone.now().date()
        
        report = DailyReport.generate_report(date, request.user)
        serializer = DailyReportSerializer(report)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Get recent reports"""
        days = int(request.query_params.get('days', 7))
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        reports = DailyReport.objects.filter(
            date__gte=start_date,
            date__lte=end_date
        ).order_by('-date')
        
        serializer = self.get_serializer(reports, many=True)
        return Response(serializer.data)


# Import models for the StockItemViewSet
from django.db import models
