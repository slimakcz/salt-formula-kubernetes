{%- from "kubernetes/map.jinja" import master with context %}
{%- if master.enabled %}

{%- if not pillar.kubernetes.pool is defined %}

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
        hostname: {{ master.host.name }}{% if master.host.get('domain') %}.{{ master.host.domain }}{%- endif %}
        {%- if master.network.genie.default_plugin is defined %}
        default_plugin: {{ master.network.genie.default_plugin }}
        {%- endif %}

/tmp/genie/:
  file.directory:
      - user: root
      - group: root

copy-genie-bin:
  cmd.run:
    - name: docker run --rm -v /tmp/genie/:/tmp/genie/ --entrypoint cp {{ master.network.genie.image }} -v /opt/cni/bin/genie /tmp/genie/
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

{%- endif %}
