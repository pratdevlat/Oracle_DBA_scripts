# Oracle Database Backup, Restore, and Recovery Guide

This document consolidates comprehensive information on Oracle RMAN and Data Pump operations for backup, restore, recovery, monitoring, and configuration. It aims to provide a unified guide with key concepts, examples of common commands, and best practices.

**Important Note:** Always test commands thoroughly in a development or test environment before executing them in production. Replace placeholder values like `'/backup_location'` or `'mydb'` with your actual paths and database names.

-----

## Table of Contents

1.  [Environment Setup and Pre-Checks](https://www.google.com/search?q=%23environment-setup-and-pre-checks)
      * [Environment Variables Setup](https://www.google.com/search?q=%23environment-variables-setup)
      * [Pre-Configuration / Pre-Recovery Validation](https://www.google.com/search?q=%23pre-configuration--pre-recovery-validation)
      * [Create Backup Directory Structure](https://www.google.com/search?q=%23create-backup-directory-structure)
2.  [Oracle RMAN Backup Operations](https://www.google.com/search?q=%23oracle-rman-backup-operations)
      * [Basic RMAN Configuration](https://www.google.com/search?q=%23basic-rman-configuration)
      * [Full Database Backups with Compression and Encryption](https://www.google.com/search?q=%23full-database-backups-with-compression-and-encryption)
          * [Compression Options](https://www.google.com/search?q=%23compression-options)
          * [Encryption Configuration](https://www.google.com/search?q=%23encryption-configuration)
          * [Advanced Full Backup Options](https://www.google.com/search?q=%23advanced-full-backup-options)
      * [Tablespace and Datafile Backups](https://www.google.com/search?q=%23tablespace-and-datafile-backups)
      * [Control File and Parameter File Backups](https://www.google.com/search?q=%23control-file-and-parameter-file-backups)
      * [Image Copies](https://www.google.com/search?q=%23image-copies)
      * [Incremental Backup Strategies](https://www.google.com/search?q=%23incremental-backup-strategies)
          * [Level 0 Incremental Backup (Baseline)](https://www.google.com/search?q=%23level-0-incremental-backup-baseline)
          * [Level 1 Incremental Backup](https://www.google.com/search?q=%23level-1-incremental-backup)
          * [Incremental Backup Strategy Examples](https://www.google.com/search?q=%23incremental-backup-strategy-examples)
      * [Archive Log Backup with Cleanup](https://www.google.com/search?q=%23archive-log-backup-with-cleanup)
          * [Basic Archive Log Backup](https://www.google.com/search?q=%23basic-archive-log-backup)
          * [Archive Log Backup with Cleanup Options](https://www.google.com/search?q=%23archive-log-backup-with-cleanup-options)
          * [Archive Log Deletion Policies](https://www.google.com/search?q=%23archive-log-deletion-policies)
      * [Retention Policy Configuration](https://www.google.com/search?q=%23retention-policy-configuration)
          * [Recovery Window Based Retention](https://www.google.com/search?q=%23recovery-window-based-retention)
          * [Redundancy Based Retention](https://www.google.com/search?q=%23redundancy-based-retention)
      * [Backup Optimization Configuration](https://www.google.com/search?q=%23backup-optimization-configuration)
          * [Enable Backup Optimization](https://www.google.com/search?q=%23enable-backup-optimization)
          * [Configure Backup Multiplexing](https://www.google.com/search?q=%23configure-backup-multiplexing)
          * [Configure Backup Exclude Options](https://www.google.com/search?q=%23configure-backup-exclude-options)
      * [Channel and Parallelism Configuration](https://www.google.com/search?q=%23channel-and-parallelism-configuration)
          * [Configure Default Channels](https://www.google.com/search?q=%23configure-default-channels)
          * [Configure Specific Channels (Optional)](https://www.google.com/search?q=%23configure-specific-channels-optional)
      * [Fast Recovery Area (FRA) Configuration](https://www.google.com/search?q=%23fast-recovery-area-fra-configuration)
3.  [Oracle RMAN Recovery Procedures](https://www.google.com/search?q=%23oracle-rman-recovery-procedures)
      * [Complete Database Restore and Point-in-Time Recovery (PITR)](https://www.google.com/search?q=%23complete-database-restore-and-point-in-time-recovery-pitr)
          * [Pre-Recovery Verification](https://www.google.com/search?q=%23pre-recovery-verification)
          * [Database Shutdown and Startup MOUNT](https://www.google.com/search?q=%23database-shutdown-and-startup-mount)
          * [RMAN Restore and Recovery Commands](https://www.google.com/search?q=%23rman-restore-and-recovery-commands)
          * [Open Database with RESETLOGS](https://www.google.com/search?q=%23open-database-with-resetlogs)
          * [Post-Recovery Verification](https://www.google.com/search?q=%23post-recovery-verification)
      * [Individual Tablespace and Datafile Recovery](https://www.google.com/search?q=%23individual-tablespace-and-datafile-recovery)
          * [Identify Damaged Tablespace/Datafile](https://www.google.com/search?q=%23identify-damaged-tablespace/datafile)
          * [Take Tablespace Offline](https://www.google.com/search?q=%23take-tablespace-offline)
          * [RMAN Restore and Recover Tablespace/Datafile](https://www.google.com/search?q=%23rman-restore-and-recover-tablespace/datafile)
          * [Bring Tablespace Online](https://www.google.com/search?q=%23bring-tablespace-online)
      * [Control File Recovery](https://www.google.com/search?q=%23control-file-recovery)
          * [Scenario: Control File Multiplexing Available](https://www.google.com/search?q=%23scenario-control-file-multiplexing-available)
          * [Scenario: No Multiplexed Control File Available](https://www.google.com/search?q=%23scenario-no-multiplexed-control-file-available)
      * [Server Parameter File (SPFILE) Recovery](https://www.google.com/search?q=%23server-parameter-file-spfile-recovery)
      * [Restoring Archived Redo Logs](https://www.google.com/search?q=%23restoring-archived-redo-logs)
4.  [RMAN Monitoring, Validation, and Troubleshooting](https://www.google.com/search?q=%23rman-monitoring-validation-and-troubleshooting)
      * [Validate, Crosscheck, and Cleanup RMAN Backups](https://www.google.com/search?q=%23validate-crosscheck-and-cleanup-rman-backups)
      * [Monitor RMAN Backup Status](https://www.google.com/search?q=%23monitor-rman-backup-status)
      * [Troubleshooting RMAN Issues](https://www.google.com/search?q=%23troubleshooting-rman-issues)
5.  [RMAN Catalog and Repository Management](https://www.google.com/search?q=%23rman-catalog-and-repository-management)
6.  [Logical Backup Operations (Oracle Data Pump)](https://www.google.com/search?q=%23logical-backup-operations-oracle-data-pump)
      * [Data Pump Exports (expdp)](https://www.google.com/search?q=%23data-pump-exports-expdp)
      * [Data Pump Imports (impdp)](https://www.google.com/search?q=%23data-pump-imports-impdp)
      * [Traditional Exports (exp)](https://www.google.com/search?q=%23traditional-exports-exp)
      * [Monitoring, Validation, and Troubleshooting Export Operations](https://www.google.com/search?q=%23monitoring-validation-and-troubleshooting-export-operations)
7.  [Scheduling and Automation](https://www.google.com/search?q=%23scheduling-and-automation)
      * [Scheduling RMAN Backup Jobs](https://www.google.com/search?q=%23scheduling-rman-backup-jobs)
      * [Scheduling Data Pump Jobs](https://www.google.com/search?q=%23scheduling-data-pump-jobs)
      * [Backup Script Templates](https://www.google.com/search?q=%23backup-script-templates)
8.  [Storage Space Calculations](https://www.google.com/search?q=%23storage-space-calculations)
9.  [Emergency Contacts and Notes](https://www.google.com/search?q=%23emergency-contacts-and-notes)
10. [Recovery SOP Execution Summary](https://www.google.com/search?q=%23recovery-sop-execution-summary)
11. [Best Practices](https://www.google.com/search?q=%23best-practices)

-----

## Environment Setup and Pre-Checks

### Environment Variables Setup

Set environment variables for Oracle Home, SID, and backup/FRA locations.

```bash
# Set environment variables (adjust paths as needed)
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=PRODDB
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman
export FRA_BASE=/u01/app/oracle/fast_recovery_area
```

### Pre-Configuration / Pre-Recovery Validation

Before configuring RMAN or performing recovery, perform essential system and database checks.

```sql
-- Connect to database
sqlplus / as sysdba

-- Check database status
SELECT name, open_mode, database_role FROM v$database;
SELECT instance_name, status, database_status FROM v$instance;

-- Check archivelog mode
SELECT log_mode FROM v$database;

-- If not in archive log mode, enable it
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Verify archive log mode
SELECT log_mode FROM v$database;

-- Check backup status (RMAN)
SELECT * FROM v$backup WHERE status = 'ACTIVE';

-- Check available backups
SELECT * FROM v$backup_set WHERE completion_time > SYSDATE - 30;

-- Verify Backup Availability
SELECT 
    bs.backup_type,
    bs.completion_time,
    bs.size_mb,
    bs.status
FROM (
    SELECT 
        'FULL DATABASE' as backup_type,
        completion_time,
        ROUND(bytes/1024/1024,2) as size_mb,
        status
    FROM v$backup_set 
    WHERE backup_type = 'D'
) bs
ORDER BY completion_time DESC;

-- Check archive log availability
SELECT 
    sequence#,
    name,
    completion_time,
    applied
FROM v$archived_log 
WHERE completion_time > SYSDATE - 7
ORDER BY sequence#;

-- Exit SQL*Plus
EXIT;
```

### Create Backup Directory Structure

Ensure necessary directories for backups and the Fast Recovery Area (FRA) exist and have correct permissions.

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

## Oracle RMAN Backup Operations

### Basic RMAN Configuration

```sql
-- Connect to RMAN
rman target /

-- Check current configuration
SHOW ALL;

-- Check database information
SELECT name, dbid, created FROM v$database;

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

### Full Database Backups with Compression and Encryption {https://www.google.com/search?q=%23full-database-backups-with-compression-and-encryption}

#### Compression Options

RMAN provides various compression algorithms for backup sets.

  * **BASIC Compression (Default)**: Fastest, moderate space savings.
    ```sql
    RMAN> BACKUP AS COMPRESSED BACKUPSET DATABASE;
    RMAN> CONFIGURE COMPRESSION ALGORITHM 'BASIC';
    RMAN> BACKUP DATABASE;
    ```
  * **MEDIUM Compression (Recommended)**: Balanced performance and space savings.
    ```sql
    RMAN> BACKUP AS COMPRESSED BACKUPSET USING 'MEDIUM' DATABASE;
    RMAN> CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
    RMAN> BACKUP DATABASE;
    ```
  * **HIGH Compression (Maximum Space Savings)**: Slower but maximum space savings.
    ```sql
    RMAN> BACKUP AS COMPRESSED BACKUPSET USING 'HIGH' DATABASE;
    RMAN> CONFIGURE COMPRESSION ALGORITHM 'HIGH';
    RMAN> BACKUP DATABASE;
    ```

#### Encryption Configuration

Encrypt your backups for enhanced security.

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
-- Or in configuration
SET ENCRYPTION IDENTIFIED BY "BackupEncrypt123";

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

#### Advanced Full Backup Options

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

### Tablespace and Datafile Backups

You can back up individual tablespaces or datafiles.

  * **Examples:**
    ```rman
    BACKUP TABLESPACE users; -- Backup a specific tablespace
    BACKUP TABLESPACE users, hr; -- Backup multiple tablespaces
    BACKUP DATAFILE 3; -- Backup a specific datafile (where 3 is the datafile ID)
    BACKUP DATABASE; -- Backup all datafiles (full backup)
    BACKUP DATABASE FORMAT '/backup_location/db_%U.bak'; -- Backup datafiles to a specific location
    ```

### Control File and Parameter File Backups

Control files and parameter files are critical. RMAN automatically backs them up, or you can explicitly back them up.

  * **Examples:**
    ```rman
    BACKUP CURRENT CONTROLFILE; -- Backup control file (explicitly)
    BACKUP CONTROLFILE FOR STANDBY FORMAT '/standby_cf/standby_control.bak'; -- For standby
    BACKUP SPFILE; -- Backs up SPFILE to default backup location
    CONFIGURE CONTROLFILE AUTOBACKUP ON; -- Automatic backup (recommended)
    ```

### Image Copies

An image copy is an exact duplicate of a datafile, tablespace, or the entire database.

  * **Examples:**
    ```rman
    COPY DATAFILE 3 TO '/image_copies/datafile03.dbf'; -- Create an image copy of a datafile
    BACKUP AS COPY DATABASE; -- Create image copies of the entire database
    LIST COPY OF DATABASE; -- Manage (list) image copies
    LIST COPY OF DATAFILE 3;
    SWITCH DATAFILE 3 TO COPY; -- Switch to an image copy for recovery
    ```

### Incremental Backup Strategies

#### Level 0 Incremental Backup (Baseline)

A Level 0 backup serves as the baseline for subsequent incremental backups.

```sql
RMAN> BACKUP INCREMENTAL LEVEL 0 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'LEVEL0_BASELINE';

RMAN> RUN {
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    BACKUP INCREMENTAL LEVEL 0 
    AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    TAG 'LEVEL0_ENCRYPTED';
}
```

#### Level 1 Incremental Backup

Level 1 backups capture changes since the last Level 0 or Level 1 backup.

```sql
RMAN> BACKUP INCREMENTAL LEVEL 1 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'LEVEL1_DIFFERENTIAL';

RMAN> BACKUP INCREMENTAL LEVEL 1 CUMULATIVE 
      AS COMPRESSED BACKUPSET 
      DATABASE 
      TAG 'LEVEL1_CUMULATIVE';
```

#### Incremental Backup Strategy Examples

  * **Weekly Level 0, Daily Level 1 Strategy:**
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
  * **Monthly Level 0, Weekly Level 1 Cumulative Strategy:**
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

### Archive Log Backup with Cleanup {https://www.google.com/search?q=%23archive-log-backup-with-cleanup}

#### Basic Archive Log Backup

```sql
-- Backup all archive logs
RMAN> BACKUP ARCHIVELOG ALL;

-- Backup archive logs from specific time
RMAN> BACKUP ARCHIVELOG FROM TIME 'SYSDATE-1';

-- Backup archive logs with compression
RMAN> BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL;
```

#### Archive Log Backup with Cleanup Options

```sql
-- Backup and delete archive logs
RMAN> BACKUP ARCHIVELOG ALL DELETE INPUT;

-- Backup with compression and delete
RMAN> BACKUP AS COMPRESSED BACKUPSET 
      ARCHIVELOG ALL 
      DELETE INPUT 
      TAG 'ARCHLOG_BACKUP_CLEANUP';

-- Backup archive logs older than 1 day and delete them
RMAN> BACKUP ARCHIVELOG FROM TIME 'SYSDATE-2' 
      UNTIL TIME 'SYSDATE-1' 
      DELETE INPUT;

-- Backup recent archive logs (keep last 4 hours)
RMAN> BACKUP ARCHIVELOG FROM TIME 'SYSDATE-1' 
      TAG 'RECENT_ARCHLOG_BACKUP';

-- Comprehensive archive log management
RMAN> RUN {
    BACKUP AS COMPRESSED BACKUPSET 
    ARCHIVELOG ALL 
    TAG 'ARCHLOG_COMPRESSED_BACKUP';
    
    DELETE NOPROMPT ARCHIVELOG UNTIL TIME 'SYSDATE-2' 
    BACKED UP 2 TIMES TO DISK;
    
    CROSSCHECK ARCHIVELOG ALL;
    DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
}
```

#### Archive Log Deletion Policies

Configure policies for automatic deletion of archive logs.

```sql
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;

-- For standby database environments
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON STANDBY;

-- For Data Guard with multiple standbys
RMAN> CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;

-- Verify deletion policy
SHOW ARCHIVELOG DELETION POLICY;
```

### Retention Policy Configuration

#### Recovery Window Based Retention

Configure how long backups should be retained based on a recovery window.

```sql
-- Configure retention policy (adjust days as needed)
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;

-- For production environments
-- CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 30 DAYS;

-- Verify retention policy
SHOW RETENTION POLICY;
```

#### Redundancy Based Retention

Alternatively, configure retention based on the number of redundant backups.

```sql
-- Alternative: Configure redundancy based retention
-- CONFIGURE RETENTION POLICY TO REDUNDANCY 2;

-- For critical systems
-- CONFIGURE RETENTION POLICY TO REDUNDANCY 3;
```

### Backup Optimization Configuration

#### Enable Backup Optimization

```sql
-- Enable backup optimization
CONFIGURE BACKUP OPTIMIZATION ON;

-- Verify optimization settings
SHOW BACKUP OPTIMIZATION;
```

#### Configure Backup Multiplexing

```sql
-- Configure backup multiplexing
CONFIGURE MAXSETSIZE TO 10G;

-- Configure backup duplexing (number of copies)
CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1;

-- For critical systems (create 2 copies)
-- CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 2;
-- CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 2;
```

#### Configure Backup Exclude Options

```sql
-- Exclude specific tablespaces from backup (adjust as needed)
CONFIGURE EXCLUDE FOR TABLESPACE TEMP;
CONFIGURE EXCLUDE FOR TABLESPACE TEMPUNDO;

-- Show excluded tablespaces
SHOW EXCLUDE;
```

### Channel and Parallelism Configuration

Channels perform backup/restore operations; parallelism improves performance.

#### Configure Default Channels

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

#### Configure Specific Channels (Optional)

```sql
-- Configure individual channels with specific settings
CONFIGURE CHANNEL 1 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch1_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 2 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch2_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 3 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch3_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 4 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch4_%U' MAXPIECESIZE 2G;
```

### Fast Recovery Area (FRA) Configuration

The FRA simplifies management of recovery-related files.

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

## Oracle RMAN Recovery Procedures

### Complete Database Restore and Point-in-Time Recovery (PITR)

#### Pre-Recovery Verification

```sql
PROMPT Step 1.1: Verify Backup Availability
SELECT 
    bs.backup_type,
    bs.completion_time,
    bs.size_mb,
    bs.status
FROM (
    SELECT 
        'FULL DATABASE' as backup_type,
        completion_time,
        ROUND(bytes/1024/1024,2) as size_mb,
        status
    FROM v$backup_set 
    WHERE backup_type = 'D'
) bs
ORDER BY completion_time DESC;

-- Check archive log availability
SELECT 
    sequence#,
    name,
    completion_time,
    applied
FROM v$archived_log 
WHERE completion_time > SYSDATE - 7
ORDER BY sequence#;
```

#### Database Shutdown and Startup MOUNT

```sql
PROMPT Step 1.2: Shutdown Database
SHUTDOWN IMMEDIATE;

PROMPT Step 1.3: Startup Database in MOUNT mode
STARTUP MOUNT;
```

#### RMAN Restore and Recovery Commands

These commands are executed within the RMAN prompt.

```rman
PROMPT Step 1.4: Execute RMAN Restore (Run in RMAN)
RESTORE DATABASE;

PROMPT Step 1.5: Execute RMAN Recovery to Point-in-Time
RECOVER DATABASE UNTIL TIME 'YYYY-MM-DD HH24:MI:SS';
-- OR
RECOVER DATABASE UNTIL SCN <scn_number>;
-- OR
RECOVER DATABASE UNTIL SEQUENCE <sequence_number>;
```

#### Open Database with RESETLOGS

```sql
PROMPT Step 1.6: Open Database with RESETLOGS
ALTER DATABASE OPEN RESETLOGS;
```

#### Post-Recovery Verification

```sql
PROMPT Step 1.7: Post-Recovery Verification
SELECT name, open_mode, resetlogs_time FROM v$database;

-- Check for invalid objects
SELECT owner, object_type, COUNT(*) 
FROM dba_objects 
WHERE status = 'INVALID' 
GROUP BY owner, object_type;
```

### Individual Tablespace and Datafile Recovery

#### Identify Damaged Tablespace/Datafile

```sql
PROMPT Step 2.1: Identify Damaged Components
SELECT 
    ts.tablespace_name,
    df.file_name,
    df.status,
    df.enabled
FROM dba_tablespaces ts
JOIN dba_data_files df ON ts.tablespace_name = df.tablespace_name
WHERE ts.status != 'ONLINE' OR df.status != 'AVAILABLE';

-- Check for datafile needing recovery
SELECT 
    file#,
    name,
    status,
    error,
    recover,
    fuzzy
FROM v$datafile_header
WHERE recover = 'YES' OR fuzzy = 'YES';
```

#### Take Tablespace Offline

```sql
PROMPT Step 2.2: Take Tablespace Offline
ALTER TABLESPACE TABLESPACE_NAME OFFLINE IMMEDIATE; -- Replace 'TABLESPACE_NAME' with actual tablespace name
```

#### RMAN Restore and Recover Tablespace/Datafile

These commands are executed within the RMAN prompt.

```rman
PROMPT Step 2.3: Execute RMAN Restore (Run in RMAN)
RESTORE TABLESPACE tablespace_name;
-- OR for specific datafile:
RESTORE DATAFILE 'datafile_path';
-- OR by file number:
RESTORE DATAFILE file_number;

PROMPT Step 2.4: Execute RMAN Recovery (Run in RMAN)
RECOVER TABLESPACE tablespace_name;
-- OR for specific datafile:
RECOVER DATAFILE 'datafile_path';
-- OR by file number:
RECOVER DATAFILE file_number;
```

#### Bring Tablespace Online

```sql
PROMPT Step 2.5: Bring Tablespace Online
ALTER TABLESPACE TABLESPACE_NAME ONLINE; -- Replace 'TABLESPACE_NAME' with actual tablespace name
```

### Control File Recovery

#### Scenario: Control File Multiplexing Available

If you have multiplexed control files, simply copy a good control file over the damaged one.

```bash
-- Example: Copy control file from a good location
cp /u01/app/oracle/oradata/PRODDB/control02.ctl /u01/app/oracle/oradata/PRODDB/control01.ctl
```

#### Scenario: No Multiplexed Control File Available

If all control files are lost, you must restore them via RMAN.

```sql
PROMPT Step 3.2: Restore Control File (No Multiplexing)
SHUTDOWN ABORT;
STARTUP NOMOUNT;

-- In RMAN:
RESTORE CONTROLFILE FROM AUTOBACKUP;
-- OR if autobackup is not configured and you know the location/tag:
RESTORE CONTROLFILE FROM '/backup/rman/control_file_backup.bak';

-- After restoring control file, mount the database:
ALTER DATABASE MOUNT;

-- Recover database (may require a full restore if no recent backups)
RECOVER DATABASE;

-- Open with RESETLOGS
ALTER DATABASE OPEN RESETLOGS;
```

### Server Parameter File (SPFILE) Recovery

```sql
PROMPT Step 4.1: Restore SPFILE
SHUTDOWN ABORT;
STARTUP NOMOUNT;

-- In RMAN:
RESTORE SPFILE FROM AUTOBACKUP;
-- OR from a specific backup piece:
RESTORE SPFILE FROM '/backup/rman/spfile_backup.bak';

-- Start up with the restored SPFILE
STARTUP;
```

### Restoring Archived Redo Logs

```sql
PROMPT Step 5.1: Restore Archived Redo Logs
RESTORE ARCHIVELOG ALL;
-- OR for a specific range:
RESTORE ARCHIVELOG FROM SEQUENCE 100 UNTIL SEQUENCE 150;
-- OR from a specific time:
RESTORE ARCHIVELOG FROM TIME 'SYSDATE-2' UNTIL TIME 'SYSDATE-1';
```

## RMAN Monitoring, Validation, and Troubleshooting

### Validate, Crosscheck, and Cleanup RMAN Backups

  * **Validate:** Checks if backup sets are usable without actually restoring them.
  * **Crosscheck:** Updates the RMAN repository about the physical existence and validity of backup pieces and copies.
  * **Cleanup:** Deletes obsolete or expired backups.

<!-- end list -->

```rman
VALIDATE BACKUPSET 123; -- Validate a backup set
VALIDATE DATABASE; -- Validate the entire database backup

CROSSCHECK BACKUP; -- Crosscheck all backups
CROSSCHECK COPY;
CROSSCHECK ARCHIVELOG ALL;

DELETE OBSOLETE; -- Delete obsolete backups (based on retention policy)
DELETE EXPIRED BACKUP; -- Delete expired backups (after crosscheck identifies them as expired)
DELETE EXPIRED COPY;
```

### Monitor RMAN Backup Status

```sql
-- Monitor RMAN backup status
SET PAGESIZE 100
SET LINESIZE 200
COLUMN STATUS FORMAT A10
COLUMN START_TIME FORMAT A20
COLUMN END_TIME FORMAT A20
COLUMN ELAPSED_SECONDS FORMAT 999999999
COLUMN INPUT_BYTES FORMAT 999999999999999
COLUMN OUTPUT_BYTES FORMAT 999999999999999
SELECT session_key, status, to_char(start_time, 'DD-MON-YYYY HH24:MI:SS') start_time, to_char(end_time, 'DD-MON-YYYY HH24:MI:SS') end_time, elapsed_seconds, input_bytes, output_bytes FROM v$rman_backup_job_details WHERE start_time > sysdate - 7 ORDER BY start_time DESC;

-- Monitor channels during a backup (from SQL*Plus while RMAN is running):
SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
       ROUND(SOFAR/TOTALWORK*100,2) "% COMPLETE"
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'RMAN%';

-- And within RMAN:
LIST CHANNEL;
```

### Troubleshooting RMAN Issues

  * **Check RMAN log files:** The primary source for errors.
  * **Check alert log:** For database-level errors.
  * **Examine `V$RMAN_STATUS` and `V$RMAN_OUTPUT`:** For RMAN session details.
  * **Check `V$SESSION_LONGOPS`:** If the backup is hung or very slow.
  * **Verify disk space:** Ensure enough space in backup destination and FRA.
  * **Check permissions:** Ensure Oracle user has read/write permissions to backup locations.
  * **Connectivity issues:** If using a catalog or NFS/SMB shares.

## RMAN Catalog and Repository Management

The RMAN repository stores metadata about your backups.

  * **Connect to a recovery catalog:**
    ```rman
    rman target / catalog rmanuser/rmanpwd@rmancatdb
    ```
  * **Register a database with the catalog:**
    ```rman
    REGISTER DATABASE;
    ```
  * **Unregister a database:**
    ```rman
    UNREGISTER DATABASE 'ORCL';
    ```
  * **Catalog a user-managed backup:**
    ```rman
    CATALOG DATAFILECOPY '/path/to/datafile.dbf';
    ```
  * **Report obsolete backups:**
    ```rman
    REPORT OBSOLETE;
    ```
  * **List backups in the catalog:**
    ```rman
    LIST BACKUP OF DATABASE;
    LIST BACKUP OF ARCHIVELOG ALL;
    ```
  * **Maintain the catalog:**
    ```rman
    DELETE EXPIRED BACKUP;
    DELETE NOPROMPT OBSOLETE;
    ```

## Logical Backup Operations (Oracle Data Pump)

### Data Pump Exports (expdp)

Data Pump is the preferred tool for logical backups.

  * **Examples (executed from the OS command line):**
    ```bash
    expdp system/password@ORCL DUMPFILE=full_db.dmp LOGFILE=full_db.log FULL=Y DIRECTORY=DATA_PUMP_DIR -- Full database export
    expdp system/password@ORCL DUMPFILE=hr_schema.dmp LOGFILE=hr_schema.log SCHEMAS=HR DIRECTORY=DATA_PUMP_DIR -- Schema level export
    expdp system/password@ORCL DUMPFILE=emp_dept.dmp LOGFILE=emp_dept.log TABLES=HR.EMPLOYEES,HR.DEPARTMENTS DIRECTORY=DATA_PUMP_DIR -- Table level export
    expdp system/password@ORCL PARFILE=export.par -- Using a parameter file
    ```
    *Example `export.par` file:*
    ```
    DUMPFILE=full_db.dmp
    LOGFILE=full_db.log
    FULL=Y
    DIRECTORY=DATA_PUMP_DIR
    ```

### Data Pump Imports (impdp)

Used to restore data from Data Pump dump files.

  * **Examples (executed from the OS command line):**
    ```bash
    impdp system/password@ORCL DUMPFILE=full_db.dmp LOGFILE=full_db_imp.log FULL=Y DIRECTORY=DATA_PUMP_DIR -- Full database import
    impdp system/password@ORCL DUMPFILE=hr_schema.dmp LOGFILE=hr_schema_imp.log SCHEMAS=HR DIRECTORY=DATA_PUMP_DIR REMAP_SCHEMA=HR:HR_NEW -- Schema level import
    impdp system/password@ORCL DUMPFILE=emp_dept.dmp LOGFILE=emp_dept_imp.log TABLES=HR.EMPLOYEES REMAP_TABLE=EMPLOYEES:EMP DIRECTORY=DATA_PUMP_DIR -- Table level import
    ```

### Traditional Exports (exp)

Older tool, generally deprecated in favor of Data Pump.

  * **Examples (executed from the OS command line):**
    ```bash
    exp system/password@ORCL FULL=Y FILE=full_db_trad.dmp LOG=full_db_trad.log -- Full database export
    exp system/password@ORCL OWNER=HR FILE=hr_schema_trad.dmp LOG=hr_schema_trad.log -- Schema level export
    ```

### Monitoring, Validation, and Troubleshooting Export Operations

  * **Monitor an active Data Pump job:**
    ```bash
    expdp system/password@ORCL ATTACH=SYS_EXPORT_FULL_01 -- Job name found in log or DBA_DATAPUMP_JOBS
    ```
    Then, at the `Export>` prompt, type `STATUS` or `CONTINUE_CLIENT`.
  * **View Data Pump jobs:**
    ```sql
    SELECT owner, job_name, operation, job_mode, state, attached_sessions FROM dba_datapump_jobs;
    ```
  * **Check `V$SESSION_LONGOPS`:** For long-running Data Pump processes.
  * **Check log files:** The primary source for troubleshooting.

## Scheduling and Automation

### Scheduling RMAN Backup Jobs

RMAN jobs are typically scheduled using operating system schedulers (`cron` on Linux/Unix, Task Scheduler on Windows) or Oracle's `DBMS_SCHEDULER`.

  * **Linux/Unix (`crontab` entry):**
    ```cron
    0 2 * * * /path/to/backup_script.sh > /path/to/backup_log.log 2>&1
    ```
    *`backup_script.sh` example:*
    ```bash
    #!/bin/bash
    ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
    ORACLE_SID=ORCL
    export ORACLE_HOME ORACLE_SID
    $ORACLE_HOME/bin/rman target / << EOF
    RUN {
      ALLOCATE CHANNEL d1 DEVICE TYPE DISK;
      BACKUP DATABASE PLUS ARCHIVELOG;
      RELEASE CHANNEL d1;
    }
    EXIT;
    EOF
    ```
  * **Oracle `DBMS_SCHEDULER` (from SQL\*Plus):**
    ```sql
    BEGIN
      DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'DAILY_RMAN_FULL_BACKUP',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN DBMS_RCVMAN.BACKUP_DATABASE; END;', -- Simplified, usually calls a shell script
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=2',
        enabled         => TRUE,
        comments        => 'Daily full RMAN backup job');
    END;
    /
    ```

### Scheduling Data Pump Jobs

Similar to RMAN, use OS schedulers or `DBMS_SCHEDULER` to execute `expdp` or `impdp` commands.

### Backup Script Templates

  * **Linux/Unix RMAN Backup Script Template:**
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
  * **Windows RMAN Backup Batch Script (Example):**
    ```batch
    @echo off
    set ORACLE_HOME=C:\app\oracle\product\19.0.0\dbhome_1
    set ORACLE_SID=ORCL
    set PATH=%ORACLE_HOME%\bin;%PATH%

    if not exist "C:\backup\rman\logs" mkdir "C:\backup\rman\logs"

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
    ```

## Storage Space Calculations

  * **Compression Ratios:**

      * **BASIC Compression**: 50-60% space reduction
      * **MEDIUM Compression**: 60-70% space reduction
      * **HIGH Compression**: 70-80% space reduction

  * **Space Planning Formula:**

    ```
    Full Backup Size = Database Size × (1 - Compression Ratio)
    Level 0 Size = Full Backup Size
    Level 1 Size = Changed Data × (1 - Compression Ratio)
    Archive Log Size = Daily Archive Generation × Retention Days
    ```

## Emergency Contacts and Notes

  * DBA Team: [Contact Information]
  * System Administrator: [Contact Information]
  * Management: [Contact Information]

## Recovery SOP Execution Summary

1.  Always verify backup availability before starting recovery.
2.  Document all recovery steps and timings.
3.  Validate database integrity after recovery.
4.  Update disaster recovery documentation.
5.  Schedule full backup after successful recovery.

## Best Practices

  * **Regularly test backups:** The most important practice.
  * **Implement a robust retention policy:** To ensure enough recovery points.
  * **Use a recovery catalog:** For easier management of multiple databases and longer history.
  * **Enable `CONTROLFILE AUTOBACKUP`:** Critical for recovering from control file loss.
  * **Enable `ARCHIVELOG MODE`:** Essential for point-in-time recovery and Data Guard.
  * **Configure FRA:** Simplifies management of recovery-related files.
  * **Implement Block Change Tracking:** For efficient incremental backups.
  * **Backup archive logs regularly:** Critical for recovery.
  * **Automate backups:** Use `cron` or `DBMS_SCHEDULER`.
  * **Monitor backups:** Regularly check logs and status.
  * **Document your backup and recovery procedures:** Crucial for DR.
  * **Store backups offsite:** For disaster recovery.
  * **Validate backups regularly:** To ensure they are usable.
  * **Consider Data Guard:** For high availability and disaster recovery.

-----
