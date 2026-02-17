from django.urls import path
from .views import RegisterView, UserDetailView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth_register'),
    path('user/', UserDetailView.as_view(), name='auth_user_detail'),
]
