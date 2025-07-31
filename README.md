# Osmosis Helm Charts

Public repository for Osmosis blockchain infrastructure Helm charts.

## Available Charts

| Chart | Description | Version | App Version |
|-------|-------------|---------|-------------|
| [osmosis-fullnode](./charts/osmosis-fullnode) | Osmosis blockchain fullnode with monitoring | `0.1.7` | `29.0.2` |

## Quick Start

### Add Helm Repository

```bash
helm repo add osmosis-charts [repo_url]
helm repo update
```

### Install a Chart

```bash
# Install osmosis-fullnode
helm install my-osmosis-node osmosis-charts/osmosis-fullnode

# Install with custom values
helm install my-osmosis-node osmosis-charts/osmosis-fullnode -f values.yaml

# Install specific version
helm install my-osmosis-node osmosis-charts/osmosis-fullnode --version 0.1.0
```

## Development

### Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) 3.8+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) 1.19+

### Adding New Charts

1. Create new chart directory:
   ```bash
   mkdir -p charts/my-new-chart
   helm create charts/my-new-chart
   ```

2. Follow the [Chart Guidelines](./docs/CHART_GUIDELINES.md)

3. Test your chart:
   ```bash
   # Lint
   helm lint charts/my-new-chart/
   
   # Template
   helm template charts/my-new-chart/
   
   # Install locally
   helm install test-release charts/my-new-chart/ --dry-run
   ```

### Testing Charts

```bash
# Lint all charts
./scripts/lint-charts.sh

# Test all charts
./scripts/test-charts.sh

```

## Release Process

### Automated Releases

Charts are automatically released when you push a tag:

```bash
# Release osmosis-fullnode v1.0.0
git tag chart-osmosis-fullnode-v1.0.0
git push origin chart-osmosis-fullnode-v1.0.0
```

### Manual Testing

Use the GitHub Actions workflow dispatch to test releases:

1. Go to **Actions** → **Release Helm Chart**
2. Click **"Run workflow"**
3. Fill in:
   - **Chart name**: `osmosis-fullnode`
   - **Version**: `1.0.0-test`
   - **Dry run**: `true` (for testing)

## Chart Guidelines

### Naming Conventions

- Chart names: `osmosis-{component}` (e.g., `osmosis-fullnode`, `osmosis-sqs`)
- Resource names: Use chart name as prefix
- Labels: Follow [Kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)

### Version Management

- **Chart version**: Semantic versioning (e.g., `1.0.0`)
- **App version**: Application version (e.g., `29.0.2`)
- Update both in `Chart.yaml`

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-chart`)
3. Add/modify charts
4. Test thoroughly
5. Submit pull request

### Pull Request Checklist

- [ ] Chart passes `helm lint`
- [ ] Chart passes `helm template`
- [ ] README.md updated
- [ ] Tests added/updated

## Support

- **Documentation**: [charts/*/README.md](./charts/)
- **Issues**: [GitHub Issues](https://github.com/osmosis-labs/helm-charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/osmosis-labs/helm-charts/discussions)
