# Veri Kontrol Rehberi — `bureau` ve `bureau_balance`

Bu klasördeki yedi SQL dosyası, iki tablonuz için tam bir veri kalitesi
denetimi yapar. Her dosya bağımsız çalışır.

## Nasıl çalıştırılır

**Seçenek 1 — BigQuery konsolu (en kolay).**
`console.cloud.google.com/bigquery` → sorgu penceresini aç → dosyadaki bir
sorguyu kopyala-yapıştır → **Run**.

Dikkat: dosyalarda birden fazla sorgu var, aralarında `;` ile ayrılmış.
BigQuery konsolu hepsini arka arkaya çalıştırır ama size **sadece sonuncunun**
sonucunu gösterir. Bu yüzden tek seferde bir sorgu kopyalayın.

**Seçenek 2 — dbt.**
Dosyaları `analyses/` klasörüne koyun ve `dbt compile` çalıştırın. dbt bu
klasördeki dosyaları modele çevirmez, sadece derler — keşif sorguları için
tasarlanmış bir alandır.

---

## Sıra önemli

Kontroller birbirine dayanır. Bu sırayla gidin:

| # | Dosya | Ne yapar | Neden bu sırada |
|---|---|---|---|
| 01 | `structure_and_grain` | Satır sayısı, anahtar tekilliği, grain | **Her şeyin temeli.** Grain bilinmeden "duplicate" tanımlanamaz |
| 02 | `completeness_and_sentinels` | NULL, boş string, sahte NULL | Eksikliği bilmeden dağılıma bakılmaz |
| 03 | `numeric_profile` | Yüzdelikler, sıfırlar, negatifler, aykırılar | Sayısal sütunların gerçek şekli |
| 04 | `categorical_profile` | Kategori envanteri, yazım/boşluk hijyeni | Metin sütunlarının hâli |
| 05 | `business_rules` | Sütunlar arası mantık, iş kuralları | **En değerli dosya** — tek tek geçerli değerler, birlikte imkânsız olabilir |
| 06 | `referential_integrity` | Öksüz kayıt, kapsama, fan-out | Tablolar birleşmeden önce |
| 07 | `missingness_pattern` | NULL'ın *nedenini* bulma | Karar vermeden hemen önce |

---

## Sonuçları nasıl okumalı

**Sıfır her zaman iyi haber değildir.** `05` dosyasındaki her kural için sıfır
görmek "veri temiz" demek değil, "bu kural ihlal edilmemiş" demektir. Doğru
kuralı yazıp yazmadığınız ayrı bir soru.

**Sıfır olmayan her sayı bir karar gerektirir**, düzeltme değil. Dört seçenek:

| Karar | Ne zaman |
|---|---|
| **Düzelt** | Hata belli ve doğru değer çıkarılabiliyor |
| **İşaretle** | Şüpheli ama emin değilsiniz — bayrak sütunu ekleyin, veriyi bırakın |
| **Bırak** | Hata değil, yapısal bir durum (açık kredinin kapanış tarihi yok) |
| **Çıkar** | Satır kullanılamaz durumda ve azınlıkta |

Hangisini seçerseniz seçin, **gerekçesini yazın.** Üç ay sonra o gerekçe,
kararın kendisinden daha değerli olacak.

---

## Şu ana kadar bulunanlar (ölçülmüş, tahmin değil)

### `bureau` — 1.716.428 satır

| Bulgu | Sayı | Durum |
|---|---|---|
| `SK_ID_BUREAU` tekilliği | Kusursuz | ✅ |
| Negatif borç | 8.418 satır | ⚠️ Aşağıdaki nota bakın |
| Negatif limit | 351 satır | ⚠️ |
| Borç > verilen kredi | 29.642 satır | ⚠️ Mantık ihlali |
| Kapalı ama borcu var | 6.618 satır | ⚠️ Mantık ihlali |
| 50 yıldan uzun kredi | 38.454 satır | ⚠️ |
| Kredi tutarı tam sıfır | 66.582 satır | ⚠️ Muhtemelen NULL olmalıydı |
| `AMT_ANNUITY` boş | %71,5 | 📋 Yapısal olabilir |
| `AMT_CREDIT_MAX_OVERDUE` boş | %65,5 | 📋 Aşağıdaki nota bakın |
| Yabancı para birimi | 1.408 satır | ⚠️ Toplanamaz |

### `bureau_balance` — 27.299.925 satır

| Bulgu | Sonuç | Durum |
|---|---|---|
| Grain (kredi + ay) tekilliği | 0 tekrar | ✅ |
| `MONTHS_BALANCE` aralığı | −96 … 0 | ✅ |
| Öksüz kayıt | 43.041 kredi | ⚠️ |
| `STATUS` beklenmedik değer | Yok | ✅ |
| `X` (bilinmiyor) oranı | %21,3 | 📋 |

---

## İki önemli not

### 1. Negatif borçlar muhtemelen rastgele değil

En negatif borç: **−4.705.600,32**
En büyük limit: **+4.705.600,32**

Aynı sayı, ters işaret. Bu tesadüf olamaz. Muhtemelen bir işaret hatası veya
sütun karışması var. `05` dosyasındaki 5.2 numaralı sorgu bunu araştırır.

**Bu, düzeltme yöntemini değiştirir.** Rastgele gürültü olsaydı sıfıra
sabitlemek doğru olurdu. İşaret hatasıysa doğru düzeltme `ABS()` almak veya
değeri doğru sütuna taşımaktır. Araştırmadan karar vermeyin.

### 2. `AMT_CREDIT_MAX_OVERDUE` boşluğu "sıfır" demek değil

İlk hipotez şuydu: NULL = hiç gecikme olmamış. **Test edildi ve çürütüldü.**

Kanıt: değeri olan 591.940 satırın 470.650'sinde değer **tam olarak sıfır**.
Yani kaynak sistem "gecikme yok"u `0` yazarak ifade edebiliyor ve ediyor.
Öyleyse `NULL` başka bir şey demek — büyük ihtimalle "bu bilgi bize
ulaşmadı".

**Karar: NULL bırakın.** Sıfır yazmak, bilmediğiniz bir şeyi biliyormuş gibi
göstermek olur.

---

## Sonraki adım

Kontrolleri çalıştırdıktan sonra, bulduğunuz her kusur için tek satırlık bir
karar kaydı tutun:

```
AMT_CREDIT_SUM_DEBT < 0  |  8.418 satır  |  KARAR: araştırılıyor (işaret
hatası şüphesi)  |  GEREKÇE: en negatif değer, en büyük limitin tam tersi
```

Bu kayıt, hem grup arkadaşlarınıza hem de üç ay sonraki kendinize yapacağınız
en büyük iyilik.
