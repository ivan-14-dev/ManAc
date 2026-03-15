"""
Management command to check for overdue borrowings and send alerts
"""
from django.core.management.base import BaseCommand
from borrowings.emails import send_admin_overdue_notification, send_borrower_overdue_reminder
from borrowings.models import Borrowing
from django.utils import timezone


class Command(BaseCommand):
    help = 'Check for overdue borrowings and send email alerts'

    def add_arguments(self, parser):
        parser.add_argument(
            '--borrowers',
            action='store_true',
            help='Send reminders to borrowers with overdue items',
        )
        parser.add_argument(
            '--admins',
            action='store_true',
            help='Send notifications to admins about overdue items',
        )
        parser.add_argument(
            '--all',
            action='store_true',
            help='Send all notifications',
        )

    def handle(self, *args, **options):
        today = timezone.now().date()
        
        # Get all checked out borrowings that are overdue
        overdue_borrowings = Borrowing.objects.filter(
            status='checked_out',
            expected_return_date__lt=today
        )
        
        if not overdue_borrowings.exists():
            self.stdout.write(
                self.style.SUCCESS('No overdue borrowings found.')
            )
            return
        
        self.stdout.write(
            self.style.WARNING(f'Found {overdue_borrowings.count()} overdue borrowings.')
        )
        
        # Send to borrowers
        if options.get('all') or options.get('borrowers'):
            self.stdout.write('Sending reminders to borrowers...')
            for borrowing in overdue_borrowings:
                if not borrowing.overdue_email_sent:
                    if send_borrower_overdue_reminder(borrowing):
                        borrowing.overdue_email_sent = True
                        borrowing.status = 'overdue'
                        borrowing.save()
                        self.stdout.write(
                            f'  Sent reminder to {borrowing.borrower_name}'
                        )
        
        # Send to admins
        if options.get('all') or options.get('admins'):
            self.stdout.write('Sending notification to admins...')
            count = send_admin_overdue_notification()
            self.stdout.write(
                self.style.SUCCESS(f'Admin notification sent to {count} items.')
            )
        
        self.stdout.write(
            self.style.SUCCESS('Done!')
        )
