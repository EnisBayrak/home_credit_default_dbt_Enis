-- ============================================================================
-- stg_bureau_balance
-- ----------------------------------------------------------------------------
-- MINIMAL STAGING: 1:1 mirror of the raw monthly history.
-- Original column names, original values, nothing added, nothing changed.
-- The STATUS decoding that used to live here now happens downstream in
-- int_bureau_balance_summarized, at the moment it is actually needed --
-- so this table stays a faithful copy of the source.
-- ============================================================================

{{ config(materialized='view') }}

select
    SK_ID_BUREAU,
    MONTHS_BALANCE,
    STATUS

from {{ source('home_credit', 'bureau_balance') }}
