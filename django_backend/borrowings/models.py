from django.db import models
from django.conf import settings
from django.utils import timezone
from equipment.models import Equipment
import uuid


class Borrowing(models.Model):
    """Borrowing/Emprunt model for equipment borrowing"""
    STATUS_CHOICES = [
        ('pending', 'En attente'),
        ('approved', 'Approuvé'),
        ('rejected', 'Rejeté'),
        ('checked_out', 'Emprunté'),
        ('returned', 'Retourné'),
        ('overdue', 'En retard'),
    ]
    
    # Unique reference number for the borrowing
    reference_number = models.CharField(
        max_length=20,
        unique=True,
        editable=False,
        null=True,
        blank=True
    )
    
    equipment = models.ForeignKey(
        Equipment,
        on_delete=models.CASCADE,
        related_name='borrowings'
    )
    
    borrower = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='borrowings'
    )
    
    borrower_name = models.CharField(max_length=200)
    borrower_cni = models.CharField(max_length=50)
    borrower_email = models.EmailField(blank=True)
    destination_room = models.CharField(max_length=100)
    
    quantity = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    request_date = models.DateTimeField(auto_now_add=True)
    approval_date = models.DateTimeField(null=True, blank=True)
    checkout_date = models.DateTimeField(null=True, blank=True)
    expected_return_date = models.DateField()
    actual_return_date = models.DateTimeField(null=True, blank=True)
    
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='approved_borrowings'
    )
    
    notes = models.TextField(blank=True)
    cni_photo = models.ImageField(upload_to='cni/', null=True, blank=True)
    
    # Email notification tracking
    checkout_email_sent = models.BooleanField(default=False)
    overdue_email_sent = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-request_date']

    def save(self, *args, **kwargs):
        if not self.reference_number:
            # Generate unique reference number: EMP-YYYYMMDD-XXXX
            today = timezone.now().strftime('%Y%m%d')
            last_borrowing = Borrowing.objects.filter(
                reference_number__startswith=f'EMP-{today}'
            ).order_by('-reference_number').first()
            
            if last_borrowing:
                last_num = int(last_borrowing.reference_number.split('-')[-1])
                new_num = last_num + 1
            else:
                new_num = 1
            
            self.reference_number = f'EMP-{today}-{new_num:04d}'
        
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.reference_number} - {self.equipment.name} - {self.borrower_name}"
