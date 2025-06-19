#!/bin/bash

#########################################################################
# AWR Report Parser and Analyzer
# Description: Parses Oracle AWR reports (text/HTML) and provides analysis
# Author: Claude
# Version: 1.0
# Usage: ./awr_analyzer.sh [OPTIONS] <awr_report_file>
#########################################################################

# Set strict error handling
set -euo pipefail

# Global variables
SCRIPT_NAME=$(basename "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="AWR_Analysis_${TIMESTAMP}.txt"
LOG_FILE="awr_analyzer_${TIMESTAMP}.log"
TEMP_DIR="/tmp/awr_$$"
EMAIL_RECIPIENT=""
VERBOSE=false
COLORS=true

# Color codes for output
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE="" BOLD="" RESET=""
    COLORS=false
fi

#########################################################################
# Utility Functions
#########################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$*" >&2
    fi
}

error() {
    echo "${RED}ERROR: $*${RESET}" >&2
    log "ERROR: $*"
}

warning() {
    echo "${YELLOW}WARNING: $*${RESET}" >&2
    log "WARNING: $*"
}

info() {
    echo "${BLUE}INFO: $*${RESET}" >&2
    log "INFO: $*"
}

success() {
    echo "${GREEN}SUCCESS: $*${RESET}" >&2
    log "SUCCESS: $*"
}

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

usage() {
    cat << EOF
${BOLD}Usage:${RESET} $SCRIPT_NAME [OPTIONS] <awr_report_file>

${BOLD}Description:${RESET}
    Parse and analyze Oracle AWR reports (text or HTML format)
    Generate comprehensive analysis with anomaly detection

${BOLD}Options:${RESET}
    -e, --email <address>    Email the report to specified address
    -o, --output <file>      Specify output file name (default: AWR_Analysis_<timestamp>.txt)
    -v, --verbose           Enable verbose logging
    -n, --no-colors         Disable colored output
    -h, --help              Show this help message

${BOLD}Examples:${RESET}
    $SCRIPT_NAME awrreport.txt
    $SCRIPT_NAME --email admin@company.com --verbose awrreport.html
    $SCRIPT_NAME -o my_analysis.txt awrreport.txt

${BOLD}Supported Formats:${RESET}
    - Oracle AWR text reports (.txt)
    - Oracle AWR HTML reports (.html)
EOF
}

#########################################################################
# AWR Parsing Functions
#########################################################################

detect_format() {
    local file="$1"
    
    if grep -q "<!DOCTYPE\|<html\|<HTML" "$file" 2>/dev/null; then
        echo "html"
    elif grep -q "WORKLOAD REPOSITORY report\|AWR Report\|Database DB Id" "$file" 2>/dev/null; then
        echo "text"
    else
        echo "unknown"
    fi
}

clean_html() {
    local input="$1"
    # Remove HTML tags and decode common entities
    sed 's/<[^>]*>//g' "$input" | \
    sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&nbsp;/ /g; s/&quot;/"/g' | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
    grep -v '^$'
}

parse_db_info() {
    local file="$1"
    local format="$2"
    
    log "Parsing database information"
    
    {
        echo "=== SYSTEM OVERVIEW ==="
        echo
        
        if [[ "$format" == "html" ]]; then
            # Parse HTML format
            DB_NAME=$(clean_html "$file" | grep -i "DB Name" | head -1 | awk '{print $NF}' 2>/dev/null || echo "N/A")
            DB_ID=$(clean_html "$file" | grep -i "DB Id" | head -1 | awk '{print $NF}' 2>/dev/null || echo "N/A")
            INSTANCE=$(clean_html "$file" | grep -i "Instance" | head -1 | awk '{print $NF}' 2>/dev/null || echo "N/A")
        else
            # Parse text format
            DB_NAME=$(grep -i "DB Name" "$file" | head -1 | awk '{print $NF}' 2>/dev/null || echo "N/A")
            DB_ID=$(grep -i "DB Id" "$file" | head -1 | awk '{print $NF}' 2>/dev/null || echo "N/A")
            INSTANCE=$(grep -i "Instance" "$file" | head -1 | awk '{print $NF}' 2>/dev/null || echo "N/A")
        fi
        
        echo "📊 System Name:           $DB_NAME"
        echo "🔢 System ID:             $DB_ID"
        echo "💻 Server Instance:       $INSTANCE"
        echo
        echo "SUMMARY: This report analyzes the performance of the '$DB_NAME' database system."
        echo
    }
}

parse_snapshot_info() {
    local file="$1"
    local format="$2"
    
    log "Parsing snapshot information"
    
    {
        echo "=== MONITORING PERIOD ==="
        echo
        
        # Extract time information
        if [[ "$format" == "html" ]]; then
            local time_info=$(clean_html "$file" | grep -A 10 -i "snap id\|begin snap\|end snap" | head -20)
        else
            local time_info=$(grep -A 10 -i "snap id\|begin snap\|end snap" "$file" | head -20)
        fi
        
        # Try to extract meaningful time ranges
        local begin_time=$(echo "$time_info" | grep -i "begin\|start" | head -1 | grep -o '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]' || echo "Not available")
        local end_time=$(echo "$time_info" | grep -i "end" | head -1 | grep -o '[0-9][0-9]-[A-Za-z][A-Za-z][A-Za-z]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]' || echo "Not available")
        local duration=$(echo "$time_info" | grep -i "elapsed" | head -1 | grep -o '[0-9]*\.[0-9]*' || echo "Unknown")
        
        echo "⏰ Analysis Period:"
        echo "   From: $begin_time"
        echo "   To:   $end_time"
        if [[ "$duration" != "Unknown" ]]; then
            echo "   Duration: $duration minutes"
        fi
        echo
        echo "SUMMARY: This report covers system performance during the above time period."
        echo
    }
}

parse_db_time() {
    local file="$1"
    local format="$2"
    
    log "Parsing DB Time and elapsed time information"
    
    {
        echo "=== SYSTEM WORKLOAD ANALYSIS ==="
        echo
        
        # Extract DB Time and Elapsed time
        local db_time_line cpu_time_line elapsed_line
        
        if [[ "$format" == "html" ]]; then
            db_time_line=$(clean_html "$file" | grep -i "DB Time" | head -1)
            cpu_time_line=$(clean_html "$file" | grep -i "DB CPU" | head -1)
            elapsed_line=$(clean_html "$file" | grep -i "Elapsed" | head -1)
        else
            db_time_line=$(grep -i "DB Time" "$file" | head -1)
            cpu_time_line=$(grep -i "DB CPU" "$file" | head -1)
            elapsed_line=$(grep -i "Elapsed" "$file" | head -1)
        fi
        
        # Extract numeric values
        local db_time=$(echo "$db_time_line" | grep -o '[0-9]*\.[0-9]*' | head -1)
        local cpu_time=$(echo "$cpu_time_line" | grep -o '[0-9]*\.[0-9]*' | head -1)
        local elapsed_time=$(echo "$elapsed_line" | grep -o '[0-9]*\.[0-9]*' | head -1)
        local cpu_pct=$(echo "$cpu_time_line" | grep -o '[0-9]*\.[0-9]*%' | head -1)
        
        echo "💼 WORKLOAD SUMMARY:"
        if [[ -n "$db_time" ]]; then
            echo "   🕐 Total Work Done: $db_time minutes"
        fi
        if [[ -n "$cpu_time" ]]; then
            echo "   ⚡ Processing Time: $cpu_time minutes"
        fi
        if [[ -n "$elapsed_time" ]]; then
            echo "   ⏱️  Real Time Passed: $elapsed_time minutes"
        fi
        if [[ -n "$cpu_pct" ]]; then
            echo "   📊 Processing Efficiency: $cpu_pct of total work"
        fi
        echo
        
        # Calculate efficiency if we have the data
        if [[ -n "$db_time" && -n "$elapsed_time" ]]; then
            local efficiency=$(echo "scale=1; $db_time / $elapsed_time" | bc 2>/dev/null || echo "N/A")
            if [[ "$efficiency" != "N/A" ]]; then
                echo "📈 EFFICIENCY ANALYSIS:"
                if (( $(echo "$efficiency > 2.0" | bc -l 2>/dev/null || echo 0) )); then
                    echo "   Status: HIGH ACTIVITY - System was very busy (${efficiency}x normal load)"
                elif (( $(echo "$efficiency > 1.5" | bc -l 2>/dev/null || echo 0) )); then
                    echo "   Status: BUSY - System had heavy workload (${efficiency}x normal load)"
                elif (( $(echo "$efficiency > 0.8" | bc -l 2>/dev/null || echo 0) )); then
                    echo "   Status: NORMAL - System had typical workload (${efficiency}x normal load)"
                else
                    echo "   Status: LIGHT - System had low workload (${efficiency}x normal load)"
                fi
            fi
        fi
        echo
        echo "SUMMARY: This shows how hard the system was working during the monitoring period."
        echo
    }
}

parse_active_sessions() {
    local file="$1"
    local format="$2"
    
    log "Parsing average active sessions"
    
    {
        echo "=== USER ACTIVITY LEVEL ==="
        echo
        
        # Extract session information
        local avg_sessions max_sessions
        
        if [[ "$format" == "html" ]]; then
            avg_sessions=$(clean_html "$file" | grep -i "Average Active Sessions\|AAS" | grep -o '[0-9]*\.[0-9]*' | head -1)
            max_sessions=$(clean_html "$file" | grep -i "Maximum.*Sessions" | grep -o '[0-9]*' | head -1)
        else
            avg_sessions=$(grep -i "Average Active Sessions\|AAS" "$file" | grep -o '[0-9]*\.[0-9]*' | head -1)
            max_sessions=$(grep -i "Maximum.*Sessions" "$file" | grep -o '[0-9]*' | head -1)
        fi
        
        echo "👥 USER ACTIVITY:"
        if [[ -n "$avg_sessions" ]]; then
            echo "   📊 Average Users Working: $avg_sessions"
            
            # Interpret the session count
            if (( $(echo "$avg_sessions > 10" | bc -l 2>/dev/null || echo 0) )); then
                echo "   📈 Activity Level: HIGH - System serving many concurrent users"
            elif (( $(echo "$avg_sessions > 5" | bc -l 2>/dev/null || echo 0) )); then
                echo "   📊 Activity Level: MODERATE - Normal user activity"
            elif (( $(echo "$avg_sessions > 1" | bc -l 2>/dev/null || echo 0) )); then
                echo "   📉 Activity Level: LOW - Light user activity"
            else
                echo "   💤 Activity Level: VERY LOW - Minimal user activity"
            fi
        fi
        
        if [[ -n "$max_sessions" ]]; then
            echo "   🔝 Peak Users: $max_sessions (highest concurrent users)"
        fi
        
        echo
        echo "SUMMARY: This shows how many people were actively using the system."
        echo
    }
}

parse_wait_events() {
    local file="$1"
    local format="$2"
    
    log "Parsing top wait events"
    
    {
        echo "=== PERFORMANCE BOTTLENECKS ==="
        echo
        
        # Extract wait events and translate to business terms
        local wait_events
        if [[ "$format" == "html" ]]; then
            wait_events=$(clean_html "$file" | awk '/Top.*Wait Events/,/^$/ {print}' | head -15)
        else
            wait_events=$(awk '/Top.*Wait Events/,/^$/ {print}' "$file" | head -15)
        fi
        
        echo "🚦 WHAT SLOWED DOWN THE SYSTEM:"
        echo
        
        # Parse and translate common wait events
        echo "$wait_events" | while IFS= read -r line; do
            if [[ "$line" =~ "CPU time" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   ⚡ Processing Work: $pct of time spent doing actual work"
            elif [[ "$line" =~ "db file sequential read" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   💽 Reading Data Files: $pct of time waiting to read individual records"
            elif [[ "$line" =~ "db file scattered read" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   📂 Scanning Large Data: $pct of time reading multiple records at once"
            elif [[ "$line" =~ "log file sync" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   💾 Saving Changes: $pct of time ensuring data is safely written"
            elif [[ "$line" =~ "buffer busy" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   🔄 Memory Conflicts: $pct of time waiting for memory access"
            elif [[ "$line" =~ "latch" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   🔒 Internal Coordination: $pct of time coordinating system resources"
            elif [[ "$line" =~ "library cache" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   📚 Code Management: $pct of time managing application code"
            elif [[ "$line" =~ "enq:" ]]; then
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*%')
                echo "   ⏳ Resource Waiting: $pct of time waiting for shared resources"
            fi
        done
        
        echo
        echo "SUMMARY: These are the main reasons the system had to wait, ranked by impact."
        echo "💡 TIP: Higher percentages indicate bigger performance problems to investigate."
        echo
    }
}

parse_efficiency() {
    local file="$1"
    local format="$2"
    
    log "Parsing instance efficiency percentages"
    
    {
        echo "=== SYSTEM HEALTH SCORECARD ==="
        echo
        
        # Extract efficiency metrics
        local buffer_hit library_hit soft_parse redo_nowait
        
        if [[ "$format" == "html" ]]; then
            buffer_hit=$(clean_html "$file" | grep -i "Buffer Hit" | grep -o '[0-9]*\.[0-9]*' | head -1)
            library_hit=$(clean_html "$file" | grep -i "Library Hit" | grep -o '[0-9]*\.[0-9]*' | head -1)
            soft_parse=$(clean_html "$file" | grep -i "Soft Parse" | grep -o '[0-9]*\.[0-9]*' | head -1)
            redo_nowait=$(clean_html "$file" | grep -i "Redo NoWait" | grep -o '[0-9]*\.[0-9]*' | head -1)
        else
            buffer_hit=$(grep -i "Buffer Hit" "$file" | grep -o '[0-9]*\.[0-9]*' | head -1)
            library_hit=$(grep -i "Library Hit" "$file" | grep -o '[0-9]*\.[0-9]*' | head -1)
            soft_parse=$(grep -i "Soft Parse" "$file" | grep -o '[0-9]*\.[0-9]*' | head -1)
            redo_nowait=$(grep -i "Redo NoWait" "$file" | grep -o '[0-9]*\.[0-9]*' | head -1)
        fi
        
        echo "📊 PERFORMANCE SCORES (Higher = Better):"
        echo
        
        # Buffer Hit Ratio
        if [[ -n "$buffer_hit" ]]; then
            echo "   💾 Memory Usage Efficiency: ${buffer_hit}%"
            if (( $(echo "$buffer_hit >= 95" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ EXCELLENT - Memory is used very efficiently"
            elif (( $(echo "$buffer_hit >= 90" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ GOOD - Memory usage is acceptable"
            elif (( $(echo "$buffer_hit >= 80" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ⚠️ FAIR - Memory could be used more efficiently"
            else
                echo "      Status: ❌ POOR - Memory usage needs improvement"
            fi
            echo
        fi
        
        # Library Hit Ratio
        if [[ -n "$library_hit" ]]; then
            echo "   📚 Code Reuse Efficiency: ${library_hit}%"
            if (( $(echo "$library_hit >= 95" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ EXCELLENT - Code is being reused effectively"
            elif (( $(echo "$library_hit >= 90" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ GOOD - Code reuse is acceptable"
            else
                echo "      Status: ⚠️ NEEDS IMPROVEMENT - Too much code recompilation"
            fi
            echo
        fi
        
        # Soft Parse Ratio
        if [[ -n "$soft_parse" ]]; then
            echo "   🔄 Query Optimization: ${soft_parse}%"
            if (( $(echo "$soft_parse >= 95" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ EXCELLENT - Queries are well optimized"
            elif (( $(echo "$soft_parse >= 80" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ GOOD - Query optimization is acceptable"
            else
                echo "      Status: ❌ POOR - Queries need better optimization"
            fi
            echo
        fi
        
        # Redo NoWait
        if [[ -n "$redo_nowait" ]]; then
            echo "   💾 Transaction Processing: ${redo_nowait}%"
            if (( $(echo "$redo_nowait >= 99" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ EXCELLENT - Transactions process smoothly"
            elif (( $(echo "$redo_nowait >= 95" | bc -l 2>/dev/null || echo 0) )); then
                echo "      Status: ✅ GOOD - Transaction processing is acceptable"
            else
                echo "      Status: ⚠️ NEEDS ATTENTION - Transaction bottlenecks detected"
            fi
            echo
        fi
        
        echo "SUMMARY: These scores show how efficiently the system uses its resources."
        echo "💡 TIP: Scores below 90% usually indicate areas for performance improvement."
        echo
    }
}

parse_load_profile() {
    local file="$1"
    local format="$2"
    
    log "Parsing load profile"
    
    {
        echo "=== SYSTEM ACTIVITY BREAKDOWN ==="
        echo
        
        # Extract key load profile metrics
        local logical_reads physical_reads user_calls executes parses
        
        if [[ "$format" == "html" ]]; then
            logical_reads=$(clean_html "$file" | grep -i "Logical reads" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            physical_reads=$(clean_html "$file" | grep -i "Physical reads" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            user_calls=$(clean_html "$file" | grep -i "User calls" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            executes=$(clean_html "$file" | grep -i "Executes" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            parses=$(clean_html "$file" | grep -i "Parses" | grep -o '[0-9,]*' | head -1 | tr -d ',')
        else
            logical_reads=$(grep -i "Logical reads" "$file" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            physical_reads=$(grep -i "Physical reads" "$file" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            user_calls=$(grep -i "User calls" "$file" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            executes=$(grep -i "Executes" "$file" | grep -o '[0-9,]*' | head -1 | tr -d ',')
            parses=$(grep -i "Parses" "$file" | grep -o '[0-9,]*' | head -1 | tr -d ',')
        fi
        
        echo "📈 SYSTEM ACTIVITY SUMMARY (Per Second):"
        echo
        
        if [[ -n "$logical_reads" ]]; then
            echo "   📖 Data Requests: $(printf "%'d" $logical_reads 2>/dev/null || echo $logical_reads)"
            echo "      What it means: How many times the system looked for data"
        fi
        
        if [[ -n "$physical_reads" ]]; then
            echo "   💽 Disk Access: $(printf "%'d" $physical_reads 2>/dev/null || echo $physical_reads)"
            echo "      What it means: How many times the system had to read from disk"
            
            # Calculate hit ratio if we have both metrics
            if [[ -n "$logical_reads" && "$logical_reads" -gt 0 ]]; then
                local hit_ratio=$(echo "scale=1; (($logical_reads - $physical_reads) * 100) / $logical_reads" | bc 2>/dev/null || echo "N/A")
                if [[ "$hit_ratio" != "N/A" ]]; then
                    echo "      📊 Memory Hit Rate: ${hit_ratio}% (${logical_reads} requests, ${physical_reads} from disk)"
                fi
            fi
        fi
        
        if [[ -n "$user_calls" ]]; then
            echo "   👥 User Requests: $(printf "%'d" $user_calls 2>/dev/null || echo $user_calls)"
            echo "      What it means: How many requests came from applications/users"
        fi
        
        if [[ -n "$executes" ]]; then
            echo "   ⚡ Commands Run: $(printf "%'d" $executes 2>/dev/null || echo $executes)"
            echo "      What it means: How many database commands were executed"
        fi
        
        if [[ -n "$parses" ]]; then
            echo "   🔍 Query Analysis: $(printf "%'d" $parses 2>/dev/null || echo $parses)"
            echo "      What it means: How many times queries needed to be interpreted"
        fi
        
        echo
        echo "SUMMARY: This shows the volume of different types of work the system performed."
        echo "💡 TIP: High disk access compared to data requests may indicate memory issues."
        echo
    }
}

parse_top_sql() {
    local file="$1"
    local format="$2"
    
    log "Parsing top SQL statements"
    
    {
        echo "=== TOP SQL BY CPU/ELAPSED TIME ==="
        echo
        
        if [[ "$format" == "html" ]]; then
            clean_html "$file" | awk '/SQL ordered by CPU Time/,/SQL ordered by Elapsed Time/ {print}' | head -30
            echo
            clean_html "$file" | awk '/SQL ordered by Elapsed Time/,/^[[:space:]]*$/ {print}' | head -20
        else
            awk '/SQL ordered by CPU Time/,/SQL ordered by Elapsed Time/ {print}' "$file" | head -30
            echo
            awk '/SQL ordered by Elapsed Time/,/^[[:space:]]*$/ {print}' "$file" | head -20
        fi
        echo
    }
}

parse_tablespace_io() {
    local file="$1"
    local format="$2"
    
    log "Parsing tablespace I/O statistics"
    
    {
        echo "=== TABLESPACE I/O STATISTICS ==="
        echo
        
        if [[ "$format" == "html" ]]; then
            clean_html "$file" | awk '/Tablespace IO Stats/,/^[[:space:]]*$/ {print}' | head -30
        else
            awk '/Tablespace IO Stats/,/^[[:space:]]*$/ {print}' "$file" | head -30
        fi
        echo
    }
}

#########################################################################
# Analysis Functions
#########################################################################

analyze_anomalies() {
    local file="$1"
    local format="$2"
    
    log "Analyzing for anomalies"
    
    {
        echo "=== ANOMALY ANALYSIS ==="
        echo
        
        # Check buffer cache hit ratio
        local buffer_hit
        if [[ "$format" == "html" ]]; then
            buffer_hit=$(clean_html "$file" | grep -i "buffer.*hit" | grep -o '[0-9]*\.[0-9]*' | head -1)
        else
            buffer_hit=$(grep -i "buffer.*hit" "$file" | grep -o '[0-9]*\.[0-9]*' | head -1)
        fi
        
        if [[ -n "$buffer_hit" ]] && (( $(echo "$buffer_hit < 90" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠️  CRITICAL: Buffer Cache Hit Ratio is ${buffer_hit}% (< 90%)"
        fi
        
        # Check for high wait events
        if [[ "$format" == "html" ]]; then
            clean_html "$file" | grep -A 10 -i "wait.*event" | grep -E "[0-9]+\.[0-9]+.*%" | while read -r line; do
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*' | head -1)
                if [[ -n "$pct" ]] && (( $(echo "$pct > 20" | bc -l 2>/dev/null || echo 0) )); then
                    echo "⚠️  HIGH WAIT: $line"
                fi
            done
        else
            grep -A 10 -i "wait.*event" "$file" | grep -E "[0-9]+\.[0-9]+.*%" | while read -r line; do
                local pct=$(echo "$line" | grep -o '[0-9]*\.[0-9]*' | head -1)
                if [[ -n "$pct" ]] && (( $(echo "$pct > 20" | bc -l 2>/dev/null || echo 0) )); then
                    echo "⚠️  HIGH WAIT: $line"
                fi
            done
        fi
        
        # Check for high hard parse ratio
        local hard_parse
        if [[ "$format" == "html" ]]; then
            hard_parse=$(clean_html "$file" | grep -i "hard parse" | grep -o '[0-9]*\.[0-9]*' | head -1)
        else
            hard_parse=$(grep -i "hard parse" "$file" | grep -o '[0-9]*\.[0-9]*' | head -1)
        fi
        
        if [[ -n "$hard_parse" ]] && (( $(echo "$hard_parse > 10" | bc -l 2>/dev/null || echo 0) )); then
            echo "⚠️  HIGH HARD PARSE: Hard Parse Ratio is ${hard_parse}% (> 10%)"
        fi
        
        echo
    }
}

#########################################################################
# Email Function
#########################################################################

send_email() {
    local recipient="$1"
    local report_file="$2"
    
    if ! command -v mail >/dev/null 2>&1 && ! command -v sendmail >/dev/null 2>&1; then
        warning "No mail command available. Cannot send email."
        return 1
    fi
    
    local subject="AWR Analysis Report - $(date '+%Y-%m-%d %H:%M:%S')"
    
    if command -v mail >/dev/null 2>&1; then
        mail -s "$subject" "$recipient" < "$report_file"
    elif command -v sendmail >/dev/null 2>&1; then
        {
            echo "To: $recipient"
            echo "Subject: $subject"
            echo "Content-Type: text/plain"
            echo
            cat "$report_file"
        } | sendmail "$recipient"
    fi
    
    log "Email sent to $recipient"
}

#########################################################################
# Main Function
#########################################################################

main() {
    local input_file=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--email)
                EMAIL_RECIPIENT="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--no-colors)
                COLORS=false
                RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE="" BOLD="" RESET=""
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$input_file" ]]; then
                    input_file="$1"
                else
                    error "Multiple input files specified"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate input file
    if [[ -z "$input_file" ]]; then
        error "No input file specified"
        usage
        exit 1
    fi
    
    if [[ ! -f "$input_file" ]]; then
        error "Input file does not exist: $input_file"
        exit 1
    fi
    
    if [[ ! -r "$input_file" ]]; then
        error "Cannot read input file: $input_file"
        exit 1
    fi
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    trap cleanup EXIT
    
    # Detect file format
    local format
    format=$(detect_format "$input_file")
    
    if [[ "$format" == "unknown" ]]; then
        error "Unable to detect AWR report format in file: $input_file"
        exit 1
    fi
    
    info "Detected format: $format"
    info "Processing AWR report: $input_file"
    info "Output file: $OUTPUT_FILE"
    
    # Start analysis
    {
        echo "##################################################################################"
        echo "# AWR REPORT ANALYSIS"
        echo "# Generated: $(date)"
        echo "# Source File: $input_file"
        echo "# Format: $format"
        echo "##################################################################################"
        echo
        
        parse_db_info "$input_file" "$format"
        parse_snapshot_info "$input_file" "$format"
        parse_db_time "$input_file" "$format"
        parse_active_sessions "$input_file" "$format"
        parse_wait_events "$input_file" "$format"
        parse_efficiency "$input_file" "$format"
        parse_load_profile "$input_file" "$format"
        parse_top_sql "$input_file" "$format"
        parse_tablespace_io "$input_file" "$format"
        analyze_anomalies "$input_file" "$format"
        
        echo "##################################################################################"
        echo "# END OF ANALYSIS"
        echo "# Generated by: $SCRIPT_NAME"
        echo "# Timestamp: $(date)"
        echo "##################################################################################"
        
    } > "$OUTPUT_FILE"
    
    success "Analysis completed successfully"
    success "Report saved to: $OUTPUT_FILE"
    
    # Send email if requested
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        info "Sending email to: $EMAIL_RECIPIENT"
        if send_email "$EMAIL_RECIPIENT" "$OUTPUT_FILE"; then
            success "Email sent successfully"
        else
            warning "Failed to send email"
        fi
    fi
    
    # Display summary
    echo
    echo "${BOLD}Analysis Summary:${RESET}"
    echo "  Input File:    $input_file"
    echo "  Format:        $format"
    echo "  Output File:   $OUTPUT_FILE"
    echo "  Log File:      $LOG_FILE"
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        echo "  Email Sent:    $EMAIL_RECIPIENT"
    fi
    echo
}

#########################################################################
# Script Entry Point
#########################################################################

# Check for required commands
for cmd in awk sed grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "Required command not found: $cmd"
        exit 1
    fi
done

# Run main function
main "$@"