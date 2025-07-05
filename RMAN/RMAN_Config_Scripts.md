# Oracle RMAN Configuration Standard Operating Procedure (SOP)

## Document Information
- **Title**: Oracle RMAN Configuration SOP
- **Version**: 1.0
- **Purpose**: Executable procedure for configuring Oracle RMAN settings, retention policies, and backup optimization

## Environment Variables Setup
```bash
# Set environment variables (adjust paths as needed)
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=PRODDB
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman
export FRA_BASE=/u01/app/oracle/fast_recovery_area
```

## Activity 1: Pre-Configuration Validation

### Step 1.1: Check Database Status
```sql
-- Connect to database
sqlplus / as sysdba

-- Check database status
SELECT instance_name, status, database_status FROM v$instance;

-- Check archive log mode
SELECT log_mode FROM v$database;

-- If not in archive log mode, enable it
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Verify archive log mode
SELECT log_mode FROM v$database;

-- Exit SQL*Plus
EXIT;
```

### Step 1.2: Create Backup Directory Structure
```bash
# Create backup directories
mkdir -p ${BACKUP_BASE}
mkdir -p ${BACKUP_BASE}/datafile
mkdir -p ${BACKUP_BASE}/archivelog
mkdir -p ${BACKUP_BASE}/controlfile
mkdir -p ${FRA_BASE}

# Set permissions
chmod 755 ${BACKUP_BASE}
chmod 755 ${FRA_BASE}
chown oracle:oinstall ${BACKUP_BASE}
chown oracle:oinstall ${FRA_BASE}
```

## Activity 2: RMAN Basic Configuration

### Step 2.1: Connect to RMAN and Check Current Settings
```sql
-- Connect to RMAN
rman target /

-- Check current configuration
SHOW ALL;

-- Check database information
SELECT name, dbid, created FROM v$database;
```

### Step 2.2: Configure Basic RMAN Settings
```sql
-- Set default device type to disk
CONFIGURE DEFAULT DEVICE TYPE TO DISK;

-- Enable controlfile autobackup
CONFIGURE CONTROLFILE AUTOBACKUP ON;

-- Set controlfile autobackup format (dynamic path)
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BACKUP_BASE}/controlfile/cf_%F';

-- Configure snapshot controlfile location
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '${BACKUP_BASE}/controlfile/snapcf_${ORACLE_SID}.f';

-- Verify configuration
SHOW DEFAULT DEVICE TYPE;
SHOW CONTROLFILE AUTOBACKUP;
SHOW CONTROLFILE AUTOBACKUP FORMAT;
```

## Activity 3: Retention Policy Configuration

### Step 3.1: Configure Recovery Window Based Retention
```sql
-- Configure retention policy (adjust days as needed)
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;

-- For production environments
-- CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 30 DAYS;

-- Verify retention policy
SHOW RETENTION POLICY;
```

### Step 3.2: Alternative - Configure Redundancy Based Retention
```sql
-- Alternative: Configure redundancy based retention
-- CONFIGURE RETENTION POLICY TO REDUNDANCY 2;

-- For critical systems
-- CONFIGURE RETENTION POLICY TO REDUNDANCY 3;
```

## Activity 4: Backup Optimization Configuration

### Step 4.1: Enable Backup Optimization
```sql
-- Enable backup optimization
CONFIGURE BACKUP OPTIMIZATION ON;

-- Configure compression
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';

-- Alternative compression levels
-- CONFIGURE COMPRESSION ALGORITHM 'HIGH';
-- CONFIGURE COMPRESSION ALGORITHM 'LOW';
-- CONFIGURE COMPRESSION ALGORITHM 'BASIC';

-- Verify optimization settings
SHOW BACKUP OPTIMIZATION;
SHOW COMPRESSION ALGORITHM;
```

### Step 4.2: Configure Backup Encryption (Optional)
```sql
-- Configure encryption algorithm
CONFIGURE ENCRYPTION ALGORITHM 'AES256';

-- Alternative encryption algorithms
-- CONFIGURE ENCRYPTION ALGORITHM 'AES192';
-- CONFIGURE ENCRYPTION ALGORITHM 'AES128';

-- Enable encryption for database
CONFIGURE ENCRYPTION FOR DATABASE ON;

-- Set encryption password (change password as needed)
SET ENCRYPTION IDENTIFIED BY "BackupEncrypt123";

-- Verify encryption settings
SHOW ENCRYPTION ALGORITHM;
SHOW ENCRYPTION FOR DATABASE;
```

## Activity 5: Channel and Parallelism Configuration

### Step 5.1: Configure Default Channels
```sql
-- Configure parallelism (adjust based on CPU cores)
CONFIGURE DEVICE TYPE DISK PARALLELISM 4;

-- Configure backup piece size
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 2G;

-- Configure backup format
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/%U';

-- Verify channel configuration
SHOW DEVICE TYPE DISK PARALLELISM;
SHOW CHANNEL FOR DEVICE TYPE DISK;
```

### Step 5.2: Configure Specific Channels (Optional)
```sql
-- Configure individual channels with specific settings
CONFIGURE CHANNEL 1 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch1_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 2 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch2_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 3 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch3_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 4 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch4_%U' MAXPIECESIZE 2G;
```

## Activity 6: Fast Recovery Area Configuration

### Step 6.1: Configure FRA via SQL*Plus
```sql
-- Connect to SQL*Plus
connect / as sysdba

-- Set FRA size (adjust size as needed)
ALTER SYSTEM SET db_recovery_file_dest_size=50G;

-- Set FRA location
ALTER SYSTEM SET db_recovery_file_dest='${FRA_BASE}';

-- Verify FRA configuration
SHOW PARAMETER db_recovery_file_dest;

-- Check FRA usage
SELECT * FROM v$recovery_file_dest;

-- Exit SQL*Plus
EXIT;
```

### Step 6.2: Configure Archive Log Deletion Policy
```sql
-- Connect back to RMAN
rman target /

-- Configure archive log deletion policy
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;

-- For standby database environments
-- CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON STANDBY;

-- Verify deletion policy
SHOW ARCHIVELOG DELETION POLICY;
```

## Activity 7: Advanced Configuration

### Step 7.1: Configure Backup Exclude Options
```sql
-- Exclude specific tablespaces from backup (adjust as needed)
CONFIGURE EXCLUDE FOR TABLESPACE TEMP;
CONFIGURE EXCLUDE FOR TABLESPACE TEMPUNDO;

-- Show excluded tablespaces
SHOW EXCLUDE;
```

### Step 7.2: Configure Backup Multiplexing
```sql
-- Configure backup multiplexing
CONFIGURE MAXSETSIZE TO 10G;

-- Configure backup duplexing
CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1;

-- For critical systems (create 2 copies)
-- CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 2;
-- CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 2;
```

## Activity 8: Verification and Testing

### Step 8.1: Verify All Configuration
```sql
-- Show complete RMAN configuration
SHOW ALL;

-- Validate database
VALIDATE DATABASE;

-- Check for any issues
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
```

### Step 8.2: Perform Test Backup
```sql
-- Test backup validation
BACKUP VALIDATE DATABASE;

-- Perform actual test backup
BACKUP DATABASE PLUS ARCHIVELOG;

-- Check backup completion
LIST BACKUP SUMMARY;

-- Verify backup files exist
LIST BACKUP OF DATABASE;
LIST BACKUP OF ARCHIVELOG ALL;
```

## Activity 9: Configuration Verification Script

### Step 9.1: Create Verification Script
```sql
-- Create verification report
SPOOL ${BACKUP_BASE}/rman_config_verification.txt

-- Show all configurations
SHOW ALL;

-- List recent backups
LIST BACKUP SUMMARY;

-- Check repository
REPORT SCHEMA;

-- Check obsolete backups
REPORT OBSOLETE;

-- Check FRA usage
SELECT * FROM v$recovery_file_dest;
SELECT * FROM v$recovery_area_usage;

SPOOL OFF;
```

## Activity 10: Post-Configuration Tasks

### Step 10.1: Create Backup Script Template
```bash
#!/bin/bash
# RMAN Backup Script Template
# File: rman_backup_template.sh

export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=PRODDB
export PATH=$ORACLE_HOME/bin:$PATH

# Create log directory
mkdir -p /backup/logs

# Run RMAN backup
rman target / << EOF
RUN {
    BACKUP DATABASE PLUS ARCHIVELOG;
    DELETE NOPROMPT OBSOLETE;
    DELETE NOPROMPT EXPIRED BACKUP;
    DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
}
EXIT;
EOF
```

### Step 10.2: Create Monitoring Script
```sql
-- File: rman_monitor.sql
-- Monitor RMAN backup status

SET PAGESIZE 100
SET LINESIZE 200
COLUMN STATUS FORMAT A10
COLUMN START_TIME FORMAT A20
COLUMN END_TIME FORMAT A20
COLUMN ELAPSED_SECONDS FORMAT 999999999
COLUMN INPUT_BYTES FORMAT 999999999999999
COLUMN OUTPUT_BYTES FORMAT 999999999999999

SELECT 
    session_key,
    status,
    to_char(start_time, 'DD-MON-YYYY HH24:MI:SS') start_time,
    to_char(end_time, 'DD-MON-YYYY HH24:MI:SS') end_time,
    elapsed_seconds,
    input_bytes,
    output_bytes
FROM v$rman_backup_job_details
WHERE start_time > sysdate - 7
ORDER BY start_time DESC;
```

## Activity 11: Configuration Modification Commands

### Step 11.1: Modify Existing Configuration
```sql
-- Change retention policy
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;

-- Change compression level
CONFIGURE COMPRESSION ALGORITHM 'HIGH';

-- Change parallelism
CONFIGURE DEVICE TYPE DISK PARALLELISM 8;

-- Change backup piece size
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 4G;
```

### Step 11.2: Reset Configuration to Default
```sql
-- Reset specific configuration to default
CONFIGURE RETENTION POLICY CLEAR;
CONFIGURE COMPRESSION ALGORITHM CLEAR;
CONFIGURE DEVICE TYPE DISK PARALLELISM CLEAR;
CONFIGURE CHANNEL DEVICE TYPE DISK CLEAR;

-- Reset all configurations to default
CONFIGURE ALL CLEAR;
```

## Activity 12: Final Validation Checklist

### Step 12.1: Execute Final Validation
```sql
-- Connect to RMAN
rman target /

-- Run comprehensive validation
RUN {
    VALIDATE DATABASE;
    CROSSCHECK BACKUP;
    CROSSCHECK ARCHIVELOG ALL;
    REPORT OBSOLETE;
    REPORT NEED BACKUP;
}

-- Show final configuration
SHOW ALL;

-- Exit RMAN
EXIT;
```

### Step 12.2: Document Configuration
```bash
# Create configuration documentation
cat > ${BACKUP_BASE}/rman_configuration_summary.txt << EOF
RMAN Configuration Summary
=========================
Database: ${ORACLE_SID}
Oracle Home: ${ORACLE_HOME}
Backup Location: ${BACKUP_BASE}
FRA Location: ${FRA_BASE}
Configuration Date: $(date)

$(rman target / << EOL
SHOW ALL;
EXIT;
EOL
)
EOF
```

## Platform-Specific Variables

### Linux/Unix Platform
```bash
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export BACKUP_BASE=/backup/rman
export FRA_BASE=/u01/app/oracle/fast_recovery_area
```

### Windows Platform
```cmd
set ORACLE_HOME=C:\app\oracle\product\19.0.0\dbhome_1
set BACKUP_BASE=D:\backup\rman
set FRA_BASE=D:\app\oracle\fast_recovery_area
```

## Troubleshooting Commands

### Common Issues Resolution
```sql
-- Check space issues
SELECT * FROM v$recovery_file_dest;

-- Check backup status
SELECT * FROM v$rman_backup_job_details WHERE start_time > sysdate - 1;

-- Clean up failed backups
CROSSCHECK BACKUP;
DELETE EXPIRED BACKUP;

-- Check configuration issues
VALIDATE DATABASE;
REPORT SCHEMA;
```

## Shell Script for Complete RMAN Configuration

### Linux/Unix Shell Script
```bash
#!/bin/bash
# RMAN Complete Configuration Script
# File: rman_config_setup.sh
# Usage: ./rman_config_setup.sh [ORACLE_SID] [BACKUP_BASE_PATH] [FRA_BASE_PATH]

# Set default values or use command line arguments
ORACLE_SID=${1:-PRODDB}
BACKUP_BASE=${2:-/backup/rman}
FRA_BASE=${3:-/u01/app/oracle/fast_recovery_area}
ORACLE_HOME=${ORACLE_HOME:-/u01/app/oracle/product/19.0.0/dbhome_1}

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "\n${BLUE}==== $1 ====${NC}"
}

# Function to check if Oracle environment is set
check_oracle_env() {
    print_section "Checking Oracle Environment"
    
    if [ -z "$ORACLE_HOME" ]; then
        print_error "ORACLE_HOME is not set"
        exit 1
    fi
    
    if [ ! -d "$ORACLE_HOME" ]; then
        print_error "ORACLE_HOME directory does not exist: $ORACLE_HOME"
        exit 1
    fi
    
    export PATH=$ORACLE_HOME/bin:$PATH
    export ORACLE_SID=$ORACLE_SID
    
    print_status "Oracle Environment configured:"
    print_status "ORACLE_HOME: $ORACLE_HOME"
    print_status "ORACLE_SID: $ORACLE_SID"
    print_status "BACKUP_BASE: $BACKUP_BASE"
    print_status "FRA_BASE: $FRA_BASE"
}

# Function to create directory structure
create_directories() {
    print_section "Creating Directory Structure"
    
    # Create backup directories
    mkdir -p ${BACKUP_BASE}/{datafile,archivelog,controlfile}
    mkdir -p ${FRA_BASE}
    
    # Set permissions
    chmod 755 ${BACKUP_BASE}
    chmod 755 ${FRA_BASE}
    
    if [ $(id -u) -eq 0 ]; then
        chown oracle:oinstall ${BACKUP_BASE} ${FRA_BASE} 2>/dev/null || print_warning "Could not change ownership to oracle:oinstall"
    fi
    
    print_status "Directories created successfully"
    ls -la ${BACKUP_BASE}
}

# Function to check database status
check_database() {
    print_section "Checking Database Status"
    
    # Test database connection
    sqlplus -s / as sysdba << EOF > /tmp/db_check.log 2>&1
    SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
    SELECT 'DB_STATUS:' || status FROM v\$instance;
    SELECT 'LOG_MODE:' || log_mode FROM v\$database;
    EXIT;
EOF
    
    if [ $? -ne 0 ]; then
        print_error "Cannot connect to database. Check if database is running."
        cat /tmp/db_check.log
        exit 1
    fi
    
    DB_STATUS=$(grep "DB_STATUS:" /tmp/db_check.log | cut -d: -f2)
    LOG_MODE=$(grep "LOG_MODE:" /tmp/db_check.log | cut -d: -f2)
    
    print_status "Database Status: $DB_STATUS"
    print_status "Archive Log Mode: $LOG_MODE"
    
    if [ "$LOG_MODE" != "ARCHIVELOG" ]; then
        print_warning "Database is not in ARCHIVELOG mode. RMAN requires ARCHIVELOG mode for online backups."
        read -p "Do you want to enable ARCHIVELOG mode? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            enable_archivelog
        else
            print_error "ARCHIVELOG mode is required for RMAN backups. Exiting."
            exit 1
        fi
    fi
    
    rm -f /tmp/db_check.log
}

# Function to enable archive log mode
enable_archivelog() {
    print_section "Enabling ARCHIVELOG Mode"
    
    sqlplus -s / as sysdba << EOF
    SHUTDOWN IMMEDIATE;
    STARTUP MOUNT;
    ALTER DATABASE ARCHIVELOG;
    ALTER DATABASE OPEN;
    SELECT 'Archive log mode enabled: ' || log_mode FROM v\$database;
    EXIT;
EOF
    
    if [ $? -eq 0 ]; then
        print_status "ARCHIVELOG mode enabled successfully"
    else
        print_error "Failed to enable ARCHIVELOG mode"
        exit 1
    fi
}

# Function to configure RMAN
configure_rman() {
    print_section "Configuring RMAN Settings"
    
    # Create RMAN configuration script
    cat > /tmp/rman_config.rman << EOF
CONNECT TARGET /;

-- Show current configuration
SHOW ALL;

-- Basic RMAN Configuration
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BACKUP_BASE}/controlfile/cf_%F';
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '${BACKUP_BASE}/controlfile/snapcf_${ORACLE_SID}.f';

-- Retention Policy Configuration
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;

-- Backup Optimization
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';

-- Channel and Parallelism Configuration
CONFIGURE DEVICE TYPE DISK PARALLELISM 4;
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 2G;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/%U';

-- Archive Log Deletion Policy
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;

-- Show final configuration
SHOW ALL;

EXIT;
EOF
    
    # Execute RMAN configuration
    rman @/tmp/rman_config.rman > /tmp/rman_config.log 2>&1
    
    if [ $? -eq 0 ]; then
        print_status "RMAN configuration completed successfully"
    else
        print_error "RMAN configuration failed. Check log:"
        cat /tmp/rman_config.log
        exit 1
    fi
    
    rm -f /tmp/rman_config.rman
}

# Function to configure Fast Recovery Area
configure_fra() {
    print_section "Configuring Fast Recovery Area"
    
    sqlplus -s / as sysdba << EOF > /tmp/fra_config.log 2>&1
    ALTER SYSTEM SET db_recovery_file_dest_size=50G;
    ALTER SYSTEM SET db_recovery_file_dest='${FRA_BASE}';
    SHOW PARAMETER db_recovery_file_dest;
    SELECT * FROM v\$recovery_file_dest;
    EXIT;
EOF
    
    if [ $? -eq 0 ]; then
        print_status "Fast Recovery Area configured successfully"
    else
        print_error "Fast Recovery Area configuration failed"
        cat /tmp/fra_config.log
        exit 1
    fi
    
    rm -f /tmp/fra_config.log
}

# Function to test RMAN configuration
test_rman_config() {
    print_section "Testing RMAN Configuration"
    
    # Create test script
    cat > /tmp/rman_test.rman << EOF
CONNECT TARGET /;

-- Validate database
VALIDATE DATABASE;

-- Test backup
BACKUP VALIDATE DATABASE;

-- Show backup summary
LIST BACKUP SUMMARY;

-- Check for issues
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;

-- Report status
REPORT SCHEMA;

EXIT;
EOF
    
    # Execute test
    rman @/tmp/rman_test.rman > /tmp/rman_test.log 2>&1
    
    if [ $? -eq 0 ]; then
        print_status "RMAN configuration test passed"
    else
        print_warning "RMAN configuration test had issues. Check log:"
        cat /tmp/rman_test.log
    fi
    
    rm -f /tmp/rman_test.rman
}

# Function to create operational scripts
create_scripts() {
    print_section "Creating Operational Scripts"
    
    # Create backup script
    cat > ${BACKUP_BASE}/rman_backup.sh << 'EOF'
#!/bin/bash
# RMAN Backup Script
# Generated by rman_config_setup.sh

ORACLE_HOME=__ORACLE_HOME__
ORACLE_SID=__ORACLE_SID__
BACKUP_BASE=__BACKUP_BASE__
export PATH=$ORACLE_HOME/bin:$PATH

LOG_FILE=${BACKUP_BASE}/logs/backup_$(date +%Y%m%d_%H%M%S).log
mkdir -p ${BACKUP_BASE}/logs

echo "Starting RMAN backup at $(date)" > $LOG_FILE

rman target / << EOL >> $LOG_FILE 2>&1
RUN {
    BACKUP DATABASE PLUS ARCHIVELOG;
    DELETE NOPROMPT OBSOLETE;
    DELETE NOPROMPT EXPIRED BACKUP;
    DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
}
EXIT;
EOL

if [ $? -eq 0 ]; then
    echo "RMAN backup completed successfully at $(date)" >> $LOG_FILE
    echo "SUCCESS: RMAN backup completed"
else
    echo "RMAN backup failed at $(date)" >> $LOG_FILE
    echo "ERROR: RMAN backup failed. Check log: $LOG_FILE"
    exit 1
fi
EOF
    
    # Replace placeholders in backup script
    sed -i "s|__ORACLE_HOME__|${ORACLE_HOME}|g" ${BACKUP_BASE}/rman_backup.sh
    sed -i "s|__ORACLE_SID__|${ORACLE_SID}|g" ${BACKUP_BASE}/rman_backup.sh
    sed -i "s|__BACKUP_BASE__|${BACKUP_BASE}|g" ${BACKUP_BASE}/rman_backup.sh
    chmod +x ${BACKUP_BASE}/rman_backup.sh
    
    # Create monitoring script
    cat > ${BACKUP_BASE}/rman_monitor.sql << EOF
-- RMAN Monitoring Script
SET PAGESIZE 100
SET LINESIZE 200
COLUMN STATUS FORMAT A10
COLUMN START_TIME FORMAT A20
COLUMN END_TIME FORMAT A20

SELECT 
    session_key,
    status,
    to_char(start_time, 'DD-MON-YYYY HH24:MI:SS') start_time,
    to_char(end_time, 'DD-MON-YYYY HH24:MI:SS') end_time,
    elapsed_seconds,
    input_bytes,
    output_bytes
FROM v\$rman_backup_job_details
WHERE start_time > sysdate - 7
ORDER BY start_time DESC;
EOF
    
    # Create configuration backup
    cat > ${BACKUP_BASE}/rman_show_config.sh << 'EOF'
#!/bin/bash
# RMAN Configuration Display Script

ORACLE_HOME=__ORACLE_HOME__
ORACLE_SID=__ORACLE_SID__
export PATH=$ORACLE_HOME/bin:$PATH

echo "RMAN Configuration for database: $ORACLE_SID"
echo "Generated on: $(date)"
echo "=========================================="

rman target / << EOL
SHOW ALL;
LIST BACKUP SUMMARY;
REPORT SCHEMA;
EXIT;
EOL
EOF
    
    # Replace placeholders in config script
    sed -i "s|__ORACLE_HOME__|${ORACLE_HOME}|g" ${BACKUP_BASE}/rman_show_config.sh
    sed -i "s|__ORACLE_SID__|${ORACLE_SID}|g" ${BACKUP_BASE}/rman_show_config.sh
    chmod +x ${BACKUP_BASE}/rman_show_config.sh
    
    print_status "Operational scripts created:"
    print_status "  Backup script: ${BACKUP_BASE}/rman_backup.sh"
    print_status "  Monitor script: ${BACKUP_BASE}/rman_monitor.sql"
    print_status "  Config script: ${BACKUP_BASE}/rman_show_config.sh"
}

# Function to generate summary report
generate_summary() {
    print_section "Generating Configuration Summary"
    
    cat > ${BACKUP_BASE}/rman_config_summary.txt << EOF
RMAN Configuration Summary
==========================
Database: ${ORACLE_SID}
Oracle Home: ${ORACLE_HOME}
Backup Location: ${BACKUP_BASE}
FRA Location: ${FRA_BASE}
Configuration Date: $(date)
Configured by: $(whoami)

Directory Structure:
$(ls -la ${BACKUP_BASE})

RMAN Configuration:
$(rman target / << EOL
SHOW ALL;
EXIT;
EOL
)

Database Information:
$(sqlplus -s / as sysdba << EOL
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT 'Database Name: ' || name FROM v\$database;
SELECT 'Instance Name: ' || instance_name FROM v\$instance;
SELECT 'Archive Log Mode: ' || log_mode FROM v\$database;
SELECT 'Database Size: ' || ROUND(SUM(bytes)/1024/1024/1024,2) || ' GB' FROM dba_data_files;
EXIT;
EOL
)
EOF
    
    print_status "Configuration summary saved to: ${BACKUP_BASE}/rman_config_summary.txt"
}

# Function to cleanup temporary files
cleanup() {
    print_section "Cleaning Up Temporary Files"
    rm -f /tmp/rman_*.log /tmp/rman_*.rman /tmp/db_check.log /tmp/fra_config.log
    print_status "Cleanup completed"
}

# Main execution function
main() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "    Oracle RMAN Configuration Setup Script"
    echo "=============================================="
    echo -e "${NC}"
    
    # Check if running as root
    if [ $(id -u) -eq 0 ]; then
        print_warning "Running as root. Consider running as oracle user."
    fi
    
    # Execute configuration steps
    check_oracle_env
    create_directories
    check_database
    configure_fra
    configure_rman
    test_rman_config
    create_scripts
    generate_summary
    cleanup
    
    print_section "RMAN Configuration Completed Successfully"
    print_status "Configuration files location: ${BACKUP_BASE}"
    print_status "Test your configuration by running: ${BACKUP_BASE}/rman_backup.sh"
    print_status "Monitor backups using: sqlplus / as sysdba @${BACKUP_BASE}/rman_monitor.sql"
    
    echo -e "\n${GREEN}RMAN configuration setup completed successfully!${NC}"
}

# Script usage information
usage() {
    echo "Usage: $0 [ORACLE_SID] [BACKUP_BASE_PATH] [FRA_BASE_PATH]"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use defaults"
    echo "  $0 PRODDB                            # Specify SID only"
    echo "  $0 PRODDB /backup/rman               # Specify SID and backup path"
    echo "  $0 PRODDB /backup/rman /fra          # Specify all parameters"
    echo ""
    echo "Defaults:"
    echo "  ORACLE_SID: PRODDB"
    echo "  BACKUP_BASE: /backup/rman"
    echo "  FRA_BASE: /u01/app/oracle/fast_recovery_area"
    exit 1
}

# Check command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

# Execute main function
main "$@"
```

### Windows PowerShell Script
```powershell
# RMAN Complete Configuration Script for Windows
# File: rman_config_setup.ps1
# Usage: .\rman_config_setup.ps1 [-OracleSid PRODDB] [-BackupBase D:\backup\rman] [-FraBase D:\fra]

param(
    [string]$OracleSid = "PRODDB",
    [string]$BackupBase = "D:\backup\rman",
    [string]$FraBase = "D:\fra",
    [string]$OracleHome = $env:ORACLE_HOME
)

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n==== $Title ====" -ForegroundColor Blue
}

# Main configuration function
function Configure-RMAN {
    Write-Section "Oracle RMAN Configuration Setup"
    
    # Set environment variables
    $env:ORACLE_SID = $OracleSid
    $env:PATH = "$OracleHome\bin;$env:PATH"
    
    Write-Status "Oracle Environment:"
    Write-Status "ORACLE_HOME: $OracleHome"
    Write-Status "ORACLE_SID: $OracleSid"
    Write-Status "BACKUP_BASE: $BackupBase"
    Write-Status "FRA_BASE: $FraBase"
    
    # Create directories
    Write-Section "Creating Directory Structure"
    New-Item -ItemType Directory -Force -Path "$BackupBase\datafile" | Out-Null
    New-Item -ItemType Directory -Force -Path "$BackupBase\archivelog" | Out-Null
    New-Item -ItemType Directory -Force -Path "$BackupBase\controlfile" | Out-Null
    New-Item -ItemType Directory -Force -Path "$FraBase" | Out-Null
    Write-Status "Directories created successfully"
    
    # Configure RMAN
    Write-Section "Configuring RMAN"
    
    $rmanScript = @"
CONNECT TARGET /;
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '$BackupBase\controlfile\cf_%F';
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
CONFIGURE DEVICE TYPE DISK PARALLELISM 4;
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 2G;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '$BackupBase\datafile\%U';
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;
SHOW ALL;
EXIT;
"@
    
    $rmanScript | Out-File -FilePath "$env:TEMP\rman_config.rman" -Encoding ASCII
    
    # Execute RMAN configuration
    $result = Start-Process -FilePath "rman" -ArgumentList "@$env:TEMP\rman_config.rman" -Wait -PassThru -RedirectStandardOutput "$env:TEMP\rman_output.log"
    
    if ($result.ExitCode -eq 0) {
        Write-Status "RMAN configuration completed successfully"
    } else {
        Write-Error "RMAN configuration failed"
        Get-Content "$env:TEMP\rman_output.log"
        return
    }
    
    # Configure FRA
    Write-Section "Configuring Fast Recovery Area"
    
    $sqlScript = @"
ALTER SYSTEM SET db_recovery_file_dest_size=50G;
ALTER SYSTEM SET db_recovery_file_dest='$FraBase';
EXIT;
"@
    
    $sqlScript | sqlplus "/ as sysdba"
    
    # Create backup script
    Write-Section "Creating Backup Script"
    
    $backupScript = @"
@echo off
set ORACLE_HOME=$OracleHome
set ORACLE_SID=$OracleSid
set PATH=%ORACLE_HOME%\bin;%PATH%

if not exist "$BackupBase\logs" mkdir "$BackupBase\logs"

echo Starting RMAN backup at %date% %time%

rman target / ^<^< EOF
RUN {
    BACKUP DATABASE PLUS ARCHIVELOG;
    DELETE NOPROMPT OBSOLETE;
    DELETE NOPROMPT EXPIRED BACKUP;
    DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
}
EXIT;
EOF

echo RMAN backup completed at %date% %time%
"@
    
    $backupScript | Out-File -FilePath "$BackupBase\rman_backup.bat" -Encoding ASCII
    
    Write-Status "Configuration completed successfully!"
    Write-Status "Backup script created: $BackupBase\rman_backup.bat"
    
    # Cleanup
    Remove-Item "$env:TEMP\rman_config.rman" -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\rman_output.log" -ErrorAction SilentlyContinue
}

# Execute configuration
Configure-RMAN
```

---

**Note**: 
- **Linux/Unix Script**: Save as `rman_config_setup.sh`, make executable with `chmod +x rman_config_setup.sh`
- **Windows Script**: Save as `rman_config_setup.ps1`, run with PowerShell execution policy set appropriately
- Both scripts are fully automated and include error handling, logging, and operational script generation
