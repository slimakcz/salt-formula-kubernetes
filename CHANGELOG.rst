kubernetes formula
==================

2018.3.1 (2018-03-15)

- deprecate network.engine field
- use subsection in network for CNI related setting

2017.1.2 (2017-01-19)

- fix cni copy order

2017.1.1 (2017-01-18)

- move basic k8s setup to common
- copy cni from hyperkube
- configurable calico node image
- use calico/cni image for obtaining cnis
- use calico/ctl image for obtaining calicoctl binary
- add cross requirement for k8s services and hyperkube
- update metadata for new pillar model
- update manifests to use hyperkube from common


2016.8.3 (2016-08-12)

- remove obsolete kube-addons scripts

2016.8.2 (2016-08-10)

- minor fixes

2016.8.1 (2016-08-05)

- second release

0.0.1 (2016-06-13)

- Initial formula setup
