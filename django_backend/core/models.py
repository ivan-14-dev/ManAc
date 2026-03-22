from django.db import models
from django.conf import settings
import uuid


class Activity(models.Model):
    """Activity log model for tracking all actions in the system"""
    TYPE_CHOICES = [
        ('stock_in', 'Stock In'),
        ('stock_out', 'Stock Out'),
        ('stock_adjustment', 'Stock Adjustment'),
        ('equipment_checkout', 'Equipment Checkout'),
        ('equipment_return', 'Equipment Return'),
        ('sync', 'Sync'),
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('user_created', 'User Created'),
        ('user_updated', 'User Updated'),
        ('equipment_created', 'Equipment Created'),
        ('equipment_updated', 'Equipment Updated'),
        ('department_created', 'Department Created'),
        ('department_updated', 'Department Updated'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type = models.CharField(max_length=30, choices=TYPE_CHOICES)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activities'
    )
    
    # Optional related objects
    equipment = models.ForeignKey(
        'equipment.Equipment',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activities'
    )
    borrowing = models.ForeignKey(
        'borrowings.Borrowing',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activities'
    )
    stock_item = models.ForeignKey(
        'StockItem',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activities'
    )
    
    # Metadata for additional info
    metadata = models.JSONField(default=dict, blank=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.title} - {self.timestamp}"


class StockItem(models.Model):
    """Stock item model for consumables and small items (separate from Equipment)"""
    CATEGORY_CHOICES = [
        ('supplies', 'Supplies'),
        ('consumables', 'Consumables'),
        ('tools', 'Tools'),
        ('spare_parts', 'Spare Parts'),
        ('stationery', 'Stationery'),
        ('other', 'Other'),
    ]
    
    UNIT_CHOICES = [
        ('pcs', 'Pieces'),
        ('boxes', 'Boxes'),
        ('packs', 'Packs'),
        ('reams', 'Reams'),
        ('liters', 'Liters'),
        ('kg', 'Kilograms'),
        ('meters', 'Meters'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='other')
    quantity = models.PositiveIntegerField(default=0)
    min_quantity = models.PositiveIntegerField(default=5)
    unit = models.CharField(max_length=20, choices=UNIT_CHOICES, default='pcs')
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    description = models.TextField(blank=True)
    barcode = models.CharField(max_length=100, blank=True)
    location = models.CharField(max_length=200, default='Main Warehouse')
    
    department = models.ForeignKey(
        'departments.Department',
        on_delete=models.PROTECT,
        related_name='stock_items'
    )
    
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_stock_items'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.quantity} {self.unit})"
    
    @property
    def is_low_stock(self):
        return self.quantity <= self.min_quantity


class StockMovement(models.Model):
    """Stock movement model for tracking all stock changes"""
    TYPE_CHOICES = [
        ('in', 'Stock In'),
        ('out', 'Stock Out'),
        ('adjustment', 'Adjustment'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    stock_item = models.ForeignKey(
        StockItem,
        on_delete=models.CASCADE,
        related_name='movements'
    )
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    quantity = models.IntegerField()  # Can be negative for adjustments
    quantity_before = models.PositiveIntegerField()
    quantity_after = models.PositiveIntegerField()
    
    reason = models.TextField(blank=True)
    reference = models.CharField(max_length=200, blank=True)
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='stock_movements'
    )
    
    date = models.DateTimeField(auto_now_add=True)
    
    # Related borrowing (if movement is from equipment borrowing)
    borrowing = models.ForeignKey(
        'borrowings.Borrowing',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='stock_movements'
    )
    
    class Meta:
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.stock_item.name} - {self.type}: {self.quantity}"


class DailyReport(models.Model):
    """Daily report model for summarizing daily activities"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField(unique=True)
    
    # Statistics
    total_checkouts = models.PositiveIntegerField(default=0)
    total_returns = models.PositiveIntegerField(default=0)
    total_items_checked_out = models.PositiveIntegerField(default=0)
    total_items_returned = models.PositiveIntegerField(default=0)
    
    # Equipment-specific stats
    new_equipment_added = models.PositiveIntegerField(default=0)
    equipment_maintenance = models.PositiveIntegerField(default=0)
    
    # Stock-specific stats
    stock_in_total = models.PositiveIntegerField(default=0)
    stock_out_total = models.PositiveIntegerField(default=0)
    
    summary = models.TextField(blank=True)
    
    generated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='daily_reports'
    )
    generated_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-date']
    
    def __str__(self):
        return f"Report - {self.date}"
    
    @classmethod
    def generate_report(cls, date, user):
        """Generate a daily report for the given date"""
        from datetime import timedelta
        from django.utils import timezone
        from borrowings.models import Borrowing
        from equipment.models import Equipment
        
        # Get start and end of day
        start_of_day = timezone.make_aware(
            timezone.datetime.combine(date, timezone.datetime.min.time())
        )
        end_of_day = start_of_day + timedelta(days=1)
        
        # Get borrowings for the day
        borrowings = Borrowing.objects.filter(
            created_at__gte=start_of_day,
            created_at__lt=end_of_day
        )
        
        checkouts = borrowings.filter(status__in=['checked_out', 'returned', 'approved'])
        returns = borrowings.filter(status='returned')
        
        # Get new equipment
        new_equipment = Equipment.objects.filter(
            created_at__gte=start_of_day,
            created_at__lt=end_of_day
        )
        
        # Get stock movements
        stock_movements = StockMovement.objects.filter(
            date__gte=start_of_day,
            date__lt=end_of_day
        )
        
        stock_in = stock_movements.filter(type='in').aggregate(
            total=models.Sum('quantity')
        )['total'] or 0
        stock_out = stock_movements.filter(type='out').aggregate(
            total=models.Sum('quantity')
        )['total'] or 0
        
        # Create or update report
        report, created = cls.objects.get_or_create(
            date=date,
            defaults={
                'total_checkouts': checkouts.count(),
                'total_returns': returns.count(),
                'total_items_checked_out': sum(b.quantity for b in checkouts),
                'total_items_returned': sum(b.quantity for b in returns),
                'new_equipment_added': new_equipment.count(),
                'stock_in_total': stock_in,
                'stock_out_total': stock_out,
                'generated_by': user,
            }
        )
        
        if not created:
            report.total_checkouts = checkouts.count()
            report.total_returns = returns.count()
            report.total_items_checked_out = sum(b.quantity for b in checkouts)
            report.total_items_returned = sum(b.quantity for b in returns)
            report.new_equipment_added = new_equipment.count()
            report.stock_in_total = stock_in
            report.stock_out_total = stock_out
            report.generated_by = user
            report.save()
        
        return report
