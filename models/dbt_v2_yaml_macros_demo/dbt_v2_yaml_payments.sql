{{ config(
    materialized='table',
    schema='dbt_v2_yaml_macros_demo',
    static_analysis='strict',
    tags=['dbt_v2_yaml_macros_demo']
) }}

{% set demo_mode = var('dbt_v2_yaml_macros_demo_mode', 'safe') | lower %}
{% if demo_mode not in ['safe', 'refunded', 'invalid_status'] %}
    {{ exceptions.raise_compiler_error(
        "dbt_v2_yaml_macros_demo_mode must be safe, refunded, or invalid_status"
    ) }}
{% endif %}

{% if demo_mode != 'safe' and target.name in ['prod', 'production', 'uat', 'candidate'] %}
    {{ exceptions.raise_compiler_error(
        "Non-safe YAML macro demo modes must run in an isolated development target"
    ) }}
{% endif %}

with payment_events as (

    select
        payment_id,
        customer_id,
        payment_status,
        payment_amount,
        paid_at
    from {{ ref('dbt_v2_yaml_payment_events') }}

)

select
    payment_id,
    customer_id,
    {% if demo_mode == 'refunded' %}
        case when payment_id = 'P-2006' then 'refunded' else payment_status end as payment_status,
    {% elif demo_mode == 'invalid_status' %}
        case when payment_id = 'P-2006' then 'not_a_status' else payment_status end as payment_status,
    {% else %}
        payment_status,
    {% endif %}
    payment_amount,
    paid_at
from payment_events
