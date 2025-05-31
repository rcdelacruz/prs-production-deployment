# Configuration Templates for PRS Single Node

This directory contains configuration templates and examples for the PRS single node deployment.

## Directory Structure

```
config/
├── README.md                           # This file
├── grafana/                            # Grafana monitoring configuration
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml          # Prometheus datasource configuration
│   │   └── dashboards/
│   │       └── dashboard.yml           # Dashboard provisioning configuration
│   └── dashboards/
│       └── prs-single-node-overview.json  # Pre-built PRS dashboard
├── postgres/
│   └── README.md                       # PostgreSQL SSL certificate documentation
└── prometheus/
    └── prometheus.yml.template         # Prometheus monitoring configuration template
```

## Usage

These configuration files are automatically used by the deployment script (`scripts/deploy.sh`) during the setup process. You typically don't need to modify them unless you want to customize the monitoring or add additional services.

### Automatic Configuration

The deployment script automatically:

1. **Copies configuration templates** to the appropriate locations
2. **Generates SSL certificates** for PostgreSQL
3. **Sets up Grafana provisioning** with datasources and dashboards
4. **Configures Prometheus** with appropriate scrape targets

### Manual Customization

If you want to customize the configuration:

1. **Prometheus Monitoring**: Edit `prometheus/prometheus.yml.template` to add custom scrape targets or adjust intervals
2. **Grafana Dashboards**: Modify `grafana/dashboards/prs-single-node-overview.json` or add new dashboard files
3. **PostgreSQL SSL**: Follow instructions in `postgres/README.md` for custom SSL certificates

## Configuration Files Overview

### Prometheus Configuration (`prometheus/prometheus.yml.template`)

- **Purpose**: Defines monitoring targets and data collection settings
- **Targets**: PRS Backend, Node Exporter, cAdvisor, PostgreSQL (optional)
- **Intervals**: Optimized for single-node deployment
- **Usage**: Automatically copied to container during deployment

### Grafana Configuration

#### Datasources (`grafana/provisioning/datasources/prometheus.yml`)
- **Purpose**: Automatically configures Prometheus as the default datasource
- **Connection**: Points to the local Prometheus container
- **Settings**: Optimized query timeout and HTTP method

#### Dashboard Provisioning (`grafana/provisioning/dashboards/dashboard.yml`)
- **Purpose**: Automatically loads dashboard files from the dashboards directory
- **Auto-update**: Monitors dashboard files for changes
- **User-editable**: Allows modifications through Grafana UI

#### Default Dashboard (`grafana/dashboards/prs-single-node-overview.json`)
- **Purpose**: Provides immediate visibility into system and application metrics
- **Panels**: 
  - PRS Backend Status (service availability)
  - CPU Usage (system performance)
  - Memory Usage (resource utilization)
  - API Request Rate (application metrics)
  - Disk Usage (storage monitoring)
- **Time Range**: Last 1 hour with 30-second refresh

### PostgreSQL SSL Configuration (`postgres/README.md`)

- **Purpose**: Documentation for SSL certificate management
- **Auto-generation**: Certificates created automatically during deployment
- **Security**: Enables encrypted database connections
- **Manual Setup**: Instructions for custom certificate deployment

## Integration with Deployment

These configurations integrate seamlessly with the single-node deployment:

### Docker Compose Integration

```yaml
# Prometheus configuration mounted from config directory
prometheus:
  volumes:
    - ./config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro

# Grafana provisioning and dashboards
grafana:
  volumes:
    - ./config/grafana/provisioning:/etc/grafana/provisioning:ro
    - ./config/grafana/dashboards:/var/lib/grafana/dashboards:ro

# PostgreSQL SSL certificates
postgres:
  volumes:
    - ./config/postgres/server.crt:/var/lib/postgresql/server.crt:ro
    - ./config/postgres/server.key:/var/lib/postgresql/server.key:ro
```

### Deployment Script Integration

The `scripts/deploy.sh` script:

1. **Validates** configuration templates exist
2. **Generates** SSL certificates for PostgreSQL
3. **Copies** Prometheus configuration to runtime location
4. **Mounts** Grafana configurations into containers
5. **Verifies** monitoring services are accessible

## Monitoring Access

Once deployed, access monitoring services at:

- **Main Application**: `https://your-server/`
- **Grafana Dashboard**: `https://your-server/grafana/`
- **Prometheus Metrics**: `https://your-server/prometheus/` (admin access required)

### Default Grafana Credentials

- **Username**: `admin`
- **Password**: Value from `GRAFANA_ADMIN_PASSWORD` in `.env` file
- **Dashboard**: "PRS Single Node Overview" available immediately

## Customization Examples

### Adding Custom Prometheus Targets

Edit `prometheus/prometheus.yml.template`:

```yaml
scrape_configs:
  # Add your custom service
  - job_name: 'custom-service'
    static_configs:
      - targets: ['custom-service:8080']
    scrape_interval: 30s
```

### Creating Custom Grafana Dashboards

1. **Design in UI**: Create dashboard in Grafana interface
2. **Export JSON**: Use Grafana export feature
3. **Save File**: Place in `config/grafana/dashboards/`
4. **Auto-load**: Dashboard appears automatically on next restart

### Modifying PostgreSQL SSL

Follow instructions in `config/postgres/README.md` to:
- Generate custom certificates
- Use certificates from internal CA
- Configure for production security requirements

## Troubleshooting

### Configuration Not Loading

1. **Check file paths** in docker-compose.yml
2. **Verify permissions** on configuration files
3. **Review container logs** for configuration errors

### Monitoring Not Working

1. **Validate Prometheus targets** at `/prometheus/targets`
2. **Check Grafana datasource** connectivity
3. **Verify network connectivity** between containers

### SSL Certificate Issues

1. **Check certificate validity**: `openssl x509 -in config/postgres/server.crt -text -noout`
2. **Verify file permissions**: Certificates should be readable by PostgreSQL user
3. **Review deployment logs** for certificate generation errors

## Support

For configuration issues:

1. **Check deployment logs**: `./scripts/deploy.sh logs`
2. **Validate setup**: `./scripts/validate-setup.sh`
3. **Review documentation**: Each subdirectory contains specific README files
4. **Test connectivity**: Use container health checks and monitoring endpoints

This configuration setup provides a robust foundation for monitoring and managing your PRS single-node deployment.
