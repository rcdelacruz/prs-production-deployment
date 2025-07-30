#!/bin/bash

# Validate SSL Configuration for Production Deployment
# This script checks if SSL certificates and configuration are properly set up

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="$SCRIPT_DIR/../ssl"
ENV_FILE="$SCRIPT_DIR/../.env"

echo "🔍 Validating SSL configuration for production deployment..."

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found at $ENV_FILE"
    echo "   Please copy .env.example to .env and configure it."
    exit 1
fi

# Source environment variables
source "$ENV_FILE"

echo "✅ Environment file found and loaded"

# Check SSL certificates
if [ ! -f "$SSL_DIR/server.crt" ]; then
    echo "❌ Error: SSL certificate not found at $SSL_DIR/server.crt"
    echo "   Run: ./scripts/generate-ssl-certs.sh"
    exit 1
fi

if [ ! -f "$SSL_DIR/server.key" ]; then
    echo "❌ Error: SSL private key not found at $SSL_DIR/server.key"
    echo "   Run: ./scripts/generate-ssl-certs.sh"
    exit 1
fi

echo "✅ SSL certificates found"

# Check certificate permissions
CERT_PERMS=$(stat -c "%a" "$SSL_DIR/server.crt" 2>/dev/null || echo "000")
KEY_PERMS=$(stat -c "%a" "$SSL_DIR/server.key" 2>/dev/null || echo "000")

if [ "$CERT_PERMS" != "644" ]; then
    echo "⚠️  Warning: Certificate permissions should be 644, found $CERT_PERMS"
    echo "   Fix with: chmod 644 $SSL_DIR/server.crt"
fi

if [ "$KEY_PERMS" != "600" ]; then
    echo "⚠️  Warning: Private key permissions should be 600, found $KEY_PERMS"
    echo "   Fix with: chmod 600 $SSL_DIR/server.key"
fi

echo "✅ Certificate permissions validated"

# Check required environment variables
REQUIRED_VARS=(
    "POSTGRES_DB"
    "POSTGRES_USER" 
    "POSTGRES_PASSWORD"
    "JWT_SECRET"
    "ENCRYPTION_KEY"
    "OTP_KEY"
    "PASS_SECRET"
    "DOMAIN"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: Required environment variable $var is not set"
        exit 1
    fi
done

echo "✅ Required environment variables are set"

# Check SSL configuration
if [ "${POSTGRES_SSL_ENABLED:-true}" = "true" ]; then
    echo "✅ PostgreSQL SSL is enabled"
    
    if [ "${POSTGRES_SSL_MODE:-on}" = "on" ]; then
        echo "✅ PostgreSQL server SSL mode is enabled"
    else
        echo "⚠️  Warning: POSTGRES_SSL_ENABLED=true but POSTGRES_SSL_MODE=$POSTGRES_SSL_MODE"
    fi
else
    echo "⚠️  Warning: PostgreSQL SSL is disabled (POSTGRES_SSL_ENABLED=false)"
fi

echo ""
echo "🎉 SSL configuration validation completed!"
echo ""
echo "📋 Configuration Summary:"
echo "   - PostgreSQL SSL Enabled: ${POSTGRES_SSL_ENABLED:-true}"
echo "   - PostgreSQL SSL Mode: ${POSTGRES_SSL_MODE:-on}"
echo "   - SSL Require: ${POSTGRES_SSL_REQUIRE:-false}"
echo "   - SSL Reject Unauthorized: ${POSTGRES_SSL_REJECT_UNAUTHORIZED:-false}"
echo ""
echo "🚀 Ready to deploy with SSL-enabled production setup!"
