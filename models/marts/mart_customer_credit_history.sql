

{{ config(materialized='table') }}

with loans as (

    select * from {{ ref('int_bureau_enriched') }}

),

by_customer as (

    select
        SK_ID_CURR,

        
        count(*)                                            as total_bureau_loans,
        countif(CREDIT_ACTIVE = 'Active')                   as active_loans,
        countif(CREDIT_ACTIVE = 'Closed')                   as closed_loans,
        countif(CREDIT_ACTIVE = 'Bad debt')                 as bad_debt_loans,
        count(distinct CREDIT_TYPE)                         as distinct_credit_types,

        
        -1 * max(DAYS_CREDIT)                               as days_since_newest_loan,
        -1 * min(DAYS_CREDIT)                               as days_since_oldest_loan,
        countif(DAYS_CREDIT >= -365)                        as loans_opened_last_year,

        
        sum(if(CREDIT_CURRENCY = 'currency 1',
               AMT_CREDIT_SUM, null))                       as total_credit_amount,
        sum(if(CREDIT_CURRENCY = 'currency 1',
               greatest(AMT_CREDIT_SUM_DEBT, 0), null))     as total_current_debt,
        sum(if(CREDIT_CURRENCY = 'currency 1',
               AMT_CREDIT_SUM_OVERDUE, null))               as total_overdue_amount,
        max(if(CREDIT_CURRENCY = 'currency 1',
               AMT_CREDIT_MAX_OVERDUE, null))               as worst_overdue_ever,

        
        round(safe_divide(
            sum(if(CREDIT_CURRENCY = 'currency 1',
                   greatest(AMT_CREDIT_SUM_DEBT, 0), null)),
            sum(if(CREDIT_CURRENCY = 'currency 1',
                   AMT_CREDIT_SUM, null))
        ), 4)                                               as debt_to_credit_ratio,

        
        max(worst_dpd_bucket)                               as worst_dpd_bucket_ever,
        sum(months_late_count)                              as total_late_months,
        min(months_since_last_late)                         as months_since_last_late,
        countif(CREDIT_DAY_OVERDUE > 0)                     as loans_currently_overdue,

        
        countif(has_monthly_history)                        as loans_with_history,
        round(safe_divide(countif(has_monthly_history), count(*)), 4)
                                                            as share_loans_with_history,
        countif(CREDIT_CURRENCY != 'currency 1')            as foreign_currency_loans,
        countif(AMT_CREDIT_SUM_DEBT < 0)                    as loans_with_negative_debt

    from loans
    group by SK_ID_CURR

)

select * from by_customer
