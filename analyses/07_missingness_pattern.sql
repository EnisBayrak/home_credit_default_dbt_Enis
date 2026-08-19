-- =============================================================================
-- 07 -- MISSINGNESS PATTERN ANALYSIS
-- -----------------------------------------------------------------------------
-- THIS FILE IS THE METHOD BEHIND "not every NULL is an error".
--
-- Knowing a column is 36.9% NULL tells you nothing about what to DO. The
-- decision depends entirely on WHY it is NULL, and there are two very different
-- reasons:
--
--   STRUCTURAL NULL -- the value cannot exist given the row's other values.
--                      An open loan has no closing date. NULL is the correct,
--                      truthful answer. Imputing anything here is fabrication.
--
--   MISSING NULL    -- the value exists in reality but was not recorded.
--                      A borrower has an annuity; we just do not know it.
--                      Imputation is defensible, if documented.
--
-- HOW TO TELL THEM APART: cross-tabulate the NULL rate against another column.
-- If the NULL rate is ~100% for one group and ~0% for another, the NULL is
-- structural -- the group membership explains it. If the NULL rate is roughly
-- the same everywhere, the data is simply missing.
--
-- ANALOGY: a school register with an empty "military service" column. If it is
-- empty only for students under 18, that is structural. If it is empty at
-- random across all ages, the clerk forgot to fill it in.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 7.1  DAYS_ENDDATE_FACT vs CREDIT_ACTIVE -- the textbook case
-- EXPECTED PATTERN: near-100% NULL for Active, near-0% for Closed.
-- If you see that, the NULL is structural and must be LEFT ALONE.
-- -----------------------------------------------------------------------------
select
  CREDIT_ACTIVE,
  count(*)                                                          as rows_in_group,
  countif(DAYS_ENDDATE_FACT is null)                                as null_end_date,
  round(100 * countif(DAYS_ENDDATE_FACT is null) / count(*), 1)     as pct_null_end_date
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by CREDIT_ACTIVE
order by rows_in_group desc;


-- -----------------------------------------------------------------------------
-- 7.2  AMT_CREDIT_MAX_OVERDUE -- testing the hypothesis directly
-- HYPOTHESIS: NULL here means "this credit was never overdue".
-- TEST: among the NULL rows, is the current overdue amount always zero and the
-- overdue-day count always zero?
--
-- If pct_also_clean is ~100%, the hypothesis holds and filling with 0 is
-- defensible. If it is materially below 100%, the hypothesis is WRONG and
-- filling with 0 would erase real delinquency.
--
-- This is what it means to test an assumption instead of adopting it.
-- -----------------------------------------------------------------------------
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


-- -----------------------------------------------------------------------------
-- 7.3  AMT_ANNUITY -- 71.5% NULL. Is the missingness explained by anything?
-- Break the NULL rate down by credit type. A type-specific pattern would mean
-- the annuity concept simply does not apply to that product.
-- -----------------------------------------------------------------------------
select
  CREDIT_TYPE,
  count(*)                                                          as rows_in_group,
  round(100 * countif(AMT_ANNUITY is null) / count(*), 1)           as pct_null_annuity,
  round(100 * countif(AMT_CREDIT_SUM_LIMIT is null) / count(*), 1)  as pct_null_limit,
  round(100 * countif(AMT_CREDIT_SUM_DEBT is null) / count(*), 1)   as pct_null_debt
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by CREDIT_TYPE
order by rows_in_group desc;


-- -----------------------------------------------------------------------------
-- 7.4  Do NULLs cluster in time?
-- If older records are systematically emptier, the gap is a data-collection
-- artefact rather than a property of the borrower. That distinction changes
-- both how you impute and how much you trust old rows.
-- -----------------------------------------------------------------------------
select
  -- Bucket the credits into years before the application date
  cast(floor(-1 * DAYS_CREDIT / 365) as int64)                      as years_before_application,
  count(*)                                                          as rows_in_bucket,
  round(100 * countif(AMT_ANNUITY is null) / count(*), 1)           as pct_null_annuity,
  round(100 * countif(AMT_CREDIT_MAX_OVERDUE is null) / count(*), 1) as pct_null_max_overdue,
  round(100 * countif(AMT_CREDIT_SUM_DEBT is null) / count(*), 1)   as pct_null_debt
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by years_before_application
order by years_before_application;


-- -----------------------------------------------------------------------------
-- 7.5  bureau_balance -- is the 'X' (unknown) status concentrated anywhere?
-- 21% of all monthly rows are 'X'. If those cluster in old months, recent
-- history is more trustworthy than the overall figure suggests.
-- -----------------------------------------------------------------------------
select
  cast(floor(-1 * MONTHS_BALANCE / 12) as int64)                    as years_ago,
  count(*)                                                          as rows_in_bucket,
  round(100 * countif(STATUS = 'X') / count(*), 1)                  as pct_unknown,
  round(100 * countif(STATUS = 'C') / count(*), 1)                  as pct_closed,
  round(100 * countif(STATUS in ('1','2','3','4','5')) / count(*), 2) as pct_delinquent
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
group by years_ago
order by years_ago;
