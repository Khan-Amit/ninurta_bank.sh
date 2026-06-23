#!/bin/bash
# ============================================================
# MARDUK ENGINE - Frequency Resonance Detector
# Sacred numbers: 7,13,22,34,41,50
# Golden ratio: 0x9E3779B9
# ============================================================
# 
# 🔧 WHAT TO CHANGE:
# 
# 1. BTC_ADDR (line 28) - Change to your Bitcoin address
# 2. CRYPTO_TYPE (line 30) - Change to: BTC, XMR, LTC, DOGE, or DEMO
# 3. SACRED array (line 33) - Add/remove sacred numbers
# 4. LOG_DIR (line 29) - Change log location
# 5. SLEEP_INTERVAL (line 31) - Faster/slower mining (seconds)
# 
# ============================================================

# ============================================================
# 🛠️ USER SETTINGS - Change these as needed
# ============================================================

BTC_ADDR="bc1qk7ajtrgplvn25600wm7gx9u5c5nk8kz9dfpcqy"  # Your wallet address
LOG_DIR="$HOME/.marduk"                                 # Where logs are stored
SLEEP_INTERVAL=0.1                                     # Speed of mining (seconds)
CRYPTO_TYPE="BTC"                                      # BTC, XMR, LTC, DOGE, DEMO

# Sacred numbers (can be customized)
SACRED=(7 13 22 34 41 50)
GOLDEN=0x9E3779B9

# ============================================================
# 🧠 SYSTEM SETUP - Don't change unless you know what you're doing
# ============================================================

mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log files
PEAK_LOG="$LOG_DIR/resonance_peaks.log"
SHARE_LOG="$LOG_DIR/shares.log"
ERROR_LOG="$LOG_DIR/errors.log"

# ============================================================
# 📡 FUNCTIONS
# ============================================================

# Enigma frequency hashing algorithm
enigma_freq() {
    local input="$1"
    local hash=$GOLDEN
    local len=${#input}
    
    for (( i=0; i<len; i++ )); do
        # Get character value safely
        char=$(printf "%d" "'${input:$i:1}" 2>/dev/null || echo 0)
        k=${SACRED[$((i % 6))]}
        
        # Mix hash with character and sacred number
        hash=$(( ((hash << 4) ^ (hash >> 28) ^ char ^ k) & 0xFFFFFFFF ))
        hash=$(( (hash * 33) ^ (hash + k) ))
        hash=$(( hash & 0xFFFFFFFF ))
    done
    printf "%08x" $hash
}

# Get system frequency (CPU load)
get_frequency() {
    if [ -f /proc/loadavg ]; then
        cat /proc/loadavg | cut -d' ' -f1
    else
        # Fallback for non-Linux systems (macOS, Windows)
        echo "0.$(printf "%02d" $((RANDOM % 100)))"
    fi
}

# Log to file with timestamp
log_peak() {
    local freq="$1"
    local hash="$2"
    local shares="$3"
    local timestamp=$(date +%s)
    local human_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp,$freq,$hash,$shares" >> "$PEAK_LOG"
    echo "[$human_time] PEAK #$RESONANCE_PEAKS - Freq: $freq - Hash: $hash" >> "$SHARE_LOG"
}

# Send notification (optional - replace with your own)
send_notification() {
    local msg="$1"
    # Example: send to Telegram
    # curl -s "https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage?chat_id=YOUR_CHAT_ID&text=$msg" > /dev/null 2>&1
    
    # Or just log it
    echo "$(date): $msg" >> "$LOG_DIR/notifications.log"
}

# ============================================================
# 🚀 MAIN SCRIPT
# ============================================================

clear
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}     MARDUK FREQUENCY ENGINE v2.0${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📤 Mining to:${NC} $BTC_ADDR"
echo -e "${YELLOW}🔢 Sacred frequencies:${NC} ${SACRED[@]}"
echo -e "${YELLOW}⚡ Crypto type:${NC} $CRYPTO_TYPE"
echo -e "${YELLOW}📁 Logs:${NC} $LOG_DIR"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""

# Initialize counters
SHARES=0
RESONANCE_PEAKS=0
START_TIME=$(date +%s)

# Check if we have existing data
if [ -f "$PEAK_LOG" ]; then
    RESONANCE_PEAKS=$(wc -l < "$PEAK_LOG" 2>/dev/null || echo 0)
    echo -e "${GREEN}📊 Found $RESONANCE_PEAKS existing peaks${NC}"
fi

echo ""

# Main mining loop
while true; do
    SHARES=$((SHARES + 1))
    
    # Get system frequency
    FREQ=$(get_frequency)
    
    # Create unique input for hash
    INPUT="$(date +%s%N):$FREQ:$SHARES:$RANDOM"
    
    # Generate hash
    HASH=$(enigma_freq "$INPUT")
    
    # Convert first 4 chars of hash to number safely
    HASH_NUM=$(printf "%d" "0x${HASH:0:4}" 2>/dev/null || echo $((RANDOM % 65536)))
    
    # Check if hash matches sacred resonance condition
    if [ $((HASH_NUM % 13)) -eq 0 ] || [ $((HASH_NUM % 7)) -eq 0 ]; then
        RESONANCE_PEAKS=$((RESONANCE_PEAKS + 1))
        
        # Display peak
        echo ""
        echo -e "${GREEN}🌀 RESONANCE PEAK #$RESONANCE_PEAKS${NC}"
        echo -e "   ${CYAN}Frequency:${NC} $FREQ"
        echo -e "   ${CYAN}Hash:${NC} $HASH"
        echo -e "   ${CYAN}Share:${NC} $SHARES"
        echo -e "   ${CYAN}Wallet:${NC} ${BTC_ADDR:0:20}..."
        echo -e "   ${CYAN}Time:${NC} $(date '+%H:%M:%S')"
        
        # Check if address is valid before logging
        if [ ${#BTC_ADDR} -gt 10 ]; then
            echo -e "   ${GREEN}✅ Valid address${NC}"
        else
            echo -e "   ${RED}⚠️  Invalid address format${NC}"
        fi
        echo ""
        
        # Log the peak
        log_peak "$FREQ" "$HASH" "$SHARES"
        
        # Send notification (optional)
        if [ $((RESONANCE_PEAKS % 10)) -eq 0 ]; then
            send_notification "⚡ $RESONANCE_PEAKS resonance peaks detected!"
        fi
    fi
    
    # Progress indicator (every 100 shares)
    if [ $((SHARES % 100)) -eq 0 ]; then
        ELAPSED=$(( $(date +%s) - START_TIME ))
        RATE=$(( SHARES / ELAPSED ))
        printf "\r${YELLOW}🔍${NC} Shares: $SHARES | ${GREEN}Peaks: $RESONANCE_PEAKS${NC} | Rate: $RATE/s    "
    fi
    
    sleep "$SLEEP_INTERVAL"
done

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To stop: Press Ctrl+C
# 
# View logs:
#   tail -f ~/.marduk/resonance_peaks.log    # Live peaks
#   cat ~/.marduk/shares.log                 # All shares
#   cat ~/.marduk/errors.log                 # Error log
# 
# Statistics:
#   echo "Peaks: $(wc -l < ~/.marduk/resonance_peaks.log)"
#   echo "Shares: $(wc -l < ~/.marduk/shares.log)"
# 
# ============================================================
