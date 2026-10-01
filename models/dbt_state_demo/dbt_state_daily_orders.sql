{{ config(
    materialized='table',
    schema='dbt_state_demo',
    tags=['dbt_state_demo'],
    state={
        "lag_tolerance": "4h"
    }
) }}

select
    order_date,
    count(*) as total_orders,
    count_if(is_completed) as completed_orders,
    sum(order_amount) as total_order_amount
from {{ ref('dbt_state_stg_orders') }}
group by order_date
