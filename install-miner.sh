#!/bin/bash
# RustChain Miner Installer
# One-line install: curl -sSL https://raw.githubusercontent.com/EugeneJarvis88/rustchain-installer/main/install-miner.sh | bash
# Bounty #63: https://github.com/Scottcjn/rustchain-bounties/issues/63

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Config
RUSTCHAIN_REPO="https://github.com/Scottcjn/Rustchain.git"
INSTALL_DIR="$HOME/.rustchain"
VENV_DIR="$INSTALL_DIR/venv"
NODE_URL="https://50.28.86.131"
DRY_RUN=false

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --help) echo "Usage: $0 [--dry-run]"; exit 0 ;;
        *) shift ;;
    esac
done

log() { echo -e "${GREEN}[RustChain]${NC} $1"; }
warn() { echo -e "${YELLOW}[Warning]${NC} $1"; }
error() { echo -e "${RED}[Error]${NC} $1"; exit 1; }

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        error "Unsupported OS: $OSTYPE"
    fi
    
    ARCH=$(uname -m)
    log "Detected: $OS ($ARCH)"
}

# Check Python
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        log "Found Python $PYTHON_VERSION"
        
        if python3 -c 'import sys; exit(0 if sys.version_info >= (3, 8) else 1)' 2>/dev/null; then
            PYTHON_CMD="python3"
            return 0
        fi
    fi
    return 1
}

# Install Python
install_python() {
    log "Installing Python 3..."
    
    if $DRY_RUN; then
        log "[DRY RUN] Would install Python 3"
        return
    fi
    
    case $OS in
        debian)
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv
            ;;
        redhat)
            sudo yum install -y python3 python3-pip
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install python@3.11
            else
                error "Please install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
            ;;
    esac
}

# Create install directory
setup_dirs() {
    log "Setting up directories..."
    
    if $DRY_RUN; then
        log "[DRY RUN] Would create $INSTALL_DIR"
        return
    fi
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
}

# Clone or update repo
clone_repo() {
    log "Downloading RustChain miner..."
    
    if $DRY_RUN; then
        log "[DRY RUN] Would clone $RUSTCHAIN_REPO"
        return
    fi
    
    if [ -d "$INSTALL_DIR/Rustchain" ]; then
        cd "$INSTALL_DIR/Rustchain"
        git pull origin main 2>/dev/null || git pull origin master
    else
        git clone "$RUSTCHAIN_REPO" "$INSTALL_DIR/Rustchain"
    fi
}

# Setup virtualenv
setup_venv() {
    log "Creating virtual environment..."
    
    if $DRY_RUN; then
        log "[DRY RUN] Would create venv at $VENV_DIR"
        return
    fi
    
    $PYTHON_CMD -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    
    if [ -f "$INSTALL_DIR/Rustchain/requirements.txt" ]; then
        pip install -r "$INSTALL_DIR/Rustchain/requirements.txt"
    else
        pip install httpx cryptography
    fi
}

# Prompt for wallet
setup_wallet() {
    if $DRY_RUN; then
        log "[DRY RUN] Would prompt for wallet name"
        WALLET_NAME="test-wallet"
        return
    fi
    
    echo ""
    echo -e "${BLUE}=== Wallet Setup ===${NC}"
    read -p "Enter wallet name (e.g., my-miner): " WALLET_NAME
    
    if [ -z "$WALLET_NAME" ]; then
        WALLET_NAME="miner-$(hostname)-$(date +%s | tail -c 6)"
    fi
    
    log "Wallet name: $WALLET_NAME"
    echo "$WALLET_NAME" > "$INSTALL_DIR/wallet_name"
}

# Create systemd service (Linux)
setup_systemd() {
    if [[ "$OS" != "debian" && "$OS" != "redhat" && "$OS" != "linux" ]]; then
        return
    fi
    
    log "Setting up systemd service..."
    
    if $DRY_RUN; then
        log "[DRY RUN] Would create systemd user service"
        return
    fi
    
    mkdir -p ~/.config/systemd/user
    
    cat > ~/.config/systemd/user/rustchain-miner.service << EOF
[Unit]
Description=RustChain Miner
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR/Rustchain
ExecStart=$VENV_DIR/bin/python miner.py --wallet $WALLET_NAME
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable rustchain-miner.service
    log "Systemd service created (run: systemctl --user start rustchain-miner)"
}

# Create launchd service (macOS)
setup_launchd() {
    if [[ "$OS" != "macos" ]]; then
        return
    fi
    
    log "Setting up launchd service..."
    
    if $DRY_RUN; then
        log "[DRY RUN] Would create launchd plist"
        return
    fi
    
    mkdir -p ~/Library/LaunchAgents
    
    cat > ~/Library/LaunchAgents/com.rustchain.miner.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.rustchain.miner</string>
    <key>ProgramArguments</key>
    <array>
        <string>$VENV_DIR/bin/python</string>
        <string>$INSTALL_DIR/Rustchain/miner.py</string>
        <string>--wallet</string>
        <string>$WALLET_NAME</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR/Rustchain</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

    log "Launchd service created (run: launchctl load ~/Library/LaunchAgents/com.rustchain.miner.plist)"
}

# Test attestation
test_attestation() {
    log "Testing connection to RustChain network..."
    
    if $DRY_RUN; then
        log "[DRY RUN] Would test connection to $NODE_URL"
        return
    fi
    
    if curl -sk "$NODE_URL/health" | grep -q "status"; then
        log "✓ Connected to RustChain node"
    else
        warn "Could not connect to node (this is okay, node may be temporarily unavailable)"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}   RustChain Miner Installation Complete ${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "Install directory: ${BLUE}$INSTALL_DIR${NC}"
    echo -e "Wallet name:       ${BLUE}$WALLET_NAME${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    
    if [[ "$OS" == "macos" ]]; then
        echo "  1. Start miner:  launchctl load ~/Library/LaunchAgents/com.rustchain.miner.plist"
        echo "  2. View logs:    tail -f /tmp/rustchain-miner.log"
        echo "  3. Stop miner:   launchctl unload ~/Library/LaunchAgents/com.rustchain.miner.plist"
    else
        echo "  1. Start miner:  systemctl --user start rustchain-miner"
        echo "  2. View logs:    journalctl --user -u rustchain-miner -f"
        echo "  3. Stop miner:   systemctl --user stop rustchain-miner"
    fi
    
    echo ""
    echo -e "Manual run: ${BLUE}source $VENV_DIR/bin/activate && python $INSTALL_DIR/Rustchain/miner.py --wallet $WALLET_NAME${NC}"
    echo ""
    echo -e "${GREEN}Happy mining! 🦀${NC}"
}

# Main
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     RustChain Miner Installer        ║${NC}"
    echo -e "${BLUE}║     Proof-of-Antiquity Mining        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""
    
    if $DRY_RUN; then
        warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    detect_os
    
    if ! check_python; then
        install_python
        check_python || error "Failed to install Python"
    fi
    
    setup_dirs
    clone_repo
    setup_venv
    setup_wallet
    
    if [[ "$OS" == "macos" ]]; then
        setup_launchd
    else
        setup_systemd
    fi
    
    test_attestation
    print_summary
}

main "$@"
