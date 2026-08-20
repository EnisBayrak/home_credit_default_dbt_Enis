
select
  count(*)                                                              as total_rows,
  round(100 * countif(SK_ID_CURR             is null) / count(*), 2)    as pct_null_sk_id_curr,
  round(100 * countif(SK_ID_BUREAU           is null) / count(*), 2)    as pct_null_sk_id_bureau,
  round(100 * countif(CREDIT_ACTIVE          is null) / count(*), 2)    as pct_null_credit_active,
  round(100 * countif(CREDIT_CURRENCY        is null) / count(*), 2)    as pct_null_currency,
  round(100 * countif(DAYS_CREDIT            is null) / count(*), 2)    as pct_null_days_credit,
  round(100 * countif(CREDIT_DAY_OVERDUE     is null) / count(*), 2)    as pct_null_day_overdue,
  round(100 * countif(DAYS_CREDIT_ENDDATE    is null) / count(*), 2)    as pct_null_credit_enddate,
  round(100 * countif(DAYS_ENDDATE_FACT      is null) / count(*), 2)    as pct_null_enddate_fact,
  round(100 * countif(AMT_CREDIT_MAX_OVERDUE is null) / count(*), 2)    as pct_null_max_overdue,
  round(100 * countif(CNT_CREDIT_PROLONG     is null) / count(*), 2)    as pct_null_prolong,
  round(100 * countif(AMT_CREDIT_SUM         is null) / count(*), 2)    as pct_null_credit_sum,
  round(100 * countif(AMT_CREDIT_SUM_DEBT    is null) / count(*), 2)    as pct_null_debt,
  round(100 * countif(AMT_CREDIT_SUM_LIMIT   is null) / count(*), 2)    as pct_null_limit,
  round(100 * countif(AMT_CREDIT_SUM_OVERDUE is null) / count(*), 2)    as pct_null_overdue,
  round(100 * countif(CREDIT_TYPE            is null) / count(*), 2)    as pct_null_credit_type,
  round(100 * countif(DAYS_CREDIT_UPDATE     is null) / count(*), 2)    as pct_null_days_update,
  round(100 * countif(AMT_ANNUITY            is null) / count(*), 2)    as pct_null_annuity
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`;



select
  countif(CREDIT_ACTIVE   = '')                             as empty_credit_active,
  countif(trim(CREDIT_ACTIVE)   = '')                       as blank_credit_active,
  countif(CREDIT_ACTIVE   != trim(CREDIT_ACTIVE))           as padded_credit_active,
  countif(CREDIT_CURRENCY = '')                             as empty_currency,
  countif(CREDIT_CURRENCY != trim(CREDIT_CURRENCY))         as padded_currency,
  countif(CREDIT_TYPE     = '')                             as empty_credit_type,
  countif(CREDIT_TYPE     != trim(CREDIT_TYPE))             as padded_credit_type
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`;



select
  countif(DAYS_CREDIT            = 365243)                  as s_365243_days_credit,
  countif(DAYS_CREDIT_ENDDATE    = 365243)                  as s_365243_enddate,
  countif(DAYS_ENDDATE_FACT      = 365243)                  as s_365243_enddate_fact,
  countif(DAYS_CREDIT_UPDATE     = 365243)                  as s_365243_update,
  -- -1 is a very common "unknown" code in loan systems
  countif(CNT_CREDIT_PROLONG     = -1)                      as s_minus1_prolong,
  countif(AMT_CREDIT_SUM         = -1)                      as s_minus1_credit_sum,
  -- Repeated-9 codes
  countif(AMT_CREDIT_SUM         in (9999, 99999, 999999))  as s_nines_credit_sum,
  countif(AMT_ANNUITY            in (9999, 99999, 999999))  as s_nines_annuity,
  -- Zero where zero makes no business sense: a credit of exactly 0 currency
  -- units is not a credit. Strong candidate for "should have been NULL".
  countif(AMT_CREDIT_SUM         = 0)                       as credit_sum_exactly_zero
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`;



select
  count(*)                                                          as total_rows,
  countif(SK_ID_BUREAU   is null)                                   as null_loan_id,
  countif(MONTHS_BALANCE is null)                                   as null_month,
  countif(STATUS         is null)                                   as null_status,
  countif(STATUS = '')                                              as empty_status,
  countif(STATUS != trim(STATUS))                                   as padded_status,
  
  countif(length(STATUS) != 1)                                      as status_wrong_length
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`;
