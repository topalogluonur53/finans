from django.db import models
from django.conf import settings

class MarketData(models.Model):
    MARKET_TYPES = (
        ('commodity', 'Emtia'),
        ('stock', 'Borsa'),
        ('currency', 'Döviz'),
    )
    
    symbol = models.CharField(max_length=50, unique=True, db_index=True)
    name = models.CharField(max_length=100, blank=True, null=True)
    price = models.DecimalField(max_digits=20, decimal_places=4)
    price_change_24h = models.DecimalField(max_digits=20, decimal_places=4, null=True, blank=True)
    change_percent_24h = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    market_type = models.CharField(max_length=20, choices=MARKET_TYPES)
    
    # Gelişmiş içerik için eklenen alanlar
    open_price = models.DecimalField(max_digits=20, decimal_places=4, null=True, blank=True)
    day_high = models.DecimalField(max_digits=20, decimal_places=4, null=True, blank=True)
    day_low = models.DecimalField(max_digits=20, decimal_places=4, null=True, blank=True)
    volume = models.BigIntegerField(null=True, blank=True)
    
    # İlişkisel alanlar (Endeks - Hisse ilişkisi için)
    is_index = models.BooleanField(default=False)
    parent_symbol = models.CharField(max_length=50, null=True, blank=True, db_index=True)
    
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.symbol}): {self.price}"

class Alarm(models.Model):
    CONDITIONS = (
        ('>', 'Büyüktür'),
        ('<', 'Küçüktür'),
    )
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='market_alarms')
    symbol = models.CharField(max_length=50)
    target_price = models.DecimalField(max_digits=20, decimal_places=4)
    condition = models.CharField(max_length=1, choices=CONDITIONS)
    is_active = models.BooleanField(default=True)
    triggered_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.symbol} {self.condition} {self.target_price}"
