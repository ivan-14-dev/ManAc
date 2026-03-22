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
                  'expected_return_date', 'notes', 'cni_photo']
        extra_kwargs = {
            'borrower_name': {'required': False},
            'borrower_cni': {'required': True},  # CNI is required
            'borrower_email': {'required': False},
            'destination_room': {'required': False},
            'expected_return_date': {'required': False},
        }
    
    def create(self, validated_data):
        # Set default expected return date to 7 days from now if not provided
        from django.utils import timezone
        from datetime import timedelta
        if 'expected_return_date' not in validated_data or not validated_data['expected_return_date']:
            validated_data['expected_return_date'] = timezone.now().date() + timedelta(days=7)
        return super().create(validated_data)


class BorrowingUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Borrowing
        fields = ['status', 'notes']
