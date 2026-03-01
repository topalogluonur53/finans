
import os
import django

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

print("Kullanıcı Detayları:")
for user in User.objects.all():
    print(f"Username: {user.username}")
    print(f"  Email: {user.email}")
    print(f"  First Name: {user.first_name}")
    print(f"  Last Name: {user.last_name}")
    print(f"  Is Active: {user.is_active}")
    print(f"  Is Staff: {user.is_staff}")
    print("-" * 20)
