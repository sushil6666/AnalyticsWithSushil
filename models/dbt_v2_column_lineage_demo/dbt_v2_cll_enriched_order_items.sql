{{ config(
    materialized='table',
    schema='dbt_v2_column_lineage_demo',
    static_analysis='strict',
    tags=['dbt_v2_column_lineage_demo']
) }}

with order_items as (

    select
        order_item_id,
        order_id,
        customer_id,
        product_name,
        quantity,
        unit_price,
        order_timestamp
    from {{ ref('dbt_v2_cll_order_items') }}

)

select
    order_item_id as line_item_id,
    order_id,
    customer_id,
    upper(trim(product_name)) as product_name_clean,
    quantity,
    unit_price,
    quantity * unit_price as line_amount,
    cast(order_timestamp as date) as order_date,
    order_timestamp
from order_items
