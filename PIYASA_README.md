# Piyasa Sayfası - CoinGecko Entegrasyonu

## 📊 Özellikler

### Canlı Piyasa Takibi
- **Kripto Paralar**: Bitcoin, Ethereum, Solana ve daha fazlası (Top 20)
- **Emtia**: Altın, Gümüş (tokenize edilmiş versiyonlar)
- **Döviz**: USD, EUR (stablecoin'ler üzerinden)

### Gösterilen Bilgiler
- Anlık fiyat (USD)
- 24 saatlik değişim (%)
- 24 saatlik değişim (tutar)
- Varlık logosu/ikonu
- Trend göstergesi (yukarı/aşağı ok)

### Kullanıcı Deneyimi
- **3 Sekme**: Kripto, Emtia, Döviz
- **Pull-to-Refresh**: Aşağı çekerek yenile
- **Manuel Yenileme**: AppBar'daki yenile butonu
- **Hata Yönetimi**: Bağlantı hatalarında kullanıcı dostu mesajlar

## 🔧 Teknik Detaylar

### Dosya Yapısı
```
lib/
├── data/
│   ├── models/
│   │   └── market_price.dart          # Piyasa fiyat modeli
│   └── services/
│       └── coingecko_service.dart     # CoinGecko API servisi
└── presentation/
    └── screens/
        └── market/
            └── market_screen.dart      # Piyasa ekranı UI
```

### API Kullanımı
- **Endpoint**: CoinGecko Public API v3
- **Rate Limit**: Ücretsiz tier (50 calls/minute)
- **Veri Formatı**: JSON
- **Güncelleme**: Manuel (kullanıcı tetiklemeli)

### Kategoriler
1. **Kripto** (`crypto`): Top 20 kripto para
2. **Emtia** (`commodity`): PAX Gold, Tether Gold, Silver
3. **Döviz** (`currency`): USDT, USDC, DAI, TUSD, EUROC

## 🚀 Kullanım

### Alt Menüden Erişim
1. Ana ekranın alt menüsünde **"Piyasa"** sekmesine tıklayın
2. İstediğiniz kategoriyi seçin (Kripto/Emtia/Döviz)
3. Listeyi görüntüleyin
4. Yenilemek için aşağı çekin veya yenile butonuna basın

### Veri Güncelleme
- Sayfa her açıldığında otomatik yüklenir
- Manuel yenileme için:
  - Aşağı çekme hareketi
  - Sağ üst köşedeki yenile ikonu

## 📝 Notlar

- CoinGecko ücretsiz API kullanıldığı için rate limit vardır
- Emtia ve döviz verileri tokenize edilmiş versiyonlar üzerinden gelir
- Gerçek zamanlı değil, API çağrısı anında güncel veridir
- İnternet bağlantısı gereklidir

## 🔮 Gelecek İyileştirmeler

- [ ] Otomatik yenileme (30 saniye/1 dakika)
- [ ] Favori varlıklar
- [ ] Fiyat alarmları
- [ ] Grafik görünümü
- [ ] Daha fazla varlık kategorisi (hisse senetleri vb.)
- [ ] Arama fonksiyonu
- [ ] Detay sayfası (tarihsel veriler, grafikler)
