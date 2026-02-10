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