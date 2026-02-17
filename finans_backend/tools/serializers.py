from rest_framework import serializers
from .models import Note, LoanCalculation

class NoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Note
        fields = '__all__'
        read_only_fields = ('user', 'created_at', 'updated_at')

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

class LoanCalculationSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoanCalculation
        fields = '__all__'
        read_only_fields = ('user', 'calculated_at', 'monthly_payment', 'total_payment')

    def create(self, validated_data):
        # We might want to perform calculation here or in view.
        # But if we just store, we calculate before saving.
        # Actually user wants "Calculate" logic which returns schedule.
        # This serializer is for saving the result.
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
