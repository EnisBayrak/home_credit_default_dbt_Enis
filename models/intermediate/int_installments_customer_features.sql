{{ config(materialized='view') }}
SELECT
    SK_ID_CURR,

    COUNT(*) AS TOPLAM_TAKSIT_SAYISI,

    COUNT(DISTINCT SK_ID_PREV) AS ESKI_KREDI_SAYISI,

    COUNTIF(GECIKME_GUNU > 0) AS GEC_ODEME_SAYISI,

    COUNTIF(GECIKME_GUNU = 0) AS ZAMANINDA_ODEME_SAYISI,

    COUNTIF(GECIKME_GUNU < 0) AS ERKEN_ODEME_SAYISI,

    COUNTIF(ODEME_FARKI > 0) AS EKSIK_ODEME_SAYISI,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(GECIKME_GUNU > 0),
            COUNT(*)
        ) * 100,
        2
    ) AS GEC_ODEME_ORANI,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(ODEME_FARKI > 0),
            COUNT(*)
        ) * 100,
        2
    ) AS EKSIK_ODEME_ORANI,

    AVG(GECIKME_GUNU) AS ORTALAMA_GECIKME_GUNU,

    MAX(GECIKME_GUNU) AS MAKS_GECIKME_GUNU

FROM {{ ref('int_installments_features') }}

GROUP BY SK_ID_CURR