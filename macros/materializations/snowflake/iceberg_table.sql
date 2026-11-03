{% materialization iceberg_table, adapter='snowflake' %}

    {%- set external_volume = config.meta_get('external_volume') -%}
    {%- set base_location   = config.meta_get('base_location') -%}
    {%- set catalog         = config.meta_get('iceberg_catalog', 'SNOWFLAKE') -%}

    {%- if not external_volume -%}
        {{ exceptions.raise_compiler_error(
            "iceberg_table materialization requires `external_volume` inside meta config."
        ) }}
    {%- endif -%}

    {%- if external_volume | upper != 'SNOWFLAKE_MANAGED' and not base_location -%}
        {{ exceptions.raise_compiler_error(
            "iceberg_table materialization requires `base_location` when not using SNOWFLAKE_MANAGED."
        ) }}
    {%- endif -%}

    {%- set relation  = this.incorporate(type='table') -%}
    {%- set model_sql = sql -%}

    {%- set iceberg_props -%}
        EXTERNAL_VOLUME = '{{ external_volume }}'
        CATALOG = '{{ catalog }}'
        {%- if external_volume | upper != 'SNOWFLAKE_MANAGED' %}
        BASE_LOCATION = '{{ base_location }}'
        {%- endif %}
    {%- endset -%}

    {%- call statement('main') -%}
        CREATE OR REPLACE ICEBERG TABLE {{ relation }}
            {{ iceberg_props }}
        AS (
            {{ model_sql }}
        )
    {%- endcall -%}

    {{ return({'relations': [relation]}) }}

{% endmaterialization %}
