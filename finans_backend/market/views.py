from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import MarketData
from .serializers import MarketDataSerializer
import random
from datetime import datetime

class MarketDataViewSet(viewsets.ModelViewSet):
    queryset = MarketData.objects.all()
    serializer_class = MarketDataSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly] # Allow public read? Or authenticated.

    @action(detail=False, methods=['get'])
    def ticker(self, request):
        # Return simplified ticker data for marquee
        # If no data, generate mock
        if not MarketData.objects.exists():
            self._generate_mock_data()
        
        data = MarketData.objects.all().values('symbol', 'price', 'change_percent_24h')
        return Response(list(data))

    @action(detail=False, methods=['post'])
    def refresh(self, request):
        # Force refresh prices (mock)
        self._generate_mock_data()
        return Response({'status': 'updated'})

    def _generate_mock_data(self):
        symbols = ['BTC', 'ETH', 'SOL', 'GOLD', 'USD', 'EUR', 'AAPL', 'SILVER']
        for sym in symbols:
            price = 100 + random.uniform(-10, 10)
            if sym == 'BTC': price = 45000 + random.uniform(-500, 500)
            if sym == 'ETH': price = 2800 + random.uniform(-50, 50)
            if sym == 'GOLD': price = 2000 + random.uniform(-20, 20)
            
            change = random.uniform(-5, 5)
            
            MarketData.objects.update_or_create(
                symbol=sym,
                defaults={
                    'price': price,
                    'change_percent_24h': change,
                    'updated_at': datetime.now()
                }
            )
