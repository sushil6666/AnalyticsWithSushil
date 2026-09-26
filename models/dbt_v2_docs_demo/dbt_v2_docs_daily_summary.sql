{{ config(
    materialized='table',
    schema='dbt_v2_docs_demo',
    static_analysis='strict',
    tags=['dbt_v2_docs_demo']
) }}

select
    order_date,
    count(*) as total_orders,
    count_if(order_status = 'completed') as completed_orders,
    sum(order_amount) as total_order_amount
from {{ ref('dbt_v2_docs_orders') }}
group by order_date
