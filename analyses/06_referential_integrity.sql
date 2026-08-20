
with b as (
  select * from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
),
bb as (
  select * from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
)
select
  
  (select count(distinct SK_ID_BUREAU) from b)                      as loans_in_bureau,
  
  (select count(distinct SK_ID_BUREAU) from bb)                     as loans_in_balance,

  
  (select count(distinct bb.SK_ID_BUREAU)
     from bb left join b using (SK_ID_BUREAU)
     where b.SK_ID_BUREAU is null)                                  as orphan_loans_in_balance,

  
  (select count(distinct b.SK_ID_BUREAU)
     from b left join bb using (SK_ID_BUREAU)
     where bb.SK_ID_BUREAU is null)                                 as loans_without_any_history,

 
  (select count(*) from b)                                          as bureau_row_count;



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
  
  (select count(*) from b left join applicants using (SK_ID_CURR)
     where applicants.SK_ID_CURR is null)                           as bureau_customers_not_in_applications,
  
  (select count(*) from applicants left join b using (SK_ID_CURR)
     where b.SK_ID_CURR is null)                                    as applicants_without_bureau_history;



select
  (select count(*) from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`) as rows_before_join,
  (select count(*)
     from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` b
     left join (
       select SK_ID_BUREAU, count(*) as months
       from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
       group by SK_ID_BUREAU
     ) s using (SK_ID_BUREAU))                                      as rows_after_join;

