#!/bin/bash
# ============================================================
# MARDUK ATM - Universal Crypto to Bank Transfer Protocol
# "No Swift. No Middlemen. Just Value."
# ============================================================
# 
# 🔧 WHAT TO CHANGE:
# 
# 1. BTC_ADDR (line 32) - Change to your Bitcoin address
# 2. CRYPTO_TYPE (line 34) - Change to: BTC, XMR, LTC, DOGE, DEMO
# 3. CURRENCIES array (line 73-83) - Add/remove supported currencies
# 4. API endpoints (line 95-108) - Change if using different price sources
# 
# ============================================================

# ============================================================
# 🛠️ USER SETTINGS - Change these as needed
# ============================================================

BTC_ADDR="bc1qk7ajtrgplvn25600wm7gx9u5c5nk8kz9dfpcqy"  # Your wallet address
CRYPTO_TYPE="BTC"                                      # BTC, XMR, LTC, DOGE, DEMO
CONFIG_DIR="$HOME/.marduk_atm"
mkdir -p "$CONFIG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================
# 📋 FIRST TIME SETUP
# ============================================================

if [ ! -f "$CONFIG_DIR/user.conf" ]; then
    clear
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}     MARDUK ATM — FIRST TIME SETUP${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo ""
    read -p "Your Thai bank name (Kasikorn/SCB/Bangkok Bank): " BANK_NAME
    read -p "Your bank account number: " BANK_ACCOUNT
    read -p "Your phone number (PromptPay): " PHONE_NUMBER
    read -p "Bitkub API Key (optional, leave empty): " API_KEY
    read -p "Bitkub API Secret (optional): " API_SECRET
    cat > "$CONFIG_DIR/user.conf" << EOF
BANK_NAME="$BANK_NAME"
BANK_ACCOUNT="$BANK_ACCOUNT"
PHONE_NUMBER="$PHONE_NUMBER"
API_KEY="$API_KEY"
API_SECRET="$API_SECRET"
EOF
    echo -e "${GREEN}✅ Setup complete!${NC}"
    sleep 2
fi

# Load user configuration
source "$CONFIG_DIR/user.conf" 2>/dev/null || {
    echo -e "${RED}⚠️  Config file corrupted. Please delete $CONFIG_DIR/user.conf and restart.${NC}"
    exit 1
}

# ============================================================
# 💱 CURRENCY CONFIGURATION
# ============================================================

declare -A CURRENCIES=(
    ["THB"]="Thai Baht|thb|1800000"
    ["USD"]="US Dollar|usd|50000"
    ["EUR"]="Euro|eur|46000"
    ["INR"]="Indian Rupee|inr|4200000"
    ["BDT"]="Bangladeshi Taka|bdt|6000000"
    ["CNY"]="Chinese Yuan|cny|360000"
    ["GBP"]="British Pound|gbp|40000"
    ["JPY"]="Japanese Yen|jpy|7500000"
    ["AUD"]="Australian Dollar|aud|75000"
    ["SGD"]="Singapore Dollar|sgd|67000"
    ["MYR"]="Malaysian Ringgit|myr|235000"
    ["IDR"]="Indonesian Rupiah|idr|800000000"
    ["PHP"]="Philippine Peso|php|2900000"
    ["VND"]="Vietnamese Dong|vnd|1270000000"
)

# ============================================================
# 📡 FUNCTIONS
# ============================================================

# Get crypto balance (supports multiple cryptos)
get_crypto_balance() {
    local addr="$1"
    local type="${2:-BTC}"
    
    case "$type" in
        "BTC")
            BAL=$(curl -s "https://blockchain.info/q/addressbalance/$addr" 2>/dev/null)
            echo "${BAL:-0}"
            ;;
        "XMR")
            # Monero balance check (requires monero-wallet-rpc)
            # For now, fallback to BTC
            BAL=$(curl -s "https://blockchain.info/q/addressbalance/$addr" 2>/dev/null)
            echo "${BAL:-0}"
            ;;
        "LTC")
            BAL=$(curl -s "https://chain.so/api/v2/get_address_balance/LTC/$addr" 2>/dev/null | grep -oP '"confirmed_balance":"\K[0-9.]+')
            echo "${BAL:-0}"
            ;;
        "DOGE")
            BAL=$(curl -s "https://chain.so/api/v2/get_address_balance/DOGE/$addr" 2>/dev/null | grep -oP '"confirmed_balance":"\K[0-9.]+')
            echo "${BAL:-0}"
            ;;
        "DEMO")
            echo $((RANDOM % 100000000))
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get crypto to fiat rate
get_crypto_rate() {
    local curr="$1"
    local curr_lower=$(echo "$curr" | tr '[:upper:]' '[:lower:]')
    
    # Try to get real rate from API
    local RATE=""
    RATE=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=$curr_lower" 2>/dev/null | grep -oP '(?<='$curr_lower'":)[0-9.]+')
    
    # If API fails, use fallback rates
    if [ -z "$RATE" ] || [ "$RATE" = "null" ]; then
        # Extract fallback from CURRENCIES array
        local entry="${CURRENCIES[$curr]}"
        RATE=$(echo "$entry" | cut -d'|' -f3)
        echo "${RATE:-50000}"
    else
        echo "$RATE"
    fi
}

# Generate QR code
generate_qr() {
    if command -v qrencode &> /dev/null; then
        qrencode -t ansiutf8 "$1" 2>/dev/null
    else
        echo -e "${YELLOW}⚠️  Install qrencode for QR support: sudo apt install qrencode${NC}"
        echo "$1"
    fi
}

# Validate Bitcoin address
validate_address() {
    local addr="$1"
    # Simple validation - check length and format
    if [[ "$addr" =~ ^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$ ]] || [[ "$addr" =~ ^bc1[a-zA-HJ-NP-Z0-9]{39,59}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Log transaction
log_transaction() {
    local type="$1"
    local amount="$2"
    local currency="$3"
    local details="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] $type | $amount $currency | $details" >> "$CONFIG_DIR/transactions.log"
}

# Display header
show_header() {
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    🏧 MARDUK ATM 🏧${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

# ============================================================
# 🚀 MAIN MENU
# ============================================================

# Initialize
BTC_SAT=$(get_crypto_balance "$BTC_ADDR" "$CRYPTO_TYPE")
BTC_BAL=$(echo "scale=8; $BTC_SAT / 100000000" | bc 2>/dev/null || echo "0.00000000")

while true; do
    # Refresh balance
    BTC_SAT=$(get_crypto_balance "$BTC_ADDR" "$CRYPTO_TYPE")
    BTC_BAL=$(echo "scale=8; $BTC_SAT / 100000000" | bc 2>/dev/null || echo "0.00000000")
    
    show_header
    echo -e "${CYAN}📍 Address:${NC} ${BTC_ADDR:0:40}..."
    echo -e "${GREEN}💰 ${CRYPTO_TYPE}:${NC} $BTC_BAL $CRYPTO_TYPE"
    echo -e "${YELLOW}🏦 Bank:${NC} $BANK_NAME - $BANK_ACCOUNT"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}[1] Send Crypto → Bank${NC}   [4] Receive Crypto${NC}"
    echo -e "${GREEN}[2] Send Crypto → Crypto${NC}  [5] Refresh Balance${NC}"
    echo -e "${GREEN}[3] Receive Money (QR)${NC}    [6] Settings${NC}"
    echo -e "${GREEN}[7] Transaction History${NC}   [8] Exit${NC}"
    echo ""
    read -p "Choose (1-8): " CHOICE
    
    case $CHOICE in
        1)
            # Send Crypto → Bank
            show_header
            echo -e "${GREEN}     SEND CRYPTO → BANK${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}Balance: $BTC_BAL $CRYPTO_TYPE${NC}"
            echo "Supported: THB, USD, EUR, INR, BDT, CNY, GBP, JPY, AUD, SGD, MYR, IDR, PHP, VND"
            echo ""
            read -p "Currency (e.g., THB): " CUR
            CUR=$(echo "$CUR" | tr '[:lower:]' '[:upper:]')
            
            if [ -z "${CURRENCIES[$CUR]}" ]; then
                echo -e "${RED}⚠️  Unsupported currency${NC}"
                sleep 2
                continue
            fi
            
            RATE=$(get_crypto_rate "$CUR")
            echo -e "${GREEN}Rate: 1 $CRYPTO_TYPE = $RATE $CUR${NC}"
            
            read -p "Amount in $CUR to send: " AMT
            BTC_NEEDED=$(echo "scale=8; $AMT / $RATE" | bc 2>/dev/null)
            echo -e "${YELLOW}Need ≈ $BTC_NEEDED $CRYPTO_TYPE${NC}"
            
            read -p "Recipient bank name: " RECIPIENT_BANK
            read -p "Recipient account number: " RECIPIENT_ACCOUNT
            echo ""
            echo -e "${YELLOW}📤 Send $AMT $CUR (≈ $BTC_NEEDED $CRYPTO_TYPE)${NC}"
            echo -e "${YELLOW}🏦 To: $RECIPIENT_BANK - $RECIPIENT_ACCOUNT${NC}"
            read -p "Confirm? (y/n): " CONFIRM
            
            if [ "$CONFIRM" = "y" ]; then
                local tx_id="MARDUK_$(date +%s)_$RANDOM"
                echo -e "${GREEN}✅ Transfer ID: $tx_id${NC}"
                log_transaction "SEND_TO_BANK" "$AMT" "$CUR" "$RECIPIENT_BANK-$RECIPIENT_ACCOUNT (≈$BTC_NEEDED BTC)"
                echo -e "${YELLOW}📝 Send $BTC_NEEDED $CRYPTO_TYPE from your wallet to complete.${NC}"
            fi
            read -p "Press Enter"
            ;;
            
        2)
            # Send Crypto → Crypto
            show_header
            echo -e "${GREEN}     SEND CRYPTO → CRYPTO${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}Balance: $BTC_BAL $CRYPTO_TYPE${NC}"
            read -p "Amount in $CRYPTO_TYPE: " BTC_SEND
            
            if (( $(echo "$BTC_SEND > $BTC_BAL" | bc -l) )); then
                echo -e "${RED}⚠️  Insufficient balance${NC}"
                sleep 2
                continue
            fi
            
            read -p "Recipient crypto address: " RECIPIENT_ADDR
            
            if ! validate_address "$RECIPIENT_ADDR"; then
                echo -e "${RED}⚠️  Invalid address format${NC}"
                sleep 2
                continue
            fi
            
            echo -e "${YELLOW}📤 Send $BTC_SEND $CRYPTO_TYPE to${NC}"
            echo -e "${CYAN}$RECIPIENT_ADDR${NC}"
            read -p "Confirm? (y/n): " CONFIRM
            
            if [ "$CONFIRM" = "y" ]; then
                local tx_id="MARDUK_CRYPTO_$(date +%s)_$RANDOM"
                echo -e "${GREEN}✅ Transfer ID: $tx_id${NC}"
                log_transaction "SEND_CRYPTO" "$BTC_SEND" "$CRYPTO_TYPE" "$RECIPIENT_ADDR"
                echo -e "${YELLOW}🔗 Please send from your wallet manually.${NC}"
            fi
            read -p "Press Enter"
            ;;
            
        3)
            # Receive Money (QR)
            show_header
            echo -e "${GREEN}     RECEIVE MONEY (THB)${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            
            # Clean phone number
            CLEAN_PHONE=$(echo "$PHONE_NUMBER" | tr -d '[:space:]-+')
            
            if [ -z "$CLEAN_PHONE" ]; then
                echo -e "${RED}⚠️  No phone number configured. Please re-run setup.${NC}"
                sleep 2
                continue
            fi
            
            read -p "Amount in THB (leave empty for any): " AMT
            if [ -z "$AMT" ]; then
                QR_URL="https://promptpay.io/$CLEAN_PHONE"
            else
                QR_URL="https://promptpay.io/$CLEAN_PHONE/$AMT"
            fi
            
            echo -e "${CYAN}📱 PromptPay QR Code:${NC}"
            generate_qr "$QR_URL"
            echo ""
            echo -e "${GREEN}💰 You receive ฿${AMT:-any amount} to $BANK_NAME${NC}"
            log_transaction "RECEIVE_THB" "${AMT:-0}" "THB" "$PHONE_NUMBER"
            read -p "Press Enter"
            ;;
            
        4)
            # Receive Crypto
            show_header
            echo -e "${GREEN}     RECEIVE $CRYPTO_TYPE${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}📬 Your $CRYPTO_TYPE address:${NC}"
            echo -e "${GREEN}$BTC_ADDR${NC}"
            echo ""
            generate_qr "$BTC_ADDR"
            echo ""
            log_transaction "RECEIVE_CRYPTO" "0" "$CRYPTO_TYPE" "$BTC_ADDR"
            read -p "Press Enter"
            ;;
            
        5)
            # Refresh Balance
            echo -e "${GREEN}✅ Refreshed!${NC}"
            sleep 1
            ;;
            
        6)
            # Settings
            show_header
            echo -e "${GREEN}     SETTINGS${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "Bank: ${YELLOW}$BANK_NAME${NC}"
            echo -e "Account: ${YELLOW}$BANK_ACCOUNT${NC}"
            echo -e "Phone: ${YELLOW}$PHONE_NUMBER${NC}"
            echo -e "Crypto: ${YELLOW}$CRYPTO_TYPE${NC}"
            echo -e "Address: ${CYAN}${BTC_ADDR:0:40}...${NC}"
            echo ""
            echo -e "${YELLOW}[1] Change Bank Details${NC}"
            echo -e "${YELLOW}[2] Change Crypto Address${NC}"
            echo -e "${YELLOW}[3] Reset Everything${NC}"
            echo -e "${YELLOW}[4] Back${NC}"
            read -p "Choose: " SETTING_CHOICE
            
            case $SETTING_CHOICE in
                1)
                    read -p "New bank name: " BANK_NAME
                    read -p "New account number: " BANK_ACCOUNT
                    read -p "New phone number: " PHONE_NUMBER
                    # Update config
                    sed -i "s/BANK_NAME=.*/BANK_NAME=\"$BANK_NAME\"/" "$CONFIG_DIR/user.conf"
                    sed -i "s/BANK_ACCOUNT=.*/BANK_ACCOUNT=\"$BANK_ACCOUNT\"/" "$CONFIG_DIR/user.conf"
                    sed -i "s/PHONE_NUMBER=.*/PHONE_NUMBER=\"$PHONE_NUMBER\"/" "$CONFIG_DIR/user.conf"
                    echo -e "${GREEN}✅ Updated!${NC}"
                    sleep 2
                    ;;
                2)
                    read -p "New crypto address: " BTC_ADDR
                    if validate_address "$BTC_ADDR"; then
                        sed -i "s/BTC_ADDR=.*/BTC_ADDR=\"$BTC_ADDR\"/" "$0"
                        echo -e "${GREEN}✅ Address updated!${NC}"
                    else
                        echo -e "${RED}⚠️  Invalid address format${NC}"
                    fi
                    sleep 2
                    ;;
                3)
                    read -p "Reset all settings? (y/n): " CONFIRM
                    if [ "$CONFIRM" = "y" ]; then
                        rm -rf "$CONFIG_DIR"
                        echo -e "${YELLOW}✅ Reset complete. Please restart.${NC}"
                        exit 0
                    fi
                    ;;
            esac
            ;;
            
        7)
            # Transaction History
            show_header
            echo -e "${GREEN}     TRANSACTION HISTORY${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            if [ -f "$CONFIG_DIR/transactions.log" ]; then
                tail -20 "$CONFIG_DIR/transactions.log" | nl
            else
                echo -e "${YELLOW}No transactions yet.${NC}"
            fi
            echo ""
            read -p "Press Enter"
            ;;
            
        8)
            # Exit
            echo -e "${GREEN}Bye. Marduk watches.${NC}"
            exit 0
            ;;
            
        *)
            echo -e "${RED}⚠️  Invalid choice${NC}"
            sleep 1
            ;;
    esac
done

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To stop: Press Ctrl+C
# 
# View logs:
#   cat ~/.marduk_atm/transactions.log
#   tail -f ~/.marduk_atm/transactions.log
# 
# Configuration:
#   ~/.marduk_atm/user.conf
# 
# ============================================================
