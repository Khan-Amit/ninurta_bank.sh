#!/bin/bash
# ============================================================
# WALLET SETUP - Get your Monero wallet address
# ============================================================

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}           💰 MONERO WALLET SETUP${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Choose how to get a Monero wallet:${NC}"
echo ""
echo -e "${GREEN}[1] Use Exchange Wallet (Easy)${NC}"
echo -e "   • Binance, KuCoin, Bitkub"
echo -e "   • Copy your deposit address"
echo ""
echo -e "${GREEN}[2] Download Monero Wallet (Recommended)${NC}"
echo -e "   • https://www.getmonero.org/downloads/"
echo -e "   • Create new wallet"
echo -e "   • Copy address"
echo ""
echo -e "${GREEN}[3] Create Online Wallet${NC}"
echo -e "   • https://www.mymonero.com/"
echo -e "   • Sign up"
echo -e "   • Get address"
echo ""
echo -e "${GREEN}[4] Use MyMonero App${NC}"
echo -e "   • Download from Play Store"
echo -e "   • Create wallet"
echo -e "   • Copy address"
echo ""

read -p "Which option did you use? (1-4): " OPTION

case $OPTION in
    1)
        echo -e "${CYAN}📱 Using Exchange Wallet:${NC}"
        echo -e "1. Log into your exchange"
        echo -e "2. Go to 'Deposit'"
        echo -e "3. Select Monero (XMR)"
        echo -e "4. Copy the deposit address"
        echo -e "5. It starts with '4' or '8'"
        ;;
    2)
        echo -e "${CYAN}💻 Downloading Monero Wallet:${NC}"
        echo -e "1. Go to: https://www.getmonero.org/downloads/"
        echo -e "2. Download for your OS"
        echo -e "3. Install and create wallet"
        echo -e "4. Copy the primary address"
        ;;
    3)
        echo -e "${CYAN}🌐 Online Wallet:${NC}"
        echo -e "1. Go to: https://www.mymonero.com/"
        echo -e "2. Sign up or create wallet"
        echo -e "3. Copy your address"
        ;;
    4)
        echo -e "${CYAN}📱 MyMonero App:${NC}"
        echo -e "1. Download from Play Store"
        echo -e "2. Create new wallet"
        echo -e "3. Copy your address"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Enter your Monero wallet address:${NC}"
read -r WALLET_ADDRESS

if [ -n "$WALLET_ADDRESS" ]; then
    echo ""
    echo -e "${GREEN}✅ Wallet address saved!${NC}"
    echo -e "${CYAN}Address:${NC} $WALLET_ADDRESS"
    echo ""
    echo -e "${YELLOW}Now edit phone_miner.sh and set:${NC}"
    echo -e "   WALLET_ADDRESS=\"$WALLET_ADDRESS\""
else
    echo -e "${RED}No address entered.${NC}"
fi
