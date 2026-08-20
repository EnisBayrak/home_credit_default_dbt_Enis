
{{ config(materialized='table') }}

select
    case
        when floor(-a.DAYS_BIRTH/365) < 30 then '1_genc (21-29)'
        when floor(-a.DAYS_BIRTH/365) < 40 then '2_otuzlar (30-39)'
        when floor(-a.DAYS_BIRTH/365) < 50 then '3_kirklar (40-49)'
        when floor(-a.DAYS_BIRTH/365) < 60 then '4_elliler (50-59)'
        else                                    '5_altmis_arti (60+)'
    end                                                             as yas_grubu,
    count(*)                                                        as musteri_sayisi,
    round(approx_quantiles(a.AMT_INCOME_TOTAL, 100)[offset(50)], 0) as gelir_medyan,
    round(100 * avg(a.TARGET), 2)                                   as temerrut_pct,
    round(100 * countif(m.total_late_months > 0) / count(*), 2)     as gecmiste_gecikme_pct,
    round(avg(m.loans_opened_last_year), 2)                         as son_yil_acilan_kredi_ort

from {{ source('home_credit', 'application_train') }} a
left join {{ ref('mart_customer_credit_history') }} m
    on a.SK_ID_CURR = m.SK_ID_CURR
group by yas_grubu