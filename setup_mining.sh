#!/bin/bash
# ============================================================
# 🔧 NINURTA BANK - REAL MINING SETUP
# "Connect your rig to the ATM"
# ============================================================

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}           ⛏️ NINURTA MINING RIG SETUP${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================
# Step 1: Install xmrig
# ============================================================

echo -e "${CYAN}📦 Step 1: Installing xmrig...${NC}"

if command -v xmrig &> /dev/null; then
    echo -e "${GREEN}✅ xmrig already installed${NC}"
else
    echo -e "${YELLOW}⚠️  xmrig not found. Installing...${NC}"
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${CYAN}🐧 Detected Linux${NC}"
        
        # Ubuntu/Debian
        if command -v apt &> /dev/null; then
            sudo apt update -y
            sudo apt install -y git cmake make g++
            sudo apt install -y libuv1-dev
        fi
        
        # Clone and build
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
    fi
fi

echo ""

# ============================================================
# Step 2: Setup wallet address
# ============================================================

echo -e "${CYAN}💳 Step 2: Configure wallet address...${NC}"

read -p "Enter your Monero (XMR) wallet address: " XMR_WALLET

if [ -z "$XMR_WALLET" ]; then
    echo -e "${RED}❌ No wallet address provided${NC}"
    echo -e "${YELLOW}Get a wallet from: https://www.getmonero.org/downloads/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Wallet: ${XMR_WALLET:0:20}...${NC}"
echo ""

# ============================================================
# Step 3: Create config
# ============================================================

echo -e "${CYAN}⚙️  Step 3: Creating config...${NC}"

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
# To start mining manually:
#   xmrig -c ~/xmrig_config.json
# 
# To check earnings:
#   curl https://xmrchain.net/api/address/YOUR_WALLET
# 
# ============================================================
