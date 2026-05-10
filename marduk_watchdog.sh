#!/bin/bash
# MARDUK WATCHDOG - Monitors all Marduk processes and restarts if needed

LOG_DIR="$HOME/.marduk"
mkdir -p "$LOG_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

PROCESSES=("marduk_engine.sh" "marduk_bridge.sh" "igigi_transporter.sh" "quantum_slicer.sh")
SCRIPT_DIR="$HOME/Marduk-v1"

is_running() {
    pgrep -f "$1" > /dev/null 2>&1
    return $?
}

start_process() {
    local script="$1"
    cd "$SCRIPT_DIR"
    nohup ./"$script" >> "$LOG_DIR/${script}.log" 2>&1 &
    echo -e "${GREEN}✅ Started $script${NC}"
}

clear
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}     MARDUK WATCHDOG${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""

for proc in "${PROCESSES[@]}"; do
    if is_running "$proc"; then
        echo -e "${GREEN}🟢 $proc is running${NC}"
    else
        echo -e "${RED}🔴 $proc is DOWN${NC}"
        start_process "$proc"
    fi
done

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📊 Summary:${NC}"
TOTAL_RUNNING=0
for proc in "${PROCESSES[@]}"; do
    if is_running "$proc"; then
        TOTAL_RUNNING=$((TOTAL_RUNNING + 1))
    fi
done
echo -e "   $TOTAL_RUNNING / ${#PROCESSES[@]} processes active"
echo ""

while true; do
    for proc in "${PROCESSES[@]}"; do
        if ! is_running "$proc"; then
            echo -e "${RED}⚠️ $proc crashed at $(date) - restarting${NC}"
            start_process "$proc"
        fi
    done
    sleep 30
done
