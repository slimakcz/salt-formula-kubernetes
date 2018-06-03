{%- from "kubernetes/map.jinja" import master with context %}
{%- if master.enabled %}
{%- if master.network.opencontrail.get('version', 3.0) != 3.0 %}

/etc/contrail/contrail-kubernetes.conf:
  file.managed:
  - source: salt://kubernetes/files/opencontrail/{{ master.network.opencontrail.version }}/contrail-kubernetes.conf
  - template: jinja
  - makedirs: True

#/etc/kubernetes/opencontrail/contrail-{{ master.network.opencontrail.version }}.yaml:
#  file.managed:
#  - source: salt://kubernetes/files/manifest/contrail-{{ master.network.opencontrail.version }}.manifest
#  - template: jinja
#  - makedirs: True

{%- endif %}
{%- endif %}
