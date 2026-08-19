with source as (
    select * from {{ source('raw_home_credit', 'previous_application') }}
),

cleaned as (
    select
        -- 1. Kimlik (ID) Alanları
        cast(SK_ID_PREV as string) as previous_application_id,
        cast(SK_ID_CURR as string) as customer_id,

        -- 2. Sözleşme ve Başvuru Durumu
        trim(lower(NAME_CONTRACT_TYPE)) as contract_type,
        trim(lower(NAME_CONTRACT_STATUS)) as contract_status,
        trim(lower(NAME_PAYMENT_TYPE)) as payment_type,
        trim(lower(CODE_REJECT_REASON)) as reject_reason,
        trim(lower(NAME_CLIENT_TYPE)) as client_type,
        trim(lower(NAME_PORTFOLIO)) as portfolio,
        trim(lower(NAME_PRODUCT_TYPE)) as product_type,
        trim(lower(PRODUCT_COMBINATION)) as product_combination,
        trim(lower(NAME_YIELD_GROUP)) as yield_group,

        -- 3. Finansal Tutarlar (Amount Fields)
        cast(AMT_ANNUITY as numeric) as annuity_amount,
        cast(AMT_APPLICATION as numeric) as application_amount,
        cast(AMT_CREDIT as numeric) as credit_amount,
        cast(coalesce(AMT_DOWN_PAYMENT, 0.0) as numeric) as down_payment_amount,
        cast(AMT_GOODS_PRICE as numeric) as goods_price_amount,

        -- 4. Oranlar ve Faizler (Rates)
        cast(RATE_DOWN_PAYMENT as float64) as down_payment_rate,
        cast(RATE_INTEREST_PRIMARY as float64) as primary_interest_rate,
        cast(RATE_INTEREST_PRIVILEGED as float64) as privileged_interest_rate,

        -- 5. Başvuru Süreci ve Zaman Bilgileri
        trim(lower(WEEKDAY_APPR_PROCESS_START)) as approval_process_day,
        cast(HOUR_APPR_PROCESS_START as int64) as approval_process_hour,
        cast(DAYS_DECISION as int64) as days_decision,

        -- 6. Tarih / Gün Alanları (365243 sentinel değeri NULL'a çekilmiştir)
        cast(nullif(DAYS_FIRST_DRAWING, 365243) as int64) as days_first_drawing,
        cast(nullif(DAYS_FIRST_DUE, 365243) as int64) as days_first_due,
        cast(nullif(DAYS_LAST_DUE_1ST_VERSION, 365243) as int64) as days_last_due_1st_version,
        cast(nullif(DAYS_LAST_DUE, 365243) as int64) as days_last_due,
        cast(nullif(DAYS_TERMINATION, 365243) as int64) as days_termination,

        -- 7. Satıcı ve Ürün Detayları
        trim(lower(NAME_TYPE_SUITE)) as suite_type,
        trim(lower(NAME_GOODS_CATEGORY)) as goods_category,
        trim(lower(CHANNEL_TYPE)) as channel_type,
        cast(SELLERPLACE_AREA as int64) as sellerplace_area,
        trim(lower(NAME_SELLER_INDUSTRY)) as seller_industry,

        -- 8. Taksit Sayısı ve Bayraklar (Flags)
        cast(CNT_PAYMENT as int64) as payment_term_count,
        cast(FLAG_LAST_APPL_PER_CONTRACT as boolean) as is_last_application_per_contract,
        cast(NFLAG_LAST_APPL_IN_DAY as boolean) as is_last_application_in_day,
        case when NFLAG_INSURED_ON_APPROVAL = 1.0 then true else false end as is_insured_on_approval,

        -- 9. Analitik Kolaylık Sağlayan Bayraklar
        case when trim(lower(NAME_CONTRACT_STATUS)) = 'approved' then true else false end as is_approved,
        case when trim(lower(NAME_CONTRACT_STATUS)) = 'refused' then true else false end as is_refused

    from source
)

select * from cleaned