#!/bin/bash

# Database Archive Cleanup Script

# Deletes database archive files older than 10 days

# Author: Generated Script

# Date: $(date +%Y-%m-%d)

# Set colors for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
NC=’\033[0m’ # No Color

# Function to display header

show_header() {
echo -e “${BLUE}==================================”
echo -e “  Database Archive Cleanup Tool”
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

# Check for valid characters (alphanumeric, underscore, hyphen)
if [[ ! "$db_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_message "ERROR" "Database name contains invalid characters. Use only letters, numbers, underscore, and hyphen."
    return 1
fi

return 0
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

# Function to find and delete archive files

cleanup_archives() {
local db_name=$1
local archive_dir=$2
local days_old=${3:-10}
local dry_run=${4:-false}

```
log_message "INFO" "Starting cleanup for database: $db_name"
log_message "INFO" "Archive directory: $archive_dir"
log_message "INFO" "Deleting files older than: $days_old days"

# Common archive file patterns
local patterns=(
    "${db_name}*.sql"
    "${db_name}*.sql.gz"
    "${db_name}*.sql.bz2"
    "${db_name}*.dump"
    "${db_name}*.backup"
    "${db_name}*.bak"
    "${db_name}*.tar"
    "${db_name}*.tar.gz"
    "${db_name}*.tar.bz2"
    "${db_name}*.zip"
)

local total_files=0
local deleted_files=0
local total_size=0
local freed_size=0

# Check if archive directory exists
if [[ ! -d "$archive_dir" ]]; then
    log_message "ERROR" "Archive directory does not exist: $archive_dir"
    return 1
fi

# Find and process files
for pattern in "${patterns[@]}"; do
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            ((total_files++))
            local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            ((total_size += file_size))
            
            # Check if file is older than specified days
            if find "$file" -type f -mtime +$days_old -print0 | grep -qz .; then
                log_message "INFO" "Found old archive: $(basename "$file") ($(date -r "$file" '+%Y-%m-%d %H:%M:%S'))"
                
                if [[ "$dry_run" == "true" ]]; then
                    log_message "INFO" "[DRY RUN] Would delete: $file"
                else
                    if rm "$file" 2>/dev/null; then
                        log_message "INFO" "Deleted: $(basename "$file")"
                        ((deleted_files++))
                        ((freed_size += file_size))
                    else
                        log_message "ERROR" "Failed to delete: $file"
                    fi
                fi
            fi
        fi
    done < <(find "$archive_dir" -name "$pattern" -type f -print0 2>/dev/null)
done

# Display summary
echo -e "\n${BLUE}=== CLEANUP SUMMARY ===${NC}"
echo -e "Total archive files found: $total_files"
echo -e "Files deleted: $deleted_files"
echo -e "Total size of archives: $(format_size $total_size)"
echo -e "Space freed: $(format_size $freed_size)"

if [[ "$dry_run" == "true" ]]; then
    echo -e "${YELLOW}This was a dry run. No files were actually deleted.${NC}"
fi
```

}

# Function to format file size

format_size() {
local size=$1
local units=(“B” “KB” “MB” “GB” “TB”)
local unit=0

```
while [[ $size -gt 1024 && $unit -lt 4 ]]; do
    ((size /= 1024))
    ((unit++))
done

echo "${size}${units[$unit]}"
```

}

# Main function

main() {
show_header

```
# Set default values
local archive_dir="/var/backups/database"
local days_old=10
local dry_run=false
local log_file=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            archive_dir="$2"
            shift 2
            ;;
        -a|--age)
            days_old="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        -l|--log)
            log_file="$2"
            LOG_FILE="$log_file"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -d, --directory DIR    Archive directory (default: /var/backups/database)"
            echo "  -a, --age DAYS         Delete files older than DAYS (default: 10)"
            echo "  --dry-run              Show what would be deleted without actually deleting"
            echo "  -l, --log FILE         Log output to file"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        *)
            log_message "ERROR" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get database name from user
local database_name
while true; do
    echo -e "${BLUE}Enter the database name:${NC}"
    read -p "> " database_name
    
    if validate_database_name "$database_name"; then
        break
    fi
    echo
done

# Show configuration
echo -e "\n${BLUE}Configuration:${NC}"
echo -e "Database name: $database_name"
echo -e "Archive directory: $archive_dir"
echo -e "Delete files older than: $days_old days"
echo -e "Dry run mode: $dry_run"
if [[ -n "$log_file" ]]; then
    echo -e "Log file: $log_file"
fi
echo

# Get user confirmation
local confirmation_msg="This will delete archive files for database '$database_name' older than $days_old days from '$archive_dir'."
if [[ "$dry_run" == "true" ]]; then
    confirmation_msg="This will show what archive files would be deleted (dry run mode)."
fi

if get_confirmation "$confirmation_msg"; then
    cleanup_archives "$database_name" "$archive_dir" "$days_old" "$dry_run"
else
    log_message "INFO" "Operation cancelled by user"
    exit 0
fi

log_message "INFO" "Cleanup completed"
```

}

# Run main function with all arguments

main “$@”