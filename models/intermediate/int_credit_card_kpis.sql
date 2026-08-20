/* Enis Bayrak */

/*
===============================================================================
Model: int_credit_card_kpis
Kaynak: stg_credit_card_balance
Hedef: Müşteri bazında (customer_id) kredi kartı limit doluluğu, asgari ödeme 
       disiplini ve gecikme (DPD) risk metriklerini hesaplamak.
===============================================================================
*/

{{
    config(
        materialized='view'
    )
}}

WITH base_cc AS (
    SELECT
        CAST(SK_ID_CURR AS STRING) AS customer_id,
        SK_ID_PREV,
        MONTHS_BALANCE,
        AMT_BALANCE,
        AMT_CREDIT_LIMIT_ACTUAL,
        AMT_PAYMENT_CURRENT,
        AMT_INST_MIN_REGULARITY,
        SK_DPD,
        -- Asgari tutarın altında kalındı mı?
        IF(AMT_PAYMENT_CURRENT < AMT_INST_MIN_REGULARITY, 1, 0) AS is_min_payment_deficit,
        -- Limit kullanım oranı
        SAFE_DIVIDE(GREATEST(AMT_BALANCE, 0), AMT_CREDIT_LIMIT_ACTUAL) AS limit_utilization
    FROM {{ ref('stg_credit_card_balance') }}
),

aggregated AS (
    SELECT
        customer_id,
        
        -- 1. Ortalama ve Maksimum Kart Limit Kullanım Oranı
        AVG(limit_utilization) AS avg_cc_limit_utilization,
        MAX(limit_utilization) AS max_cc_limit_utilization,
        
        -- 2. Asgari Tutarın Altında Kalma Oranı
        SAFE_DIVIDE(
            SUM(is_min_payment_deficit), 
            COUNT(AMT_INST_MIN_REGULARITY)
        ) AS cc_min_payment_deficit_ratio,
        
        -- 3. Son 12 Aydaki En Yüksek DPD
        COALESCE(MAX(CASE WHEN MONTHS_BALANCE >= -12 THEN SK_DPD END), 0) AS max_cc_sk_dpd_last_12m,

        -- 4. Kart Sayısı
        COUNT(DISTINCT SK_ID_PREV) AS total_cc_card_count

    FROM base_cc
    GROUP BY customer_id
)

SELECT * FROM aggregated