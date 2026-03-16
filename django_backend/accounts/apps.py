from django.apps import AppConfig
from django.core.management import call_command


class AccountsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'accounts'

    def ready(self):
        # Automatically run migrations and seed data when app starts
        try:
            call_command('migrate', '--run-syncdb', verbosity=0)
            call_command('seed_data', verbosity=0)
        except Exception:
            pass  # Ignore errors during startup
