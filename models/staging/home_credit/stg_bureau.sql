-- ============================================================================
-- stg_bureau
-- ----------------------------------------------------------------------------
-- MINIMAL STAGING: a 1:1 mirror of the raw table.
--
-- Team decision: keep ORIGINAL column names and ORIGINAL values, exactly as
-- they arrive from the source. Four people share these tables; the original
-- names are the common language. No renames, no sign flips, no clamping,
-- no category grouping.
--
-- Why does this model exist at all, then? Two reasons:
--   1. LINEAGE ANCHOR -- downstream models say ref('stg_bureau') instead
--      of hard-coding the BigQuery path, so dbt can draw the dependency graph
--      and the physical location stays changeable in one place (sources.yml).
--   2. FUTURE-PROOFING -- if a cleaning step ever becomes necessary, it has an
--      agreed home here, without touching any downstream model.
--
-- The columns are listed explicitly (not SELECT *) on purpose: if the source
-- ever gains or loses a column, this model keeps a stable contract instead of
-- silently changing shape.
-- ============================================================================

{{ config(materialized='view') }}

select
    SK_ID_CURR,
    SK_ID_BUREAU,
    CREDIT_ACTIVE,
    CREDIT_CURRENCY,
    DAYS_CREDIT,
    CREDIT_DAY_OVERDUE,
    DAYS_CREDIT_ENDDATE,
    DAYS_ENDDATE_FACT,
    AMT_CREDIT_MAX_OVERDUE,
    CNT_CREDIT_PROLONG,
    AMT_CREDIT_SUM,
    AMT_CREDIT_SUM_DEBT,
    AMT_CREDIT_SUM_LIMIT,
    AMT_CREDIT_SUM_OVERDUE,
    CREDIT_TYPE,
    DAYS_CREDIT_UPDATE,
    AMT_ANNUITY

from {{ source('home_credit', 'bureau') }}
