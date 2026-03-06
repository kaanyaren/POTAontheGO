# POTA on the GO - Mimari Tasarım Belgesi

## 1. Giriş
Bu belge, Parks on the Air (POTA) platformu için geliştirilecek olan "POTA on the GO" adlı Android ve iOS mobil istemcisinin mimari yapısını, teknoloji yığınını ve veri akışı stratejilerini tanımlar. Dokümantasyondaki API verileri referans alınarak tasarlanmıştır.

## 2. Teknoloji Yığını (Technology Stack)

Uygulamanın hem iOS hem de Android'de maksimum performans ve stabilite ile çalışabilmesi için **Flutter** ekosistemi seçilmiştir. Buna göre belirlenmiş teknoloji yığını aşağıdadır:

*   **Mobil Çerçeve (Framework):** **Flutter** (Dart). Tek kod tabanı ile iOS ve Android'de native'e yakın harita ve liste performansı sunar. Geliştirme hızı ve zengin UI kütüphanesi ile çapraz platform için en uygun çözümdür.
*   **Ağ (Networking):** **Dio**. HTTP istekleri için gelişmiş, interceptor (araya girme), timeout ve hata yönetimi özellikleri sunan en popüler ve güçlü Flutter ağ paketidir.
*   **Durum Yönetimi (State Management):** **Riverpod**. Güvenli bağımlılık enjeksiyonu ve derleme zamanı (compile-time) hataları yakalama yetenekleri sunan, test edilebilirliği yüksek ve performansı mükemmel bir modern durum yönetim paketidir.
*   **Yerel Veritabanı (Local Storage):** **Isar Database**. Dart ve Flutter için özel olarak uçtan uca yazılmış, SQLite'a göre devasa veri setlerinde (Örn: POTA'nın tüm park listesi) çok daha hızlı (NoSQL) çalışan, asenkron ve yüksek performanslı bir veritabanı çözümüdür. Doğada çevrimdışı kullanım senaryosu için kritik bir rol oynayacaktır.
*   **Harita Entegrasyonu:** **flutter_map**. OpenStreetMap tabanlı olması ve çevrimdışı harita katmanlarını (offline map tiles) destekleme esnekliği sayesinde, internetin çekmediği kamp ve POTA aktivasyon alanlarında büyük avantaj sağlar.

## 3. Mimari Desen (Architecture Pattern)

Uygulamanın sürdürülebilir olması için **Clean Architecture (Temiz Mimari)** ve **MVVM (Model-View-ViewModel)** desenlerinin birleşimi kullanılmalıdır.

*   **Presentation Layer (Sunum Katmanı):** UI bileşenleri ve View bileşenleri. İş mantığı içermez, sadece veriyi gösterir ve kullanıcı etkileşimlerini alır.
*   **Domain Layer (Etki Alanı Katmanı):** Uygulamanın temel iş kuralları (Use Case'ler), Entity'ler (Spot, Park, Activation modelleri) burada tanımlanır.
*   **Data Layer (Veri Katmanı):**
    *   **Remote Data Source:** `api.pota.app` uç noktaları ile iletişim kurar (Spotlar, geçmiş aktivasyonlar).
    *   **Local Data Source:** Cihazdaki veritabanı. Çevrimdışı desteği sağlar (Tüm park listesi, favoriler).
    *   **Repository:** Verinin nereden (Remote veya Local) geleceğine karar veren ve Domain katmanına temiz veriyi sağlayan soyutlama katmanı.

## 4. Veri Yönetimi ve Senkronizasyon Stratejisi

POTA API dokümantasyonunda da belirtildiği üzere, uygulamanın veri akışı iki ana koldan ilerlemelidir:

### 4.1. Statik/Büyük Veriler (Park Listesi)
Tüm POTA referanslarının listesi, her seferinde API'den çekilmek yerine **Offline-First (Önce Çevrimdışı)** stratejisi ile yönetilmelidir:
1.  **Senkronizasyon (Sync):** Uygulama ilk açıldığında veya periyodik olarak arka planda `https://pota.app/all_parks_ext.csv` dosyası indirilir.
2.  **Ayrıştırma ve Kayıt:** İndirilen CSV dosyası parse edilerek uygulamanın yerel veritabanına kaydedilir.
3.  **Kullanım:** Kullanıcı haritada park aradığında veya park isimlerini listelerken sorgular **sadece yerel veritabanı üzerinden** anlık olarak çalışır. Bu sayede API gereksiz yere yorulmaz ve doğadayken internet kopukluklarından etkilenilmez.

### 4.2. Dinamik/Anlık Veriler (Spotlar ve Aktivasyonlar)
Anlık değişen veriler (Spotlar ve geçmiş aktivasyon istatistikleri) doğası gereği doğrudan API üzerinden çekilmelidir:
*   `GET https://api.pota.app/spot/` -> Ana sayfada "Güncel Spotlar" sekmesinde gösterilir. Kullanıcı sayfayı yeniledikçe (Pull-to-refresh) API'den güncel veri talep edilir.
*   `GET https://api.pota.app/park/activations/{park_referansı}` -> Kullanıcı yerel veritabanındaki bir parka tıkladığında, o parkın detay sayfasında API'den anlık olarak o parkın geçmiş aktivasyon bilgisi çekilip gösterilir.

## 5. Uygulama Modülleri ve Ekranlar

1.  **Güncel Spotlar (Spots) Ekranı:**
    *   Şu an aktif olan radyo amatörlerinin (activators) listesi.
    *   Mod (CW, SSB vs.), frekans ve banda göre filtreleme seçenekleri.
2.  **Harita ve Park Bulucu (Map & Parks) Ekranı:**
    *   Yerel veritabanındaki parkların harita üzerinde konumlarına göre pin/işaretçi olarak gösterilmesi.
    *   "Çevremdeki Parklar" özelliği (Konum tabanlı).
3.  **Park Detay Ekranı:**
    *   Parkın genel bilgileri (isim, referans kodu, bölge).
    *   API'den o an çekilecek olan özel istatistikler ve geçmiş aktivasyon listesi.
4.  **Favoriler / Ayarlar:**
    *   Kullanıcının sık takip ettiği park referanslarını favorilemesi (Local Database üzerinden).
    *   API'yi yormadan CSV veri senkronizasyonunu başlatma/durdurma ayarları.

## 6. Sonuç ve Özet
Bu mimari sayesinde "POTA on the GO", **Spotlar için anlık ve senkron çalışırken**, **Park listesi gibi devasa veriler için kotayı tüketmeyen, API sınırlarına takılmayan ve çevrimdışı (doğa koşullarında) hayat kurtaran** kullanıcı dostu, modüler ve yüksek performanslı bir mobil istemci olacaktır.
