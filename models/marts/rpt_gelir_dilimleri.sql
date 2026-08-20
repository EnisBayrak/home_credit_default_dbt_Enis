
{{ config(materialized='table') }}

with ranked as (

    select
        TARGET,
        AMT_INCOME_TOTAL,
        ntile(10) over (order by AMT_INCOME_TOTAL) as gelir_dilimi
    from {{ source('home_credit', 'application_train') }}

)

select
    gelir_dilimi,
    round(min(AMT_INCOME_TOTAL), 0)   as dilim_alt_siniri,
    round(max(AMT_INCOME_TOTAL), 0)   as dilim_ust_siniri,
    count(*)                          as musteri_sayisi,
    round(100 * avg(TARGET), 2)       as temerrut_pct
from ranked
group by gelir_dilimi