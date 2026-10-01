{{ config(
    materialized='view',
    schema='dbt_state_demo',
    tags=['dbt_state_demo'],
    state={
        "lag_tolerance": "15m"
    }
) }}

select
    order_id,
    customer_id,
    order_amount,
    order_status,
    cast(ordered_at as date) as order_date,
    order_status = 'completed' as is_completed
from {{ ref('dbt_state_order_events') }}
