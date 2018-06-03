{%- from "kubernetes/map.jinja" import pool with context %}

{%- if pool.get('container', 'true') %}

/etc/kubernetes/manifests/kube-proxy.manifest:
  file.managed:
    - source: salt://kubernetes/files/manifest/kube-proxy.manifest.pool
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755

{%- else %}

/etc/kubernetes/proxy.kubeconfig:
  file.managed:
    - source: salt://kubernetes/files/kube-proxy/proxy.kubeconfig
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true

/etc/systemd/system/kube-proxy.service:
  file.managed:
  - source: salt://kubernetes/files/systemd/kube-proxy.service
  - template: jinja
  - user: root
  - group: root
  - mode: 644

/etc/default/kube-proxy:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: DAEMON_ARGS=" --logtostderr=true --v={{ pool.get('verbosity', 2) }} --kubeconfig=/etc/kubernetes/proxy.kubeconfig {%- if pool.network.get('calico', {}).get('enabled', False) %} --proxy-mode=iptables{% endif %}{%- for key, value in pool.get('proxy', {}).get('daemon_opts', {}).items() %} --{{ key }}={{ value }}{%- endfor %}"

pool_services:
  service.running:
  - names: {{ pool.services }}
  - enable: True
  - watch:
    - file: /etc/default/kube-proxy
    - file: /usr/bin/hyperkube
    - file: /etc/kubernetes/proxy.kubeconfig
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- endif %}
