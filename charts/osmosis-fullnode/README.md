# Osmosis Fullnode Helm Chart

A Helm chart for deploying Osmosis blockchain fullnode with monitoring and sentinel capabilities.

## Overview

This chart deploys:
- Osmosis blockchain node with Cosmovisor
- Droid monitoring service
- Sentinel CronJob for automatic cleanup
- Multiple service endpoints (RPC, LCD, gRPC, P2P, Metrics)

## Installation

### Add Helm Repository

```bash
helm repo add osmosis-charts https://osmosis-labs.github.io/helm-charts
helm repo update
```

### Install Chart

```bash
# Install with default values
helm install my-osmosis-node osmosis-charts/osmosis-fullnode

# Install with custom values
helm install my-osmosis-node osmosis-charts/osmosis-fullnode -f values.yaml
```

## Configuration

### Basic Configuration

```yaml
# Image versions
images:
  osmosis:
    tag: "29.0.2"
  droid:
    tag: "0.0.4"

# Resource limits
containers:
  osmosis:
    resources:
      limits:
        memory: "32Gi"
        cpu: "4"
      requests:
        memory: "16Gi"
        cpu: "2"

# Storage
storage:
  hostPath: "/osmosis-data"

# Services
services:
  rpc:
    enabled: true
    type: LoadBalancer
    port: 26657
  lcd:
    enabled: true
    type: ClusterIP
    port: 1317
```

### Advanced Configuration

#### Multiple Nodes

```bash
# Deploy multiple nodes with different suffixes
helm install osmosis-node-0 osmosis-charts/osmosis-fullnode --set global.nameSuffix="-node-0"
helm install osmosis-node-1 osmosis-charts/osmosis-fullnode --set global.nameSuffix="-node-1"
```

#### Monitoring

```yaml
monitoring:
  enabled: true
  datadog:
    enabled: true
```

#### Sentinel Configuration

```yaml
sentinel:
  enabled: true
  schedule: "0 */6 * * *"
  config:
    maxDirSizeGb: 200
    monitorPath: "/osmosis/.osmosisd"
    argocdApp: "fullnodes"
    maxNodeRestartCount: 10
    # Enable/disable ArgoCD integration - set to false if ArgoCD is not available
    argocdEnabled: true
```

##### ArgoCD Integration

The sentinel supports optional ArgoCD integration for coordinated deployments:

- **`argocdEnabled: true`** (default): Enables ArgoCD auto-sync pause/resume during cleanup operations
- **`argocdEnabled: false`**: Disables ArgoCD integration completely

When enabled, the sentinel will:
1. Check if ArgoCD namespace and application exist
2. Install and configure ArgoCD CLI with service account authentication
3. Pause auto-sync before scaling down pods using `argocd app set --sync-policy none`
4. Resume auto-sync after cleanup using `argocd app set --sync-policy automated`
5. Continue safely if ArgoCD is not available

**Configuration options:**
- `argocdApp`: Name of the ArgoCD application to manage
- `argocdServer`: ArgoCD server endpoint (defaults to in-cluster service)
- `argocdEnabled`: Enable/disable ArgoCD integration

**Recommended settings:**
- Set `argocdEnabled: false` if ArgoCD is not installed in your cluster
- Set `argocdEnabled: true` if you want coordinated deployments with ArgoCD

```yaml
# For environments without ArgoCD
sentinel:
  config:
    argocdEnabled: false

# For environments with ArgoCD (default configuration)
sentinel:
  config:
    argocdEnabled: true
    argocdApp: "fullnodes"
    argocdServer: "argocd-server.argocd.svc.cluster.local:80"

# For external ArgoCD server
sentinel:
  config:
    argocdEnabled: true
    argocdApp: "my-osmosis-application"
    argocdServer: "argocd.example.com:443"
```

**Note:** The sentinel uses the Kubernetes service account token for authentication with ArgoCD. Ensure your ArgoCD instance is configured to accept service account authentication.

## Parameters

### Global Parameters

| Name | Description | Default |
|------|-------------|---------|
| `global.nameSuffix` | Suffix for resource names | `""` |
| `namespace` | Kubernetes namespace | `"fullnodes"` |

### Image Parameters

| Name | Description | Default |
|------|-------------|---------|
| `images.osmosis.repository` | Osmosis image repository | `"osmolabs/osmosis-cosmovisor"` |
| `images.osmosis.tag` | Osmosis image tag | `"29.0.2"` |
| `images.droid.repository` | Droid image repository | `"osmolabs/droid"` |
| `images.droid.tag` | Droid image tag | `"0.0.4"` |

### Resource Parameters

| Name | Description | Default |
|------|-------------|---------|
| `containers.osmosis.resources.limits.memory` | Memory limit | `"63Gi"` |
| `containers.osmosis.resources.limits.cpu` | CPU limit | `"8"` |
| `containers.osmosis.resources.requests.memory` | Memory request | `"24Gi"` |
| `containers.osmosis.resources.requests.cpu` | CPU request | `"2"` |

### Storage Parameters

| Name | Description | Default |
|------|-------------|---------|
| `storage.hostPath` | Host path for data | `"/tmp/osmosis-data"` |

### Service Parameters

| Name | Description | Default |
|------|-------------|---------|
| `services.rpc.enabled` | Enable RPC service | `true` |
| `services.rpc.port` | RPC service port | `26657` |
| `services.lcd.enabled` | Enable LCD service | `true` |
| `services.lcd.port` | LCD service port | `1317` |

## Troubleshooting

### Common Issues

1. **Pod stuck in Pending**: Check node resources and tolerations
2. **Sentinel not working**: Verify RBAC permissions and pod affinity
3. **Service not accessible**: Check service type and port configuration

### Useful Commands

```bash
# Check pod status
kubectl get pods -n fullnodes -l app.kubernetes.io/name=osmosis-fullnode

# Check logs
kubectl logs -n fullnodes -l app.kubernetes.io/name=osmosis-fullnode -c osmosis

# Port forward for local access
kubectl port-forward -n fullnodes svc/my-osmosis-node-rpc 26657:26657
```

## Upgrading

```bash
helm upgrade my-osmosis-node osmosis-charts/osmosis-fullnode
```

## Uninstalling

```bash
helm uninstall my-osmosis-node
```
