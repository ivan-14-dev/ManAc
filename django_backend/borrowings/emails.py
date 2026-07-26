"""
Email notification service for borrowings
"""
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from .models import Borrowing


def send_borrowing_request_received_email(borrowing):
    """Notify borrower that their request was received and is pending."""
    if not borrowing.borrower_email:
        return False

    subject = f"ManAC – Demande d'emprunt reçue – {borrowing.reference_number}"
    message = (
        f"Bonjour {borrowing.borrower_name},\n\n"
        f"Votre demande d'emprunt a bien été reçue et est en cours de traitement.\n\n"
        f"=== DÉTAILS DE VOTRE DEMANDE ===\n"
        f"Référence      : {borrowing.reference_number}\n"
        f"Équipement     : {borrowing.equipment.name}\n"
        f"Quantité       : {borrowing.quantity}\n"
        f"Salle          : {borrowing.destination_room}\n"
        f"Retour prévu   : {borrowing.expected_return_date.strftime('%d/%m/%Y')}\n\n"
        f"Vous serez notifié(e) dès qu'une décision sera prise.\n\n"
        f"Cordialement,\nL'équipe ManAC"
    )
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
        print(f"Error sending borrowing request email: {e}")
        return False


def send_borrowing_approved_email(borrowing):
    """Notify borrower that their request was approved."""
    if not borrowing.borrower_email:
        return False

    subject = f"ManAC – Emprunt approuvé – {borrowing.reference_number}"
    message = (
        f"Bonjour {borrowing.borrower_name},\n\n"
        f"✅ Bonne nouvelle ! Votre demande d'emprunt a été APPROUVÉE.\n\n"
        f"=== DÉTAILS ===\n"
        f"Référence      : {borrowing.reference_number}\n"
        f"Équipement     : {borrowing.equipment.name}\n"
        f"Quantité       : {borrowing.quantity}\n"
        f"Salle          : {borrowing.destination_room}\n"
        f"Retour prévu   : {borrowing.expected_return_date.strftime('%d/%m/%Y')}\n\n"
        f"Vous pouvez maintenant récupérer votre équipement.\n"
        f"Merci de le retourner à la date prévue.\n\n"
        f"Cordialement,\nL'équipe ManAC"
    )
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
        print(f"Error sending approval email: {e}")
        return False


def send_borrowing_rejected_email(borrowing):
    """Notify borrower that their request was rejected."""
    if not borrowing.borrower_email:
        return False

    subject = f"ManAC – Demande d'emprunt refusée – {borrowing.reference_number}"
    message = (
        f"Bonjour {borrowing.borrower_name},\n\n"
        f"❌ Votre demande d'emprunt a été REFUSÉE.\n\n"
        f"=== DÉTAILS ===\n"
        f"Référence  : {borrowing.reference_number}\n"
        f"Équipement : {borrowing.equipment.name}\n"
        f"Quantité   : {borrowing.quantity}\n"
    )
    if borrowing.notes:
        message += f"Motif      : {borrowing.notes}\n"
    message += (
        f"\nPour toute question, veuillez contacter votre administrateur.\n\n"
        f"Cordialement,\nL'équipe ManAC"
    )
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
        print(f"Error sending rejection email: {e}")
        return False


def send_borrowing_confirmation_email(borrowing):
    """Send confirmation email when equipment is checked out."""
    if not borrowing.borrower_email:
        return False

    subject = f"ManAC – Confirmation de remise – {borrowing.reference_number}"
    message = (
        f"Bonjour {borrowing.borrower_name},\n\n"
        f"Votre équipement a été remis avec succès.\n\n"
        f"=== INFORMATIONS EMPRUNT ===\n"
        f"Référence          : {borrowing.reference_number}\n"
        f"Équipement         : {borrowing.equipment.name}\n"
        f"Quantité           : {borrowing.quantity}\n"
        f"Date de remise     : {borrowing.checkout_date.strftime('%d/%m/%Y à %H:%M') if borrowing.checkout_date else 'N/A'}\n"
        f"Date retour prévu  : {borrowing.expected_return_date.strftime('%d/%m/%Y')}\n"
        f"Destination        : {borrowing.destination_room}\n\n"
        f"Merci de retourner l'équipement à temps.\n"
        f"En cas de retard, vous recevrez une alerte.\n\n"
        f"Cordialement,\nL'équipe ManAC"
    )
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
        print(f"Error sending checkout email: {e}")
        return False


def send_borrowing_returned_email(borrowing):
    """Send confirmation email when equipment is returned."""
    if not borrowing.borrower_email:
        return False

    subject = f"ManAC – Retour confirmé – {borrowing.reference_number}"
    return_date = borrowing.actual_return_date
    message = (
        f"Bonjour {borrowing.borrower_name},\n\n"
        f"Le retour de votre équipement a bien été enregistré.\n\n"
        f"=== INFORMATIONS RETOUR ===\n"
        f"Référence        : {borrowing.reference_number}\n"
        f"Équipement       : {borrowing.equipment.name}\n"
        f"Quantité         : {borrowing.quantity}\n"
        f"Date de retour   : {return_date.strftime('%d/%m/%Y à %H:%M') if return_date else 'N/A'}\n\n"
        f"Merci d'avoir utilisé ManAC.\n\n"
        f"Cordialement,\nL'équipe ManAC"
    )
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
        print(f"Error sending return email: {e}")
        return False


def send_borrower_overdue_reminder(borrowing):
    """Send reminder to borrower when equipment is overdue."""
    if not borrowing.borrower_email:
        return False

    days_overdue = (timezone.now().date() - borrowing.expected_return_date).days
    subject = f"ManAC – ⚠️ Retard d'emprunt – {borrowing.reference_number}"
    message = (
        f"Bonjour {borrowing.borrower_name},\n\n"
        f"⚠️ ALERTE : Votre emprunt est en retard !\n\n"
        f"=== INFORMATIONS EMPRUNT ===\n"
        f"Référence          : {borrowing.reference_number}\n"
        f"Équipement         : {borrowing.equipment.name}\n"
        f"Date retour prévu  : {borrowing.expected_return_date.strftime('%d/%m/%Y')}\n"
        f"Retard             : {days_overdue} jour(s)\n\n"
        f"Merci de retourner l'équipement immédiatement.\n\n"
        f"Cordialement,\nL'équipe ManAC"
    )
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
        print(f"Error sending overdue email: {e}")
        return False


def send_admin_overdue_notification():
    """Send notification to admins about all overdue borrowings."""
    from accounts.models import User

    admins = User.objects.filter(role__in=['general_admin', 'department_admin'])
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
        dept_name = (
            borrowing.equipment.department.name
            if borrowing.equipment.department
            else 'Sans département'
        )
        by_department.setdefault(dept_name, []).append(borrowing)

    subject = f"ManAC – ALERTE : {overdue_borrowings.count()} emprunt(s) en retard"
    message_parts = [subject, "\n=== EMPRUNTS EN RETARD ===\n"]
    for dept_name, borrowings in by_department.items():
        message_parts.append(f"\n--- {dept_name} ---")
        for b in borrowings:
            days = (timezone.now().date() - b.expected_return_date).days
            message_parts.append(
                f"• {b.reference_number}: {b.equipment.name} – {b.borrower_name} "
                f"(Retard : {days} jour(s))"
            )
    message_parts.append("\n\nMerci de traiter ces retards rapidement.")
    message_parts.append("\nCordialement,\nSystème ManAC")

    message = "\n".join(message_parts)
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=admin_emails,
            fail_silently=False,
        )
        overdue_borrowings.update(status='overdue', overdue_email_sent=True)
        return overdue_borrowings.count()
    except Exception as e:
        print(f"Error sending admin overdue email: {e}")
        return 0
