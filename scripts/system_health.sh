#!/usr/bin/env bash
# ==============================================================================
# Script Name: system_health.sh
# Description: Monitors system health (CPU, Memory, Disk usage) and logs entries
#              with timestamps. Emits warning if disk usage exceeds 80%.
# Author:      DevOps Candidate (Care Guide Assessment)
# ==============================================================================

set -o pipefail

# Configuration
LOG_FILE="${LOG_FILE:-health_log.txt}"
DISK_THRESHOLD="${DISK_THRESHOLD:-80}"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Function to get CPU usage percentage
get_cpu_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS implementation
        top -l 1 -n 0 | awk '/CPU usage/ {print $3}' | tr -d '%'
    else
        # Linux implementation (standard top output)
        top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}'
    fi
}

# Function to get Memory usage
get_memory_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS implementation using vm_stat
        local free_pages=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
        local active_pages=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
        local total_pages=$((free_pages + active_pages))
        if [ "$total_pages" -gt 0 ]; then
            awk -v active="$active_pages" -v total="$total_pages" 'BEGIN {printf "%.1f%%", (active/total)*100}'
        else
            echo "N/A"
        fi
    else
        # Linux implementation using free
        free -m | awk 'NR==2 {printf "%.1f%% (%dMB/%dMB)", $3*100/$2, $3, $2}'
    fi
}

# Function to get Disk usage percentage of root partition
get_disk_usage() {
    # Portable df command for root filesystem
    df -h / | awk 'NR==2 {print $5}' | tr -d '%'
}

# Collect metrics
CPU_USAGE=$(get_cpu_usage)
MEM_USAGE=$(get_memory_usage)
DISK_USAGE=$(get_disk_usage)

# Validate that metrics were retrieved
CPU_USAGE="${CPU_USAGE:-0}"
MEM_USAGE="${MEM_USAGE:-0%}"
DISK_USAGE="${DISK_USAGE:-0}"

# Format log entry
LOG_ENTRY="[$TIMESTAMP] CPU Usage: ${CPU_USAGE}% | Memory Usage: ${MEM_USAGE} | Disk Usage: ${DISK_USAGE}%"

# Append to log file
echo "$LOG_ENTRY" >> "$LOG_FILE"
echo "Logged: $LOG_ENTRY"

# Disk threshold warning check (requirement: if exceeds 80%, print [WARNING] Disk space high!)
# Convert disk usage to integer comparison
DISK_USAGE_INT=$(echo "$DISK_USAGE" | awk '{print int($1)}')

if [ "$DISK_USAGE_INT" -gt "$DISK_THRESHOLD" ]; then
    WARNING_MSG="[WARNING] Disk space high!"
    echo "$WARNING_MSG"
    echo "[$TIMESTAMP] $WARNING_MSG (Current: ${DISK_USAGE_INT}%, Threshold: ${DISK_THRESHOLD}%)" >> "$LOG_FILE"
fi

exit 0
