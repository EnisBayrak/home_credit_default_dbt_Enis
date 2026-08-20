{{
    config(
        materialized='view'
    )
}}

/*
===============================================================================
Model: int_bureau_kpis
Kaynak: stg_bureau_balance, stg_bureau
Hedef: Müşteri bazında (customer_id) dış kredi bürosu metrikleri.
===============================================================================
*/

WITH bureau_balance_agg AS (
    SELECT
        SK_ID_BUREAU,
        COUNTIF(STATUS IN ('3', '4', '5')) AS severe_overdue_month_count
    FROM {{ ref('stg_bureau_balance') }}
    GROUP BY SK_ID_BUREAU
),

bureau_joined AS (
    SELECT
        CAST(b.SK_ID_CURR AS STRING) AS customer_id,
        b.SK_ID_BUREAU,
        b.CREDIT_ACTIVE,
        b.AMT_CREDIT_SUM_OVERDUE,
        b.AMT_CREDIT_MAX_OVERDUE,
        b.CNT_CREDIT_PROLONG,
        COALESCE(bb.severe_overdue_month_count, 0) AS severe_overdue_month_count
    FROM {{ ref('stg_bureau') }} b
    LEFT JOIN bureau_balance_agg bb ON b.SK_ID_BUREAU = bb.SK_ID_BUREAU
),

aggregated AS (
    SELECT
        customer_id,

        -- 1. Aktif dış kredilerdeki toplam gecikmiş borç tutarı
        SUM(CASE WHEN LOWER(CREDIT_ACTIVE) = 'active' THEN AMT_CREDIT_SUM_OVERDUE ELSE 0 END) AS bureau_active_overdue_amt,

        -- 2. Dış kredilerde bugüne kadar görülmüş en yüksek gecikme tutarı
        MAX(AMT_CREDIT_MAX_OVERDUE) AS bureau_max_overdue_amt,

        -- 3. Toplam kredi erteleme / uzatma sayısı
        SUM(CNT_CREDIT_PROLONG) AS total_credit_prolong_count,

        -- 4. Ağır temerrüt / yasal takip statüsündeki toplam ay sayısı
        SUM(severe_overdue_month_count) AS bureau_dpd_worst_status_count

    FROM bureau_joined
    GROUP BY customer_id
)

SELECT * FROM aggregated