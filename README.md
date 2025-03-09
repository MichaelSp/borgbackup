# Simple borgbackup docker image with SSH and init logic for borgmatic.

This image is based on the official [borgbackup](https://borgbackup.readthedocs.io/en/stable/) image and adds SSH
support.

## Configuration
Configuration via `${SOURCES_YAML:-./sources.yaml}`:

```
crontabs: # generic crontab configuration (not a backup source)
  - name: default
    schedule: "17 17 * * *"
    command: PATH=$PATH:/usr/local/bin /usr/local/bin/borgmatic --stats -v 0 2>&1
backup-of-PVC:
  namespace: ns
  pvc: name-of-the-ovc
  exclude_patterns:
    - /things-to-exclude
db-example
  type: mariadb
  namespace: ns
  instanceName: this-instance   # see label app.kubernetes.io/instance:
```

## Usage:

 * args: `server|borgmatic-init`
    * `server`: to start the SSH server
    * `borgmatic-init`: to create config yamls for borgmatic
 * env:
   * `SSH_PORT` - SSH port to listen on (default: `2222`)
   * `SSH_HOST_KEY_DIR` - Directory to store host keys (default: `/etc/ssh/keys`)