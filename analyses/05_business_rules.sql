
select
  count(*)                                                          as total_rows,

  
  countif(AMT_CREDIT_SUM_DEBT > AMT_CREDIT_SUM)                     as r1_debt_exceeds_credit,

  
  countif(CREDIT_ACTIVE = 'Closed' and AMT_CREDIT_SUM_DEBT > 0)     as r2_closed_but_indebted,

  
  countif(CREDIT_ACTIVE = 'Closed' and DAYS_ENDDATE_FACT is null)   as r3_closed_without_end_date,

  
  countif(CREDIT_ACTIVE = 'Active' and DAYS_ENDDATE_FACT is not null) as r4_active_but_ended,

  
  countif(DAYS_CREDIT_ENDDATE < DAYS_CREDIT)                        as r5_ends_before_it_starts,

  
  countif(DAYS_CREDIT > 0)                                          as r6_applied_in_the_future,

  
  countif(DAYS_CREDIT_ENDDATE > 18250)                              as r7_ends_beyond_50_years,
  countif(DAYS_CREDIT_ENDDATE < -18250)                             as r7b_ended_over_50_years_ago,

  
  countif(CREDIT_DAY_OVERDUE > 0 and AMT_CREDIT_SUM_OVERDUE = 0)    as r8_late_but_owes_nothing,
  countif(CREDIT_DAY_OVERDUE = 0 and AMT_CREDIT_SUM_OVERDUE > 0)    as r8b_owes_but_not_late,

  
  countif(AMT_CREDIT_MAX_OVERDUE < AMT_CREDIT_SUM_OVERDUE)          as r9_max_below_current,

  
  countif(AMT_CREDIT_SUM = 0)                                       as r10_zero_value_credit,

  
  countif(AMT_CREDIT_SUM_LIMIT > 0 and CREDIT_TYPE != 'Credit card') as r11_limit_on_non_card

from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`;



select
  count(*)                                                          as negative_debt_rows,
  
  countif(abs(AMT_CREDIT_SUM_DEBT) = AMT_CREDIT_SUM_LIMIT)          as debt_mirrors_limit_exactly,
  countif(AMT_CREDIT_SUM_LIMIT is null)                             as limit_is_null,
  countif(AMT_CREDIT_SUM_LIMIT = 0)                                 as limit_is_zero,
  -- What kind of products are affected? A concentration in one credit type
  -- would point at a specific broken source system.
  string_agg(distinct CREDIT_TYPE, ' | ')                           as affected_credit_types,
  string_agg(distinct CREDIT_ACTIVE, ' | ')                         as affected_statuses,
  min(AMT_CREDIT_SUM_DEBT)                                          as most_negative,
  round(avg(AMT_CREDIT_SUM_DEBT), 2)                                as average_negative
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
where AMT_CREDIT_SUM_DEBT < 0;



select
  SK_ID_BUREAU, SK_ID_CURR, CREDIT_ACTIVE, CREDIT_TYPE,
  AMT_CREDIT_SUM, AMT_CREDIT_SUM_DEBT, AMT_CREDIT_SUM_LIMIT,
  DAYS_CREDIT, DAYS_CREDIT_ENDDATE, DAYS_ENDDATE_FACT
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
where AMT_CREDIT_SUM_DEBT > AMT_CREDIT_SUM      
                                                 
order by AMT_CREDIT_SUM_DEBT - AMT_CREDIT_SUM desc
limit 20;
