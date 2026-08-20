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

select
    customer_id,
    avg(days_past_due) as avg_days_past_due,
    max(days_past_due) as max_days_past_due,
    count(distinct previous_application_id) as total_pos_contracts
from {{ ref('stg_pos_cash_balance') }}
group by customer_id