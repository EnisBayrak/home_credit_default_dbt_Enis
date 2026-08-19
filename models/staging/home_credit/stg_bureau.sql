-- ============================================================================
-- stg_bureau
-- ----------------------------------------------------------------------------
-- PURPOSE: make the raw `bureau` table safe to use, without changing its shape.
--
-- THE ONE RULE OF STAGING: row count in == row count out. 1,716,428 rows go
-- in, 1,716,428 rows come out. No joins. No GROUP BY. No filtering.
-- If you ever feel the urge to join something here, that urge belongs in the
-- intermediate layer instead.
--
-- What we DO allow ourselves here:
--   * rename columns to readable snake_case
--   * flip sign conventions that fight human intuition
--   * neutralise values that are physically impossible
--   * add explicit flags so nothing is silently "fixed" behind the analyst's back
-- ============================================================================

{{ config(materialized='view') }}
-- Materialised as a view, not a table: staging models are thin transformations
-- and BigQuery charges by bytes scanned, not by objects created. A view costs
-- nothing to store and always reflects the current source data.

with source as (

    select * from {{ source('home_credit', 'bureau') }}

),

cleaned as (

    select
        -- ================= IDENTIFIERS =================
        SK_ID_CURR                                  as customer_id,
        SK_ID_BUREAU                                as bureau_loan_id,

        -- ================= CATEGORICAL =================
        CREDIT_ACTIVE                               as credit_status,
        CREDIT_CURRENCY                             as currency_code,

        -- Keep the original type for auditing...
        CREDIT_TYPE                                 as credit_type_raw,

        -- ...and add a grouped version. Rationale from profiling: 15 distinct
        -- credit types exist, but the top 5 cover 99.4% of rows. Types like
        -- 'Interbank credit' and 'Mobile operator loan' have exactly ONE row
        -- each. Left alone, one-hot encoding would create columns that are
        -- almost entirely zeros -- pure noise that invites overfitting.
        case
            when CREDIT_TYPE in (
                'Consumer credit',   -- 1,251,615 rows
                'Credit card',       --   402,195 rows
                'Car loan',          --    27,690 rows
                'Mortgage',          --    18,391 rows
                'Microloan'          --    12,413 rows
            ) then CREDIT_TYPE
            else 'Other'
        end                                         as credit_type,

        -- ================= TIME COLUMNS =================
        -- The source encodes time as NEGATIVE days relative to the date our
        -- customer applied. "-229" means "229 days before the application".
        -- Negative numbers that actually mean "ago" are a classic source of
        -- sign-flip bugs, so we normalise to positive "days ago" and keep a
        -- months version because humans think in months, not in 1,247 days.
        -1 * DAYS_CREDIT                            as days_since_credit_applied,
        round(-1 * DAYS_CREDIT / 30.44, 1)          as months_since_credit_applied,

        -- This one stays as-is on purpose: it can legitimately be positive
        -- (loan ends in the future) or negative (loan already ended).
        -- Flipping the sign here would destroy that meaning.
        DAYS_CREDIT_ENDDATE                         as days_until_credit_ends,

        -- NULL for ~36.9% of rows -- which almost exactly matches the 36.7%
        -- share of 'Active' credits. This NULL is NOT missing data: an open
        -- loan simply has no actual closing date yet. We deliberately leave it
        -- NULL. Imputing 0 here would tell the model "closed today", a lie.
        -1 * DAYS_ENDDATE_FACT                      as days_since_credit_closed,

        -1 * DAYS_CREDIT_UPDATE                     as days_since_last_update,
        CREDIT_DAY_OVERDUE                          as days_currently_overdue,

        -- ================= MONEY COLUMNS =================
        AMT_CREDIT_SUM                              as credit_amount,

        -- 8,418 rows carry a NEGATIVE debt. A debt below zero is physically
        -- meaningless, so we clamp it to zero. Note the CASE structure: when
        -- the input is NULL the condition evaluates to NULL, control falls to
        -- ELSE, and NULL is preserved. We fix errors without inventing data.
        case
            when AMT_CREDIT_SUM_DEBT < 0 then 0
            else AMT_CREDIT_SUM_DEBT
        end                                         as debt_amount,

        -- Same treatment, 351 offending rows.
        case
            when AMT_CREDIT_SUM_LIMIT < 0 then 0
            else AMT_CREDIT_SUM_LIMIT
        end                                         as credit_limit_amount,

        AMT_CREDIT_SUM_OVERDUE                      as overdue_amount,

        -- 65.5% NULL. Strong hypothesis: NULL means "never went overdue"
        -- rather than "we lost the number". We do NOT act on that hypothesis
        -- here -- staging preserves reality. The decision is documented and
        -- deferred to the mart layer, where it is easy to change your mind.
        AMT_CREDIT_MAX_OVERDUE                      as max_overdue_amount_ever,

        -- 71.5% NULL. This column is close to unusable as a numeric feature.
        -- Keep it, but treat its PRESENCE as the real signal (see flag below).
        AMT_ANNUITY                                 as annuity_amount,

        CNT_CREDIT_PROLONG                          as prolongation_count,

        -- ================= DATA-QUALITY FLAGS =================
        -- Every silent correction above gets a visible witness here. Six months
        -- from now, when a number looks odd, you can filter on these flags and
        -- see exactly which rows we touched. COALESCE is essential: without it
        -- a NULL input would produce a NULL flag instead of FALSE.
        coalesce(AMT_CREDIT_SUM_DEBT  < 0, false)   as was_debt_clamped,
        coalesce(AMT_CREDIT_SUM_LIMIT < 0, false)   as was_limit_clamped,

        -- 1,408 rows are in currency 2/3/4. Summing money across currencies is
        -- adding apples to oranges. Downstream aggregations must either filter
        -- on this flag or convert. Making it visible means nobody can forget.
        CREDIT_CURRENCY != 'currency 1'             as is_foreign_currency,

        -- "Do we know the annuity at all?" is often more predictive than the
        -- annuity value itself -- missingness carries information here.
        AMT_ANNUITY is not null                     as has_annuity_reported

    from source

)

select * from cleaned
