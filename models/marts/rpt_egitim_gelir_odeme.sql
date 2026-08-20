
{{ config(materialized='table') }}

select
    a.NAME_EDUCATION_TYPE                                           as egitim,
    count(*)                                                        as musteri_sayisi,

    -- Income profile (robust statistics)
    round(approx_quantiles(a.AMT_INCOME_TOTAL, 100)[offset(50)], 0) as gelir_medyan,
    round(approx_quantiles(a.AMT_INCOME_TOTAL, 100)[offset(25)], 0) as gelir_p25,
    round(approx_quantiles(a.AMT_INCOME_TOTAL, 100)[offset(75)], 0) as gelir_p75,

    -- Repayment behaviour
    round(100 * avg(a.TARGET), 2)                                   as temerrut_pct,
    round(100 * countif(m.total_late_months > 0) / count(*), 2)     as gecmiste_gecikme_pct,
    round(avg(m.debt_to_credit_ratio), 3)                           as ort_borc_kredi_orani

from {{ source('home_credit', 'application_train') }} a
left join {{ ref('mart_customer_credit_history') }} m
    on a.SK_ID_CURR = m.SK_ID_CURR
group by egitim