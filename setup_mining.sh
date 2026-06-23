#!/bin/bash
# ============================================================
# 🔧 NINURTA BANK - REAL MINING SETUP
# "Connect your rig to the ATM"
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}           ⛏️ NINURTA MINING RIG SETUP${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================
# YOUR XMR WALLET (Already configured!)
# ============================================================

XMR_WALLET="44osUR6e9UjePWUQhavLNYTY7JSzwZMN6249AdnjbwmtXtirsjDiGcejCjJkoTst2BGD3NaLrtpzNENsc6AsZ9AGKWTx7YZ"

echo -e "${GREEN}✅ Wallet: ${XMR_WALLET:0:20}...${XMR_WALLET: -10}${NC}"
echo ""

# ============================================================
# Step 1: Install xmrig
# ============================================================

echo -e "${CYAN}📦 Step 1: Installing xmrig...${NC}"

if command -v xmrig &> /dev/null; then
    echo -e "${GREEN}✅ xmrig already installed${NC}"
else
    echo -e "${YELLOW}⚠️  xmrig not found. Installing...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${CYAN}🐧 Detected Linux${NC}"
        
        if command -v apt &> /dev/null; then
            sudo apt update -y
            sudo apt install -y git cmake make g++
            sudo apt install -y libuv1-dev
        elif command -v yum &> /dev/null; then
            sudo yum install -y git cmake make gcc-c++
            sudo yum install -y libuv-devel
        fi
        
        cd ~/
        git clone https://github.com/xmrig/xmrig.git
        cd xmrig
        mkdir -p build
        cd build
        cmake .. -DCMAKE_BUILD_TYPE=Release
        make -j$(nproc)
        sudo cp xmrig /usr/local/bin/
        
        echo -e "${GREEN}✅ xmrig installed${NC}"
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${CYAN}🍎 Detected macOS${NC}"
        brew install xmrig
        
    else
        echo -e "${RED}❌ Unsupported OS${NC}"
        echo -e "${YELLOW}Download from: https://github.com/xmrig/xmrig/releases${NC}"
        exit 1
    fi
fi

echo ""

# ============================================================
# Step 2: Create config with YOUR wallet
# ============================================================

echo -e "${CYAN}⚙️  Step 2: Creating config with your wallet...${NC}"

cat > ~/xmrig_config.json << EOF
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "threads": $(nproc 2>/dev/null || echo 2)
    },
    "pools": [
        {
            "url": "pool.supportxmr.com:3333",
            "user": "$XMR_WALLET",
            "pass": "ninurta_rig",
            "tls": false
        }
    ],
    "donate-level": 1
}
EOF

echo -e "${GREEN}✅ Config created at ~/xmrig_config.json${NC}"
echo ""

# ============================================================
# Step 3: Show wallet info
# ============================================================

echo -e "${CYAN}💳 Step 3: Wallet Information${NC}"
echo -e "${YELLOW}Your Monero Wallet:${NC}"
echo -e "${CYAN}$XMR_WALLET${NC}"
echo ""
echo -e "${YELLOW}Check your balance at:${NC}"
echo -e "${CYAN}https://xmrchain.net/address/$XMR_WALLET${NC}"
echo ""

# ============================================================
# Step 4: Start mining
# ============================================================

echo -e "${CYAN}⛏️ Step 4: Starting mining...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop mining${NC}"
echo ""

xmrig -c ~/xmrig_config.json

# ============================================================
# 📌 NOTES
# ============================================================
# 
# Your wallet is already configured!
# 
# To start mining manually:
#   xmrig -c ~/xmrig_config.json
# 
# To check earnings:
#   curl https://xmrchain.net/api/address/$XMR_WALLET
# 
# ============================================================
