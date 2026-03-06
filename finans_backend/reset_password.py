
import os
import django

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()
username = '5368977153'
new_password = '123456' # Basit bir test şifresi, kullanıcı bunu her zaman değiştirebilir.

try:
    user = User.objects.get(username=username)
    user.set_password(new_password)
    user.save()
    print(f"[OK] {username} kullanıcısının şifresi başarıyla '{new_password}' olarak güncellendi.")
except User.DoesNotExist:
    print(f"[HATA] {username} kullanıcısı bulunamadı.")
except Exception as e:
    print(f"[HATA] Bir hata oluştu: {e}")
