from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MarketDataViewSet, AlarmViewSet, piyasa_page, create_alarm

router = DefaultRouter()
router.register(r'alarms', AlarmViewSet, basename='alarms')
router.register(r'', MarketDataViewSet, basename='market-data')

urlpatterns = [
    path('piyasa/', piyasa_page, name='piyasa-page'),
    path('alarm/ekle/', create_alarm, name='create-alarm-template'),
    path('categorized/', MarketDataViewSet.as_view({'get': 'categorized'}), name='market-categorized'),
    path('ticker/', MarketDataViewSet.as_view({'get': 'ticker'}), name='market-ticker'),
    path('api/', include(router.urls)),
]
