{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for role_name, role in control.role.items() %}
  {%- set role_name = role.name|default(role_name) %}

  {%- if role.get('namespace') or role.get('kind') == 'Role' %}
    {%- set role_kind = 'Role' %}
  {%- else %}
    {%- set role_kind = 'ClusterRole' %}
  {%- endif %}

  {%- if role.get('rules') %}
    {%- if role.enabled|default(True) %}
/srv/kubernetes/roles/{{ role_name }}/{{ role_name }}-role.yml:
  file.managed:
  - source: salt://kubernetes/files/role.yml
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      role_name: {{ role_name }}
      role_kind: {{ role_kind }}
      role: {{ role|yaml }}

kubernetes_role_create_{{ role_name }}:
  cmd.run:
    - name: kubectl apply -f /srv/kubernetes/roles/{{ role_name }}/{{ role_name }}-role.yml
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - require:
      - file: /srv/kubernetes/roles/{{ role_name }}/{{ role_name }}-role.yml

    {%- else %}

kubernetes_role_delete_{{ role_name }}:
  cmd.run:
    - name: kubectl delete {{ role_kind }} {{ role_name }}
    - onlyif: kubectl get {{ role_kind }} -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep "{{ role_name }}"

    {%- endif %}
  {%- endif %}

  {%- for binding_name, binding in role.get('binding', {}).items() %}
    {%- set binding_name = binding.name|default(binding_name) %}
    {%- if binding.get('namespace') or binding.get('kind') == 'RoleBinding' %}
      {%- set binding_kind = 'RoleBinding' %}
    {%- else %}
      {%- set binding_kind = 'ClusterRoleBinding' %}
    {%- endif %}

    {%- if role.enabled|default(True) %}

/srv/kubernetes/roles/{{ role_name }}/{{ binding_name }}-rolebinding.yml:
  file.managed:
  - source: salt://kubernetes/files/rolebinding.yml
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      role_name: {{ role_name }}
      role_kind: {{ role_kind }}
      role: {{ role|yaml }}
      binding_name: {{ binding_name }}
      binding_kind: {{ binding_kind }}
      binding: {{ binding|yaml }}

kubernetes_rolebinding_create_{{ role_name }}_{{ binding_name }}:
  cmd.run:
    - name: kubectl apply -f /srv/kubernetes/roles/{{ role_name }}/{{ binding_name }}-rolebinding.yml
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - require:
      - file: /srv/kubernetes/roles/{{ role_name }}/{{ binding_name }}-rolebinding.yml

    {%- else %}

kubernetes_rolebinding_delete_{{ role_name }}_{{ binding_name }}:
  cmd.run:
    - name: kubectl delete {{ binding_kind }} {{ binding_name }}
    - onlyif: kubectl get {{ binding_kind }} -o=custom-columns=NAME:.metadata.name | grep -v NAME | grep "{{ binding_name }}"

    {%- endif %}
  {%- endfor %}
{%- endfor %}
