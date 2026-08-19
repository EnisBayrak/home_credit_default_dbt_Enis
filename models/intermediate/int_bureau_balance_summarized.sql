-- ============================================================================
-- int_bureau_balance_summarized
-- ----------------------------------------------------------------------------
-- PURPOSE: collapse 27.3 million monthly rows into 817,395 rows -- one per
-- loan -- so that this history can be joined onto `bureau` without exploding
-- the row count.
--
-- This is the single most important step in the whole pipeline, and the one
-- where most people quietly lose information. Turning a time series into one
-- row is a compression: you choose what survives. Choose badly and the model
-- never sees the thing that actually predicts default.
--
-- Our choices, and why:
--   * WORST point ever      -> captures the peak of the crisis
--   * HOW OFTEN it happened -> distinguishes one bad month from chronic trouble
--   * HOW RECENT it was     -> a default 7 years ago is not today's default
--   * HOW MUCH we observed  -> 3 months of history is weaker evidence than 96
-- ============================================================================

{{ config(materialized='table') }}
-- Materialised as a TABLE, not a view. Reason: this aggregation scans 27M rows.
-- As a view, every downstream query would re-run that scan and re-bill it.
-- Writing the result down once is the difference between cents and euros.

with monthly as (

    select * from {{ ref('stg_bureau_balance') }}

),

summarized as (

    select
        bureau_loan_id,

        -- ---------- Volume of evidence ----------
        count(*)                                    as months_of_history,
        max(months_ago)                             as oldest_month_observed,
        min(months_ago)                             as newest_month_observed,

        -- ---------- Peak severity ----------
        -- MAX ignores NULLs automatically, so 'C' and 'X' months simply do not
        -- vote. A loan whose every month is 'C' returns NULL here, which is the
        -- honest answer: no delinquency was ever recorded.
        max(dpd_bucket)                             as worst_dpd_bucket,

        -- ---------- Frequency ----------
        countif(was_late_this_month)                as months_late_count,
        countif(dpd_bucket = 5)                     as months_written_off_count,

        -- SAFE_DIVIDE returns NULL instead of throwing on division by zero.
        -- The denominator counts only months where lateness is KNOWN, so the
        -- 21% of 'X' months cannot silently deflate the ratio.
        round(safe_divide(
            countif(was_late_this_month),
            countif(was_late_this_month is not null)
        ), 4)                                       as share_of_months_late,

        -- ---------- Recency ----------
        -- MIN over only the late months = how long ago the most recent problem
        -- was. NULL means "never had one". Recency usually beats severity as a
        -- predictor: people recover.
        min(case when was_late_this_month then months_ago end)
                                                    as months_since_last_late,

        -- ---------- Composition ----------
        countif(status_group = 'closed')            as months_closed_count,
        countif(status_group = 'unknown')           as months_unknown_count,

        -- Data-quality signal: if a large share of a loan's history is 'X',
        -- every other metric on this row is built on sand. Downstream models
        -- can use this to down-weight or exclude the loan.
        round(safe_divide(
            countif(status_group = 'unknown'),
            count(*)
        ), 4)                                       as share_of_months_unknown

    from monthly
    group by bureau_loan_id

)

select * from summarized
