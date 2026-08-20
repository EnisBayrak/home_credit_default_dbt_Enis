select
  income_band,
  count(*) as n,
  round(100 * avg(TARGET), 2) as default_rate_pct
from {{ ref('int_application_train_features') }}
group by income_band
order by income_band