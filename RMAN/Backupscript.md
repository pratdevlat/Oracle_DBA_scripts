# Oracle RMAN Backup Operations Complete Guide

## Table of Contents
1. [Full Database Backups with Compression and Encryption](#full-database-backups)
2. [Incremental Backup Strategies](#incremental-backups)
3. [Archive Log Backup with Cleanup](#archive-log-backup)
4. [Performance Optimization](#performance-optimization)
5. [Dynamic Backup Scripts](#dynamic-scripts)
6. [Monitoring and Validation](#monitoring)
7. [Troubleshooting](#troubleshooting)

## Full Database Backups with Compression and Encryption {#full-database-backups}

### Compression Options

#### BASIC Compression (Default)
```sql
-- Basic compression (fastest, moderate space savings)
RMAN> BACKUP AS COMPRESSED BACKUPSET DATABASE;

-- Configure compression globally
RMAN> CONFIGURE COMPRESSION ALGORITHM 'BASIC';
RMAN> BACKUP DATABASE;
```

#### MEDIUM Compression (Recommended)
```sql
-- Medium compression (balanced performance and space savings)
RMAN> BACKUP AS COMPRESSED BACKUPSET USING 'MEDIUM' DATABASE;

-- Configure globally
RMAN> CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
RMAN> BACKUP DATABASE;
```

#### HIGH Compression (Maximum Space Savings)
```sql
-- High compression (slower but maximum space savings)
RMAN> BACKUP AS COMPRESSED BACKUPSET USING 'HIGH' DATABASE;

-- Configure globally
RMAN> CONFIGURE COMPRESSION ALGORITHM 'HIGH';
RMAN> BACKUP DATABASE;
```

### Encryption Configuration

#### Setup Encryption
```sql
-- Configure encryption algorithm
RMAN> CONFIGURE ENCRYPTION ALGORITHM 'AES256';

-- Alternative algorithms
RMAN> CONFIGURE ENCRYPTION ALGORITHM 'AES192';
RMAN> CONFIGURE ENCRYPTION ALGORITHM 'AES128';

-- Enable encryption for database
RMAN> CONFIGURE ENCRYPTION FOR DATABASE ON;

-- Set encryption password
RMAN> SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
```

#### Full Database Backup with Compression and Encryption
```sql
-- Complete backup with compression and encryption
RMAN> RUN {
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    BACKUP AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'FULL_BACKUP_COMPRESSED_ENCRYPTED';
    DELETE NOPROMPT OBSOLETE;
}
```

### Advanced Full Backup Options
```sql
-- Parallel backup with compression and encryption
RMAN> RUN {
    ALLOCATE CHANNEL c1 TYPE DISK FORMAT '/backup/rman/full_%U';
    ALLOCATE CHANNEL c2 TYPE DISK FORMAT '/backup/rman/full_%U';
    ALLOCATE CHANNEL c3 TYPE DISK FORMAT '/backup/rman/full_%U';
    ALLOCATE CHANNEL c4 TYPE DISK FORMAT '/backup/rman/full_%U';
    
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    
    BACKUP AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'PARALLEL_FULL_BACKUP'
    MAXPIECESIZE 2G;
    
    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
    RELEASE CHANNEL c3;
    RELEASE CHANNEL c4;
}
```

## Incremental Backup Strategies {#incremental-backups}

### Level 0 Incremental Backup (Baseline)
```sql
-- Level 0 backup (baseline for incrementals)
RMAN> BACKUP INCREMENTAL LEVEL 0 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'LEVEL0_BASELINE';

-- Level 0 with encryption
RMAN> RUN {
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    BACKUP INCREMENTAL LEVEL 0 
    AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    TAG 'LEVEL0_ENCRYPTED';
}
```

### Level 1 Differential Incremental Backup
```sql
-- Level 1 differential (changes since last level 0 or level 1)
RMAN> BACKUP INCREMENTAL LEVEL 1 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'LEVEL1_DIFFERENTIAL';

-- Level 1 with cumulative option
RMAN> BACKUP INCREMENTAL LEVEL 1 CUMULATIVE 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'LEVEL1_CUMULATIVE';
```

### Incremental Backup Strategy Examples

#### Weekly Level 0, Daily Level 1 Strategy
```sql
-- Sunday: Level 0 backup
RMAN> RUN {
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    BACKUP INCREMENTAL LEVEL 0 
    AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'WEEKLY_LEVEL0';
    DELETE NOPROMPT OBSOLETE;
}

-- Monday-Saturday: Level 1 backup
RMAN> RUN {
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    BACKUP INCREMENTAL LEVEL 1 
    AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'DAILY_LEVEL1';
    DELETE NOPROMPT ARCHIVELOG UNTIL TIME 'SYSDATE-1';
}
```

#### Monthly Level 0, Weekly Level 1 Cumulative Strategy
```sql
-- First Sunday of month: Level 0
RMAN> BACKUP INCREMENTAL LEVEL 0 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'MONTHLY_LEVEL0';

-- Other Sundays: Level 1 Cumulative
RMAN> BACKUP INCREMENTAL LEVEL 1 CUMULATIVE 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'WEEKLY_LEVEL1_CUMULATIVE';
```

## Archive Log Backup with Cleanup {#archive-log-backup}

### Basic Archive Log Backup
```sql
-- Backup all archive logs
RMAN> BACKUP ARCHIVELOG ALL;

-- Backup archive logs from specific time
RMAN> BACKUP ARCHIVELOG FROM TIME 'SYSDATE-1';

-- Backup archive logs with compression
RMAN> BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL;
```

### Archive Log Backup with Cleanup Options

#### Delete Input After Backup
```sql
-- Backup and delete archive logs
RMAN> BACKUP ARCHIVELOG ALL DELETE INPUT;

-- Backup with compression and delete
RMAN> BACKUP AS COMPRESSED BACKUPSET 
      ARCHIVELOG ALL 
      DELETE INPUT 
      TAG 'ARCHLOG_BACKUP_CLEANUP';
```

#### Time-Based Archive Log Management
```sql
-- Backup archive logs older than 1 day and delete them
RMAN> BACKUP ARCHIVELOG FROM TIME 'SYSDATE-2' 
      UNTIL TIME 'SYSDATE-1' 
      DELETE INPUT;

-- Backup recent archive logs (keep last 4 hours)
RMAN> BACKUP ARCHIVELOG FROM TIME 'SYSDATE-1' 
      TAG 'RECENT_ARCHLOG_BACKUP';
```

#### Advanced Archive Log Cleanup
```sql
-- Comprehensive archive log management
RMAN> RUN {
    -- Backup all archive logs with compression
    BACKUP AS COMPRESSED BACKUPSET 
    ARCHIVELOG ALL 
    TAG 'ARCHLOG_COMPRESSED_BACKUP';
    
    -- Delete archive logs backed up more than once
    DELETE NOPROMPT ARCHIVELOG UNTIL TIME 'SYSDATE-2' 
    BACKED UP 2 TIMES TO DISK;
    
    -- Crosscheck and delete expired archive logs
    CROSSCHECK ARCHIVELOG ALL;
    DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
}
```

### Archive Log Deletion Policies

#### Configure Deletion Policies
```sql
-- Delete after backing up once
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;

-- For standby database environments
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON STANDBY;

-- For Data Guard with multiple standbys
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
```

## Performance Optimization {#performance-optimization}

### Parallel Channel Configuration
```sql
-- Configure default parallelism
RMAN> CONFIGURE DEVICE TYPE DISK PARALLELISM 8;

-- Configure channel-specific settings
RMAN> CONFIGURE CHANNEL 1 DEVICE TYPE DISK 
      FORMAT '/backup/disk1/rman_%U' 
      MAXPIECESIZE 4G;
RMAN> CONFIGURE CHANNEL 2 DEVICE TYPE DISK 
      FORMAT '/backup/disk2/rman_%U' 
      MAXPIECESIZE 4G;
```

### Backup Performance Tuning
```sql
-- Optimized backup with multiple channels
RMAN> RUN {
    ALLOCATE CHANNEL c1 TYPE DISK 
    FORMAT '/backup/fast_disk1/%U' 
    MAXPIECESIZE 2G 
    RATE 100M;
    
    ALLOCATE CHANNEL c2 TYPE DISK 
    FORMAT '/backup/fast_disk2/%U' 
    MAXPIECESIZE 2G 
    RATE 100M;
    
    ALLOCATE CHANNEL c3 TYPE DISK 
    FORMAT '/backup/fast_disk3/%U' 
    MAXPIECESIZE 2G 
    RATE 100M;
    
    ALLOCATE CHANNEL c4 TYPE DISK 
    FORMAT '/backup/fast_disk4/%U' 
    MAXPIECESIZE 2G 
    RATE 100M;
    
    BACKUP AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    PLUS ARCHIVELOG;
    
    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
    RELEASE CHANNEL c3;
    RELEASE CHANNEL c4;
}
```

### Storage Space Calculations

#### Compression Ratios
- **BASIC Compression**: 50-60% space reduction
- **MEDIUM Compression**: 60-70% space reduction  
- **HIGH Compression**: 70-80% space reduction

#### Space Planning Formula
```
Full Backup Size = Database Size × (1 - Compression Ratio)
Level 0 Size = Full Backup Size
Level 1 Size = Changed Data × (1 - Compression Ratio)
Archive Log Size = Daily Archive Generation × Retention Days
```

## Dynamic Backup Scripts {#dynamic-scripts}

### Linux/Unix Shell Script
```bash
#!/bin/bash
# Oracle RMAN Backup Script
# File: rman_backup.sh
# Usage: ./rman_backup.sh [OPTIONS]

# Default configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/rman_backup.conf"

# Default values
ORACLE_SID="${ORACLE_SID:-PRODDB}"
ORACLE_HOME="${ORACLE_HOME:-/u01/app/oracle/product/19.0.0/dbhome_1}"
BACKUP_TYPE="${BACKUP_TYPE:-FULL}"
COMPRESSION="${COMPRESSION:-MEDIUM}"
ENCRYPTION="${ENCRYPTION:-NO}"
ENCRYPTION_PASSWORD="${ENCRYPTION_PASSWORD:-}"
BACKUP_BASE="${BACKUP_BASE:-/backup/rman}"
PARALLEL_DEGREE="${PARALLEL_DEGREE:-4}"
MAXPIECESIZE="${MAXPIECESIZE:-2G}"
TAG_PREFIX="${TAG_PREFIX:-AUTO}"
DELETE_OBSOLETE="${DELETE_OBSOLETE:-YES}"
CLEANUP_ARCHLOGS="${CLEANUP_ARCHLOGS:-YES}"
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}" | tee -a "$LOG_FILE"
}

# Load configuration file if exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "Loading configuration from: $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

# Create configuration file template
create_config_template() {
    cat > "$CONFIG_FILE" << 'EOF'
# RMAN Backup Configuration File
# Customize these values for your environment

# Oracle Environment
ORACLE_SID=PRODDB
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1

# Backup Configuration
BACKUP_TYPE=FULL              # FULL, LEVEL0, LEVEL1, LEVEL1_CUMULATIVE, ARCHIVELOG
COMPRESSION=MEDIUM            # BASIC, MEDIUM, HIGH, NONE
ENCRYPTION=NO                 # YES, NO
ENCRYPTION_PASSWORD=SecureBackupPassword123

# Storage Configuration
BACKUP_BASE=/backup/rman
PARALLEL_DEGREE=4
MAXPIECESIZE=2G

# Cleanup Configuration
DELETE_OBSOLETE=YES
CLEANUP_ARCHLOGS=YES
LOG_RETENTION_DAYS=30

# Notification
NOTIFICATION_EMAIL=dba@company.com

# Tagging
TAG_PREFIX=AUTO
EOF
    log_info "Configuration template created: $CONFIG_FILE"
}

# Setup environment
setup_environment() {
    export ORACLE_SID="$ORACLE_SID"
    export ORACLE_HOME="$ORACLE_HOME"
    export PATH="$ORACLE_HOME/bin:$PATH"
    
    # Create backup directories
    mkdir -p "${BACKUP_BASE}/logs"
    mkdir -p "${BACKUP_BASE}/datafile"
    mkdir -p "${BACKUP_BASE}/archivelog"
    mkdir -p "${BACKUP_BASE}/controlfile"
    
    # Setup log file
    LOG_FILE="${BACKUP_BASE}/logs/rman_backup_$(date +%Y%m%d_%H%M%S).log"
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    
    log_info "Environment setup completed"
    log_info "Oracle SID: $ORACLE_SID"
    log_info "Oracle Home: $ORACLE_HOME"
    log_info "Backup Base: $BACKUP_BASE"
    log_info "Log File: $LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    # Check Oracle Home
    if [ ! -d "$ORACLE_HOME" ]; then
        log_error "Oracle Home not found: $ORACLE_HOME"
        exit 1
    fi
    
    # Check RMAN executable
    if ! command -v rman &> /dev/null; then
        log_error "RMAN executable not found in PATH"
        exit 1
    fi
    
    # Test database connection
    sqlplus -s / as sysdba << EOF > /tmp/db_test.log 2>&1
    SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
    SELECT 'DB_STATUS:' || status FROM v\$instance;
    EXIT;
EOF
    
    if [ $? -ne 0 ]; then
        log_error "Cannot connect to database"
        cat /tmp/db_test.log
        exit 1
    fi
    
    DB_STATUS=$(grep "DB_STATUS:" /tmp/db_test.log | cut -d: -f2)
    if [ "$DB_STATUS" != "OPEN" ]; then
        log_error "Database is not open. Status: $DB_STATUS"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
    rm -f /tmp/db_test.log
}

# Generate RMAN script based on backup type
generate_rman_script() {
    local rman_script="/tmp/rman_backup_${BACKUP_TYPE}_$$.rman"
    local current_tag="${TAG_PREFIX}_$(date +%Y%m%d_%H%M%S)"
    
    log_section "Generating RMAN Script for $BACKUP_TYPE backup"
    
    # Start RMAN script
    cat > "$rman_script" << EOF
CONNECT TARGET /;

-- Show configuration
SHOW ALL;

RUN {
EOF
    
    # Add channel allocation if parallel degree > 1
    if [ "$PARALLEL_DEGREE" -gt 1 ]; then
        for ((i=1; i<=PARALLEL_DEGREE; i++)); do
            cat >> "$rman_script" << EOF
    ALLOCATE CHANNEL c${i} TYPE DISK 
    FORMAT '${BACKUP_BASE}/datafile/ch${i}_%U' 
    MAXPIECESIZE ${MAXPIECESIZE};
EOF
        done
    fi
    
    # Add encryption if enabled
    if [ "$ENCRYPTION" = "YES" ] && [ -n "$ENCRYPTION_PASSWORD" ]; then
        cat >> "$rman_script" << EOF
    SET ENCRYPTION IDENTIFIED BY "${ENCRYPTION_PASSWORD}";
EOF
    fi
    
    # Add backup command based on type
    case "$BACKUP_TYPE" in
        "FULL")
            if [ "$COMPRESSION" != "NONE" ]; then
                cat >> "$rman_script" << EOF
    BACKUP AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_FULL';
EOF
            else
                cat >> "$rman_script" << EOF
    BACKUP DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_FULL';
EOF
            fi
            ;;
        "LEVEL0")
            if [ "$COMPRESSION" != "NONE" ]; then
                cat >> "$rman_script" << EOF
    BACKUP INCREMENTAL LEVEL 0 
    AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_LEVEL0';
EOF
            else
                cat >> "$rman_script" << EOF
    BACKUP INCREMENTAL LEVEL 0 
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_LEVEL0';
EOF
            fi
            ;;
        "LEVEL1")
            if [ "$COMPRESSION" != "NONE" ]; then
                cat >> "$rman_script" << EOF
    BACKUP INCREMENTAL LEVEL 1 
    AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_LEVEL1';
EOF
            else
                cat >> "$rman_script" << EOF
    BACKUP INCREMENTAL LEVEL 1 
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_LEVEL1';
EOF
            fi
            ;;
        "LEVEL1_CUMULATIVE")
            if [ "$COMPRESSION" != "NONE" ]; then
                cat >> "$rman_script" << EOF
    BACKUP INCREMENTAL LEVEL 1 CUMULATIVE 
    AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_LEVEL1_CUM';
EOF
            else
                cat >> "$rman_script" << EOF
    BACKUP INCREMENTAL LEVEL 1 CUMULATIVE 
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${current_tag}_LEVEL1_CUM';
EOF
            fi
            ;;
        "ARCHIVELOG")
            if [ "$COMPRESSION" != "NONE" ]; then
                cat >> "$rman_script" << EOF
    BACKUP AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    ARCHIVELOG ALL 
    TAG '${current_tag}_ARCHLOG';
EOF
            else
                cat >> "$rman_script" << EOF
    BACKUP ARCHIVELOG ALL 
    TAG '${current_tag}_ARCHLOG';
EOF
            fi
            
            if [ "$CLEANUP_ARCHLOGS" = "YES" ]; then
                cat >> "$rman_script" << EOF
    DELETE NOPROMPT ARCHIVELOG UNTIL TIME 'SYSDATE-2' 
    BACKED UP 1 TIMES TO DISK;
EOF
            fi
            ;;
    esac
    
    # Add cleanup commands
    if [ "$DELETE_OBSOLETE" = "YES" ]; then
        cat >> "$rman_script" << EOF
    DELETE NOPROMPT OBSOLETE;
    DELETE NOPROMPT EXPIRED BACKUP;
EOF
    fi
    
    # Release channels if allocated
    if [ "$PARALLEL_DEGREE" -gt 1 ]; then
        for ((i=1; i<=PARALLEL_DEGREE; i++)); do
            cat >> "$rman_script" << EOF
    RELEASE CHANNEL c${i};
EOF
        done
    fi
    
    # Close RUN block and add validation
    cat >> "$rman_script" << EOF
}

-- Validate backup
VALIDATE BACKUP;

-- List recent backups
LIST BACKUP SUMMARY;

-- Report any issues
REPORT NEED BACKUP;

EXIT;
EOF
    
    echo "$rman_script"
}

# Execute RMAN backup
execute_backup() {
    local rman_script="$1"
    local start_time=$(date +%s)
    
    log_section "Executing RMAN Backup"
    log_info "Backup Type: $BACKUP_TYPE"
    log_info "Compression: $COMPRESSION"
    log_info "Encryption: $ENCRYPTION"
    log_info "Parallel Degree: $PARALLEL_DEGREE"
    
    # Execute RMAN script
    rman @"$rman_script"
    local rman_exit_code=$?
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_formatted=$(printf '%02d:%02d:%02d' $((duration/3600)) $(((duration%3600)/60)) $((duration%60)))
    
    if [ $rman_exit_code -eq 0 ]; then
        log_info "RMAN backup completed successfully"
        log_info "Duration: $duration_formatted"
        BACKUP_STATUS="SUCCESS"
    else
        log_error "RMAN backup failed with exit code: $rman_exit_code"
        log_error "Duration: $duration_formatted"
        BACKUP_STATUS="FAILED"
    fi
    
    # Cleanup script
    rm -f "$rman_script"
    
    return $rman_exit_code
}

# Generate backup report
generate_backup_report() {
    local report_file="${BACKUP_BASE}/logs/backup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_section "Generating Backup Report"
    
    cat > "$report_file" << EOF
Oracle RMAN Backup Report
========================
Database: $ORACLE_SID
Backup Date: $(date)
Backup Type: $BACKUP_TYPE
Status: $BACKUP_STATUS

Configuration:
- Compression: $COMPRESSION
- Encryption: $ENCRYPTION
- Parallel Degree: $PARALLEL_DEGREE
- Max Piece Size: $MAXPIECESIZE

Backup Location: $BACKUP_BASE

Recent Backup Information:
$(rman target / << EOL
LIST BACKUP SUMMARY;
EXIT;
EOL
)

Storage Usage:
$(df -h "$BACKUP_BASE")

Database Information:
$(sqlplus -s / as sysdba << EOL
SET PAGESIZE 100 LINESIZE 200
SELECT 'Database Size: ' || ROUND(SUM(bytes)/1024/1024/1024,2) || ' GB' FROM dba_data_files;
SELECT 'Archive Generation: ' || ROUND(SUM(blocks*block_size)/1024/1024,2) || ' MB/day' 
FROM v\$archived_log WHERE first_time > sysdate - 1;
EXIT;
EOL
)
EOF
    
    log_info "Backup report generated: $report_file"
    
    # Display summary
    log_info "=== BACKUP SUMMARY ==="
    log_info "Status: $BACKUP_STATUS"
    log_info "Type: $BACKUP_TYPE"
    log_info "Log File: $LOG_FILE"
    log_info "Report: $report_file"
}

# Send notification
send_notification() {
    if [ -n "$NOTIFICATION_EMAIL" ]; then
        local subject="RMAN Backup $BACKUP_STATUS - $ORACLE_SID - $(date)"
        local message="RMAN backup for database $ORACLE_SID completed with status: $BACKUP_STATUS"
        
        if command -v mail &> /dev/null; then
            echo "$message" | mail -s "$subject" "$NOTIFICATION_EMAIL"
            log_info "Notification sent to: $NOTIFICATION_EMAIL"
        else
            log_warning "Mail command not available. Cannot send notification."
        fi
    fi
}

# Cleanup old logs
cleanup_old_logs() {
    if [ "$LOG_RETENTION_DAYS" -gt 0 ]; then
        log_section "Cleaning up old log files"
        find "${BACKUP_BASE}/logs" -name "*.log" -type f -mtime +${LOG_RETENTION_DAYS} -delete
        find "${BACKUP_BASE}/logs" -name "*.txt" -type f -mtime +${LOG_RETENTION_DAYS} -delete
        log_info "Cleaned up logs older than $LOG_RETENTION_DAYS days"
    fi
}

# Display usage
usage() {
    cat << EOF
Oracle RMAN Backup Script

Usage: $0 [OPTIONS]

Options:
  -t, --type TYPE           Backup type (FULL, LEVEL0, LEVEL1, LEVEL1_CUMULATIVE, ARCHIVELOG)
  -c, --compression LEVEL   Compression level (NONE, BASIC, MEDIUM, HIGH)
  -e, --encryption          Enable encryption (requires password)
  -p, --password PASSWORD   Encryption password
  -d, --degree NUMBER       Parallel degree (1-16)
  -s, --size SIZE          Max piece size (e.g., 2G, 4G)
  -b, --base PATH          Backup base directory
  --config-template        Create configuration file template
  --no-obsolete            Skip deletion of obsolete backups
  --no-archlog-cleanup     Skip archive log cleanup
  -h, --help               Display this help

Examples:
  $0 -t FULL -c MEDIUM -e -p "SecurePass123"
  $0 -t LEVEL0 -c HIGH -d 8 -s 4G
  $0 -t ARCHIVELOG --no-archlog-cleanup
  $0 --config-template

Configuration File: $CONFIG_FILE
EOF
    exit 0
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                BACKUP_TYPE="$2"
                shift 2
                ;;
            -c|--compression)
                COMPRESSION="$2"
                shift 2
                ;;
            -e|--encryption)
                ENCRYPTION="YES"
                shift
                ;;
            -p|--password)
                ENCRYPTION_PASSWORD="$2"
                shift 2
                ;;
            -d|--degree)
                PARALLEL_DEGREE="$2"
                shift 2
                ;;
            -s|--size)
                MAXPIECESIZE="$2"
                shift 2
                ;;
            -b|--base)
                BACKUP_BASE="$2"
                shift 2
                ;;
            --config-template)
                create_config_template
                exit 0
                ;;
            --no-obsolete)
                DELETE_OBSOLETE="NO"
                shift
                ;;
            --no-archlog-cleanup)
                CLEANUP_ARCHLOGS="NO"
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Validate parameters
validate_parameters() {
    # Validate backup type
    case "$BACKUP_TYPE" in
        FULL|LEVEL0|LEVEL1|LEVEL1_CUMULATIVE|ARCHIVELOG)
            ;;
        *)
            log_error "Invalid backup type: $BACKUP_TYPE"
            exit 1
            ;;
    esac
    
    # Validate compression
    case "$COMPRESSION" in
        NONE|BASIC|MEDIUM|HIGH)
            ;;
        *)
            log_error "Invalid compression level: $COMPRESSION"
            exit 1
            ;;
    esac
    
    # Validate parallel degree
    if ! [[ "$PARALLEL_DEGREE" =~ ^[1-9][0-9]*$ ]] || [ "$PARALLEL_DEGREE" -gt 16 ]; then
        log_error "Invalid parallel degree: $PARALLEL_DEGREE (must be 1-16)"
        exit 1
    fi
    
    # Validate encryption settings
    if [ "$ENCRYPTION" = "YES" ] && [ -z "$ENCRYPTION_PASSWORD" ]; then
        log_error "Encryption password required when encryption is enabled"
        exit 1
    fi
}

# Main execution function
main() {
    echo "Oracle RMAN Backup Script Starting..."
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Load configuration
    load_config
    
    # Validate parameters
    validate_parameters
    
    # Setup environment
    setup_environment
    
    # Check prerequisites
    check_prerequisites
    
    # Generate and execute backup
    local rman_script=$(generate_rman_script)
    execute_backup "$rman_script"
    local backup_result=$?
    
    # Generate report
    generate_backup_report
    
    # Send notification
    send_notification
    
    # Cleanup old logs
    cleanup_old_logs
    
    # Exit with backup result
    exit $backup_result
}

# Execute main function with all arguments
main "$@"
```

