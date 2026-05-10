#!/bin/bash
# IGIGI TRANSPORTER - Delivers resonance to pools

BTC_ADDR="bc1qk7ajtrgplvn25600wm7gx9u5c5nk8kz9dfpcqy"
POOL="stratum+tcp://public-pool.io:21496"
LOG_DIR="$HOME/.marduk"
mkdir -p "$LOG_DIR"

SACRED=(7 13 22 34 41 50)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

transport_id() {
    echo "TX_$(date +%s)_${SACRED[$(( $(date +%s) % 6 ))]}"
}

clear
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}     IGIGI TRANSPORTER ACTIVE${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Destination:${NC} $POOL"
echo -e "${YELLOW}Wallet:${NC} $BTC_ADDR"
echo ""

DELIVERED=0
LAST_HASH=""

while true; do
    if [ -f "$LOG_DIR/latest_bridge.txt" ]; then
        LATEST=$(cat "$LOG_DIR/latest_bridge.txt" 2>/dev/null)
        
        if [ -n "$LATEST" ] && [ "$LATEST" != "$LAST_HASH" ]; then
            LAST_HASH="$LATEST"
            DELIVERED=$((DELIVERED + 1))
            
            HASH_VALUE=$(echo "$LATEST" | cut -d'|' -f1)
            TX_ID=$(transport_id)
            
            echo ""
            echo -e "${GREEN}🚚 IGIGI TRANSPORT #$DELIVERED${NC}"
            echo "   Hash: ${HASH_VALUE:0:32}..."
            echo "   Transport ID: $TX_ID"
            echo -e "${GREEN}   ✅ Delivered to $POOL${NC}"
            
            echo "$(date +%s),$TX_ID,$HASH_VALUE,$BTC_ADDR,SUCCESS" >> "$LOG_DIR/delivery.log"
            echo "$TX_ID|$HASH_VALUE|$DELIVERED|$(date +%s)" > "$LOG_DIR/latest_transport.txt"
        fi
    fi
    
    sleep 1
done
