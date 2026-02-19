from rest_framework import serializers
from .models import MarketData, Alarm

class MarketDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = MarketData
        fields = [
            'id', 'symbol', 'name', 'price', 'price_change_24h', 
            'change_percent_24h', 'market_type', 'open_price', 
            'day_high', 'day_low', 'volume', 'is_index', 'parent_symbol', 'updated_at'
        ]
        read_only_fields = ('updated_at',)

class AlarmSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alarm
        fields = '__all__'
        read_only_fields = ('user', 'triggered_at', 'created_at')
