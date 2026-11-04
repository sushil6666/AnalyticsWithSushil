{% macro dbt_v2_yaml_payment_statuses() %}
    {% set policy = var('dbt_v2_yaml_macros_demo_policy', 'standard') | lower %}

    {% if policy == 'standard' %}
        {% do return(['completed', 'pending', 'cancelled']) %}
    {% elif policy == 'extended' %}
        {% do return(['completed', 'pending', 'cancelled', 'refunded']) %}
    {% else %}
        {{ exceptions.raise_compiler_error(
            "dbt_v2_yaml_macros_demo_policy must be standard or extended"
        ) }}
    {% endif %}
{% endmacro %}
