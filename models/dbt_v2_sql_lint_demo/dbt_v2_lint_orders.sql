{{ config(
    materialized='table',
    schema='dbt_v2_sql_lint_demo',
    tags=['dbt_v2_sql_lint_demo']
) }}

with order_events as (

    select
        order_id,
        customer_id,
        order_amount,
        order_status,
        ordered_at
    from {{ ref('dbt_v2_lint_order_events') }}

),

final as (

    select
        order_id,
        customer_id,
        order_amount,
        order_status,
        cast(ordered_at as date) as order_date,
        order_status = 'completed' as is_completed
    from order_events

)

select *
from final
