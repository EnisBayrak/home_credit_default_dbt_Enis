

with src as (
  select * from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
),

profile as (

  
  select 'AMT_CREDIT_SUM' as column_name,
         countif(AMT_CREDIT_SUM is null)                              as null_count,
         countif(AMT_CREDIT_SUM = 0)                                  as zero_count,
         countif(AMT_CREDIT_SUM < 0)                                  as negative_count,
         min(AMT_CREDIT_SUM)                                          as min_value,
         approx_quantiles(AMT_CREDIT_SUM, 100)[offset(1)]             as p01,
         approx_quantiles(AMT_CREDIT_SUM, 100)[offset(25)]            as p25,
         approx_quantiles(AMT_CREDIT_SUM, 100)[offset(50)]            as median,
         approx_quantiles(AMT_CREDIT_SUM, 100)[offset(75)]            as p75,
         approx_quantiles(AMT_CREDIT_SUM, 100)[offset(99)]            as p99,
         max(AMT_CREDIT_SUM)                                          as max_value
  from src

  union all
  select 'AMT_CREDIT_SUM_DEBT',
         countif(AMT_CREDIT_SUM_DEBT is null), countif(AMT_CREDIT_SUM_DEBT = 0),
         countif(AMT_CREDIT_SUM_DEBT < 0), min(AMT_CREDIT_SUM_DEBT),
         approx_quantiles(AMT_CREDIT_SUM_DEBT, 100)[offset(1)],
         approx_quantiles(AMT_CREDIT_SUM_DEBT, 100)[offset(25)],
         approx_quantiles(AMT_CREDIT_SUM_DEBT, 100)[offset(50)],
         approx_quantiles(AMT_CREDIT_SUM_DEBT, 100)[offset(75)],
         approx_quantiles(AMT_CREDIT_SUM_DEBT, 100)[offset(99)],
         max(AMT_CREDIT_SUM_DEBT)
  from src

  union all
  select 'AMT_CREDIT_SUM_LIMIT',
         countif(AMT_CREDIT_SUM_LIMIT is null), countif(AMT_CREDIT_SUM_LIMIT = 0),
         countif(AMT_CREDIT_SUM_LIMIT < 0), min(AMT_CREDIT_SUM_LIMIT),
         approx_quantiles(AMT_CREDIT_SUM_LIMIT, 100)[offset(1)],
         approx_quantiles(AMT_CREDIT_SUM_LIMIT, 100)[offset(25)],
         approx_quantiles(AMT_CREDIT_SUM_LIMIT, 100)[offset(50)],
         approx_quantiles(AMT_CREDIT_SUM_LIMIT, 100)[offset(75)],
         approx_quantiles(AMT_CREDIT_SUM_LIMIT, 100)[offset(99)],
         max(AMT_CREDIT_SUM_LIMIT)
  from src

  union all
  select 'AMT_CREDIT_SUM_OVERDUE',
         countif(AMT_CREDIT_SUM_OVERDUE is null), countif(AMT_CREDIT_SUM_OVERDUE = 0),
         countif(AMT_CREDIT_SUM_OVERDUE < 0), min(AMT_CREDIT_SUM_OVERDUE),
         approx_quantiles(AMT_CREDIT_SUM_OVERDUE, 100)[offset(1)],
         approx_quantiles(AMT_CREDIT_SUM_OVERDUE, 100)[offset(25)],
         approx_quantiles(AMT_CREDIT_SUM_OVERDUE, 100)[offset(50)],
         approx_quantiles(AMT_CREDIT_SUM_OVERDUE, 100)[offset(75)],
         approx_quantiles(AMT_CREDIT_SUM_OVERDUE, 100)[offset(99)],
         max(AMT_CREDIT_SUM_OVERDUE)
  from src

  union all
  select 'AMT_CREDIT_MAX_OVERDUE',
         countif(AMT_CREDIT_MAX_OVERDUE is null), countif(AMT_CREDIT_MAX_OVERDUE = 0),
         countif(AMT_CREDIT_MAX_OVERDUE < 0), min(AMT_CREDIT_MAX_OVERDUE),
         approx_quantiles(AMT_CREDIT_MAX_OVERDUE, 100)[offset(1)],
         approx_quantiles(AMT_CREDIT_MAX_OVERDUE, 100)[offset(25)],
         approx_quantiles(AMT_CREDIT_MAX_OVERDUE, 100)[offset(50)],
         approx_quantiles(AMT_CREDIT_MAX_OVERDUE, 100)[offset(75)],
         approx_quantiles(AMT_CREDIT_MAX_OVERDUE, 100)[offset(99)],
         max(AMT_CREDIT_MAX_OVERDUE)
  from src

  union all
  select 'AMT_ANNUITY',
         countif(AMT_ANNUITY is null), countif(AMT_ANNUITY = 0),
         countif(AMT_ANNUITY < 0), min(AMT_ANNUITY),
         approx_quantiles(AMT_ANNUITY, 100)[offset(1)],
         approx_quantiles(AMT_ANNUITY, 100)[offset(25)],
         approx_quantiles(AMT_ANNUITY, 100)[offset(50)],
         approx_quantiles(AMT_ANNUITY, 100)[offset(75)],
         approx_quantiles(AMT_ANNUITY, 100)[offset(99)],
         max(AMT_ANNUITY)
  from src

  
  union all
  select 'DAYS_CREDIT',
         countif(DAYS_CREDIT is null), countif(DAYS_CREDIT = 0),
         countif(DAYS_CREDIT < 0), min(DAYS_CREDIT),
         approx_quantiles(DAYS_CREDIT, 100)[offset(1)],
         approx_quantiles(DAYS_CREDIT, 100)[offset(25)],
         approx_quantiles(DAYS_CREDIT, 100)[offset(50)],
         approx_quantiles(DAYS_CREDIT, 100)[offset(75)],
         approx_quantiles(DAYS_CREDIT, 100)[offset(99)],
         max(DAYS_CREDIT)
  from src

  union all
  select 'DAYS_CREDIT_ENDDATE',
         countif(DAYS_CREDIT_ENDDATE is null), countif(DAYS_CREDIT_ENDDATE = 0),
         countif(DAYS_CREDIT_ENDDATE < 0), min(DAYS_CREDIT_ENDDATE),
         approx_quantiles(DAYS_CREDIT_ENDDATE, 100)[offset(1)],
         approx_quantiles(DAYS_CREDIT_ENDDATE, 100)[offset(25)],
         approx_quantiles(DAYS_CREDIT_ENDDATE, 100)[offset(50)],
         approx_quantiles(DAYS_CREDIT_ENDDATE, 100)[offset(75)],
         approx_quantiles(DAYS_CREDIT_ENDDATE, 100)[offset(99)],
         max(DAYS_CREDIT_ENDDATE)
  from src

  union all
  select 'DAYS_ENDDATE_FACT',
         countif(DAYS_ENDDATE_FACT is null), countif(DAYS_ENDDATE_FACT = 0),
         countif(DAYS_ENDDATE_FACT < 0), min(DAYS_ENDDATE_FACT),
         approx_quantiles(DAYS_ENDDATE_FACT, 100)[offset(1)],
         approx_quantiles(DAYS_ENDDATE_FACT, 100)[offset(25)],
         approx_quantiles(DAYS_ENDDATE_FACT, 100)[offset(50)],
         approx_quantiles(DAYS_ENDDATE_FACT, 100)[offset(75)],
         approx_quantiles(DAYS_ENDDATE_FACT, 100)[offset(99)],
         max(DAYS_ENDDATE_FACT)
  from src

  union all
  select 'DAYS_CREDIT_UPDATE',
         countif(DAYS_CREDIT_UPDATE is null), countif(DAYS_CREDIT_UPDATE = 0),
         countif(DAYS_CREDIT_UPDATE < 0), min(DAYS_CREDIT_UPDATE),
         approx_quantiles(DAYS_CREDIT_UPDATE, 100)[offset(1)],
         approx_quantiles(DAYS_CREDIT_UPDATE, 100)[offset(25)],
         approx_quantiles(DAYS_CREDIT_UPDATE, 100)[offset(50)],
         approx_quantiles(DAYS_CREDIT_UPDATE, 100)[offset(75)],
         approx_quantiles(DAYS_CREDIT_UPDATE, 100)[offset(99)],
         max(DAYS_CREDIT_UPDATE)
  from src

  union all
  select 'CREDIT_DAY_OVERDUE',
         countif(CREDIT_DAY_OVERDUE is null), countif(CREDIT_DAY_OVERDUE = 0),
         countif(CREDIT_DAY_OVERDUE < 0), min(CREDIT_DAY_OVERDUE),
         approx_quantiles(CREDIT_DAY_OVERDUE, 100)[offset(1)],
         approx_quantiles(CREDIT_DAY_OVERDUE, 100)[offset(25)],
         approx_quantiles(CREDIT_DAY_OVERDUE, 100)[offset(50)],
         approx_quantiles(CREDIT_DAY_OVERDUE, 100)[offset(75)],
         approx_quantiles(CREDIT_DAY_OVERDUE, 100)[offset(99)],
         max(CREDIT_DAY_OVERDUE)
  from src

  union all
  select 'CNT_CREDIT_PROLONG',
         countif(CNT_CREDIT_PROLONG is null), countif(CNT_CREDIT_PROLONG = 0),
         countif(CNT_CREDIT_PROLONG < 0), min(CNT_CREDIT_PROLONG),
         approx_quantiles(CNT_CREDIT_PROLONG, 100)[offset(1)],
         approx_quantiles(CNT_CREDIT_PROLONG, 100)[offset(25)],
         approx_quantiles(CNT_CREDIT_PROLONG, 100)[offset(50)],
         approx_quantiles(CNT_CREDIT_PROLONG, 100)[offset(75)],
         approx_quantiles(CNT_CREDIT_PROLONG, 100)[offset(99)],
         max(CNT_CREDIT_PROLONG)
  from src
)

select
  *,
  
  round(safe_divide(max_value, nullif(p99, 0)), 1) as max_to_p99_ratio
from profile
order by max_to_p99_ratio desc nulls last;
