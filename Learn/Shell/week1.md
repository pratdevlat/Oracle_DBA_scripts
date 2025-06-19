**##***Phase 1: Foundation***##**
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



## Day 4: File Operations and Permissions for Oracle Environments

### Core Concepts
- File and directory operations essential for Oracle DBAs
- Understanding permissions in Oracle contexts
- Working with Oracle directory structures

### Key Commands for DBAs
```bash
# Essential file operations
ls -la $ORACLE_HOME/bin          # List Oracle binaries with permissions
find $ORACLE_BASE -name "*.log"  # Find all log files
du -sh $ORACLE_BASE/oradata/*    # Check datafile sizes
df -h /u01                       # Check filesystem usage

# File permissions for Oracle files
chmod 640 $ORACLE_HOME/network/admin/tnsnames.ora
chown oracle:dba /u01/app/oracle/oradata/ORCL/system01.dbf
```

### Practical DBA Example: Oracle File Permissions Checker
```bash
#!/bin/bash
# check_oracle_permissions.sh - Verify Oracle file permissions

ORACLE_HOME="/u01/app/oracle/product/19.0.0/dbhome_1"
ORACLE_BASE="/u01/app/oracle"

echo "=== Oracle File Permissions Check ==="
echo "Date: $(date)"
echo

# Check Oracle binary permissions
echo "Checking Oracle binary permissions..."
if [ -x "$ORACLE_HOME/bin/sqlplus" ]; then
    echo "✓ SQL*Plus is executable"
    ls -l "$ORACLE_HOME/bin/sqlplus"
else
    echo "✗ SQL*Plus permissions issue"
fi

# Check Oracle configuration files
echo -e "\nChecking configuration files..."
CONFIG_FILES=("$ORACLE_HOME/network/admin/tnsnames.ora" 
              "$ORACLE_HOME/network/admin/listener.ora"
              "$ORACLE_HOME/network/admin/sqlnet.ora")

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
        ls -l "$file"
    else
        echo "✗ $file missing"
    fi
done

# Check datafile directory permissions
echo -e "\nChecking datafile directories..."
if [ -d "$ORACLE_BASE/oradata" ]; then
    echo "Datafile directory permissions:"
    ls -ld "$ORACLE_BASE/oradata"
    echo "Sample datafiles:"
    ls -l "$ORACLE_BASE/oradata"/*/*.dbf 2>/dev/null | head -3
fi
```

### Daily Exercise (30 minutes)
Create a script that:
1. Checks if Oracle directories exist
2. Verifies proper ownership (oracle:dba)
3. Reports any permission issues
4. Creates missing directories with correct permissions

---

## Day 5: Process Management for Oracle DBAs

### Core Concepts
- Understanding Oracle processes
- Process monitoring and management
- Signal handling for Oracle processes

### Essential Process Commands
```bash
# Oracle process monitoring
ps -ef | grep oracle           # All Oracle processes
ps -ef | grep pmon             # Database processes
ps -ef | grep tns              # Listener processes
pgrep -f "ora_.*_ORCL"        # Specific database processes

# Process management
kill -TERM <pid>               # Graceful termination
kill -9 <pid>                  # Force kill (last resort)
nohup command &                # Run in background
```

### Practical DBA Example: Oracle Process Monitor
```bash
#!/bin/bash
# oracle_process_monitor.sh - Monitor Oracle database processes

DB_NAME="ORCL"
ORACLE_USER="oracle"

echo "=== Oracle Process Monitor ==="
echo "Database: $DB_NAME"
echo "Timestamp: $(date)"
echo

# Function to check if database is running
check_database_status() {
    local db_name=$1
    local pmon_count=$(pgrep -f "ora_pmon_${db_name}" | wc -l)
    
    if [ $pmon_count -eq 1 ]; then
        echo "✓ Database $db_name is RUNNING"
        return 0
    else
        echo "✗ Database $db_name is DOWN"
        return 1
    fi
}

# Function to check listener status
check_listener_status() {
    local listener_count=$(pgrep -f "tnslsnr" | wc -l)
    
    if [ $listener_count -gt 0 ]; then
        echo "✓ Oracle Listener is RUNNING ($listener_count processes)"
        return 0
    else
        echo "✗ Oracle Listener is DOWN"
        return 1
    fi
}

# Function to display Oracle background processes
show_background_processes() {
    local db_name=$1
    echo -e "\nOracle Background Processes for $db_name:"
    echo "Process Name    PID     CPU%    Memory"
    echo "============================================"
    
    ps -eo pid,pcpu,pmem,comm | grep "ora_.*_${db_name}" | while read pid cpu mem comm; do
        printf "%-12s   %-6s  %-6s  %-6s\n" "$comm" "$pid" "$cpu" "$mem"
    done
}

# Main execution
echo "Database Status Check:"
check_database_status $DB_NAME
db_status=$?

echo -e "\nListener Status Check:"
check_listener_status
listener_status=$?

if [ $db_status -eq 0 ]; then
    show_background_processes $DB_NAME
fi

# Summary
echo -e "\n=== Summary ==="
if [ $db_status -eq 0 ] && [ $listener_status -eq 0 ]; then
    echo "Status: ALL SERVICES RUNNING"
    exit 0
else
    echo "Status: SOME SERVICES DOWN - ATTENTION REQUIRED"
    exit 1
fi
```

### Daily Exercise (30 minutes)
Create a process monitoring script that:
1. Checks all Oracle instances on the server
2. Reports CPU and memory usage for each process
3. Sends alerts if critical processes are missing
4. Logs the status to a monitoring file

---

## Day 6: Input/Output Redirection and Piping for Oracle

### Core Concepts
- Redirecting command output for Oracle operations
- Using pipes to chain Oracle commands
- Error handling with redirection

### Redirection Basics
```bash
# Output redirection
sqlplus / as sysdba <<EOF > database_status.log
SELECT status FROM v\$instance;
EOF

# Error redirection
sqlplus / as sysdba 2> sql_errors.log

# Both output and errors
rman target / > backup.log 2>&1

# Input redirection
sqlplus / as sysdba < startup_script.sql
```

### Practical DBA Example: Database Health Check with Logging
```bash
#!/bin/bash
# db_health_check.sh - Comprehensive database health check with logging

DB_NAME="ORCL"
LOG_DIR="/u01/app/oracle/scripts/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HEALTH_LOG="$LOG_DIR/health_check_${TIMESTAMP}.log"
ERROR_LOG="$LOG_DIR/health_errors_${TIMESTAMP}.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HEALTH_LOG"
}

# Function to execute SQL and capture results
execute_sql() {
    local sql_command="$1"
    local description="$2"
    
    log_message "Executing: $description"
    
    sqlplus -s / as sysdba <<EOF 2>> "$ERROR_LOG"
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
$sql_command
EXIT;
EOF
}

# Start health check
log_message "=== Database Health Check Started ==="
log_message "Database: $DB_NAME"

# Check database status
log_message "Checking database status..."
DB_STATUS=$(execute_sql "SELECT status FROM v\$instance;" "Database Status Check")
echo "Database Status: $DB_STATUS" >> "$HEALTH_LOG"

# Check tablespace usage
log_message "Checking tablespace usage..."
execute_sql "
SELECT 
    tablespace_name,
    ROUND(((total_bytes-free_bytes)/total_bytes)*100,2) as used_percent
FROM (
    SELECT 
        tablespace_name,
        SUM(bytes) as total_bytes
    FROM dba_data_files 
    GROUP BY tablespace_name
) total,
(
    SELECT 
        tablespace_name,
        SUM(bytes) as free_bytes
    FROM dba_free_space 
    GROUP BY tablespace_name
) free
WHERE total.tablespace_name = free.tablespace_name
AND ((total_bytes-free_bytes)/total_bytes)*100 > 85;
" "High Tablespace Usage Check" >> "$HEALTH_LOG"

# Check archive log space
log_message "Checking archive log destination..."
execute_sql "
SELECT 
    dest_name,
    status,
    ROUND(space_limit/1024/1024/1024,2) as space_limit_gb,
    ROUND(space_used/1024/1024/1024,2) as space_used_gb
FROM v\$recovery_file_dest;
" "Archive Log Space Check" >> "$HEALTH_LOG"

# Check for database errors
log_message "Checking for recent database errors..."
execute_sql "
SELECT 
    TO_CHAR(originating_timestamp,'YYYY-MM-DD HH24:MI:SS') as error_time,
    message_text
FROM v\$diag_alert_ext 
WHERE originating_timestamp > SYSDATE - 1
AND message_text LIKE '%ORA-%'
ORDER BY originating_timestamp DESC;
" "Recent Database Errors" >> "$HEALTH_LOG"

log_message "=== Health Check Completed ==="
log_message "Results saved to: $HEALTH_LOG"
log_message "Errors logged to: $ERROR_LOG"

# Send summary via pipe to monitoring system (example)
{
    echo "Database Health Check Summary"
    echo "Database: $DB_NAME"
    echo "Status: $DB_STATUS" 
    echo "Timestamp: $(date)"
    echo "Full report: $HEALTH_LOG"
} | mail -s "DB Health Check - $DB_NAME" dba-team@company.com 2>/dev/null || \
  echo "Mail not configured - check logs manually"
```

### Daily Exercise (45 minutes)
Create a backup verification script that:
1. Runs RMAN list backup commands
2. Redirects output to dated log files
3. Pipes summary information to a dashboard file
4. Handles both success and error scenarios

---

## Day 7: Basic Commands Mastery for DBAs

### Core Concepts
- Mastering grep, awk, sed for log analysis
- Using find for Oracle file management
- Combining commands for powerful Oracle administration

### Essential Command Combinations
```bash
# Log analysis with grep
grep -i "ora-" $ORACLE_BASE/diag/rdbms/orcl/orcl/trace/alert_orcl.log
grep -E "(ERROR|WARNING)" /u01/app/oracle/diag/rdbms/*/trace/alert*.log

# Using awk for structured output
ps -ef | awk '/ora_.*_ORCL/ {print $2, $8}' # PID and process name
df -h | awk '/oradata/ {print $5, $6}'      # Usage and mount point

# Using sed for configuration changes
sed 's/ORCL/TESTDB/g' tnsnames.ora > tnsnames_test.ora

# Find for Oracle file management
find $ORACLE_BASE -name "*.trc" -mtime +7 -exec rm {} \;
find /u01/app/oracle -name "*.aud" -size +100M
```

### Comprehensive DBA Example: Alert Log Analyzer
```bash
#!/bin/bash
# alert_log_analyzer.sh - Advanced Oracle alert log analysis

ORACLE_BASE="/u01/app/oracle"
DB_NAME="ORCL"
ALERT_LOG="$ORACLE_BASE/diag/rdbms/${DB_NAME,,}/$DB_NAME/trace/alert_$DB_NAME.log"
ANALYSIS_DIR="/u01/app/oracle/scripts/analysis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create analysis directory
mkdir -p "$ANALYSIS_DIR"

# Function to analyze errors in the last 24 hours
analyze_recent_errors() {
    local output_file="$ANALYSIS_DIR/errors_${TIMESTAMP}.txt"
    local yesterday=$(date -d "yesterday" +%Y-%m-%d)
    
    echo "=== Error Analysis for last 24 hours ===" > "$output_file"
    echo "Alert Log: $ALERT_LOG" >> "$output_file"
    echo "Analysis Date: $(date)" >> "$output_file"
    echo >> "$output_file"
    
    # Extract errors from yesterday and today
    grep -E "^($(date +%a\ %b\ %d)|$(date -d yesterday +%a\ %b\ %d))" "$ALERT_LOG" | \
    grep -i -E "(ora-|error|failed|corrupt)" | \
    awk '{
        # Count error types
        if (match($0, /ORA-[0-9]+/)) {
            error_code = substr($0, RSTART, RLENGTH)
            error_count[error_code]++
        }
        print $0
    }
    END {
        print "\n=== Error Summary ==="
        for (error in error_count) {
            print error ": " error_count[error] " occurrences"
        }
    }' >> "$output_file"
    
    echo "Error analysis saved to: $output_file"
}

# Function to analyze database startups/shutdowns
analyze_startup_shutdown() {
    local output_file="$ANALYSIS_DIR/startup_shutdown_${TIMESTAMP}.txt"
    
    echo "=== Database Startup/Shutdown Analysis ===" > "$output_file"
    echo >> "$output_file"
    
    # Find startup events
    echo "Recent Database Startups:" >> "$output_file"
    grep -E "(Starting ORACLE instance|Database mounted|Database opened)" "$ALERT_LOG" | \
    tail -10 >> "$output_file"
    
    echo >> "$output_file"
    echo "Recent Database Shutdowns:" >> "$output_file"
    grep -E "(Shutting down instance|Instance shutdown complete)" "$ALERT_LOG" | \
    tail -10 >> "$output_file"
    
    echo "Startup/Shutdown analysis saved to: $output_file"
}

# Function to analyze tablespace usage alerts
analyze_tablespace_alerts() {
    local output_file="$ANALYSIS_DIR/tablespace_alerts_${TIMESTAMP}.txt"
    
    echo "=== Tablespace Usage Alerts ===" > "$output_file"
    echo >> "$output_file"
    
    # Find tablespace related messages
    grep -i -E "(tablespace.*full|unable to extend|ORA-01653|ORA-01654|ORA-01655)" "$ALERT_LOG" | \
    awk '{
        # Extract tablespace name if possible
        if (match($0, /tablespace [A-Z_]+/)) {
            ts_name = substr($0, RSTART+11, RLENGTH-11)
            ts_alerts[ts_name]++
        }
        print $0
    }
    END {
        if (length(ts_alerts) > 0) {
            print "\n=== Tablespace Alert Summary ==="
            for (ts in ts_alerts) {
                print "Tablespace " ts ": " ts_alerts[ts] " alerts"
            }
        }
    }' >> "$output_file"
    
    echo "Tablespace alerts analysis saved to: $output_file"
}

# Function to generate daily summary
generate_daily_summary() {
    local summary_file="$ANALYSIS_DIR/daily_summary_${TIMESTAMP}.txt"
    
    echo "=== Daily Alert Log Summary ===" > "$summary_file"
    echo "Database: $DB_NAME" >> "$summary_file"
    echo "Date: $(date)" >> "$summary_file"
    echo "Alert Log Size: $(ls -lh "$ALERT_LOG" | awk '{print $5}')" >> "$summary_file"
    echo >> "$summary_file"
    
    # Count different types of messages
    echo "Message Counts (last 1000 lines):" >> "$summary_file"
    tail -1000 "$ALERT_LOG" | \
    awk '
    /ORA-/ { ora_errors++ }
    /WARNING/ { warnings++ }
    /ERROR/ { errors++ }
    /Checkpoint/ { checkpoints++ }
    /Log switch/ { log_switches++ }
    END {
        print "ORA Errors: " (ora_errors ? ora_errors : 0)
        print "Warnings: " (warnings ? warnings : 0)
        print "Errors: " (errors ? errors : 0)
        print "Checkpoints: " (checkpoints ? checkpoints : 0)
        print "Log Switches: " (log_switches ? log_switches : 0)
    }' >> "$summary_file"
    
    echo "Daily summary saved to: $summary_file"
}

# Main execution
echo "Starting Alert Log Analysis for $DB_NAME..."
echo "Alert Log Location: $ALERT_LOG"

if [ ! -f "$ALERT_LOG" ]; then
    echo "Error: Alert log not found at $ALERT_LOG"
    exit 1
fi

echo "Performing analysis..."
analyze_recent_errors
analyze_startup_shutdown
analyze_tablespace_alerts
generate_daily_summary

echo "Analysis complete. Results saved in $ANALYSIS_DIR"
echo "Files created:"
ls -la "$ANALYSIS_DIR"/*_${TIMESTAMP}.txt
```

### Daily Exercise (45 minutes)
Create a comprehensive Oracle environment analysis script that:
1. Uses find to locate all Oracle configuration files
2. Uses grep to extract connection information from tnsnames.ora
3. Uses awk to format and summarize database sizes
4. Uses sed to create backup copies of configuration files
5. Combines all commands to create an environment report

---

## Week 1 Wrap-up Exercises

### Integration Project (2 hours)
Combine all Week 1 concepts to create a "Daily DBA Health Check" script that:

1. **File Operations**: Check Oracle file permissions and disk space
2. **Process Management**: Monitor all Oracle processes
3. **I/O Redirection**: Log all activities and redirect errors appropriately
4. **Command Mastery**: Use grep/awk/sed to analyze logs and generate reports

### Key Deliverables
- One comprehensive health check script
- Separate log files for different types of checks
- Error handling for all scenarios
- Email/alert integration for critical issues

### Next Week Preview
Week 2 will focus on:
- Variables and environment management for Oracle
- Functions and modular script design
- Regular expressions for advanced log parsing
- Introduction to control structures with Oracle use cases

### Best Practices Checklist
- [ ] Always use absolute paths for Oracle directories
- [ ] Include proper error handling in every script
- [ ] Log all activities with timestamps
- [ ] Test scripts in non-production environments first
- [ ] Use consistent naming conventions for variables and files
- [ ] Include help/usage information in scripts
- [ ] Validate Oracle environment variables before use
