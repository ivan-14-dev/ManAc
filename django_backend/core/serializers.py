from rest_framework import serializers
from .models import Activity, StockItem, StockMovement, DailyReport


class ActivitySerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    equipment_name = serializers.CharField(source='equipment.name', read_only=True)
    
    class Meta:
        model = Activity
        fields = [
            'id', 'type', 'title', 'description', 'timestamp',
            'user', 'user_name', 'equipment', 'equipment_name',
            'borrowing', 'stock_item', 'metadata'
        ]
        read_only_fields = ['id', 'timestamp']


class StockItemSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    is_low_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = StockItem
        fields = [
            'id', 'name', 'category', 'quantity', 'min_quantity',
            'unit', 'price', 'description', 'barcode', 'location',
            'department', 'department_name', 'created_by', 'created_by_name',
            'created_at', 'updated_at', 'is_low_stock'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class StockMovementSerializer(serializers.ModelSerializer):
    stock_item_name = serializers.CharField(source='stock_item.name', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    
    class Meta:
        model = StockMovement
        fields = [
            'id', 'stock_item', 'stock_item_name', 'type', 'quantity',
            'quantity_before', 'quantity_after', 'reason', 'reference',
            'user', 'user_name', 'date', 'borrowing'
        ]
        read_only_fields = ['id', 'quantity_before', 'quantity_after', 'date']


class DailyReportSerializer(serializers.ModelSerializer):
    generated_by_name = serializers.CharField(source='generated_by.get_full_name', read_only=True)
    
    class Meta:
        model = DailyReport
        fields = [
            'id', 'date', 'total_checkouts', 'total_returns',
            'total_items_checked_out', 'total_items_returned',
            'new_equipment_added', 'equipment_maintenance',
            'stock_in_total', 'stock_out_total', 'summary',
            'generated_by', 'generated_by_name', 'generated_at'
        ]
        read_only_fields = ['id', 'generated_at']
