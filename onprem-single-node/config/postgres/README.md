# PostgreSQL SSL Configuration

This directory contains SSL certificate templates for PostgreSQL.

## Certificate Generation

The deployment script will automatically generate SSL certificates for PostgreSQL:

1. **server.crt** - Server certificate
2. **server.key** - Server private key

## Manual Certificate Generation

If you need to generate certificates manually:

```bash
# Generate private key
openssl genrsa -out server.key 2048

# Generate certificate signing request
openssl req -new -key server.key -out server.csr \
  -subj "/C=PH/ST=Metro Manila/L=Quezon City/O=PRS System/CN=postgres"

# Generate self-signed certificate
openssl x509 -req -in server.csr -signkey server.key -out server.crt -days 365

# Set proper permissions
chmod 600 server.key
chmod 644 server.crt
```

## Security Notes

- Keep the private key secure and never commit it to version control
- For production, consider using certificates from a trusted CA
- The deployment script generates these automatically during setup
- Certificates are mounted into the PostgreSQL container at runtime

## Directory Structure

After certificate generation:
```
config/postgres/
├── README.md        # This file
├── server.crt       # Generated SSL certificate
└── server.key       # Generated private key
```

## Configuration Integration

These certificates are automatically integrated into the PostgreSQL container via the docker-compose.yml volume mounts:

```yaml
volumes:
  - ./config/postgres/server.crt:/var/lib/postgresql/server.crt:ro
  - ./config/postgres/server.key:/var/lib/postgresql/server.key:ro
```

The PostgreSQL configuration enables SSL with these certificates for secure connections.
