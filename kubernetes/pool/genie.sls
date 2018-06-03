{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.enabled %}

/etc/cni/net.d/00-genie.conf:
  file.managed:
    - source: salt://kubernetes/files/genie/genie.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja
    - defaults:
        hostname: {{ pool.host.name }}{% if pool.host.get('domain') %}.{{ pool.host.domain }}{%- endif %}
        {%- if pool.network.genie.default_plugin is defined %}
        default_plugin: {{ pool.network.genie.default_plugin }}
        {%- endif %}

/tmp/genie/:
  file.directory:
      - user: root
      - group: root

copy-genie-bin:
  cmd.run:
    - name: docker run --rm -v /tmp/genie/:/tmp/genie/ --entrypoint cp {{ pool.network.genie.image }} -v /opt/cni/bin/genie /tmp/genie/
    - require:
      - file: /tmp/genie/
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/opt/cni/bin/genie:
  file.managed:
    - source: /tmp/genie/genie
    - mode: 751
    - user: root
    - group: root
    - require:
      - cmd: copy-genie-bin
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- endif %}
