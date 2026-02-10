#### Variables ####

export ROOT_DIR ?= $(PWD)
export KUBEADM_ROOT_DIR ?= $(ROOT_DIR)
export K8s_ROOT_DIR ?= $(ROOT_DIR)

export HOSTS_INI_FILE ?= $(K8s_ROOT_DIR)/hosts.ini

export EXTRA_VARS ?= "@$(K8s_ROOT_DIR)/vars/main.yml"

# Makefile for kubeadm

KUBEADM_PLAYBOOK_INSTALL := $(KUBEADM_ROOT_DIR)/install.yml
KUBEADM_PLAYBOOK_UNINSTALL := $(KUBEADM_ROOT_DIR)/uninstall.yml
KUBEADM_PLAYBOOK := $(KUBEADM_ROOT_DIR)/kubeadm.yml

# Install kubeadm, kubelet, kubectl, and containerd
kubeadm-install:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK_INSTALL) \
		--tags "install" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadm-setup:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK) \
		--tags "kubeadm" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# TODO: implement playbook to setup nodes with kubeadm configs
kubeadm-setup-configs:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK) \
		--tags "kubeadm-configs" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadm-uninstall-cluster:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK) \
		--tags "uninstall-kubeadm" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadm-add-workers:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK) \
		--tags "add-workers" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadm-remove-workers:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK) \
		--tags "remove-workers" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# Uninstall kubeadm, kubelet, kubectl, and containerd
kubeadm-uninstall:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK_UNINSTALL) \
		--tags "uninstall" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# Restore swap after uninstallation (optional)
kubeadm-restore-swap:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADM_PLAYBOOK_UNINSTALL) \
		--tags "restore-swap" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

install-helm:
	sudo apt-get install curl gpg apt-transport-https --yes
	curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
	echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
	sudo apt-get update --yes
	sudo apt-get install helm --yes

# ============================================
# EXTRAS: Container Image Backup & Restore
# ============================================

# Backup all container images from nodes
backup-images:
	ansible-playbook -i $(HOSTS_INI_FILE) $(K8s_ROOT_DIR)/backup_images.yml \
		--extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# Copy backup tar files to restore directory
copy-backups:
	ansible-playbook -i $(HOSTS_INI_FILE) $(K8s_ROOT_DIR)/copy_backups.yml \
		--extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# Restore container images from tar files
restore-images:
	ansible-playbook -i $(HOSTS_INI_FILE) $(K8s_ROOT_DIR)/restore_images.yml \
		--extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# Complete backup workflow (backup + copy)
backup-all: backup-images copy-backups
	@echo "✓ Complete backup workflow finished"

# Show local backup files
show-backups:
	@echo "=== Local Backup Files ==="
	@if [ -d "backups-images" ]; then \
		du -sh backups-images 2>/dev/null || echo "No backups found"; \
		find backups-images -type f -name "*.tar" 2>/dev/null | head -20; \
	else \
		echo "No backups-images directory found. Run 'make backup-images' first."; \
	fi

# Verify restored images on all nodes
verify-images:
	ansible all -i $(HOSTS_INI_FILE) -m shell -a "ctr -n k8s.io images list | wc -l" -b

# Clean up backup files
clean-backups:
	ansible all -i $(HOSTS_INI_FILE) -m file -a "path=/opt/tarz-k8s/restore-in-all-nodes state=absent" -b
	ansible all -i $(HOSTS_INI_FILE) -m file -a "path=/tmp/k8s-images-backup state=absent" -b

# Clean local backup files
clean-local-backups:
	rm -rf backups-images/
	@echo "✓ Local backup files removed"