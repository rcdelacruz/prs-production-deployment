#!/bin/bash

# Secrets Management Script for Production Deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Generate secure random password
function generate_password {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Create Docker secrets
function create_secrets {
    echo -e "${BLUE}Creating Docker secrets...${NC}"

    # Database passwords
    if ! docker secret ls | grep -q "postgres_password"; then
        generate_password | docker secret create postgres_password -
        echo -e "${GREEN}Created postgres_password secret${NC}"
    else
        echo -e "${YELLOW}postgres_password secret already exists${NC}"
    fi

    if ! docker secret ls | grep -q "postgres_replica_password"; then
        generate_password | docker secret create postgres_replica_password -
        echo -e "${GREEN}Created postgres_replica_password secret${NC}"
    else
        echo -e "${YELLOW}postgres_replica_password secret already exists${NC}"
    fi

    # Redis password
    if ! docker secret ls | grep -q "redis_password"; then
        generate_password | docker secret create redis_password -
        echo -e "${GREEN}Created redis_password secret${NC}"
    else
        echo -e "${YELLOW}redis_password secret already exists${NC}"
    fi

    # MinIO credentials
    if ! docker secret ls | grep -q "minio_access_key"; then
        echo "minioadmin$(generate_password | cut -c1-10)" | docker secret create minio_access_key -
        echo -e "${GREEN}Created minio_access_key secret${NC}"
    else
        echo -e "${YELLOW}minio_access_key secret already exists${NC}"
    fi

    if ! docker secret ls | grep -q "minio_secret_key"; then
        generate_password | docker secret create minio_secret_key -
        echo -e "${GREEN}Created minio_secret_key secret${NC}"
    else
        echo -e "${YELLOW}minio_secret_key secret already exists${NC}"
    fi

    # Application secrets
    if ! docker secret ls | grep -q "jwt_secret"; then
        openssl rand -hex 64 | docker secret create jwt_secret -
        echo -e "${GREEN}Created jwt_secret secret${NC}"
    else
        echo -e "${YELLOW}jwt_secret secret already exists${NC}"
    fi

    if ! docker secret ls | grep -q "encryption_key"; then
        openssl rand -hex 32 | docker secret create encryption_key -
        echo -e "${GREEN}Created encryption_key secret${NC}"
    else
        echo -e "${YELLOW}encryption_key secret already exists${NC}"
    fi

    # OTP and pass secrets
    if ! docker secret ls | grep -q "otp_key"; then
        openssl rand -base64 64 | docker secret create otp_key -
        echo -e "${GREEN}Created otp_key secret${NC}"
    else
        echo -e "${YELLOW}otp_key secret already exists${NC}"
    fi

    if ! docker secret ls | grep -q "pass_secret"; then
        generate_password | docker secret create pass_secret -
        echo -e "${GREEN}Created pass_secret secret${NC}"
    else
        echo -e "${YELLOW}pass_secret secret already exists${NC}"
    fi

    # Monitoring passwords
    if ! docker secret ls | grep -q "grafana_password"; then
        generate_password | docker secret create grafana_password -
        echo -e "${GREEN}Created grafana_password secret${NC}"
    else
        echo -e "${YELLOW}grafana_password secret already exists${NC}"
    fi

    if ! docker secret ls | grep -q "grafana_smtp_password"; then
        generate_password | docker secret create grafana_smtp_password -
        echo -e "${GREEN}Created grafana_smtp_password secret${NC}"
    else
        echo -e "${YELLOW}grafana_smtp_password secret already exists${NC}"
    fi

    # Alert manager secrets
    if ! docker secret ls | grep -q "alertmanager_slack_webhook"; then
        echo "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" | docker secret create alertmanager_slack_webhook -
        echo -e "${GREEN}Created alertmanager_slack_webhook secret${NC}"
        echo -e "${YELLOW}Please update the Slack webhook URL manually${NC}"
    else
        echo -e "${YELLOW}alertmanager_slack_webhook secret already exists${NC}"
    fi

    if ! docker secret ls | grep -q "alertmanager_email_password"; then
        generate_password | docker secret create alertmanager_email_password -
        echo -e "${GREEN}Created alertmanager_email_password secret${NC}"
    else
        echo -e "${YELLOW}alertmanager_email_password secret already exists${NC}"
    fi

    # Backup encryption key
    if ! docker secret ls | grep -q "backup_encryption_key"; then
        openssl rand -hex 32 | docker secret create backup_encryption_key -
        echo -e "${GREEN}Created backup_encryption_key secret${NC}"
    else
        echo -e "${YELLOW}backup_encryption_key secret already exists${NC}"
    fi

    echo -e "${GREEN}All secrets created successfully${NC}"
}

# Set up SSL certificates
function setup_ssl {
    local domain=${1:-}
    local use_staging=${2:-false}
    
    if [[ -z $domain ]]; then
        read -p "Enter your domain name: " domain
    fi

    echo -e "${BLUE}Setting up SSL certificates for $domain...${NC}"

    # Create certificates directory
    mkdir -p ./security/certificates

    # Determine staging flag
    staging_flag=""
    if [[ "$use_staging" == "true" ]]; then
        staging_flag="--staging"
        echo -e "${YELLOW}Using Let's Encrypt staging environment${NC}"
    fi

    # Generate Let's Encrypt certificates using certbot
    echo -e "${BLUE}Obtaining SSL certificates...${NC}"
    
    # Use docker to run certbot
    docker run --rm -it \
        -v $(pwd)/security/certificates:/etc/letsencrypt \
        -p 80:80 \
        certbot/certbot certonly \
        --standalone \
        --agree-tos \
        --non-interactive \
        --email admin@$domain \
        $staging_flag \
        -d $domain \
        -d api.$domain \
        -d monitoring.$domain

    # Create Docker secrets from certificates
    if [[ -f "./security/certificates/live/$domain/fullchain.pem" ]]; then
        if ! docker secret ls | grep -q "ssl_certificate"; then
            docker secret create ssl_certificate ./security/certificates/live/$domain/fullchain.pem
            echo -e "${GREEN}Created ssl_certificate secret${NC}"
        else
            echo -e "${YELLOW}ssl_certificate secret already exists${NC}"
        fi

        if ! docker secret ls | grep -q "ssl_private_key"; then
            docker secret create ssl_private_key ./security/certificates/live/$domain/privkey.pem
            echo -e "${GREEN}Created ssl_private_key secret${NC}"
        else
            echo -e "${YELLOW}ssl_private_key secret already exists${NC}"
        fi

        echo -e "${GREEN}SSL certificates configured successfully${NC}"
    else
        echo -e "${RED}Failed to obtain SSL certificates${NC}"
        exit 1
    fi
}

# Set up node labels
function setup_node_labels {
    echo -e "${BLUE}Setting up node labels...${NC}"

    nodes=$(docker node ls --format "{{.Hostname}}")
    node_count=$(echo "$nodes" | wc -l)
    
    if [[ $node_count -eq 1 ]]; then
        # Single node setup - assign all tiers to the single node
        node=$(echo "$nodes" | head -n1)
        docker node update --label-add tier=backend $node
        docker node update --label-add tier=frontend $node
        docker node update --label-add tier=database $node
        docker node update --label-add tier=cache $node
        docker node update --label-add tier=storage $node
        docker node update --label-add tier=monitoring $node
        docker node update --label-add postgres=primary $node
        echo -e "${GREEN}Labels set for single node: $node${NC}"
    else
        # Multi-node setup - distribute tiers across nodes
        counter=0
        for node in $nodes; do
            case $((counter % 3)) in
                0)
                    docker node update --label-add tier=backend $node
                    docker node update --label-add tier=database $node
                    docker node update --label-add postgres=primary $node
                    echo -e "${GREEN}Node $node labeled as: backend, database (primary)${NC}"
                    ;;
                1)
                    docker node update --label-add tier=frontend $node
                    docker node update --label-add tier=cache $node
                    docker node update --label-add tier=monitoring $node
                    echo -e "${GREEN}Node $node labeled as: frontend, cache, monitoring${NC}"
                    ;;
                2)
                    docker node update --label-add tier=storage $node
                    docker node update --label-add tier=monitoring $node
                    docker node update --label-add postgres=replica $node
                    echo -e "${GREEN}Node $node labeled as: storage, monitoring, postgres (replica)${NC}"
                    ;;
            esac
            ((counter++))
        done
    fi

    echo -e "${GREEN}Node labels configured successfully${NC}"
}

# Generate PostgreSQL SSL certificates
function generate_postgres_ssl {
    echo -e "${BLUE}Generating PostgreSQL SSL certificates...${NC}"

    # Create directory for postgres certs
    mkdir -p ./security/postgres

    # Generate CA private key
    openssl genrsa -out ./security/postgres/ca-key.pem 4096

    # Generate CA certificate
    openssl req -new -x509 -days 365 -key ./security/postgres/ca-key.pem \
        -out ./security/postgres/ca-cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=PostgreSQL-CA"

    # Generate server private key
    openssl genrsa -out ./security/postgres/server-key.pem 4096

    # Generate server certificate request
    openssl req -new -key ./security/postgres/server-key.pem \
        -out ./security/postgres/server-req.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=postgres-primary"

    # Generate server certificate
    openssl x509 -req -days 365 -in ./security/postgres/server-req.pem \
        -CA ./security/postgres/ca-cert.pem -CAkey ./security/postgres/ca-key.pem \
        -CAcreateserial -out ./security/postgres/server-cert.pem

    # Create Docker secrets for PostgreSQL SSL
    if ! docker secret ls | grep -q "postgres_ssl_cert"; then
        docker secret create postgres_ssl_cert ./security/postgres/server-cert.pem
        echo -e "${GREEN}Created postgres_ssl_cert secret${NC}"
    fi

    if ! docker secret ls | grep -q "postgres_ssl_key"; then
        docker secret create postgres_ssl_key ./security/postgres/server-key.pem
        echo -e "${GREEN}Created postgres_ssl_key secret${NC}"
    fi

    if ! docker secret ls | grep -q "postgres_ca_cert"; then
        docker secret create postgres_ca_cert ./security/postgres/ca-cert.pem
        echo -e "${GREEN}Created postgres_ca_cert secret${NC}"
    fi

    echo -e "${GREEN}PostgreSQL SSL certificates generated successfully${NC}"
}

# Display help
function show_help {
    echo -e "${BLUE}PRS Production Secrets Management${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --secrets                  Create all Docker secrets"
    echo "  --ssl [domain] [staging]   Set up SSL certificates"
    echo "  --labels                   Set up node labels"
    echo "  --postgres-ssl             Generate PostgreSQL SSL certificates"
    echo "  --all [domain] [staging]   Set up everything"
    echo "  --help                     Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --secrets               # Create all secrets"
    echo "  $0 --ssl example.com       # Set up SSL for example.com"
    echo "  $0 --ssl example.com true  # Set up SSL using staging (testing)"
    echo "  $0 --labels                # Set up node labels"
    echo "  $0 --all example.com       # Complete setup"
}

# Main execution
case "${1:-}" in
    --secrets)
        create_secrets
        ;;
    --ssl)
        setup_ssl "${2:-}" "${3:-false}"
        ;;
    --labels)
        setup_node_labels
        ;;
    --postgres-ssl)
        generate_postgres_ssl
        ;;
    --all)
        create_secrets
        generate_postgres_ssl
        setup_ssl "${2:-}" "${3:-false}"
        setup_node_labels
        echo -e "${GREEN}Complete setup finished successfully!${NC}"
        ;;
    --help|*)
        show_help
        ;;
esac
