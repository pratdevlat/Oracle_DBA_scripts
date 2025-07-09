#!/bin/bash

# RMAN Archive Cleanup Script

# Deletes database archive logs older than 10 days using RMAN

# Author: Generated Script

# Date: $(date +%Y-%m-%d)

# Set colors for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
NC=’\033[0m’ # No Color

# Default values

ORACLE_HOME=${ORACLE_HOME:-”/u01/app/oracle/product/19.0.0/dbhome_1”}
ORACLE_SID=””
DAYS_OLD=10
DRY_RUN=false
LOG_FILE=””
RMAN_USER=”/”
RMAN_CATALOG=””

# Function to display header

show_header() {
echo -e “${BLUE}==================================”
echo -e “  RMAN Archive Cleanup Tool”
echo -e “==================================”
echo -e “${NC}”
}

# Function to log messages

log_message() {
local level=$1
local message=$2
local timestamp=$(date ‘+%Y-%m-%d %H:%M:%S’)

```
case $level in
    "INFO")
        echo -e "${GREEN}[INFO]${NC} $timestamp - $message"
        ;;
    "WARN")
        echo -e "${YELLOW}[WARN]${NC} $timestamp - $message"
        ;;
    "ERROR")
        echo -e "${RED}[ERROR]${NC} $timestamp - $message"
        ;;
esac

# Also log to file if LOG_FILE is set
if [[ -n "$LOG_FILE" ]]; then
    echo "[$level] $timestamp - $message" >> "$LOG_FILE"
fi
```

}

# Function to validate database name

validate_database_name() {
local db_name=$1

```
# Check if database name is empty
if [[ -z "$db_name" ]]; then
    log_message "ERROR" "Database name cannot be empty"
    return 1
fi

# Check for valid characters (alphanumeric, underscore)
if [[ ! "$db_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
    log_message "ERROR" "Database name contains invalid characters. Use only letters, numbers, and underscore."
    return 1
fi

return 0
```

}

# Function to check Oracle environment

check_oracle_env() {
log_message “INFO” “Checking Oracle environment…”

```
# Check ORACLE_HOME
if [[ ! -d "$ORACLE_HOME" ]]; then
    log_message "ERROR" "ORACLE_HOME directory does not exist: $ORACLE_HOME"
    return 1
fi

# Check if RMAN executable exists
if [[ ! -x "$ORACLE_HOME/bin/rman" ]]; then
    log_message "ERROR" "RMAN executable not found: $ORACLE_HOME/bin/rman"
    return 1
fi

# Check if sqlplus exists
if [[ ! -x "$ORACLE_HOME/bin/sqlplus" ]]; then
    log_message "ERROR" "SQL*Plus executable not found: $ORACLE_HOME/bin/sqlplus"
    return 1
fi

log_message "INFO" "Oracle environment check passed"
return 0
```

}

# Function to test database connection

test_db_connection() {
local db_name=$1

```
log_message "INFO" "Testing database connection to $db_name..."

export ORACLE_SID=$db_name

# Test connection using sqlplus
local test_result=$(echo "SELECT 'CONNECTION_OK' FROM DUAL;" | $ORACLE_HOME/bin/sqlplus -s / as sysdba 2>&1)

if [[ $test_result == *"CONNECTION_OK"* ]]; then
    log_message "INFO" "Database connection successful"
    return 0
else
    log_message "ERROR" "Failed to connect to database $db_name"
    log_message "ERROR" "Connection error: $test_result"
    return 1
fi
```

}

# Function to get user confirmation

get_confirmation() {
local message=$1
local response

```
while true; do
    echo -e "${YELLOW}$message${NC}"
    read -p "Continue? (y/N): " response
    
    case $response in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        [Nn]|[Nn][Oo]|"")
            return 1
            ;;
        *)
            echo "Please answer yes (y) or no (n)."
            ;;
    esac
done
```

}

# Function to generate RMAN script

generate_rman_script() {
local db_name=$1
local days_old=$2
local dry_run=$3
local script_file=”/tmp/rman_cleanup_${db_name}_$$.rman”

```
cat > "$script_file" <<EOF
```

CONNECT TARGET ${RMAN_USER};
$(if [[ -n “$RMAN_CATALOG” ]]; then echo “CONNECT CATALOG ${RMAN_CATALOG};”; fi)

# Show current archivelog information

LIST ARCHIVELOG ALL;

# Show what will be deleted (older than ${days_old} days)

LIST ARCHIVELOG UNTIL TIME ‘SYSDATE-${days_old}’;

$(if [[ “$dry_run” == “false” ]]; then
cat <<EOD

# Crosscheck archivelog files

CROSSCHECK ARCHIVELOG ALL;

# Delete expired archivelog files

DELETE EXPIRED ARCHIVELOG ALL;

# Delete archivelog files older than ${days_old} days

DELETE ARCHIVELOG UNTIL TIME ‘SYSDATE-${days_old}’;

# Delete obsolete backups based on retention policy

DELETE OBSOLETE;
EOD
fi)

EXIT;
EOF

```
echo "$script_file"
```

}

# Function to run RMAN cleanup

run_rman_cleanup() {
local db_name=$1
local days_old=$2
local dry_run=$3

```
log_message "INFO" "Starting RMAN cleanup for database: $db_name"
log_message "INFO" "Archive logs older than: $days_old days"

# Set environment variables
export ORACLE_SID=$db_name
export ORACLE_HOME=$ORACLE_HOME

# Generate RMAN script
local rman_script=$(generate_rman_script "$db_name" "$days_old" "$dry_run")

log_message "INFO" "Generated RMAN script: $rman_script"

if [[ "$dry_run" == "true" ]]; then
    log_message "INFO" "DRY RUN MODE - Showing what would be deleted:"
    echo -e "${YELLOW}=== RMAN SCRIPT CONTENT ===${NC}"
    cat "$rman_script"
    echo -e "${YELLOW}=== END OF SCRIPT ===${NC}"
fi

# Execute RMAN script
log_message "INFO" "Executing RMAN cleanup..."

local rman_output_file="/tmp/rman_output_${db_name}_$$.log"

if $ORACLE_HOME/bin/rman @"$rman_script" > "$rman_output_file" 2>&1; then
    log_message "INFO" "RMAN cleanup completed successfully"
    
    # Display summary from RMAN output
    echo -e "\n${BLUE}=== RMAN CLEANUP SUMMARY ===${NC}"
    
    # Extract relevant information from RMAN output
    if grep -q "deleted" "$rman_output_file"; then
        grep -i "deleted\|freed\|removed" "$rman_output_file" | while read line; do
            echo -e "${GREEN}$line${NC}"
        done
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}This was a dry run. No files were actually deleted.${NC}"
    fi
    
    # Show RMAN output if verbose mode or if there were errors
    if [[ -n "$LOG_FILE" ]]; then
        echo -e "\n${BLUE}=== FULL RMAN OUTPUT ===${NC}" >> "$LOG_FILE"
        cat "$rman_output_file" >> "$LOG_FILE"
    fi
    
else
    log_message "ERROR" "RMAN cleanup failed"
    echo -e "${RED}=== RMAN ERROR OUTPUT ===${NC}"
    cat "$rman_output_file"
    
    # Clean up temp files
    rm -f "$rman_script" "$rman_output_file"
    return 1
fi

# Clean up temp files
rm -f "$rman_script" "$rman_output_file"
return 0
```

}

# Function to show archive log information

show_archive_info() {
local db_name=$1

```
log_message "INFO" "Gathering archive log information for $db_name..."

export ORACLE_SID=$db_name

# Get archive log information
local info_script="/tmp/archive_info_$$.sql"

cat > "$info_script" <<EOF
```

SET PAGESIZE 1000
SET LINESIZE 200
COLUMN name FORMAT A60
COLUMN first_time FORMAT A20
COLUMN completion_time FORMAT A20

SELECT
COUNT(*) as “Total Archive Logs”,
ROUND(SUM(blocks * block_size)/1024/1024, 2) as “Total Size (MB)”
FROM v$archived_log
WHERE deleted = ‘NO’;

SELECT
TO_CHAR(first_time, ‘YYYY-MM-DD’) as “Date”,
COUNT(*) as “Archive Count”,
ROUND(SUM(blocks * block_size)/1024/1024, 2) as “Size (MB)”
FROM v$archived_log
WHERE deleted = ‘NO’
GROUP BY TO_CHAR(first_time, ‘YYYY-MM-DD’)
ORDER BY 1;

EXIT;
EOF

```
echo -e "${BLUE}=== ARCHIVE LOG INFORMATION ===${NC}"
$ORACLE_HOME/bin/sqlplus -s / as sysdba @"$info_script"

rm -f "$info_script"
```

}

# Function to display usage

show_usage() {
echo “Usage: $0 [OPTIONS]”
echo “Options:”
echo “  -d, –days DAYS           Delete archives older than DAYS (default: 10)”
echo “  -o, –oracle-home PATH    Oracle home directory”
echo “  -u, –user USER           RMAN user (default: /)”
echo “  -c, –catalog CATALOG     RMAN catalog connection string”
echo “  –dry-run                 Show what would be deleted without actually deleting”
echo “  -l, –log FILE            Log output to file”
echo “  -i, –info                Show archive log information only”
echo “  -h, –help                Show this help message”
echo “”
echo “Example:”
echo “  $0 –days 7 –dry-run”
echo “  $0 –oracle-home /u01/app/oracle/product/19.0.0/dbhome_1”
}

# Main function

main() {
show_header

```
local show_info_only=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            DAYS_OLD="$2"
            shift 2
            ;;
        -o|--oracle-home)
            ORACLE_HOME="$2"
            shift 2
            ;;
        -u|--user)
            RMAN_USER="$2"
            shift 2
            ;;
        -c|--catalog)
            RMAN_CATALOG="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -i|--info)
            show_info_only=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_message "ERROR" "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check Oracle environment
if ! check_oracle_env; then
    exit 1
fi

# Get database name from user
local database_name
while true; do
    echo -e "${BLUE}Enter the database name (ORACLE_SID):${NC}"
    read -p "> " database_name
    
    if validate_database_name "$database_name"; then
        break
    fi
    echo
done

# Test database connection
if ! test_db_connection "$database_name"; then
    exit 1
fi

# Show archive information if requested
if [[ "$show_info_only" == "true" ]]; then
    show_archive_info "$database_name"
    exit 0
fi

# Show configuration
echo -e "\n${BLUE}Configuration:${NC}"
echo -e "Database name (ORACLE_SID): $database_name"
echo -e "Oracle Home: $ORACLE_HOME"
echo -e "Delete archives older than: $DAYS_OLD days"
echo -e "RMAN User: $RMAN_USER"
if [[ -n "$RMAN_CATALOG" ]]; then
    echo -e "RMAN Catalog: $RMAN_CATALOG"
fi
echo -e "Dry run mode: $DRY_RUN"
if [[ -n "$LOG_FILE" ]]; then
    echo -e "Log file: $LOG_FILE"
fi
echo

# Show current archive information
show_archive_info "$database_name"

# Get user confirmation
local confirmation_msg="This will delete archive logs for database '$database_name' older than $DAYS_OLD days using RMAN."
if [[ "$DRY_RUN" == "true" ]]; then
    confirmation_msg="This will show what archive logs would be deleted (dry run mode)."
fi

if get_confirmation "$confirmation_msg"; then
    if run_rman_cleanup "$database_name" "$DAYS_OLD" "$DRY_RUN"; then
        log_message "INFO" "RMAN cleanup completed successfully"
    else
        log_message "ERROR" "RMAN cleanup failed"
        exit 1
    fi
else
    log_message "INFO" "Operation cancelled by user"
    exit 0
fi
```

}

# Run main function with all arguments

main “$@”