from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom User model with roles"""
    ROLE_CHOICES = [
        ('general_admin', 'General Admin'),
        ('department_admin', 'Department Admin'),
        ('user', 'User'),
    ]
    
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')
    department = models.ForeignKey(
        'departments.Department',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users'
    )
    phone = models.CharField(max_length=20, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['username']

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
    
    @property
    def is_general_admin(self):
        return self.role == 'general_admin' or self.is_superuser
    
    @property
    def is_department_admin(self):
        return self.role == 'department_admin'
    
    @property
    def is_admin(self):
        return self.is_general_admin or self.is_department_admin
    
    def can_manage_department(self, department):
        if self.is_general_admin:
            return True
        if self.is_department_admin and self.department == department:
            return True
        return False
