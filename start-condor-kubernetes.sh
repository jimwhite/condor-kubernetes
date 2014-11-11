#!/bin/bash

# KUBERNETES_PROVIDER=gce # is the default (see kube-env.sh).
# KUBE_CONFIG_FILE=config-default.sh # or config-test.sh

# Start Kube:
$KUBE_HOME/cluster/kube-up.sh

# Spin up the Condor manager:
$KUBE_HOME/cluster/kubecfg.sh -c ~/Projects/dockerfiles/condor/kubernetes/condor-manager.json create pods

# See that it is running by polling list pods:
$KUBE_HOME/cluster/kubecfg.sh list pods

# Spin up the Condor manager service:
$KUBE_HOME/cluster/kubecfg.sh -c ~/Projects/dockerfiles/condor/kubernetes/condor-manager-service.json create services

# Spin up the Condor executor controller:
$KUBE_HOME/cluster/kubecfg.sh -c ~/Projects/dockerfiles/condor/kubernetes/condor-executor-controller.json create replicationControllers

$KUBE_HOME/cluster/kubecfg.sh list pods
$KUBE_HOME/cluster/kubecfg.sh list services
$KUBE_HOME/cluster/kubecfg.sh list replicationControllers

gcloud compute instances list
#NAME                ZONE          MACHINE_TYPE  INTERNAL_IP    EXTERNAL_IP     STATUS
#kubernetes-minion-3 us-central1-b n1-standard-1 10.240.27.240  146.148.65.178  RUNNING
#kubernetes-minion-4 us-central1-b n1-standard-1 10.240.65.105  130.211.163.206 RUNNING
#kubernetes-minion-1 us-central1-b n1-standard-1 10.240.180.64  130.211.121.209 RUNNING
#kubernetes-master   us-central1-b n1-standard-1 10.240.26.143  146.148.75.238  RUNNING
#kubernetes-minion-2 us-central1-b n1-standard-1 10.240.254.204 130.211.135.3   RUNNING

gcloud compute firewall-rules list
#NAME                     NETWORK SRC_RANGES    RULES                        SRC_TAGS TARGET_TAGS
#default-allow-icmp       default 0.0.0.0/0     icmp
#default-allow-internal   default 10.240.0.0/16 tcp:1-65535,udp:1-65535,icmp
#default-allow-rdp        default 0.0.0.0/0     tcp:3389
#default-allow-ssh        default 0.0.0.0/0     tcp:22
#default-default-internal default 10.0.0.0/8    udp:1-65535,tcp:1-65535,icmp
#default-default-ssh      default 0.0.0.0/0     tcp:22
#kubernetes-master-https  default 0.0.0.0/0     tcp:443                               kubernetes-master
#kubernetes-minion-1-all  default 10.244.1.0/24 icmp,sctp,tcp,udp,esp,ah
#kubernetes-minion-2-all  default 10.244.2.0/24 icmp,sctp,tcp,udp,esp,ah
#kubernetes-minion-3-all  default 10.244.3.0/24 icmp,sctp,tcp,udp,esp,ah
#kubernetes-minion-4-all  default 10.244.4.0/24 icmp,sctp,tcp,udp,esp,ah
#kubernetes-minion-8080   default 0.0.0.0/0     tcp:8080                              kubernetes-minio#n

# Up the number of Condor workers.  
# Note that the default NUM_MINIONS for GCE (cluster/gce/config-default.sh) is 4.
# $KUBE_HOME/cluster/kubecfg.sh resize condorExecutorController 6
