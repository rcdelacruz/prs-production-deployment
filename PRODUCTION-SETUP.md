# Production Environment Setup Guide

This guide provides a comprehensive production deployment setup for the PRS (Purchase Requisition System) application, designed for high availability, security, and scalability.

## Overview

The production environment includes all services with enterprise-grade configurations:

- **Backend API**: Node.js/Fastify application with clustering
- **Frontend**: React/Vite application served via Nginx
- **Database**: PostgreSQL with replication and backup
- **Cache**: Redis Cluster for high availability
- **Object Storage**: MinIO cluster or cloud storage integration
- **Load Balancer**: Nginx with SSL termination
- **Monitoring**: Prometheus, Grafana, Loki, AlertManager
- **Security**: SSL/TLS, secrets management, network isolation
- **Backup**: Automated database and file backups
- **Logging**: Centralized logging with retention policies

## Prerequisites

- Docker Swarm or Kubernetes cluster
- SSL certificates (Let's Encrypt or commercial)
- Domain name configured with DNS
- At least 16GB RAM and 4 CPU cores per node
- Persistent storage volumes
- Load balancer (cloud or hardware)
- Monitoring and alerting infrastructure

## Architecture Overview

```
                    [Load Balancer]
                          |
                    [Nginx Proxy]
                    /           \
            [Frontend]      [Backend API]
                              |
                        [PostgreSQL]
                        [Redis Cluster]
                        [MinIO Cluster]
```

## Quick Start

1. **Prepare the environment**:
   ```bash
   # Clone production deployment repository
   git clone https://github.com/rcdelacruz/prs-production-deployment.git
   cd prs-production-deployment
   
   # Set up secrets and certificates
   ./scripts/setup-secrets.sh --all your-domain.com
   ```

2. **Configure production environment**:
   ```bash
   # Copy and customize production configurations
   cp examples/.env.production.example .env.production
   cp examples/backend.prod.env.example backend.prod.env
   cp examples/frontend.prod.env.example frontend.prod.env
   
   # Edit configurations for your environment
   nano .env.production
   ```

3. **Deploy the stack**:
   ```bash
   # Deploy using Docker Swarm
   ./scripts/deploy-production.sh --deploy --init-db
   
   # Or deploy using Kubernetes
   kubectl apply -f k8s/
   ```

4. **Verify deployment**:
   ```bash
   # Check service health
   ./scripts/deploy-production.sh --health-check
   
   # View monitoring dashboards
   # https://monitoring.your-domain.com
   ```

## Configuration

See the `examples/` directory for sample configuration files:

- `.env.production.example` - Main environment variables
- `backend.prod.env.example` - Backend application configuration
- `frontend.prod.env.example` - Frontend application configuration

## Deployment Options

### Docker Swarm Deployment

Use the Docker Compose files in the `compose/` directory for Docker Swarm deployment.

### Kubernetes Deployment

Use the manifests in the `k8s/` directory for Kubernetes deployment.

## Monitoring

The production setup includes a complete monitoring stack:

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation and search
- **AlertManager**: Alert routing and notifications

Access monitoring at `https://monitoring.your-domain.com`

## Security

Production security features:

- SSL/TLS encryption with automatic certificate renewal
- Docker secrets management for sensitive data
- Network segmentation and firewall rules
- Security headers (CSP, HSTS, XSS protection)
- Rate limiting and DDoS protection
- Regular security updates and patches

## Backup and Recovery

Automated backup features:

- Daily encrypted database backups
- File system and configuration backups
- Cloud storage integration (S3)
- Point-in-time recovery capabilities
- Disaster recovery procedures

## Scaling

The setup supports horizontal scaling:

- Backend API: Scale replicas based on load
- Frontend: Multiple replicas behind load balancer
- Database: Primary/replica setup with read scaling
- Cache: Redis clustering for high availability
- Storage: Distributed MinIO cluster

## Maintenance

Regular maintenance procedures:

- Daily health checks and monitoring review
- Weekly security patches and updates
- Monthly performance optimization
- Quarterly disaster recovery testing

## Troubleshooting

Common issues and solutions:

1. **Service Health Issues**: Check logs and resource usage
2. **Database Connectivity**: Verify network and credentials
3. **SSL Certificate Issues**: Check certificate expiration
4. **Performance Issues**: Review metrics and scaling

For detailed troubleshooting, see the monitoring dashboards and logs.

## Support

For support and questions:

1. Check the documentation and examples
2. Review monitoring dashboards for issues
3. Create an issue in this repository
4. Contact the development team

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
