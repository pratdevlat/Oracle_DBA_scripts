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

---

**Note**: Replace environment variables (${ORACLE_SID}, ${ORACLE_HOME}, ${BACKUP_BASE}, ${FRA_BASE}) with actual values for your environment before executing commands.
