#!/bin/bash
# ============================================================
# MARDUK WATCHDOG - Monitors all Marduk processes and restarts if needed
# "Eternal vigilance is the price of resonance."
# ============================================================
# 
# 🔧 WHAT TO CHANGE:
# 
# 1. PROCESSES array (line 38-39) - Add/remove scripts to monitor
# 2. SCRIPT_DIR (line 40) - Change to your scripts directory
# 3. CHECK_INTERVAL (line 42) - How often to check (seconds)
# 4. MAX_RESTARTS (line 43) - Max restarts before alert
# 5. ALERT_EMAIL (line 44) - Email for notifications (optional)
# 
# ============================================================

# ============================================================
# 🛠️ USER SETTINGS - Change these as needed
# ============================================================

# Scripts to monitor (add or remove as needed)
PROCESSES=(
    "marduk_engine.sh"
    "marduk_bridge.sh"
    "igigi_transporter.sh"
    "quantum_slicer.sh"
    "marduk_atm.sh"
)

SCRIPT_DIR="$HOME/Marduk-v1"                      # Where your scripts live
LOG_DIR="$HOME/.marduk"                           # Log directory
CHECK_INTERVAL=30                                 # Check every N seconds
MAX_RESTARTS=5                                    # Max restarts per hour
ALERT_EMAIL=""                                    # Email for alerts (optional)

# ============================================================
# 🧠 SYSTEM SETUP - Don't change unless you know what you're doing
# ============================================================

mkdir -p "$LOG_DIR"
mkdir -p "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log files
WATCHDOG_LOG="$LOG_DIR/watchdog.log"
RESTART_LOG="$LOG_DIR/restarts.log"
STATUS_LOG="$LOG_DIR/status.log"
ALERT_LOG="$LOG_DIR/alerts.log"

# Stats tracking
declare -A RESTART_COUNTS
declare -A RESTART_TIMES
START_TIME=$(date +%s)

# ============================================================
# 📡 FUNCTIONS
# ============================================================

# Log message with timestamp
log_message() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" >> "$WATCHDOG_LOG"
    echo -e "$msg"
}

# Check if a process is running
is_running() {
    local script="$1"
    # Check by script name (more reliable)
    if pgrep -f "$script" > /dev/null 2>&1; then
        return 0
    fi
    # Also check by process name (fallback)
    if pgrep -x "$(basename "$script" .sh)" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Get process PID
get_pid() {
    local script="$1"
    pgrep -f "$script" | head -1
}

# Get process uptime
get_uptime() {
    local pid="$1"
    if [ -n "$pid" ]; then
        local start_time=$(ps -p "$pid" -o lstart= 2>/dev/null)
        if [ -n "$start_time" ]; then
            local start_epoch=$(date -d "$start_time" +%s 2>/dev/null)
            local current_epoch=$(date +%s)
            local uptime_sec=$((current_epoch - start_epoch))
            local uptime_min=$((uptime_sec / 60))
            local uptime_hour=$((uptime_min / 60))
            if [ $uptime_hour -gt 0 ]; then
                echo "${uptime_hour}h $((uptime_min % 60))m"
            elif [ $uptime_min -gt 0 ]; then
                echo "${uptime_min}m $((uptime_sec % 60))s"
            else
                echo "${uptime_sec}s"
            fi
        else
            echo "unknown"
        fi
    else
        echo "N/A"
    fi
}

# Start a process
start_process() {
    local script="$1"
    local script_path="$SCRIPT_DIR/$script"
    
    # Check if script exists
    if [ ! -f "$script_path" ]; then
        log_message "${RED}❌ Script not found: $script_path${NC}"
        return 1
    fi
    
    # Check if script is executable
    if [ ! -x "$script_path" ]; then
        log_message "${YELLOW}⚠️ Script not executable, fixing...${NC}"
        chmod +x "$script_path"
    fi
    
    # Start the process
    cd "$SCRIPT_DIR" || return 1
    nohup "./$script" >> "$LOG_DIR/${script}.log" 2>&1 &
    local pid=$!
    
    # Wait a moment to ensure it started
    sleep 1
    if is_running "$script"; then
        local new_pid=$(get_pid "$script")
        log_message "${GREEN}✅ Started $script (PID: $new_pid)${NC}"
        
        # Log restart
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$timestamp,$script,$new_pid" >> "$RESTART_LOG"
        
        # Update restart counter
        RESTART_COUNTS["$script"]=$((RESTART_COUNTS["$script"] + 1))
        RESTART_TIMES["$script"]=$(date +%s)
        
        # Check if too many restarts
        check_restart_limit "$script"
        return 0
    else
        log_message "${RED}❌ Failed to start $script${NC}"
        return 1
    fi
}

# Check restart limits
check_restart_limit() {
    local script="$1"
    local count=${RESTART_COUNTS["$script"]:-0}
    
    if [ $count -ge $MAX_RESTARTS ]; then
        local last_restart=${RESTART_TIMES["$script"]:-0}
        local now=$(date +%s)
        local elapsed=$((now - last_restart))
        
        # If 5 restarts happened in last hour
        if [ $elapsed -lt 3600 ]; then
            log_message "${RED}⚠️ ALERT: $script restarted $count times in the last hour!${NC}"
            send_alert "CRITICAL: $script is unstable! $count restarts in 1 hour."
            
            # Optional: pause monitoring for this script
            # PAUSED_SCRIPTS+=("$script")
        fi
    fi
}

# Send alert (email/telegram/notification)
send_alert() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ALERT: $msg" >> "$ALERT_LOG"
    
    # Email alert
    if [ -n "$ALERT_EMAIL" ] && command -v mail &> /dev/null; then
        echo "$msg" | mail -s "MARDUK WATCHDOG ALERT" "$ALERT_EMAIL"
    fi
    
    # Telegram alert (optional)
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d "chat_id=$TELEGRAM_CHAT_ID" \
            -d "text=🚨 MARDUK ALERT: $msg" > /dev/null 2>&1
    fi
    
    # Terminal alert (visual)
    echo -e "${RED}🔔 ALERT: $msg${NC}"
}

# Save status summary
save_status() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local total=${#PROCESSES[@]}
    local running=0
    
    echo "=== STATUS REPORT: $timestamp ===" > "$STATUS_LOG"
    
    for proc in "${PROCESSES[@]}"; do
        local status=""
        local pid=""
        local uptime=""
        
        if is_running "$proc"; then
            status="RUNNING"
            pid=$(get_pid "$proc")
            uptime=$(get_uptime "$pid")
            running=$((running + 1))
        else
            status="STOPPED"
        fi
        
        printf "%-25s | %-8s | PID: %-8s | Uptime: %s\n" \
            "$proc" "$status" "${pid:-N/A}" "${uptime:-N/A}" >> "$STATUS_LOG"
    done
    
    local uptime_total=$(($(date +%s) - START_TIME))
    local uptime_hours=$((uptime_total / 3600))
    
    echo "" >> "$STATUS_LOG"
    echo "Running: $running / $total" >> "$STATUS_LOG"
    echo "Watchdog uptime: ${uptime_hours}h" >> "$STATUS_LOG"
}

# Display status banner
show_banner() {
    clear
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    🐕 MARDUK WATCHDOG v2.0${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📁 Script directory:${NC} $SCRIPT_DIR"
    echo -e "${YELLOW}📊 Check interval:${NC} ${CHECK_INTERVAL}s"
    echo -e "${YELLOW}🔄 Max restarts:${NC} $MAX_RESTARTS/hour"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Handle script not found
handle_missing_script() {
    local script="$1"
    local script_path="$SCRIPT_DIR/$script"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${YELLOW}⚠️  $script not found in $SCRIPT_DIR${NC}"
        echo -e "${YELLOW}   Create it or update PROCESSES array${NC}"
        return 1
    fi
    return 0
}

# ============================================================
# 🚀 MAIN SCRIPT
# ============================================================

show_banner

# Check if scripts directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
    echo -e "${RED}❌ Script directory not found: $SCRIPT_DIR${NC}"
    echo -e "${YELLOW}Please create the directory or update SCRIPT_DIR in the script${NC}"
    exit 1
fi

echo -e "${CYAN}🔍 Initializing watchdog...${NC}"
echo ""

# Initial check - start all missing processes
for proc in "${PROCESSES[@]}"; do
    if handle_missing_script "$proc"; then
        if is_running "$proc"; then
            pid=$(get_pid "$proc")
            uptime=$(get_uptime "$pid")
            echo -e "${GREEN}🟢 $proc${NC} is running (PID: $pid, Uptime: $uptime)"
        else
            echo -e "${RED}🔴 $proc${NC} is DOWN"
            start_process "$proc"
        fi
    fi
done

# Show initial summary
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📊 Initial Summary:${NC}"
TOTAL_RUNNING=0
for proc in "${PROCESSES[@]}"; do
    if is_running "$proc"; then
        TOTAL_RUNNING=$((TOTAL_RUNNING + 1))
    fi
done
echo -e "   ${GREEN}$TOTAL_RUNNING${NC} / ${#PROCESSES[@]} processes active"
echo ""

log_message "${GREEN}🚀 Watchdog started - monitoring ${#PROCESSES[@]} processes${NC}"
echo -e "${CYAN}🔄 Monitoring... Press Ctrl+C to stop${NC}"
echo ""

# Main monitoring loop
while true; do
    for proc in "${PROCESSES[@]}"; do
        if ! is_running "$proc"; then
            log_message "${RED}⚠️ $proc crashed at $(date)${NC}"
            start_process "$proc"
            
            # Send alert for crash
            send_alert "⚠️ $proc crashed and was restarted"
        fi
    done
    
    # Save status periodically (every 10 checks)
    if [ $(( (SECONDS / CHECK_INTERVAL) % 10 )) -eq 0 ]; then
        save_status
    fi
    
    # Show status summary every 5 minutes
    if [ $((SECONDS / 60 % 5)) -eq 0 ] && [ $((SECONDS % 60)) -lt $CHECK_INTERVAL ]; then
        show_banner
        echo -e "${CYAN}📊 Current Status:${NC}"
        for proc in "${PROCESSES[@]}"; do
            if is_running "$proc"; then
                pid=$(get_pid "$proc")
                uptime=$(get_uptime "$pid")
                echo -e "   ${GREEN}🟢${NC} $proc (PID: $pid, Uptime: $uptime)"
            else
                echo -e "   ${RED}🔴${NC} $proc (STOPPED)"
            fi
        done
        echo ""
        echo -e "${YELLOW}📊 Restart counts:${NC}"
        for proc in "${PROCESSES[@]}"; do
            count=${RESTART_COUNTS["$proc"]:-0}
            if [ $count -gt 0 ]; then
                echo -e "   $proc: $count restarts"
            fi
        done
        echo ""
        echo -e "${CYAN}🔄 Watching...${NC}"
        echo ""
    fi
    
    sleep "$CHECK_INTERVAL"
done

# ============================================================
# 📌 NOTES
# ============================================================
# 
# To stop: Press Ctrl+C
# 
# View logs:
#   tail -f ~/.marduk/watchdog.log        # Watchdog activity
#   tail -f ~/.marduk/restarts.log        # Restart history
#   cat ~/.marduk/status.log              # Current status
#   tail -f ~/.marduk/alerts.log          # Alerts
# 
# To monitor a specific script:
#   tail -f ~/.marduk/marduk_engine.sh.log
# 
# ============================================================

# ============================================================
# 🚨 EMERGENCY EXIT HANDLER
# ============================================================

cleanup() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🐕 WATCHDOG SHUTDOWN${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Save final status
    save_status
    
    # Show summary
    local uptime_total=$(($(date +%s) - START_TIME))
    local uptime_hours=$((uptime_total / 3600))
    local uptime_min=$(((uptime_total % 3600) / 60))
    
    echo -e "Uptime: ${GREEN}${uptime_hours}h ${uptime_min}m${NC}"
    echo -e "Processes monitored: ${GREEN}${#PROCESSES[@]}${NC}"
    echo ""
    echo -e "${YELLOW}Restart summary:${NC}"
    for proc in "${PROCESSES[@]}"; do
        count=${RESTART_COUNTS["$proc"]:-0}
        if [ $count -gt 0 ]; then
            echo -e "   $proc: ${RED}$count restarts${NC}"
        else
            echo -e "   $proc: ${GREEN}0 restarts${NC}"
        fi
    done
    echo ""
    echo -e "${GREEN}Logs saved to: $LOG_DIR${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Marduk watches. Always.${NC}"
    exit 0
}

# Trap Ctrl+C for clean exit
trap cleanup SIGINT SIGTERM

# ============================================================
# 📧 TELEGRAM NOTIFICATIONS (Optional)
# ============================================================
# 
# To enable Telegram alerts, uncomment and set these:
# 
# TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
# TELEGRAM_CHAT_ID="YOUR_CHAT_ID"
# 
# Get them from @BotFather on Telegram
# 
# ============================================================

# ============================================================
# 🚀 AUTO-START ON BOOT (Optional)
# ============================================================
# 
# To start watchdog automatically on system boot:
# 
# 1. Add to crontab:
#    crontab -e
#    @reboot sleep 30 && /home/$USER/Marduk-v1/marduk_watchdog.sh
# 
# 2. Or create a systemd service:
#    sudo nano /etc/systemd/system/marduk-watchdog.service
# 
# ============================================================
