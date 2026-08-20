
{{ config(materialized='view') }}

select
    SK_ID_BUREAU,
    MONTHS_BALANCE,
    STATUS

from {{ source('home_credit', 'bureau_balance') }}
