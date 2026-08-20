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



select
  count(*)                                                as total_rows,
  count(distinct to_json_string(t))                       as distinct_full_rows,
  count(*) - count(distinct to_json_string(t))            as identical_duplicate_rows
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` as t;
