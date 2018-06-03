{%- from "kubernetes/map.jinja" import pool with context %}
include:
{%- if pool.network.get('calico', {}).get('enabled', False) %}
- kubernetes.pool.calico
{%- endif %}
{%- if pool.network.get('opencontrail', {}).get('enabled', False) %}
- kubernetes.pool.opencontrail
{%- endif %}
- kubernetes.pool.service
{%- if pool.network.get('flannel', {}).get('enabled', False) %}
- kubernetes.pool.flannel
{%- endif %}
{%- if pool.network.get('genie', {}).get('enabled', False) %}
- kubernetes.pool.genie
{%- endif %}
- kubernetes.pool.kube-proxy
