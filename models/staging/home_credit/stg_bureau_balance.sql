-- ============================================================================
-- stg_bureau_balance
-- ----------------------------------------------------------------------------
-- PURPOSE: untangle the STATUS column, which currently smuggles two unrelated
-- concepts through a single field.
--
-- Observed distribution across 27,299,925 rows:
--     C  -> 13,646,993  (49.99%)  loan was CLOSED that month
--     0  ->  7,499,507  (27.47%)  loan open, nothing overdue
--     X  ->  5,810,482  (21.28%)  status genuinely unknown
--     1  ->    242,347  ( 0.89%)  1-30 days past due
--     2  ->     23,419  ( 0.09%)  31-60 days past due
--     3  ->      8,924  ( 0.03%)  61-90 days past due
--     4  ->      5,847  ( 0.02%)  91-120 days past due
--     5  ->     62,406  ( 0.23%)  120+ days / written off
--
-- The trap: 0-5 form an ORDERED severity scale, but C and X are not points on
-- that scale at all. Map C to 6 and you have just declared that a repaid loan
-- is worse than a default. We split the field into three honest columns.
-- ============================================================================

{{ config(materialized='view') }}

with source as (

    select * from {{ source('home_credit', 'bureau_balance') }}

),

cleaned as (

    select
        SK_ID_BUREAU                        as bureau_loan_id,

        -- Kept in original form so we can always trace back to the source.
        MONTHS_BALANCE                      as months_before_application,

        -- Same sign-flip logic as in stg_bureau: 0 = the most recent month,
        -- 96 = eight years back. Positive numbers read as "months ago".
        -1 * MONTHS_BALANCE                 as months_ago,

        STATUS                              as status_code,

        -- CONCEPT 1: what kind of month was this?
        case STATUS
            when 'C' then 'closed'
            when 'X' then 'unknown'
            when '0' then 'current'
            else          'delinquent'
        end                                 as status_group,

        -- CONCEPT 2: how severe was the delinquency, on a 0-5 scale?
        -- SAFE_CAST is doing real work here. On '3' it returns 3. On 'C' or 'X'
        -- it returns NULL instead of blowing the query up. That NULL is the
        -- correct answer: a closed month has no delinquency level, and forcing
        -- one would be fabrication. Plain CAST would fail the whole job.
        safe_cast(STATUS as int64)          as dpd_bucket,

        -- CONCEPT 3: cheap boolean for the most common downstream question.
        -- The explicit NULL branch keeps unknown months out of the numerator
        -- AND out of any later "% of months late" denominator decisions.
        case
            when STATUS in ('1','2','3','4','5') then true
            when STATUS in ('0','C')             then false
            else null  -- 'X': we genuinely do not know. Say so.
        end                                 as was_late_this_month

    from source

)

select * from cleaned
