with source as (

  select *
  from {{ source('home_credit_raw', 'application_train') }}

),

staged as (

  select
    cast(SK_ID_CURR as int64) as sk_id_curr,
    cast(TARGET as int64) as target,

    EXT_SOURCE_1,
    EXT_SOURCE_2,
    EXT_SOURCE_3,

    AMT_INCOME_TOTAL,
    AMT_CREDIT,
    AMT_ANNUITY,

    DAYS_BIRTH,
    DAYS_EMPLOYED,

    OCCUPATION_TYPE

  from source

)

select * from staged