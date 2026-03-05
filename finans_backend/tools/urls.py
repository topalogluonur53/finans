from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import NoteViewSet, LoanCalculationViewSet, proxy_generic

router = DefaultRouter()
router.register(r'notes', NoteViewSet, basename='note')
router.register(r'loan-calculator', LoanCalculationViewSet, basename='loan-calculation')

    path('proxy/', proxy_generic, name='proxy-generic'),
    path('', include(router.urls)),
]
