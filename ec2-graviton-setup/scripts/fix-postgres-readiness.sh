#!/bin/bash

# Script to fix PostgreSQL readiness issues
set -e

# Constants
CONTAINER_NAME="prs-ec2-postgres-timescale"
POSTGRES_USER="prs_user"
POSTGRES_DB="prs_production"
POSTGRES_PASSWORD="p*Ecp5YP2cvctg"

# Functions
log_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS] $1\033[0m"
}

log_error() {
    echo -e "\033[0;31m[ERROR] $1\033[0m"
}

log_info "Starting PostgreSQL readiness fix..."

# Step 1: Check if PostgreSQL container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log_error "PostgreSQL container is not running"
    exit 1
fi
log_success "PostgreSQL container is running"

# Step 2: Check basic connectivity
if docker exec "$CONTAINER_NAME" pg_isready; then
    log_success "Basic PostgreSQL connection is working"
else
    log_error "Basic PostgreSQL connection failed"
    exit 1
fi

# Step 3: Create .pgpass file inside the container for password-less authentication
log_info "Creating .pgpass file inside container..."
docker exec "$CONTAINER_NAME" bash -c "echo '*:*:*:postgres:postgres' > ~/.pgpass && chmod 600 ~/.pgpass"
log_success ".pgpass file created"

# Step 4: Ensure database exists
log_info "Ensuring database exists..."
docker exec "$CONTAINER_NAME" bash -c "psql -U postgres -c \"SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'\" | grep -q 1 || psql -U postgres -c \"CREATE DATABASE $POSTGRES_DB\""
log_success "Database exists or was created"

# Step 5: Ensure user exists
log_info "Ensuring user exists..."
docker exec "$CONTAINER_NAME" bash -c "psql -U postgres -c \"SELECT 1 FROM pg_roles WHERE rolname = '$POSTGRES_USER'\" | grep -q 1 || psql -U postgres -c \"CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD'\""
log_success "User exists or was created"

# Step 6: Grant privileges
log_info "Granting privileges..."
docker exec "$CONTAINER_NAME" bash -c "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER\""
docker exec "$CONTAINER_NAME" bash -c "psql -U postgres -c \"ALTER USER $POSTGRES_USER WITH SUPERUSER\""
log_success "Privileges granted"

# Step 7: Update pg_hba.conf for better authentication
log_info "Updating pg_hba.conf..."
docker exec "$CONTAINER_NAME" bash -c "echo 'local all all trust' > /tmp/pg_hba.conf"
docker exec "$CONTAINER_NAME" bash -c "echo 'host all all 0.0.0.0/0 md5' >> /tmp/pg_hba.conf"
docker exec "$CONTAINER_NAME" bash -c "cat /tmp/pg_hba.conf > /var/lib/postgresql/data/pg_hba.conf"
docker exec "$CONTAINER_NAME" bash -c "chown postgres:postgres /var/lib/postgresql/data/pg_hba.conf"
docker exec "$CONTAINER_NAME" bash -c "chmod 600 /var/lib/postgresql/data/pg_hba.conf"
log_success "pg_hba.conf updated"

# Step 8: Restart PostgreSQL to apply configuration
log_info "Restarting PostgreSQL container..."
docker restart "$CONTAINER_NAME"
log_success "PostgreSQL container restarted"

# Wait for PostgreSQL to be ready again
log_info "Waiting for PostgreSQL to be ready again..."
sleep 10

# Step 9: Verify connectivity
log_info "Testing connection..."
if docker exec "$CONTAINER_NAME" pg_isready; then
    log_success "Basic PostgreSQL connection is working"
else
    log_error "Basic PostgreSQL connection failed"
    exit 1
fi

# Step 10: Verify connection with the specific user and database
log_info "Testing connection with specific user and database..."
if docker exec "$CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
    log_success "Connection with specific user and database is working"
else
    log_error "Connection with specific user and database failed"
    exit 1
fi

log_success "PostgreSQL readiness fix completed successfully"
log_info "You can now run the database import again"
