-- ============================================================================
-- mart_customer_credit_history
-- ----------------------------------------------------------------------------
-- One analysis-ready row per customer (305,811). Inputs are the ORIGINAL
-- bureau columns; outputs are aggregates, which are new concepts and
-- therefore carry descriptive new names.
--
-- SOURCE VALUES ARE NOT ALTERED anywhere in this pipeline anymore. The two
-- data-quality realities we measured are handled here, at aggregation time,
-- transparently:
--
--   * CURRENCY GUARD -- 1,408 rows sit in currency 2/3/4 with no exchange
--     rate available anywhere in the dataset. Every money aggregate below is
--     computed over currency-1 rows only; the excluded rows are counted in
--     foreign_currency_loans so nothing disappears silently.
--
--   * NEGATIVE DEBTS -- 8,418 rows carry AMT_CREDIT_SUM_DEBT < 0 (all credit
--     cards; part mirrors the credit limit, part looks like genuine
--     overpayment). The raw values stay untouched upstream. Here, GREATEST(x,0)
--     floors them at zero ONLY inside the debt sums, so a customer's total
--     debt is not reduced by bookkeeping negatives. The affected loans are
--     counted in loans_with_negative_debt for auditability.
-- ============================================================================

{{ config(materialized='table') }}

with loans as (

    select * from {{ ref('int_bureau_enriched') }}

),

by_customer as (

    select
        SK_ID_CURR,

        -- ================= PORTFOLIO SHAPE =================
        count(*)                                            as total_bureau_loans,
        countif(CREDIT_ACTIVE = 'Active')                   as active_loans,
        countif(CREDIT_ACTIVE = 'Closed')                   as closed_loans,
        countif(CREDIT_ACTIVE = 'Bad debt')                 as bad_debt_loans,
        count(distinct CREDIT_TYPE)                         as distinct_credit_types,

        -- ================= RECENCY OF BORROWING =================
        -- DAYS_CREDIT is negative "days before application", so the NEWEST
        -- loan has the LARGEST (closest to zero) value: MAX = newest.
        -- We keep the source sign convention and only translate at the edge,
        -- flipping to positive "days since" in the output metric.
        -1 * max(DAYS_CREDIT)                               as days_since_newest_loan,
        -1 * min(DAYS_CREDIT)                               as days_since_oldest_loan,
        countif(DAYS_CREDIT >= -365)                        as loans_opened_last_year,

        -- ================= MONEY (currency-1 only) =================
        sum(if(CREDIT_CURRENCY = 'currency 1',
               AMT_CREDIT_SUM, null))                       as total_credit_amount,
        sum(if(CREDIT_CURRENCY = 'currency 1',
               greatest(AMT_CREDIT_SUM_DEBT, 0), null))     as total_current_debt,
        sum(if(CREDIT_CURRENCY = 'currency 1',
               AMT_CREDIT_SUM_OVERDUE, null))               as total_overdue_amount,
        max(if(CREDIT_CURRENCY = 'currency 1',
               AMT_CREDIT_MAX_OVERDUE, null))               as worst_overdue_ever,

        -- Ratio built from the two sums (not an average of per-loan ratios,
        -- which would over-weight tiny loans).
        round(safe_divide(
            sum(if(CREDIT_CURRENCY = 'currency 1',
                   greatest(AMT_CREDIT_SUM_DEBT, 0), null)),
            sum(if(CREDIT_CURRENCY = 'currency 1',
                   AMT_CREDIT_SUM, null))
        ), 4)                                               as debt_to_credit_ratio,

        -- ================= DELINQUENCY =================
        max(worst_dpd_bucket)                               as worst_dpd_bucket_ever,
        sum(months_late_count)                              as total_late_months,
        min(months_since_last_late)                         as months_since_last_late,
        countif(CREDIT_DAY_OVERDUE > 0)                     as loans_currently_overdue,

        -- ================= EVIDENCE QUALITY =================
        countif(has_monthly_history)                        as loans_with_history,
        round(safe_divide(countif(has_monthly_history), count(*)), 4)
                                                            as share_loans_with_history,
        countif(CREDIT_CURRENCY != 'currency 1')            as foreign_currency_loans,
        countif(AMT_CREDIT_SUM_DEBT < 0)                    as loans_with_negative_debt

    from loans
    group by SK_ID_CURR

)

select * from by_customer
