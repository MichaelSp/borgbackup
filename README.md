# Simple borgbackup docker image with SSH

This image is based on the official [borgbackup](https://borgbackup.readthedocs.io/en/stable/) image and adds SSH
support.

## Usage

* [`docker-compose.yaml`](./docker-compose.yaml)
* [Kubernetes Destination](./kubernetes-destination.yaml)
* [Kubernetes Source](./kubernetes-source.yaml)

Make sure to store a backup of the repo-key created in `${BORG_SECURITY_DIR}/repokey` after the first run.

## Configuration 

Configuration via `BACKUP_CONFIG_YAML` file:

```yaml
backup-from-dir:
  schedule: "0 0 * * *"
  source: "/source"
  keep: 7d
backup-from-pvc:
  schedule: "0 0 * * *"
  type: pvc
  source: "namespace/pvc"
backup-from-db-dump:
  type: mariadb
  namespace: "namespace"
  helmReleaseName: "helm-release-name"
backup-from-db-pqsql:
  type: postgresql
  namespace: "namespace"
  helmReleaseName: "helm-pg-release-name" 
```

The databases are found using this label filter:

`app.kubernetes.io/name=mariadb,app.kubernetes.io/instance=${helmReleaseName},app.kubernetes.io/component=primary`

## Environment Variables

  * `DEFAULT_KEEP` - Default keep policy (default: `7d`)
  * `DEFAULT_SCHEDULE` - Default schedule (default: `0 0 * * *`)
  * `DEFAULT_COMPRESSION` - Default compression (default: `lz4`)
  * `BACKUP_CONFIG_YAML` - Path to the backup configuration file (default: `/etc/backup/config.yaml`)
  * `SSH_PORT` - SSH port to listen on (default: `2222`)
  * `SSH_HOST_KEY_DIR` - Directory to store host keys (default: `/etc/ssh/keys`)
  * `BORG_REPO` - Borg repository to back up to (default: `/backup`)
  * `BORG_SECURITY_DIR` - Directory to store security files (default: `""`)
  * `BORG_PASSPHRASE` - Passphrase to encrypt the repository
