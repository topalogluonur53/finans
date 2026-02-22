from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from market.models import MarketData
from .models import Asset, Transaction
from .serializers import AssetSerializer, TransactionSerializer
from decimal import Decimal
import random

# MOCK PRICE SERVICE - Still here as fallback but preferred is MarketData
def get_current_price(asset_type, symbol):
    # Try to find symbol in MarketData
    lookup_symbol = symbol if symbol else ''
    
    # Mapping Asset Type to Market Symbol if needed
    type_map = {
        'GOLD_GRAM': 'GRAM-ALTIN',
        'GOLD_QUARTER': 'CEYREK-ALTIN',
        'GOLD_HALF': 'YARIM-ALTIN',
        'GOLD_FULL': 'TAM-ALTIN',
        'SILVER_GRAM': 'GRAM-GUMUS',
        'PLATINUM_GRAM': 'GRAM-PLATIN',
        'PALLADIUM_GRAM': 'GRAM-PALADYUM',
        'CRYPTO_BTC': 'BTCUSDT',
        'CRYPTO_ETH': 'ETHUSDT',
        'CRYPTO_SOL': 'SOLUSDT',
        'CRYPTO_BNB': 'BNBUSDT',
        'CRYPTO_XRP': 'XRPUSDT',
        'CURRENCY_USD': 'USDTRY=X',
        'CURRENCY_EUR': 'EURTRY=X',
        'CURRENCY_GBP': 'GBPTRY=X',
        'CURRENCY_JPY': 'JPYTRY=X',
        'CURRENCY_CHF': 'CHFTRY=X',
    }
    
    target_symbol = type_map.get(asset_type, lookup_symbol)
    
    try:
        if target_symbol:
            md = MarketData.objects.filter(symbol=target_symbol).first()
            if md:
                return float(md.price)
    except:
        pass

    # Fallback to older mock logic if still relevant
    if 'GOLD' in asset_type: return 2000.0 + random.uniform(-50, 50)
    if 'BTC' in (symbol or '') or 'BTC' in asset_type: return 40000.0 + random.uniform(-1000, 1000)
    if 'ETH' in (symbol or '') or 'ETH' in asset_type: return 2500.0 + random.uniform(-100, 100)
    if 'USD' in (symbol or '') or 'USD' in asset_type: return 30.0 + random.uniform(-1, 1)
    return 100.0

class AssetViewSet(viewsets.ModelViewSet):
    serializer_class = AssetSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Asset.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=True, methods=['get'])
    def summary(self, request, pk=None):
        asset = self.get_object()
        current_price = get_current_price(asset.type, asset.symbol or '')
        purchase_value = float(asset.quantity * asset.purchase_price)
        current_value = float(asset.quantity) * current_price
        
        profit_loss = current_value - purchase_value
        profit_loss_percent = (profit_loss / purchase_value * 100) if purchase_value != 0 else 0
        
        return Response({
            'current_price': current_price,
            'current_value': current_value,
            'original_value': purchase_value,
            'profit_loss': profit_loss,
            'profit_loss_percent': profit_loss_percent
        })

class TransactionViewSet(viewsets.ModelViewSet):
    serializer_class = TransactionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Only transactions for user's assets
        return Transaction.objects.filter(asset__user=self.request.user)
    
    def perform_create(self, serializer):
        transaction = serializer.save()
        asset = transaction.asset
        
        if transaction.type == 'BUY':
            # Weighted Average Cost Calculation
            # New Price = ((Old Qty * Old Price) + (New Qty * New Price)) / (Old Qty + New Qty)
            current_total_cost = asset.quantity * asset.purchase_price
            new_cost = transaction.quantity * transaction.price
            total_qty = asset.quantity + transaction.quantity
            
            if total_qty > 0:
                asset.purchase_price = (current_total_cost + new_cost) / total_qty
            
            asset.quantity += transaction.quantity
            
        elif transaction.type == 'SELL':
            # For SELL, average cost (purchase_price) doesn't change, only quantity
            asset.quantity -= transaction.quantity
            
        asset.save()
