# POTA (Parks on the Air) API Dokümantasyonu

`api.pota.app` uç noktası (endpoint) standart OpenAPI, Swagger veya `/docs` gibi herkesin erişebileceği (resmi olarak yayınlanmış) bir API referans sayfasına sahip değildir. Ana dizine (`/`) veya `/openapi.json` gibi sayfalara doğrudan istek attığınızda AWS API Gateway üzerinden **HTTP 403 Forbidden** (`{"message":"Missing Authentication Token"}`) hatası alırsınız. Bu, API'nin çoğunlukla kapalı ve POTA'nın kendi servisleri ile yetkilendirilmiş uygulamalar için olduğunu gösterir.

Bununla birlikte, POTA (Parks on the Air) programının kendi ön yüzünün (pota.app) de arka planda veri çekmek için kullandığı ve dışarıdan **kimlik doğrulama gerektirmeden (Authentication'sız)** erişilebilen bazı **açık API (public endpoint)** yolları mevcuttur. Topluluk tarafından sıklıkla bu uç noktalar kullanılmaktadır.

## Nasıl İletişim Kurulur?

Açık uç noktalarla iletişim kurmak oldukça kolaydır:
1. **HTTP Metodu:** Veri çekmek için sadece standart HTTP **GET** istekleri kullanılır.
2. **Veri Formatı:** Tüm yanıtlar **JSON** (JavaScript Object Notation) formatında döner.
3. **Kimlik Doğrulama:** Aşağıda belirtilen açık uç noktalarda API anahtarı veya Token'a genel veriler için ihtiyaç yoktur. Kullanıcı hesabı bilgilerini değiştirme veya log gönderme gibi işlemler yetkilendirme (Token) gerektirir.

---

## 📻 Bilinen Açık Uç Noktalar (Public Endpoints)

Aşağıdaki uç noktaların veri yapısı POTA geliştiricileri tarafından önceden haber verilmeksizin değiştirilebilir.

### 1. Güncel Spotları (Anlık Aktivasyon İhbarlarını) Çekmek
Şu anda parklarda kimlerin aktif olduğunu (Spotları) listeler.

*   **Endpoint:** `GET https://api.pota.app/spot/`
*   **Açıklama:** POTA ağında son bildirilen güncel spotları getirir.
*   **Örnek Dönen Değer Yapısı:**
    ```json
    [
      {
        "spotId": 48002691,
        "activator": "N1XX",
        "frequency": "7.032",
        "band": "40m",
        "mode": "CW",
        "reference": "K-1234",
        "parkName": "National Forest Reserve",
        "spotTime": "2026-03-06T12:00:00Z",
        "locationDesc": "US-CA"
      }
    ]
    ```

### 2. Ülke veya Program Bazlı Park Listesini ve İstatistiklerini Çekmek
Belirli bir program bölgesine dahil olan parkların listesini getirir.

*   **Endpoint:** `GET https://api.pota.app/program/parks/{program_kodu}`
*   **Örnek:** `https://api.pota.app/program/parks/TR` (Türkiye parkları), `US` (ABD) veya `GB` (İngiltere)
*   **Açıklama:** İlgili koddaki tüm parklara ait aktiflik, QSO (iletişim) ve deneme sayılarını içeren veriyi döner.
*   **Örnek Dönen Değer Yapısı:**
    ```json
    [
      {
        "reference": "TR-0001",
        "name": "Kaz Dağları Milli Parkı",
        "attempts": 5,
        "activations": 12,
        "qsos": 150
      }
    ]
    ```

### 3. Belirli Bir Parkın Geçmiş Aktivasyonlarını (Activations) Çekmek
Bir referans numarasının tarihteki aktivasyon aktivitelerini görmek için kullanılır.

*   **Endpoint:** `GET https://api.pota.app/park/activations/{park_referansı}`
*   **Parametreler:**
    *   `count` (opsiyonel): Döndürülecek sonuç sayısı. Ör: `?count=10`
*   **Örnek:** `https://api.pota.app/park/activations/K-0001?count=5`

---

## 💻 İletişim Örnekleri (Kod Örnekleri)

Bu API uç noktalarını projelerinize entegre etmek için aşağıdaki yolları izleyebilirsiniz:

### JavaScript (fetch ile, Node.js veya Tarayıcı Ön Yüzü)
```javascript
const getPotaSpots = async () => {
    try {
        const response = await fetch("https://api.pota.app/spot/");
        if (!response.ok) {
            throw new Error(`HTTP Hata: ${response.status}`);
        }
        const data = await response.json();
        console.log(data.slice(0, 5)); // İlk 5 kaydı ekrana bas
    } catch (error) {
        console.error("Spotlar alınırken hata oluştu:", error);
    }
};

getPotaSpots();
```

### Python (Requests Kütüphanesi ile)
Python projelerinizde HTTP `requests` modülü kullanarak spotları okuyabilirsiniz.
```python
import requests

url = "https://api.pota.app/spot/"
response = requests.get(url)

if response.status_code == 200:
    data = response.json()
    for spot in data[:5]: # Sadece ilk 5 veriyi yazdır
        print(f"{spot['activator']} -> {spot['reference']} ({spot['frequency']} MHz)")
else:
    print("Hata:", response.status_code)
```

### cURL (Komut Satırından Hızlı Test)
```bash
# Türkiye (TR) parklarını çekip terminalde görmek için
curl -s https://api.pota.app/program/parks/TR

# Veri içinden spot listesini jq ile filtreleyerek görmek için (jq yüklüyse)
curl -s https://api.pota.app/spot/ | jq '.[0]'
```

## 📋 Ek Bilgiler
POTA programı, sistemlerindeki tüm referansları içeren bir listeyi toplu olarak günde bir kez **CSV formatında** da yayınlamaktadır. Eğer amacınız yalnızca POTA referans veri tabanını (Park listesini) offline olarak yedeklemek, mobil veya web projenizde API'yi boşuna yormadan haritada park göstermekse, `https://pota.app/all_parks_ext.csv` adresindeki güncel dosyayı programatik olarak indirip içe aktarmak, binlerce API sorgusu atmaktan çok daha mantıklı bir yoldur.
