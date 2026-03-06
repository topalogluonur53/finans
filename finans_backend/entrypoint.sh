#!/bin/sh
# Ensure data directory exists
mkdir -p /app/data
# Create the directory for the SQLite database if it's set
if [ -n "$SQLITE_DB_PATH" ]; then
    mkdir -p $(dirname "$SQLITE_DB_PATH")
fi

# Apply database migrations
python manage.py migrate --noinput

# Collect static files
python manage.py collectstatic --noinput

# Start gunicorn
exec gunicorn config.wsgi:application --bind 0.0.0.0:2223 --workers 3

