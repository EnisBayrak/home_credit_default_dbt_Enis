
with categories as (

  select 'CREDIT_ACTIVE'   as column_name, CREDIT_ACTIVE   as value, count(*) as row_count
  from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` group by 1, 2

  union all
  select 'CREDIT_CURRENCY', CREDIT_CURRENCY, count(*)
  from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` group by 1, 2

  union all
  select 'CREDIT_TYPE', CREDIT_TYPE, count(*)
  from `home-credit-risk-grup3.home_credit_risk_grup3.bureau` group by 1, 2

)
select
  column_name,
  value,
  row_count,
  round(100 * row_count / sum(row_count) over (partition by column_name), 4) as pct_of_column,
  
  value != trim(value)                                    as has_hidden_whitespace,
  
  strpos(trim(value), ' ') > 0                            as contains_inner_space,
  
  value != initcap(value)                                 as not_title_case,
  
  row_count < 0.01 * sum(row_count) over (partition by column_name) as is_rare_category
from categories
order by column_name, row_count desc;



select
  lower(trim(CREDIT_TYPE))                                as normalised_value,
  count(distinct CREDIT_TYPE)                             as distinct_raw_spellings,
  string_agg(distinct CREDIT_TYPE, ' | ')                 as the_spellings
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau`
group by normalised_value
having count(distinct CREDIT_TYPE) > 1;



select
  STATUS,
  count(*)                                                as row_count,
  round(100 * count(*) / sum(count(*)) over (), 2)        as pct_of_rows,
  length(STATUS)                                          as character_length,
  STATUS not in ('0','1','2','3','4','5','C','X')         as is_unexpected_value
from `home-credit-risk-grup3.home_credit_risk_grup3.bureau_balance`
group by STATUS
order by row_count desc;
