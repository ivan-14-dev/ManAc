from django.db import models
from django.conf import settings


class Equipment(models.Model):
    """Equipment/Accessory model for campus equipment"""
    CATEGORY_CHOICES = [
        ('computer', 'Computer'),
        ('monitor', 'Monitor'),
        ('keyboard', 'Keyboard'),
        ('mouse', 'Mouse'),
        ('printer', 'Printer'),
        ('scanner', 'Scanner'),
        ('projector', 'Projector'),
        ('camera', 'Camera'),
        ('audio', 'Audio Equipment'),
        ('furniture', 'Furniture'),
        ('tool', 'Tools'),
        ('network', 'Network Equipment'),
        ('cables', 'Cables'),
        ('accessories', 'Accessories'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('checked_out', 'Checked Out'),
        ('maintenance', 'Maintenance'),
        ('retired', 'Retired'),
    ]
    
    name = models.CharField(max_length=200)
    category = models.CharField(max_length=50)  # Allow custom categories
    description = models.TextField(blank=True)
    serial_number = models.CharField(max_length=100, unique=True)
    barcode = models.CharField(max_length=100, blank=True)
    
    department = models.ForeignKey(
        'departments.Department',
        on_delete=models.PROTECT,
        related_name='equipment'
    )
    
    location = models.CharField(max_length=200)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    total_quantity = models.PositiveIntegerField(default=1)
    available_quantity = models.PositiveIntegerField(default=1)
    
    photo = models.ImageField(upload_to='equipment/', null=True, blank=True)
    value = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    purchase_date = models.DateField(null=True, blank=True)
    
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_equipment'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.serial_number})"
