# Simple borgbackup docker image with SSH

This image is based on the official [borgbackup](https://borgbackup.readthedocs.io/en/stable/) image and adds SSH
support.

## Usage

* [`docker-compose.yaml`](./docker-compose.yaml)
* [Kubernetes Deployment](./kubernetes.yaml)

## Environment Variables

* `SSH_PORT` - SSH port to listen on (default: `2222`)
* `SSH_HOST_KEY_DIR` - Directory to store host keys (default: `/etc/ssh`)