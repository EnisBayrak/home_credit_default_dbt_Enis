select
  cast(floor(age_years/5)*5 as int64) as age_band_5y,
  count(*) as customers_number,
  round(100 * avg(TARGET), 2) as default_rate_pct
from {{ ref('int_application_train_features') }}
where age_years is not null
group by age_band_5y
order by age_band_5y