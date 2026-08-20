select
  occupation_type_clean,
  count(*) as customers_number,
  round(100 * avg(TARGET), 2) as default_rate_pct
from {{ ref('int_application_train_features') }}
group by occupation_type_clean
having count(*) >= 500
order by default_rate_pct desc