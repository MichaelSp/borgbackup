# Simple borgbackup docker image with SSH

This image is based on the official [borgbackup](https://borgbackup.readthedocs.io/en/stable/) image and adds SSH
support.

## Usage

* [`docker-compose.yaml`](./docker-compose.yaml)
* [Kubernetes Destination](./kubernetes-destination.yaml)
* [Kubernetes Source](./kubernetes-source.yaml)

Make sure to store a backup of the repo-key created in `${BORG_SECURITY_DIR}/repokey` after the first run.

## Environment Variables

* `SSH_PORT` - SSH port to listen on (default: `2222`)
* `SSH_HOST_KEY_DIR` - Directory to store host keys (default: `/etc/ssh`)
* `BORG_REPO` - Borg repository to backup to (default: `/backup`)
* `BORG_SECURITY_DIR` - Directory to store security files (default: `/etc/borg`)
* `BORG_PASSPHRASE` - Passphrase to encrypt the repository)
* `DEFAULT_KEEP` - Default keep policy (default: `7`)
