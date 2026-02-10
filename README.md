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
## Quick Start

### Install Kubernetes Cluster

```bash
# Install kubeadm, kubelet, kubectl and containerd
make kubeadm-install

# Initialize master and add workers
make kubeadm-setup

# Add worker nodes
make kubeadm-add-workers
```

### Uninstall Kubernetes Cluster

```bash
# Remove cluster
make kubeadm-uninstall-cluster

# Uninstall all components
make kubeadm-uninstall

# Restore swap (optional)
make kubeadm-restore-swap
```

## Container Image Backup & Restore

The `extras` role provides functionality to backup, copy, and restore container images across all Kubernetes nodes.

### Backup Workflow

```bash
# Step 1: Backup all images from nodes
make backup-images

# Step 2: Copy backups to centralized directory
make copy-backups

# Or run both steps together
make backup-all
```

### Restore Workflow

```bash
# Restore images from tar files
make restore-images

# Verify restored images
make verify-images
```

### Manual Commands

```bash
# Backup
ansible-playbook -i hosts.ini backup_images.yml

# Copy
ansible-playbook -i hosts.ini copy_backups.yml

# Restore
ansible-playbook -i hosts.ini restore_images.yml
```

### Cleanup

```bash
# Remove all backup files
make clean-backups
```

### Use Cases

- **Disaster Recovery**: Backup images before cluster maintenance
- **Cluster Migration**: Export images from old cluster, import to new
- **Air-Gapped Deployments**: Transfer images via tar files
- **Testing**: Save clean state, restore after tests

Backup files are stored in: `/opt/tarz-k8s/restore-in-all-nodes/`

See [roles/extras/README.md](roles/extras/README.md) for detailed documentation.

## Available Make Targets

```bash
make kubeadm-install           # Install K8s components
make kubeadm-setup             # Initialize cluster
make kubeadm-add-workers       # Add worker nodes
make kubeadm-remove-workers    # Remove worker nodes
make kubeadm-uninstall-cluster # Uninstall cluster
make kubeadm-uninstall         # Full uninstall
make kubeadm-restore-swap      # Restore swap after uninstall

make backup-images             # Backup container images
make copy-backups              # Copy backups to restore dir
make restore-images            # Restore images from backups
make backup-all                # Backup + copy workflow
make verify-images             # Verify restored images
make clean-backups             # Remove backup files
```
