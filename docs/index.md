# Osmosis Helm Charts

Public Helm chart repository for Osmosis blockchain infrastructure.

## Overview

This repository contains Helm charts for deploying Osmosis blockchain infrastructure components on Kubernetes.

```kroki-mermaid
flowchart TB
    subgraph Repo ["Helm Charts Repository"]
        Charts["charts/"]
        GHPages["GitHub Pages"]
    end

    subgraph Users ["Users"]
        Helm["Helm CLI"]
        ArgoCD["ArgoCD"]
        Kustomize["Kustomize"]
    end

    subgraph Cluster ["Kubernetes Cluster"]
        Pods["Osmosis Pods"]
    end

    Charts --> GHPages
    GHPages --> Helm & ArgoCD & Kustomize
    Helm & ArgoCD & Kustomize --> Pods
```

## Available Charts

| Chart | Description | Version | App Version |
|-------|-------------|---------|-------------|
| [osmosis-fullnode](charts/osmosis-fullnode.md) | Osmosis blockchain fullnode with monitoring and sentinel | `0.2.0` | `30.0.3` |

## Quick Start

### Add Helm Repository

```bash
helm repo add osmosis-charts https://osmosis-labs.github.io/helm-charts
helm repo update
```

### Search Available Charts

```bash
helm search repo osmosis-charts
```

### Install a Chart

```bash
# Install osmosis-fullnode with default values
helm install my-osmosis-node osmosis-charts/osmosis-fullnode

# Install with custom values file
helm install my-osmosis-node osmosis-charts/osmosis-fullnode -f values.yaml

# Install specific version
helm install my-osmosis-node osmosis-charts/osmosis-fullnode --version 0.1.7
```

## Repository Structure

```
helm-charts/
├── .github/
│   └── workflows/
│       ├── lint-test.yml      # Chart linting and testing
│       └── release-chart.yml  # Automated releases
├── charts/
│   └── osmosis-fullnode/      # Osmosis fullnode chart
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-testnet.yaml
│       └── templates/
├── scripts/
│   ├── lint-charts.sh
│   └── test-charts.sh
├── docs/                      # This documentation
└── README.md
```

## Chart Features

### osmosis-fullnode

The primary chart for deploying Osmosis blockchain nodes:

- **Osmosis Node** - Full blockchain node with Cosmovisor
- **Droid Sidecar** - Health monitoring and metrics
- **SQS Sidecar** - Sidecar Query Server (optional)
- **Sentinel CronJob** - Automatic disk cleanup
- **Multiple Services** - RPC, LCD, gRPC, P2P endpoints

## Usage with Kustomize

Charts can be referenced in Kustomize configurations:

```yaml
# kustomization.yaml
helmCharts:
  - name: osmosis-fullnode
    repo: https://osmosis-labs.github.io/helm-charts
    releaseName: osmosis-fullnode-0
    namespace: osmosis-fullnodes
    version: 0.1.7
    valuesFile: values.yaml
```

## Usage with ArgoCD

Deploy charts via ArgoCD applications:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: osmosis-fullnode
  namespace: argocd
spec:
  source:
    repoURL: https://osmosis-labs.github.io/helm-charts
    chart: osmosis-fullnode
    targetRevision: 0.1.7
    helm:
      values: |
        global:
          nameSuffix: "-node-0"
  destination:
    server: https://kubernetes.default.svc
    namespace: osmosis-fullnodes
```

## Versioning

Charts follow [Semantic Versioning](https://semver.org/):

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.0.1): Bug fixes, backward compatible

### Chart Version vs App Version

| Field | Meaning |
|-------|---------|
| `version` | Helm chart version |
| `appVersion` | Osmosis/application version |

## Support

- **Documentation**: This site
- **Issues**: [GitHub Issues](https://github.com/osmosis-labs/helm-charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/osmosis-labs/helm-charts/discussions)

## Quick Links

- [Getting Started](getting-started.md) - Installation and configuration
- [osmosis-fullnode Chart](charts/osmosis-fullnode.md) - Detailed chart documentation
- [Development Guide](development.md) - Contributing to charts
