from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from .models import MarketData, Alarm
from .serializers import MarketDataSerializer, AlarmSerializer
from django.contrib import messages
from decimal import Decimal


# ─────────────────────────────────────
# API Views
# ─────────────────────────────────────

class MarketDataViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MarketData.objects.all().order_by('symbol')
    serializer_class = MarketDataSerializer
    permission_classes = [permissions.AllowAny]

    @action(detail=False, methods=['get'])
    def categorized(self, request):
        all_data = MarketData.objects.all()

        # Hisseler: is_index=False olanlar (bileşen hisseler)
        stocks = all_data.filter(market_type='stock', is_index=False)
        # Endeksler: is_index=True olanlar (BIST 100, S&P 500 vs.)
        indexes = all_data.filter(market_type='stock', is_index=True)
        commodities = all_data.filter(market_type='commodity')
        currencies = all_data.filter(market_type='currency')

        result = {
            'commodity': MarketDataSerializer(commodities, many=True).data,
            'stock':     MarketDataSerializer(stocks,     many=True).data,
            'index':     MarketDataSerializer(indexes,    many=True).data,
            'currency':  MarketDataSerializer(currencies, many=True).data,
        }
        return Response(result)

    @action(detail=False, methods=['get'])
    def ticker(self, request):
        data = MarketData.objects.all().values('symbol', 'price', 'change_percent_24h', 'market_type')
        return Response(list(data))


class AlarmViewSet(viewsets.ModelViewSet):
    serializer_class = AlarmSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Alarm.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        """Alarm aktif/pasif durumunu değiştirir."""
        alarm = self.get_object()
        alarm.is_active = not alarm.is_active
        alarm.save()
        return Response({'is_active': alarm.is_active}, status=status.HTTP_200_OK)

    def destroy(self, request, *args, **kwargs):
        """Alarmı siler."""
        instance = self.get_object()
        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)


# ─────────────────────────────────────
# Template Views
# ─────────────────────────────────────

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
