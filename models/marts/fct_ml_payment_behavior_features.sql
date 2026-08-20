{{
    config(
        materialized='table',
        schema='marts',
        tags=['marts', 'ml_features', 'payment_behavior'],
        cluster_by=['customer_id']
    )
}}

WITH base_application AS (
    SELECT
        CAST(SK_ID_CURR AS STRING) AS customer_id,
        TARGET AS target
    FROM {{ ref('stg_application_train') }}
),

installments_kpis AS (
    SELECT * FROM {{ ref('int_installments_payment_kpis') }}
),

credit_card_kpis AS (
    SELECT * FROM {{ ref('int_credit_card_kpis') }}
),

pos_cash_kpis AS (
    SELECT * FROM {{ ref('int_pos_cash_kpis') }}
),

bureau_kpis AS (
    SELECT * FROM {{ ref('int_bureau_kpis') }}
)

SELECT
    -- 1. Kimlik ve Hedef Değişken
    app.customer_id,
    app.target,

    -- 2. Taksitli Kredi Ödeme Disiplini (Installments)
    COALESCE(inst.avg_payment_delay_days, 0)         AS inst_avg_payment_delay_days,
    COALESCE(inst.max_payment_delay_days, 0)         AS inst_max_payment_delay_days,
    COALESCE(inst.late_payment_ratio, 0)             AS inst_late_payment_ratio,
    COALESCE(inst.underpayment_ratio, 0)            AS inst_underpayment_ratio,
    COALESCE(inst.payment_completion_rate, 1.0)      AS inst_payment_completion_rate,
    COALESCE(inst.recent_payment_delay_trend, 0)     AS inst_recent_payment_delay_trend,
    COALESCE(inst.total_installment_count, 0)        AS inst_total_installment_count,

    -- 3. Kredi Kartı Kullanım ve Asgari Ödeme Davranışı (Credit Card)
    COALESCE(cc.avg_cc_limit_utilization, 0)         AS cc_avg_limit_utilization,
    COALESCE(cc.max_cc_limit_utilization, 0)         AS cc_max_limit_utilization,
    COALESCE(cc.cc_min_payment_deficit_ratio, 0)     AS cc_min_payment_deficit_ratio,
    COALESCE(cc.max_cc_sk_dpd_last_12m, 0)          AS cc_max_dpd_last_12m,
    COALESCE(cc.total_cc_card_count, 0)              AS cc_total_card_count,

    -- 4. POS / Nakit Kredi Gecikme ve Vade Davranışı (POS Cash)
    COALESCE(pos.max_pos_dpd_all_time, 0)            AS pos_max_dpd_all_time,
    COALESCE(pos.max_pos_dpd_tolerance_all_time, 0)  AS pos_max_dpd_tolerance_all_time,
    COALESCE(pos.avg_pos_dpd_all_time, 0)            AS pos_avg_dpd_all_time,
    COALESCE(pos.pos_dpd_month_ratio, 0)             AS pos_dpd_month_ratio,
    COALESCE(pos.max_pos_dpd_last_12m, 0)            AS pos_max_dpd_last_12m,
    COALESCE(pos.pos_completed_contracts_ratio, 0)   AS pos_completed_contracts_ratio,
    COALESCE(pos.avg_pos_remaining_instalments, 0)   AS pos_avg_remaining_instalments,
    COALESCE(pos.total_pos_loan_count, 0)            AS pos_total_loan_count,

    -- 5. Kredi Bürosu Dış Sicil Davranışı (Bureau)
    COALESCE(bur.bureau_active_overdue_amt, 0)       AS bureau_active_overdue_amt,
    COALESCE(bur.bureau_max_overdue_amt, 0)          AS bureau_max_overdue_amt,
    COALESCE(bur.total_credit_prolong_count, 0)      AS bureau_total_credit_prolong_count,
    COALESCE(bur.bureau_dpd_worst_status_count, 0)   AS bureau_dpd_worst_status_count

FROM base_application app
LEFT JOIN installments_kpis inst ON app.customer_id = inst.customer_id
LEFT JOIN credit_card_kpis cc    ON app.customer_id = cc.customer_id
LEFT JOIN pos_cash_kpis pos      ON app.customer_id = pos.customer_id
LEFT JOIN bureau_kpis bur        ON app.customer_id = bur.customer_id