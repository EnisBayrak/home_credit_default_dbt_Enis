select
  case
    when AMT_CREDIT < 100000 then '<100k'
    when AMT_CREDIT < 200000 then '100-200k'
    when AMT_CREDIT < 500000 then '200-500k'
    else '500k+'
  end as credit_band,
  count(*) as n,
  round(100 * avg(TARGET), 2) as default_rate_pct
from {{ ref('int_application_train_features') }}
group by credit_band
order by credit_band