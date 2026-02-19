from celery import shared_task
from .services import update_market_from_yahoo
from .models import MarketData, Alarm
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

@shared_task
def update_market_data():
    """
    Periodic task to update market data and check alarms.
    Runs every 5 minutes (configured in settings).
    """
    # 1. Update prices from Yahoo
    update_market_from_yahoo()
    
    # 2. Check and trigger alarms
    check_alarms()
    
    return "Market data and alarms processed successfully."

def check_alarms():
    """
    Checks each active alarm against the latest market data.
    If condition is met, triggers the alarm and deactivates it.
    """
    active_alarms = Alarm.objects.filter(is_active=True)
    
    for alarm in active_alarms:
        try:
            market_item = MarketData.objects.get(symbol=alarm.symbol)
            triggered = False
            
            if alarm.condition == '>' and market_item.price >= alarm.target_price:
                triggered = True
            elif alarm.condition == '<' and market_item.price <= alarm.target_price:
                triggered = True
            
            if triggered:
                alarm.is_active = False
                alarm.triggered_at = timezone.now()
                alarm.save()
                
                # Log to admin/console
                msg = f"ALARM TETİKLENDİ: {alarm.user.username} - {alarm.symbol} fiyatı {market_item.price} oldu! (Hedef: {alarm.target_price})"
                logger.info(msg)
                print(msg)
                
                # Optional: Send Email (Console backend usually)
                try:
                    send_mail(
                        'Piyasa Alarmı Tetiklendi!',
                        msg,
                        settings.DEFAULT_FROM_EMAIL,
                        [alarm.user.email],
                        fail_silently=True,
                    )
                except Exception as e:
                    logger.error(f"Email sending failed for alarm {alarm.id}: {str(e)}")
                    
        except MarketData.DoesNotExist:
            logger.warning(f"Alarm for symbol {alarm.symbol} skipped: symbol not found in MarketData.")
            continue
        except Exception as e:
            logger.error(f"Error processing alarm {alarm.id}: {str(e)}")
