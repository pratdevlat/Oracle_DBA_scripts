I'll help you create a comprehensive learning plan for Days 1-3 of Week 1, focusing on shell scripting fundamentals with Oracle DBA-specific applications. Let me break this down into daily modules with practical exercises.

## Day 1: Shell Environment and Basic Commands

### Morning Session (2-3 hours)
**Topic: Understanding the Shell Environment**

**Concepts:**
- What is a shell? (bash, sh, ksh differences)
- Setting up your learning environment
- Understanding the terminal and command prompt
- Environment variables and PATH

**Practical DBA Exercise 1.1: Oracle Environment Setup Script**
```bash
#!/bin/bash
# my_oracle_env.sh - Your first Oracle environment script

# Display current shell
echo "Current Shell: $SHELL"
echo "Shell Version: $BASH_VERSION"

# Set Oracle environment variables
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=ORCL
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

# Display Oracle environment
echo "=== Oracle Environment ==="
echo "ORACLE_HOME: $ORACLE_HOME"
echo "ORACLE_SID: $ORACLE_SID"
echo "PATH includes Oracle: $(echo $PATH | grep -o $ORACLE_HOME/bin)"

# Check if Oracle binaries are accessible
if command -v sqlplus >/dev/null 2>&1; then
    echo "✓ sqlplus found in PATH"
else
    echo "✗ sqlplus NOT found in PATH"
fi
```

### Afternoon Session (2-3 hours)
**Topic: Basic Commands for DBAs**

**Essential Commands:**
- `ps` - Process monitoring
- `grep` - Pattern searching
- `echo` - Output display
- `cat`, `head`, `tail` - File viewing
- `which`, `whereis` - Finding executables

**Practical DBA Exercise 1.2: Oracle Process Monitor**
```bash
#!/bin/bash
# check_oracle_processes.sh - Monitor Oracle background processes

echo "=== Oracle Database Processes ==="
echo "Checking for Oracle processes..."

# Check for PMON process (Process Monitor)
if ps -ef | grep -v grep | grep "ora_pmon_$ORACLE_SID" > /dev/null; then
    echo "✓ PMON is running"
    ps -ef | grep "ora_pmon_$ORACLE_SID" | grep -v grep
else
    echo "✗ PMON is NOT running - Database may be down"
fi

# Check for other critical background processes
for process in smon lgwr dbwr ckpt
do
    echo -n "Checking $process: "
    if ps -ef | grep -v grep | grep "ora_${process}_$ORACLE_SID" > /dev/null; then
        echo "✓ Running"
    else
        echo "✗ Not found"
    fi
done

# Count total Oracle processes
total_procs=$(ps -ef | grep "ora_" | grep -v grep | wc -l)
echo "Total Oracle processes: $total_procs"
```

**Hands-on Practice:**
1. Create the scripts above and make them executable with `chmod +x`
2. Run them and observe the output
3. Modify the environment script for your Oracle installation
4. Add more process checks to the monitoring script

## Day 2: Variables, Input/Output, and File Operations

### Morning Session (2-3 hours)
**Topic: Variables and User Input**

**Concepts:**
- Variable declaration and usage
- Command substitution
- Reading user input
- Special variables ($?, $#, $@, etc.)

**Practical DBA Exercise 2.1: Interactive Database Connection Checker**
```bash
#!/bin/bash
# db_connect_check.sh - Interactive database connection tester

# Prompt for database details
echo "=== Oracle Database Connection Checker ==="
read -p "Enter username: " username
read -s -p "Enter password: " password
echo # New line after password
read -p "Enter database SID or service name: " db_identifier

# Store connection result
connection_test=$(sqlplus -s /nolog <<EOF
connect ${username}/${password}@${db_identifier}
select 'CONNECTION_SUCCESS' from dual;
exit;
EOF
)

# Check connection status
if echo "$connection_test" | grep -q "CONNECTION_SUCCESS"; then
    echo "✓ Successfully connected to database!"
    
    # Get database version
    db_version=$(sqlplus -s ${username}/${password}@${db_identifier} <<EOF
set heading off feedback off
select version from v\$instance;
exit;
EOF
)
    echo "Database Version: $db_version"
else
    echo "✗ Connection failed!"
    echo "Error details:"
    echo "$connection_test" | grep -E "ORA-|SP2-"
fi
```

### Afternoon Session (2-3 hours)
**Topic: Input/Output Redirection and File Operations**

**Concepts:**
- Standard streams (stdin, stdout, stderr)
- Redirection operators (>, >>, <, 2>, &>)
- Pipes and command chaining
- File permissions for Oracle files

**Practical DBA Exercise 2.2: Alert Log Monitor with Logging**
```bash
#!/bin/bash
# alert_log_monitor.sh - Monitor alert log for errors

# Variables
ORACLE_BASE=/u01/app/oracle
ALERT_LOG="${ORACLE_BASE}/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log"
LOG_DIR="$HOME/oracle_monitoring/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MONITOR_LOG="${LOG_DIR}/alert_monitor_${TIMESTAMP}.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$MONITOR_LOG"
}

# Check if alert log exists
if [ ! -f "$ALERT_LOG" ]; then
    log_message "ERROR: Alert log not found at $ALERT_LOG"
    exit 1
fi

log_message "Starting alert log monitoring..."
log_message "Alert log: $ALERT_LOG"

# Check for ORA- errors in the last 100 lines
log_message "Checking for recent errors..."
recent_errors=$(tail -100 "$ALERT_LOG" | grep -E "ORA-[0-9]{4,5}" 2>/dev/null)

if [ -n "$recent_errors" ]; then
    log_message "WARNING: Found recent errors in alert log!"
    echo "$recent_errors" | while read -r error_line; do
        log_message "ERROR: $error_line"
    done
else
    log_message "No recent errors found in alert log"
fi

# Check file size and growth
file_size=$(du -h "$ALERT_LOG" | cut -f1)
log_message "Alert log size: $file_size"

# Save monitoring results
echo "=== Alert Log Monitoring Report ===" > "${LOG_DIR}/alert_summary_${TIMESTAMP}.txt"
echo "Generated: $(date)" >> "${LOG_DIR}/alert_summary_${TIMESTAMP}.txt"
echo "Alert Log: $ALERT_LOG" >> "${LOG_DIR}/alert_summary_${TIMESTAMP}.txt"
echo "Size: $file_size" >> "${LOG_DIR}/alert_summary_${TIMESTAMP}.txt"
echo "Recent Errors:" >> "${LOG_DIR}/alert_summary_${TIMESTAMP}.txt"
echo "$recent_errors" >> "${LOG_DIR}/alert_summary_${TIMESTAMP}.txt"

log_message "Monitoring complete. Report saved to ${LOG_DIR}/alert_summary_${TIMESTAMP}.txt"
```

**Hands-on Practice:**
1. Create and test both scripts
2. Experiment with different redirection operators
3. Modify the alert log monitor to check for specific error codes
4. Create a script that backs up important Oracle configuration files

## Day 3: Basic Text Processing and Practical Automation

### Morning Session (2-3 hours)
**Topic: Text Processing with grep, awk, and sed basics**

**Concepts:**
- Pattern matching with grep
- Basic awk for column extraction
- Simple sed substitutions
- Combining commands with pipes

**Practical DBA Exercise 3.1: Database Performance Quick Check**
```bash
#!/bin/bash
# db_performance_check.sh - Quick database performance overview

# Function to execute SQL and return results
execute_sql() {
    sqlplus -s / as sysdba <<EOF
set pagesize 0 feedback off heading off
$1
exit;
EOF
}

echo "=== Database Performance Quick Check ==="
echo "Report generated: $(date)"
echo "----------------------------------------"

# Check database status
echo "1. Database Status:"
db_status=$(execute_sql "select status from v\$instance;")
echo "   Database is: $db_status"

# Check active sessions
echo -e "\n2. Active Sessions:"
active_sessions=$(execute_sql "select count(*) from v\$session where status='ACTIVE' and type='USER';")
echo "   Active user sessions: $active_sessions"

# Top 5 sessions by CPU
echo -e "\n3. Top CPU Consuming Sessions:"
sqlplus -s / as sysdba <<EOF | grep -v "^$" | head -6
set linesize 200 pagesize 50
col username format a20
col program format a30
select username, sid, serial#, cpu_time/1000000 as cpu_seconds, program
from v\$session
where type='USER' and status='ACTIVE'
order by cpu_time desc
fetch first 5 rows only;
exit;
EOF

# Check tablespace usage
echo -e "\n4. Tablespace Usage (>80%):"
sqlplus -s / as sysdba <<EOF | awk '$5 > 80 {print "   "$1": "$5"% used ("$3"MB free)"}' 
set pagesize 0 feedback off
select tablespace_name,
       round(used_space*8192/1024/1024,2) used_mb,
       round(free_space*8192/1024/1024,2) free_mb,
       round(total_space*8192/1024/1024,2) total_mb,
       round((used_space/total_space)*100,2) pct_used
from (
    select tablespace_name,
           sum(decode(autoextensible,'NO',blocks,maxblocks)) total_space,
           sum(blocks) used_space,
           sum(decode(autoextensible,'NO',blocks,maxblocks)) - sum(blocks) free_space
    from dba_data_files
    group by tablespace_name
);
exit;
EOF

# Recent wait events
echo -e "\n5. Top Wait Events (last 5 minutes):"
sqlplus -s / as sysdba <<EOF | sed 's/  */ /g' | column -t
set pagesize 0 feedback off
col event format a40
select event, total_waits, time_waited_micro/1000000 as seconds_waited
from v\$system_event
where event not like '%idle%'
and event not like '%timer%'
order by time_waited_micro desc
fetch first 5 rows only;
exit;
EOF
```

### Afternoon Session (2-3 hours)
**Topic: Putting It All Together - Your First Automation Script**

**Practical DBA Exercise 3.2: Comprehensive Daily Health Check**
```bash
#!/bin/bash
# daily_health_check.sh - Automated daily database health check

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT_DIR="${SCRIPT_DIR}/health_reports"
REPORT_DATE=$(date +"%Y%m%d")
REPORT_FILE="${REPORT_DIR}/health_check_${ORACLE_SID}_${REPORT_DATE}.html"
EMAIL_TO="dba-team@company.com"

# Create report directory
mkdir -p "$REPORT_DIR"

# Start HTML report
cat > "$REPORT_FILE" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Database Health Check - $ORACLE_SID - $REPORT_DATE</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; border-bottom: 2px solid #ddd; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        pre { background-color: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>Database Health Check Report</h1>
    <p><strong>Database:</strong> $ORACLE_SID</p>
    <p><strong>Generated:</strong> $(date)</p>
    <p><strong>Host:</strong> $(hostname)</p>
EOF

# Function to add section to HTML report
add_section() {
    local title="$1"
    local content="$2"
    local status="$3"
    
    echo "<h2>$title</h2>" >> "$REPORT_FILE"
    if [ -n "$status" ]; then
        echo "<p class='$status'>Status: ${status^^}</p>" >> "$REPORT_FILE"
    fi
    echo "<pre>$content</pre>" >> "$REPORT_FILE"
}

# 1. Database Status Check
echo "Checking database status..."
db_check=$(sqlplus -s / as sysdba <<EOF
set heading off feedback off
select 'STATUS:'||status from v\$instance;
select 'UPTIME:'||to_char(startup_time,'DD-MON-YYYY HH24:MI:SS') from v\$instance;
exit;
EOF
)

if echo "$db_check" | grep -q "STATUS:OPEN"; then
    add_section "Database Status" "$db_check" "success"
else
    add_section "Database Status" "$db_check" "error"
fi

# 2. Space Usage Check
echo "Checking space usage..."
space_check=$(sqlplus -s / as sysdba <<EOF
set pagesize 100 linesize 200
col tablespace_name format a30
col pct_used format 999.99
select tablespace_name, 
       round((used_space/total_space)*100,2) as pct_used,
       round(free_space*8192/1024/1024,2) as free_mb
from (
    select tablespace_name,
           sum(blocks) used_space,
           sum(decode(autoextensible,'NO',blocks,maxblocks)) total_space,
           sum(decode(autoextensible,'NO',blocks,maxblocks)) - sum(blocks) free_space
    from dba_data_files
    group by tablespace_name
)
order by 2 desc;
exit;
EOF
)

# Check if any tablespace is over 90%
if echo "$space_check" | awk '$2 > 90 {exit 1}'; then
    add_section "Tablespace Usage" "$space_check" "success"
else
    add_section "Tablespace Usage" "$space_check" "warning"
fi

# 3. Alert Log Errors
echo "Checking alert log..."
if [ -f "$ORACLE_BASE/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log" ]; then
    alert_errors=$(tail -500 "$ORACLE_BASE/diag/rdbms/${ORACLE_SID,,}/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log" | grep -E "ORA-[0-9]{4,5}" | tail -10)
    if [ -z "$alert_errors" ]; then
        add_section "Alert Log Check" "No recent errors found" "success"
    else
        add_section "Alert Log Check" "$alert_errors" "warning"
    fi
else
    add_section "Alert Log Check" "Alert log not found!" "error"
fi

# Close HTML report
echo "</body></html>" >> "$REPORT_FILE"

echo "Health check complete. Report saved to: $REPORT_FILE"

# Optional: Send email (uncomment if mail is configured)
# mail -s "Database Health Check - $ORACLE_SID - $REPORT_DATE" "$EMAIL_TO" < "$REPORT_FILE"
```

## End of Day 3 Exercises

### Comprehensive Practice Project
Create a "DBA Toolkit" directory with the following structure:
```
dba_toolkit/
├── scripts/
│   ├── check_db_status.sh
│   ├── monitor_space.sh
│   ├── check_performance.sh
│   └── daily_health_check.sh
├── logs/
├── reports/
└── config/
    └── db_list.txt
```

### Homework Assignments:

1. **Day 1 Assignment**: Modify the Oracle process monitor to check processes for multiple databases listed in a configuration file.

2. **Day 2 Assignment**: Create a script that monitors the alert log in real-time and sends notifications when specific errors appear.

3. **Day 3 Assignment**: Enhance the daily health check script to:
   - Include backup status verification
   - Check for invalid objects
   - Monitor temp tablespace usage
   - Add color coding to the terminal output

### Key Learning Points to Review:
- Always use absolute paths in production scripts
- Include error checking after every critical command
- Log all automated actions for troubleshooting
- Test scripts thoroughly in non-production environments first
- Use meaningful variable names and add comments
- Consider security implications (never hardcode passwords)

Ready to move on to Day 4 when you've completed these exercises! Feel free to ask questions about any of the scripts or concepts.
