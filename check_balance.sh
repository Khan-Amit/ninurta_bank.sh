#!/bin/bash
# ============================================================
# 💰 CHECK YOUR MINING EARNINGS
# ============================================================

XMR_WALLET="44osUR6e9UjePWUQhavLNYTY7JSzwZMN6249AdnjbwmtXtirsjDiGcejCjJkoTst2BGD3NaLrtpzNENsc6AsZ9AGKWTx7YZ"

echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}💰 CHECKING XMR EARNINGS${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""

# Fetch balance
BALANCE=$(curl -s "https://xmrchain.net/api/address/$XMR_WALLET" | grep -oP '(?<="balance":)[0-9]+' 2>/dev/null)

if [ -n "$BALANCE" ]; then
    XMR=$(echo "scale=8; $BALANCE / 1000000000000" | bc)
    echo -e "${GREEN}✅ Wallet: ${XMR_WALLET:0:20}...${XMR_WALLET: -10}${NC}"
    echo -e "${GREEN}💰 Balance: ${XMR} XMR${NC}"
    
    # Get price in THB
    PRICE=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=monero&vs_currencies=thb" | grep -oP '(?<="thb":)[0-9.]+' 2>/dev/null)
    if [ -n "$PRICE" ]; then
        THB=$(echo "scale=2; $XMR * $PRICE" | bc)
        echo -e "${GREEN}💱 Value: ฿${THB} THB${NC}"
        echo -e "${YELLOW}📊 Price: 1 XMR = ฿${PRICE}${NC}"
    fi
else
    echo -e "${YELLOW}⏳ No balance yet. Keep mining!${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${CYAN}Check online: https://xmrchain.net/address/$XMR_WALLET${NC}"
