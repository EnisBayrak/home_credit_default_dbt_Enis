-- =============================================================================
-- 04 -- CATEGORICAL PROFILE
-- -----------------------------------------------------------------------------
-- Three questions for every text column:
--   1. WHAT values exist?          -> unexpected categories, typos
--   2. HOW OFTEN does each appear? -> rare categories that add noise
--   3. Are they CLEAN?             -> case inconsistency, hidden whitespace
--
-- Question 3 is the sneaky one. 'Active', 'active' and 'Active ' are three
-- different values to a database and one value to a human. GROUP BY will split
-- them into three rows and your counts will quietly be wrong.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 4.1  Full inventory of every categorical value with its frequency
-- The window function SUM(COUNT(*)) OVER () gives the grand total on every row,
-- which lets us compute each value's share without a second query.
-- -----------------------------------------------------------------------------
with categories as (

  select 'CREDIT_ACTIVE'   as column_name, CREDIT_ACTIVE   as value, count(*) as row_count
  from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` group by 1, 2

  union all
  select 'CREDIT_CURRENCY', CREDIT_CURRENCY, count(*)
  from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` group by 1, 2

  union all
  select 'CREDIT_TYPE', CREDIT_TYPE, count(*)
  from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` group by 1, 2

)
select
  column_name,
  value,
  row_count,
  round(100 * row_count / sum(row_count) over (partition by column_name), 4) as pct_of_column,
  -- HYGIENE FLAGS -------------------------------------------------------------
  -- Does the value change when trimmed? Then it has hidden padding.
  value != trim(value)                                    as has_hidden_whitespace,
  -- Does it contain an internal space? Not an error, but it matters when you
  -- turn these values into column names later ('Bad debt' -> bad_debt).
  strpos(trim(value), ' ') > 0                            as contains_inner_space,
  -- Is it mixed case? If some rows say 'Active' and others 'ACTIVE', you have a
  -- consistency problem that GROUP BY will happily hide from you.
  value != initcap(value)                                 as not_title_case,
  -- RARE CATEGORY FLAG: below 1% of rows. These survive one-hot encoding as
  -- columns of almost pure zeros -- noise that encourages overfitting.
  row_count < 0.01 * sum(row_count) over (partition by column_name) as is_rare_category
from categories
order by column_name, row_count desc;


-- -----------------------------------------------------------------------------
-- 4.2  Case-insensitive collision check
-- If lowercasing two different raw values makes them identical, you have found
-- a case-consistency bug. Expected result: zero rows returned.
-- -----------------------------------------------------------------------------
select
  lower(trim(CREDIT_TYPE))                                as normalised_value,
  count(distinct CREDIT_TYPE)                             as distinct_raw_spellings,
  string_agg(distinct CREDIT_TYPE, ' | ')                 as the_spellings
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by normalised_value
having count(distinct CREDIT_TYPE) > 1;


-- -----------------------------------------------------------------------------
-- 4.3  bureau_balance STATUS -- distribution and validity
-- Any value outside the known set is corruption and must be investigated.
-- -----------------------------------------------------------------------------
select
  STATUS,
  count(*)                                                as row_count,
  round(100 * count(*) / sum(count(*)) over (), 2)        as pct_of_rows,
  length(STATUS)                                          as character_length,
  STATUS not in ('0','1','2','3','4','5','C','X')         as is_unexpected_value
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
group by STATUS
order by row_count desc;
