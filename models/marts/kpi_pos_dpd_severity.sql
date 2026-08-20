""" Gecikme Şiddeti KPI """


select
    customer_id,
    avg(days_past_due) as avg_days_past_due,
    max(days_past_due) as max_days_past_due,
    count(distinct previous_application_id) as total_pos_contracts
from {{ ref('stg_pos_cash_balance') }}
group by customer_id