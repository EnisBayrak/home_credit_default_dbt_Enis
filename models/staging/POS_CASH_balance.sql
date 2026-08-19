with source as (
    select * from {{ source('raw_home_credit', 'POS_CASH_balance') }}
)

select * from source