#!/bin/bash
# ============================================================
# MARDUK MINING RIG - Easy Harvest Crypto Miner
# "Mine. Earn. Withdraw to Ninurta Bank."
# ============================================================
# 
# 🔧 WHAT TO CHANGE:
# 
# 1. WALLET_ADDRESS (line 38) - Your crypto wallet address
# 2. MINING_POOL (line 39) - Mining pool URL
# 3. CRYPTO_CHOICE (line 40) - xmr, ltc, doge, rvn, vrsc
# 4. THREADS (line 41) - Number of CPU threads to use
# 
# ============================================================

# ============================================================
# 🛠️ USER SETTINGS
# ============================================================

WALLET_ADDRESS="YOUR_WALLET_ADDRESS_HERE"  # Replace with your address
MINING_POOL="stratum+tcp://pool.supportxmr.com:3333"  # Default pool
CRYPTO_CHOICE="xmr"  # Options: xmr, ltc, doge, rvn, vrsc
THREADS=$(nproc 2>/dev/null || echo 4)  # Auto-detect CPU cores
LOG_DIR="$HOME/.marduk_rig"

# ============================================================
# 🧠 SYSTEM SETUP
# ============================================================

mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================
# 📡 FUNCTIONS
# ============================================================

show_banner() {
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    ⛏️ MARDUK MINING RIG v1.0${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📤 Wallet:${NC} ${WALLET_ADDRESS:0:20}..."
    echo -e "${YELLOW}⛏️  Crypto:${NC} $CRYPTO_CHOICE"
    echo -e "${YELLOW}💻 Threads:${NC} $THREADS"
    echo -e "${YELLOW}📁 Logs:${NC} $LOG_DIR"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check and install miners
install_miner() {
    local crypto="$1"
    
    case "$crypto" in
        "xmr")
            echo -e "${CYAN}📦 Installing Monero miner...${NC}"
            if command -v xmrig &> /dev/null; then
                echo -e "${GREEN}✅ xmrig already installed${NC}"
                return 0
            fi
            # Download xmrig
            wget -q https://github.com/xmrig/xmrig/releases/latest/download/xmrig-6.21.3-linux-x64.tar.gz -O /tmp/xmrig.tar.gz
            tar -xzf /tmp/xmrig.tar.gz -C /tmp/
            sudo mv /tmp/xmrig-*/xmrig /usr/local/bin/ 2>/dev/null || mv /tmp/xmrig-*/xmrig .
            chmod +x xmrig 2>/dev/null || sudo chmod +x /usr/local/bin/xmrig
            echo -e "${GREEN}✅ Monero miner installed${NC}"
            ;;
        "ltc"|"doge")
            echo -e "${CYAN}📦 Installing Litecoin/Dogecoin miner...${NC}"
            if command -v cpuminer &> /dev/null; then
                echo -e "${GREEN}✅ cpuminer already installed${NC}"
                return 0
            fi
            # Install cpuminer
            sudo apt update -qq && sudo apt install -y cpuminer 2>/dev/null || {
                echo -e "${YELLOW}⚠️  Install cpuminer manually: sudo apt install cpuminer${NC}"
            }
            ;;
        "rvn")
            echo -e "${CYAN}📦 Installing Ravencoin miner...${NC}"
            if command -v kawpowminer &> /dev/null; then
                echo -e "${GREEN}✅ kawpowminer already installed${NC}"
                return 0
            fi
            # Download kawpowminer
            wget -q https://github.com/RavenCommunity/kawpowminer/releases/latest/download/kawpowminer-ubuntu-20.04.tar.gz -O /tmp/kawpowminer.tar.gz
            tar -xzf /tmp/kawpowminer.tar.gz -C /tmp/
            sudo mv /tmp/kawpowminer /usr/local/bin/ 2>/dev/null || mv /tmp/kawpowminer .
            chmod +x kawpowminer 2>/dev/null || sudo chmod +x /usr/local/bin/kawpowminer
            echo -e "${GREEN}✅ Ravencoin miner installed${NC}"
            ;;
        "vrsc")
            echo -e "${CYAN}📦 Installing VerusCoin miner...${NC}"
            if command -v verus-miner &> /dev/null; then
                echo -e "${GREEN}✅ verus-miner already installed${NC}"
                return 0
            fi
            # Download verus-miner
            wget -q https://github.com/VerusCoin/VerusCoin/releases/latest/download/verus-miner-ubuntu-20.04.tar.gz -O /tmp/verus-miner.tar.gz
            tar -xzf /tmp/verus-miner.tar.gz -C /tmp/
            sudo mv /tmp/verus-miner /usr/local/bin/ 2>/dev/null || mv /tmp/verus-miner .
            chmod +x verus-miner 2>/dev/null || sudo chmod +x /usr/local/bin/verus-miner
            echo -e "${GREEN}✅ VerusCoin miner installed${NC}"
            ;;
        *)
            echo -e "${RED}❌ Unknown crypto: $crypto${NC}"
            return 1
            ;;
    esac
}

# Start mining
start_mining() {
    local crypto="$1"
    local wallet="$2"
    local threads="$3"
    
    case "$crypto" in
        "xmr")
            echo -e "${GREEN}⛏️ Starting Monero mining...${NC}"
            xmrig -o "$MINING_POOL" -u "$wallet" -t "$threads" --donate-level=1
            ;;
        "ltc")
            echo -e "${GREEN}⛏️ Starting Litecoin mining...${NC}"
            cpuminer -a scrypt -o "$MINING_POOL" -u "$wallet" -t "$threads"
            ;;
        "doge")
            echo -e "${GREEN}⛏️ Starting Dogecoin mining...${NC}"
            cpuminer -a scrypt -o "$MINING_POOL" -u "$wallet" -t "$threads"
            ;;
        "rvn")
            echo -e "${GREEN}⛏️ Starting Ravencoin mining...${NC}"
            kawpowminer -P "$MINING_POOL" -u "$wallet" -t "$threads"
            ;;
        "vrsc")
            echo -e "${GREEN}⛏️ Starting VerusCoin mining...${NC}"
            verus-miner -o "$MINING_POOL" -u "$wallet" -t "$threads"
            ;;
        *)
            echo -e "${RED}❌ Unknown crypto: $crypto${NC}"
            return 1
            ;;
    esac
}

# Check mining status
check_status() {
    local crypto="$1"
    local log_file="$LOG_DIR/mining.log"
    
    if [ -f "$log_file" ]; then
        local last_line=$(tail -1 "$log_file")
        echo -e "${CYAN}📊 Last mining status:${NC} $last_line"
    else
        echo -e "${YELLOW}⏳ No mining data yet${NC}"
    fi
}

# Show mining stats
show_stats() {
    local crypto="$1"
    local log_file="$LOG_DIR/mining.log"
    
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📊 MINING STATISTICS${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    
    if [ -f "$log_file" ]; then
        local total_hashes=$(grep -c "accepted" "$log_file" 2>/dev/null || echo 0)
        local total_shares=$(grep -c "share" "$log_file" 2>/dev/null || echo 0)
        echo -e "Total accepted hashes: ${GREEN}$total_hashes${NC}"
        echo -e "Total shares: ${GREEN}$total_shares${NC}"
        
        # Calculate average hashrate
        local hashrate=$(grep "hashrate" "$log_file" | tail -1 | grep -o '[0-9.]*' | head -1)
        if [ -n "$hashrate" ]; then
            echo -e "Current hashrate: ${GREEN}${hashrate} H/s${NC}"
        fi
    else
        echo -e "${YELLOW}No mining data yet${NC}"
    fi
}

# ============================================================
# 🚀 MAIN SCRIPT
# ============================================================

show_banner

# Check wallet address
if [ "$WALLET_ADDRESS" = "YOUR_WALLET_ADDRESS_HERE" ]; then
    echo -e "${RED}⚠️  Please set your wallet address in the script!${NC}"
    echo -e "${YELLOW}Edit line 38: WALLET_ADDRESS=\"YOUR_ADDRESS\"${NC}"
    echo ""
    read -p "Enter your wallet address now: " WALLET_ADDRESS
fi

# Show menu
echo -e "${CYAN}📋 MENU${NC}"
echo -e "${GREEN}[1] Start Mining${NC}"
echo -e "${GREEN}[2] Stop Mining${NC}"
echo -e "${GREEN}[3] Check Status${NC}"
echo -e "${GREEN}[4] Show Stats${NC}"
echo -e "${GREEN}[5] Install Miner${NC}"
echo -e "${GREEN}[6] View Logs${NC}"
echo -e "${GREEN}[7] Change Settings${NC}"
echo -e "${GREEN}[8] Exit${NC}"
echo ""

read -p "Choose (1-8): " CHOICE

case $CHOICE in
    1)
        echo -e "${CYAN}⛏️ Starting miner...${NC}"
        install_miner "$CRYPTO_CHOICE"
        start_mining "$CRYPTO_CHOICE" "$WALLET_ADDRESS" "$THREADS" | tee -a "$LOG_DIR/mining.log"
        ;;
    2)
        echo -e "${YELLOW}⏹️ Stopping miner...${NC}"
        pkill -f "xmrig|cpuminer|kawpowminer|verus-miner" 2>/dev/null
        echo -e "${GREEN}✅ Miner stopped${NC}"
        ;;
    3)
        check_status "$CRYPTO_CHOICE"
        ;;
    4)
        show_stats "$CRYPTO_CHOICE"
        ;;
    5)
        install_miner "$CRYPTO_CHOICE"
        ;;
    6)
        if [ -f "$LOG_DIR/mining.log" ]; then
            tail -50 "$LOG_DIR/mining.log"
        else
            echo -e "${YELLOW}No logs yet${NC}"
        fi
        ;;
    7)
        read -p "New wallet address: " WALLET_ADDRESS
        read -p "New crypto (xmr/ltc/doge/rvn/vrsc): " CRYPTO_CHOICE
        echo -e "${GREEN}✅ Settings updated${NC}"
        ;;
    8)
        echo -e "${GREEN}Bye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        ;;
esac

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To stop: Ctrl+C
# View logs: tail -f ~/.marduk_rig/mining.log
# 
# ============================================================
