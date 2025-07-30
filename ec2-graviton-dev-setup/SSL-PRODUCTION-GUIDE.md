# SSL-Enabled Production Deployment Guide

This guide covers the elegant SSL-enabled production setup for the PRS application on EC2 Graviton instances.

## Overview

The production deployment now supports proper SSL configuration for both PostgreSQL and the application layer, eliminating the need for hardcoded `DISABLE_SSL=true` workarounds.

## Key Features

✅ **Environment-driven SSL configuration**  
✅ **Automatic SSL certificate generation**  
✅ **PostgreSQL SSL support**  
✅ **Validation scripts**  
✅ **Production-ready security**  

## SSL Configuration

### Backend SSL Settings

The backend now intelligently handles SSL based on environment variables:

```bash
# Enable SSL for production
POSTGRES_SSL_ENABLED=true
POSTGRES_SSL_REQUIRE=false
POSTGRES_SSL_REJECT_UNAUTHORIZED=false
```

### PostgreSQL SSL Settings

PostgreSQL server SSL configuration:

```bash
# PostgreSQL SSL mode
POSTGRES_SSL_MODE=on
POSTGRES_SSL_CERT_FILE=/etc/ssl/certs/server.crt
POSTGRES_SSL_KEY_FILE=/etc/ssl/private/server.key
```

## Deployment Process

### 1. Environment Setup

Copy and configure your environment file:

```bash
cp .env.example .env
nano .env
```

### 2. SSL Certificate Generation

The deployment script automatically generates SSL certificates, or you can generate them manually:

```bash
./scripts/deploy-ec2.sh ssl-setup
```

### 3. Validate Configuration

Before deployment, validate your SSL configuration:

```bash
./scripts/deploy-ec2.sh ssl-validate
```

### 4. Deploy Production

Run the full deployment with SSL enabled:

```bash
./scripts/deploy-ec2.sh deploy
```

## SSL Certificate Management

### Automatic Generation

The deployment script automatically generates:

- **Nginx SSL certificates** (`cert.pem`, `key.pem`)
- **PostgreSQL SSL certificates** (`server.crt`, `server.key`)
- **Root certificate** (`root.crt`)

### Manual Certificate Management

For production environments, you may want to use certificates from a trusted CA:

1. Replace the generated certificates in the `ssl/` directory
2. Ensure proper permissions:
   ```bash
   chmod 644 ssl/server.crt ssl/cert.pem
   chmod 600 ssl/server.key ssl/key.pem
   ```

## Environment Variables Reference

### Required Variables

```bash
# Database
POSTGRES_DB=prs_production
POSTGRES_USER=prs_user
POSTGRES_PASSWORD=your_secure_password

# Application Security
JWT_SECRET=your_jwt_secret_32_chars_minimum
ENCRYPTION_KEY=your_encryption_key_32_chars
OTP_KEY=your_base64_otp_key_64_bytes
PASS_SECRET=your_password_secret

# Domain
DOMAIN=your-domain.com
```

### SSL Configuration Variables

```bash
# Backend SSL
POSTGRES_SSL_ENABLED=true
POSTGRES_SSL_REQUIRE=false
POSTGRES_SSL_REJECT_UNAUTHORIZED=false

# PostgreSQL SSL
POSTGRES_SSL_MODE=on
POSTGRES_SSL_CERT_FILE=/etc/ssl/certs/server.crt
POSTGRES_SSL_KEY_FILE=/etc/ssl/private/server.key
```

## Troubleshooting

### SSL Connection Issues

1. **Check certificate permissions**:
   ```bash
   ./scripts/deploy-ec2.sh ssl-validate
   ```

2. **Verify PostgreSQL SSL status**:
   ```bash
   docker-compose exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SHOW ssl;"
   ```

3. **Check backend SSL configuration**:
   ```bash
   docker-compose logs backend | grep -i ssl
   ```

### Common Issues

**Issue**: Backend fails to connect to PostgreSQL  
**Solution**: Ensure `POSTGRES_SSL_ENABLED` matches PostgreSQL `ssl` setting

**Issue**: Certificate permission errors  
**Solution**: Run `chmod 600 ssl/server.key && chmod 644 ssl/server.crt`

**Issue**: SSL handshake failures  
**Solution**: Set `POSTGRES_SSL_REJECT_UNAUTHORIZED=false` for self-signed certificates

## Security Considerations

### Production Recommendations

1. **Use trusted CA certificates** for public-facing deployments
2. **Enable SSL requirement** (`POSTGRES_SSL_REQUIRE=true`) for sensitive data
3. **Regular certificate rotation** (certificates expire in 365 days)
4. **Monitor SSL connections** through application logs

### Development vs Production

- **Development**: SSL disabled for faster iteration
- **Production**: SSL enabled with proper certificates
- **Environment-driven**: No code changes needed between environments

## Commands Reference

```bash
# Full deployment with SSL
./scripts/deploy-ec2.sh deploy

# Setup SSL certificates only
./scripts/deploy-ec2.sh ssl-setup

# Validate SSL configuration
./scripts/deploy-ec2.sh ssl-validate

# View service status
./scripts/deploy-ec2.sh status

# View logs
./scripts/deploy-ec2.sh logs [service-name]
```

## Migration from DISABLE_SSL Setup

If you're migrating from a setup that used `DISABLE_SSL=true`:

1. **Update your `.env` file** with the new SSL variables
2. **Remove any hardcoded `DISABLE_SSL=true`** from docker-compose
3. **Run SSL setup**: `./scripts/deploy-ec2.sh ssl-setup`
4. **Validate configuration**: `./scripts/deploy-ec2.sh ssl-validate`
5. **Deploy**: `./scripts/deploy-ec2.sh deploy`

The new setup is backward compatible and will work with existing databases.

---

**Note**: This setup uses self-signed certificates by default. For production environments with public access, consider using certificates from a trusted Certificate Authority (CA) like Let's Encrypt.
