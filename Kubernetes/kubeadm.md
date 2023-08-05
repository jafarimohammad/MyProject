## setp 0:
```
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
```
----------------------------------------------------------------------------------------
* 2 GB or more of RAM per machine (any less will leave little room for your apps).
* 2 CPUs or more.
* Full network connectivity between all machines in the cluster (public or private network is fine).
* Unique hostname, MAC address, and product_uuid for every node. See [here](#verify-mac-address) for more details. ( `ip link` or `ifconfig -a` | `sudo cat /sys/class/dmi/id/product_uuid` )
* Certain ports are open on your machines. See [here](#check-required-ports) for more details. ( `nc 127.0.0.1 6443` )
* Swap disabled. You **MUST** disable swap in order for the kubelet to work properly.
    * For example, `sudo swapoff -a` will disable swapping temporarily. To make this change persistent across reboots, make sure swap is disabled in config files like `/etc/fstab`, `systemd.swap`, depending how it was configured on your system.
----------------------------------------------------------------------------------------

## setp 1: Install and configure prerequisites
every node: 
```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```
-------------------------------------------------------------------------------------------

## step 2: installing containerd (CRI)
every node: 
```
wget https://github.com/containerd/containerd/releases/download/v1.7.3/containerd-1.7.3-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.7.3-linux-amd64.tar.gz
```
## Create Service:
```
/usr/lib/systemd/system/containerd.service :

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
```
```
systemctl daemon-reload
systemctl enable --now containerd
```
---------------------------------------------------------------------------------------------------

## install runc:
```
wget https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64
cp runc.amd64 /usr/local/sbin/runc OR install -m 755 runc.amd64 /usr/local/sbin/runc
```
----------------------------------------------------------------------------------------------------

## install CNI plugin:
```
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.3.0.tgz
```
-----------------------------------------------------------------------------------------------------

## step 3: Installing kubeadm, kubelet and kubectl 
every node: 
```
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://dl.k8s.io/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
------------------------------------------------------------------------------------------------

## step 4: kubeadm initialize
```
https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
```
```
kubeadm config images pull
kubeadm init --apiserver-advertise-address 192.168... --pod-network-cidr 10.96.0.0/12

#for import image => ctr image import image.tar
```
```
export KUBECONFIG=/etc/kubernetes/admin.conf
```
--------------------------------------------------------------------------------------------------------

## step 5: install calico
```
https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
```
```
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico-typha.yaml -o calico.yaml
# Change CALICO_IPV4POOL_CIDR value to 10.96.0.0/12

kubectl apply -f calico.yaml
```
