{%- from "kubernetes/map.jinja" import master with context %}
{%- if master.enabled %}

/etc/calico/network-environment:
  file.managed:
    - source: salt://kubernetes/files/calico/network-environment.master
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/etc/calico/calicoctl.cfg:
  file.managed:
    - source: salt://kubernetes/files/calico/calicoctl.cfg.master
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/tmp/calico/:
  file.directory:
      - user: root
      - group: root

copy-calico-ctl:
  cmd.run:
    - name: docker run --rm -v /tmp/calico/:/tmp/calico/ --entrypoint cp {{ master.network.calico.calicoctl_image }} -v /calicoctl /tmp/calico/
    - require:
      - file: /tmp/calico/
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/usr/bin/calicoctl:
  file.managed:
    - source: /tmp/calico/calicoctl
    - mode: 751
    - user: root
    - group: root
    - require:
      - cmd: copy-calico-ctl
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- if master.network.calico.get('systemd', true) %}

/etc/systemd/system/calico-node.service:
  file.managed:
    - source: salt://kubernetes/files/calico/calico-node.service.master
    - user: root
    - group: root
    - template: jinja

calico_node:
  service.running:
    - name: calico-node
    - enable: True
    - watch:
      - file: /etc/systemd/system/calico-node.service
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    
{%- endif %}

{%- endif %}
