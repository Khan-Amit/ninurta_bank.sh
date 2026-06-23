#!/bin/bash
# ============================================================
# 📱 PHONE MINING EXPERIMENT - Real Monero Mining on Android
# "For science! And maybe 0.000000001 XMR!"
# ============================================================
# 
# 🔧 WHAT TO REPLACE:
# 
# 1. YOUR_WALLET_ADDRESS (line 32) - Get from Monero wallet
# 2. MINING_POOL (line 33) - Use pool.supportxmr.com:3333
# 3. THREADS (line 34) - Set to 1 (phone CPU)
# 
# ============================================================

# ============================================================
# 🛠️ USER SETTINGS - CHANGE THESE!
# ============================================================

# Get your Monero wallet address from:
# - Monero wallet app
# - Exchange (Binance, KuCoin, Bitkub)
WALLET_ADDRESS="YOUR_WALLET_ADDRESS_HERE"  # ⚠️ REPLACE THIS!

# Mining pool (use the public pool)
POOL="pool.supportxmr.com:3333"

# Number of CPU threads (keep at 1 for phone)
THREADS=1

# ============================================================
# 🧠 SYSTEM SETUP
# ============================================================

LOG_DIR="$HOME/phone_mining_logs"
mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Log files
MINING_LOG="$LOG_DIR/mining.log"
EARNINGS_LOG="$LOG_DIR/earnings.log"
STATS_LOG="$LOG_DIR/stats.log"
TEMP_LOG="$LOG_DIR/temperature.log"

# ============================================================
# 📡 FUNCTIONS
# ============================================================

# Show banner
show_banner() {
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}           📱 PHONE MINING EXPERIMENT${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📤 Wallet:${NC} ${WALLET_ADDRESS:0:20}..."
    echo -e "${YELLOW}⛏️  Pool:${NC} $POOL"
    echo -e "${YELLOW}💻 Threads:${NC} $THREADS"
    echo -e "${YELLOW}📁 Logs:${NC} $LOG_DIR"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}⚠️  IMPORTANT:${NC}"
    echo -e "   • Keep phone plugged in!"
    echo -e "   • Phone will get warm (40-50°C)"
    echo -e "   • Battery will drain fast"
    echo -e "   • Earnings will be tiny (0.000000001 XMR)"
    echo -e "   • This is for SCIENCE! 🔬"
    echo ""
    echo -e "${YELLOW}Press Enter to start mining...${NC}"
    read -r
}

# Check if wallet address is set
check_wallet() {
    if [ "$WALLET_ADDRESS" = "YOUR_WALLET_ADDRESS_HERE" ]; then
        echo -e "${RED}❌ ERROR: Please set your wallet address!${NC}"
        echo -e "${YELLOW}Edit line 32 in the script:${NC}"
        echo -e "   WALLET_ADDRESS=\"YOUR_MONERO_WALLET_ADDRESS\""
        echo ""
        echo -e "${CYAN}How to get a Monero wallet:${NC}"
        echo -e "   1. Download Monero wallet app"
        echo -e "   2. Or use exchange wallet (Binance/KuCoin)"
        echo -e "   3. Or create at: https://www.mymonero.com/"
        echo ""
        exit 1
    fi
}

# Install xmrig if not installed
install_miner() {
    echo -e "${CYAN}📦 Checking for xmrig miner...${NC}"
    
    if command -v xmrig &> /dev/null; then
        echo -e "${GREEN}✅ xmrig already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}⚠️  xmrig not found. Installing...${NC}"
    
    # Check if we're on Android (Termux)
    if [ -d "/data/data/com.termux" ] || [ -n "$TERMUX_VERSION" ]; then
        echo -e "${CYAN}📱 Detected Termux environment${NC}"
        pkg update -y
        pkg install -y git cmake make gcc
        pkg install -y libuv-dev
    else
        echo -e "${CYAN}💻 Detected Linux/Desktop environment${NC}"
        sudo apt update -y
        sudo apt install -y git cmake make g++
        sudo apt install -y libuv1-dev
    fi
    
    # Clone and build xmrig
    echo -e "${CYAN}🔨 Building xmrig from source...${NC}"
    cd "$HOME" || exit 1
    rm -rf xmrig 2>/dev/null
    git clone https://github.com/xmrig/xmrig.git
    cd xmrig || exit 1
    mkdir -p build
    cd build || exit 1
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(nproc 2>/dev/null || echo 2)
    
    # Install
    if [ -d "/data/data/com.termux" ] || [ -n "$TERMUX_VERSION" ]; then
        # Termux - install to local
        cp xmrig "$HOME/../usr/bin/" 2>/dev/null || cp xmrig "$HOME/bin/"
    else
        sudo cp xmrig /usr/local/bin/
    fi
    
    echo -e "${GREEN}✅ xmrig installed successfully!${NC}"
}

# Get phone temperature (Android)
get_temperature() {
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        TEMP_C=$((TEMP / 1000))
        echo "$TEMP_C"
    else
        echo "Unknown"
    fi
}

# Get battery level (Android)
get_battery() {
    if [ -f "/sys/class/power_supply/battery/capacity" ]; then
        BAT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        echo "$BAT"
    else
        echo "Unknown"
    fi
}

# Log mining stats
log_stats() {
    local hashrate="$1"
    local shares="$2"
    local earnings="$3"
    local temp=$(get_temperature)
    local battery=$(get_battery)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp,$hashrate,$shares,$earnings,$temp,$battery" >> "$STATS_LOG"
}

# Monitor mining progress
monitor_mining() {
    echo -e "${CYAN}📊 Monitoring mining progress...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
    
    # Show initial stats
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                    MINING STATUS                      │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC}  ⏰ Time: $(date '+%H:%M:%S')"
    echo -e "${BLUE}│${NC}  🔥 Temperature: $(get_temperature)°C"
    echo -e "${BLUE}│${NC}  🔋 Battery: $(get_battery)%"
    echo -e "${BLUE}│${NC}  ⛏️  Status: Mining..."
    echo -e "${BLUE}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ============================================================
# 🚀 MAIN MINING SCRIPT
# ============================================================

# Show banner
show_banner

# Check wallet
check_wallet

# Install miner
install_miner

# Create config file for xmrig
cat > "$HOME/xmrig-config.json" << EOF
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "huge-pages": false,
        "max-threads-hint": 20
    },
    "pools": [
        {
            "url": "$POOL",
            "user": "$WALLET_ADDRESS",
            "pass": "phone_miner",
            "tls": false
        }
    ],
    "print-time": 10
}
EOF

echo -e "${GREEN}✅ Configuration created${NC}"
echo ""

# Start mining
echo -e "${GREEN}⛏️ Starting mining...${NC}"
echo -e "${YELLOW}📊 Watch the terminal for real mining data!${NC}"
echo ""

# Start monitoring in background
monitor_mining &

# Start xmrig
cd "$HOME/xmrig/build" || cd "$HOME/xmrig" || exit 1

# Run xmrig
if command -v xmrig &> /dev/null; then
    xmrig -c "$HOME/xmrig-config.json"
else
    ./xmrig -c "$HOME/xmrig-config.json"
fi

# ============================================================
# 🚨 CLEANUP
# ============================================================

# This runs when you press Ctrl+C
cleanup() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}📱 PHONE MINING EXPERIMENT - RESULTS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Show final stats
    if [ -f "$STATS_LOG" ]; then
        echo -e "${CYAN}📊 Mining Statistics:${NC}"
        echo ""
        echo -e "${GREEN}Total mining time:${NC} $(ps -o etime= -p $$ 2>/dev/null || echo 'Unknown')"
        
        # Calculate average hashrate
        local avg_hash=$(tail -20 "$STATS_LOG" | awk -F',' '{sum+=$2; count++} END {print sum/count}')
        if [ -n "$avg_hash" ]; then
            echo -e "${GREEN}Average hashrate:${NC} ${avg_hash} H/s"
        fi
        
        # Count shares
        local shares=$(tail -20 "$STATS_LOG" | awk -F',' '{sum+=$3} END {print sum}')
        echo -e "${GREEN}Total shares:${NC} ${shares:-0}"
        
        # Show final earnings
        local earnings=$(tail -1 "$STATS_LOG" | cut -d',' -f4)
        if [ -n "$earnings" ]; then
            echo -e "${GREEN}Estimated earnings:${NC} ${earnings} XMR"
            echo -e "${YELLOW}Value:${NC} ~$0.0000000002 USD"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}📁 Logs saved to:${NC} $LOG_DIR"
    echo -e "${BLUE}📄 Stats log:${NC} $STATS_LOG"
    echo -e "${BLUE}📄 Earnings log:${NC} $EARNINGS_LOG"
    echo ""
    echo -e "${PURPLE}💡 CONCLUSIONS:${NC}"
    echo -e "   • Phone mining is ${RED}NOT PROFITABLE${NC}"
    echo -e "   • Phone got warm (${YELLOW}$(get_temperature)°C${NC})"
    echo -e "   • Battery drained ${RED}FAST${NC}"
    echo -e "   • But you learned a lot! 🎓"
    echo ""
    echo -e "${GREEN}Thanks for experimenting! 🔬${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT SIGTERM

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To use this script:
# 
# 1. Save as phone_miner.sh
# 2. Replace WALLET_ADDRESS with your Monero address
# 3. Run: bash phone_miner.sh
# 4. Wait 24 hours
# 5. Check results!
# 
# ============================================================
