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
  runs-on: any
  namespace: ns
  pvc: name-of-the-ovc
  exclude_patterns:
    - /things-to-exclude
db-example:
  type: mariadb
  runs-on: server.example
  namespace: ns
  instanceName: this-instance   # see label app.kubernetes.io/instance:

postgresql-example:
  type: postgresql
  namespace: ns
  instanceName: this-instance
  # Optional. Defaults to <instanceName>-postgresql.<namespace>.svc.cluster.local.
  hostname: postgres.ns.svc.cluster.local

node-files:
  type: fs
  runs-on: all
  source_directories:
    - /node-state
```

### Source placement

Each source supports `runs-on: any|<node-name>|all`:

- `any` (default): local PVC sources follow their PV's hostname affinity.
  Other sources use `RUNS_ON_ANY_NODE` when set, otherwise the current node.
- `<node-name>`: generate this source only on the named node. A PVC must also
  belong to that node; conflicting placement fails initialization.
- `all`: generate the source on every node. Useful for node-local filesystem
  paths. A PVC path must exist on every node where it is backed up.

Set `K8S_NODE_NAME` in the init container using the Downward API:

```yaml
env:
  - name: K8S_NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
```

Pin shared network database dumps to one node with `runs-on: <node-name>`, or
set `RUNS_ON_ANY_NODE` to the same designated node in every backup pod.
`any` does not elect a leader: without that setting, non-PVC sources run in
each invoking pod. Without node information, the default `any` preserves the
previous single-node behavior.

Set `BORGMATIC_INIT_ALL_NODES=true` for an exporter or repository-check init
container to generate every configured source without filtering. Named and
automatically located PVC sources retain their owner's archive hostname.
For `all` sources, catalog configs match archives from every hostname; normal
backup configs retain per-node pruning. Missing PVCs, missing local PV paths,
and ambiguous PVC ownership fail initialization.

## Usage:

 * args: `server|borgmatic-init`
    * `server`: to start the SSH server
    * `borgmatic-init`: to create config yamls for borgmatic
 * env:
   * `SSH_PORT` - SSH port to listen on (default: `2222`)
   * `SSH_HOST_KEY_DIR` - Directory to store host keys (default: `/etc/ssh/keys`)
   * `K8S_NODE_NAME` - Current backup node; provide this to enable PVC routing.
   * `RUNS_ON_ANY_NODE` - Optional designated node for non-PVC `any` sources.
   * `BORGMATIC_INIT_ALL_NODES` - Generate the full catalog for monitoring/checks (default: `false`).
