#!/bin/bash
# MARDUK ATM - Universal Crypto to Bank Transfer Protocol
# "No Swift. No Middlemen. Just Value."

BTC_ADDR="bc1qk7ajtrgplvn25600wm7gx9u5c5nk8kz9dfpcqy"
CONFIG_DIR="$HOME/.marduk_atm"
mkdir -p "$CONFIG_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

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

source "$CONFIG_DIR/user.conf"

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

get_btc_balance() {
    BAL=$(curl -s "https://blockchain.info/q/addressbalance/$BTC_ADDR" 2>/dev/null)
    echo "${BAL:-0}"
}

get_btc_rate() {
    local curr_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    RATE=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=$curr_lower" 2>/dev/null | grep -oP '(?<='$curr_lower'":)[0-9.]+')
    case $1 in
        "THB") echo "${RATE:-1800000}" ;;
        "USD") echo "${RATE:-50000}" ;;
        "EUR") echo "${RATE:-46000}" ;;
        "INR") echo "${RATE:-4200000}" ;;
        "BDT") echo "${RATE:-6000000}" ;;
        "CNY") echo "${RATE:-360000}" ;;
        *) echo "${RATE:-50000}" ;;
    esac
}

generate_qr() {
    qrencode -t ansiutf8 "$1" 2>/dev/null
}

while true; do
    BTC_SAT=$(get_btc_balance)
    BTC_BAL=$(echo "scale=8; $BTC_SAT / 100000000" | bc)
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    🏧 MARDUK ATM 🏧${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}📍 Address:${NC} ${BTC_ADDR:0:40}..."
    echo -e "${GREEN}💰 BTC:${NC} $BTC_BAL BTC"
    echo -e "${YELLOW}🏦 Bank:${NC} $BANK_NAME - $BANK_ACCOUNT"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}[1] Send Crypto → Bank${NC}   [4] Receive Crypto${NC}"
    echo -e "${GREEN}[2] Send Crypto → Crypto${NC}  [5] Refresh Balance${NC}"
    echo -e "${GREEN}[3] Receive Money (QR)${NC}    [6] Exit${NC}"
    echo ""
    read -p "Choose (1-6): " CHOICE
    
    case $CHOICE in
        1)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     SEND CRYPTO → BANK${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo "Supported: THB, USD, EUR, INR, BDT, CNY, GBP, JPY, AUD"
            read -p "Currency: " CUR
            CUR=$(echo "$CUR" | tr '[:lower:]' '[:upper:]')
            [ -z "${CURRENCIES[$CUR]}" ] && echo -e "${RED}Unsupported${NC}" && sleep 2 && continue
            RATE=$(get_btc_rate "$CUR")
            echo -e "${GREEN}Rate: 1 BTC = $RATE $CUR${NC}"
            read -p "Amount in $CUR to send: " AMT
            BTC_NEEDED=$(echo "scale=8; $AMT / $RATE" | bc)
            read -p "Recipient bank name: " RECIPIENT_BANK
            read -p "Recipient account number: " RECIPIENT_ACCOUNT
            echo ""
            echo -e "${YELLOW}Send $AMT $CUR (≈ $BTC_NEEDED BTC) to $RECIPIENT_BANK - $RECIPIENT_ACCOUNT${NC}"
            read -p "Confirm? (y/n): " CONFIRM
            if [ "$CONFIRM" = "y" ]; then
                echo -e "${GREEN}✅ Transfer ID: MARDUK_$(date +%s)${NC}"
                echo "$(date),SEND,$AMT,$CUR,$BTC_NEEDED,$RECIPIENT_BANK,$RECIPIENT_ACCOUNT" >> "$CONFIG_DIR/transactions.log"
            fi
            read -p "Press Enter"
            ;;
        2)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     SEND CRYPTO → CRYPTO${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}Balance: $BTC_BAL BTC${NC}"
            read -p "Amount in BTC: " BTC_SEND
            read -p "Recipient BTC address: " RECIPIENT_ADDR
            echo -e "${YELLOW}Send $BTC_SEND BTC to $RECIPIENT_ADDR${NC}"
            read -p "Confirm? (y/n): " CONFIRM
            if [ "$CONFIRM" = "y" ]; then
                echo -e "${GREEN}✅ Transfer ID: MARDUK_CRYPTO_$(date +%s)${NC}"
                echo "$(date),SEND_CRYPTO,$BTC_SEND,$RECIPIENT_ADDR" >> "$CONFIG_DIR/transactions.log"
                echo -e "${YELLOW}Manually send from your wallet to the address above.${NC}"
            fi
            read -p "Press Enter"
            ;;
        3)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     RECEIVE MONEY (THB)${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            read -p "Amount in THB: " AMT
            generate_qr "https://promptpay.io/${PHONE_NUMBER//[^0-9]/}/$AMT"
            echo -e "${GREEN}Share QR above. You receive ฿$AMT to $BANK_NAME${NC}"
            read -p "Press Enter"
            ;;
        4)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     RECEIVE CRYPTO${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}$BTC_ADDR${NC}"
            generate_qr "$BTC_ADDR"
            read -p "Press Enter"
            ;;
        5)
            echo -e "${GREEN}✅ Refreshed${NC}"
            sleep 1
            ;;
        6)
            echo -e "${GREEN}Bye. Marduk watches.${NC}"
            exit 0
            ;;
    esac
done
