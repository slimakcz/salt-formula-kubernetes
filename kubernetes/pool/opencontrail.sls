{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.enabled %}

/etc/cni/net.d/11-opencontrail.conf:
  file.managed:
    - source: salt://kubernetes/files/opencontrail/opencontrail.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

{%- if pool.network.opencontrail.get('version', '3.0') == '3.0' %}

/tmp/opencontrail:
  file.directory:
    - user: root
    - group: root

copy-contrail-cni:
  cmd.run:
    - name: docker cp $(docker create  {{ pool.network.opencontrail.cni_image }}):/opencontrail /tmp/opencontrail
    - require:
      - file: /tmp/opencontrail
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/opt/cni/bin/opencontrail:
  file.managed:
    - source: /tmp/opencontrail/opencontrail
    - mode: 755
    - makedirs: true
    - user: root
    - group: root
    - require:
      - cmd: copy-contrail-cni
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- else %}

opencontrail_cni_package:
  pkg.installed:
  - name: contrail-k8s-cni
  - force_yes: True

opencontrail_cni_symlink:
  file.symlink:
  - name: /opt/cni/bin/opencontrail
  - target: /usr/bin/contrail-k8s-cni
  - force: true
  - makedirs: true
  - watch_in:
    - service: kubelet_service
  - require:
    - pkg: opencontrail_cni_package

{%- endif %}

{%- endif %}
