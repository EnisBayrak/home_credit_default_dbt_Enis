
{{ config(materialized='table') }}

select
    case
        when floor(-DAYS_BIRTH/365) < 30 then '1_genc (21-29)'
        when floor(-DAYS_BIRTH/365) < 45 then '2_orta (30-44)'
        else                                  '3_olgun (45+)'
    end                                          as yas_grubu,
    case
        when NAME_EDUCATION_TYPE in ('Academic degree','Higher education')
                                            then 'yuksek_egitim'
        when NAME_EDUCATION_TYPE = 'Incomplete higher'
                                            then 'yarim_yuksek'
        else                                     'orta_ve_alti'
    end                                          as egitim_bandi,
    count(*)                                     as musteri_sayisi,
    round(100 * avg(TARGET), 2)                  as temerrut_pct

from {{ source('home_credit', 'application_train') }}
group by yas_grubu, egitim_bandi