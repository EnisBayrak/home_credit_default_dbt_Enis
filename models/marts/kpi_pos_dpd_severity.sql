/*
=============================================================================
KPI Adı: Gecikme Şiddeti Metrikleri (DPD Severity)
Tablo: kpi_pos_dpd_severity
Granülarite: SK_ID_CURR (Müşteri Seviyesi)
Kaynak: stg_pos_cash_balance

Açıklama:
Müşterinin geçmiş POS ve nakit kredilerindeki aylık gecikme gün sayılarını 
(Days Past Due - DPD) özetler. Ortalama gecikme genel ödeme alışkanlığını, 
maksimum gecikme ise müşterinin yaşadığı en uç temerrüt riskini ölçer.
=============================================================================
*/

with customer_dpd as (
    select
        customer_id,
        avg(days_past_due) as avg_days_past_due,
        max(days_past_due) as max_days_past_due,
        count(distinct previous_application_id) as total_pos_contracts
    from {{ ref('stg_pos_cash_balance') }}
    group by customer_id
)

select
    customer_id,
    avg_days_past_due,
    max_days_past_due,
    total_pos_contracts,

    -- 1. Maksimum Gecikmeye Göre Risk Kovası (En Kritik Segmentasyon)
    case
        when max_days_past_due = 0 then '0 Gun (Gecikmesiz)'
        when max_days_past_due between 1 and 30 then '1-30 Gun (Hafif Risk)'
        when max_days_past_due between 31 and 60 then '31-60 Gun (Orta Risk)'
        when max_days_past_due between 61 and 90 then '61-90 Gun (Yuksek Risk)'
        else '90+ Gun (Temerrut / NPL)'
    end as max_dpd_risk_bucket,

    -- 2. Görselleştirme ve Sıralama İçin Sayısal Segment Kodu (1 - 5)
    case
        when max_days_past_due = 0 then 1
        when max_days_past_due between 1 and 30 then 2
        when max_days_past_due between 31 and 60 then 3
        when max_days_past_due between 61 and 90 then 4
        else 5
    end as max_dpd_risk_level

from customer_dpd