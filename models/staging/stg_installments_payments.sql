select
    SK_ID_CURR,
    SK_ID_PREV,
    NUM_INSTALMENT_VERSION,
    NUM_INSTALMENT_NUMBER,
    DAYS_INSTALMENT,
    DAYS_ENTRY_PAYMENT,
    AMT_INSTALMENT,
    AMT_PAYMENT

from {{ source('home_credit', 'installments_payments') }}