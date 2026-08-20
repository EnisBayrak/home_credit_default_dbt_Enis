select
  count(*) as total_applications,
  sum(TARGET) as default_count,
  count(*) - sum(TARGET) as non_default_count,
  round(100 * avg(TARGET), 2) as default_rate_pct
from {{ ref('int_application_train_features') }}