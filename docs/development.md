# Development Guide

This guide covers how to contribute to the Osmosis Helm charts repository.

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Helm | >= 3.8 | Chart development and testing |
| kubectl | >= 1.19 | Kubernetes testing |
| ct (chart-testing) | Latest | Chart linting and testing |
| yamllint | Latest | YAML validation |

### Installation

```bash
# macOS with Homebrew
brew install helm kubectl chart-testing yamllint

# Verify installations
helm version
ct version
```

## Repository Structure

```
helm-charts/
├── .github/
│   └── workflows/
│       ├── lint-test.yml      # PR validation
│       └── release-chart.yml  # Release automation
├── charts/
│   └── osmosis-fullnode/      # Chart directory
│       ├── Chart.yaml         # Chart metadata
│       ├── values.yaml        # Default values
│       ├── values-testnet.yaml
│       ├── .helmignore
│       ├── README.md
│       └── templates/
│           ├── _helpers.tpl
│           ├── statefulset.yaml
│           ├── services.yaml
│           ├── configmaps.yaml
│           ├── cronjob.yaml
│           ├── rbac.yaml
│           ├── sqs-configmaps.yaml
│           └── sqs-services.yaml
├── scripts/
│   ├── lint-charts.sh
│   └── test-charts.sh
└── docs/
```

## Creating a New Chart

### 1. Create Chart Directory

```bash
mkdir -p charts/my-new-chart
helm create charts/my-new-chart
```

### 2. Configure Chart.yaml

```yaml
# charts/my-new-chart/Chart.yaml
apiVersion: v2
name: my-new-chart
description: A Helm chart for deploying my service
type: application
version: 0.1.0
appVersion: "1.0.0"

keywords:
  - osmosis
  - blockchain

home: https://github.com/osmosis-labs/helm-charts
sources:
  - https://github.com/osmosis-labs/helm-charts

maintainers:
  - name: Osmosis Labs
    url: https://app.osmosis.zone
    email: devops@osmosis.zone
```

### 3. Configure Default Values

```yaml
# charts/my-new-chart/values.yaml
global:
  nameSuffix: ""

image:
  repository: myorg/myimage
  tag: "1.0.0"
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: "1"
    memory: "1Gi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

### 4. Create Templates

Follow Helm best practices:

```yaml
# charts/my-new-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-new-chart.fullname" . }}
  labels:
    {{- include "my-new-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-new-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-new-chart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

## Chart Guidelines

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Chart name | `osmosis-{component}` | `osmosis-fullnode` |
| Resource names | Use chart name prefix | `{{ include "chart.fullname" . }}` |
| Labels | Kubernetes recommended | `app.kubernetes.io/name` |

### Required Labels

```yaml
labels:
  app.kubernetes.io/name: {{ include "chart.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  helm.sh/chart: {{ include "chart.chart" . }}
```

### Value Schema

- Use nested structures for related values
- Provide sensible defaults
- Document all values in README

```yaml
# Good
containers:
  osmosis:
    resources:
      limits:
        cpu: "8"
        memory: "64Gi"

# Avoid
osmosis_cpu_limit: "8"
osmosis_memory_limit: "64Gi"
```

## Testing Charts

### Lint Charts

```bash
# Lint all charts
./scripts/lint-charts.sh

# Lint specific chart
helm lint charts/osmosis-fullnode/

# Using chart-testing
ct lint --charts charts/osmosis-fullnode
```

### Template Charts

```bash
# Generate templates
helm template my-release charts/osmosis-fullnode/

# With custom values
helm template my-release charts/osmosis-fullnode/ -f values-test.yaml

# Validate output
helm template my-release charts/osmosis-fullnode/ | kubectl apply --dry-run=client -f -
```

### Dry-Run Installation

```bash
helm install test-release charts/osmosis-fullnode/ --dry-run --debug
```

### Local Testing

```bash
# Install chart
helm install test-release charts/osmosis-fullnode/ -n test --create-namespace

# Check status
kubectl get all -n test

# Uninstall
helm uninstall test-release -n test
```

## Version Management

### Chart Version

Increment for any chart changes:

```yaml
# Chart.yaml
version: 0.1.0  # Chart version
```

| Change Type | Version Bump |
|-------------|--------------|
| Breaking changes | Major (1.0.0) |
| New features | Minor (0.1.0) |
| Bug fixes | Patch (0.0.1) |

### App Version

Reflects the application version:

```yaml
# Chart.yaml
appVersion: "30.0.3"  # Osmosis version
```

## Release Process

### Automated Releases

Charts are automatically released when you push a tag:

```bash
# Create and push tag
git tag osmosis-fullnode-0.1.8
git push origin osmosis-fullnode-0.1.8
```

The GitHub Actions workflow will:

1. Package the chart
2. Update the Helm repository index
3. Publish to GitHub Pages

### Manual Testing (Workflow Dispatch)

1. Go to **Actions** > **Release Helm Chart**
2. Click **Run workflow**
3. Configure:
   - Chart name: `osmosis-fullnode`
   - Version: `0.1.8-test`
   - Dry run: `true`

### Tag Naming Convention

```
{chart-name}-{version}
```

Examples:
- `osmosis-fullnode-0.1.8`
- `osmosis-sqs-1.0.0`

## Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Chart passes `helm lint`
- [ ] Chart passes `helm template`
- [ ] All values documented in README
- [ ] Chart.yaml version incremented
- [ ] appVersion updated if application changed
- [ ] CHANGELOG updated (if applicable)
- [ ] Tests pass locally

## CI/CD Workflows

### lint-test.yml

Runs on every PR:

```yaml
name: Lint and Test Charts
on:
  pull_request:
    paths:
      - 'charts/**'
jobs:
  lint-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: azure/setup-helm@v3
      - name: Lint charts
        run: ./scripts/lint-charts.sh
```

### release-chart.yml

Runs on tag push:

```yaml
name: Release Helm Chart
on:
  push:
    tags:
      - '*-*.*.*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Package and publish chart
        run: |
          helm package charts/$CHART_NAME
          # Update index and publish
```

## Common Patterns

### Optional Components

```yaml
{{- if .Values.sqs.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "chart.fullname" . }}-sqs-config
data:
  # SQS configuration
{{- end }}
```

### Conditional Resources

```yaml
{{- if .Values.sentinel.enabled }}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "chart.fullname" . }}-sentinel
spec:
  schedule: {{ .Values.sentinel.schedule | quote }}
{{- end }}
```

### Multiple Containers

```yaml
containers:
  - name: main
    image: "{{ .Values.images.main.repository }}:{{ .Values.images.main.tag }}"
  {{- if .Values.sidecar.enabled }}
  - name: sidecar
    image: "{{ .Values.images.sidecar.repository }}:{{ .Values.images.sidecar.tag }}"
  {{- end }}
```

## Troubleshooting Development

### Template Errors

```bash
# Debug template rendering
helm template my-release charts/my-chart/ --debug

# Check specific value
helm template my-release charts/my-chart/ --set key=value --debug
```

### Schema Validation

```bash
# Validate values against schema
helm lint charts/my-chart/ --strict
```

### Dependency Issues

```bash
# Update dependencies
helm dependency update charts/my-chart/

# List dependencies
helm dependency list charts/my-chart/
```

## Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Chart Testing](https://github.com/helm/chart-testing)
- [Kubernetes Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)

## Next Steps

- [Getting Started](getting-started.md) - Using the charts
- [osmosis-fullnode Chart](charts/osmosis-fullnode.md) - Chart reference
