{% from "kubernetes/map.jinja" import control with context %}
include:
  - kubernetes.control

{%- for job_name, job in control.job.items() %}

/srv/kubernetes/jobs/{{ job_name }}-job.yml:
  file.managed:
  - source: salt://kubernetes/files/job.yml
  - user: root
  - group: root
  - template: jinja
  - makedirs: true
  - require:
    - file: /srv/kubernetes
  - defaults:
      job: {{ job|yaml }}

{%- endfor %}
