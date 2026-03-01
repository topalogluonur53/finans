
import os
import django

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

username_to_delete = 'topalogluonur53'

try:
    user = User.objects.get(username=username_to_delete)
    user.delete()
    print(f"[OK] {username_to_delete} kullanıcısı başarıyla silindi.")
except User.DoesNotExist:
    print(f"[HATA] {username_to_delete} kullanıcısı bulunamadı.")
except Exception as e:
    print(f"[HATA] Bir hata oluştu: {e}")

print("\nGüncel Kullanıcı Listesi:")
for user in User.objects.all():
    print(f"Username: {user.username}, Email: {user.email}")
