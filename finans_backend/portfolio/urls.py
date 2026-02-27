from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AssetViewSet, TransactionViewSet, BinanceProxyView

router = DefaultRouter()
router.register(r'assets', AssetViewSet, basename='asset')
router.register(r'transactions', TransactionViewSet, basename='transaction')

urlpatterns = [
    path('', include(router.urls)),
    path('binance-balance/', BinanceProxyView.as_view(), name='binance-balance'),
]
