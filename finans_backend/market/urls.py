from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MarketDataViewSet

router = DefaultRouter()
router.register(r'', MarketDataViewSet, basename='market-data')

urlpatterns = [
    path('prices/', MarketDataViewSet.as_view({'get': 'list'}), name='prices'),
    path('ticker/', MarketDataViewSet.as_view({'get': 'ticker'}), name='ticker'),
    path('refresh/', MarketDataViewSet.as_view({'post': 'refresh'}), name='refresh'),
    path('', include(router.urls)),
]
