{% materialization table, adapter='snowflake' %}

  {% set original_query_tag = set_query_tag() %}

  {%- set identifier = model['alias'] -%}

  {% set grant_config = config.get('grants') %}
  {% set copy_grants = config.get('copy_grants', False) %}

  {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
  {%- set target_relation = api.Relation.create(identifier=identifier,
                                                schema=schema,
                                                database=database, type='table') -%}

  {{ run_hooks(pre_hooks) }}

  {#-- Drop the relation if it was a view to "convert" it in a table. This may lead to
    -- downtime, but it should be a relatively infrequent occurrence  #}
  {% if old_relation is not none and not old_relation.is_table %}
    {{ log("Dropping relation " ~ old_relation ~ " because it is of type " ~ old_relation.type) }}
    {{ drop_relation_if_exists(old_relation) }}
  {% endif %}

  --build model
  {% call statement('main') -%}
    {{ create_table_as(false, target_relation, sql) }}
  {%- endcall %}

  {{ run_hooks(post_hooks) }}

  {#-- If copy_grants is True, grants will be copied over by CREATE OR REPLACE --#}
  {#-- Otherwise, they won't, so no need to revoke --#}
  {% do apply_grants(target_relation, grant_config, should_revoke=copy_grants) %}

  {% do persist_docs(target_relation, model) %}

  {% do unset_query_tag(original_query_tag) %}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}
