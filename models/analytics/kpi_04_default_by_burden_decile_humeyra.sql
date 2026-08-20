with scored as (
  select
    ntile(10) over (order by annuity_to_credit_ratio) as decile,
    TARGET
  from {{ ref('int_application_train_features') }}
  where annuity_to_credit_ratio is not null
)
select
  decile,
  count(*) as n,
  round(100 * avg(TARGET), 2) as default_rate_pct
from scored
group by decile
order by decile