# CasaOS'a GitHub Üzerinden Kurulum Rehberi

Bu proje, oluşturduğunuz GitHub Actions entegrasyonu sayesinde her yeni kod eklediğinizde (push) otomatik olarak Docker Hub'a (veya GitHub Container Registry'ye) yüklenir.

Raspberry Pi üzerinde çalışan CasaOS cihazınıza projenizi GitHub aracılığıyla kolayca kurmak için aşağıdaki adımları takip edebilirsiniz. İki farklı yöntem mevcuttur:

---

## Yöntem 1: Tek Tıkla Kurulum (En Kolay)

Bu yöntemle CasaOS arayüzündeki **İçe Aktar (Import)** özelliğini kullanarak projeyi doğrudan çekebilirsiniz. Sizin için `casaos-compose.yml` adında CasaOS ile tam uyumlu ve Watchtower içeren bir dosya oluşturduk.

1. CasaOS arayüzünü (Raspberry Pi'nizin IP adresi) tarayıcınızda açın.
2. Ana penceredeki **App Store (Uygulama Mağazası)** butonuna tıklayın.
3. Sağ üst köşede bulunan **Custom Install (Özel Kurulum)** veya **Import (İçe Aktar)** seçeneğine tıklayın.
4. Açılan penceredeki Import alanına tıklayıp şu GitHub Raw linkini yapıştırın:
   ```
   https://raw.githubusercontent.com/topalogluonur53/finans-app/main/casaos-compose.yml
   ```
   *(Not: Bu linkin düzgün çalışması için `casaos-compose.yml` dosyanızı commit edip main branch'e pushlamış olmanız gerekir).*
5. Linki yapıştırıp **Submit (Gönder)** butonuna tıkladığınızda CasaOS formu projenizin ayarlarına göre dolduracaktır. (İsim, portlar vb.)
6. Tüm alanlar doldurulduktan sonra **Install (Kur)** seçeneğine tıklayarak kurulumu tamamlayın.
7. *Not:* Bu compose dosyası içerisinde Watchtower da otomatik olarak ekli durumdadır. Bu sayede siz GitHub'a yeni kod pushladığınızda ve GitHub Actions yeni imajınızı derlediğinde, Watchtower CasaOS üzerinde çalışan uygulamanızı otomatik olarak güncelleyecektir.

---

## Yöntem 2: Kendi CasaOS Uygulama Mağazanızı Oluşturma (Gelişmiş)

Eğer projenizi doğrudan CasaOS App Store listesinde uygulamanızın ikonunu ve açıklamasını görerek kurmak isterseniz, GitHub deponuzu bir "CasaOS Özel Mağaza (Third Party Appstore)" olarak bağlayabilirsiniz.

Bunun için:
1. CasaOS arayüzüne girin ve **App Store**'a tıklayın.
2. Sağdaki pencerede bulunan **Add Source (Kaynak Ekle)** veya **+** ikonuna tıklayın.
3. Çıkan kutucuğa GitHub deponuzun linkini ekleyin:
   ```
   https://github.com/topalogluonur53/finans-app
   ```
   *(DİKKAT: Bu özelliğin tam olarak çalışabilmesi için deponuzun ayarlarında bazı CasaOS AppStore kurallarına uygun klasör yapısı veya manifest dosyaları gerekebilir. Genellikle 1. yöntemi kullanmak tek bir projeyi yayınlamak için daha pratiktir).*

---

### Veritabanının Yolunu Güncelleme Hakkında Önemli Not
Eski yapılandırmanızda Django SQLite veritabanı dosya olarak (`./finans_backend/db.sqlite3`) bağlanıyordu. CasaOS'ta bunu kalıcı ve düzgün bir **Volume** haline getirdik (`finans_db_data`), böylece konteyner bir hata verip yeniden başlatıldığında veya güncellendiğinde verileriniz asla kaybolmayacaktır.

### Docker Hesabınızı Ayarlama
`.github/workflows/casaos-deployment.yml` dosyanızda şu an `DOCKER_USERNAME` ve `DOCKER_PASSWORD` GitHub Secrets üzerinden çalışacak şekilde ayarlanmış. 

Eğer Github'a henüz ayarları girmediyseniz:
1. GitHub deponuza (`finans-app`) gidin.
2. **Settings (Ayarlar)** -> **Secrets and variables** -> **Actions** yolunu izleyin.
3. **New repository secret** butonuna basarak aşağıdaki iki değişkeni ekleyin:
   - `DOCKER_USERNAME`: Docker Hub kullanıcı adınız
   - `DOCKER_PASSWORD`: Docker Hub şifreniz (veya yetkili token'ınız)

Bunu yaptıktan sonra Github'da yapacağınız herhangi bir `git push` işlemi sonucunda güncel uygulamanız otomatik olarak derlenecek, Watchtower sayesinde de Raspberry Pi cihazınızdaki eski versiyon yerini yeni versiyona bırakacaktır.
