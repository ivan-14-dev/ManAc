from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import User

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.name', read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 
                  'role', 'department', 'department_name', 'phone', 
                  'avatar', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']


class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'first_name', 
                  'last_name', 'role', 'department', 'phone']
    
    def validate_role(self, value):
        """Validate that the role doesn't exceed the current user's role"""
        request = self.context.get('request')
        if not request or not request.user:
            raise serializers.ValidationError("Authentication required")
        
        user = request.user
        # Define role hierarchy: general_admin > department_admin > user
        role_hierarchy = {'general_admin': 3, 'department_admin': 2, 'user': 1}
        
        user_role_level = role_hierarchy.get(user.role, 0)
        requested_role_level = role_hierarchy.get(value, 0)
        
        if requested_role_level > user_role_level:
            raise serializers.ValidationError(
                f"You cannot assign a role higher than your own ({user.get_role_display()})"
            )
        
        return value
    
    def validate_department(self, value):
        """Validate department assignment for department admins"""
        request = self.context.get('request')
        if not request or not request.user:
            raise serializers.ValidationError("Authentication required")
        
        user = request.user
        # Department admins can only assign users to their own department
        if user.is_department_admin and value != user.department:
            raise serializers.ValidationError(
                "You can only assign users to your own department"
            )
        
        return value
    
    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'role', 
                  'department', 'phone', 'avatar', 'is_active']
    
    def validate_role(self, value):
        """Validate that the role doesn't exceed the current user's role"""
        request = self.context.get('request')
        if not request or not request.user:
            raise serializers.ValidationError("Authentication required")
        
        user = request.user
        # Define role hierarchy: general_admin > department_admin > user
        role_hierarchy = {'general_admin': 3, 'department_admin': 2, 'user': 1}
        
        user_role_level = role_hierarchy.get(user.role, 0)
        requested_role_level = role_hierarchy.get(value, 0)
        
        if requested_role_level > user_role_level:
            raise serializers.ValidationError(
                f"You cannot assign a role higher than your own ({user.get_role_display()})"
            )
        
        return value
    
    def validate_department(self, value):
        """Validate department assignment for department admins"""
        request = self.context.get('request')
        if not request or not request.user:
            raise serializers.ValidationError("Authentication required")
        
        user = request.user
        # Department admins can only assign users to their own department
        if user.is_department_admin and value != user.department:
            raise serializers.ValidationError(
                "You can only assign users to your own department"
            )
        
        return value


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=8)
