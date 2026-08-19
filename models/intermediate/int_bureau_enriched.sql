-- ============================================================================
-- int_bureau_enriched
-- ----------------------------------------------------------------------------
-- PURPOSE: attach each loan's summarised monthly history to its master record.
--
-- THE CRITICAL DECISION IN THIS FILE IS THE WORD "LEFT".
--
-- Profiling told us that 942,074 of the 1,716,428 loans in `bureau` -- 55% --
-- have no monthly history whatsoever. If we wrote INNER JOIN here, those rows
-- would evaporate. The query would run fine. No error, no warning. You would
-- simply be analysing a little under half your data and never know it.
--
-- That is the most expensive kind of bug: the silent one. LEFT JOIN keeps
-- `bureau` as the spine and lets the history columns arrive as NULL where it
-- does not exist -- and we flag that absence explicitly, because "we have no
-- payment history on this loan" is itself a meaningful fact about a borrower.
--
-- (The mirror-image problem also exists: 43,041 loan IDs appear in
-- bureau_balance with no parent in bureau. A LEFT JOIN from bureau correctly
-- ignores those orphans. They are logged, not silently dropped -- see the
-- orphan test in _home_credit__models.yml.)
-- ============================================================================

{{ config(materialized='table') }}

with loans as (

    select * from {{ ref('stg_bureau') }}

),

history as (

    select * from {{ ref('int_bureau_balance_summarized') }}

),

joined as (

    select
        -- ---------- Everything from the loan master record ----------
        loans.*,

        -- ---------- History metrics (NULL for 55% of rows, by design) --------
        history.months_of_history,
        history.worst_dpd_bucket,
        history.months_late_count,
        history.months_written_off_count,
        history.share_of_months_late,
        history.months_since_last_late,
        history.months_closed_count,
        history.share_of_months_unknown,

        -- ---------- The flag that prevents the silent bug ----------
        -- Any downstream analyst who averages `share_of_months_late` MUST know
        -- whether they are averaging over 45% of the population or all of it.
        history.bureau_loan_id is not null          as has_monthly_history

    from loans
    left join history
        on loans.bureau_loan_id = history.bureau_loan_id

)

select * from joined
