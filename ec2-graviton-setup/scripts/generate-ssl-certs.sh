#!/bin/bash

# Generate SSL Certificates for PostgreSQL Production
# This script creates self-signed certificates for PostgreSQL SSL connections

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="$SCRIPT_DIR/../ssl"

echo "🔐 Generating SSL certificates for PostgreSQL production..."

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Generate private key
echo "📝 Generating private key..."
openssl genrsa -out "$SSL_DIR/server.key" 2048

# Set proper permissions for private key
chmod 600 "$SSL_DIR/server.key"

# Generate certificate signing request
echo "📝 Generating certificate signing request..."
openssl req -new -key "$SSL_DIR/server.key" -out "$SSL_DIR/server.csr" -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=postgres"

# Generate self-signed certificate
echo "📝 Generating self-signed certificate..."
openssl x509 -req -in "$SSL_DIR/server.csr" -signkey "$SSL_DIR/server.key" -out "$SSL_DIR/server.crt" -days 365

# Set proper permissions
chmod 644 "$SSL_DIR/server.crt"
chmod 600 "$SSL_DIR/server.key"

# Clean up CSR file
rm "$SSL_DIR/server.csr"

# Create root certificate (copy of server cert for this setup)
cp "$SSL_DIR/server.crt" "$SSL_DIR/root.crt"

echo "✅ SSL certificates generated successfully!"
echo "📁 Certificates location: $SSL_DIR"
echo "🔑 Private key: server.key"
echo "📜 Certificate: server.crt"
echo "🏛️  Root certificate: root.crt"
echo ""
echo "⚠️  Note: These are self-signed certificates for development/testing."
echo "   For production, consider using certificates from a trusted CA."
echo ""
echo "🚀 You can now start the PostgreSQL container with SSL enabled."
