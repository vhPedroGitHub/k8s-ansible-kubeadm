# k8s-ansible-kubeadm
Ansible playbooks to manage clusters with kubeadm

## Install ansible

### Fedora

```bash
sudo dnf install ansible
sudo dnf install ansible-core
sudo dnf install ansible-collection-community-general
```

### Ubuntu

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```