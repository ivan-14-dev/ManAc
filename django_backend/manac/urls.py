from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from rest_framework.routers import DefaultRouter
from accounts.views import UserViewSet
from accounts.auth_views import login_view, logout_view, current_user_view
from departments.views import DepartmentViewSet
from equipment.views import EquipmentViewSet
from borrowings.views import BorrowingViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'departments', DepartmentViewSet)
router.register(r'equipment', EquipmentViewSet)
router.register(r'borrowings', BorrowingViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/login/', login_view, name='login'),
    path('api/auth/logout/', logout_view, name='logout'),
    path('api/auth/me/', current_user_view, name='current_user'),
    path('api/', include(router.urls)),
    path('api-auth/', include('rest_framework.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
