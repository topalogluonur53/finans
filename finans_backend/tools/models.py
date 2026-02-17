from django.db import models
from django.conf import settings

class Note(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notes')
    asset = models.ForeignKey('portfolio.Asset', on_delete=models.CASCADE, related_name='asset_notes', blank=True, null=True)
    title = models.CharField(max_length=200, blank=True)
    content = models.TextField()
    is_general = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} - Note - {self.title or 'No Title'}"

class LoanCalculation(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='loan_calculations')
    principal = models.DecimalField(max_digits=15, decimal_places=2)
    interest_rate_annual = models.DecimalField(max_digits=5, decimal_places=2)
    months = models.PositiveIntegerField()
    calculated_at = models.DateTimeField(auto_now_add=True)
    
    # Optional: store result summary for quick access
    monthly_payment = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    total_payment = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} - Loan {self.principal}"
