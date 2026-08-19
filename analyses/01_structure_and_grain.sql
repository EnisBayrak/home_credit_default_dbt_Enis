-- =============================================================================
-- 01 -- STRUCTURE AND GRAIN
-- -----------------------------------------------------------------------------
-- RUN THIS FIRST. Everything else depends on it.
--
-- "Grain" means: what does ONE ROW represent? Until you can finish the sentence
-- "one row in this table is exactly one ___", you cannot meaningfully check for
-- duplicates -- because duplicate is DEFINED by the grain.
--
-- The core technique below is the same every time:
--     COUNT(*) vs COUNT(DISTINCT <candidate key>)
-- If the two numbers match, the key is unique. If COUNT(*) is larger, the
-- difference IS the number of duplicate rows. No guessing required.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1.1  bureau -- is SK_ID_BUREAU really the primary key?
-- Expected: total_rows = distinct_bureau_ids, duplicate_rows = 0
-- -----------------------------------------------------------------------------
select
  'bureau'                                                as table_name,
  count(*)                                                as total_rows,
  count(distinct SK_ID_BUREAU)                            as distinct_bureau_ids,
  count(*) - count(distinct SK_ID_BUREAU)                 as duplicate_rows,
  count(distinct SK_ID_CURR)                              as distinct_customers,
  -- How many loans does an average customer carry? A useful sanity number:
  -- if this were 1.0 the table would not need a separate ID at all.
  round(count(*) / count(distinct SK_ID_CURR), 2)         as avg_loans_per_customer,
  -- NULL keys are catastrophic: they join to nothing and are invisible in
  -- GROUP BY results. Must be zero.
  countif(SK_ID_BUREAU is null)                           as null_bureau_ids,
  countif(SK_ID_CURR is null)                             as null_customer_ids
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`;


-- -----------------------------------------------------------------------------
-- 1.2  bureau_balance -- the key here is a PAIR of columns, not one
-- We concatenate the two columns with a separator so COUNT(DISTINCT) can
-- evaluate the combination as a single value.
--
-- WHY THE '|' SEPARATOR MATTERS: without it, ('12', '34') and ('123', '4')
-- would both become '1234' and be counted as the same key. The separator makes
-- the boundary unambiguous. This is a classic silent bug.
-- Expected: total_rows = distinct_loan_month_pairs
-- -----------------------------------------------------------------------------
select
  'bureau_balance'                                        as table_name,
  count(*)                                                as total_rows,
  count(distinct SK_ID_BUREAU)                            as distinct_loans,
  count(distinct concat(cast(SK_ID_BUREAU as string), '|',
                        cast(MONTHS_BALANCE as string)))  as distinct_loan_month_pairs,
  count(*) - count(distinct concat(cast(SK_ID_BUREAU as string), '|',
                        cast(MONTHS_BALANCE as string)))  as duplicate_rows,
  round(count(*) / count(distinct SK_ID_BUREAU), 1)       as avg_months_per_loan,
  min(MONTHS_BALANCE)                                     as oldest_month_index,
  max(MONTHS_BALANCE)                                     as newest_month_index,
  countif(SK_ID_BUREAU is null)                           as null_loan_ids,
  countif(MONTHS_BALANCE is null)                         as null_month_index
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`;


-- -----------------------------------------------------------------------------
-- 1.3  If 1.1 or 1.2 reports duplicates, THIS query shows you the actual rows.
-- A count tells you a problem exists; this tells you what it looks like.
-- Uncomment and run only when needed.
-- -----------------------------------------------------------------------------
-- select SK_ID_BUREAU, count(*) as times_repeated
-- from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
-- group by SK_ID_BUREAU
-- having count(*) > 1
-- order by times_repeated desc
-- limit 50;


-- -----------------------------------------------------------------------------
-- 1.4  Are there fully identical rows (every column the same)?
-- Different from a key duplicate: this catches an accidental double-load of the
-- same file, where every value repeats -- not just the ID.
-- TO_JSON_STRING turns the whole row into one text value so we can compare
-- entire rows in a single expression.
-- -----------------------------------------------------------------------------
select
  count(*)                                                as total_rows,
  count(distinct to_json_string(t))                       as distinct_full_rows,
  count(*) - count(distinct to_json_string(t))            as identical_duplicate_rows
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` as t;
