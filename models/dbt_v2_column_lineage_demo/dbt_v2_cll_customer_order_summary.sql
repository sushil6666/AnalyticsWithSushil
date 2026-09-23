{{ config(
    materialized='table',
    schema='dbt_v2_column_lineage_demo',
    static_analysis='strict',
    tags=['dbt_v2_column_lineage_demo']
) }}

select
    customer_id,
    count(distinct order_id) as total_orders,
    count(*) as total_line_items,
    sum(quantity) as total_units,
    sum(line_amount) as gross_revenue,
    min(order_date) as first_order_date,
    max(order_date) as last_order_date
from {{ ref('dbt_v2_cll_enriched_order_items') }}
group by customer_id
