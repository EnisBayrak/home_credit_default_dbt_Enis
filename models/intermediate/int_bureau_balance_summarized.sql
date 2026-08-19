-- ============================================================================
-- int_bureau_balance_summarized
-- ----------------------------------------------------------------------------
-- Collapses 27.3M monthly rows into one row per loan, so the history can be
-- joined onto bureau without exploding the row count.
--
-- Reads ORIGINAL columns (SK_ID_BUREAU, MONTHS_BALANCE, STATUS). The STATUS
-- decoding that previously lived in staging happens right here, inside the
-- aggregation, because this is the only place that needs it.
--
-- Reminder of what STATUS holds (measured distribution):
--   C = closed that month (50%), X = unknown (21%), 0 = current (27%),
--   1-5 = delinquency severity buckets (1.26% combined).
-- '0'-'5' are an ordered scale; 'C' and 'X' are NOT points on that scale.
-- SAFE_CAST turns '3' into 3 and 'C'/'X' into NULL -- the honest answer --
-- instead of crashing the query the way plain CAST would.
--
-- The OUTPUT columns are new names by necessity: they are aggregates that do
-- not exist in the source, so there is no original name to preserve.
-- ============================================================================

{{ config(materialized='table') }}
-- TABLE, not view: this scans 27M rows. As a view every downstream query
-- would re-run and re-bill that scan.

with monthly as (

    select
        SK_ID_BUREAU,
        MONTHS_BALANCE,
        STATUS,
        -- Decode once, reuse below. Positive "months ago" reads naturally.
        -1 * MONTHS_BALANCE                  as months_ago,
        safe_cast(STATUS as int64)           as dpd_bucket,
        case
            when STATUS in ('1','2','3','4','5') then true
            when STATUS in ('0','C')             then false
            else null   -- 'X': genuinely unknown; do not guess
        end                                  as was_late_this_month

    from {{ ref('stg_bureau_balance') }}

),

summarized as (

    select
        SK_ID_BUREAU,

        -- Volume of evidence
        count(*)                                     as months_of_history,
        max(months_ago)                              as oldest_month_observed,
        min(months_ago)                              as newest_month_observed,

        -- Peak severity. MAX ignores NULLs, so C/X months simply do not vote.
        max(dpd_bucket)                              as worst_dpd_bucket,

        -- Frequency
        countif(was_late_this_month)                 as months_late_count,
        countif(dpd_bucket = 5)                      as months_written_off_count,

        -- Share of KNOWN months that were late. The denominator excludes 'X'
        -- months so 21% unknowns cannot silently deflate the ratio.
        round(safe_divide(
            countif(was_late_this_month),
            countif(was_late_this_month is not null)
        ), 4)                                        as share_of_months_late,

        -- Recency of the most recent problem. NULL = never late.
        min(case when was_late_this_month then months_ago end)
                                                     as months_since_last_late,

        -- Composition / data-quality signal
        countif(STATUS = 'C')                        as months_closed_count,
        countif(STATUS = 'X')                        as months_unknown_count,
        round(safe_divide(countif(STATUS = 'X'), count(*)), 4)
                                                     as share_of_months_unknown

    from monthly
    group by SK_ID_BUREAU

)

select * from summarized
