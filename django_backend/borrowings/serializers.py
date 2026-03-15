from rest_framework import serializers
from .models import Borrowing
from equipment.serializers import EquipmentListSerializer


class BorrowingSerializer(serializers.ModelSerializer):
    equipment_name = serializers.CharField(source='equipment.name', read_only=True)
    equipment_details = EquipmentListSerializer(source='equipment', read_only=True)
    borrower_username = serializers.CharField(source='borrower.username', read_only=True)
    approved_by_username = serializers.CharField(source='approved_by.username', read_only=True)
    department_name = serializers.CharField(source='equipment.department.name', read_only=True)
    
    class Meta:
        model = Borrowing
        fields = ['id', 'equipment', 'equipment_name', 'equipment_details',
                  'borrower', 'borrower_username', 'borrower_name', 
                  'borrower_cni', 'borrower_email', 'destination_room',
                  'quantity', 'status', 'request_date', 'approval_date',
                  'checkout_date', 'expected_return_date', 'actual_return_date',
                  'approved_by', 'approved_by_username', 'notes', 'cni_photo',
                  'department_name', 'created_at', 'updated_at']
        read_only_fields = ['id', 'request_date', 'created_at', 'updated_at']


class BorrowingCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Borrowing
        fields = ['equipment', 'borrower_name', 'borrower_cni', 
                  'borrower_email', 'destination_room', 'quantity',
                  'expected_return_date', 'notes']
        extra_kwargs = {
            'borrower_name': {'required': False},
            'borrower_cni': {'required': False},
            'borrower_email': {'required': False},
            'destination_room': {'required': False},
        }


class BorrowingUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Borrowing
        fields = ['status', 'notes']
