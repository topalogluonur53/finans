
import os
import django

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

print("Mevcut Kullanıcılar:")
for user in User.objects.all():
    print(f"Username: {user.username}, Email: {user.email}, Name: {user.first_name} {user.last_name}")
