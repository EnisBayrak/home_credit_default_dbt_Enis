select
    SK_ID_CURR,
    SK_ID_PREV,
    MONTHS_BALANCE,
    AMT_BALANCE,
    AMT_CREDIT_LIMIT_ACTUAL,
    AMT_INST_MIN_REGULARITY,
    AMT_PAYMENT_CURRENT,
    AMT_PAYMENT_TOTAL_CURRENT,
    NAME_CONTRACT_STATUS,
    SK_DPD,
    SK_DPD_DEF

from {{ source('home_credit', 'credit_card_balance') }}