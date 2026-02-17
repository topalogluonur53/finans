from rest_framework import serializers
from .models import MarketData

class MarketDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = MarketData
        fields = '__all__'
        read_only_fields = ('updated_at',)
