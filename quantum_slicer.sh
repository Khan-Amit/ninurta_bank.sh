#!/bin/bash
# ============================================================
# QUANTUM SLICER v2.0 - Captures resonance peaks from wave amplitude
# "Every peak is a quantum of resonance."
# ============================================================
# 
# 🔧 WHAT TO CHANGE:
# 
# 1. LOG_DIR (line 38) - Change log location
# 2. MIN_AMPLITUDE (line 39) - Minimum amplitude to register (0.0000 - 1.0000)
# 3. SLICE_INTERVAL (line 40) - Seconds between capture cycles
# 4. SAMPLES_PER_SCAN (line 41) - Number of samples to analyze per scan
# 5. MAX_SLICES (line 42) - Keep only this many slices in history
# 6. VERBOSE (line 43) - Set to false to quiet output
# 7. AMPLITUDE_SOURCE (line 46-47) - Change to real input source
# 
# ============================================================

# ============================================================
# 🛠️ USER SETTINGS - Change these as needed
# ============================================================

LOG_DIR="$HOME/.marduk"          # Where logs are stored
MIN_AMPLITUDE=0.2000             # Minimum amplitude to register (0.0000 - 1.0000)
SLICE_INTERVAL=0.5               # Seconds between capture cycles
SAMPLES_PER_SCAN=10              # Number of samples to analyze per scan
MAX_SLICES=100                   # Keep only this many slices in history
VERBOSE=true                     # Set to false to quiet output

# Amplitude source options:
#   "random" - Random values (default)
#   "cpu"    - CPU load
#   "audio"  - Microphone input (requires sox)
#   "api"    - External API (e.g., crypto price)
#   "file"   - Read from file
AMPLITUDE_SOURCE="random"        # random, cpu, audio, api, file
AMPLITUDE_FILE=""                # Path to file if using "file" source
API_URL=""                       # API URL if using "api" source

# ============================================================
# 🧠 SYSTEM SETUP - Don't change unless you know what you're doing
# ============================================================

mkdir -p "$LOG_DIR"

SLICE_OUT="$LOG_DIR/slices.out"
PEAK_LOG="$LOG_DIR/quantum_slices.log"
TEMP_FILE="$LOG_DIR/slices.tmp"
STATS_LOG="$LOG_DIR/slicer_stats.log"
ERROR_LOG="$LOG_DIR/slicer_errors.log"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================
# 📡 FUNCTIONS
# ============================================================

# Detect amplitude from various sources
detect_amplitude() {
    local amp=0
    
    case "$AMPLITUDE_SOURCE" in
        "random")
            # Random value between 0 and 1
            amp=$(echo "scale=4; $RANDOM / 32768" | bc 2>/dev/null || echo "0.5000")
            ;;
            
        "cpu")
            # CPU load (normalized to 0-1)
            if [ -f /proc/loadavg ]; then
                local load=$(cat /proc/loadavg | cut -d' ' -f1)
                amp=$(echo "scale=4; $load / 10" | bc 2>/dev/null || echo "0.5000")
            else
                # macOS / other systems
                local load=$(sysctl -n vm.loadavg 2>/dev/null | cut -d' ' -f2 | tr -d ',')
                amp=$(echo "scale=4; $load / 10" | bc 2>/dev/null || echo "0.5000")
            fi
            ;;
            
        "audio")
            # Microphone input (requires sox)
            if command -v sox &> /dev/null; then
                local rms=$(rec -t wav - 2>/dev/null | sox -t wav - -n stat 2>&1 | grep "RMS" | awk '{print $3}' | head -1)
                amp=$(echo "scale=4; $rms * 10" | bc 2>/dev/null || echo "0.5000")
            else
                echo "0.5000"
            fi
            ;;
            
        "api")
            # External API (e.g., Bitcoin price)
            if [ -n "$API_URL" ]; then
                local data=$(curl -s "$API_URL" 2>/dev/null)
                # Try to extract numeric value (adjust for your API)
                amp=$(echo "$data" | grep -oE '[0-9]+\.[0-9]+' | head -1 | awk '{print $1/1000000}')
                amp=${amp:-0.5000}
            else
                echo "0.5000"
            fi
            ;;
            
        "file")
            # Read from file
            if [ -f "$AMPLITUDE_FILE" ]; then
                amp=$(cat "$AMPLITUDE_FILE" 2>/dev/null | head -1)
                amp=${amp:-0.5000}
            else
                echo "0.5000"
            fi
            ;;
            
        *)
            # Default: random
            amp=$(echo "scale=4; $RANDOM / 32768" | bc 2>/dev/null || echo "0.5000")
            ;;
    esac
    
    # Ensure value is between 0 and 1
    if (( $(echo "$amp < 0" | bc -l) )); then
        amp="0.0000"
    elif (( $(echo "$amp > 1" | bc -l) )); then
        amp="1.0000"
    fi
    
    printf "%.4f" "$amp"
}

# Log a message (with timestamp)
log_message() {
    local msg="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" >> "$LOG_DIR/slicer.log"
    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ]; then
        echo -e "$msg"
    fi
}

# Log error with details
log_error() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $msg" >> "$ERROR_LOG"
    log_message "${RED}❌ ERROR: $msg${NC}" "ERROR"
}

# Save statistics
save_stats() {
    local slices="$1"
    local peaks="$2"
    local avg_amp="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp,$slices,$peaks,$avg_amp" >> "$STATS_LOG"
}

# Generate simple progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=30
    local percent=$((current * 100 / total))
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

# ============================================================
# 🚀 MAIN SCRIPT - Let's go!
# ============================================================

clear
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}           ⚡ QUANTUM SLICER v2.0${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📁 Log directory:${NC} $LOG_DIR"
echo -e "${YELLOW}📊 Minimum amplitude:${NC} $MIN_AMPLITUDE"
echo -e "${YELLOW}⚡ Source:${NC} $AMPLITUDE_SOURCE"
echo -e "${YELLOW}🔢 Samples per scan:${NC} $SAMPLES_PER_SCAN"
echo -e "${YELLOW}⏱️  Interval:${NC} ${SLICE_INTERVAL}s"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

SLICES=0
TOTAL_PEAKS=0
PEAKS_FOUND=0
START_TIME=$(date +%s)

# Check if we have existing slices
if [ -f "$SLICE_OUT" ]; then
    SLICES=$(wc -l < "$SLICE_OUT" 2>/dev/null || echo 0)
    echo -e "${GREEN}📊 Found $SLICES existing slices${NC}"
fi

if [ -f "$PEAK_LOG" ]; then
    TOTAL_PEAKS=$(wc -l < "$PEAK_LOG" 2>/dev/null || echo 0)
    echo -e "${GREEN}🌀 Found $TOTAL_PEAKS recorded peaks${NC}"
fi

echo ""

# Check for required tools
if [ "$AMPLITUDE_SOURCE" = "audio" ] && ! command -v sox &> /dev/null; then
    echo -e "${YELLOW}⚠️  sox not installed. Install with: sudo apt install sox${NC}"
    echo -e "${YELLOW}   Falling back to random source${NC}"
    AMPLITUDE_SOURCE="random"
fi

if [ "$AMPLITUDE_SOURCE" = "api" ] && ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}⚠️  curl not installed. Install with: sudo apt install curl${NC}"
    echo -e "${YELLOW}   Falling back to random source${NC}"
    AMPLITUDE_SOURCE="random"
fi

echo -e "${CYAN}🌀 Starting quantum slicing... Press Ctrl+C to stop${NC}"
echo ""

# Main loop
while true; do
    PREV_AMP=0
    DIRECTION="up"
    PEAK_FOUND=false
    SCAN_AMPS=()
    
    # Scan samples to find a peak
    for i in $(seq 1 $SAMPLES_PER_SCAN); do
        CURR_AMP=$(detect_amplitude)
        SCAN_AMPS+=($CURR_AMP)
        
        # Show progress for this scan
        if [ "$VERBOSE" = false ]; then
            show_progress $i $SAMPLES_PER_SCAN
        fi
        
        # Check if we're going down after going up = PEAK!
        if [ "$DIRECTION" = "up" ] && (( $(echo "$CURR_AMP < $PREV_AMP" | bc -l) )); then
            PEAK_AMP=$PREV_AMP
            
            # Only register if amplitude meets minimum threshold
            if (( $(echo "$PEAK_AMP >= $MIN_AMPLITUDE" | bc -l) )); then
                PEAK_TIME=$(date +%s%N)
                SLICES=$((SLICES + 1))
                PEAKS_FOUND=$((PEAKS_FOUND + 1))
                PEAK_FOUND=true
                
                # Calculate peak metrics
                local peak_intensity=$(echo "scale=2; ($PEAK_AMP / 1) * 100" | bc 2>/dev/null || echo "0")
                
                # Display the peak
                echo ""
                echo -e "${GREEN}⚡ QUANTUM SLICE #$SLICES${NC}"
                echo "   ⏰ Time: $(date '+%H:%M:%S.%N' | cut -c1-12)"
                echo "   📊 Amplitude: $PEAK_AMP"
                echo "   📈 Intensity: ${peak_intensity}%"
                echo "   🎯 Threshold: $MIN_AMPLITUDE ✓"
                echo "   📋 Samples: $SAMPLES_PER_SCAN"
                
                # Calculate frequency (rough estimate)
                local freq=$(echo "scale=2; 1 / $SLICE_INTERVAL * $SAMPLES_PER_SCAN" | bc 2>/dev/null || echo "0")
                echo "   📐 Frequency: ${freq}Hz"
                
                # Save to log files
                echo "$PEAK_TIME,$PEAK_AMP,$SLICES,$freq" >> "$PEAK_LOG"
                echo "$PEAK_AMP" >> "$SLICE_OUT"
                
                # Keep only last MAX_SLICES (prevents huge files)
                tail -$MAX_SLICES "$SLICE_OUT" > "$TEMP_FILE" 2>/dev/null
                mv "$TEMP_FILE" "$SLICE_OUT" 2>/dev/null
                
                # Log to system log
                log_message "${GREEN}⚡ SLICE #$SLICES - Amp: $PEAK_AMP (${peak_intensity}%)${NC}" "INFO"
                break
            else
                # Amplitude too low - skip but note it
                if [ "$VERBOSE" = true ]; then
                    echo -e "${YELLOW}⏳ Peak below threshold ($PEAK_AMP < $MIN_AMPLITUDE)${NC}"
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
        echo -e "${CYAN}⏳ Scanning... (no peak yet)${NC}"
        # Show average amplitude of this scan
        local avg_amp=0
        for amp in "${SCAN_AMPS[@]}"; do
            avg_amp=$(echo "scale=4; $avg_amp + $amp" | bc 2>/dev/null || echo "0")
        done
        avg_amp=$(echo "scale=4; $avg_amp / ${#SCAN_AMPS[@]}" | bc 2>/dev/null || echo "0.0000")
        echo -e "   ${CYAN}Avg amplitude: $avg_amp${NC}"
    fi
    
    # Save stats every 10 slices
    if [ $((SLICES % 10)) -eq 0 ] && [ $SLICES -gt 0 ]; then
        local elapsed=$(($(date +%s) - START_TIME))
        local rate=$((SLICES / elapsed))
        echo -e "${YELLOW}📊 Stats:${NC} $SLICES slices | $PEAKS_FOUND peaks | ${rate}/s"
        save_stats "$SLICES" "$PEAKS_FOUND" "$avg_amp"
    fi
    
    # Wait before next scan cycle
    sleep "$SLICE_INTERVAL"
done

# ============================================================
# 🚨 EMERGENCY EXIT HANDLER
# ============================================================

cleanup() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}⚡ QUANTUM SLICER SHUTDOWN${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local elapsed=$(($(date +%s) - START_TIME))
    local hours=$((elapsed / 3600))
    local mins=$(((elapsed % 3600) / 60))
    local secs=$((elapsed % 60))
    
    echo -e "Uptime: ${GREEN}${hours}h ${mins}m ${secs}s${NC}"
    echo -e "Total slices: ${GREEN}$SLICES${NC}"
    echo -e "Peaks found: ${GREEN}$PEAKS_FOUND${NC}"
    
    if [ $SLICES -gt 0 ]; then
        local success_rate=$(echo "scale=2; $PEAKS_FOUND / $SLICES * 100" | bc 2>/dev/null || echo "0")
        echo -e "Success rate: ${GREEN}${success_rate}%${NC}"
    fi
    
    echo -e "Logs saved to: ${CYAN}$LOG_DIR${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Resonance captured.${NC}"
    exit 0
}

# Trap Ctrl+C for clean exit
trap cleanup SIGINT SIGTERM

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To stop: Press Ctrl+C
# 
# View logs:
#   tail -f ~/.marduk/quantum_slices.log   # Live peak log
#   cat ~/.marduk/slices.out                # Last $MAX_SLICES amplitudes
#   tail -f ~/.marduk/slicer_stats.log     # Statistics
#   tail -f ~/.marduk/slicer.log           # Full log
# 
# ============================================================
