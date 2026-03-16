from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse, HttpResponse
import os

from rest_framework.routers import DefaultRouter
from accounts.views import UserViewSet
from accounts.auth_views import login_view, logout_view, current_user_view
from departments.views import DepartmentViewSet
from equipment.views import EquipmentViewSet
from borrowings.views import BorrowingViewSet


def frontend_view(request):
    """Serve the React frontend at /"""
    possible_paths = [
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'react-frontend', 'dist', 'index.html'),
        os.path.join(os.path.dirname(os.path.dirname(__file__)), '..', 'react-frontend', 'dist', 'index.html'),
        '/var/task/react-frontend/dist/index.html',
        '/var/task/dist/index.html',
        '/var/task/react-frontend/dist/index.html',
    ]
    
    for build_path in possible_paths:
        if os.path.exists(build_path):
            with open(build_path, 'r', encoding='utf-8') as f:
                return HttpResponse(f.read(), content_type='text/html')
    
    return HttpResponse(
        "<html><body><h1>ManAC - Campus Equipment Management</h1>"
        "<p>Frontend build not found. Please run 'npm run build' in react-frontend directory.</p>"
        "<p>API is available at <a href='/api/'>API</a></p>"
        "<p>Django Admin is available at <a href='/admin/'>admin</a></p>"
        "</body></html>",
        content_type='text/html'
    )


def serve_static(request, path):
    """Serve React static files"""
    possible_paths = [
        os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'react-frontend', 'dist', path),
        os.path.join(os.path.dirname(os.path.dirname(__file__)), '..', 'react-frontend', 'dist', path),
        '/var/task/react-frontend/dist/' + path,
        '/var/task/dist/' + path,
    ]
    
    for file_path in possible_paths:
        if os.path.exists(file_path):
            content_type = 'application/javascript' if path.endswith('.js') else 'text/css'
            if path.endswith('.svg'):
                content_type = 'image/svg+xml'
            with open(file_path, 'rb') as f:
                return HttpResponse(f.read(), content_type=content_type)
    
    return HttpResponse('Not found', status=404)


def api_root(request):
    return JsonResponse({
        'message': 'ManAC API - Campus Equipment Management',
        'version': '1.0.0',
        'endpoints': {
            'admin': '/admin/',
            'auth': '/api/auth/',
            'users': '/api/users/',
            'departments': '/api/departments/',
            'equipment': '/api/equipment/',
            'borrowings': '/api/borrowings/',
        }
    })


router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'departments', DepartmentViewSet)
router.register(r'equipment', EquipmentViewSet)
router.register(r'borrowings', BorrowingViewSet)

urlpatterns = [
    path('', frontend_view, name='frontend'),
    re_path(r'^(assets/.*)$', serve_static),
    re_path(r'^(favicon\.svg)$', serve_static),
    path('api/', api_root, name='api_root'),
    path('api/auth/login/', login_view, name='login'),
    path('api/auth/logout/', logout_view, name='logout'),
    path('api/auth/me/', current_user_view, name='current_user'),
    path('api/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls')),
    path('admin/', admin.site.urls),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
