{{ config(
    materialized='table',
    schema='dbt_v2_static_analysis_demo',
    static_analysis='strict',
    tags=['dbt_v2_static_analysis_demo']
) }}

{% set demo_error = var('dbt_v2_static_analysis_demo_error', 'safe') | lower %}

select
    event_id,
    customer_id,
    {% if demo_error == 'missing_column' %}
        payment_amunt as payment_amount,
    {% elif demo_error == 'type_mismatch' %}
        sqrt(event_timestamp) as payment_amount,
    {% else %}
        payment_amount,
    {% endif %}
    payment_status,
    event_timestamp
from {{ ref('dbt_v2_static_analysis_payment_events') }}
