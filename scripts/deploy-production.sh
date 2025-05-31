#!/bin/bash

# Production Deployment Script for PRS
# This script manages the production environment deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILES=(
    "compose/docker-compose.prod.yml"
    "compose/docker-compose.monitoring.yml"
    "compose/docker-compose.backup.yml"
)
ENV_FILE=".env.production"
STACK_NAME="prs-production"

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
else
    echo -e "${RED}Error: $ENV_FILE not found${NC}"
    exit 1
fi

# Function to check prerequisites
function check_prerequisites {
    echo -e "${BLUE}Checking prerequisites...${NC}"

    # Check Docker Swarm
    if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
        echo -e "${RED}Error: Docker Swarm is not initialized${NC}"
        echo "Run: docker swarm init"
        exit 1
    fi

    # Check secrets
    required_secrets=(
        "postgres_password"
        "redis_password"
        "jwt_secret"
        "ssl_certificate"
        "ssl_private_key"
    )

    for secret in "${required_secrets[@]}"; do
        if ! docker secret ls | grep -q "$secret"; then
            echo -e "${RED}Error: Secret '$secret' not found${NC}"
            echo "Run: ./scripts/setup-secrets.sh to create required secrets"
            exit 1
        fi
    done

    # Check node labels
    if ! docker node ls --format "table {{.Hostname}}\t{{.ManagerStatus}}\t{{.Availability}}" | grep -q "Ready"; then
        echo -e "${RED}Error: No ready nodes found${NC}"
        exit 1
    fi

    echo -e "${GREEN}Prerequisites check passed${NC}"
}

# Function to deploy the stack
function deploy_stack {
    echo -e "${BLUE}Deploying production stack...${NC}"

    # Build compose command
    compose_cmd="docker stack deploy"
    for file in "${COMPOSE_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            compose_cmd="$compose_cmd -c $file"
        fi
    done
    compose_cmd="$compose_cmd $STACK_NAME"

    # Deploy the stack
    eval "$compose_cmd"

    echo -e "${GREEN}Stack deployed successfully${NC}"
}

# Function to check stack health
function health_check {
    echo -e "${BLUE}Performing health check...${NC}"

    # Wait for services to start
    sleep 30

    # Check service status
    services=$(docker stack services $STACK_NAME --format "{{.Name}}")
    
    for service in $services; do
        replicas=$(docker service ls --filter name=$service --format "{{.Replicas}}")
        if [[ $replicas == *"0/"* ]]; then
            echo -e "${RED}Service $service has 0 replicas running${NC}"
            return 1
        else
            echo -e "${GREEN}Service $service: $replicas${NC}"
        fi
    done

    # Test application endpoints
    echo -e "${BLUE}Testing application endpoints...${NC}"
    
    # Test main application
    if curl -f -s "https://$DOMAIN/health" > /dev/null; then
        echo -e "${GREEN}Main application health check passed${NC}"
    else
        echo -e "${RED}Main application health check failed${NC}"
        return 1
    fi

    # Test API
    if curl -f -s "https://api.$DOMAIN/health" > /dev/null; then
        echo -e "${GREEN}API health check passed${NC}"
    else
        echo -e "${RED}API health check failed${NC}"
        return 1
    fi

    echo -e "${GREEN}All health checks passed${NC}"
}

# Function to initialize database
function init_database {
    echo -e "${BLUE}Initializing database...${NC}"

    # Wait for database to be ready
    echo "Waiting for database to be ready..."
    sleep 60

    # Run migrations
    backend_task=$(docker service ps --filter desired-state=running ${STACK_NAME}_backend -q --no-trunc | head -n1)
    if [[ -n "$backend_task" ]]; then
        docker exec $(docker ps -q --filter "label=com.docker.swarm.task.id=$backend_task") npm run migrate
        docker exec $(docker ps -q --filter "label=com.docker.swarm.task.id=$backend_task") npm run seed:production
    fi

    echo -e "${GREEN}Database initialized successfully${NC}"
}

# Function to update the stack
function update_stack {
    local version=${1:-latest}
    
    echo -e "${BLUE}Updating stack to version $version...${NC}"

    # Update backend service
    docker service update --image prs-backend:$version ${STACK_NAME}_backend

    # Update frontend service
    docker service update --image prs-frontend:$version ${STACK_NAME}_frontend

    # Wait for update to complete
    echo "Waiting for update to complete..."
    sleep 60

    # Verify update
    health_check
}

# Function to rollback the stack
function rollback_stack {
    echo -e "${YELLOW}Rolling back stack...${NC}"

    # Rollback backend service
    docker service rollback ${STACK_NAME}_backend

    # Rollback frontend service
    docker service rollback ${STACK_NAME}_frontend

    echo -e "${GREEN}Rollback completed${NC}"
}

# Function to scale services
function scale_services {
    local backend_replicas=${1:-3}
    local frontend_replicas=${2:-2}

    echo -e "${BLUE}Scaling services...${NC}"

    # Scale backend
    docker service scale ${STACK_NAME}_backend=$backend_replicas

    # Scale frontend
    docker service scale ${STACK_NAME}_frontend=$frontend_replicas

    echo -e "${GREEN}Services scaled successfully${NC}"
}

# Function to show logs
function show_logs {
    local service=${1:-""}
    
    if [[ -n $service ]]; then
        docker service logs -f ${STACK_NAME}_$service
    else
        echo -e "${BLUE}Available services:${NC}"
        docker stack services $STACK_NAME --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
    fi
}

# Function to backup database
function backup_database {
    echo -e "${BLUE}Creating database backup...${NC}"

    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="prs_production_backup_$timestamp.sql.gz"

    # Create backup
    postgres_task=$(docker service ps --filter desired-state=running ${STACK_NAME}_postgres-primary -q --no-trunc | head -n1)
    if [[ -n "$postgres_task" ]]; then
        docker exec $(docker ps -q --filter "label=com.docker.swarm.task.id=$postgres_task") \
            pg_dump -U $POSTGRES_USER $POSTGRES_DB | gzip > /backups/$backup_file
    fi

    echo -e "${GREEN}Backup created: $backup_file${NC}"
}

# Function to remove the stack
function remove_stack {
    echo -e "${YELLOW}Removing production stack...${NC}"
    
    read -p "Are you sure you want to remove the production stack? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker stack rm $STACK_NAME
        echo -e "${GREEN}Stack removed${NC}"
    else
        echo "Cancelled"
    fi
}

# Display help
function show_help {
    echo -e "${BLUE}PRS Production Deployment Script${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --deploy                   Deploy the production stack"
    echo "  --update [version]         Update stack to specified version"
    echo "  --rollback                 Rollback to previous version"
    echo "  --scale [backend] [frontend] Scale services"
    echo "  --health-check             Perform health check"
    echo "  --init-db                  Initialize database"
    echo "  --backup-db                Create database backup"
    echo "  --logs [service]           Show service logs"
    echo "  --remove                   Remove the stack"
    echo "  --help                     Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --deploy --init-db      # Deploy and initialize"
    echo "  $0 --update v1.2.0         # Update to version 1.2.0"
    echo "  $0 --scale 5 3             # Scale backend to 5, frontend to 3"
    echo "  $0 --logs backend          # Show backend logs"
}

# Parse command line arguments
case "${1:-}" in
    --deploy)
        check_prerequisites
        deploy_stack
        if [[ "${2:-}" == "--init-db" ]]; then
            init_database
        fi
        health_check
        ;;
    --update)
        update_stack "${2:-latest}"
        ;;
    --rollback)
        rollback_stack
        ;;
    --scale)
        scale_services "${2:-3}" "${3:-2}"
        ;;
    --health-check)
        health_check
        ;;
    --init-db)
        init_database
        ;;
    --backup-db)
        backup_database
        ;;
    --logs)
        show_logs "${2:-}"
        ;;
    --remove)
        remove_stack
        ;;
    --help|*)
        show_help
        ;;
esac
