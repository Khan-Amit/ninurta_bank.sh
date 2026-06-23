#!/bin/bash
# ============================================================
# NINURTA ATM WITH RIG INTEGRATION
# "Mine. Earn. Withdraw."
# ============================================================

# Add mining wallet to ATM config
add_mining_wallet() {
    local wallet="$1"
    local coin="$2"
    
    echo "MINING_WALLET_$coin=$wallet" >> "$HOME/.marduk_atm/user.conf"
    echo "✅ Added mining wallet for $coin"
}

# Convert mining earnings to BTC
convert_to_btc() {
    local coin="$1"
    local amount="$2"
    
    case "$coin" in
        "xmr")
            # XMR to BTC conversion
            local rate=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=monero&vs_currencies=btc" | grep -oP '(?<="btc":)[0-9.]+')
            echo "$amount * $rate" | bc
            ;;
        "ltc"|"doge")
            local rate=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=${coin}&vs_currencies=btc" | grep -oP '(?<="btc":)[0-9.]+')
            echo "$amount * $rate" | bc
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Check mining earnings
check_mining_earnings() {
    local coin="$1"
    local wallet="$2"
    
    echo -e "${CYAN}🔍 Checking $coin earnings...${NC}"
    
    case "$coin" in
        "xmr")
            curl -s "https://xmrchain.net/api/address/$wallet" | grep -oP '(?<="balance":)[0-9]+' | awk '{print $1/1000000000000}'
            ;;
        "ltc"|"doge")
            curl -s "https://chain.so/api/v2/get_address_balance/$coin/$wallet" | grep -oP '(?<="confirmed_balance":")[0-9.]+'
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Add to main ATM menu
add_mining_menu() {
    echo -e "${PURPLE}[9] Mining Dashboard${NC}"
    echo -e "${PURPLE}[10] Start Mining Rig${NC}"
    echo -e "${PURPLE}[11] Check Mining Earnings${NC}"
    echo -e "${PURPLE}[12] Convert Mining to BTC${NC}"
}

# ============================================================
# 🚀 USAGE
# ============================================================
# 
# Add these functions to ninurta_bank.sh
# Then call add_mining_menu in the main loop
# 
# ============================================================
