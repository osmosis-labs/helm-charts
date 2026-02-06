# Getting Started

This guide covers how to install and use Osmosis Helm charts.

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Helm | >= 3.8 | Helm chart management |
| kubectl | >= 1.19 | Kubernetes cluster management |

### Installation

```bash
# macOS with Homebrew
brew install helm kubectl

# Verify installations
helm version
kubectl version --client
```

## Adding the Repository

Add the Osmosis Helm charts repository:

```bash
helm repo add osmosis-charts https://osmosis-labs.github.io/helm-charts
helm repo update
```

Verify the repository was added:

```bash
helm repo list
helm search repo osmosis-charts
```

## Installing Charts

### Basic Installation

```bash
# Install osmosis-fullnode with default values
helm install my-osmosis-node osmosis-charts/osmosis-fullnode

# Install in a specific namespace
helm install my-osmosis-node osmosis-charts/osmosis-fullnode -n osmosis-nodes --create-namespace
```

### Installation with Custom Values

Create a `values.yaml` file:

```yaml
# values.yaml
global:
  nameSuffix: "-node-0"

images:
  osmosis:
    tag: "v31-cometbft-v0.38.20"

containers:
  osmosis:
    resources:
      limits:
        cpu: "6"
        memory: "32Gi"
      requests:
        cpu: "2"
        memory: "16Gi"

storage:
  hostPath: "/var/lib/osmosis-data"
```

Install with custom values:

```bash
helm install my-osmosis-node osmosis-charts/osmosis-fullnode -f values.yaml
```

### Installation with Specific Version

```bash
# List available versions
helm search repo osmosis-charts/osmosis-fullnode --versions

# Install specific version
helm install my-osmosis-node osmosis-charts/osmosis-fullnode --version 0.1.7
```

### Dry-Run Installation

Preview what will be installed:

```bash
helm install my-osmosis-node osmosis-charts/osmosis-fullnode --dry-run
```

## Configuration Overview

### Essential Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.nameSuffix` | Suffix for resource names | `""` |
| `images.osmosis.tag` | Osmosis image version | `"30.0.3"` |
| `storage.hostPath` | Data storage path | `"/tmp/osmosis-data"` |
| `sqs.enabled` | Enable SQS sidecar | `false` |

### Resource Configuration

```yaml
containers:
  osmosis:
    resources:
      limits:
        cpu: "8"
        memory: "64Gi"
      requests:
        cpu: "2"
        memory: "16Gi"
```

### Node Scheduling

```yaml
nodeSelector:
  node.kubernetes.io/pool: mainnet-prod

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "mainnet-prod"
    effect: "NoSchedule"
```

## Verifying Installation

### Check Pod Status

```bash
# List pods
kubectl get pods -l app.kubernetes.io/name=osmosis-fullnode

# Describe pod
kubectl describe pod <pod-name>
```

### Check Services

```bash
kubectl get svc -l app.kubernetes.io/name=osmosis-fullnode
```

### Check Logs

```bash
kubectl logs -l app.kubernetes.io/name=osmosis-fullnode -c osmosis --tail 100
```

### Verify Node Sync

```bash
kubectl exec <pod-name> -c osmosis -- curl -s localhost:26657/status | jq '.result.sync_info'
```

## Upgrading Charts

### Upgrade to Latest Version

```bash
# Update repository
helm repo update

# Upgrade release
helm upgrade my-osmosis-node osmosis-charts/osmosis-fullnode
```

### Upgrade with New Values

```bash
helm upgrade my-osmosis-node osmosis-charts/osmosis-fullnode -f values.yaml
```

### Upgrade to Specific Version

```bash
helm upgrade my-osmosis-node osmosis-charts/osmosis-fullnode --version 0.1.8
```

### Rollback

```bash
# List revision history
helm history my-osmosis-node

# Rollback to previous revision
helm rollback my-osmosis-node 1
```

## Uninstalling Charts

```bash
# Uninstall release
helm uninstall my-osmosis-node

# Uninstall and keep history
helm uninstall my-osmosis-node --keep-history
```

!!! warning "Data Persistence"
    Uninstalling the chart does not delete data stored on the host path. Manual cleanup may be required.

## Common Use Cases

### Multiple Nodes

Deploy multiple nodes with different suffixes:

```bash
helm install osmosis-node-0 osmosis-charts/osmosis-fullnode --set global.nameSuffix="-node-0"
helm install osmosis-node-1 osmosis-charts/osmosis-fullnode --set global.nameSuffix="-node-1"
helm install osmosis-node-2 osmosis-charts/osmosis-fullnode --set global.nameSuffix="-node-2"
```

### Testnet vs Mainnet

Use different values files:

```bash
# Mainnet
helm install mainnet-node osmosis-charts/osmosis-fullnode -f values-mainnet.yaml

# Testnet
helm install testnet-node osmosis-charts/osmosis-fullnode -f values-testnet.yaml
```

### With SQS Enabled

```yaml
# values-with-sqs.yaml
sqs:
  enabled: true
  container:
    image:
      repository: osmolabs/sqs
      tag: "28.3.11"
```

```bash
helm install osmosis-sqs osmosis-charts/osmosis-fullnode -f values-with-sqs.yaml
```

## Troubleshooting

### Chart Not Found

```bash
# Update repositories
helm repo update

# Verify repository
helm repo list
```

### Values Not Applied

```bash
# Check computed values
helm get values my-osmosis-node

# Check all values
helm get values my-osmosis-node --all
```

### Pod Not Starting

```bash
# Check events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name> -c osmosis --previous
```

## Next Steps

- [osmosis-fullnode Chart](charts/osmosis-fullnode.md) - Detailed chart documentation
- [Development Guide](development.md) - Contributing to charts
