from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import authenticate, login, logout
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
import random
import string


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response(
            {'error': 'Username and password required'},
            status=status.HTTP_400_BAD_REQUEST
        )

    user = authenticate(request, username=username, password=password)

    if user is not None:
        login(request, user)
        return Response({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'role': user.role,
            'department': user.department_id,
        })
    else:
        return Response(
            {'error': 'Invalid credentials'},
            status=status.HTTP_401_UNAUTHORIZED
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    logout(request)
    return Response({'message': 'Logged out successfully'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def current_user_view(request):
    user = request.user
    return Response({
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'role': user.role,
        'department': user.department_id,
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def forgot_password_view(request):
    """
    Request a 6-digit password reset code sent to the user's email.
    Accepts: email or username
    """
    from accounts.models import User, PasswordResetCode

    email = request.data.get('email', '').strip()
    username = request.data.get('username', '').strip()

    user = None
    if email:
        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            pass
    if user is None and username:
        try:
            user = User.objects.get(username__iexact=username)
        except User.DoesNotExist:
            pass

    # Always return success to avoid user enumeration
    if user is None or not user.email:
        return Response({'message': 'If this account exists, a reset code has been sent.'})

    # Invalidate old codes
    PasswordResetCode.objects.filter(user=user, used=False).update(used=True)

    # Generate new 6-digit code
    minutes = getattr(settings, 'PASSWORD_RESET_CODE_EXPIRY_MINUTES', 15)
    expires_at = timezone.now() + timezone.timedelta(minutes=minutes)
    code_str = ''.join(random.choices(string.digits, k=6))
    code_obj = PasswordResetCode.objects.create(
        user=user,
        code=code_str,
        expires_at=expires_at,
    )

    # Send email
    subject = "ManAC – Code de réinitialisation de mot de passe"
    message = (
        f"Bonjour {user.first_name or user.username},\n\n"
        f"Votre code de réinitialisation de mot de passe est :\n\n"
        f"    {code_obj.code}\n\n"
        f"Ce code est valable {minutes} minutes.\n"
        f"Si vous n'avez pas demandé de réinitialisation, ignorez cet email.\n\n"
        f"Cordialement,\nL'équipe ManAC"
    )
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )
    except Exception as e:
        print(f"Error sending password reset email: {e}")

    return Response({'message': 'If this account exists, a reset code has been sent.'})


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_reset_code_view(request):
    """Verify a 6-digit reset code without consuming it."""
    from accounts.models import User, PasswordResetCode

    email = request.data.get('email', '').strip()
    username = request.data.get('username', '').strip()
    code = request.data.get('code', '').strip()

    if not code:
        return Response({'error': 'Code requis.'}, status=status.HTTP_400_BAD_REQUEST)

    user = None
    if email:
        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            pass
    if user is None and username:
        try:
            user = User.objects.get(username__iexact=username)
        except User.DoesNotExist:
            pass

    if user is None:
        return Response({'error': 'Code invalide ou expiré.'}, status=status.HTTP_400_BAD_REQUEST)

    code_obj = PasswordResetCode.objects.filter(
        user=user, code=code, used=False
    ).order_by('-created_at').first()

    if code_obj is None or not code_obj.is_valid:
        return Response({'error': 'Code invalide ou expiré.'}, status=status.HTTP_400_BAD_REQUEST)

    return Response({'valid': True})


@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password_view(request):
    """Reset password using a valid 6-digit code."""
    from accounts.models import User, PasswordResetCode

    email = request.data.get('email', '').strip()
    username = request.data.get('username', '').strip()
    code = request.data.get('code', '').strip()
    new_password = request.data.get('new_password', '')

    if not code or not new_password:
        return Response(
            {'error': 'Code et nouveau mot de passe requis.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if len(new_password) < 8:
        return Response(
            {'error': 'Le mot de passe doit contenir au moins 8 caractères.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    user = None
    if email:
        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            pass
    if user is None and username:
        try:
            user = User.objects.get(username__iexact=username)
        except User.DoesNotExist:
            pass

    if user is None:
        return Response({'error': 'Code invalide ou expiré.'}, status=status.HTTP_400_BAD_REQUEST)

    code_obj = PasswordResetCode.objects.filter(
        user=user, code=code, used=False
    ).order_by('-created_at').first()

    if code_obj is None or not code_obj.is_valid:
        return Response({'error': 'Code invalide ou expiré.'}, status=status.HTTP_400_BAD_REQUEST)

    # Mark code used and reset password
    code_obj.used = True
    code_obj.save()

    user.set_password(new_password)
    user.save()

    return Response({'message': 'Mot de passe réinitialisé avec succès.'})
