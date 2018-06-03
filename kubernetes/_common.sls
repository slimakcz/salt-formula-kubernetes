{%- from "kubernetes/map.jinja" import common with context %}

kubernetes_pkgs:
  pkg.installed:
  - names: {{ common.pkgs }}

{%- if common.hyperkube is defined %}
/tmp/hyperkube:
  file.directory:
    - user: root
    - group: root

hyperkube-copy:
  cmd.run:
    - name: docker run --rm -v /tmp/hyperkube:/tmp/hyperkube --entrypoint cp {{ common.hyperkube.image }} -vr /hyperkube /tmp/hyperkube
    - require:
      - file: /tmp/hyperkube
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/usr/bin/hyperkube:
  file.managed:
    - source: /tmp/hyperkube/hyperkube
    - mode: 751
    - makedirs: true
    - user: root
    - group: root
    - require:
      - cmd: hyperkube-copy
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/usr/bin/kubectl:
  file.symlink:
    - target: /usr/bin/hyperkube
    - require:
      - file: /usr/bin/hyperkube
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- if common.addons.get('virtlet', {}).get('enabled') %}

/usr/bin/criproxy:
  file.managed:
    - source: https://github.com/mirantis/criproxy/releases/download/{{ common.addons.virtlet.get('criproxy_version', 'v0.10.0') }}/criproxy
    - mode: 750
    - makedirs: true
    - user: root
    - group: root
    - source_hash: {{ common.addons.virtlet.get('criproxy_source', 'md5=52717b1f70f15558ef4bdb0e4d4948da') }}
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- if not pillar.kubernetes.pool is defined %}

/etc/default/dockershim:
  file.managed:
  - source: salt://kubernetes/files/dockershim/default.master
  - template: jinja
  - user: root
  - group: root
  - mode: 644

{%- else %}

/etc/default/dockershim:
  file.managed:
  - source: salt://kubernetes/files/dockershim/default.pool
  - template: jinja
  - user: root
  - group: root
  - mode: 644

{%- endif %}

/etc/criproxy:
  file.directory:
    - user: root
    - group: root
    - mode: 0750

/etc/criproxy/node.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 0640
    - contents: ''

/etc/systemd/system/dockershim.service:
  file.managed:
    - source: salt://kubernetes/files/systemd/dockershim.service
    - template: jinja
    - user: root
    - group: root
    - mode: 755

/etc/systemd/system/criproxy.service:
  file.managed:
    - source: salt://kubernetes/files/systemd/criproxy.service
    - template: jinja
    - user: root
    - group: root
    - mode: 755

dockershim_service:
  service.running:
  - name: dockershim
  - enable: True
  - watch:
    - file: /etc/default/dockershim
    - file: /usr/bin/hyperkube
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

criproxy_service:
  service.running:
  - name: criproxy
  - enable: True
  - watch:
    - file: /etc/systemd/system/criproxy.service
    - file: /etc/criproxy/node.conf
    - file: /usr/bin/criproxy
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- else %}

/etc/criproxy:
  file.absent

dockershim_service:
  service.dead:
  - name: dockershim
  - enable: False

criproxy_service:
  service.dead:
  - name: criproxy
  - enable: False

{%- endif %}

/etc/systemd/system/kubelet.service:
  file.managed:
    - source: salt://kubernetes/files/systemd/kubelet.service
    - template: jinja
    - user: root
    - group: root
    - mode: 644

/etc/kubernetes/config:
  file.absent

{%- if common.get('cloudprovider', {}).get('enabled') and common.get('cloudprovider', {}).get('provider') == 'openstack' %}
/etc/kubernetes/cloud-config.conf:
  file.managed:
  - source: salt://kubernetes/files/cloudprovider/cloud-config-openstack.conf
  - template: jinja
  - user: root
  - group: root
  - mode: 600

{% endif %}

{%- if not pillar.kubernetes.pool is defined %}

/etc/default/kubelet:
  file.managed:
  - source: salt://kubernetes/files/kubelet/default.master
  - template: jinja
  - user: root
  - group: root
  - mode: 644

/etc/kubernetes/kubelet.kubeconfig:
  file.managed:
    - source: salt://kubernetes/files/kubelet/kubelet.kubeconfig.master
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true

{%- else %}

/etc/default/kubelet:
  file.managed:
  - source: salt://kubernetes/files/kubelet/default.pool
  - template: jinja
  - user: root
  - group: root
  - mode: 644

/etc/kubernetes/kubelet.kubeconfig:
  file.managed:
    - source: salt://kubernetes/files/kubelet/kubelet.kubeconfig.pool
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true

{%- endif %}

manifest_dir_create:
  file.directory:
    - makedirs: true
    - name: /etc/kubernetes/manifests
    - user: root
    - group: root
    - mode: 0751

kubelet_service:
  service.running:
  - name: kubelet
  - enable: True
  - watch:
    - file: /etc/default/kubelet
    - file: /usr/bin/hyperkube
    - file: /etc/kubernetes/kubelet.kubeconfig
    - file: manifest_dir_create
  {%- if grains.get('noservices') %}
  - onlyif: /bin/false
  {%- endif %}

{%- if common.logrotate is defined %}
/etc/logrotate.d/kubernetes:
  file.managed:
    - source: salt://kubernetes/files/logrotate
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - defaults:
      logfile: {{ common.logrotate }}

{% endif %}
{% endif %}

{%- if common.cni is defined %}
/opt/cni/bin:
  archive.extracted:
    - source: {{ common.cni.plugins.source }}
    - source_hash: md5={{ common.cni.plugins.hash }}
    - tar_options: xzf
    - archive_format: tar
    - if_missing: /opt/cni/bin/host-local
{%- endif %}
