from rest_framework import serializers
from .models import Equipment


class EquipmentSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Equipment
        fields = ['id', 'name', 'category', 'description', 'serial_number',
                  'barcode', 'department', 'department_name', 'location', 'status',
                  'total_quantity', 'available_quantity', 'photo', 'value',
                  'purchase_date', 'created_by', 'created_by_username', 
                  'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class EquipmentListSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    
    class Meta:
        model = Equipment
        fields = ['id', 'name', 'category', 'serial_number', 'barcode',
                  'department', 'department_name', 'location', 'status',
                  'total_quantity', 'available_quantity', 'photo', 'value']
