# Testing kubespray in AWS

## Introduction

### Purpose

Exploring how to use kubespray to start k8s on aws instances.

### Vocabulary

### References

* [Deploy a Production Ready Kubernetes Cluster](https://kubespray.io/#/)
* [kubespray github project](https://github.com/kubernetes-sigs/kubespray)
* [Kubernetes at Home with Kubespray and Ansible](https://www.youtube.com/watch?v=1W4w2ziRU8Q)

* [!!! BEWARE of forked project](https://github.com/kubespray/kubespray)

## Installation

* ssh-keygen -t ed25519 -b 512  -q -f private_admin_id_ed25519
* ssh-keygen -t rsa -b 2048  -q -f private_admin_id_rsa

### Deploying the instances in AWS

* terraform init
* terraform plan
* terraform apply

### Prep the install-instance

* sudo apt update
* sudo apt install -y byobu git
* git clone -b baseline_instance_deployment https://github.com/henkoch/poc_kubespray.git
* cd poc_kubespray

### prep for kubsespray

* Do this in the bastion instance
* `git clone https://github.com/kubernetes-sigs/kubespray.git`
* sudo apt install -y python3-venv
* python3 -m venv kubespray-venv
* source kubespray-venv/bin/activate
* cd kubespray
* pip install -U -r requirements.txt
* pip install ruamel.yaml
  * a requirement not mentioned?
* cd ..
* mkdir -p clusters/aws-k8s
* declare -a IPS=(ip1 ip2 ip3 ip4)
* CONFIG_FILE=clusters/aws-k8s/hosts.yaml python3 kubespray/contrib/inventory_builder/inventory.py ${IPS[@]}
* Edit the clusters/aws-k8s/cluster-config.yaml
  * Set name?
  * select k8s version
* cd kubespray
* ansible-inventory -i ../clusters/aws-k8s/hosts.yaml --list
* ansible-playbook -i ../clusters/aws-k8s/hosts.yaml -e @../clusters/aws-k8s/cluster-config.yaml --private-key ../terraform/aws/private_admin_id_ed25519 --user=admin --become --become-user=root cluster.yml
  * -i: inventory file
  * -e: extra variables
    * TODO what is the purpose of '@'?
  * --private-key: specify the private key to use in the ssh command
* ssh to the first node
* sudo -i
* kubectl get nodes
* add 6443 tcp to inbound rules in the SG
* 

### Upgrade cluster

* update the version in cluster-config.yaml
* ansible-playbook -i ../clusters/aws-k8s/hosts.yaml -e @../clusters/aws-k8s/cluster-config.yaml --private-key ../terraform/aws/private_admin_id_ed25519 --user=admin --become --become-user=root upgrade-cluster.yml
  * Please note the file is now: 'upgrade-'cluster.yml

### Other yml

* remove-node.yml
* add node: scale.yml --limit=nodeX
  * first update the hosts.yaml


## Troubleshooting

### Troubleshooting ansible

#### ERROR! Unable to retrieve file contents Could not find or access '/home/hck/Dropbox/Sources/Servers/clusters/aws-k8s/cluster-config.yaml' on the Ansible Controller

Fix: the -e @ had two '../../' instead of one '../'

```text
ERROR! Unable to retrieve file contents
Could not find or access '/home/hck/Dropbox/Sources/Servers/clusters/aws-k8s/cluster-config.yaml' on the Ansible Controller.
```

#### [Errno 2] No such file or directory: b'amazon-linux-extras'", "rc": 2, "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []

This seems to be because aws linux 2023 does not have amazon-linux-extras, only linux 2 [sudo: amazon-linux-extras: command not found](https://stackoverflow.com/questions/75966794/sudo-amazon-linux-extras-command-not-found)

for linux 2 there are also issues: [Amazon Linux 2](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operating_systems/amazonlinux.md)

```text
TASK [bootstrap-os : Enable selinux-ng repo for Amazon Linux for container-selinux] **********************************************************************************
[WARNING]: Platform linux on host node3 is using the discovered Python interpreter at /usr/bin/python3.9, but future installation of another Python interpreter could
change the meaning of that path. See https://docs.ansible.com/ansible-core/2.16/reference_appendices/interpreter_discovery.html for more information.
fatal: [node3]: FAILED! => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3.9"}, "changed": false, "cmd": "amazon-linux-extras enable selinux-ng", "msg": "[Errno 2] No such file or directory: b'amazon-linux-extras'", "rc": 2, "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
[WARNING]: Platform linux on host node4 is using the discovered Python interpreter at /usr/bin/python3.9, but future installation of another Python interpreter could
change the meaning of that path. See https://docs.ansible.com/ansible-core/2.16/reference_appendices/interpreter_discovery.html for more information.
fatal: [node4]: FAILED! => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3.9"}, "changed": false, "cmd": "amazon-linux-extras enable selinux-ng", "msg": "[Errno 2] No such file or directory: b'amazon-linux-extras'", "rc": 2, "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
[WARNING]: Platform linux on host node2 is using the discovered Python interpreter at /usr/bin/python3.9, but future installation of another Python interpreter could
change the meaning of that path. See https://docs.ansible.com/ansible-core/2.16/reference_appendices/interpreter_discovery.html for more information.
fatal: [node2]: FAILED! => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3.9"}, "changed": false, "cmd": "amazon-linux-extras enable selinux-ng", "msg": "[Errno 2] No such file or directory: b'amazon-linux-extras'", "rc": 2, "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
[WARNING]: Platform linux on host node1 is using the discovered Python interpreter at /usr/bin/python3.9, but future installation of another Python interpreter could
change the meaning of that path. See https://docs.ansible.com/ansible-core/2.16/reference_appendices/interpreter_discovery.html for more information.
fatal: [node1]: FAILED! => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3.9"}, "changed": false, "cmd": "amazon-linux-extras enable selinux-ng", "msg": "[Errno 2] No such file or directory: b'amazon-linux-extras'", "rc": 2, "stderr": "", "stderr_lines": [], "stdout": "", "stdout_lines": []}
```

#### fatal: [node1]: FAILED! => {"msg": "Timeout (302s) waiting for privilege escalation prompt: "}

my public IP address had changed, so I needed to update that in the aws security group information in the private_variables.tf

```text
TASK [bootstrap-os : Fetch /etc/os-release] **************************************************************************************************************************
fatal: [node1]: FAILED! => {"msg": "Timeout (302s) waiting for privilege escalation prompt: "}
fatal: [node4]: FAILED! => {"msg": "Timeout (302s) waiting for privilege escalation prompt: "}
fatal: [node2]: FAILED! => {"msg": "Timeout (302s) waiting for privilege escalation prompt: "}
fatal: [node3]: FAILED! => {"msg": "Timeout (302s) waiting for privilege escalation prompt: "}

NO MORE HOSTS LEFT ***************************************************************************************************************************************************

PLAY RECAP ***********************************************************************************************************************************************************
node1                      : ok=3    changed=0    unreachable=0    failed=1    skipped=6    rescued=0    ignored=0   
node2                      : ok=0    changed=0    unreachable=0    failed=1    skipped=3    rescued=0    ignored=0   
node3                      : ok=0    changed=0    unreachable=0    failed=1    skipped=3    rescued=0    ignored=0   
node4                      : ok=0    changed=0    unreachable=0    failed=1    skipped=3    rescued=0    ignored=0   
```

### SSH connection

#### ec2-user@AWS_PUB_IP: Permission denied (publickey)

the user is 'admin' for debian bookworm

Maybe RSA can be used, but I generated a new pair using ED25519

```text
ssh -i private_admin_id_rsa ec2-user@AWS_PUB_IP
The authenticity of host 'AWS_PUB_IP (AWS_PUB_IP)' can't be established.
ED25519 key fingerprint is SHA256:wJFjVkec9B1+BncHpN5N8bhW8k6Pp7LjVeaXii2Zajg.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'AWS_PUB_IP' (ED25519) to the list of known hosts.
ec2-user@AWS_PUB_IP: Permission denied (publickey).
```

#### "msg": "IPv4: '['10.0.1.136']' and IPv6: '['fe80::4a8:19ff:feca:2f45']' do not contain 'Public_IP_addr1'"

Seems like you need to run this from an instance in the same subnet

```text
TASK [kubernetes/preinstall : Stop if ip var does not match local ips] ****************************************************************************************************************************************************************************************
fatal: [node1]: FAILED! => {
    "assertion": "(ip in ansible_all_ipv4_addresses) or (ip in ansible_all_ipv6_addresses)",
    "changed": false,
    "evaluated_to": false,
    "msg": "IPv4: '['10.0.1.136']' and IPv6: '['fe80::4a8:19ff:feca:2f45']' do not contain 'Public_IP_addr1'"
}
fatal: [node2]: FAILED! => {
    "assertion": "(ip in ansible_all_ipv4_addresses) or (ip in ansible_all_ipv6_addresses)",
    "changed": false,
    "evaluated_to": false,
    "msg": "IPv4: '['10.0.1.20']' and IPv6: '['fe80::4e1:d1ff:fe32:4e37']' do not contain 'Public_IP_addr2'"
}
fatal: [node3]: FAILED! => {
    "assertion": "(ip in ansible_all_ipv4_addresses) or (ip in ansible_all_ipv6_addresses)",
    "changed": false,
    "evaluated_to": false,
    "msg": "IPv4: '['10.0.1.126']' and IPv6: '['fe80::49b:adff:fe27:b63d']' do not contain 'Public_IP_addr3'"
}
fatal: [node4]: FAILED! => {
    "assertion": "(ip in ansible_all_ipv4_addresses) or (ip in ansible_all_ipv6_addresses)",
    "changed": false,
    "evaluated_to": false,
    "msg": "IPv4: '['10.0.1.77']' and IPv6: '['fe80::450:77ff:feba:ca6b']' do not contain 'Public_IP_addr4'"
}

NO MORE HOSTS LEFT ********************************************************************************************************************************************************************************************************************************************

PLAY RECAP ****************************************************************************************************************************************************************************************************************************************************
node1                      : ok=56   changed=2    unreachable=0    failed=1    skipped=24   rescued=0    ignored=0   
node2                      : ok=49   changed=2    unreachable=0    failed=1    skipped=19   rescued=0    ignored=0   
node3                      : ok=48   changed=2    unreachable=0    failed=1    skipped=20   rescued=0    ignored=0   
node4                      : ok=47   changed=2    unreachable=0    failed=1    skipped=21   rescued=0    ignored=0   
```


Finished

```text
TASK [network_plugin/calico : Check ipip and vxlan mode if simultaneously enabled] *******************************************************************************************************************************************************************************************************
ok: [node1] => {
    "changed": false,
    "msg": "All assertions passed"
}
Sunday 08 September 2024  17:50:50 +0000 (0:00:00.058)       0:13:29.038 ****** 

TASK [network_plugin/calico : Get Calico default-pool configuration] *********************************************************************************************************************************************************************************************************************
ok: [node1]
Sunday 08 September 2024  17:50:51 +0000 (0:00:00.366)       0:13:29.404 ****** 

TASK [network_plugin/calico : Set calico_pool_conf] **************************************************************************************************************************************************************************************************************************************
ok: [node1]
Sunday 08 September 2024  17:50:51 +0000 (0:00:00.056)       0:13:29.461 ****** 

TASK [network_plugin/calico : Check if inventory match current cluster configuration] ****************************************************************************************************************************************************************************************************
ok: [node1] => {
    "changed": false,
    "msg": "All assertions passed"
}
Sunday 08 September 2024  17:50:51 +0000 (0:00:00.078)       0:13:29.539 ****** 
Sunday 08 September 2024  17:50:51 +0000 (0:00:00.046)       0:13:29.586 ****** 
Sunday 08 September 2024  17:50:51 +0000 (0:00:00.040)       0:13:29.627 ****** 

PLAY RECAP *******************************************************************************************************************************************************************************************************************************************************************************
node1                      : ok=653  changed=139  unreachable=0    failed=0    skipped=1110 rescued=0    ignored=6   
node2                      : ok=562  changed=127  unreachable=0    failed=0    skipped=979  rescued=0    ignored=3   
node3                      : ok=484  changed=106  unreachable=0    failed=0    skipped=675  rescued=0    ignored=2   
node4                      : ok=418  changed=83   unreachable=0    failed=0    skipped=645  rescued=0    ignored=1   

Sunday 08 September 2024  17:50:51 +0000 (0:00:00.188)       0:13:29.815 ****** 
=============================================================================== 
kubernetes/control-plane : Kubeadm | Initialize first control plane node --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 30.34s
kubernetes/preinstall : Install packages requirements ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 26.94s
etcd : Reload etcd --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 20.59s
download : Download_file | Download item ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 19.82s
kubernetes/control-plane : Joining control plane node to the cluster. ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 18.01s
download : Download_file | Download item ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 17.62s
kubernetes/kubeadm : Join to cluster --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 15.31s
container-engine/containerd : Download_file | Download item ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 13.43s
container-engine/crictl : Download_file | Download item -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 12.55s
etcd : Gen_certs | Write etcd member/admin and kube_control_plane client certs to other etcd nodes ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 12.23s
container-engine/runc : Download_file | Download item ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 12.12s
container-engine/nerdctl : Download_file | Download item ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 11.56s
download : Download_container | Download image if required ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 10.19s
container-engine/crictl : Extract_file | Unpacking archive ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 9.82s
kubernetes-apps/ansible : Kubernetes Apps | Start Resources ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 8.80s
download : Download_container | Download image if required ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 8.62s
etcdctl_etcdutl : Download_file | Download item ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 8.55s
container-engine/nerdctl : Extract_file | Unpacking archive ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 8.17s
kubernetes/preinstall : Preinstall | wait for the apiserver to be running --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 7.60s
kubernetes-apps/ansible : Kubernetes Apps | Lay Down CoreDNS templates ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 7.37s
(kubespray-venv) admin@ip-10-0-1-170:~/poc_kubespray/kubespray$ 
```

#### Get "https://127.0.0.1:6443/api?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused

Change the server address in the ~/.kube/config file

```text
k get nodes
E0908 22:19:30.816657 1745037 memcache.go:265] couldn't get current server API group list: Get "https://127.0.0.1:6443/api?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused
E0908 22:19:30.817432 1745037 memcache.go:265] couldn't get current server API group list: Get "https://127.0.0.1:6443/api?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused
E0908 22:19:30.819190 1745037 memcache.go:265] couldn't get current server API group list: Get "https://127.0.0.1:6443/api?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused
E0908 22:19:30.819596 1745037 memcache.go:265] couldn't get current server API group list: Get "https://127.0.0.1:6443/api?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused
E0908 22:19:30.821173 1745037 memcache.go:265] couldn't get current server API group list: Get "https://127.0.0.1:6443/api?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused
The connection to the server 127.0.0.1:6443 was refused - did you specify the right host or port?
```

#### E0908 22:20:13.161163 1745399 memcache.go:265] couldn't get current server API group list: Get "https://51.20.75.108:6443/api?timeout=32s": tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 10.0.1.136, 127.0.0.1, 10.0.1.20, not 51.20.75.108

TODO this is the certificate thing, I have to sign a new certificate with that address.
Possibly put a load balancer in front

```text
k get nodes
E0908 22:20:13.034610 1745399 memcache.go:265] couldn't get current server API group list: Get "https://51.20.75.108:6443/api?timeout=32s": tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 10.0.1.136, 127.0.0.1, 10.0.1.20, not 51.20.75.108
E0908 22:20:13.079450 1745399 memcache.go:265] couldn't get current server API group list: Get "https://51.20.75.108:6443/api?timeout=32s": tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 10.0.1.136, 127.0.0.1, 10.0.1.20, not 51.20.75.108
E0908 22:20:13.120101 1745399 memcache.go:265] couldn't get current server API group list: Get "https://51.20.75.108:6443/api?timeout=32s": tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 10.0.1.136, 127.0.0.1, 10.0.1.20, not 51.20.75.108
E0908 22:20:13.161163 1745399 memcache.go:265] couldn't get current server API group list: Get "https://51.20.75.108:6443/api?timeout=32s": tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 10.0.1.136, 127.0.0.1, 10.0.1.20, not 51.20.75.108
E0908 22:20:13.206584 1745399 memcache.go:265] couldn't get current server API group list: Get "https://51.20.75.108:6443/api?timeout=32s": tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 10.0.1.136, 127.0.0.1, 10.0.1.20, not 51.20.75.108
Unable to connect to the server: tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 10.0.1.136, 127.0.0.1, 10.0.1.20, not 51.20.75.108
```