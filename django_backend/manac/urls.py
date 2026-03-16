from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse

from rest_framework.routers import DefaultRouter
from accounts.views import UserViewSet
from accounts.auth_views import login_view, logout_view, current_user_view
from departments.views import DepartmentViewSet
from equipment.views import EquipmentViewSet
from borrowings.views import BorrowingViewSet

# Root endpoint
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
    path('', api_root),
    path('admin/', admin.site.urls),
    path('api/auth/login/', login_view, name='login'),
    path('api/auth/logout/', logout_view, name='logout'),
    path('api/auth/me/', current_user_view, name='current_user'),
    path('api/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
