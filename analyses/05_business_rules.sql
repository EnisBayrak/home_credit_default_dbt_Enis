-- =============================================================================
-- 05 -- BUSINESS RULES AND CROSS-COLUMN LOGIC
-- -----------------------------------------------------------------------------
-- This is where the real defects hide, and it is the part no automated tool can
-- do for you.
--
-- Every check so far looked at ONE column in isolation. Every value can be
-- individually valid while the ROW as a whole is impossible. A person aged 12
-- is valid. A driving licence is valid. A 12-year-old with a driving licence is
-- not.
--
-- Writing these rules requires understanding the BUSINESS, not the data. That
-- is what makes them the most valuable checks you will write -- and the ones
-- most often skipped.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 5.1  All rules in one pass, each with its own violation count.
-- Run this, and any non-zero number is a conversation you need to have.
-- -----------------------------------------------------------------------------
select
  count(*)                                                          as total_rows,

  -- RULE 1: Outstanding debt cannot exceed the credit that was granted.
  -- You cannot owe more than you were lent (ignoring interest, which this
  -- dataset does not model).
  countif(AMT_CREDIT_SUM_DEBT > AMT_CREDIT_SUM)                     as r1_debt_exceeds_credit,

  -- RULE 2: A closed credit should carry no outstanding debt.
  -- If it does, either the status is stale or the debt figure is.
  countif(CREDIT_ACTIVE = 'Closed' and AMT_CREDIT_SUM_DEBT > 0)     as r2_closed_but_indebted,

  -- RULE 3: A closed credit must have an actual end date.
  -- The mirror of the structural NULL we identified earlier: NULL is correct
  -- for Active loans, but suspicious for Closed ones.
  countif(CREDIT_ACTIVE = 'Closed' and DAYS_ENDDATE_FACT is null)   as r3_closed_without_end_date,

  -- RULE 4: An active credit should NOT have an actual end date.
  -- The reverse violation: if it ended, why is it still marked Active?
  countif(CREDIT_ACTIVE = 'Active' and DAYS_ENDDATE_FACT is not null) as r4_active_but_ended,

  -- RULE 5: A credit cannot end before it began.
  -- Time only runs one way.
  countif(DAYS_CREDIT_ENDDATE < DAYS_CREDIT)                        as r5_ends_before_it_starts,

  -- RULE 6: A credit cannot have been applied for in the future.
  -- DAYS_CREDIT is measured backwards from the application date, so a positive
  -- value would mean "applied for after today".
  countif(DAYS_CREDIT > 0)                                          as r6_applied_in_the_future,

  -- RULE 7: Absurd durations. 18,250 days is 50 years.
  -- A consumer credit ending 85 years from now is a data-entry accident.
  countif(DAYS_CREDIT_ENDDATE > 18250)                              as r7_ends_beyond_50_years,
  countif(DAYS_CREDIT_ENDDATE < -18250)                             as r7b_ended_over_50_years_ago,

  -- RULE 8: Overdue days and overdue amount must agree.
  -- If the borrower is late, there should be money outstanding, and vice versa.
  -- Disagreement means one of the two columns is unreliable.
  countif(CREDIT_DAY_OVERDUE > 0 and AMT_CREDIT_SUM_OVERDUE = 0)    as r8_late_but_owes_nothing,
  countif(CREDIT_DAY_OVERDUE = 0 and AMT_CREDIT_SUM_OVERDUE > 0)    as r8b_owes_but_not_late,

  -- RULE 9: The worst-ever overdue amount cannot be smaller than the current
  -- overdue amount. A maximum is never below a current value.
  countif(AMT_CREDIT_MAX_OVERDUE < AMT_CREDIT_SUM_OVERDUE)          as r9_max_below_current,

  -- RULE 10: A credit of exactly zero is not a credit.
  countif(AMT_CREDIT_SUM = 0)                                       as r10_zero_value_credit,

  -- RULE 11: Only credit-card products should carry a credit limit.
  countif(AMT_CREDIT_SUM_LIMIT > 0 and CREDIT_TYPE != 'Credit card') as r11_limit_on_non_card

from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`;


-- -----------------------------------------------------------------------------
-- 5.2  THE SIGN-FLIP HYPOTHESIS
-- Profiling revealed something striking: the most negative AMT_CREDIT_SUM_DEBT
-- and the largest AMT_CREDIT_SUM_LIMIT are the SAME NUMBER with opposite signs
-- (-4,705,600.32 and +4,705,600.32).
--
-- That is not a coincidence. It suggests the negative debts are not random
-- noise but a systematic error -- values landing in the wrong column, or a sign
-- being flipped during export.
--
-- This matters enormously for the FIX. Clamping to zero treats it as noise.
-- If it is a sign flip, the correct repair is ABS() -- or moving the value to
-- the right column. Run this before deciding.
-- -----------------------------------------------------------------------------
select
  count(*)                                                          as negative_debt_rows,
  -- Do the negative debts mirror values found in the limit column?
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


-- -----------------------------------------------------------------------------
-- 5.3  Inspect actual violating rows before deciding what to do.
-- NEVER design a fix from a count alone. Look at 20 real rows first -- the
-- pattern is usually obvious once you see them side by side.
-- -----------------------------------------------------------------------------
select
  SK_ID_BUREAU, SK_ID_CURR, CREDIT_ACTIVE, CREDIT_TYPE,
  AMT_CREDIT_SUM, AMT_CREDIT_SUM_DEBT, AMT_CREDIT_SUM_LIMIT,
  DAYS_CREDIT, DAYS_CREDIT_ENDDATE, DAYS_ENDDATE_FACT
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
where AMT_CREDIT_SUM_DEBT > AMT_CREDIT_SUM      -- swap this condition to
                                                 -- inspect any other rule
order by AMT_CREDIT_SUM_DEBT - AMT_CREDIT_SUM desc
limit 20;
