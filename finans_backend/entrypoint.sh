#!/bin/sh
# Apply database migrations
python manage.py migrate --noinput

# Collect static files
python manage.py collectstatic --noinput

# Start gunicorn
exec gunicorn config.wsgi:application --bind 0.0.0.0:2223 --workers 3
