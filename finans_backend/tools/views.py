from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Note, LoanCalculation
from .serializers import NoteSerializer, LoanCalculationSerializer
import decimal

class NoteViewSet(viewsets.ModelViewSet):
    serializer_class = NoteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Note.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class LoanCalculationViewSet(viewsets.ModelViewSet):
    serializer_class = LoanCalculationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return LoanCalculation.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def create(self, request, *args, **kwargs):
        # Calculate before creating or after?
        # If we save, we return the saved instance AND the schedule.
        # Check simple calculation first.
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Extract data for calculation
        principal = serializer.validated_data['principal']
        rate = serializer.validated_data['interest_rate_annual']
        months = serializer.validated_data['months']
        
        # Perform calculation
        result = self.calculate_loan_schedule(float(principal), float(rate), int(months))
        
        # Save instance with summary results (optional, if model supports)
        serializer.validated_data['monthly_payment'] = decimal.Decimal(result['monthly_payment'])
        serializer.validated_data['total_payment'] = decimal.Decimal(result['total_payment'])
        
        self.perform_create(serializer)
        
        # Return response with schedule
        data = serializer.data
        data['schedule'] = result['schedule']
        data['summary'] = {
            'monthly_payment': result['monthly_payment'],
            'total_payment': result['total_payment'],
            'total_interest': result['total_interest']
        }
        
        return Response(data, status=status.HTTP_201_CREATED)

    @staticmethod
    def calculate_loan_schedule(principal, annual_rate, months):
        monthly_rate = annual_rate / 12 / 100
        if monthly_rate == 0:
            monthly_payment = principal / months
        else:
            monthly_payment = principal * (monthly_rate * (1 + monthly_rate)**months) / ((1 + monthly_rate)**months - 1)
        
        total_payment = monthly_payment * months
        total_interest = total_payment - principal
        
        schedule = []
        remaining = principal
        
        for month in range(1, months + 1):
            interest = remaining * monthly_rate
            principal_payment = monthly_payment - interest
            remaining -= principal_payment
            # Fix floating point precision issues for last payment if needed, but for MVP float is okay-ish or use Decimal.
            # Using float for schedule generation is easier, but Decimal preferred for money.
            
            schedule.append({
                'month': month,
                'payment': round(monthly_payment, 2),
                'principal': round(principal_payment, 2),
                'interest': round(interest, 2),
                'remaining': round(max(0, remaining), 2)
            })
            
        return {
            'monthly_payment': round(monthly_payment, 2),
            'total_payment': round(total_payment, 2),
            'total_interest': round(total_interest, 2),
            'schedule': schedule
        }
