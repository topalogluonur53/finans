from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import NoteViewSet, LoanCalculationViewSet

router = DefaultRouter()
router.register(r'notes', NoteViewSet, basename='note')
router.register(r'loan-calculator', LoanCalculationViewSet, basename='loan-calculation')

urlpatterns = [
    path('', include(router.urls)),
]
