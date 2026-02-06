# osmosis-fullnode Chart

A Helm chart for deploying Osmosis blockchain fullnode with monitoring and sentinel capabilities.

## Overview

This chart deploys:

- **Osmosis Node** - Full blockchain node with Cosmovisor for automatic upgrades
- **Droid Sidecar** - Health monitoring and metrics collection
- **SQS Sidecar** - Sidecar Query Server (optional)
- **Price Monitor** - Token price monitoring (with SQS)
- **Sentinel CronJob** - Automatic disk cleanup and maintenance

```kroki-mermaid
flowchart TB
    subgraph Pod ["StatefulSet Pod"]
        Osmosis["Osmosis Container - 26656, 26657, 1317, 9090"]
        Droid["Droid Sidecar - 8080"]
        SQS["SQS Sidecar - 9092"]
        PM["Price Monitor - 8081"]
    end

    subgraph Services
        RPC["RPC Service"]
        LCD["LCD Service"]
        GRPC["gRPC Service"]
        P2P["P2P Service"]
    end

    subgraph CronJob
        Sentinel["Sentinel - Disk Cleanup"]
    end

    Osmosis --> RPC & LCD & GRPC & P2P
    Sentinel --> Pod
```

## Installation

### Add Repository

```bash
helm repo add osmosis-charts https://osmosis-labs.github.io/helm-charts
helm repo update
```

### Install Chart

```bash
# Default installation
helm install my-osmosis-node osmosis-charts/osmosis-fullnode

# With custom values
helm install my-osmosis-node osmosis-charts/osmosis-fullnode -f values.yaml

# In specific namespace
helm install my-osmosis-node osmosis-charts/osmosis-fullnode -n osmosis-nodes --create-namespace
```

## Configuration

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.nameSuffix` | Suffix appended to all resource names | `""` |
| `namespace` | Kubernetes namespace | `"fullnodes"` |

### Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `images.osmosis.repository` | Osmosis image repository | `"osmolabs/osmosis-cosmovisor"` |
| `images.osmosis.tag` | Osmosis image tag | `"30.0.3"` |
| `images.droid.repository` | Droid image repository | `"osmolabs/droid"` |
| `images.droid.tag` | Droid image tag | `"0.0.4"` |

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
  droid:
    resources:
      limits:
        cpu: "200m"
        memory: "256Mi"
      requests:
        cpu: "50m"
        memory: "64Mi"
```

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storage.hostPath` | Host path for blockchain data | `"/tmp/osmosis-data"` |

!!! warning "Production Storage"
    For production, configure a proper host path with sufficient storage (500GB+ recommended).

### Service Configuration

```yaml
services:
  rpc:
    enabled: true
    type: ClusterIP
    port: 26657
  lcd:
    enabled: true
    type: ClusterIP
    port: 1317
  grpc:
    enabled: true
    type: ClusterIP
    port: 9090
  p2p:
    enabled: true
    type: ClusterIP
    port: 26656
```

## SQS Configuration

The Sidecar Query Server (SQS) provides additional query capabilities.

### Enable SQS

```yaml
sqs:
  enabled: true
  
  container:
    image:
      repository: osmolabs/sqs
      tag: "28.3.11"
    
    resources:
      limits:
        cpu: "4"
        memory: "31Gi"
      requests:
        cpu: "100m"
        memory: "1Gi"
    
    env:
      DD_AGENT_HOST: datadog-agent.datadog.svc.cluster.local
      LOGGER_LEVEL: debug
      OSMOSIS_LCD_ENDPOINT: http://localhost:1317
      OSMOSIS_RPC_ENDPOINT: http://localhost:26657
```

### SQS Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sqs.enabled` | Enable SQS sidecar | `false` |
| `sqs.container.image.repository` | SQS image | `"osmolabs/sqs"` |
| `sqs.container.image.tag` | SQS version | `"28.3.11"` |
| `sqs.priceMonitor.enabled` | Enable price monitor | `true` (when sqs enabled) |

### SQS Config Options

```yaml
sqs:
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

## Sentinel Configuration

Sentinel is a CronJob that manages disk space and node health.

### Enable Sentinel

```yaml
sentinel:
  enabled: true
  schedule: "0 */6 * * *"  # Every 6 hours
  
  config:
    maxDirSizeGb: 200
    monitorPath: "/osmosis/.osmosisd"
    argocdApp: "fullnodes"
    maxNodeRestartCount: 10
    argocdEnabled: true
```

### Sentinel Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sentinel.enabled` | Enable sentinel CronJob | `true` |
| `sentinel.schedule` | Cron schedule | `"0 */6 * * *"` |
| `sentinel.config.maxDirSizeGb` | Max directory size before cleanup | `200` |
| `sentinel.config.argocdEnabled` | Enable ArgoCD integration | `true` |

### ArgoCD Integration

When `argocdEnabled: true`, Sentinel will:

1. Check if ArgoCD namespace and application exist
2. Pause auto-sync before scaling down pods
3. Resume auto-sync after cleanup completes
4. Continue safely if ArgoCD is not available

```yaml
# For environments without ArgoCD
sentinel:
  config:
    argocdEnabled: false

# For environments with ArgoCD
sentinel:
  config:
    argocdEnabled: true
    argocdApp: "osmosis-1-prod-fullnodes"
    argocdServer: "argocd-server.argocd.svc.cluster.local:80"
```

## Node Scheduling

### Node Selector

```yaml
nodeSelector:
  node.kubernetes.io/pool: mainnet-prod
```

### Tolerations

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "mainnet-prod"
    effect: "NoSchedule"
```

### Affinity

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node.kubernetes.io/pool
              operator: In
              values:
                - mainnet-prod
```

## Full Values Example

### Production Mainnet Node

```yaml
global:
  nameSuffix: "-node-0"

images:
  osmosis:
    repository: osmolabs/osmosis-dev-cosmovisor
    tag: "v31-cometbft-v0.38.20"
  droid:
    repository: osmolabs/droid
    tag: "0.0.4"

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

sqs:
  enabled: true
  container:
    image:
      repository: osmolabs/sqs
      tag: "28.3.11"
    resources:
      limits:
        cpu: "4"
        memory: "31Gi"
      requests:
        cpu: "100m"
        memory: "1Gi"

sentinel:
  enabled: true
  schedule: "0 */6 * * *"
  config:
    maxDirSizeGb: 200
    argocdEnabled: true
    argocdApp: "osmosis-1-prod-fullnodes"

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "mainnet-prod"
    effect: "NoSchedule"

nodeSelector:
  node.kubernetes.io/pool: mainnet-prod
```

### Testnet Node

```yaml
global:
  nameSuffix: "-testnet-0"

images:
  osmosis:
    tag: "v31-cometbft-v0.38.20"

containers:
  osmosis:
    resources:
      limits:
        cpu: "4"
        memory: "16Gi"
      requests:
        cpu: "1"
        memory: "8Gi"

storage:
  hostPath: "/var/lib/osmosis-testnet-data"

sqs:
  enabled: false

sentinel:
  enabled: true
  schedule: "0 */12 * * *"
  config:
    maxDirSizeGb: 100

nodeSelector:
  node.kubernetes.io/pool: fullnode-workers
```

## Exposed Endpoints

After deployment, the following endpoints are available:

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| RPC | 26657 | HTTP/WebSocket | Tendermint RPC |
| LCD | 1317 | HTTP | Cosmos REST API |
| gRPC | 9090 | gRPC | Cosmos gRPC |
| P2P | 26656 | TCP | Peer-to-peer networking |
| Metrics | 26660 | HTTP | Prometheus metrics |
| Droid | 8080 | HTTP | Health and monitoring |
| SQS | 9092 | HTTP | Sidecar Query Server |

## Troubleshooting

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check container status
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses}'
```

### Node Not Syncing

```bash
# Check sync status
kubectl exec <pod-name> -c osmosis -- curl -s localhost:26657/status | jq '.result.sync_info'

# Check peers
kubectl exec <pod-name> -c osmosis -- curl -s localhost:26657/net_info | jq '.result.n_peers'
```

### SQS Health Issues

```bash
# Check SQS health
kubectl exec <pod-name> -c sqs -- curl -s localhost:9092/healthcheck

# Check SQS logs
kubectl logs <pod-name> -c sqs --tail 100
```

### Sentinel Issues

```bash
# Check CronJob status
kubectl get cronjobs

# Check recent job
kubectl get jobs | grep sentinel

# Check job logs
kubectl logs job/<job-name>
```

## Upgrade Notes

### From 0.1.x to 0.2.x

- SQS configuration structure changed
- Sentinel ArgoCD integration added
- New resource defaults

Review your values.yaml before upgrading.

## Next Steps

- [Getting Started](../getting-started.md) - Installation basics
- [Development Guide](../development.md) - Contributing to the chart
