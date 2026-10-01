{{ config(
    materialized='table',
    schema='dbt_state_demo',
    tags=['dbt_state_demo'],
    state={
        "lag_tolerance": "24h"
    }
) }}

select
    count(*) as total_reporting_days,
    sum(total_orders) as total_orders,
    sum(completed_orders) as completed_orders,
    sum(total_order_amount) as gross_order_amount,
    sum(completed_orders) / nullif(sum(total_orders), 0) as completion_rate
from {{ ref('dbt_state_daily_orders') }}
