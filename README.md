# Kişisel Finans & Yatırım Takip Uygulaması (MVP)

Bu proje Flutter (Frontend) ve Django REST Framework (Backend) kullanılarak geliştirilmiştir.

## Kurulum ve Çalıştırma

### 1. Backend (Django)

1. `finans_backend` klasörüne gidin:
   ```bash
   cd finans_backend
   ```
2. Sanal ortam (venv) oluşturun ve aktif edin (Opsiyonel ama önerilir):
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # Mac/Linux:
   source venv/bin/activate
   ```
3. Gerekli paketleri yükleyin:
   ```bash
   pip install django djangorestframework djangorestframework-simplejwt django-cors-headers requests
   ```
   *(Not: `requirements.txt` dosyası oluşturulmadıysa yukarıdaki paketleri manuel yükleyin.)*

4. Veritabanı Migrations işlemlerini yapın:
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```
5. Superuser (Yönetici) oluşturun:
   ```bash
   python manage.py createsuperuser
   ```
6. Sunucuyu başlatın:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```
   API adresi: `http://127.0.0.1:8000/api/`

### 2. Frontend (Flutter)

1. `finans_app` klasörüne gidin:
   ```bash
   cd ../finans_app
   ```
2. Paketleri yükleyin:
   ```bash
   flutter pub get
   ```
3. Uygulamayı başlatın (Android Emulator veya Cihaz):
   ```bash
   flutter run
   ```

**Not:** Eğer Android Emulator kullanıyorsanız, API adresi `http://10.0.2.2:8000` olarak ayarlanmıştır (`lib/core/constants/api_constants.dart`). Eğer iOS veya Web kullanacaksanız bu adresi `localhost` veya makinenizin IP adresi olarak güncelleyin.

## Özellikler

- **Auth**: Kayıt ve Giriş (JWT).
- **Portföy**: Varlıkların listesi, toplam değer, canlı fiyatlar (mock verisi ile simüle edilmiştir).
- **Finans**: Gelir/Gider (UI iskeleti hazır).
- **Araçlar**: Notlar ve Kredi Hesaplama (UI iskeleti hazır).
