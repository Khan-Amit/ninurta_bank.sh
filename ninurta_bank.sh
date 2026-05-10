#!/bin/bash
# NINURTA BANK ATM - Bitcoin to Thai Baht Bridge
# "A fun game" for imbeciles. A bank bridge for you.

BTC_ADDR="bc1qk7ajtrgplvn25600wm7gx9u5c5nk8kz9dfpcqy"
CONFIG_DIR="$HOME/.ninurta_bank"
mkdir -p "$CONFIG_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

if [ ! -f "$CONFIG_DIR/user.conf" ]; then
    clear
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}     NINURTA BANK — FIRST TIME SETUP${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo ""
    read -p "Your Thai bank name (Kasikorn/SCB/Bangkok Bank): " BANK_NAME
    read -p "Your bank account number: " BANK_ACCOUNT
    read -p "Your phone number (PromptPay): " PHONE_NUMBER
    read -p "Bitkub API Key (optional): " API_KEY
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

get_btc_balance() {
    BAL=$(curl -s "https://blockchain.info/q/addressbalance/$BTC_ADDR" 2>/dev/null)
    echo "${BAL:-0}"
}

get_btc_rate() {
    RATE=$(curl -s "https://api.bitkub.com/api/market/ticker?sym=BTC_THB" 2>/dev/null | grep -oP '"last":\K[0-9.]+')
    echo "${RATE:-1800000}"
}

while true; do
    BTC_SAT=$(get_btc_balance)
    BTC_BAL=$(echo "scale=8; $BTC_SAT / 100000000" | bc)
    BTC_RATE=$(get_btc_rate)
    THB_BAL=$(echo "scale=2; $BTC_BAL * $BTC_RATE" | bc)
    
    clear
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}         NINURTA BANK ATM — ONLINE${NC}"
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📍 Your BTC Address:${NC}"
    echo "   $BTC_ADDR"
    echo ""
    echo -e "${YELLOW}💰 Your Balance:${NC}"
    echo "   BTC: $BTC_BAL"
    echo "   THB: ฿$THB_BAL (rate: ฿$BTC_RATE/BTC)"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════${NC}"
    echo -e "${GREEN}⚡ OPTIONS:${NC}"
    echo "   [1] Refresh Balance"
    echo "   [2] Sell BTC → THB (Guide)"
    echo "   [3] Withdraw THB to Bank (Guide)"
    echo "   [4] Generate PromptPay QR"
    echo "   [5] Exit"
    echo ""
    read -p "Choose (1-5): " CHOICE
    
    case $CHOICE in
        1)
            echo -e "${GREEN}✅ Balance refreshed.${NC}"
            sleep 1
            ;;
        2)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     SELL BTC → THB GUIDE${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${YELLOW}📌 To sell BTC for Thai Baht:${NC}"
            echo "   1. Create account at Bitkub (bitkub.com)"
            echo "   2. Verify your identity"
            echo "   3. Deposit BTC to your Bitkub wallet"
            echo "   4. Go to Trade → BTC/THB → Sell"
            echo "   5. Enter amount at market price"
            echo "   6. THB appears in your Bitkub wallet"
            echo ""
            echo -e "${YELLOW}💡 Your BTC Address for deposit:${NC}"
            echo -e "${GREEN}$BTC_ADDR${NC}"
            echo ""
            read -p "Press Enter to continue"
            ;;
        3)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     WITHDRAW THB TO BANK GUIDE${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${YELLOW}📌 To withdraw THB to your bank:${NC}"
            echo "   1. Log into Bitkub"
            echo "   2. Go to Wallet → THB"
            echo "   3. Click 'Withdraw'"
            echo "   4. Select your bank: $BANK_NAME"
            echo "   5. Enter account: $BANK_ACCOUNT"
            echo "   6. Enter amount and confirm"
            echo "   7. Money arrives in 1-2 business days"
            echo ""
            read -p "Press Enter to continue"
            ;;
        4)
            clear
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     GENERATE PROMPTPAY QR${NC}"
            echo -e "${BLUE}════════════════════════════════════════════${NC}"
            echo ""
            read -p "Enter amount in THB: " AMT
            echo ""
            echo -e "${GREEN}💰 QR Code for ฿$AMT${NC}"
            echo ""
            qrencode -t ansiutf8 "https://promptpay.io/${PHONE_NUMBER//[^0-9]/}/$AMT" 2>/dev/null
            echo ""
            echo -e "${YELLOW}Share this QR with buyer.${NC}"
            echo -e "${GREEN}They scan → pay → money to your bank ($BANK_NAME)${NC}"
            read -p "Press Enter to continue"
            ;;
        5)
            echo -e "${GREEN}Bye. Marduk watches.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            sleep 1
            ;;
    esac
done
