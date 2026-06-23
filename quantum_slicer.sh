#!/bin/bash
# ============================================================
# QUANTUM SLICER - Captures resonance peaks from wave amplitude
# ============================================================
# 
# 🔧 WHAT TO CHANGE:
# 
# 1. LOG DIRECTORY (line 24)
#    Change LOG_DIR if you want logs elsewhere
# 
# 2. AMPLITUDE DETECTION (line 29-31)
#    Replace the random generator with real input if needed
# 
# 3. PEAK THRESHOLD (line 69)
#    Add a minimum amplitude to filter noise
# 
# 4. SLICE INTERVAL (line 83)
#    Change sleep duration for faster/slower capture
# 
# ============================================================

# ============================================================
# 🛠️ USER SETTINGS - Change these as needed
# ============================================================

LOG_DIR="$HOME/.marduk"          # Where logs are stored
MIN_AMPLITUDE=0.2000             # Minimum amplitude to register (0.0000 - 1.0000)
SLICE_INTERVAL=0.5               # Seconds between capture cycles
VERBOSE=true                     # Set to false to quiet output

# ============================================================
# 🧠 SYSTEM SETUP - Don't change unless you know what you're doing
# ============================================================

mkdir -p "$LOG_DIR"

SLICE_OUT="$LOG_DIR/slices.out"
PEAK_LOG="$LOG_DIR/quantum_slices.log"
TEMP_FILE="$LOG_DIR/slices.tmp"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================
# 📡 FUNCTIONS
# ============================================================

# Detect amplitude - REPLACE THIS with real input if needed
detect_amplitude() {
    # Current: Random value between 0 and 1
    # Replace this with actual sensor/API data
    echo "scale=4; $RANDOM / 32768" | bc
}

# Log a message (with timestamp)
log_message() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" >> "$LOG_DIR/slicer.log"
    if [ "$VERBOSE" = true ]; then
        echo -e "$msg"
    fi
}

# ============================================================
# 🚀 MAIN SCRIPT - Let's go!
# ============================================================

clear
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}     QUANTUM SLICER ACTIVE${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Capturing resonance peaks...${NC}"
echo -e "${YELLOW}Log directory: $LOG_DIR${NC}"
echo -e "${YELLOW}Minimum amplitude: $MIN_AMPLITUDE${NC}"
echo ""

SLICES=0

# Check if we have existing slices
if [ -f "$SLICE_OUT" ]; then
    SLICES=$(wc -l < "$SLICE_OUT" 2>/dev/null || echo 0)
    echo -e "${GREEN}📊 Found $SLICES existing slices${NC}"
fi

# Main loop
while true; do
    PREV_AMP=0
    DIRECTION="up"
    PEAK_FOUND=false
    
    # Scan 10 samples to find a peak
    for i in {1..10}; do
        CURR_AMP=$(detect_amplitude)
        
        # DEBUG: Show current amplitude (uncomment to see values)
        # echo "Sample $i: $CURR_AMP (direction: $DIRECTION)"
        
        # Check if we're going down after going up = PEAK!
        if [ "$DIRECTION" = "up" ] && (( $(echo "$CURR_AMP < $PREV_AMP" | bc -l) )); then
            PEAK_AMP=$PREV_AMP
            
            # Only register if amplitude meets minimum threshold
            if (( $(echo "$PEAK_AMP >= $MIN_AMPLITUDE" | bc -l) )); then
                PEAK_TIME=$(date +%s%N)
                SLICES=$((SLICES + 1))
                PEAK_FOUND=true
                
                # Display the peak
                echo -e "${GREEN}⚡ QUANTUM SLICE #$SLICES${NC}"
                echo "   Time: $(date '+%H:%M:%S.%N' | cut -c1-12)"
                echo "   Amplitude: $PEAK_AMP"
                echo "   Threshold: $MIN_AMPLITUDE ✓"
                
                # Save to log files
                echo "$PEAK_TIME,$PEAK_AMP,$SLICES" >> "$PEAK_LOG"
                echo "$PEAK_AMP" >> "$SLICE_OUT"
                
                # Keep only last 100 slices (prevents huge files)
                tail -100 "$SLICE_OUT" > "$TEMP_FILE" 2>/dev/null
                mv "$TEMP_FILE" "$SLICE_OUT" 2>/dev/null
                
                # Log to system log
                log_message "${GREEN}⚡ SLICE #$SLICES - Amplitude: $PEAK_AMP${NC}"
                break
            else
                # Amplitude too low - skip
                if [ "$VERBOSE" = true ]; then
                    echo -e "${YELLOW}⏳ Peak detected but below threshold ($PEAK_AMP < $MIN_AMPLITUDE)${NC}"
                fi
            fi
        fi
        
        # Update direction tracking
        if (( $(echo "$CURR_AMP > $PREV_AMP" | bc -l) )); then
            DIRECTION="up"
        else
            DIRECTION="down"
        fi
        
        PREV_AMP=$CURR_AMP
        sleep 0.01  # Short delay between samples
    done
    
    # Show status if no peak found
    if [ "$PEAK_FOUND" = false ] && [ "$VERBOSE" = true ]; then
        echo -e "${YELLOW}⏳ Scanning... (no peak yet)${NC}"
    fi
    
    # Wait before next scan cycle
    sleep "$SLICE_INTERVAL"
done

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To stop the script: Press Ctrl+C
# 
# View logs:
#   cat ~/.marduk/slices.out          # Last 100 amplitudes
#   tail -f ~/.marduk/quantum_slices.log  # Live peak log
# 
# ============================================================
