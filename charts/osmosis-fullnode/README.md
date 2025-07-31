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

#### SQS Configuration

The chart supports deploying SQS (Sidecar Query Service) as sidecar containers when enabled. SQS provides additional query capabilities and price monitoring for the Osmosis blockchain.

```yaml
sqs:
  enabled: true  # Set to true to enable SQS containers
  
  # SQS container configuration
  container:
    image:
      repository: osmolabs/sqs
      tag: "28.3.11"
    
    # Resource limits and requests
    resources:
      limits:
        cpu: 4
        memory: 31Gi
      requests:
        cpu: 100m
        memory: 1Gi
    
    # Environment variables (customize as needed)
    env:
      DD_AGENT_HOST: datadog-agent.datadog.svc.cluster.local
      LOGGER_LEVEL: debug
      OSMOSIS_KEYRING_KEY_NAME: local.info
      OSMOSIS_KEYRING_PASSWORD: test
      OSMOSIS_KEYRING_PATH: /osmosis/.osmosisd/keyring-test
      OSMOSIS_LCD_ENDPOINT: http://osmosis-fullnode-0-node-0-lcd.osmosis-1-prod-fullnodes:1317
      OSMOSIS_RPC_ENDPOINT: http://osmosis-fullnode-0-node-0-rpc.osmosis-1-prod-fullnodes:26657
      OTEL_EXPORTER_OTLP_ENDPOINT: http://datadog-agent.datadog.svc.cluster.local:4317
      SQS_GRPC_GATEWAY_ENDPOINT: osmosis-fullnode-0-node-0-grpc.osmosis-1-prod-fullnodes:9090
      SQS_GRPC_INGESTER_MAX_RECEIVE_MSG_SIZE_BYTES: "20971520"
      SQS_GRPC_TENDERMINT_RPC_ENDPOINT: http://osmosis-fullnode-0-node-0-rpc.osmosis-1-prod-fullnodes:26657
      SQS_ROUTER_ROUTE_CACHE_ENABLED: "false"
      SQS_SKIP_CHAIN_AVAILABILITY_CHECK: "true"
  
  # Price monitor container configuration
  priceMonitor:
    image:
      repository: osmolabs/price-monitor
      tag: "main-89f39d74"
    
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 100m
        memory: 128Mi
  
  # SQS configuration
  config:
    flightRecord:
      enabled: false
    otel:
      enabled: false
      environment: prod
    grpcIngester:
      plugins:
        - name: orderbook-fillbot-plugin
          enabled: false
        - name: orderbook-claimbot-plugin
          enabled: false
        - name: orderbook-orders-cache-plugin
          enabled: true
```

When SQS is enabled, the following additional resources are created:
- **SQS Container**: Main SQS service container
- **Price Monitor Container**: Price monitoring sidecar
- **ConfigMaps**: Environment variables and configuration
- **Services**: SQS and gRPC ingest services
- **Pod Affinity**: Ensures SQS runs on the same node as the Osmosis fullnode

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

### SQS Parameters

| Name | Description | Default |
|------|-------------|---------|
| `sqs.enabled` | Enable SQS sidecar containers | `false` |
| `sqs.container.image.repository` | SQS image repository | `"osmolabs/sqs"` |
| `sqs.container.image.tag` | SQS image tag | `"28.3.11"` |
| `sqs.container.resources.limits.memory` | SQS memory limit | `"31Gi"` |
| `sqs.container.resources.limits.cpu` | SQS CPU limit | `"4"` |
| `sqs.priceMonitor.image.repository` | Price monitor image repository | `"osmolabs/price-monitor"` |
| `sqs.priceMonitor.image.tag` | Price monitor image tag | `"main-89f39d74"` |

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
