"""
Demo kullanıcı oluşturma scripti
Bu script demo kullanıcısını oluşturur veya günceller.
"""

import os
import django

# Django setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

def create_demo_user():
    """Demo kullanıcısını oluştur veya güncelle"""
    username = 'demo'
    email = 'demo@finans.app'
    password = '123456'
    
    # Kullanıcı zaten var mı kontrol et
    if User.objects.filter(username=username).exists():
        user = User.objects.get(username=username)
        user.set_password(password)
        user.email = email
        user.save()
        print('[OK] Demo kullanici guncellendi: {}'.format(username))
    else:
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name='Demo',
            last_name='User'
        )
        print('[OK] Demo kullanici olusturuldu: {}'.format(username))
    
    print('   Kullanici Adi: {}'.format(username))
    print('   Sifre: {}'.format(password))
    print('   E-posta: {}'.format(email))
    return user

if __name__ == '__main__':
    print('=' * 50)
    print('DEMO KULLANICI OLUŞTURMA')
    print('=' * 50)
    create_demo_user()
    print('=' * 50)
    print('Demo kullanıcı hazır!')
    print('Login ekranında "Demo Giriş (Test)" butonunu kullanabilirsiniz.')
    print('=' * 50)
