#!/bin/bash

# DBA Performance Issue Analyzer

# Automatically identifies performance bottlenecks from system statistics

RED=’\033[0;31m’
YELLOW=’\033[1;33m’
GREEN=’\033[0;32m’
BLUE=’\033[0;34m’
NC=’\033[0m’ # No Color

DB_PORTS=“1521 3306 5432 1433”  # Oracle, MySQL, PostgreSQL, SQL Server
CRITICAL_THRESHOLD=80
WARNING_THRESHOLD=60

echo -e “${BLUE}========================================${NC}”
echo -e “${BLUE}   DBA PERFORMANCE ISSUE ANALYZER      ${NC}”
echo -e “${BLUE}========================================${NC}”
echo “Analysis Time: $(date)”
echo

# Get system info

CPU_CORES=$(nproc)
TOTAL_MEM=$(free -m | awk ‘NR==2{print $2}’)

echo -e “${BLUE}System Info:${NC} $CPU_CORES CPU cores, ${TOTAL_MEM}MB RAM”
echo

# Function to analyze vmstat

analyze_vmstat() {
echo -e “${BLUE}=== CPU & MEMORY ANALYSIS ===${NC}”

```
# Get 3 samples to avoid first sample bias
VMSTAT_OUTPUT=$(vmstat 1 3 | tail -n 1)

R_QUEUE=$(echo $VMSTAT_OUTPUT | awk '{print $1}')
B_QUEUE=$(echo $VMSTAT_OUTPUT | awk '{print $2}')
SWPD=$(echo $VMSTAT_OUTPUT | awk '{print $3}')
FREE_MEM=$(echo $VMSTAT_OUTPUT | awk '{print $4}')
BUFFER=$(echo $VMSTAT_OUTPUT | awk '{print $5}')
CACHE=$(echo $VMSTAT_OUTPUT | awk '{print $6}')
SWAP_IN=$(echo $VMSTAT_OUTPUT | awk '{print $7}')
SWAP_OUT=$(echo $VMSTAT_OUTPUT | awk '{print $8}')
IO_WAIT=$(echo $VMSTAT_OUTPUT | awk '{print $16}')
USER_CPU=$(echo $VMSTAT_OUTPUT | awk '{print $13}')
SYS_CPU=$(echo $VMSTAT_OUTPUT | awk '{print $14}')
IDLE_CPU=$(echo $VMSTAT_OUTPUT | awk '{print $15}')

echo "Raw stats: r=$R_QUEUE b=$B_QUEUE swap=${SWPD}KB free=${FREE_MEM}KB wa=${IO_WAIT}% us=${USER_CPU}% sy=${SYS_CPU}% id=${IDLE_CPU}%"
echo

ISSUES_FOUND=0

# CPU Analysis
CPU_LOAD_RATIO=$(echo "scale=2; $R_QUEUE / $CPU_CORES" | bc -l 2>/dev/null || echo "0")
if (( $(echo "$CPU_LOAD_RATIO > 2" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "🔴 ${RED}CRITICAL - CPU Overload${NC}"
    echo "   └─ Run queue ($R_QUEUE) is ${CPU_LOAD_RATIO}x CPU cores"
    echo "   └─ Impact: Database queries queuing for CPU, slow response times"
    echo "   └─ Action: Check slow queries, optimize indexes, consider CPU upgrade"
    ISSUES_FOUND=1
elif (( $(echo "$CPU_LOAD_RATIO > 1" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "🟡 ${YELLOW}WARNING - High CPU Load${NC}"
    echo "   └─ Run queue ($R_QUEUE) approaching CPU capacity"
    echo "   └─ Action: Monitor query performance, check for CPU-intensive operations"
else
    echo -e "✅ ${GREEN}CPU Load: Normal${NC} (${CPU_LOAD_RATIO}x cores)"
fi

# I/O Wait Analysis
if [ "$IO_WAIT" -gt 30 ]; then
    echo -e "🔴 ${RED}CRITICAL - I/O Bottleneck${NC}"
    echo "   └─ I/O Wait: ${IO_WAIT}% (processes waiting for disk)"
    echo "   └─ Impact: Database queries waiting for disk reads/writes"
    echo "   └─ Action: Check iostat for slow disks, optimize queries, consider SSD upgrade"
    ISSUES_FOUND=1
elif [ "$IO_WAIT" -gt 15 ]; then
    echo -e "🟡 ${YELLOW}WARNING - Elevated I/O Wait${NC}"
    echo "   └─ I/O Wait: ${IO_WAIT}%"
    echo "   └─ Action: Monitor disk performance, check for large table scans"
else
    echo -e "✅ ${GREEN}I/O Wait: Normal${NC} (${IO_WAIT}%)"
fi

# Memory Analysis
FREE_MEM_PCT=$(echo "scale=2; $FREE_MEM * 100 / $TOTAL_MEM" | bc -l 2>/dev/null || echo "0")
CACHE_PCT=$(echo "scale=2; $CACHE * 100 / ($TOTAL_MEM * 1024)" | bc -l 2>/dev/null || echo "0")

if [ "$SWPD" -gt 0 ] && ([ "$SWAP_IN" -gt 0 ] || [ "$SWAP_OUT" -gt 0 ]); then
    echo -e "🔴 ${RED}CRITICAL - Memory Pressure${NC}"
    echo "   └─ Active swapping detected (si=$SWAP_IN so=$SWAP_OUT)"
    echo "   └─ Impact: Database performance severely degraded"
    echo "   └─ Action: Add RAM, tune database memory settings, kill memory-heavy processes"
    ISSUES_FOUND=1
elif (( $(echo "$FREE_MEM_PCT < 5" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "🟡 ${YELLOW}WARNING - Low Free Memory${NC}"
    echo "   └─ Free memory: ${FREE_MEM_PCT}% (${FREE_MEM}MB)"
    echo "   └─ Cache usage: ${CACHE_PCT}% (good for database file caching)"
else
    echo -e "✅ ${GREEN}Memory: Adequate${NC} (${FREE_MEM_PCT}% free, ${CACHE_PCT}% cached)"
fi

# Process Queue Analysis
if [ "$B_QUEUE" -gt 5 ]; then
    echo -e "🔴 ${RED}CRITICAL - I/O Queue Backup${NC}"
    echo "   └─ $B_QUEUE processes waiting for I/O completion"
    echo "   └─ Impact: Database operations queuing behind slow disk I/O"
    echo "   └─ Action: Check disk health, optimize storage configuration"
    ISSUES_FOUND=1
elif [ "$B_QUEUE" -gt 2 ]; then
    echo -e "🟡 ${YELLOW}WARNING - I/O Queue Building${NC}"
    echo "   └─ $B_QUEUE processes in I/O wait"
fi

return $ISSUES_FOUND
```

}

# Function to analyze network/database connections

analyze_connections() {
echo -e “\n${BLUE}=== DATABASE CONNECTION ANALYSIS ===${NC}”

```
CONN_ISSUES=0

for PORT in $DB_PORTS; do
    LISTENING=$(netstat -ln | grep ":$PORT " | grep LISTEN)
    if [ ! -z "$LISTENING" ]; then
        CONN_COUNT=$(netstat -an | grep ":$PORT " | grep ESTABLISHED | wc -l)
        TIMEWAIT_COUNT=$(netstat -an | grep ":$PORT " | grep TIME_WAIT | wc -l)
        
        DB_TYPE=""
        case $PORT in
            1521) DB_TYPE="Oracle" ;;
            3306) DB_TYPE="MySQL" ;;
            5432) DB_TYPE="PostgreSQL" ;;
            1433) DB_TYPE="SQL Server" ;;
        esac
        
        echo "${DB_TYPE} (port $PORT):"
        echo "  └─ Active connections: $CONN_COUNT"
        echo "  └─ TIME_WAIT connections: $TIMEWAIT_COUNT"
        
        # Connection analysis
        if [ "$CONN_COUNT" -gt 200 ]; then
            echo -e "  🔴 ${RED}CRITICAL - High connection count${NC}"
            echo "     └─ Risk of hitting max_connections limit"
            echo "     └─ Action: Check for connection leaks, implement connection pooling"
            CONN_ISSUES=1
        elif [ "$CONN_COUNT" -gt 100 ]; then
            echo -e "  🟡 ${YELLOW}WARNING - Elevated connections${NC}"
            echo "     └─ Monitor for connection growth"
        else
            echo -e "  ✅ ${GREEN}Connection count: Normal${NC}"
        fi
        
        if [ "$TIMEWAIT_COUNT" -gt 50 ]; then
            echo -e "  🟡 ${YELLOW}WARNING - High TIME_WAIT connections${NC}"
            echo "     └─ Possible connection churning, check connection pooling"
        fi
    fi
done

# Check for network errors
NET_ERRORS=$(netstat -i | awk 'NR>2 {errs+=$4+$8} END {print errs+0}')
if [ "$NET_ERRORS" -gt 0 ]; then
    echo -e "🟡 ${YELLOW}WARNING - Network errors detected: $NET_ERRORS${NC}"
    echo "   └─ Check network connectivity and hardware"
fi

return $CONN_ISSUES
```

}

# Function to analyze I/O performance

analyze_iostat() {
echo -e “\n${BLUE}=== DISK I/O ANALYSIS ===${NC}”

```
# Check if iostat is available
if ! command -v iostat &> /dev/null; then
    echo -e "🟡 ${YELLOW}WARNING: iostat not available (install sysstat package)${NC}"
    return 0
fi

IO_ISSUES=0

# Get iostat data (2 samples to avoid first sample bias)
IOSTAT_OUTPUT=$(iostat -x 1 2 | tail -n +4)

echo "Analyzing disk devices..."

while read -r line; do
    if [[ $line =~ ^[a-zA-Z] ]]; then
        DEVICE=$(echo $line | awk '{print $1}')
        UTIL=$(echo $line | awk '{print $NF}' | cut -d. -f1)
        AWAIT=$(echo $line | awk '{print $(NF-3)}' | cut -d. -f1)
        R_S=$(echo $line | awk '{print $4}' | cut -d. -f1)
        W_S=$(echo $line | awk '{print $5}' | cut -d. -f1)
        
        # Skip if no activity
        if [ "$UTIL" = "0" ] && [ "$R_S" = "0" ] && [ "$W_S" = "0" ]; then
            continue
        fi
        
        echo "$DEVICE: ${UTIL}% utilized, ${AWAIT}ms avg wait, ${R_S}r/s, ${W_S}w/s"
        
        # Analyze utilization
        if [ "$UTIL" -gt 85 ]; then
            echo -e "  🔴 ${RED}CRITICAL - Disk saturated${NC}"
            echo "     └─ ${UTIL}% utilization indicates I/O bottleneck"
            echo "     └─ Impact: Database queries will be slow"
            echo "     └─ Action: Optimize queries, add faster storage, check RAID config"
            IO_ISSUES=1
        elif [ "$UTIL" -gt 70 ]; then
            echo -e "  🟡 ${YELLOW}WARNING - High disk utilization${NC}"
            echo "     └─ ${UTIL}% utilization"
            echo "     └─ Monitor for performance degradation"
        else
            echo -e "  ✅ ${GREEN}Utilization: Normal${NC} (${UTIL}%)"
        fi
        
        # Analyze response time
        if [ "$AWAIT" -gt 50 ]; then
            echo -e "  🔴 ${RED}CRITICAL - Slow disk response${NC}"
            echo "     └─ ${AWAIT}ms average wait time"
            echo "     └─ Impact: Every database I/O operation is slow"
            echo "     └─ Action: Check disk health, consider SSD upgrade"
            IO_ISSUES=1
        elif [ "$AWAIT" -gt 20 ]; then
            echo -e "  🟡 ${YELLOW}WARNING - Elevated response time${NC}"
            echo "     └─ ${AWAIT}ms average wait time"
        else
            echo -e "  ✅ ${GREEN}Response time: Good${NC} (${AWAIT}ms)"
        fi
    fi
done <<< "$IOSTAT_OUTPUT"

return $IO_ISSUES
```

}

# Function to provide summary and recommendations

provide_summary() {
local vmstat_issues=$1
local conn_issues=$2
local io_issues=$3

```
echo -e "\n${BLUE}=== SUMMARY & RECOMMENDATIONS ===${NC}"

TOTAL_ISSUES=$((vmstat_issues + conn_issues + io_issues))

if [ $TOTAL_ISSUES -eq 0 ]; then
    echo -e "🎉 ${GREEN}SYSTEM STATUS: HEALTHY${NC}"
    echo "   └─ No critical performance issues detected"
    echo "   └─ Continue regular monitoring"
else
    echo -e "⚠️  ${RED}ISSUES DETECTED: $TOTAL_ISSUES critical problems${NC}"
    echo
    echo -e "${BLUE}Immediate Actions:${NC}"
    
    if [ $vmstat_issues -gt 0 ]; then
        echo "• Check database slow query log"
        echo "• Review currently running queries (SHOW PROCESSLIST)"
        echo "• Analyze query execution plans"
        echo "• Consider query optimization or hardware upgrade"
    fi
    
    if [ $conn_issues -gt 0 ]; then
        echo "• Review database connection limits"
        echo "• Implement or tune connection pooling"
        echo "• Check for connection leaks in applications"
    fi
    
    if [ $io_issues -gt 0 ]; then
        echo "• Identify and optimize I/O intensive queries"
        echo "• Check disk health and RAID configuration"
        echo "• Consider faster storage (SSD) or additional IOPS"
        echo "• Review database file placement and partitioning"
    fi
    
    echo
    echo -e "${BLUE}Monitoring Commands:${NC}"
    echo "• Watch system: watch -n 2 'vmstat 1 1'"
    echo "• Monitor I/O: iostat -x 2"
    echo "• Database processes: ps aux | grep -E '(mysql|postgres|oracle)'"
    echo "• Check connections: netstat -an | grep :3306 | wc -l"
fi
```

}

# Main execution

vmstat_result=0
conn_result=0
io_result=0

analyze_vmstat
vmstat_result=$?

analyze_connections
conn_result=$?

analyze_iostat
io_result=$?

provide_summary $vmstat_result $conn_result $io_result

echo
echo -e “${BLUE}Analysis completed at $(date)${NC}”