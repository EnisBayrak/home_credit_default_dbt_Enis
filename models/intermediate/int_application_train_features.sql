{{ config(materialized='view') }}

with a as (
  select *
  from {{ ref('stg_application_train_clean') }}
)

select
  a.*,

  -- Age (DAYS_BIRTH negatif geliyor)
  cast(floor((-a.DAYS_BIRTH) / 365.25) as int64) as age_years,

  -- Income band (EDA’da kullandığın segment)
  case
    when a.AMT_INCOME_TOTAL < 100000 then '<100k'
    when a.AMT_INCOME_TOTAL < 200000 then '100-200k'
    when a.AMT_INCOME_TOTAL < 300000 then '200-300k'
    else '300k+'
  end as income_band,

  -- Credit burden ratio (annuity/credit) - güvenli bölme
  safe_divide(a.AMT_ANNUITY, a.AMT_CREDIT) as annuity_to_credit_ratio

from a