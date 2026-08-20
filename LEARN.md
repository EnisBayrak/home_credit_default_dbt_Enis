# LEARN.md — `bureau` ve `bureau_balance` Temizliği


## 1. Hikâyenin başladığı yer

Elimizde iki tablo var ve ikisi de "ham" — yani birileri bir CSV dosyasını
BigQuery'ye yükleyip bırakmış. Kimse dokunmamış.

**`bureau`** — Kredi bürosunun bizim başvuru sahiplerimiz hakkında bildiği
geçmiş krediler. 1.716.428 satır, 305.811 müşteri. Yani ortalama bir müşterinin
sicilinde **5,6 eski kredi** var.

**`bureau_balance`** — Bu kredilerin **aylık** durum kayıtları. 27.299.925 satır.
Yirmi yedi milyon. Her satır tek bir kredinin tek bir ayına ait.

İşin özü şu soruya cevap aramak: *"Bu kişinin geçmiş kredi davranışı, bugün
vereceğimiz kredinin geri ödenmesi hakkında ne söylüyor?"*

---

## 2. Önce baktık, sonra dokunduk

Burada altı çizilmesi gereken bir alışkanlık var: **tek satır kod yazmadan önce
veriye baktık.**

Acemi refleksi şudur: veriyi görür görmez temizlemeye başlamak. "Boşluklar var,
doldurayım. Negatif değerler var, sileyim." Bu, hastayı muayene etmeden ilaç
yazmaya benzer.

Bunun yerine **profilleme** yaptık — veriye soru sorup cevabını ölçtük. Toplam
sekiz sorgu. İşte öğrendiklerimiz ve her birinin neden önemli olduğu:

| Ölçüm | Sonuç | Bu ne demek? |
|---|---|---|
| `SK_ID_BUREAU` tekil sayısı | 1.716.428 / 1.716.428 | Kusursuz birincil anahtar |
| `AMT_ANNUITY` boş | %71,5 | Sayı olarak neredeyse kullanılamaz |
| `AMT_CREDIT_MAX_OVERDUE` boş | %65,5 | Muhtemelen "hiç gecikme yok" |
| `DAYS_ENDDATE_FACT` boş | %36,9 | **Hata değil** — bkz. Ders 1 |
| Negatif borç | 8.418 satır | Fiziksel olarak imkânsız |
| Negatif limit | 351 satır | Aynı şekilde imkânsız |
| Öksüz kayıt (`bureau_balance`) | 43.041 kredi | Ana tabloda karşılığı yok |
| Geçmişi olmayan kredi | 942.074 (%55) | Yarıdan fazlası! |
| Yabancı para birimi | 1.408 satır | Toplanamaz |

**Ders:** Profilleme bir formalite değil. Yukarıdaki tablonun her satırı,
sonradan yazacağımız kodun bir satırını değiştirdi. Bu adımı atlasaydık,
kodumuz çalışırdı ama **yanlış sonuç üretirdi** — ki bu, hata vermekten çok
daha tehlikelidir.

---

## 3. Ders 1: Her boşluk bir eksiklik değildir

Bu, projedeki en önemli tek fikir.

`DAYS_ENDDATE_FACT` sütunu (kredinin fiilen kapandığı tarih) satırların
**%36,9**'unda boş. İlk tepki: "veri eksik, doldurayım."

Ama bir şey daha ölçmüştük: `CREDIT_ACTIVE = 'Active'` olan kredilerin oranı
**%36,7**.

Bu iki sayının bu kadar yakın olması tesadüf değil. **Kredi hâlâ açıksa,
kapanış tarihi zaten yoktur.** Boşluk bir kusur değil, bilginin ta kendisi.

Buraya sıfır yazsaydık ne olurdu? Model "bu kredi bugün kapandı" diye
okuyacaktı. Yani 630 bin açık krediyi, kapanmış gibi göstermiş olacaktık.
Model bunu öğrenir, siz de sonuçlara güvenirsiniz. **Sessiz felaket.**

> **İki tür boşluk vardır:**
> **Yapısal boşluk** — durumun doğal sonucu. Açık kredinin kapanış tarihi yok.
> Bekârın eşinin adı yok. Bunlar `NULL` kalmalı; `NULL` doğru cevaptır.
>
> **Eksik boşluk** — değer var ama kaydedilmemiş. Bir müşterinin yaşı boşsa,
> o kişinin bir yaşı vardır, biz bilmiyoruz. İşte imputasyon (doldurma)
> burada tartışılabilir.
>
> Ayırt etmenin tek yolu: **başka bir sütunla karşılaştırıp oranları ölçmek.**
> Tam olarak burada yaptığımız şey.

---

## 4. Ders 2: Bir sütun, iki kavram taşıyorsa bölünmelidir

`bureau_balance.STATUS` sütununun gerçek dağılımı:

```
C  ->  13.646.993   (%49,99)   o ay kredi KAPALIYDI
0  ->   7.499.507   (%27,47)   açık, gecikme yok
X  ->   5.810.482   (%21,28)   durum BİLİNMİYOR
1  ->     242.347   (%0,89)    1-30 gün gecikme
2  ->      23.419   (%0,09)    31-60 gün
3  ->       8.924   (%0,03)    61-90 gün
4  ->       5.847   (%0,02)    91-120 gün
5  ->      62.406   (%0,23)    120+ gün / zarar yazıldı
```

Dikkat: `0`'dan `5`'e kadar olanlar **sıralı bir ölçek** — 3, 2'den kötüdür.
Ama `C` ve `X` bu ölçekte hiçbir yerde durmuyor.

Yaygın hata şudur: bu sütunu sayıya çevirmek için `C = 6`, `X = 7` demek.
Bunu yaptığınız anda modele şunu öğretmiş olursunuz: *"Kapatılmış kredi, 120
gün geciktirilmiş krediden daha kötüdür."* Bu cümle saçmadır ve modeliniz
buna göre karar verir.

Biz sütunu **üçe böldük**:

- `status_group` — kategorik: `closed` / `unknown` / `current` / `delinquent`
- `dpd_bucket` — sıralı sayı 0–5, `C` ve `X` için **`NULL`**
- `was_late_this_month` — boole, `X` için **`NULL`**

`SAFE_CAST` burada gerçek iş yapıyor. `'3'` girdiğinde `3` döner; `'C'`
girdiğinde patlamak yerine `NULL` döner. Normal `CAST` olsaydı 27 milyon
satırlık sorgu tek bir harf yüzünden çöker, siz de sabahın üçünde hata
mesajına bakıyor olurdunuz.

> **Ders:** `NULL`, "bilgi yok" demenin dürüst yoludur. Onu bir sayıya
> zorlamak, bilmediğiniz bir şeyi biliyormuş gibi yapmaktır.

---

## 5. Ders 3: `LEFT JOIN` ile `INNER JOIN` arasındaki 942.074 satırlık fark

`int_bureau_enriched.sql` dosyasında tek bir kelime var ki, projedeki en
pahalı karar odur: **LEFT**.

Ölçtüğümüz şuydu: `bureau` tablosundaki 1.716.428 kredinin **942.074'ünün**
(%55) hiç aylık geçmişi yok.

`INNER JOIN` yazsaydık ne olurdu?

- Sorgu hatasız çalışırdı.
- Hiçbir uyarı çıkmazdı.
- Sonuç tablosu makul görünürdü.
- Ve **verinizin yarısından fazlası buharlaşmış olurdu.**

Bu, yazılımdaki en tehlikeli hata türüdür: **sessiz hata.** Kod çöktüğünde
düzeltirsiniz. Kod çalışıp yanlış cevap verdiğinde, ona aylarca güvenirsiniz.

Üstelik bu 942 bin kredi rastgele değil. Muhtemelen daha eski veya daha küçük
krediler. Onları atarsanız, sistematik olarak çarpıtılmış bir örneklemle
çalışırsınız.

Bu yüzden `LEFT JOIN` kullandık **ve** `has_monthly_history` adında bir bayrak
ekledik. Böylece hiç kimse "gecikme oranı ortalaması" hesaplarken bunun sadece
%45'lik bir kesimden geldiğini unutamaz.

> **Ders:** Her `JOIN`'den önce iki soru sorun:
> 1. Sağdaki tabloda karşılığı olmayan satırlar var mı? (→ `LEFT` mi `INNER` mi)
> 2. Sağdaki tabloda **birden fazla** karşılığı olan satırlar var mı?
>    (→ satır sayısı patlar mı — buna *fan-out* denir)
>
> Bizim `int_bureau_balance_summarized` modelimiz kredi başına tek satır
> ürettiği için ikinci risk yok. Ve bunu tesadüfe bırakmadık: o modele
> `unique` testi koyduk.

---

## 6. Ders 4: Elma ile armut toplamak

Satırların %99,9'u `currency 1`. Geriye 1.408 satır kalıyor: `currency 2`, `3`
ve `4`.

"1.408 satır, 1,7 milyonun yanında hiçbir şey" diye düşünmek cazip. Ama
düşünün: bir müşterinin 50.000 birimlik kredisi var. Hangi para biriminde?
Bilmiyoruz ve veri setinde **hiçbir kur bilgisi yok**.

Bu tutarları körü körüne toplarsanız, o müşterinin toplam borcu ya absürt
şekilde yüksek ya da düşük çıkar. Aykırı değer (outlier) olarak görünür.
Birileri onu "temizler". Ve gerçek problem hiç fark edilmez.

Çözümümüz: `is_foreign_currency` bayrağı, ve mart katmanındaki **her** para
toplamı sadece `currency 1` üzerinden hesaplanıyor. Dışlananlar sayılıyor ve
raporlanıyor.

---

## 7. Mimari: neden üç katman?

```
KAYNAK (ham BigQuery tabloları — asla dokunulmaz)
   │
   ├── staging/      ← yıkama ve doğrama.  Satır sayısı DEĞİŞMEZ.
   │     stg_bureau              (1.716.428 satır)
   │     stg_bureau_balance     (27.299.925 satır)
   │
   ├── intermediate/ ← birleştirme ve özetleme
   │     int_bureau_balance_summarized  (817.395 satır — 27M'den sıkıştırıldı)
   │     int_bureau_enriched            (1.716.428 satır — LEFT JOIN)
   │
   └── marts/        ← servise hazır
         mart_customer_credit_history   (305.811 satır — müşteri başına bir)
```

**Staging'in tek kuralı:** giren satır sayısı = çıkan satır sayısı. `JOIN` yok,
`GROUP BY` yok, filtre yok. Sadece isim düzeltme, tip düzeltme, imkânsız
değerleri nötrleme.

Bu kural neden bu kadar katı? Çünkü hata ayıklamayı mümkün kılan şey odur.
Bir sayı yanlış çıktığında sırayla sorarsınız:

1. Ham veri mi yanlış? → kaynağa bak
2. Temizlik mi bozdu? → staging'e bak (satır sayısı korunuyor mu?)
3. Birleştirme mi patladı? → intermediate'e bak (`unique` testi geçiyor mu?)
4. Toplama mı hatalı? → mart'a bak

Her şeyi tek dev sorguya yazsaydınız, bu dört soruyu birbirinden ayıramazdınız.

> **Benzetme:** Mutfakta hazırlık tezgâhı, ocak ve servis tabağı ayrıdır.
> Ayrı oldukları için, yemek tuzlu çıktığında tuzun nerede eklendiğini
> bulabilirsiniz. Hepsini aynı tencerede yapsaydınız, tek çareniz baştan
> başlamak olurdu.

### `view` mi `table` mı?

Fark ettiyseniz staging modelleri `view`, diğerleri `table`:

- **Staging = `view`** — ince bir dönüşüm. BigQuery depolamaya değil, taranan
  bayta göre ücret alır. View bedava durur ve her zaman güncel veriyi gösterir.
- **`int_bureau_balance_summarized` = `table`** — bu model 27 milyon satır
  tarıyor. View olsaydı, onu kullanan **her** sorgu bu taramayı baştan yapar
  ve faturaya yazardı. Bir kere yazıp saklamak, kuruş ile euro arasındaki fark.

> **Ders:** Materyalizasyon seçimi estetik değil, **maliyet** kararıdır.
> Kural: ucuz ve sık değişen → view. Pahalı ve nadiren değişen → table.

---

## 8. Testler: en ucuz sigorta

`_home_credit__models.yml` dosyasındaki testler süs değil. Her biri belirli bir
felaketi engelliyor:

| Test | Neyi yakalar |
|---|---|
| `unique` on `stg_bureau.bureau_loan_id` | Yeni veri yüklemesinde tekrar eden kayıt |
| `unique` on `int_bureau_enriched` | **Join fan-out** — projedeki en değerli test |
| `accepted_values` on `credit_status` | Kaynakta yeni bir durum kodu belirmesi |
| `accepted_values` on `dpd_bucket` | Beklenmedik bir gecikme kademesi |
| `accepted_range` on `debt_amount` | Negatif borç temizliğinin bozulması |

`int_bureau_enriched` üzerindeki `unique` testinin özel bir yeri var. Eğer bir
gün `int_bureau_balance_summarized` modeli yanlışlıkla kredi başına iki satır
üretmeye başlarsa, `LEFT JOIN` sessizce satır sayısını şişirir. Toplamlarınız
iki katına çıkar. Hiçbir hata mesajı almazsınız — **o test olmasaydı.**

`dpd_bucket` testindeki `where: "dpd_bucket is not null"` satırına dikkat: o
olmasaydı test, kasten `NULL` bıraktığımız %71'lik kesim yüzünden sürekli
hata verirdi. Testin kendisi de veriyi anlamayı gerektirir.

---

## 9. Karşılaştığımız tuzaklar (ve nasıl düştüğümüz)

Bu bölüm dürüstlük bölümü. Yol boyunca yanlış teşhisler koyduk:

**Tuzak 1 — BigQuery'nin ikircikli hata mesajı.**
`application_train` tablosunu sorguladık, `403 Access Denied ... or perhaps it
does not exist` aldık. "İzin sorunu" diye teşhis koyduk. **Yanlıştı.** Tablo
sadece yoktu. BigQuery, güvenlik gereği "yetkin yok" ile "tablo yok" durumlarını
aynı mesajla verir — aksi halde saldırganlar hangi tabloların var olduğunu
tarayabilirdi.
*Alınacak ders:* Bir hata mesajı iki farklı sebebi işaret ediyorsa, teşhisi
başka bir kanıtla doğrulayana kadar kesin konuşmayın.

**Tuzak 2 — `INFORMATION_SCHEMA` kapalıydı.**
Tablo listesini çekemedik çünkü metadata görünümlerine erişim yoktu. Ama veri
tablolarının kendisi açıktı. Bunlar **ayrı izinlerdir**.
*Alınacak ders:* Keşif yolu kapalıysa iş bitmiş değildir; doğrudan sorgulamayı
deneyin.

**Tuzak 3 — Sonuçlardaki sahte "string" tipleri.**
Sorgu sonuçlarında `SK_ID_CURR` tipi `"string"` görünüyordu. Sütunların metin
olarak saklandığını sandık. Kontrol ettik: `SUM(DAYS_CREDIT)` çalıştı ve
`-1.960.345.609` döndürdü. BigQuery'de `SUM` metin sütununda **çalışmaz**.
Yani sütunlar gerçekten sayısal; "string" görüntüsü sadece sonuçların JSON'a
çevrilirken oluşan bir yan etki.
*Alınacak ders:* Metadata'ya değil, **davranışa** güvenin. Bir tipten emin
değilseniz, o tipe özgü bir işlem çalıştırın ve sonuca bakın.

---

## 10. Bundan sonra ne yapmalı

1. **`packages.yml` ekleyin** ve `dbt deps` çalıştırın — `accepted_range`
   testleri `dbt_utils` paketini gerektiriyor:
   ```yaml
   packages:
     - package: dbt-labs/dbt_utils
       version: [">=1.1.0", "<2.0.0"]
   ```

2. **`dbt build` çalıştırın.** Bu komut modelleri oluşturur *ve* testleri
   çalıştırır. `dbt run` sadece modelleri kurar; alışkanlığınızı `build`
   üzerine kurun.

3. **`AMT_CREDIT_MAX_OVERDUE` kararını verin.** %65,5 boş. Hipotezimiz: bu
   boşluklar "hiç gecikme olmamış" demek. Test edin — bu satırlarda
   `AMT_CREDIT_SUM_OVERDUE = 0` ve `CREDIT_DAY_OVERDUE = 0` mı? Öyleyse sıfır
   yazmak savunulabilir. Değilse `NULL` bırakın.

4. **Production ortamı kurun.** Şu an projede sadece Development ortamı var.
   Production'da bir iş çalıştırdığınızda dbt'nin katalog ve soyağacı
   özellikleri açılır — modelleri listelemek, bağımlılık grafiğini görmek,
   model sağlığını izlemek.

5. **Diğer tabloları da aynı kalıpla ekleyin.** `previous_application`,
   `installments_payments`, `credit_card_balance`. Kalıp aynı: önce profille,
   sonra staging'de temizle, intermediate'te özetle, mart'ta birleştir.

---

## 11. Tek cümlelik özet

> İyi veri mühendisliği, veriyi temizlemekten çok **verinin nerede kirli
> olduğunu görünür kılmak**tır. Kodumuzdaki her bayrak, her `NULL`, her test —
> hepsi geleceğin analistine "buraya dikkat et" diyen birer not.
