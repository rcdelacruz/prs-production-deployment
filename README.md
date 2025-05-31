# PRS Production Deployment

Production deployment configuration and setup guide for PRS (Purchase Requisition System)

## Quick Start

1. **Clone this repository**:
   ```bash
   git clone https://github.com/rcdelacruz/prs-production-deployment.git
   cd prs-production-deployment
   ```

2. **Set up secrets and SSL**:
   ```bash
   ./scripts/setup-secrets.sh --all your-domain.com
   ```

3. **Deploy the production stack**:
   ```bash
   ./scripts/deploy-production.sh --deploy --init-db
   ```

4. **Verify deployment**:
   ```bash
   ./scripts/deploy-production.sh --health-check
   ```

## Documentation

See [PRODUCTION-SETUP.md](./PRODUCTION-SETUP.md) for the complete production deployment guide.

## Directory Structure

```
production/
├── compose/                     # Docker Compose files
├── k8s/                        # Kubernetes manifests
├── nginx/                      # Nginx configurations
├── monitoring/                 # Monitoring stack configs
├── scripts/                    # Deployment scripts
├── security/                   # Security configurations
└── examples/                   # Example configurations
```

## Features

- **High Availability**: Multi-replica services with load balancing
- **Security**: SSL/TLS, secrets management, security headers
- **Monitoring**: Prometheus, Grafana, Loki, AlertManager
- **Backup**: Automated encrypted backups with cloud storage
- **Scalability**: Docker Swarm and Kubernetes support
- **Performance**: Caching, compression, resource optimization

## Requirements

- Docker Swarm or Kubernetes cluster
- SSL certificates (Let's Encrypt or commercial)
- Domain name with DNS configuration
- Minimum 16GB RAM and 4 CPU cores per node
- Persistent storage volumes

## Support

For issues and questions, please create an issue in this repository.

## License

MIT License - see [LICENSE](./LICENSE) file for details.
