-- ============================================================================
-- int_bureau_enriched
-- ----------------------------------------------------------------------------
-- Attaches each loan's summarised monthly history to its master record.
-- All bureau columns pass through with their ORIGINAL names.
--
-- THE CRITICAL WORD IS STILL "LEFT": 942,074 of 1,716,428 loans (55%) have no
-- monthly history. INNER JOIN would delete them silently -- no error, no
-- warning, half the data gone. LEFT keeps bureau as the spine; history
-- columns arrive as NULL where none exists, and the flag at the bottom makes
-- that absence visible instead of implicit.
--
-- Row count in == row count out (1,716,428). The unique test on SK_ID_BUREAU
-- in the schema file is the tripwire that guards this.
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
        loans.*,

        history.months_of_history,
        history.worst_dpd_bucket,
        history.months_late_count,
        history.months_written_off_count,
        history.share_of_months_late,
        history.months_since_last_late,
        history.months_closed_count,
        history.share_of_months_unknown,

        -- Anyone averaging the history metrics MUST know whether they cover
        -- 45% of the loans or all of them.
        history.SK_ID_BUREAU is not null            as has_monthly_history

    from loans
    left join history
        on loans.SK_ID_BUREAU = history.SK_ID_BUREAU

)

select * from joined
