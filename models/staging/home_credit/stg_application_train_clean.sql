{{ config(materialized='view') }}

with src as (
  select *
  from {{ source('home_credit_raw', 'application_train') }}
)

select
  SK_ID_CURR,
  TARGET,

  EXT_SOURCE_1,
  EXT_SOURCE_2,
  EXT_SOURCE_3,
  if(EXT_SOURCE_1 is null, 1, 0) as is_ext_source_1_missing,
  if(EXT_SOURCE_3 is null, 1, 0) as is_ext_source_3_missing,

  ifnull(OCCUPATION_TYPE, 'Unknown') as occupation_type_clean,
  if(OCCUPATION_TYPE is null, 1, 0) as is_occupation_missing,

  * except (EXT_SOURCE_1, EXT_SOURCE_2, EXT_SOURCE_3, OCCUPATION_TYPE, SK_ID_CURR, TARGET)
from src