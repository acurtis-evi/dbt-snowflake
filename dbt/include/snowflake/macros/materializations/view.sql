{% materialization view, adapter='snowflake' -%}
  {% if should_run_model('view') %}
    {% set original_query_tag = set_query_tag() %}
    {% set to_return = create_or_replace_view() %}

    {% set target_relation = this.incorporate(type='view') %}

    {% do persist_docs(target_relation, model, for_columns=false) %}

    {% do return(to_return) %}

    {% do unset_query_tag(original_query_tag) %}
  {% else %}
      {% set target_relation = this.incorporate(type='view') %}
      {{ return({'relations': [target_relation]}) }}
  {% endif %}
{%- endmaterialization %}
