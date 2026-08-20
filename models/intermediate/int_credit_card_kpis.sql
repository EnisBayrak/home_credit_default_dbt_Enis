/* Enis Bayrak */


/*
===============================================================================
Model: int_credit_card_kpis
Kaynak: stg_credit_card_balance
Hedef: Müşteri bazında (SK_ID_CURR) kredi kartı limit doluluğu, asgari ödeme 
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
        SK_ID_CURR,
        MONTHS_BALANCE,
        AMT_BALANCE,
        AMT_CREDIT_LIMIT_ACTUAL,
        AMT_PAYMENT_CURRENT,
        AMT_INST_MIN_REGULARITY,
        SK_DPD,
        -- Asgari tutarın altında kalındı mı?
        IF(AMT_PAYMENT_CURRENT < AMT_INST_MIN_REGULARITY, 1, 0) AS is_min_payment_deficit,
        -- Limit kullanım oranı
        SAFE_DIVIDE(AMT_BALANCE, AMT_CREDIT_LIMIT_ACTUAL) AS limit_utilization
    FROM {{ ref('stg_credit_card_balance') }}
),

aggregated AS (
    SELECT
        SK_ID_CURR,
        
        -- 1. Asgari Tutarın Altında Kalma Oranı
        SAFE_DIVIDE(
            SUM(is_min_payment_deficit), 
            COUNT(AMT_INST_MIN_REGULARITY)
        ) AS cc_min_payment_deficit_ratio,
        
        -- 2. Son 12 Aydaki En Yüksek DPD
        MAX(CASE WHEN MONTHS_BALANCE >= -12 THEN SK_DPD END) AS max_cc_sk_dpd_last_12m,
        
        -- 3. Ortalama Kart Limit Kullanım Oranı
        AVG(limit_utilization) AS avg_cc_limit_utilization

    FROM base_cc
    GROUP BY SK_ID_CURR
)

SELECT * FROM aggregated