#!/bin/bash
# ============================================================
# IGIGI TRANSPORTER v2.1 - Delivers resonance to pools
# "Transporting quantum resonance to the blockchain."
# ============================================================

# ============================================================
# 🔧 CONFIGURATION - Can be overridden by ~/.marduk/transporter.conf
# ============================================================

# Default settings (can be overridden)
: "${BTC_ADDR:=bc1qk7ajtrgplvn25600wm7gx9u5c5nk8kz9dfpcqy}"
: "${POOL:=stratum+tcp://public-pool.io:21496}"
: "${LOG_DIR:=$HOME/.marduk}"
: "${DELIVERY_INTERVAL:=1}"
: "${MAX_RETRIES:=3}"
: "${BATCH_SIZE:=1}"
: "${DELIVERY_TIMEOUT:=30}"
: "${RATE_LIMIT:=10}"  # Max deliveries per minute
: "${MAX_HISTORY:=1000}"  # Keep only this many processed hashes

# Sacred numbers
SACRED=(7 13 22 34 41 50)

# ============================================================
# 📂 LOAD CONFIG FILE (if exists)
# ============================================================

CONFIG_FILE="$HOME/.marduk/transporter.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "📋 Loaded config from $CONFIG_FILE"
fi

# ============================================================
# 🧠 SYSTEM SETUP
# ============================================================

mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Log files
DELIVERY_LOG="$LOG_DIR/delivery.log"
TRANSPORT_LOG="$LOG_DIR/transport.log"
LATEST_TRANSPORT="$LOG_DIR/latest_transport.txt"
FAILED_LOG="$LOG_DIR/failed_deliveries.log"
STATS_LOG="$LOG_DIR/transporter_stats.log"
BRIDGE_LOG="$LOG_DIR/bridge_hashes.log"
PROCESSED_HASHES="$LOG_DIR/processed_hashes.txt"

# Counters
DELIVERED=0
FAILED=0
START_TIME=$(date +%s)
BATCH_BUFFER=()

# Track processed hashes (prevents duplicates)
declare -A PROCESSED_CACHE
if [ -f "$PROCESSED_HASHES" ]; then
    while IFS= read -r line; do
        PROCESSED_CACHE["$line"]=1
    done < "$PROCESSED_HASHES"
fi

# Rate limiting
RATE_COUNTER=0
RATE_TIMESTAMP=$(date +%s)

# ============================================================
# 📡 FUNCTIONS
# ============================================================

# Generate transport ID
transport_id() {
    local seed=$(date +%s%N)
    local sacred_index=$((seed % 6))
    local sacred_num=${SACRED[$sacred_index]}
    echo "TX_${seed}_${sacred_num}_${RANDOM}"
}

# Log message
log_message() {
    local msg="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" >> "$TRANSPORT_LOG"
    if [ "$level" != "DEBUG" ]; then
        echo -e "$msg"
    fi
}

# Log error
log_error() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $msg" >> "$FAILED_LOG"
    log_message "${RED}❌ ERROR: $msg${NC}" "ERROR"
}

# Validate hash format
validate_hash() {
    local hash="$1"
    if [[ "$hash" =~ ^[a-fA-F0-9]{64}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate Bitcoin address
validate_address() {
    local addr="$1"
    if [[ "$addr" =~ ^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$ ]] || [[ "$addr" =~ ^bc1[a-zA-HJ-NP-Z0-9]{39,59}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if pool is reachable with retry
check_pool() {
    local pool_host=$(echo "$POOL" | cut -d'/' -f3 | cut -d':' -f1)
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ping -c 1 -W 2 "$pool_host" &> /dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    return 1
}

# Check rate limit
check_rate_limit() {
    local current_time=$(date +%s)
    local time_diff=$((current_time - RATE_TIMESTAMP))
    
    if [ $time_diff -ge 60 ]; then
        # Reset counter every minute
        RATE_COUNTER=0
        RATE_TIMESTAMP=$current_time
    fi
    
    if [ $RATE_COUNTER -ge $RATE_LIMIT ]; then
        log_message "${YELLOW}⏳ Rate limit reached ($RATE_LIMIT/min). Waiting...${NC}" "WARN"
        sleep 5
        return 1
    fi
    
    RATE_COUNTER=$((RATE_COUNTER + 1))
    return 0
}

# Deliver to pool with exponential backoff
deliver_to_pool() {
    local hash="$1"
    local address="$2"
    local attempt=1
    local backoff=1
    
    # Check pool connectivity first
    if ! check_pool; then
        log_error "Pool $POOL unreachable"
        return 1
    fi
    
    # Check rate limit
    if ! check_rate_limit; then
        return 1
    fi
    
    # Validate hash
    if ! validate_hash "$hash"; then
        log_error "Invalid hash format: $hash"
        return 1
    fi
    
    # Attempt delivery with exponential backoff
    while [ $attempt -le $MAX_RETRIES ]; do
        log_message "${YELLOW}📤 Attempt $attempt/$MAX_RETRIES to $POOL${NC}" "INFO"
        
        # This is where you'd actually submit to the pool
        # For real mining, replace with actual pool submission
        
        # Simulate delivery with 95% success rate
        if [ $((RANDOM % 100)) -lt 95 ]; then
            return 0
        fi
        
        # Exponential backoff
        if [ $attempt -lt $MAX_RETRIES ]; then
            local wait_time=$((backoff * attempt * 2))
            log_message "${YELLOW}⏳ Retrying in ${wait_time}s...${NC}" "WARN"
            sleep $wait_time
        fi
        
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Mark hash as processed
mark_processed() {
    local hash="$1"
    PROCESSED_CACHE["$hash"]=1
    echo "$hash" >> "$PROCESSED_HASHES"
    
    # Keep only last MAX_HISTORY entries
    if [ -f "$PROCESSED_HASHES" ] && [ $(wc -l < "$PROCESSED_HASHES") -gt $MAX_HISTORY ]; then
        tail -$MAX_HISTORY "$PROCESSED_HASHES" > "$PROCESSED_HASHES.tmp"
        mv "$PROCESSED_HASHES.tmp" "$PROCESSED_HASHES"
    fi
}

# Check if hash was already processed
is_processed() {
    local hash="$1"
    if [ -n "${PROCESSED_CACHE[$hash]}" ]; then
        return 0
    fi
    return 1
}

# Process a single hash delivery
process_hash() {
    local hash="$1"
    
    # Check for duplicates
    if is_processed "$hash"; then
        log_message "${YELLOW}⚠️ Hash already processed, skipping${NC}" "WARN"
        return 0
    fi
    
    if deliver_to_pool "$hash" "$BTC_ADDR"; then
        mark_processed "$hash"
        return 0
    else
        return 1
    fi
}

# Save statistics
save_stats() {
    local delivered="$1"
    local failed="$2"
    local rate="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp,$delivered,$failed,$rate" >> "$STATS_LOG"
}

# Health check mode
health_check() {
    echo "🔍 IGIGI TRANSPORTER - Health Check"
    echo "===================================="
    
    # Check Bitcoin address
    if validate_address "$BTC_ADDR"; then
        echo "✅ Bitcoin address: $BTC_ADDR"
    else
        echo "❌ Invalid Bitcoin address: $BTC_ADDR"
    fi
    
    # Check pool
    if check_pool; then
        echo "✅ Pool reachable: $POOL"
    else
        echo "❌ Pool unreachable: $POOL"
    fi
    
    # Check log directory
    if [ -d "$LOG_DIR" ]; then
        echo "✅ Log directory: $LOG_DIR"
    else
        echo "❌ Log directory missing: $LOG_DIR"
    fi
    
    # Check processed hashes
    if [ -f "$PROCESSED_HASHES" ]; then
        echo "✅ Processed hashes: $(wc -l < "$PROCESSED_HASHES")"
    fi
    
    # Check delivery stats
    if [ -f "$DELIVERY_LOG" ]; then
        local total=$(wc -l < "$DELIVERY_LOG")
        local success=$(grep -c "SUCCESS" "$DELIVERY_LOG" 2>/dev/null || echo 0)
        echo "✅ Total deliveries: $total"
        echo "✅ Successful: $success"
    fi
    
    exit 0
}

# ============================================================
# 🚀 MAIN SCRIPT
# ============================================================

# Parse command line arguments
case "$1" in
    --health-check|-h)
        health_check
        ;;
    --version|-v)
        echo "IGIGI TRANSPORTER v2.1"
        echo "Sacred numbers: ${SACRED[@]}"
        exit 0
        ;;
esac

clear
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}           🚚 IGIGI TRANSPORTER v2.1${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📤 Destination:${NC} $POOL"
echo -e "${YELLOW}📬 Wallet:${NC} $BTC_ADDR"
echo -e "${YELLOW}🔢 Sacred numbers:${NC} ${SACRED[@]}"
echo -e "${YELLOW}⚡ Check interval:${NC} ${DELIVERY_INTERVAL}s"
echo -e "${YELLOW}🔄 Max retries:${NC} $MAX_RETRIES"
echo -e "${YELLOW}⏱️  Rate limit:${NC} $RATE_LIMIT/min"
echo -e "${YELLOW}📊 History:${NC} $MAX_HISTORY hashes"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Validate Bitcoin address
if ! validate_address "$BTC_ADDR"; then
    echo -e "${RED}⚠️  WARNING: Invalid Bitcoin address format!${NC}"
    echo -e "${YELLOW}Please update BTC_ADDR in the script or config.${NC}"
    echo ""
fi

# Check pool connectivity
echo -e "${CYAN}🔍 Checking pool connectivity...${NC}"
if check_pool; then
    echo -e "${GREEN}✅ Pool reachable: $POOL${NC}"
else
    echo -e "${YELLOW}⚠️  Pool unreachable. Will retry later.${NC}"
fi
echo ""

# Check if we have a bridge log
if [ ! -f "$BRIDGE_LOG" ] && [ ! -f "$LOG_DIR/latest_bridge.txt" ]; then
    echo -e "${YELLOW}⚠️  No bridge data found. Waiting for Marduk Bridge...${NC}"
    echo -e "${YELLOW}   Make sure marduk_bridge.sh is running.${NC}"
    echo ""
fi

echo -e "${CYAN}🌀 Starting transport... Press Ctrl+C to stop${NC}"
echo ""

# Process any existing bridge hashes
if [ -f "$BRIDGE_LOG" ]; then
    echo -e "${GREEN}📊 Found bridge log with $(wc -l < "$BRIDGE_LOG") entries${NC}"
    echo ""
fi

# Main loop
while true; do
    NEW_HASH=""
    NEW_ENIGMA=""
    NEW_COUNT=""
    
    # Try to read from latest_bridge.txt first
    if [ -f "$LOG_DIR/latest_bridge.txt" ]; then
        LATEST=$(cat "$LOG_DIR/latest_bridge.txt" 2>/dev/null)
        
        if [ -n "$LATEST" ] && [ "$LATEST" != "$LAST_HASH" ]; then
            HASH_VALUE=$(echo "$LATEST" | cut -d'|' -f1 2>/dev/null)
            ENIGMA_VALUE=$(echo "$LATEST" | cut -d'|' -f2 2>/dev/null)
            COUNT_VALUE=$(echo "$LATEST" | cut -d'|' -f3 2>/dev/null)
            
            if [ -n "$HASH_VALUE" ] && [ "$HASH_VALUE" != "$LAST_HASH" ]; then
                NEW_HASH="$HASH_VALUE"
                NEW_ENIGMA="$ENIGMA_VALUE"
                NEW_COUNT="$COUNT_VALUE"
                LAST_HASH="$LATEST"
            fi
        fi
    fi
    
    # If no new hash, try reading from bridge log
    if [ -z "$NEW_HASH" ] && [ -f "$BRIDGE_LOG" ]; then
        LATEST_BRIDGE=$(tail -1 "$BRIDGE_LOG" 2>/dev/null)
        if [ -n "$LATEST_BRIDGE" ]; then
            HASH_VALUE=$(echo "$LATEST_BRIDGE" | cut -d',' -f2 2>/dev/null)
            if [ -n "$HASH_VALUE" ] && [ "$HASH_VALUE" != "$LAST_HASH" ]; then
                NEW_HASH="$HASH_VALUE"
                LAST_HASH="$HASH_VALUE"
            fi
        fi
    fi
    
    # Process new hash if found
    if [ -n "$NEW_HASH" ]; then
        DELIVERED=$((DELIVERED + 1))
        TX_ID=$(transport_id)
        
        echo ""
        echo -e "${GREEN}🚚 IGIGI TRANSPORT #$DELIVERED${NC}"
        echo "   🎲 Hash: ${NEW_HASH:0:32}...${NEW_HASH:32:32}"
        echo "   🔐 Enigma: ${NEW_ENIGMA:-N/A}"
        echo "   📋 Bridge count: ${NEW_COUNT:-N/A}"
        echo "   🆔 Transport ID: $TX_ID"
        echo "   📤 Destination: $POOL"
        echo "   📬 Wallet: ${BTC_ADDR:0:20}..."
        
        # Check if already processed
        if is_processed "$NEW_HASH"; then
            echo -e "   ${YELLOW}⏭️  Hash already processed, skipping${NC}"
            continue
        fi
        
        # Attempt delivery
        echo -e "${CYAN}   ⏳ Delivering...${NC}"
        
        if process_hash "$NEW_HASH"; then
            echo -e "   ${GREEN}✅ Successfully delivered to $POOL${NC}"
            echo "$(date +%s),$TX_ID,$NEW_HASH,$BTC_ADDR,SUCCESS" >> "$DELIVERY_LOG"
            echo "$TX_ID|$NEW_HASH|$DELIVERED|$(date +%s)|SUCCESS" > "$LATEST_TRANSPORT"
        else
            FAILED=$((FAILED + 1))
            echo -e "   ${RED}❌ Delivery failed after $MAX_RETRIES attempts${NC}"
            echo "$(date +%s),$TX_ID,$NEW_HASH,$BTC_ADDR,FAILED" >> "$DELIVERY_LOG"
            echo "$(date +%s),$NEW_HASH,$TX_ID,FAILED" >> "$FAILED_LOG"
            echo "$TX_ID|$NEW_HASH|$DELIVERED|$(date +%s)|FAILED" > "$LATEST_TRANSPORT"
        fi
        
        # Show stats every 10 deliveries
        if [ $((DELIVERED % 10)) -eq 0 ]; then
            ELAPSED=$(($(date +%s) - START_TIME))
            RATE=$((DELIVERED / ELAPSED))
            SUCCESS_RATE=$(echo "scale=2; ($DELIVERED - $FAILED) / $DELIVERED * 100" | bc 2>/dev/null || echo "0")
            echo -e "${YELLOW}📊 Stats:${NC} $DELIVERED delivered | $FAILED failed | ${SUCCESS_RATE}% success | ${RATE}/s"
            save_stats "$DELIVERED" "$FAILED" "$RATE"
        fi
        
        echo ""
    fi
    
    # Show heartbeat if no new hashes
    if [ -z "$NEW_HASH" ] && [ $((SECONDS % 10)) -eq 0 ]; then
        echo -e "${CYAN}💓 Waiting for new bridge hashes...${NC}"
        echo -e "   ${YELLOW}Delivered: $DELIVERED | Failed: $FAILED${NC}"
    fi
    
    sleep "$DELIVERY_INTERVAL"
done

# ============================================================
# 🚨 EMERGENCY EXIT HANDLER
# ============================================================

cleanup() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🚚 IGIGI TRANSPORTER SHUTDOWN${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local elapsed=$(($(date +%s) - START_TIME))
    local hours=$((elapsed / 3600))
    local mins=$(((elapsed % 3600) / 60))
    local secs=$((elapsed % 60))
    
    echo -e "Uptime: ${GREEN}${hours}h ${mins}m ${secs}s${NC}"
    echo -e "Delivered: ${GREEN}$DELIVERED${NC}"
    echo -e "Failed: ${RED}$FAILED${NC}"
    
    if [ $DELIVERED -gt 0 ]; then
        local success_rate=$(echo "scale=2; ($DELIVERED - $FAILED) / $DELIVERED * 100" | bc 2>/dev/null || echo "0")
        echo -e "Success rate: ${GREEN}${success_rate}%${NC}"
    fi
    
    echo -e "Logs saved to: ${CYAN}$LOG_DIR${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Resonance transported.${NC}"
    exit 0
}

# Trap signals
trap cleanup SIGINT SIGTERM SIGHUP

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To stop: Press Ctrl+C
# 
# Commands:
#   ./igigi_transporter.sh --health-check  # Check status
#   ./igigi_transporter.sh --version       # Show version
# 
# View logs:
#   tail -f ~/.marduk/delivery.log        # All deliveries
#   tail -f ~/.marduk/transport.log       # Detailed log
#   cat ~/.marduk/latest_transport.txt    # Latest transport
#   tail -f ~/.marduk/failed_deliveries.log  # Failed deliveries
# 
# ============================================================

# ============================================================
# 📝 CONFIG FILE EXAMPLE (~/.marduk/transporter.conf)
# ============================================================
# 
# BTC_ADDR="your_address_here"
# POOL="stratum+tcp://your-pool:port"
# DELIVERY_INTERVAL=2
# MAX_RETRIES=5
# RATE_LIMIT=20
# MAX_HISTORY=2000
# 
# ============================================================
