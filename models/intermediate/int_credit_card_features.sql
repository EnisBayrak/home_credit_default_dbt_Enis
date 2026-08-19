SELECT
    SK_ID_CURR,

    COUNT(*) AS AYLIK_KAYIT_SAYISI,

    COUNTIF(SK_DPD > 0) AS GECIKMELI_AY_SAYISI,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(SK_DPD > 0),
            COUNT(*)
        ) * 100,
        2
    ) AS GECIKMELI_AY_ORANI,

    COUNTIF(SK_DPD_DEF > 0) AS TOLERANS_SONRASI_GECIKMELI_AY_SAYISI,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(SK_DPD_DEF > 0),
            COUNT(*)
        ) * 100,
        2
    ) AS TOLERANS_SONRASI_GECIKME_ORANI,

    MAX(SK_DPD) AS MAKS_GECIKME_GUNU,

    AVG(AMT_BALANCE) AS ORTALAMA_BORC_BAKIYESI,

    MAX(AMT_BALANCE) AS MAKS_BORC_BAKIYESI,

    ROUND(
        AVG(
            SAFE_DIVIDE(
                AMT_BALANCE,
                NULLIF(AMT_CREDIT_LIMIT_ACTUAL, 0)
            )
        ) * 100,
        2
    ) AS ORTALAMA_LIMIT_KULLANIM_ORANI,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                AMT_CREDIT_LIMIT_ACTUAL > 0
                AND AMT_BALANCE > AMT_CREDIT_LIMIT_ACTUAL
            ),
            COUNTIF(AMT_CREDIT_LIMIT_ACTUAL > 0)
        ) * 100,
        2
    ) AS LIMIT_ASIMLI_AY_ORANI

FROM {{ ref('stg_credit_card_balance') }}

GROUP BY SK_ID_CURR