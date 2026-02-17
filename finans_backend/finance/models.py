from django.db import models
from django.conf import settings

class Income(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='incomes')
    category = models.CharField(max_length=100)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.TextField(blank=True, null=True)
    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - Income - {self.category} - {self.amount}"

class Expense(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='expenses')
    category = models.CharField(max_length=100)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.TextField(blank=True, null=True)
    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - Expense - {self.category} - {self.amount}"

class Budget(models.Model):
    PERIOD_CHOICES = [
        ('MONTHLY', 'Aylık'),
        ('YEARLY', 'Yıllık'),
    ]
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='budgets')
    category = models.CharField(max_length=100)
    limit = models.DecimalField(max_digits=12, decimal_places=2)
    period = models.CharField(max_length=10, choices=PERIOD_CHOICES, default='MONTHLY')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - Budget - {self.category} - {self.limit}"
