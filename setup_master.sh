#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

## Add user sysadm & apm
username1="sysadm"
password1="sysadm@123"

## Check if the user already exists
if id "$username1" &>/dev/null; then
    echo "User '$username1' already exists."
else
    # Create the user with the provided username and set the password
    sudo useradd -m -s /bin/bash "$username1"
    echo "$username1:$password1" | sudo chpasswd

    echo "User '$username1' created successfully."
fi

## Add user sysadm visudo
echo "sysadm          ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

## Setting ip_forward
sudo sysctl -w net.ipv4.ip_forward=1

## Firewall disable
systemctl stop firewalld
systemctl disable firewalld >/dev/null 2>&1

## Selinux disable
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

## off swap
sed -i '/swap/d' /etc/fstab
swapoff -a

## Fix ssh weak
echo "
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com" >> /etc/ssh/sshd_config
systemctl restart sshd

## Fix host splunk
cd /tmp/
chmod +x installsplunk9-redhat.sh
sh installsplunk9-redhat.sh >/dev/null 2>&1
cat >> /opt/splunkforwarder/etc/system/local/deploymentclient.conf<<EOF
[target-broker:deploymentServer]
targetUri = 10.6.12.30:8089
EOF

echo "
192.168.10.11 giangnh-master1
192.168.10.12 giangnh-master2
192.168.10.13 giangnh-master3
192.168.10.14 giangnh-worker1
192.168.10.15 giangnh-worker2
192.168.10.16 giangnh-worker3
192.168.10.18 giangnh-gitlab
192.168.10.19 giangnh-rancher
192.168.10.20 giangnh-cicd " >> /etc/hosts
sysctl -p

##Setup docker
# Cai dat Docker
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum update -y && yum install docker-ce -y 
usermod -aG docker $(whoami)

# Restart Docker
systemctl enable docker.service
systemctl daemon-reload
systemctl restart docker
