from rest_framework import serializers
from .models import Asset, Transaction

class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = '__all__'
        read_only_fields = ('created_at',)

class AssetSerializer(serializers.ModelSerializer):
    transactions = TransactionSerializer(many=True, read_only=True)
    
    # Optional: Calculate P/L here? Or on View?
    # View is better for dynamic market data, but Serializer is good for basic.

    class Meta:
        model = Asset
        fields = '__all__'
        read_only_fields = ('user', 'created_at', 'updated_at')

    def create(self, validated_data):
        # Assign current user
        user = self.context['request'].user
        validated_data['user'] = user
        return super().create(validated_data)
