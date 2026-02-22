from django.contrib import admin
from .models import MarketData, Alarm


@admin.register(MarketData)
class MarketDataAdmin(admin.ModelAdmin):
    list_display = ('symbol', 'name', 'price', 'change_percent_24h', 'market_type', 'is_index', 'updated_at')
    list_filter = ('market_type', 'is_index')
    search_fields = ('symbol', 'name')
    ordering = ('market_type', 'symbol')
    readonly_fields = ('updated_at',)


@admin.register(Alarm)
class AlarmAdmin(admin.ModelAdmin):
    list_display = ('user', 'symbol', 'condition', 'target_price', 'is_active', 'triggered_at', 'created_at')
    list_filter = ('is_active', 'condition')
    search_fields = ('user__username', 'symbol')
    ordering = ('-created_at',)
    readonly_fields = ('triggered_at', 'created_at')
