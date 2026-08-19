with source as (
    select * from {{ source('raw_home_credit', 'previous_application') }}
)

select * from source