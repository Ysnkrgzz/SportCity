# Flutter Projesi
![İstinye Üniversitesi](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPDx-F-jg4WHeC9IQEykC41ZIMYOTQNJo5RQ&s)

## Proje Hakkında
[SportCity insanların, kişisel gelişimini yapmak istediği alışveriş için kurulan bir mobil uygulamadır, amacı insanların uygulama içerisinde spor eşyaları, spor içecekleri, antrenman eşyaları gibi ürünleri satın alması için kuruldu]

## Ekibimiz
- **Danışman:** Keyvan Arasteh(https://github.com/keyvanarasteh)
- **Takım Lideri** Yasin KARAGÖZ [Github](https://github.com/Ysnkrgzz)
- **Takım Üyeleri:**
    - Yusuf Taha ORHAN [Github](https://github.com/yusuforhan000)
    - Beyza AKKILIÇ [Github](https://github.com/Beyzakkilic)


## Özellikler 
- [Kolay kullanım]
- [Güvenli alışveriş]
- [Gözleri yormayacak uygun renk paleti]

## Kullanılan Teknolojiler
- Flutter
- Firebase
- Dart
- Node.js backend
- Http API

### Gereksinimler
- Min SDK android versiyon 21
- Flutter SDK (sürüm ^3.5.4)
- Dart SDK (sürüm 3.5.4)
- Shared Preferences (sürüm 2.3.5)
- cupertino_icons (sürüm 1.0.8)
- flutter_secure_storage: (sürüm 9.2.2)
- go_router: (sürüm 14.6.1)      
- shared_preferences: (sürüm 2.3.5)     # Basit veri depolama için
- dotlottie_loader: (sürüm 0.0.4)
- lottie: (sürüm 3.2.0)
- firebase_core: (sürüm 2.27.1)
- firebase_auth: (sürüm 4.17.9)
- cloud_firestore: (sürüm 4.15.9)
- http: (sürüm 1.2.0)
- cached_network_image: (sürüm 3.3.1)
- path_provider: (sürüm 2.1.2)
- flutter_dotenv: (sürüm 5.2.1)
- provider: (6.1.1)

### Kurulum Adımları
1. Projeyi bilgisayarınıza indirin:
```bash
git clone [https://github.com/Ysnkrgzz/SportCity.git]
```
2. Proje Klasörüne gidin: 
```bash
cd [SportCity]
```
3. Gerekli paketleri yükleyin
```bash
flutter pub get
```
4. lib\services klasöründeki api.dart dosyasında ip adresini güncelleyin
```bash
cd [lib/services/api.dart]
```
5. Uygulamayı Başlatın
```bash
flutter run
```

# Proje Yapısı
```
lib/
|--core/            #Veri modelleri
|--screens/         #Uygulama ekranları
|--services/        #API servisleri
|--yardımcılar/     #Yardımcı fonksiyonlar
|--auth/            #Doğrulama fonksiyonları
```

## Ekran Görüntüleri
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/1-Loading.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/2-Login.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/3-%C5%9Eifre%20S%C4%B1f%C4%B1rlama.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/4-AnaMenu.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/5-Arama.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/6-Sepetim.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/7-AdminGiris.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/8-UrunYonetim.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/9-UrunDuzenle.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/10-KategoriYonetim.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/11-Siparisler.png" width="200" height="400" />
<img src="https://github.com/Ysnkrgzz/SportCity/blob/f0ed8384a4738627c144946234cc6c2cd16fd68f/EkranGoruntuleri/11-SiparislerDetay.png" width="200" height="400" />


## Projeye Katkı Sağlama
1. Projeyi Forklayın
2. Yeni bir yan dal oluşturun (`git checkout -b ozellik/YeniOzellik`)
3. Değişiklerinizi kaydedin (`git commit -m Yeni Özellik Eklendi.`)
4. Dalınıza gönderin (`git push origin ozellik/YeniOzellik`)
5. Pull Request Oluşturun

## İletişim
- Proje bağlantısı: https://github.com/Ysnkrgzz/SportCity.git
- İstinye Üniversitesi: https://www.istinye.edu.tr/

## Teşekkürler
- Projeyi Yapmamızda yardımcı olan Yusuf Taha ORHAN, Beyza Fatma AKKILIÇ'a teşşekkür ederiz.
