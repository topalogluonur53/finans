from django.db import models

class MarketData(models.Model):
    symbol = models.CharField(max_length=20, unique=True, db_index=True)
    name = models.CharField(max_length=100, blank=True, null=True)
    price = models.DecimalField(max_digits=20, decimal_places=8)
    change_percent_24h = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.symbol}: {self.price}"
