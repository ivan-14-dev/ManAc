"""
Email notification service for borrowings
"""
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.template.loader import render_to_string
from .models import Borrowing


def send_borrowing_confirmation_email(borrowing):
    """
    Send confirmation email when equipment is checked out
    """
    if not borrowing.borrower_email:
        return False
    
    subject = f"Confirmation d'emprunt - {borrowing.reference_number}"
    
    message = f"""
Bonjour {borrowing.borrower_name},

Votre emprunt a été confirmé avec succès!

=== INFORMATIONS EMPRUNT ===
Référence: {borrowing.reference_number}
Équipement: {borrowing.equipment.name}
Quantité: {borrowing.quantity}
Date d'emprunt: {borrowing.checkout_date.strftime('%d/%m/%Y à %H:%M') if borrowing.checkout_date else 'N/A'}
Date de retour prévue: {borrowing.expected_return_date.strftime('%d/%m/%Y')}
Destination: {borrowing.destination_room}

Merci de retourner l'équipement à temps.
En cas de retard, vous recevrez une alerte.

Cordialement,
L'équipe de gestion des équipements
"""
    
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[borrowing.borrower_email],
            fail_silently=False,
        )
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False


def send_borrower_overdue_reminder(borrowing):
    """
    Send reminder to borrower when equipment is overdue
    """
    if not borrowing.borrower_email:
        return False
    
    subject = f"ALERTE: Retard d'emprunt - {borrowing.reference_number}"
    
    days_overdue = (timezone.now().date() - borrowing.expected_return_date).days
    
    message = f"""
Bonjour {borrowing.borrower_name},

⚠️ ALERTE: Votre emprunt est en retard!

=== INFORMATIONS EMPRUNT ===
Référence: {borrowing.reference_number}
Équipement: {borrowing.equipment.name}
Date de retour prévue: {borrowing.expected_return_date.strftime('%d/%m/%Y')}
Retard: {days_overdue} jour(s)

Merci de retourner l'équipement immédiatement au plus tard aujourd'hui.

Cordialement,
L'équipe de gestion des équipements
"""
    
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[borrowing.borrower_email],
            fail_silently=False,
        )
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False


def send_admin_overdue_notification():
    """
    Send notification to admins about all overdue borrowings
    """
    from accounts.models import User
    
    # Get all admins
    admins = User.objects.filter(
        role__in=['general_admin', 'department_admin']
    )
    
    # Get overdue borrowings
    overdue_borrowings = Borrowing.objects.filter(
        status='checked_out',
        expected_return_date__lt=timezone.now().date()
    )
    
    if not overdue_borrowings.exists():
        return 0
    
    admin_emails = [admin.email for admin in admins if admin.email]
    
    if not admin_emails:
        return 0
    
    # Group by department
    by_department = {}
    for borrowing in overdue_borrowings:
        dept_name = borrowing.equipment.department.name if borrowing.equipment.department else 'Sans département'
        if dept_name not in by_department:
            by_department[dept_name] = []
        by_department[dept_name].append(borrowing)
    
    # Build message
    subject = f"ALERTE: {overdue_borrowings.count()} emprunt(s) en retard"
    
    message_parts = [subject, "\n=== EMPRUNTS EN RETARD ===\n"]
    
    for dept_name, borrowings in by_department.items():
        message_parts.append(f"\n--- {dept_name} ---")
        for b in borrowings:
            days = (timezone.now().date() - b.expected_return_date).days
            message_parts.append(
                f"• {b.reference_number}: {b.equipment.name} - {b.borrower_name} "
                f"(Retard: {days} jour(s))"
            )
    
    message_parts.append("\n\nMerci de traiter ces retards rapidement.")
    message_parts.append("\nCordialement,\nSystème de gestion des équipements")
    
    message = "\n".join(message_parts)
    
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=admin_emails,
            fail_silently=False,
        )
        
        # Mark overdue items as overdue status
        for borrowing in overdue_borrowings:
            borrowing.status = 'overdue'
            borrowing.overdue_email_sent = True
            borrowing.save()
        
        return overdue_borrowings.count()
    except Exception as e:
        print(f"Error sending admin email: {e}")
        return 0
