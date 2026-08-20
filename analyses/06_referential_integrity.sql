-- =============================================================================
-- 06 -- REFERENTIAL INTEGRITY, ORPHANS AND JOIN CARDINALITY
-- -----------------------------------------------------------------------------
-- Three separate questions that people habitually collapse into one:
--
--   A. ORPHANS      -- do child rows point at parents that do not exist?
--   B. COVERAGE     -- do parent rows have any children at all?
--   C. CARDINALITY  -- how MANY children does a parent have?
--
-- C is the one that gets skipped, and it is the one that silently multiplies
-- your row count. If a parent has 3 matching children, a LEFT JOIN turns one
-- row into three. Your totals triple. No error is raised. This is called
-- FAN-OUT and it is the single most common cause of wrong numbers in analytics.
--
-- ANALOGY: you join a list of 100 employees to a list of their phone numbers.
-- Some have two phones. Suddenly your "employee count" is 130 and payroll is
-- overstated -- and nothing anywhere said a word.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 6.1  Orphans and coverage in BOTH directions
-- Always check both. Checking only one direction is how half a dataset goes
-- missing without anyone noticing.
-- -----------------------------------------------------------------------------
with b as (
  select * from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
),
bb as (
  select * from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
)
select
  -- Parent side
  (select count(distinct SK_ID_BUREAU) from b)                      as loans_in_bureau,
  -- Child side
  (select count(distinct SK_ID_BUREAU) from bb)                     as loans_in_balance,

  -- A. ORPHANS: child rows whose parent does not exist.
  -- These silently disappear in an INNER JOIN from bureau.
  (select count(distinct bb.SK_ID_BUREAU)
     from bb left join b using (SK_ID_BUREAU)
     where b.SK_ID_BUREAU is null)                                  as orphan_loans_in_balance,

  -- B. COVERAGE: parents with no children.
  -- These disappear in an INNER JOIN too -- from the other side.
  (select count(distinct b.SK_ID_BUREAU)
     from b left join bb using (SK_ID_BUREAU)
     where bb.SK_ID_BUREAU is null)                                 as loans_without_any_history,

  -- The row count you MUST preserve through the join.
  (select count(*) from b)                                          as bureau_row_count;


-- -----------------------------------------------------------------------------
-- 6.2  FAN-OUT SAFETY CHECK
-- Before joining anything onto `bureau`, confirm the right-hand table has at
-- most ONE row per bureau_loan_id. If max_rows_per_loan is 1, the join is safe.
-- If it is greater than 1, the join WILL multiply your rows.
--
-- Run this against your aggregated model, not the raw monthly table -- the raw
-- table legitimately has many rows per loan, which is exactly why it must be
-- summarised before joining.
-- -----------------------------------------------------------------------------
select
  count(*)                                                          as summary_rows,
  count(distinct SK_ID_BUREAU)                                      as distinct_loans,
  max(rows_per_loan)                                                as max_rows_per_loan,
  countif(rows_per_loan > 1)                                        as loans_appearing_more_than_once
from (
  select SK_ID_BUREAU, count(*) as rows_per_loan
  from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
  group by SK_ID_BUREAU
);


-- -----------------------------------------------------------------------------
-- 6.3  UPWARD INTEGRITY: does every bureau loan belong to a real applicant?
-- bureau.SK_ID_CURR should exist in application_train or application_test.
-- A loan belonging to nobody is unusable.
-- -----------------------------------------------------------------------------
with b as (
  select distinct SK_ID_CURR from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
),
applicants as (
  select SK_ID_CURR from `home-credit-risk-grup3.home_credit_risk_grup3.application_train`
  union distinct
  select SK_ID_CURR from `home-credit-risk-grup3.home_credit_risk_grup3.application_test`
)
select
  (select count(*) from b)                                          as customers_in_bureau,
  (select count(*) from applicants)                                 as customers_in_applications,
  -- Bureau records pointing at an applicant we do not have
  (select count(*) from b left join applicants using (SK_ID_CURR)
     where applicants.SK_ID_CURR is null)                           as bureau_customers_not_in_applications,
  -- Applicants with no bureau history at all -- NOT an error, just a fact you
  -- must know before you INNER JOIN and lose them.
  (select count(*) from applicants left join b using (SK_ID_CURR)
     where b.SK_ID_CURR is null)                                    as applicants_without_bureau_history;


-- -----------------------------------------------------------------------------
-- 6.4  THE HABIT THAT PREVENTS MOST JOIN BUGS
-- After every join you write, count the rows and compare to what you started
-- with. If the number changed and you did not intend it to, stop and find out
-- why -- before building anything on top of it.
-- -----------------------------------------------------------------------------
select
  (select count(*) from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`) as rows_before_join,
  (select count(*)
     from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` b
     left join (
       select SK_ID_BUREAU, count(*) as months
       from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
       group by SK_ID_BUREAU
     ) s using (SK_ID_BUREAU))                                      as rows_after_join;
-- These two numbers MUST be identical. If they are not, the right-hand side is
-- not unique on the join key and you have a fan-out.
