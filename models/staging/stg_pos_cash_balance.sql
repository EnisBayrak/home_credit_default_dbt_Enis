with source as (
    select * from {{ source('raw_home_credit', 'POS_CASH_balance') }}
),

cleaned as (
    select
        -- 1. Kimlik (ID) Alanları (String'e çeviriyoruz)
        cast(SK_ID_PREV as string) as previous_application_id,
        cast(SK_ID_CURR as string) as customer_id,

        -- 2. Zaman / Ay Bilgisi
        cast(MONTHS_BALANCE as int64) as months_balance,

        -- 3. Taksit Bilgileri (Float'tan Tam Sayıya Dönüşüm)
        cast(CNT_INSTALMENT as int64) as total_instalment_count,
        cast(CNT_INSTALMENT_FUTURE as int64) as remaining_instalment_count,

        -- 4. Durum Bilgisi (Standardizasyon)
        trim(lower(NAME_CONTRACT_STATUS)) as contract_status,

        -- 5. Gecikme Gün Sayıları (DPD: Days Past Due)
        cast(coalesce(SK_DPD, 0) as int64) as days_past_due,
        cast(coalesce(SK_DPD_DEF, 0) as int64) as days_past_due_with_tolerance,

        -- 6. Analitik Yardımcı Bayraklar (Flags - Veri kaybetmeden değer katar)
        case 
            when coalesce(SK_DPD, 0) > 0 then true 
            else false 
        end as is_past_due,
        
        case 
            when trim(lower(NAME_CONTRACT_STATUS)) = 'completed' or coalesce(CNT_INSTALMENT_FUTURE, 0) = 0 then true 
            else false 
        end as is_completed

    from source
)

select * from cleaned