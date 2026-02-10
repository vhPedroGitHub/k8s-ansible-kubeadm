#### Variables ####

export ROOT_DIR ?= $(PWD)
export KUBEADMIN_ROOT_DIR ?= $(ROOT_DIR)
export K8s_ROOT_DIR ?= $(ROOT_DIR)

export HOSTS_INI_FILE ?= $(K8s_ROOT_DIR)/hosts.ini

export EXTRA_VARS ?= "@$(K8s_ROOT_DIR)/vars/main.yml"

# Makefile for kubeadmin

KUBEADMIN_PLAYBOOK_INSTALL := $(KUBEADMIN_ROOT_DIR)/install.yml
KUBEADMIN_PLAYBOOK_UNINSTALL := $(KUBEADMIN_ROOT_DIR)/uninstall.yml
KUBEADMIN_PLAYBOOK := $(KUBEADMIN_ROOT_DIR)/kubeadm.yml

# Install kubeadm, kubelet, kubectl, and containerd
kubeadmin-install:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK_INSTALL) \
		--tags "install" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadmin-setup:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK) \
		--tags "kubeadmin" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# TODO: implement playbook to setup nodes with kubeadm configs
kubeadmin-setup-configs:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK) \
		--tags "kubeadmin-configs" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadmin-uninstall-cluster:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK) \
		--tags "uninstall-kubeadmin" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadmin-add-workers:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK) \
		--tags "add-workers" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

kubeadmin-remove-workers:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK) \
		--tags "remove-workers" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# Uninstall kubeadm, kubelet, kubectl, and containerd
kubeadmin-uninstall:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK_UNINSTALL) \
		--tags "uninstall" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

# Restore swap after uninstallation (optional)
kubeadmin-restore-swap:
	ansible-playbook -i $(HOSTS_INI_FILE) $(KUBEADMIN_PLAYBOOK_UNINSTALL) \
		--tags "restore-swap" --extra-vars "ROOT_DIR=$(ROOT_DIR)" \
		--extra-vars $(EXTRA_VARS)

install-helm:
	sudo apt-get install curl gpg apt-transport-https --yes
	curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
	echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
	sudo apt-get update --yes
	sudo apt-get install helm --yes