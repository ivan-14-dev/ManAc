"""
Custom authentication class that bypasses CSRF checks for session authentication.
This is useful when the frontend is on a different domain or using session auth.
"""
from rest_framework.authentication import SessionAuthentication


class CsrfExemptSessionAuthentication(SessionAuthentication):
    """
    Override enforce_csrf to skip CSRF check for session authentication.
    This allows API calls from the React frontend without CSRF tokens.
    """
    def enforce_csrf(self, request):
        # Skip CSRF check
        return
