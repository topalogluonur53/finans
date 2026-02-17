from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Asset, Transaction
from .serializers import AssetSerializer, TransactionSerializer
import random # Mock price for now

# MOCK PRICE SERVICE
def get_current_price(asset_type, symbol):
    # In real app, call Market Service or External API
    # Mock prices:
    if 'GOLD' in asset_type: return 2000.0 + random.uniform(-50, 50)
    if 'BTC' in symbol or 'BTC' in asset_type: return 40000.0 + random.uniform(-1000, 1000)
    if 'ETH' in symbol or 'ETH' in asset_type: return 2500.0 + random.uniform(-100, 100)
    if 'USD' in symbol or 'USD' in asset_type: return 30.0 + random.uniform(-1, 1)
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
        purchase_value = asset.quantity * asset.purchase_price
        current_value = asset.quantity * current_price # This assumes quantity is preserved. But transactions change quantity?
        # IMPORTANT: Asset model has 'quantity'. Logic assumes quantity is current holding.
        
        profit_loss = current_value - purchase_value
        profit_loss_percent = (profit_loss / purchase_value * 100) if purchase_value != 0 else 0
        
        return Response({
            'current_price': current_price,
            'current_value': current_value,
            'original_value': purchase_value, # based on purchase_price field, might be avg cost
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
        # When transaction is created, should we update Asset quantity?
        # The requirement didn't specify, but usually yes.
        transaction = serializer.save()
        asset = transaction.asset
        if transaction.type == 'BUY':
            # Logic for AVG Price calculation could go here
            # For MVP, just update quantity?
            # Or assume Asset.quantity is updated manually?
            # Creating a transaction implies change in asset.
            # Let's keep it simple: manual update or auto update.
            # I will implement auto update of quantity.
            asset.quantity += transaction.quantity
        elif transaction.type == 'SELL':
            asset.quantity -= transaction.quantity
        asset.save()
