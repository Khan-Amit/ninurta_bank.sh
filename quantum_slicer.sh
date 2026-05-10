#!/bin/bash
# QUANTUM SLICER - Captures resonance peaks from wave amplitude

LOG_DIR="$HOME/.marduk"
mkdir -p "$LOG_DIR"

SLICE_OUT="$LOG_DIR/slices.out"
PEAK_LOG="$LOG_DIR/quantum_slices.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

detect_amplitude() {
    echo "scale=4; $RANDOM / 32768" | bc
}

clear
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}     QUANTUM SLICER ACTIVE${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Capturing resonance peaks...${NC}"
echo ""

SLICES=0

while true; do
    PREV_AMP=0
    DIRECTION="up"
    
    for i in {1..10}; do
        CURR_AMP=$(detect_amplitude)
        
        if [ "$DIRECTION" = "up" ] && (( $(echo "$CURR_AMP < $PREV_AMP" | bc -l) )); then
            PEAK_AMP=$PREV_AMP
            PEAK_TIME=$(date +%s%N)
            SLICES=$((SLICES + 1))
            
            echo -e "${GREEN}⚡ QUANTUM SLICE #$SLICES${NC}"
            echo "   Time: $PEAK_TIME"
            echo "   Amplitude: $PEAK_AMP"
            
            echo "$PEAK_TIME,$PEAK_AMP,$SLICES" >> "$PEAK_LOG"
            echo "$PEAK_AMP" >> "$SLICE_OUT"
            
            tail -100 "$SLICE_OUT" > "$SLICE_OUT.tmp" 2>/dev/null
            mv "$SLICE_OUT.tmp" "$SLICE_OUT" 2>/dev/null
            break
        fi
        
        PREV_AMP=$CURR_AMP
        if (( $(echo "$CURR_AMP > $PREV_AMP" | bc -l) )); then
            DIRECTION="up"
        else
            DIRECTION="down"
        fi
        
        sleep 0.01
    done
    
    sleep 0.5
done
