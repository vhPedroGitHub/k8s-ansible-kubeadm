# Extras Role - Container Image Backup & Restore

This role provides functionality to backup, copy, and restore container images across Kubernetes nodes using the local machine as an intermediary.

## Features

- **Backup**: Export all container images from each node and download to local machine in `backups-images/`
- **Copy**: Upload backup tar files from local machine to all nodes at `/opt/tarz-k8s/restore-in-all-nodes`
- **Restore**: Import container images from tar files back into containerd

## Architecture

```
┌─────────────┐          ┌──────────────────┐          ┌─────────────┐
│   Node 1    │──fetch──>│  Local Machine   │──copy──>│   Node 1    │
│             │          │ backups-images/  │         │   /opt/...  │
└─────────────┘          └──────────────────┘         └─────────────┘
                                  │                            ▲
┌─────────────┐                   │                            │
│   Node 2    │──fetch────────────┤                            │
│             │                   │                            │
└─────────────┘                   └────────────────────────────┘
                                           copy to all
```

## Directory Structure

```
roles/extras/
├── tasks/
│   ├── main.yml           # Entry point
│   ├── backup_images.yml  # Backup logic
│   ├── copy_backups.yml   # Copy logic
│   └── restore_images.yml # Restore logic
├── handlers/
│   └── main.yml
└── vars/
    └── main.yml           # Configuration variables
```

## Usage

### 1. Backup Images

Export all container images from each node and download to local machine:

```bash
ansible-playbook -i hosts.ini backup_images.yml
```

This will:
- Create `/tmp/k8s-images-backup/` on each node
- Export each image to a separate `.tar` file
- Download all tar files to `backups-images/<hostname>/` on your local machine
- Clean up temporary files from remote nodes

### 2. Copy Backups

Copy all backup files from local machine to all nodes:

```bash
ansible-playbook -i hosts.ini copy_backups.yml
```

This will:
- Create `/opt/tarz-k8s/restore-in-all-nodes/` on each node
- Upload all `.tar` files from `backups-images/` directory
- Make images available on all nodes for restore

### 3. Restore Images

Import container images from tar files:

```bash
ansible-playbook -i hosts.ini restore_images.yml
```

This will:
- Find all `.tar` files in `/opt/tarz-k8s/restore-in-all-nodes/`
- Import each image using `ctr images import`
- Display statistics of restored images

## Complete Workflow

```bash
# Step 1: Backup all images
ansible-playbook -i hosts.ini backup_images.yml

# Step 2: Copy to restore directory
ansible-playbook -i hosts.ini copy_backups.yml

# Step 3: Restore images (on same or different nodes)
ansible-playbook -i hosts.ini restore_images.yml
```

## Use Cases

1. **Disaster Recovery**: Backup images before cluster maintenance, restore on same or new nodes
2. **Cluster Migration**: Export images from old cluster, import to new cluster
3. **Air-Gapped Deployments**: Transfer images via local machine to isolated environments
4. **Testing**: Save clean state, restore after tests
5. **Multi-Cluster Sync**: Share images across multiple clusters via local backup

## Local Backup Location

Backup files are stored locally at:
```
./backups-images/
├── node1/
│   ├── registry.k8s.io_pause_3.9.tar
│   ├── docker.io_library_nginx_latest.tar
│   └── ...
├── node2/
│   ├── registry.k8s.io_pause_3.9.tar
│   └── ...
└── ...
```

Remote restore location: `/opt/tarz-k8s/restore-in-all-nodes/`

## Verification

Check images on all nodes:
```bash
ansible all -i hosts.ini -m shell -a "ctr -n k8s.io images list" -b
```

Check backup directory size:
```bash
ansible all -i hosts.ini -m shell -a "du -sh /opt/tarz-k8s/restore-in-all-nodes" -b
```

## Cleanup

Remove backup files after successful restore:
```bash
# Clean remote files
ansible all -i hosts.ini -m file -a "path=/opt/tarz-k8s/restore-in-all-nodes state=absent" -b

# Clean local files
rm -rf backups-images/
```

## Notes

- Uses `ctr` (containerd CLI) with namespace `k8s.io`
- Image names are sanitized for filenames (`/` and `:` replaced with `_`)
- Backup files are organized by hostname in local `backups-images/` directory
- All nodes receive the same backup files during copy phase
- Failed imports are reported but don't stop the restore process
- Local machine needs sufficient disk space for all images from all nodes
