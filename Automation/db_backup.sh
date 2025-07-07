#!/bin/bash

#################################################
## Oracle Database Full Backup Script
## Usage: ./db_backup.sh <DATABASE_NAME> <BACKUP_BASE_DIR>
## Example: ./db_backup.sh ORCL /backup/oracle
#################################################

# Check if correct number of arguments provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <DATABASE_NAME> <BACKUP_BASE_DIR>"
    echo "Example: $0 ORCL /backup/oracle"
    exit 1
fi

# Input parameters
DATABASE_NAME=$1
BACKUP_BASE_DIR=$2

# Validate inputs
if [ -z "$DATABASE_NAME" ] || [ -z "$BACKUP_BASE_DIR" ]; then
    echo "Error: DATABASE_NAME and BACKUP_BASE_DIR cannot be empty"
    exit 1
fi

# Check if backup base directory exists
if [ ! -d "$BACKUP_BASE_DIR" ]; then
    echo "Error: Backup directory $BACKUP_BASE_DIR does not exist"
    exit 1
fi

# Check if backup base directory is writable
if [ ! -w "$BACKUP_BASE_DIR" ]; then
    echo "Error: Backup directory $BACKUP_BASE_DIR is not writable"
    exit 1
fi

#################################################
## Environment Setup
#################################################

# Function to get ORACLE_HOME from /etc/oratab
get_oracle_home() {
    local db_name=$1
    local oracle_home=""
    
    # Check if /etc/oratab exists
    if [ ! -f "/etc/oratab" ]; then
        echo "Error: /etc/oratab file not found"
        exit 1
    fi
    
    # Read ORACLE_HOME from /etc/oratab for the given database
    oracle_home=$(grep "^${db_name}:" /etc/oratab | cut -d':' -f2 | head -1)
    
    # If not found, try case-insensitive search
    if [ -z "$oracle_home" ]; then
        oracle_home=$(grep -i "^${db_name}:" /etc/oratab | cut -d':' -f2 | head -1)
    fi
    
    # If still not found, get the first active Oracle home
    if [ -z "$oracle_home" ]; then
        oracle_home=$(grep -E "^[^#].*:.*:Y" /etc/oratab | cut -d':' -f2 | head -1)
        if [ -n "$oracle_home" ]; then
            echo "Warning: Database $db_name not found in /etc/oratab, using first available Oracle home: $oracle_home"
        fi
    fi
    
    # Validate Oracle home exists
    if [ -z "$oracle_home" ]; then
        echo "Error: Could not determine ORACLE_HOME for database $db_name from /etc/oratab"
        exit 1
    fi
    
    if [ ! -d "$oracle_home" ]; then
        echo "Error: ORACLE_HOME directory $oracle_home does not exist"
        exit 1
    fi
    
    if [ ! -f "$oracle_home/bin/sqlplus" ]; then
        echo "Error: Oracle binaries not found in $oracle_home/bin"
        exit 1
    fi
    
    echo "$oracle_home"
}

# Get ORACLE_HOME from /etc/oratab
ORACLE_HOME=$(get_oracle_home "$DATABASE_NAME")
export ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=$DATABASE_NAME

echo "Using ORACLE_HOME: $ORACLE_HOME"

# Get current date and time for folder naming
CURRENT_DATE=$(date +%d_%b_%Y)
CURRENT_TIME=$(date +%H%M)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Create backup directory structure
BACKUP_DIR="$BACKUP_BASE_DIR/LV0_${DATABASE_NAME}_${CURRENT_DATE}_${CURRENT_TIME}"
LOG_FILE="$BACKUP_DIR/backup_${DATABASE_NAME}_${CURRENT_DATE}_${CURRENT_TIME}.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create backup directory $BACKUP_DIR"
    exit 1
fi

# Set backup tag
BACKUP_TAG="LV0_${DATABASE_NAME}_${CURRENT_DATE}_${CURRENT_TIME}"

#################################################
## Logging Functions
#################################################

log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$TIMESTAMP] ERROR: $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo "[$TIMESTAMP] INFO: $1" | tee -a "$LOG_FILE"
}

#################################################
## Database Connectivity Check
#################################################

check_database_connection() {
    log_info "Checking database connection for $DATABASE_NAME..."
    
    DB_STATUS=$(echo "SELECT 'DB_CONNECTED' FROM DUAL;" | sqlplus -s "/ as sysdba" 2>/dev/null | grep "DB_CONNECTED")
    
    if [ -z "$DB_STATUS" ]; then
        log_error "Cannot connect to database $DATABASE_NAME"
        log_error "Please check ORACLE_SID, ORACLE_HOME, and database status"
        exit 2
    fi
    
    log_info "Database connection successful"
}

#################################################
## Database Status Check
#################################################

check_database_status() {
    log_info "Checking database status..."
    
    # Check if database is open
    DB_OPEN_MODE=$(echo "SELECT OPEN_MODE FROM V\$DATABASE;" | sqlplus -s "/ as sysdba" 2>/dev/null | grep -E "READ WRITE|READ ONLY|MOUNTED")
    
    if [ -z "$DB_OPEN_MODE" ]; then
        log_error "Database is not in a valid state for backup"
        exit 3
    fi
    
    log_info "Database open mode: $DB_OPEN_MODE"
    
    # Check archivelog mode
    ARCHIVELOG_MODE=$(echo "SELECT LOG_MODE FROM V\$DATABASE;" | sqlplus -s "/ as sysdba" 2>/dev/null | grep -E "ARCHIVELOG|NOARCHIVELOG")
    log_info "Database archivelog mode: $ARCHIVELOG_MODE"
    
    # Get database size estimate
    DB_SIZE=$(echo "SELECT ROUND(SUM(BYTES)/1024/1024/1024,2) as GB FROM DBA_DATA_FILES;" | sqlplus -s "/ as sysdba" 2>/dev/null | grep -E "^[0-9.,]+$")
    log_info "Database size: ${DB_SIZE} GB"
}

#################################################
## Archive Log Count Check
#################################################

check_archived_logs() {
    log_info "Checking archived logs..."
    
    ARC_COUNT=$(echo "SELECT COUNT(*) FROM V\$ARCHIVED_LOG;" | sqlplus -s "/ as sysdba" 2>/dev/null | grep -E "^[0-9]+$")
    
    if [ -z "$ARC_COUNT" ]; then
        ARC_COUNT=0
    fi
    
    log_info "Archived log count: $ARC_COUNT"
    echo "ARC_COUNT=$ARC_COUNT" >> "$LOG_FILE"
}

#################################################
## Disk Space Check
#################################################

check_disk_space() {
    log_info "Checking available disk space..."
    
    # Get available space in GB
    AVAILABLE_SPACE=$(df -BG "$BACKUP_BASE_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    
    log_info "Available disk space: ${AVAILABLE_SPACE} GB"
    
    # Basic check - should have at least 10GB free
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        log_error "Insufficient disk space. Available: ${AVAILABLE_SPACE}GB, Required: at least 10GB"
        exit 4
    fi
}

#################################################
## Main Backup Function
#################################################

perform_backup() {
    log_info "Starting full database backup..."
    log_info "Database: $DATABASE_NAME"
    log_info "Backup Directory: $BACKUP_DIR"
    log_info "Backup Tag: $BACKUP_TAG"
    
    # Start backup
    $ORACLE_HOME/bin/rman target / <<EOF >> "$LOG_FILE"
run
{
    # Configure backup settings
    CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
    CONFIGURE DEVICE TYPE DISK BACKUP TYPE TO COMPRESSED BACKUPSET;
    
    # Backup database
    BACKUP DATABASE 
    FORMAT '$BACKUP_DIR/db_%d_s%s_p%p_t%t'
    TAG='$BACKUP_TAG';
    
    # Backup current controlfile
    BACKUP CURRENT CONTROLFILE 
    FORMAT '$BACKUP_DIR/cf_%d_s%s_p%p_t%t'
    TAG='$BACKUP_TAG';
    
    # Backup spfile
    BACKUP SPFILE 
    FORMAT '$BACKUP_DIR/spfile_%d_s%s_p%p_t%t'
    TAG='$BACKUP_TAG';
    
    # Backup archived logs (if any exist)
    sql "SELECT COUNT(*) FROM V\$ARCHIVED_LOG;";
    
    # Only backup archived logs if they exist
    BACKUP ARCHIVELOG ALL 
    FORMAT '$BACKUP_DIR/arch_%d_s%s_p%p_t%t'
    TAG='$BACKUP_TAG'
    SKIP INACCESSIBLE;
    
    # Create additional controlfile copy
    sql "ALTER DATABASE BACKUP CONTROLFILE TO '$BACKUP_DIR/control_file_backup.ctl'";
    
    # List backup summary
    LIST BACKUP SUMMARY;
}
EOF

    BACKUP_STATUS=$?
    return $BACKUP_STATUS
}

#################################################
## Backup Validation
#################################################

validate_backup() {
    log_info "Validating backup..."
    
    $ORACLE_HOME/bin/rman target / <<EOF >> "$LOG_FILE"
run
{
    # Validate the backup
    VALIDATE BACKUPSET TAG='$BACKUP_TAG';
    
    # Cross-check backup
    CROSSCHECK BACKUP TAG='$BACKUP_TAG';
    
    # Report backup details
    REPORT SCHEMA;
    LIST BACKUP TAG='$BACKUP_TAG';
}
EOF

    VALIDATE_STATUS=$?
    return $VALIDATE_STATUS
}

#################################################
## Cleanup and Summary
#################################################

generate_summary() {
    log_info "Generating backup summary..."
    
    # Calculate backup size
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    
    # Count backup files
    BACKUP_FILE_COUNT=$(find "$BACKUP_DIR" -type f -name "*" | wc -l)
    
    # End time
    END_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
    echo "           BACKUP SUMMARY" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
    echo "Database Name: $DATABASE_NAME" >> "$LOG_FILE"
    echo "Backup Directory: $BACKUP_DIR" >> "$LOG_FILE"
    echo "Backup Tag: $BACKUP_TAG" >> "$LOG_FILE"
    echo "Start Time: $TIMESTAMP" >> "$LOG_FILE"
    echo "End Time: $END_TIME" >> "$LOG_FILE"
    echo "Backup Size: $BACKUP_SIZE" >> "$LOG_FILE"
    echo "Number of Files: $BACKUP_FILE_COUNT" >> "$LOG_FILE"
    echo "Log File: $LOG_FILE" >> "$LOG_FILE"
    echo "=========================================" >> "$LOG_FILE"
}

#################################################
## Main Execution
#################################################

main() {
    # Initialize log file
    log_info "Oracle Database Backup Script Started"
    log_info "Script: $0"
    log_info "Parameters: $DATABASE_NAME $BACKUP_BASE_DIR"
    log_info "Backup Directory: $BACKUP_DIR"
    
    # Pre-backup checks
    check_database_connection
    check_database_status
    check_archived_logs
    check_disk_space
    
    # Perform backup
    perform_backup
    
    if [ $? -eq 0 ]; then
        log_info "Database backup completed successfully"
        
        # Validate backup
        validate_backup
        
        if [ $? -eq 0 ]; then
            log_info "Backup validation completed successfully"
            generate_summary
            
            echo ""
            echo "✅ BACKUP COMPLETED SUCCESSFULLY!"
            echo "Database: $DATABASE_NAME"
            echo "Backup Location: $BACKUP_DIR"
            echo "Log File: $LOG_FILE"
            echo ""
            
            exit 0
        else
            log_error "Backup validation failed"
            echo ""
            echo "❌ BACKUP VALIDATION FAILED!"
            echo "Check log file: $LOG_FILE"
            echo ""
            exit 6
        fi
    else
        log_error "Database backup failed"
        echo ""
        echo "❌ BACKUP FAILED!"
        echo "Check log file: $LOG_FILE"
        echo ""
        exit 5
    fi
}

# Trap to ensure cleanup on script exit
trap 'log_info "Script execution completed"' EXIT

# Execute main function
main "$@"
