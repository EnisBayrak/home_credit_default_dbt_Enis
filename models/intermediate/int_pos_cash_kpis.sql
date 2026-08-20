/* Enis Bayrak */ 


{{
    config(
        materialized='view',
        schema='intermediate',
        tags=['intermediate', 'feature_engineering', 'pos_cash_behavior']
    )
}}

/*
===============================================================================
Model: int_pos_cash_kpis
Kaynak: stg_pos_cash_balance (customer_id, months_balance, days_past_due vb.)
Hedef: Müşteri bazında (customer_id) POS ve Nakit kredilerin ödeme ve gecikme metrikleri
===============================================================================
*/

WITH base_pos_cash AS (
    SELECT
        customer_id,
        previous_application_id,
        months_balance,
        total_instalment_count,
        remaining_instalment_count,
        contract_status,
        days_past_due,
        days_past_due_with_tolerance,
        is_past_due,
        is_completed
    -- Staging dosyanızın adı ne ise ref içine onu yazın (ör: stg_pos_cash_balance)
    FROM {{ ref('stg_pos_cash_balance') }}
),

customer_aggregations AS (
    SELECT
        customer_id,

        -- 1. GECİKME (DPD) METRİKLERİ (TÜM ZAMANLAR)
        -- Tüm geçmişteki maksimum gecikme günü
        MAX(days_past_due) AS max_pos_dpd_all_time,

        -- Toleranslı (küçük borçlar elenmiş) maksimum gecikme günü
        MAX(days_past_due_with_tolerance) AS max_pos_dpd_tolerance_all_time,

        -- POS/CASH kredilerindeki ortalama aylık gecikme süresi
        AVG(days_past_due) AS avg_pos_dpd_all_time,

        -- Gecikmeli geçen ayların toplam kayıtlara oranı
        SAFE_DIVIDE(COUNTIF(is_past_due), COUNT(*)) AS pos_dpd_month_ratio,
        SAFE_DIVIDE(COUNTIF(days_past_due_with_tolerance > 0), COUNT(*)) AS pos_dpd_tolerance_month_ratio,

        -- 2. YAKIN DÖNEM RİSK METRİKLERİ (SON 12 AY)
        -- Son 12 ay içindeki en yüksek gecikme günü
        COALESCE(
            MAX(CASE WHEN months_balance >= -12 THEN days_past_due END), 0
        ) AS max_pos_dpd_last_12m,

        -- Son 12 ay içinde gecikme yaşanan ay sayısı
        COUNTIF(months_balance >= -12 AND is_past_due) AS pos_dpd_months_count_last_12m,

        -- 3. SÖZLEŞME VE VADE DİSİPLİNİ
        -- Başarıyla tamamlanan sözleşme kayıtlarının oranı
        SAFE_DIVIDE(COUNTIF(is_completed), COUNT(*)) AS pos_completed_contracts_ratio,

        -- Kalan ortalama taksit sayısı (Müşterinin üstündeki taksit yükü)
        AVG(remaining_instalment_count) AS avg_pos_remaining_instalments,

        -- 4. HACİM BİLGİSİ
        COUNT(DISTINCT previous_application_id) AS total_pos_loan_count,
        COUNT(*) AS total_pos_months_count

    FROM base_pos_cash
    GROUP BY customer_id
)

SELECT * FROM customer_aggregations