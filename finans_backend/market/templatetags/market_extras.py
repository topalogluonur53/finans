from django import template

register = template.Library()

@register.filter
def format_volume(value):
    if not value:
        return "0"
    try:
        if value >= 1_000_000_000:
            return f"{value / 1_000_000_000:.1f}B"
        if value >= 1_000_000:
            return f"{value / 1_000_000:.1f}M"
        if value >= 1_000:
            return f"{value / 1_000:.1f}K"
        return str(value)
    except:
        return str(value)

@register.filter
def price_progress(price, args):
    """
    Usage: {{ item.price|price_progress:"low,high" }}
    Wait, filter only takes one arg. I'll pass a string or use model method.
    Let's handle it by passing a combined string or just calculate in view.
    Actually, I'll change the template to pass low and high.
    """
    return 50 # Fallback

@register.simple_tag
def get_price_percentage(current, low, high):
    try:
        if not current or not low or not high or high == low:
            return 50
        percentage = ((float(current) - float(low)) / (float(high) - float(low))) * 100
        return max(0, min(100, percentage))
    except:
        return 50
