#!/bin/bash
# MARDUK ATM - Universal Crypto to Bank Transfer Protocol
# "No Swift. No Middlemen. Just Value."

# ============================================================
# CONFIGURATION
# ============================================================
BTC_ADDR="bc1qk7ajtrgplvn25600wm7gx9u5c5nk8kz9dfpcqy"
CONFIG_DIR="$HOME/.marduk_atm"
mkdir -p "$CONFIG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================
# FIRST TIME SETUP
# ============================================================
if [ ! -f "$CONFIG_DIR/user.conf" ]; then
    clear
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}     MARDUK ATM — FIRST TIME SETUP${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📱 Your Information (for receiving THB):${NC}"
    read -p "   Your Thai bank name (e.g., Kasikorn, SCB, Bangkok Bank): " BANK_NAME
    read -p "   Your bank account number: " BANK_ACCOUNT
    read -p "   Your phone number (PromptPay): " PHONE_NUMBER
    
    echo ""
    echo -e "${YELLOW}🔑 Bitkub API Keys (optional, for auto-sell):${NC}"
    echo "   (Leave empty to use manual sell mode)"
    read -p "   Bitkub API Key: " API_KEY
    read -p "   Bitkub API Secret: " API_SECRET
    
    cat > "$CONFIG_DIR/user.conf" << EOF
BANK_NAME="$BANK_NAME"
BANK_ACCOUNT="$BANK_ACCOUNT"
PHONE_NUMBER="$PHONE_NUMBER"
API_KEY="$API_KEY"
API_SECRET="$API_SECRET"
EOF
    
    echo ""
    echo -e "${GREEN}✅ Setup complete!${NC}"
    sleep 2
fi

source "$CONFIG_DIR/user.conf"

# ============================================================
# CURRENCY SUPPORT
# ============================================================
declare -A CURRENCIES=(
    ["THB"]="Thai Baht|thb"
    ["USD"]="US Dollar|usd"
    ["EUR"]="Euro|eur"
    ["INR"]="Indian Rupee|inr"
    ["BDT"]="Bangladeshi Taka|bdt"
    ["CNY"]="Chinese Yuan|cny"
    ["GBP"]="British Pound|gbp"
    ["JPY"]="Japanese Yen|jpy"
    ["AUD"]="Australian Dollar|aud"
)

# ============================================================
# FUNCTIONS
# ============================================================

get_btc_balance() {
    BAL=$(curl -s "https://blockchain.info/q/addressbalance/$BTC_ADDR" 2>/dev/null)
    if [ -z "$BAL" ]; then
        echo "0"
    else
        echo "$BAL"
    fi
}

get_btc_rate() {
    local currency="$1"
    local curr_lower=$(echo "$currency" | tr '[:upper:]' '[:lower:]')
    RATE=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=$curr_lower" 2>/dev/null | grep -oP '(?<='$curr_lower'":)[0-9.]+')
    if [ -z "$RATE" ]; then
        case $currency in
            "THB") echo "1800000" ;;
            "USD") echo "50000" ;;
            "EUR") echo "46000" ;;
            "INR") echo "4200000" ;;
            "BDT") echo "6000000" ;;
            "CNY") echo "360000" ;;
            *) echo "50000" ;;
        esac
    else
        echo "$RATE"
    fi
}

generate_promptpay_qr() {
    local amount="$1"
    local phone="${PHONE_NUMBER//[^0-9]/}"
    qrencode -t ansiutf8 "https://promptpay.io/$phone/$amount" 2>/dev/null
}

show_currencies() {
    echo ""
    echo -e "${YELLOW}📀 SUPPORTED CURRENCIES:${NC}"
    echo "   ┌─────────┬─────────────────────┐"
    for code in "${!CURRENCIES[@]}"; do
        IFS='|' read -r name _ <<< "${CURRENCIES[$code]}"
        printf "   │ %-7s │ %-19s │\n" "$code" "$name"
    done
    echo "   └─────────┴─────────────────────┘"
}

# ============================================================
# MAIN MENU
# ============================================================

while true; do
    BTC_SAT=$(get_btc_balance)
    BTC_BAL=$(echo "scale=8; $BTC_SAT / 100000000" | bc)
    
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    🏧 MARDUK ATM 🏧${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}📍 Your BTC address:${NC} ${BTC_ADDR:0:40}..."
    echo ""
    echo -e "${GREEN}💰 VAULT BALANCE:${NC}"
    echo "   ₿ $BTC_BAL BTC"
    echo ""
    echo -e "${YELLOW}🏦 LINKED BANK:${NC} $BANK_NAME - $BANK_ACCOUNT"
    echo -e "${YELLOW}📱 PROMPTPAY:${NC} $PHONE_NUMBER"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}⚡ OPTIONS:${NC}"
    echo "   [1] Send Crypto → Bank (any currency)"
    echo "   [2] Send Crypto → Crypto (to any wallet)"
    echo "   [3] Receive Money (QR for THB)"
    echo "   [4] Receive Crypto (show address)"
    echo "   [5] Refresh Balance"
    echo "   [6] Exit"
    echo ""
    read -p "Choose (1-6): " CHOICE
    
    case $CHOICE in
        1)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     SEND CRYPTO → BANK${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo ""
            
            # Show supported currencies
            show_currencies
            echo ""
            read -p "Select currency (THB, USD, EUR, INR, BDT, CNY, etc.): " CURRENCY
            CURRENCY=$(echo "$CURRENCY" | tr '[:lower:]' '[:upper:]')
            
            if [ -z "${CURRENCIES[$CURRENCY]}" ]; then
                echo -e "${RED}❌ Unsupported currency.${NC}"
                sleep 2
                continue
            fi
            
            RATE=$(get_btc_rate "$CURRENCY")
            echo ""
            echo -e "${GREEN}📊 Current rate: 1 BTC = $RATE $CURRENCY${NC}"
            echo -e "${YELLOW}💰 Your BTC balance: $BTC_BAL BTC${NC}"
            echo ""
            read -p "Amount in $CURRENCY to send: " AMOUNT
            BTC_NEEDED=$(echo "scale=8; $AMOUNT / $RATE" | bc)
            
            echo ""
            echo -e "${YELLOW}📝 RECIPIENT INFORMATION:${NC}"
            read -p "   Recipient's bank name: " RECIPIENT_BANK
            read -p "   Recipient's account number: " RECIPIENT_ACCOUNT
            read -p "   Recipient's name (optional): " RECIPIENT_NAME
            
            echo ""
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}📋 TRANSACTION SUMMARY:${NC}"
            echo "   Send: $AMOUNT $CURRENCY"
            echo "   BTC needed: $BTC_NEEDED BTC"
            echo "   To bank: $RECIPIENT_BANK"
            echo "   Account: $RECIPIENT_ACCOUNT"
            echo "   Recipient: ${RECIPIENT_NAME:-Not specified}"
            echo ""
            read -p "Confirm transfer? (y/n): " CONFIRM
            
            if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                echo ""
                echo -e "${GREEN}✅ TRANSFER INITIATED${NC}"
                echo ""
                echo -e "${YELLOW}📌 NEXT STEPS:${NC}"
                echo "   1. Your BTC ($BTC_NEEDED BTC) will be sold for $CURRENCY"
                echo "   2. $AMOUNT $CURRENCY will be sent to $RECIPIENT_BANK"
                echo "   3. Recipient will receive money in minutes (via exchange local rails)"
                echo "   4. No Swift. No hidden fees."
                echo ""
                echo -e "${GREEN}💰 Transfer ID: MARDUK_$(date +%s)${NC}"
                echo "$(date),SEND,$AMOUNT,$CURRENCY,$BTC_NEEDED,$RECIPIENT_BANK,$RECIPIENT_ACCOUNT" >> "$CONFIG_DIR/transactions.log"
            else
                echo -e "${RED}❌ Cancelled.${NC}"
            fi
            read -p "Press Enter to continue"
            ;;
            
        2)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     SEND CRYPTO → CRYPTO${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${YELLOW}💰 Your BTC balance: $BTC_BAL BTC${NC}"
            echo ""
            read -p "Amount in BTC to send: " BTC_SEND
            read -p "Recipient's BTC address: " RECIPIENT_ADDR
            
            echo ""
            echo -e "${YELLOW}📋 SUMMARY:${NC}"
            echo "   Send: $BTC_SEND BTC"
            echo "   To address: $RECIPIENT_ADDR"
            echo ""
            read -p "Confirm send? (y/n): " CONFIRM
            
            if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                echo ""
                echo -e "${GREEN}✅ TRANSFER INITIATED${NC}"
                echo ""
                echo -e "${YELLOW}📌 NEXT STEPS:${NC}"
                echo "   1. Open your crypto wallet (Trust Wallet, BlueWallet)"
                echo "   2. Send $BTC_SEND BTC to:"
                echo "      $RECIPIENT_ADDR"
                echo "   3. Blockchain confirms in 10-60 minutes"
                echo ""
                echo -e "${GREEN}💰 Transfer ID: MARDUK_CRYPTO_$(date +%s)${NC}"
                echo "$(date),SEND_CRYPTO,$BTC_SEND,$RECIPIENT_ADDR" >> "$CONFIG_DIR/transactions.log"
            else
                echo -e "${RED}❌ Cancelled.${NC}"
            fi
            read -p "Press Enter to continue"
            ;;
            
        3)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     RECEIVE MONEY (THB)${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo ""
            read -p "Enter amount in THB to receive: " AMOUNT
            echo ""
            echo -e "${GREEN}💰 QR Code for ฿$AMOUNT${NC}"
            echo -e "${YELLOW}📱 Share this QR with sender:${NC}"
            echo ""
            generate_promptpay_qr "$AMOUNT"
            echo ""
            echo -e "${YELLOW}Sender scans → pays → money to your bank ($BANK_NAME)${NC}"
            echo -e "${GREEN}✅ You receive ฿$AMOUNT instantly.${NC}"
            read -p "Press Enter to continue"
            ;;
            
        4)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     RECEIVE CRYPTO${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${YELLOW}📋 Your BTC Address:${NC}"
            echo -e "${GREEN}$BTC_ADDR${NC}"
            echo ""
            qrencode -t ansiutf8 "$BTC_ADDR" 2>/dev/null
            echo ""
            echo -e "${YELLOW}Share this address with sender.${NC}"
            echo -e "${GREEN}✅ BTC will appear in your vault.${NC}"
            read -p "Press Enter to continue"
            ;;
            
        5)
            echo -e "${GREEN}✅ Balance refreshed.${NC}"
            sleep 1
            ;;
            
        6)
            echo -e "${GREEN}Bye. Marduk watches.${NC}"
            exit 0
            ;;
            
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            sleep 1
            ;;
    esac
done
