# Halka Arz (IPO) Sayfası

## 📈 Özellikler

### Gerçek Zamanlı IPO Verileri
- **Financial Modeling Prep API** entegrasyonu
- **IEX Cloud API** yedek veri kaynağı
- Ücretsiz API tier kullanımı (günlük limit: 250 istek)

### İki Ana Kategori
1. **📅 Yaklaşan Halka Arzlar**
   - Önümüzdeki 90 gün içinde gerçekleşecek IPO'lar
   - Fiyat aralığı tahminleri
   - Planlanan tarihler

2. **📊 Son 30 Gün**
   - Geçtiğimiz 30 gündeki halka arzlar
   - Kesin fiyatlandırma bilgileri
   - Gerçekleşen tarihler

### Gösterilen Bilgiler
- ✅ Şirket adı ve sembolü
- ✅ Borsa (NASDAQ, NYSE, vb.)
- ✅ Halka arz tarihi
- ✅ Fiyat aralığı (yaklaşan için)
- ✅ Kesin fiyat (gerçekleşenler için)
- ✅ Toplam hisse sayısı
- ✅ Durum göstergesi (Yaklaşan/Fiyatlandı/İptal)

## 🔧 Teknik Detaylar

### API Entegrasyonu

#### 1. Financial Modeling Prep (Birincil)
```
Endpoint: https://financialmodelingprep.com/api/v3/ipo_calendar
API Key: Demo key (değiştirilebilir)
Rate Limit: 250 requests/day (ücretsiz)
```

#### 2. IEX Cloud (Yedek)
```
Endpoint: https://cloud.iexapis.com/stable/stock/market/upcoming-ipos
Token: Demo token (değiştirilebilir)
Rate Limit: Varies by plan
```

### Dosya Yapısı
```
lib/
├── data/
│   ├── models/
│   │   └── ipo.dart                    # IPO veri modeli
│   └── services/
│       └── ipo_service.dart            # API servisi
└── presentation/
    └── screens/
        └── tools/
            ├── tools_screen.dart        # Araçlar ana menüsü (güncellendi)
            └── ipo_screen.dart          # IPO ekranı
```

### Fallback Sistemi
API'ler erişilemez olduğunda demo veriler gösterilir:
- 3 örnek IPO
- Gerçek veri formatında
- Test amaçlı

## 🚀 Kullanım

### Erişim
1. Alt menüden **"Araçlar"** sekmesine gidin
2. **"Halka Arz (IPO)"** kartına tıklayın
3. İki sekme arasında geçiş yapın:
   - Yaklaşan
   - Son 30 Gün

### Detay Görüntüleme
- Herhangi bir IPO kartına tıklayın
- Alt modal açılır
- Tüm detayları görün
- Varsa resmi web sitesine gidin

### Yenileme
- **Pull-to-Refresh**: Aşağı çekerek
- **Manuel**: Sağ üst köşedeki yenile butonu

## 🔑 API Key Yapılandırması

### Financial Modeling Prep
1. [financialmodelingprep.com](https://financialmodelingprep.com) adresinden ücretsiz hesap oluşturun
2. API key alın
3. `lib/data/services/ipo_service.dart` dosyasında güncelleyin:
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

### IEX Cloud (Opsiyonel)
1. [iexcloud.io](https://iexcloud.io) adresinden hesap oluşturun
2. Token alın
3. `lib/data/services/ipo_service.dart` dosyasında güncelleyin:
```dart
static const String _iexToken = 'YOUR_TOKEN_HERE';
```

## ⚠️ Önemli Notlar

1. **Demo Mode**: API key'ler "demo" olarak ayarlıysa, sınırlı veri gelir
2. **Rate Limiting**: Ücretsiz tier kullanıyorsanız günlük limit vardır
3. **Veri Doğruluğu**: Yatırım kararları için resmi kaynaklardan doğrulama yapın
4. **İnternet Bağlantısı**: Canlı veri için internet gereklidir

## 📱 Ekran Görüntüleri

### Ana Ekran
- İki sekme (Yaklaşan / Son 30 Gün)
- Kart bazlı liste görünümü
- Durum göstergeleri (renkli badge'ler)

### Detay Modal
- Şirket bilgileri
- Tüm IPO detayları
- Harici link butonu

## 🔮 Gelecek İyileştirmeler

- [ ] Favori IPO'lar
- [ ] Bildirim sistemi (yaklaşan IPO'lar için)
- [ ] Filtreleme (borsa, fiyat aralığı, vb.)
- [ ] Arama fonksiyonu
- [ ] Tarihsel IPO verileri
- [ ] Performans grafikleri (IPO sonrası)
- [ ] Sektör bazlı gruplama
- [ ] Türk borsası (BIST) entegrasyonu

## 📚 Kaynaklar

- [Financial Modeling Prep API Docs](https://site.financialmodelingprep.com/developer/docs)
- [IEX Cloud API Docs](https://iexcloud.io/docs/api/)
- [Flutter url_launcher Package](https://pub.dev/packages/url_launcher)
