from django.db import models
from django.conf import settings

ASSET_TYPES = [
    ('GOLD_GRAM', 'Gram Altın'),
    ('GOLD_QUARTER', 'Çeyrek Altın'),
    ('GOLD_HALF', 'Yarım Altın'),
    ('GOLD_FULL', 'Tam Altın'),
    ('SILVER_GRAM', 'Gram Gümüş'),
    ('PLATINUM_GRAM', 'Gram Platin'),
    ('PALLADIUM_GRAM', 'Gram Paladyum'),
    ('CRYPTO_BTC', 'Bitcoin'),
    ('CRYPTO_ETH', 'Ethereum'),
    ('CRYPTO_SOL', 'Solana'),
    ('CRYPTO_BNB', 'Binance Coin'),
    ('CRYPTO_XRP', 'Ripple'),
    ('CURRENCY_USD', 'Dolar'),
    ('CURRENCY_EUR', 'Euro'),
    ('CURRENCY_GBP', 'Sterlin'),
    ('CURRENCY_JPY', 'Japon Yeni'),
    ('CURRENCY_CHF', 'İsviçre Frangı'),
    ('STOCK', 'Hisse Senedi'),
]

class Asset(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='assets')
    type = models.CharField(max_length=20, choices=ASSET_TYPES)
    name = models.CharField(max_length=100) # e.g. "Bitcoin", "Apple Stock", "Gram Altın"
    symbol = models.CharField(max_length=20, blank=True, null=True) # BTC, AAPL
    quantity = models.DecimalField(max_digits=20, decimal_places=8)
    purchase_price = models.DecimalField(max_digits=20, decimal_places=2) # Per unit price
    purchase_date = models.DateTimeField()
    notes = models.TextField(blank=True, null=True)
    tag = models.CharField(max_length=50, blank=True, null=True) # Etiket
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.quantity})"

class Transaction(models.Model):
    TRANSACTION_TYPES = [
        ('BUY', 'Alış'),
        ('SELL', 'Satış'),
    ]
    asset = models.ForeignKey(Asset, on_delete=models.CASCADE, related_name='transactions')
    type = models.CharField(max_length=4, choices=TRANSACTION_TYPES)
    quantity = models.DecimalField(max_digits=20, decimal_places=8)
    price = models.DecimalField(max_digits=20, decimal_places=2) # Price per unit at transaction time
    date = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.asset.name} - {self.type} - {self.quantity}"
