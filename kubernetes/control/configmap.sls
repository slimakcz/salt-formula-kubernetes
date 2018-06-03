{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for configmap_name, configmap in control.get('configmap', {}).items() %}
{%- if configmap.enabled|default(True) %}

{%- if configmap.pillar is defined %}
{%- if control.config_type == "default" %}
  {%- for service_name in configmap.pillar.keys() %}
    {%- if pillar.get(service_name, {}).get('_support', {}).get('config', {}).get('enabled', False) %}

      {%- set support_fragment_file = service_name+'/meta/config.yml' %}
      {% macro load_support_file(pillar, grains) %}{% include support_fragment_file %}{% endmacro %}

      {%- set service_config_files = load_support_file(configmap.pillar, configmap.get('grains', {}))|load_yaml %}
      {%- for service_config_name, service_config in service_config_files.config.items() %}

/srv/kubernetes/configmap/{{ configmap_name }}/{{ service_config_name }}:
  file.managed:
  - source: {{ service_config.source }}
  - user: root
  - group: root
  - template: {{ service_config.template }}
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      pillar: {{ configmap.pillar|yaml }}
      grains: {{ configmap.get('grains', {}) }}

      {%- endfor %}
    {%- endif %}
  {%- endfor %}

{%- else %}

/srv/kubernetes/configmap/{{ configmap_name }}.yml:
  file.managed:
  - source: salt://kubernetes/files/configmap.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      configmap_name: {{ configmap_name }}
      configmap: {{ configmap|yaml }}
      grains: {{ configmap.get('grains', {}) }}

{%- endif %}

{%- else %}
{# TODO: configmap not using support between formulas #}
{%- endif %}

{%- endif %}
{%- endfor %}
