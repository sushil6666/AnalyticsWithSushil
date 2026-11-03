{{ config(
    materialized='table',
    schema='dbt_v2_batch_tests_demo',
    static_analysis='strict',
    tags=['dbt_v2_batch_tests_demo']
) }}

{% set demo_mode = var('dbt_v2_batch_tests_demo_mode', 'safe') | lower %}
{% if demo_mode not in ['safe', 'null_customer', 'duplicate_payment'] %}
    {{ exceptions.raise_compiler_error(
        "dbt_v2_batch_tests_demo_mode must be safe, null_customer, or duplicate_payment"
    ) }}
{% endif %}

with order_events as (

    select
        order_id,
        payment_id,
        customer_id,
        order_amount,
        order_status,
        ordered_at
    from {{ ref('dbt_v2_batch_order_events') }}

)

select
    order_id,
    {% if demo_mode == 'duplicate_payment' %}
        case when order_id = 'O-1002' then 'P-1001' else payment_id end as payment_id,
    {% else %}
        payment_id,
    {% endif %}
    {% if demo_mode == 'null_customer' %}
        case when order_id = 'O-1002' then cast(null as varchar) else customer_id end as customer_id,
    {% else %}
        customer_id,
    {% endif %}
    order_amount,
    order_status,
    ordered_at
from order_events
