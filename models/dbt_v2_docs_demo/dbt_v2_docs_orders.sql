{{ config(
    materialized='table',
    schema='dbt_v2_docs_demo',
    static_analysis='strict',
    tags=['dbt_v2_docs_demo']
) }}

select
    order_id,
    customer_id,
    order_amount,
    order_status,
    cast(ordered_at as date) as order_date,
    ordered_at
from {{ ref('dbt_v2_docs_order_events') }}
