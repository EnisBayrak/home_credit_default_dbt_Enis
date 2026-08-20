
select
  CREDIT_ACTIVE,
  count(*)                                                          as rows_in_group,
  countif(DAYS_ENDDATE_FACT is null)                                as null_end_date,
  round(100 * countif(DAYS_ENDDATE_FACT is null) / count(*), 1)     as pct_null_end_date
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by CREDIT_ACTIVE
order by rows_in_group desc;



select
  case when AMT_CREDIT_MAX_OVERDUE is null then 'MAX_OVERDUE is NULL'
       else 'MAX_OVERDUE has a value' end                           as group_label,
  count(*)                                                          as rows_in_group,
  countif(AMT_CREDIT_SUM_OVERDUE = 0)                               as also_zero_current_overdue,
  countif(CREDIT_DAY_OVERDUE = 0)                                   as also_zero_overdue_days,
  round(100 * countif(AMT_CREDIT_SUM_OVERDUE = 0 and CREDIT_DAY_OVERDUE = 0)
        / count(*), 2)                                              as pct_also_clean
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by group_label;



select
  CREDIT_TYPE,
  count(*)                                                          as rows_in_group,
  round(100 * countif(AMT_ANNUITY is null) / count(*), 1)           as pct_null_annuity,
  round(100 * countif(AMT_CREDIT_SUM_LIMIT is null) / count(*), 1)  as pct_null_limit,
  round(100 * countif(AMT_CREDIT_SUM_DEBT is null) / count(*), 1)   as pct_null_debt
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by CREDIT_TYPE
order by rows_in_group desc;



select
 
  cast(floor(-1 * DAYS_CREDIT / 365) as int64)                      as years_before_application,
  count(*)                                                          as rows_in_bucket,
  round(100 * countif(AMT_ANNUITY is null) / count(*), 1)           as pct_null_annuity,
  round(100 * countif(AMT_CREDIT_MAX_OVERDUE is null) / count(*), 1) as pct_null_max_overdue,
  round(100 * countif(AMT_CREDIT_SUM_DEBT is null) / count(*), 1)   as pct_null_debt
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by years_before_application
order by years_before_application;



select
  cast(floor(-1 * MONTHS_BALANCE / 12) as int64)                    as years_ago,
  count(*)                                                          as rows_in_bucket,
  round(100 * countif(STATUS = 'X') / count(*), 1)                  as pct_unknown,
  round(100 * countif(STATUS = 'C') / count(*), 1)                  as pct_closed,
  round(100 * countif(STATUS in ('1','2','3','4','5')) / count(*), 2) as pct_delinquent
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
group by years_ago
order by years_ago;
