/* Enis Bayrak */

/*
===============================================================================
Model: int_installments_payment_kpis
Kaynak: stg_installments_payments
Hedef: Müşteri bazında (SK_ID_CURR) taksit ödeme disiplini ve risk KPI'ları üretmek.
===============================================================================
*/
/* Enis Bayrak */

/*
===============================================================================
Model: int_installments_payment_kpis
Kaynak: stg_installments_payments
Hedef: Müşteri bazında (customer_id) taksit ödeme disiplini ve risk KPI'ları üretmek.
===============================================================================
*/

{{
    config(
        materialized='view'
    )
}}

WITH base_installments AS (
    SELECT
        CAST(SK_ID_CURR AS STRING) AS customer_id,
        SK_ID_PREV,
        DAYS_INSTALMENT,
        DAYS_ENTRY_PAYMENT,
        AMT_INSTALMENT,
        AMT_PAYMENT,
        -- Gecikme günü (Erken ödemelerde 0 kabul edilir)
        GREATEST(DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT, 0) AS delay_days,
        -- Gerçek gecikme mi?
        IF(DAYS_ENTRY_PAYMENT > DAYS_INSTALMENT, 1, 0) AS is_late_payment,
        -- Eksik ödeme yapıldı mı?
        IF(AMT_PAYMENT < AMT_INSTALMENT, 1, 0) AS is_underpayment
    FROM {{ ref('stg_installments_payments') }}
),

aggregated AS (
    SELECT
        customer_id,
        
        -- 1. Ortalama ve Maksimum Gecikme Gün Sayısı
        AVG(delay_days) AS avg_payment_delay_days,
        MAX(delay_days) AS max_payment_delay_days,
        
        -- 2. Geciken Taksit Oranı
        SAFE_DIVIDE(SUM(is_late_payment), COUNT(*)) AS late_payment_ratio,
        
        -- 3. Eksik Ödenen Taksit Oranı
        SAFE_DIVIDE(SUM(is_underpayment), COUNT(*)) AS underpayment_ratio,
        
        -- 4. Toplam Ödeme Tamamlama Oranı
        SAFE_DIVIDE(SUM(AMT_PAYMENT), SUM(AMT_INSTALMENT)) AS payment_completion_rate,
        
        -- 5. Son 180 Günlük Trend (Son 6 aydaki ortalama gecikme - Tüm zamanlar ortalaması)
        COALESCE(
            AVG(CASE WHEN DAYS_INSTALMENT >= -180 THEN delay_days END), 0
        ) - AVG(delay_days) AS recent_payment_delay_trend,

        -- 6. Toplam Taksit Sayısı (Marts modeliyle tam uyum için)
        COUNT(*) AS total_installment_count

    FROM base_installments
    GROUP BY customer_id
)

SELECT * FROM aggregated