-- ============================================================================
-- mart_customer_credit_history
-- ----------------------------------------------------------------------------
-- PURPOSE: the finished dish. One row per customer (305,811 of them), ready to
-- be joined onto the main application table for analysis or modelling.
--
-- This is the second compression in the pipeline: many loans -> one customer.
-- The same discipline applies as in the monthly rollup -- decide deliberately
-- what survives, and write down why.
--
-- CURRENCY GUARD: every money aggregate below is computed ONLY over
-- currency-1 rows. 1,408 rows sit in other currencies with no exchange rate
-- available anywhere in the dataset. Summing them would produce a number that
-- looks perfectly reasonable and is quietly wrong -- the worst possible
-- outcome. We exclude and count them instead.
-- ============================================================================

{{ config(materialized='table') }}

with loans as (

    select * from {{ ref('int_bureau_enriched') }}

),

by_customer as (

    select
        customer_id,

        -- ================= PORTFOLIO SHAPE =================
        count(*)                                            as total_bureau_loans,
        countif(credit_status = 'Active')                   as active_loans,
        countif(credit_status = 'Closed')                   as closed_loans,
        countif(credit_status = 'Bad debt')                 as bad_debt_loans,
        count(distinct credit_type)                         as distinct_credit_types,

        -- ================= RECENCY OF BORROWING =================
        -- A burst of recent applications is a classic distress signal:
        -- somebody shopping hard for credit is often running out of options.
        min(days_since_credit_applied)                      as days_since_newest_loan,
        max(days_since_credit_applied)                      as days_since_oldest_loan,
        countif(days_since_credit_applied <= 365)           as loans_opened_last_year,

        -- ================= MONEY (currency-1 only) =================
        sum(if(not is_foreign_currency, credit_amount, null))
                                                            as total_credit_amount,
        sum(if(not is_foreign_currency, debt_amount, null))
                                                            as total_current_debt,
        sum(if(not is_foreign_currency, overdue_amount, null))
                                                            as total_overdue_amount,
        max(if(not is_foreign_currency, max_overdue_amount_ever, null))
                                                            as worst_overdue_ever,

        -- Debt-to-credit ratio: how much of the granted credit is still owed.
        -- Built from the two sums above rather than averaging per-loan ratios,
        -- because an average of ratios silently over-weights tiny loans.
        round(safe_divide(
            sum(if(not is_foreign_currency, debt_amount, null)),
            sum(if(not is_foreign_currency, credit_amount, null))
        ), 4)                                               as debt_to_credit_ratio,

        -- ================= DELINQUENCY =================
        max(worst_dpd_bucket)                               as worst_dpd_bucket_ever,
        sum(months_late_count)                              as total_late_months,
        min(months_since_last_late)                         as months_since_last_late,
        countif(days_currently_overdue > 0)                 as loans_currently_overdue,

        -- ================= EVIDENCE QUALITY =================
        -- Never let a consumer of this table forget how much of it is guesswork.
        countif(has_monthly_history)                        as loans_with_history,
        round(safe_divide(countif(has_monthly_history), count(*)), 4)
                                                            as share_loans_with_history,
        countif(is_foreign_currency)                        as foreign_currency_loans,
        countif(was_debt_clamped or was_limit_clamped)      as loans_with_repaired_amounts

    from loans
    group by customer_id

)

select * from by_customer
