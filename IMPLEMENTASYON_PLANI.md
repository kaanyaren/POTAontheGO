# POTA on the GO - Multi-Agent Implementation Plan

Bu belge, "POTA on the GO" uygulamasının geliştirilmesi için birden fazla otonom yapay zeka ajanının paralel veya ardışık olarak çalışabilmesini sağlayacak şekilde modülerlere bölünmüş bir implementasyon planıdır.

## Genel Kurallar (Tüm Ajanlar İçin)
*   **Teknoloji:** Flutter (Dart), Dio, Riverpod, Isar Database, flutter_map.
*   **Bağımlılıklar:** Her modül sadece kendi sorumluluk alanından (Clean Architecture katmanından) sorumludur.
*   **İletişim:** Veri modelleri (`Entity` ve `Model` sınıfları) tüm ajanların ortak dilidir. Önce modeller oluşturulmalıdır.
*   **Dil:** Belirtilmedikçe kod mimarisi İngilizce, kullanıcı arayüzü metinleri Türkçe (veya i18n altyapısına uygun) yazılacaktır.

---

## Modül 1: Temel Kurulum ve Çekirdek Yapı (Foundation Agent)
**Görev Tanımı:** Proje iskeletinin oluşturulması, temel paketlerin eklenmesi ve Clean Architecture klasör yapısının kurulması.

**Adımlar:**
1.  `flutter create pota_on_the_go` komutu ile projeyi oluştur.
2.  `pubspec.yaml` dosyasına gerekli bağımlılıkları ekle: `flutter_riverpod`, `dio`, `isar`, `isar_flutter_libs`, `path_provider`, `flutter_map`, `latlong2`.
3.  Clean Architecture klasör yapısını oluştur:
    *   `lib/core/` (Hata yönetimi, sabitler, ağ istemcisi yapılandırması)
    *   `lib/features/` (Özellik bazlı modüller: `parks`, `spots`, `activations`)
4.  `core/network/dio_client.dart` dosyasını oluşturup temel `Dio` yapılandırmasını kur (Base URL: `https://api.pota.app/`).

---

## Modül 2: Veri Modelleri ve Yerel Veritabanı (Data Agent)
**Görev Tanımı:** Isar veritabanının yapılandırılması ve Park, Spot, Activation modellerinin oluşturulması.
*Ön Koşul: Modül 1 tamamlanmış olmalı.*

**Adımlar:**
1.  `lib/features/parks/data/models/park_model.dart` oluştur. (Alanlar: `reference` (ID), `name`, `latitude`, `longitude`, `locationDesc` - Isar Collection olarak işaretle).
2.  `lib/features/spots/data/models/spot_model.dart` oluştur. (Alanlar: `spotId`, `activator`, `frequency`, `band`, `mode`, `reference`, `spotTime`).
3.  `core/database/isar_helper.dart` oluştur. Isar veritabanı başlatma (initialization) mantığını yaz.
4.  `build_runner` çalıştırarak Isar tabanlı `.g.dart` kodlarını üret.

---

## Modül 3: Park Listesi Senkronizasyonu (Sync Agent)
**Görev Tanımı:** `https://pota.app/all_parks_ext.csv` dosyasının indirilip parse edilmesi ve yerel Isar veritabanına kaydedilmesi.
*Ön Koşul: Modül 2 tamamlanmış olmalı.*

**Adımlar:**
1.  `csv` paketini pubspec'e ekle.
2.  `lib/features/parks/data/repositories/park_sync_repository.dart` oluştur.
3.  CSV dosyasını indiren, satır satır okuyan ve Isar veritabanına `ParkModel` nesneleri olarak topluca (batch insert) yazan fonksiyonu kodla.
4.  Uygulama ilk açılışı için Riverpod ile bir asenkron başlatıcı (initializer) provider yazarak bu senkronizasyonu bağla.

---

## Modül 4: API Entegrasyonları (API Agent)
**Görev Tanımı:** POTA açık uç noktalarından anlık veri çeken servislerin yazılması.
*Ön Koşul: Modül 1 ve Modül 2 tamamlanmış olmalı.*

**Adımlar:**
1.  **Spotlar:** `lib/features/spots/data/repositories/spot_repository.dart` oluştur. `GET /spot/` uç noktasına Dio ile istek aıp dönen JSON'u `SpotModel` listesine çeviren metodu yaz.
2.  **Park İstatistikleri/Aktivasyonlar:** `lib/features/activations/data/repositories/activation_repository.dart` oluştur. `GET /park/activations/{reference}` uç noktasına istek atıp veriyi işleyen metodu yaz.
3.  Riverpod `FutureProvider`'ları oluşturarak bu repository'leri UI katmanına sunulabilir hale getir.

---

## Modül 5: UI ve Harita Geliştirimi (UI/UX Agent)
**Görev Tanımı:** Kullanıcı arayüzünün oluşturulması ve Riverpod ile state'lerin bağlanması.
*Ön Koşul: Modül 3 ve Modül 4 çalışır durumda olmalı.*

**Adımlar:**
1.  **Ana Sayfa (Bottom Navigation):** Harita, Güncel Spotlar ve Ayarlar sekmelerini içeren ana iskeleti kur.
2.  **Harita Ekranı (`flutter_map`):** Isar'dan çekilen (Modül 3) parkları harita üzerinde pin (`Marker`) olarak göster. Pin'e tıklandığında detay sayfasına yönlendir.
3.  **Spotlar Ekranı:** Riverpod `FutureProvider`'ı (Modül 4) dinleyerek API'den gelen güncel spotları `ListView` içinde listele. "Pull to refresh" (Aşağı çek-yenile) ekle.
4.  **Park Detay Ekranı:** Parkın temel bilgilerini Isar'dan al, API'den anlık olarak geçmiş aktivasyon listesini (Modül 4) çekip ekranda göster.
