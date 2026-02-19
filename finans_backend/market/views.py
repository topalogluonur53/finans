from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import MarketData, Alarm
from .serializers import MarketDataSerializer, AlarmSerializer
from django.contrib import messages
from decimal import Decimal

# API Views
class MarketDataViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MarketData.objects.all().order_by('symbol')
    serializer_class = MarketDataSerializer
    permission_classes = [permissions.AllowAny]

    @action(detail=False, methods=['get'])
    def categorized(self, request):
        data = MarketData.objects.all()
        result = {
            'commodity': MarketDataSerializer(data.filter(market_type='commodity'), many=True).data,
            'stock': MarketDataSerializer(data.filter(market_type='stock'), many=True).data,
            'currency': MarketDataSerializer(data.filter(market_type='currency'), many=True).data,
        }
        return Response(result)

    @action(detail=False, methods=['get'])
    def ticker(self, request):
        data = MarketData.objects.all().values('symbol', 'price', 'change_percent_24h', 'market_type')
        return Response(list(data))

class AlarmViewSet(viewsets.ModelViewSet):
    queryset = Alarm.objects.all()
    serializer_class = AlarmSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Alarm.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# Template Views
def piyasa_page(request):
    """
    Renders the market page with Emtia, Borsa, and Döviz categories.
    """
    context = {
        'commodities': MarketData.objects.filter(market_type='commodity'),
        'stocks': MarketData.objects.filter(market_type='stock'),
        'currencies': MarketData.objects.filter(market_type='currency'),
        'alarms': Alarm.objects.filter(user=request.user) if request.user.is_authenticated else [],
    }
    return render(request, 'market/piyasa.html', context)

@login_required
def create_alarm(request):
    """
    Handles alarm creation from the market page.
    """
    if request.method == 'POST':
        symbol = request.POST.get('symbol')
        target_price = request.POST.get('target_price')
        condition = request.POST.get('condition')
        
        try:
            Alarm.objects.create(
                user=request.user,
                symbol=symbol,
                target_price=Decimal(target_price),
                condition=condition,
                is_active=True
            )
            messages.success(request, f"{symbol} için alarm başarıyla kuruldu.")
        except Exception as e:
            messages.error(request, f"Alarm kurulurken hata oluştu: {str(e)}")
            
    return redirect('piyasa-page')
