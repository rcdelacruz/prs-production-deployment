#!/bin/bash

# PRS EC2 Graviton Setup Script
# This script prepares an EC2 Graviton instance for PRS deployment
# Optimized for t4g.medium (2 cores, 4GB memory, ARM64)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat Enterprise Linux"
        VER=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log_info "Detected OS: $OS $VER"
}

check_architecture() {
    ARCH=$(uname -m)
    log_info "Architecture: $ARCH"
    
    if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        log_warning "This setup is optimized for ARM64 architecture"
        log_warning "Current architecture: $ARCH"
        log_warning "Some optimizations may not apply"
    else
        log_success "ARM64 architecture detected - perfect for Graviton!"
    fi
}

check_resources() {
    log_info "Checking system resources..."
    
    # Check memory
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    log_info "Total Memory: ${TOTAL_MEM}MB"
    
    if [ "$TOTAL_MEM" -lt 3500 ]; then
        log_warning "Memory is less than 4GB. Performance may be limited."
        log_warning "Consider upgrading to a larger instance type."
    else
        log_success "Memory check passed"
    fi
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    log_info "CPU Cores: $CPU_CORES"
    
    if [ "$CPU_CORES" -lt 2 ]; then
        log_warning "Less than 2 CPU cores detected. Performance may be limited."
    else
        log_success "CPU check passed"
    fi
    
    # Check disk space
    DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
    log_info "Available Disk Space: ${DISK_SPACE}GB"
    
    if [ "${DISK_SPACE%.*}" -lt 10 ]; then
        log_warning "Less than 10GB disk space available"
        log_warning "Consider expanding the root volume"
    else
        log_success "Disk space check passed"
    fi
}

update_system() {
    log_info "Updating system packages..."
    
    if [[ "$OS" == *"Amazon Linux"* ]] || [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo yum update -y
        log_success "System updated (yum)"
    elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt-get update && sudo apt-get upgrade -y
        log_success "System updated (apt)"
    else
        log_warning "Unknown package manager. Please update system manually."
    fi
}

install_docker() {
    log_info "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        log_info "Docker is already installed"
        docker --version
        return
    fi
    
    if [[ "$OS" == *"Amazon Linux"* ]]; then
        # Amazon Linux 2
        sudo yum install -y docker
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        log_success "Docker installed on Amazon Linux"
        
    elif [[ "$OS" == *"Ubuntu"* ]]; then
        # Ubuntu
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        log_success "Docker installed on Ubuntu"
        
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # CentOS/RHEL
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        log_success "Docker installed on CentOS/RHEL"
        
    else
        log_error "Unsupported OS for automatic Docker installation: $OS"
        log_info "Please install Docker manually: https://docs.docker.com/engine/install/"
        exit 1
    fi
}

install_docker_compose() {
    log_info "Installing Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose is already installed"
        docker-compose --version
        return
    fi
    
    # Install Docker Compose for ARM64
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for easier access
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose installed: $COMPOSE_VERSION"
}

install_utilities() {
    log_info "Installing useful utilities..."
    
    if [[ "$OS" == *"Amazon Linux"* ]] || [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo yum install -y git curl wget htop nano vim openssl net-tools
    elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt-get install -y git curl wget htop nano vim openssl net-tools
    fi
    
    log_success "Utilities installed"
}

configure_firewall() {
    log_info "Configuring firewall..."
    
    # Check if firewall is active
    if command -v ufw &> /dev/null; then
        # Ubuntu firewall
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 8080/tcp
        sudo ufw allow 3001/tcp
        log_info "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL firewall
        sudo firewall-cmd --permanent --add-port=22/tcp
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        sudo firewall-cmd --permanent --add-port=8080/tcp
        sudo firewall-cmd --permanent --add-port=3001/tcp
        sudo firewall-cmd --reload
        log_info "Firewalld configured"
    else
        log_warning "No firewall detected. Make sure EC2 Security Groups are configured properly."
    fi
    
    log_info "Required ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080 (Adminer), 3001 (Grafana)"
}

optimize_for_4gb() {
    log_info "Optimizing system for 4GB memory..."
    
    # Configure swap if not present
    if [ ! -f /swapfile ]; then
        log_info "Creating 2GB swap file..."
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        log_success "Swap file created"
    else
        log_info "Swap file already exists"
    fi
    
    # Optimize kernel parameters
    log_info "Optimizing kernel parameters..."
    cat << EOF | sudo tee -a /etc/sysctl.conf
# PRS EC2 Optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
fs.file-max=65536
EOF
    
    sudo sysctl -p
    log_success "Kernel parameters optimized"
}

setup_monitoring() {
    log_info "Setting up basic monitoring..."
    
    # Install htop if not present
    if ! command -v htop &> /dev/null; then
        if [[ "$OS" == *"Amazon Linux"* ]] || [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
            sudo yum install -y htop
        elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
            sudo apt-get install -y htop
        fi
    fi
    
    # Create monitoring script
    cat << 'EOF' > /tmp/monitor.sh
#!/bin/bash
echo "=== System Monitor ==="
echo "Time: $(date)"
echo "Uptime: $(uptime)"
echo "Memory: $(free -h | grep Mem)"
echo "Disk: $(df -h / | tail -1)"
echo "Load: $(cat /proc/loadavg)"
echo "Docker: $(docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'Docker not running')"
EOF
    
    chmod +x /tmp/monitor.sh
    sudo mv /tmp/monitor.sh /usr/local/bin/monitor
    
    log_success "Monitoring tools installed. Run 'monitor' to check system status."
}

create_project_structure() {
    log_info "Creating project structure..."
    
    # Create directories
    mkdir -p ~/prs-deployment/{logs,backups,ssl}
    
    # Set permissions
    chmod 755 ~/prs-deployment
    chmod 700 ~/prs-deployment/ssl
    
    log_success "Project structure created in ~/prs-deployment"
}

show_next_steps() {
    log_success "EC2 Graviton setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Log out and log back in (to apply Docker group membership)"
    echo "2. Clone your PRS repository"
    echo "3. Navigate to prs-production-deployment/ec2-graviton-setup/"
    echo "4. Copy .env.example to .env and configure your settings"
    echo "5. Run: ./scripts/deploy-ec2.sh deploy"
    echo ""
    echo "Useful commands:"
    echo "  monitor          - Check system status"
    echo "  docker ps        - List running containers"
    echo "  docker stats     - Show container resource usage"
    echo "  htop             - Interactive process viewer"
    echo ""
    echo "Important notes:"
    echo "- Configure your domain name in .env"
    echo "- Set strong passwords for production"
    echo "- Configure proper SSL certificates for production"
    echo "- Ensure EC2 Security Groups allow required ports"
    echo ""
    log_info "System optimized for 4GB memory with ARM64 architecture"
}

# Main execution
main() {
    log_info "Starting PRS EC2 Graviton setup..."
    
    detect_os
    check_architecture
    check_resources
    update_system
    install_docker
    install_docker_compose
    install_utilities
    configure_firewall
    optimize_for_4gb
    setup_monitoring
    create_project_structure
    show_next_steps
}

# Run main function
main "$@"
