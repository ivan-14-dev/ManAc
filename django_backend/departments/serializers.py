from rest_framework import serializers
from .models import Department


class DepartmentSerializer(serializers.ModelSerializer):
    user_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Department
        fields = ['id', 'name', 'code', 'description', 'is_active', 
                  'created_at', 'updated_at', 'user_count']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_user_count(self, obj):
        return obj.users.count()
