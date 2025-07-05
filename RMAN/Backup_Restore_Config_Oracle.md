# Oracle Database Backup, Restore, and Recovery Complete Guide

This comprehensive guide consolidates all aspects of Oracle RMAN and Data Pump operations for backup, restore, recovery, monitoring, and configuration. It includes practical examples, automation scripts, and best practices.

**Important Note:** Always test commands thoroughly in a development or test environment before executing them in production. Replace placeholder values with your actual paths and database names.

---

## Table of Contents

1. [Environment Setup and Pre-Checks](#1-environment-setup-and-pre-checks)
   - [1.1 Environment Variables Setup](#11-environment-variables-setup)
   - [1.2 Pre-Configuration Validation](#12-pre-configuration-validation)
   - [1.3 Directory Structure Creation](#13-directory-structure-creation)

2. [RMAN Configuration](#2-rman-configuration)
   - [2.1 Basic RMAN Configuration](#21-basic-rman-configuration)
   - [2.2 Retention Policy Configuration](#22-retention-policy-configuration)
   - [2.3 Backup Optimization Configuration](#23-backup-optimization-configuration)
   - [2.4 Channel and Parallelism Configuration](#24-channel-and-parallelism-configuration)
   - [2.5 Fast Recovery Area (FRA) Configuration](#25-fast-recovery-area-fra-configuration)

3. [RMAN Backup Operations](#3-rman-backup-operations)
   - [3.1 Full Database Backups](#31-full-database-backups)
   - [3.2 Incremental Backup Strategies](#32-incremental-backup-strategies)
   - [3.3 Archive Log Backup and Management](#33-archive-log-backup-and-management)
   - [3.4 Tablespace and Datafile Backups](#34-tablespace-and-datafile-backups)
   - [3.5 Control File and Parameter File Backups](#35-control-file-and-parameter-file-backups)
   - [3.6 Image Copies](#36-image-copies)

4. [RMAN Recovery Procedures](#4-rman-recovery-procedures)
   - [4.1 Complete Database Restore and PITR](#41-complete-database-restore-and-pitr)
   - [4.2 Tablespace and Datafile Recovery](#42-tablespace-and-datafile-recovery)
   - [4.3 Control File Recovery](#43-control-file-recovery)
   - [4.4 Block-Level Recovery](#44-block-level-recovery)
   - [4.5 Archive Log Recovery](#45-archive-log-recovery)
   - [4.6 Disaster Recovery Procedures](#46-disaster-recovery-procedures)

5. [Data Pump Operations](#5-data-pump-operations)
   - [5.1 Data Pump Exports](#51-data-pump-exports)
   - [5.2 Data Pump Imports](#52-data-pump-imports)
   - [5.3 Traditional Export/Import](#53-traditional-exportimport)
   - [5.4 Monitoring Data Pump Operations](#54-monitoring-data-pump-operations)

6. [Special Recovery Scenarios](#6-special-recovery-scenarios)
   - [6.1 Flashback Database Operations](#61-flashback-database-operations)
   - [6.2 Standby Database Recovery](#62-standby-database-recovery)
   - [6.3 Media Failure Recovery](#63-media-failure-recovery)

7. [Monitoring and Validation](#7-monitoring-and-validation)
   - [7.1 Backup Validation and Crosscheck](#71-backup-validation-and-crosscheck)
   - [7.2 Performance Monitoring](#72-performance-monitoring)
   - [7.3 Troubleshooting](#73-troubleshooting)

8. [Automation Scripts](#8-automation-scripts)
   - [8.1 Linux/Unix Shell Scripts](#81-linuxunix-shell-scripts)
   - [8.2 Windows PowerShell Scripts](#82-windows-powershell-scripts)
   - [8.3 Scheduling with DBMS_SCHEDULER](#83-scheduling-with-dbms_scheduler)

9. [Performance Optimization](#9-performance-optimization)
   - [9.1 Parallel Processing](#91-parallel-processing)
   - [9.2 Compression Strategies](#92-compression-strategies)
   - [9.3 Storage Optimization](#93-storage-optimization)

10. [Best Practices and Guidelines](#10-best-practices-and-guidelines)
    - [10.1 Backup Best Practices](#101-backup-best-practices)
    - [10.2 Recovery Best Practices](#102-recovery-best-practices)
    - [10.3 Testing and Documentation](#103-testing-and-documentation)

---

## 1. Environment Setup and Pre-Checks

### 1.1 Environment Variables Setup

Configure environment variables for Oracle operations:

**Linux/Unix:**
```bash
# Set environment variables (adjust paths as needed)
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=PRODDB
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman
export FRA_BASE=/u01/app/oracle/fast_recovery_area
```

**Windows:**
```cmd
set ORACLE_HOME=C:\app\oracle\product\19.0.0\dbhome_1
set ORACLE_SID=PRODDB
set BACKUP_BASE=D:\backup\rman
set FRA_BASE=D:\app\oracle\fast_recovery_area
set PATH=%ORACLE_HOME%\bin;%PATH%
```

### 1.2 Pre-Configuration Validation

Perform essential system and database checks before any backup or recovery operation:

```sql
-- Connect to database
sqlplus / as sysdba

-- Check database status
SELECT name, open_mode, database_role FROM v$database;
SELECT instance_name, status, startup_time, database_status FROM v$instance;

-- Check archive log mode
SELECT log_mode FROM v$database;

-- Check backup status
SELECT * FROM v$backup WHERE status = 'ACTIVE';

-- Check available backups
SELECT * FROM v$backup_set WHERE completion_time > SYSDATE - 30;

-- Check for datafiles needing recovery
SELECT file#, name, status, error, recover, fuzzy
FROM v$datafile_header
WHERE recover = 'YES' OR fuzzy = 'YES';

-- Check archive log availability
SELECT sequence#, name, completion_time, applied
FROM v$archived_log 
WHERE completion_time > SYSDATE - 7
ORDER BY sequence#;

-- Check for gaps in archive logs
SELECT thread#, low_sequence#, high_sequence#
FROM v$archive_gap;

-- Check control file status
SELECT name, status, is_recovery_dest_file, block_size, file_size_blks
FROM v$controlfile;

-- Check FRA usage
SELECT * FROM v$recovery_file_dest;
SELECT * FROM v$recovery_area_usage;
```

**Enable Archive Log Mode if Needed:**
```sql
-- If not in archive log mode, enable it
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Verify archive log mode
SELECT log_mode FROM v$database;
EXIT;
```

### 1.3 Directory Structure Creation

Create necessary directories for backups and recovery:

```bash
# Create backup directories
mkdir -p ${BACKUP_BASE}/{datafile,archivelog,controlfile,logs}
mkdir -p ${FRA_BASE}

# Set permissions
chmod 755 ${BACKUP_BASE} ${FRA_BASE}
chown oracle:oinstall ${BACKUP_BASE} ${FRA_BASE}

# Verify directory creation
ls -la ${BACKUP_BASE}
```

## 2. RMAN Configuration

### 2.1 Basic RMAN Configuration

```sql
-- Connect to RMAN
rman target /

-- Check current configuration
SHOW ALL;

-- Basic configuration settings
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BACKUP_BASE}/controlfile/cf_%F';
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '${BACKUP_BASE}/controlfile/snapcf_${ORACLE_SID}.f';

-- Verify configuration
SHOW DEFAULT DEVICE TYPE;
SHOW CONTROLFILE AUTOBACKUP;
SHOW CONTROLFILE AUTOBACKUP FORMAT;
```

### 2.2 Retention Policy Configuration

```sql
-- Configure recovery window based retention
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;

-- Alternative: Configure redundancy based retention
-- CONFIGURE RETENTION POLICY TO REDUNDANCY 3;

-- For production environments
-- CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 30 DAYS;

-- Verify retention policy
SHOW RETENTION POLICY;
```

### 2.3 Backup Optimization Configuration

```sql
-- Enable backup optimization
CONFIGURE BACKUP OPTIMIZATION ON;

-- Configure compression algorithm
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
-- Options: 'BASIC', 'LOW', 'MEDIUM', 'HIGH'

-- Configure encryption
CONFIGURE ENCRYPTION ALGORITHM 'AES256';
-- Alternative algorithms: 'AES192', 'AES128'

-- Enable encryption for database
CONFIGURE ENCRYPTION FOR DATABASE ON;

-- Configure backup multiplexing
CONFIGURE MAXSETSIZE TO 10G;

-- Configure backup copies
CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1;
CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1;

-- Exclude specific tablespaces
CONFIGURE EXCLUDE FOR TABLESPACE TEMP;
CONFIGURE EXCLUDE FOR TABLESPACE TEMPUNDO;

-- Show optimization settings
SHOW BACKUP OPTIMIZATION;
SHOW COMPRESSION ALGORITHM;
SHOW ENCRYPTION ALGORITHM;
SHOW EXCLUDE;
```

### 2.4 Channel and Parallelism Configuration

```sql
-- Configure parallelism
CONFIGURE DEVICE TYPE DISK PARALLELISM 4;

-- Configure channel settings
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 2G;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/%U';

-- Configure specific channels (optional)
CONFIGURE CHANNEL 1 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch1_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 2 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch2_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 3 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch3_%U' MAXPIECESIZE 2G;
CONFIGURE CHANNEL 4 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/ch4_%U' MAXPIECESIZE 2G;

-- Verify channel configuration
SHOW DEVICE TYPE DISK PARALLELISM;
SHOW CHANNEL FOR DEVICE TYPE DISK;
```

### 2.5 Fast Recovery Area (FRA) Configuration

```sql
-- Connect to SQL*Plus
connect / as sysdba

-- Set FRA size and location
ALTER SYSTEM SET db_recovery_file_dest_size=50G;
ALTER SYSTEM SET db_recovery_file_dest='${FRA_BASE}';

-- Verify FRA configuration
SHOW PARAMETER db_recovery_file_dest;

-- Check FRA usage
SELECT * FROM v$recovery_file_dest;

-- Configure archive log deletion policy (in RMAN)
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;
-- For standby environments:
-- CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON STANDBY;

EXIT;
```

## 3. RMAN Backup Operations

### 3.1 Full Database Backups

#### Basic Full Backup
```sql
-- Simple full database backup
BACKUP DATABASE;

-- Full backup with archive logs
BACKUP DATABASE PLUS ARCHIVELOG;

-- Full backup with specific format
BACKUP DATABASE FORMAT '${BACKUP_BASE}/datafile/full_%U.bak';
```

#### Full Backup with Compression
```sql
-- Basic compression (fastest, moderate space savings)
BACKUP AS COMPRESSED BACKUPSET DATABASE;

-- Medium compression (balanced)
BACKUP AS COMPRESSED BACKUPSET USING 'MEDIUM' DATABASE;

-- High compression (maximum space savings)
BACKUP AS COMPRESSED BACKUPSET USING 'HIGH' DATABASE;

-- Configure compression globally
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
BACKUP DATABASE;
```

#### Full Backup with Encryption
```sql
-- Set encryption password
SET ENCRYPTION IDENTIFIED BY "SecurePassword123";

-- Complete backup with compression and encryption
RUN {
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    BACKUP AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'FULL_BACKUP_COMPRESSED_ENCRYPTED';
    DELETE NOPROMPT OBSOLETE;
}
```

#### Advanced Full Backup with Parallelism
```sql
-- Parallel backup with compression and encryption
RUN {
    ALLOCATE CHANNEL c1 TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_%U';
    ALLOCATE CHANNEL c2 TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_%U';
    ALLOCATE CHANNEL c3 TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_%U';
    ALLOCATE CHANNEL c4 TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_%U';
    
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

### 3.2 Incremental Backup Strategies

#### Level 0 Incremental Backup (Baseline)
```sql
-- Basic Level 0 backup
BACKUP INCREMENTAL LEVEL 0 DATABASE;

-- Level 0 with compression
BACKUP INCREMENTAL LEVEL 0 
AS COMPRESSED BACKUPSET 
DATABASE 
TAG 'LEVEL0_BASELINE';

-- Level 0 with encryption
RUN {
    SET ENCRYPTION IDENTIFIED BY "SecurePassword123";
    BACKUP INCREMENTAL LEVEL 0 
    AS COMPRESSED BACKUPSET 
    USING 'MEDIUM'
    DATABASE 
    TAG 'LEVEL0_ENCRYPTED';
}
```

#### Level 1 Incremental Backup
```sql
-- Level 1 differential (default)
BACKUP INCREMENTAL LEVEL 1 
AS COMPRESSED BACKUPSET 
DATABASE 
TAG 'LEVEL1_DIFFERENTIAL';

-- Level 1 cumulative
BACKUP INCREMENTAL LEVEL 1 CUMULATIVE 
AS COMPRESSED BACKUPSET 
DATABASE 
TAG 'LEVEL1_CUMULATIVE';
```

#### Incremental Backup Strategy Examples

**Weekly Level 0, Daily Level 1:**
```sql
-- Sunday: Level 0 backup
RUN {
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
RUN {
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

**Monthly Level 0, Weekly Level 1 Cumulative:**
```sql
-- First Sunday of month: Level 0
BACKUP INCREMENTAL LEVEL 0 
AS COMPRESSED BACKUPSET 
DATABASE 
TAG 'MONTHLY_LEVEL0';

-- Other Sundays: Level 1 Cumulative
BACKUP INCREMENTAL LEVEL 1 CUMULATIVE 
AS COMPRESSED BACKUPSET 
DATABASE 
TAG 'WEEKLY_LEVEL1_CUMULATIVE';
```

### 3.3 Archive Log Backup and Management

#### Basic Archive Log Backup
```sql
-- Backup all archive logs
BACKUP ARCHIVELOG ALL;

-- Backup archive logs from specific time
BACKUP ARCHIVELOG FROM TIME 'SYSDATE-1';

-- Backup archive logs with compression
BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL;

-- Backup specific sequence range
BACKUP ARCHIVELOG FROM SEQUENCE 123 TO SEQUENCE 456;
```

#### Archive Log Backup with Cleanup
```sql
-- Backup and delete archive logs
BACKUP ARCHIVELOG ALL DELETE INPUT;

-- Backup with compression and delete
BACKUP AS COMPRESSED BACKUPSET 
ARCHIVELOG ALL 
DELETE INPUT 
TAG 'ARCHLOG_BACKUP_CLEANUP';

-- Backup archive logs older than 1 day and delete them
BACKUP ARCHIVELOG FROM TIME 'SYSDATE-2' 
UNTIL TIME 'SYSDATE-1' 
DELETE INPUT;

-- Comprehensive archive log management
RUN {
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

#### Configure Archive Log Deletion Policies
```sql
-- Delete after backing up once
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;

-- For standby database environments
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON STANDBY;

-- For Data Guard with multiple standbys
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;

-- Verify deletion policy
SHOW ARCHIVELOG DELETION POLICY;
```

### 3.4 Tablespace and Datafile Backups

```sql
-- Backup specific tablespace
BACKUP TABLESPACE users;

-- Backup multiple tablespaces
BACKUP TABLESPACE users, hr;

-- Backup specific datafile by number
BACKUP DATAFILE 3;

-- Backup specific datafile by name
BACKUP DATAFILE '${ORACLE_BASE}/oradata/PRODDB/users01.dbf';

-- Backup tablespace with compression
BACKUP AS COMPRESSED BACKUPSET TABLESPACE users;

-- Backup tablespace to specific location
BACKUP TABLESPACE users FORMAT '${BACKUP_BASE}/tablespace/users_%U.bak';
```

### 3.5 Control File and Parameter File Backups

```sql
-- Backup current control file
BACKUP CURRENT CONTROLFILE;

-- Backup control file to specific location
BACKUP CURRENT CONTROLFILE FORMAT '${BACKUP_BASE}/controlfile/control_%U.bak';

-- Backup control file for standby
BACKUP CONTROLFILE FOR STANDBY FORMAT '${BACKUP_BASE}/controlfile/standby_control.bak';

-- Backup SPFILE
BACKUP SPFILE;

-- Backup SPFILE to specific location
BACKUP SPFILE FORMAT '${BACKUP_BASE}/spfile/spfile_%U.bak';

-- Configure automatic control file backup
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BACKUP_BASE}/controlfile/cf_%F';
```

### 3.6 Image Copies

```sql
-- Create image copy of a datafile
COPY DATAFILE 3 TO '${BACKUP_BASE}/image_copies/datafile03.dbf';

-- Create image copy of a datafile with tag
BACKUP AS COPY DATAFILE 3 TAG 'USERS_COPY';

-- Create image copies of entire database
BACKUP AS COPY DATABASE;

-- Create image copy of tablespace
BACKUP AS COPY TABLESPACE users;

-- List image copies
LIST COPY OF DATABASE;
LIST COPY OF DATAFILE 3;
LIST COPY OF TABLESPACE users;

-- Switch to image copy (for recovery)
SWITCH DATAFILE 3 TO COPY;

-- Validate image copy
VALIDATE COPY OF DATAFILE 3;
```

## 4. RMAN Recovery Procedures

### 4.1 Complete Database Restore and PITR

#### Pre-Recovery Verification
```sql
-- Verify backup availability
SELECT backup_type, completion_time, 
       ROUND(bytes/1024/1024,2) as size_mb, status
FROM v$backup_set 
WHERE backup_type = 'D'
ORDER BY completion_time DESC;

-- Check archive log availability
SELECT sequence#, name, completion_time, applied
FROM v$archived_log 
WHERE completion_time > SYSDATE - 7
ORDER BY sequence#;

-- Current SCN and time information
SELECT current_scn, to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') as current_time
FROM v$database;
```

#### Complete Database Restore
```sql
-- Shutdown database
SHUTDOWN IMMEDIATE;

-- Startup in MOUNT mode
STARTUP MOUNT;

-- Restore and recover database (in RMAN)
RESTORE DATABASE;
RECOVER DATABASE;

-- Open database
ALTER DATABASE OPEN;
```

#### Point-in-Time Recovery (PITR)
```sql
-- PITR to specific time
RUN {
    SET UNTIL TIME "TO_DATE('2025-07-04 10:00:00', 'YYYY-MM-DD HH24:MI:SS')";
    RESTORE DATABASE;
    RECOVER DATABASE;
}
ALTER DATABASE OPEN RESETLOGS;

-- PITR to specific SCN
RUN {
    SET UNTIL SCN 1234567;
    RESTORE DATABASE;
    RECOVER DATABASE;
}
ALTER DATABASE OPEN RESETLOGS;

-- PITR to specific sequence
RUN {
    SET UNTIL SEQUENCE 123;
    RESTORE DATABASE;
    RECOVER DATABASE;
}
ALTER DATABASE OPEN RESETLOGS;
```

#### Cancel-Based Recovery
```sql
-- Cancel-based recovery
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
RECOVER DATABASE UNTIL CANCEL;
-- When prompted, type CANCEL to stop recovery
ALTER DATABASE OPEN RESETLOGS;
```

### 4.2 Tablespace and Datafile Recovery

#### Identify Damaged Components
```sql
-- Check tablespace/datafile status
SELECT ts.tablespace_name, df.file_name, df.status, df.enabled
FROM dba_tablespaces ts
JOIN dba_data_files df ON ts.tablespace_name = df.tablespace_name
WHERE ts.status != 'ONLINE' OR df.status != 'AVAILABLE';

-- Check for datafiles needing recovery
SELECT file#, name, status, error, recover, fuzzy
FROM v$datafile_header
WHERE recover = 'YES' OR fuzzy = 'YES';
```

#### Tablespace Recovery
```sql
-- Take tablespace offline
ALTER TABLESPACE users OFFLINE IMMEDIATE;

-- In RMAN: Restore and recover tablespace
RESTORE TABLESPACE users;
RECOVER TABLESPACE users;

-- Bring tablespace online
ALTER TABLESPACE users ONLINE;

-- Verify recovery
SELECT tablespace_name, status, contents, logging
FROM dba_tablespaces 
WHERE tablespace_name = 'USERS';
```

#### Datafile Recovery
```sql
-- Take datafile offline
ALTER DATABASE DATAFILE 3 OFFLINE;

-- In RMAN: Restore and recover datafile
RESTORE DATAFILE 3;
RECOVER DATAFILE 3;

-- Bring datafile online
ALTER DATABASE DATAFILE 3 ONLINE;

-- Verify datafile status
SELECT file_name, tablespace_name, status, enabled
FROM dba_data_files 
WHERE file_id = 3;
```

### 4.3 Control File Recovery

#### All Control Files Lost
```sql
-- Shutdown database
SHUTDOWN ABORT;

-- Startup NOMOUNT
STARTUP NOMOUNT;

-- In RMAN: Restore control file from autobackup
RESTORE CONTROLFILE FROM AUTOBACKUP;

-- Or restore from specific backup piece
RESTORE CONTROLFILE FROM '${BACKUP_BASE}/controlfile/c-123456789-20250705-00';

-- Mount database
ALTER DATABASE MOUNT;

-- Restore and recover database
RESTORE DATABASE;
RECOVER DATABASE;

-- Open with RESETLOGS
ALTER DATABASE OPEN RESETLOGS;
```

#### Some Control Files Lost
```bash
# Copy existing control file to missing location
cp /u01/app/oracle/oradata/PRODDB/control02.ctl /u01/app/oracle/oradata/PRODDB/control01.ctl
```

### 4.4 Block-Level Recovery

```sql
-- Identify corrupted blocks
SELECT file#, block#, blocks, corruption_change#, corruption_type
FROM v$database_block_corruption;

-- Check for logical corruption
SELECT owner, segment_name, segment_type, tablespace_name,
       file_id, block_id, blocks
FROM dba_segments
WHERE segment_name IN (
    SELECT segment_name 
    FROM dba_segments s
    WHERE EXISTS (
        SELECT 1 FROM v$database_block_corruption c
        WHERE s.header_file = c.file# 
        AND s.header_block BETWEEN c.block# AND c.block# + c.blocks - 1
    )
);

-- In RMAN: Recover corrupted blocks
RECOVER DATAFILE 3 BLOCK 12345;

-- Recover multiple blocks
RECOVER DATAFILE 3 BLOCK 12345, 12346;

-- Recover all blocks in corruption list
RECOVER CORRUPTION LIST;

-- Validate after recovery
ANALYZE TABLE schema.table_name VALIDATE STRUCTURE CASCADE;
```

### 4.5 Archive Log Recovery

```sql
-- Check archive log status
SELECT sequence#, name, dest_id, status, archived,
       applied, deleted, completion_time
FROM v$archived_log 
WHERE completion_time > SYSDATE - 7
ORDER BY sequence#;

-- Check for gaps in archive logs
SELECT thread#, low_sequence#, high_sequence#
FROM v$archive_gap;

-- In RMAN: Restore archive logs
RESTORE ARCHIVELOG ALL;

-- Restore specific sequence range
RESTORE ARCHIVELOG FROM SEQUENCE 100 UNTIL SEQUENCE 150;

-- Restore from specific time
RESTORE ARCHIVELOG FROM TIME 'SYSDATE-2' UNTIL TIME 'SYSDATE-1';

-- Restore to different location
SET ARCHIVELOG DESTINATION TO '${BACKUP_BASE}/restored_arch';
RESTORE ARCHIVELOG FROM SEQUENCE 123 TO SEQUENCE 125;
```

### 4.6 Disaster Recovery Procedures

#### System Damage Assessment
```sql
-- Check component status
SELECT 'Database Files' as component,
       COUNT(*) as total_files,
       SUM(CASE WHEN status = 'AVAILABLE' THEN 1 ELSE 0 END) as available,
       SUM(CASE WHEN status != 'AVAILABLE' THEN 1 ELSE 0 END) as damaged
FROM v$datafile
UNION ALL
SELECT 'Control Files' as component,
       COUNT(*) as total_files,
       SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) as available,
       SUM(CASE WHEN status IS NOT NULL THEN 1 ELSE 0 END) as damaged
FROM v$controlfile;
```

#### Complete System Recovery Steps
```sql
-- 1. Restore Oracle software (if needed)
-- 2. Restore parameter files
-- 3. Restore control files
-- 4. Restore database files
-- 5. Restore archive logs
-- 6. Perform recovery
-- 7. Open database

-- RMAN Complete Recovery Script
STARTUP NOMOUNT;
RESTORE SPFILE FROM AUTOBACKUP;
SHUTDOWN IMMEDIATE;
STARTUP NOMOUNT;
RESTORE CONTROLFILE FROM AUTOBACKUP;
ALTER DATABASE MOUNT;
RESTORE DATABASE;
RECOVER DATABASE;
ALTER DATABASE OPEN RESETLOGS;

-- Post-recovery validation
SELECT name, open_mode, database_role, protection_mode, protection_level
FROM v$database;

-- Check datafile status
SELECT file#, name, status, enabled, checkpoint_change#, checkpoint_time
FROM v$datafile;

-- Check invalid objects
SELECT owner, object_type, COUNT(*) as invalid_count
FROM dba_objects 
WHERE status = 'INVALID'
GROUP BY owner, object_type
ORDER BY owner, object_type;
```

## 5. Data Pump Operations

### 5.1 Data Pump Exports

#### Full Database Export
```bash
expdp system/password@ORCL \
  DUMPFILE=full_db.dmp \
  LOGFILE=full_db.log \
  FULL=Y \
  DIRECTORY=DATA_PUMP_DIR
```

#### Schema Level Export
```bash
expdp system/password@ORCL \
  DUMPFILE=hr_schema.dmp \
  LOGFILE=hr_schema.log \
  SCHEMAS=HR \
  DIRECTORY=DATA_PUMP_DIR
```

#### Table Level Export
```bash
expdp system/password@ORCL \
  DUMPFILE=emp_dept.dmp \
  LOGFILE=emp_dept.log \
  TABLES=HR.EMPLOYEES,HR.DEPARTMENTS \
  DIRECTORY=DATA_PUMP_DIR
```

#### Using Parameter File
Create `export.par`:
```
DUMPFILE=full_db_%U.dmp
LOGFILE=full_db.log
FULL=Y
DIRECTORY=DATA_PUMP_DIR
PARALLEL=4
COMPRESSION=ALL
```

Execute:
```bash
expdp system/password@ORCL PARFILE=export.par
```

### 5.2 Data Pump Imports

#### Full Database Import
```bash
impdp system/password@ORCL \
  DUMPFILE=full_db.dmp \
  LOGFILE=full_db_imp.log \
  FULL=Y \
  DIRECTORY=DATA_PUMP_DIR
```

#### Schema Level Import with Remapping
```bash
impdp system/password@ORCL \
  DUMPFILE=hr_schema.dmp \
  LOGFILE=hr_schema_imp.log \
  SCHEMAS=HR \
  REMAP_SCHEMA=HR:NEW_HR \
  DIRECTORY=DATA_PUMP_DIR
```

#### Table Level Import with Options
```bash
impdp system/password@ORCL \
  DUMPFILE=emp_dept.dmp \
  LOGFILE=emp_dept_imp.log \
  TABLES=HR.EMPLOYEES,HR.DEPARTMENTS \
  TABLE_EXISTS_ACTION=REPLACE \
  DIRECTORY=DATA_PUMP_DIR
```

#### Import with Transformations
```bash
impdp system/password@ORCL \
  DUMPFILE=full_db.dmp \
  LOGFILE=full_db_imp.log \
  FULL=Y \
  TRANSFORM=OID:N \
  TRANSFORM=SEGMENT_ATTRIBUTES:N \
  DIRECTORY=DATA_PUMP_DIR
```

### 5.3 Traditional Export/Import

#### Traditional Export
```bash
# Full database export
exp system/password@ORCL FULL=Y FILE=full_db_trad.dmp LOG=full_db_trad.log

# Schema level export
exp system/password@ORCL OWNER=HR FILE=hr_schema_trad.dmp LOG=hr_schema_trad.log

# Table level export
exp system/password@ORCL TABLES=(HR.EMPLOYEES,HR.DEPARTMENTS) FILE=tables.dmp LOG=tables.log
```

#### Traditional Import
```bash
# Full database import
imp system/password@ORCL FULL=Y FILE=full_db_trad.dmp LOG=full_db_trad_imp.log

# Schema level import with remapping
imp system/password@ORCL FILE=hr_schema.dmp FROMUSER=HR TOUSER=NEW_HR IGNORE=Y

# Selective table import
imp system/password@ORCL FILE=full_db.dmp TABLES=(HR.EMPLOYEES,HR.DEPARTMENTS) IGNORE=Y
```

### 5.4 Monitoring Data Pump Operations

#### Attach to Running Job
```bash
expdp system/password@ORCL ATTACH=SYS_EXPORT_FULL_01
```

At the prompt, use commands:
- `STATUS` - Show job status
- `STOP_JOB=IMMEDIATE` - Stop the job
- `CONTINUE_CLIENT` - Continue a stopped job

#### Monitor from Database
```sql
-- Check Data Pump jobs
SELECT owner, job_name, operation, job_mode, state, attached_sessions
FROM dba_datapump_jobs;

-- Detailed job information
SELECT * FROM dba_datapump_sessions;

-- Monitor long operations
SELECT SID, SERIAL#, OPNAME, SOFAR, TOTALWORK,
       ROUND(SOFAR/TOTALWORK*100,2) "% COMPLETE"
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'Data Pump%';
```

## 6. Special Recovery Scenarios

### 6.1 Flashback Database Operations

#### Enable Flashback Database
```sql
-- Check and enable flashback
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE FLASHBACK ON;
ALTER DATABASE OPEN;

-- Verify flashback status
SELECT flashback_on FROM v$database;

-- Configure flashback retention
ALTER SYSTEM SET db_flashback_retention_target=1440; -- 24 hours in minutes
```

#### Perform Flashback Database
```sql
-- Flashback to specific time
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
FLASHBACK DATABASE TO TIME "TO_DATE('2025-07-04 09:30:00', 'YYYY-MM-DD HH24:MI:SS')";
ALTER DATABASE OPEN RESETLOGS;

-- Flashback to specific SCN
FLASHBACK DATABASE TO SCN 1234567;

-- Flashback to restore point
CREATE RESTORE POINT before_upgrade GUARANTEE FLASHBACK DATABASE;
-- Later...
FLASHBACK DATABASE TO RESTORE POINT before_upgrade;
```

### 6.2 Standby Database Recovery

#### Start Managed Recovery
```sql
-- On standby database
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;

-- Real-time apply (if using Active Data Guard)
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;

-- Stop managed recovery
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
```

#### Recover Standby After Gap
```sql
-- In RMAN on standby
RECOVER STANDBY DATABASE;

-- Manually register archive logs if needed
ALTER DATABASE REGISTER LOGFILE '${BACKUP_BASE}/archivelog/arch_123.arc';
```

### 6.3 Media Failure Recovery

#### Disk Failure Recovery Steps
1. Identify failed disk/datafiles
2. Replace failed hardware
3. Restore datafiles from backup
4. Recover datafiles
5. Bring datafiles online

```sql
-- Identify damaged files
SELECT file#, name, status FROM v$datafile WHERE status != 'ONLINE';

-- Take damaged files offline
ALTER DATABASE DATAFILE 5 OFFLINE;

-- In RMAN: Restore and recover
RESTORE DATAFILE 5;
RECOVER DATAFILE 5;

-- Bring back online
ALTER DATABASE DATAFILE 5 ONLINE;
```

## 7. Monitoring and Validation

### 7.1 Backup Validation and Crosscheck

#### Validate Backups
```sql
-- Validate database
VALIDATE DATABASE;

-- Validate specific backup set
VALIDATE BACKUPSET 123;

-- Validate datafile
VALIDATE DATAFILE 3;

-- Validate without actually restoring
RESTORE DATABASE VALIDATE;
RESTORE TABLESPACE users VALIDATE;
```

#### Crosscheck Operations
```sql
-- Crosscheck all backups
CROSSCHECK BACKUP;
CROSSCHECK COPY;
CROSSCHECK ARCHIVELOG ALL;

-- Delete expired items
DELETE EXPIRED BACKUP;
DELETE EXPIRED COPY;
DELETE EXPIRED ARCHIVELOG ALL;

-- Delete obsolete backups
DELETE OBSOLETE;
DELETE NOPROMPT OBSOLETE;
```

### 7.2 Performance Monitoring

#### Monitor Backup Performance
```sql
-- Current RMAN operations
SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK,
       ROUND(SOFAR/TOTALWORK*100,2) "% COMPLETE"
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'RMAN%';

-- RMAN job history
SELECT session_key, session_recid, status,
       to_char(start_time, 'DD-MON-YYYY HH24:MI:SS') start_time,
       to_char(end_time, 'DD-MON-YYYY HH24:MI:SS') end_time,
       elapsed_seconds, input_bytes, output_bytes
FROM v$rman_backup_job_details
WHERE start_time > sysdate - 7
ORDER BY start_time DESC;

-- Channel performance
SELECT channel, sid, serial#, device_type, status
FROM v$rman_backup_job_details
WHERE status = 'RUNNING';
```

#### Monitor Recovery Performance
```sql
-- Recovery progress
SELECT file#, checkpoint_change#, 
       to_char(checkpoint_time, 'DD-MON-YYYY HH24:MI:SS') checkpoint_time
FROM v$datafile_header;

-- Archive log application status
SELECT sequence#, applied, to_char(completion_time, 'DD-MON-YYYY HH24:MI:SS') applied_time
FROM v$archived_log
WHERE applied = 'YES'
ORDER BY sequence# DESC;
```

### 7.3 Troubleshooting

#### Common RMAN Issues and Solutions

**Issue: ORA-19502: write error on file**
```sql
-- Check disk space
!df -h ${BACKUP_BASE}

-- Check permissions
!ls -la ${BACKUP_BASE}

-- Adjust backup piece size
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 2G;
```

**Issue: ORA-19809: limit exceeded for recovery files**
```sql
-- Check FRA usage
SELECT * FROM v$recovery_file_dest;
SELECT * FROM v$recovery_area_usage;

-- Increase FRA size
ALTER SYSTEM SET db_recovery_file_dest_size=100G;

-- Delete obsolete files
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUP;
```

**Issue: RMAN-06023: no backup or copy of datafile found**
```sql
-- List available backups
LIST BACKUP OF DATAFILE 3;

-- Crosscheck and update repository
CROSSCHECK BACKUP;

-- Catalog any missing backups
CATALOG START WITH '${BACKUP_BASE}';
```

## 8. Automation Scripts

### 8.1 Linux/Unix Shell Scripts

#### Comprehensive RMAN Backup Script
```bash
#!/bin/bash
# RMAN Backup Script with Full Features
# File: rman_backup_advanced.sh

# Configuration
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
ORACLE_SID=PRODDB
BACKUP_BASE=/backup/rman
BACKUP_TYPE=${1:-FULL}  # FULL, LEVEL0, LEVEL1, ARCHIVELOG
COMPRESSION=MEDIUM
ENCRYPTION=YES
ENCRYPTION_PASSWORD="SecurePassword123"
PARALLEL_DEGREE=4
RETENTION_DAYS=7
EMAIL_TO="dba@company.com"

# Environment setup
export ORACLE_HOME ORACLE_SID
export PATH=$ORACLE_HOME/bin:$PATH

# Create log directory
LOG_DIR=${BACKUP_BASE}/logs
mkdir -p ${LOG_DIR}
LOG_FILE=${LOG_DIR}/rman_backup_$(date +%Y%m%d_%H%M%S).log

# Functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ${LOG_FILE}
}

send_notification() {
    local status=$1
    local subject="RMAN Backup ${status} - ${ORACLE_SID} - $(date)"
    local message="RMAN backup completed with status: ${status}\nLog file: ${LOG_FILE}"
    
    echo -e "${message}" | mail -s "${subject}" ${EMAIL_TO}
}

check_prerequisites() {
    log_message "Checking prerequisites..."
    
    # Check if database is up
    sqlplus -s / as sysdba << EOF > /tmp/db_check.log 2>&1
    SET PAGESIZE 0 FEEDBACK OFF
    SELECT 'DB_STATUS:' || status FROM v\$instance;
    EXIT;
EOF
    
    if [ $? -ne 0 ]; then
        log_message "ERROR: Cannot connect to database"
        exit 1
    fi
    
    DB_STATUS=$(grep "DB_STATUS:" /tmp/db_check.log | cut -d: -f2)
    if [ "${DB_STATUS}" != "OPEN" ]; then
        log_message "ERROR: Database is not open. Status: ${DB_STATUS}"
        exit 1
    fi
    
    # Check disk space
    SPACE_AVAILABLE=$(df -P ${BACKUP_BASE} | tail -1 | awk '{print $4}')
    if [ ${SPACE_AVAILABLE} -lt 10485760 ]; then  # Less than 10GB
        log_message "WARNING: Low disk space in ${BACKUP_BASE}"
    fi
    
    rm -f /tmp/db_check.log
}

perform_backup() {
    log_message "Starting ${BACKUP_TYPE} backup..."
    
    case ${BACKUP_TYPE} in
        FULL)
            rman target / << EOF >> ${LOG_FILE} 2>&1
RUN {
    ALLOCATE CHANNEL c1 TYPE DISK;
    ALLOCATE CHANNEL c2 TYPE DISK;
    ALLOCATE CHANNEL c3 TYPE DISK;
    ALLOCATE CHANNEL c4 TYPE DISK;
    
    SET ENCRYPTION IDENTIFIED BY "${ENCRYPTION_PASSWORD}";
    
    BACKUP AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'FULL_BACKUP_$(date +%Y%m%d_%H%M%S)'
    MAXPIECESIZE 2G;
    
    DELETE NOPROMPT OBSOLETE;
    
    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
    RELEASE CHANNEL c3;
    RELEASE CHANNEL c4;
}
EXIT;
EOF
            ;;
        LEVEL0)
            rman target / << EOF >> ${LOG_FILE} 2>&1
RUN {
    SET ENCRYPTION IDENTIFIED BY "${ENCRYPTION_PASSWORD}";
    
    BACKUP INCREMENTAL LEVEL 0
    AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'LEVEL0_$(date +%Y%m%d_%H%M%S)';
    
    DELETE NOPROMPT OBSOLETE;
}
EXIT;
EOF
            ;;
        LEVEL1)
            rman target / << EOF >> ${LOG_FILE} 2>&1
RUN {
    SET ENCRYPTION IDENTIFIED BY "${ENCRYPTION_PASSWORD}";
    
    BACKUP INCREMENTAL LEVEL 1
    AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG 'LEVEL1_$(date +%Y%m%d_%H%M%S)';
    
    DELETE NOPROMPT ARCHIVELOG UNTIL TIME 'SYSDATE-2';
}
EXIT;
EOF
            ;;
        ARCHIVELOG)
            rman target / << EOF >> ${LOG_FILE} 2>&1
RUN {
    BACKUP AS COMPRESSED BACKUPSET 
    USING '${COMPRESSION}'
    ARCHIVELOG ALL 
    DELETE INPUT
    TAG 'ARCHLOG_$(date +%Y%m%d_%H%M%S)';
    
    DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
}
EXIT;
EOF
            ;;
    esac
    
    return $?
}

validate_backup() {
    log_message "Validating backup..."
    
    rman target / << EOF >> ${LOG_FILE} 2>&1
VALIDATE DATABASE;
LIST BACKUP SUMMARY;
REPORT NEED BACKUP;
EXIT;
EOF
}

cleanup_old_logs() {
    log_message "Cleaning up old log files..."
    find ${LOG_DIR} -name "*.log" -mtime +${RETENTION_DAYS} -delete
}

# Main execution
log_message "=== RMAN Backup Script Started ==="
log_message "Database: ${ORACLE_SID}"
log_message "Backup Type: ${BACKUP_TYPE}"
log_message "Backup Location: ${BACKUP_BASE}"

check_prerequisites
perform_backup
BACKUP_STATUS=$?

if [ ${BACKUP_STATUS} -eq 0 ]; then
    log_message "Backup completed successfully"
    validate_backup
    cleanup_old_logs
    send_notification "SUCCESS"
else
    log_message "ERROR: Backup failed with exit code ${BACKUP_STATUS}"
    send_notification "FAILED"
    exit ${BACKUP_STATUS}
fi

log_message "=== RMAN Backup Script Completed ==="
```

#### RMAN Configuration Setup Script
```bash
#!/bin/bash
# RMAN Configuration Setup Script
# File: rman_config_setup.sh

# Set default values
ORACLE_SID=${1:-PRODDB}
BACKUP_BASE=${2:-/backup/rman}
FRA_BASE=${3:-/u01/app/oracle/fast_recovery_area}
ORACLE_HOME=${ORACLE_HOME:-/u01/app/oracle/product/19.0.0/dbhome_1}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
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

# Check Oracle environment
check_oracle_env() {
    print_section "Checking Oracle Environment"
    
    if [ -z "$ORACLE_HOME" ]; then
        print_error "ORACLE_HOME is not set"
        exit 1
    fi
    
    export PATH=$ORACLE_HOME/bin:$PATH
    export ORACLE_SID=$ORACLE_SID
    
    print_status "Oracle Environment configured:"
    print_status "ORACLE_HOME: $ORACLE_HOME"
    print_status "ORACLE_SID: $ORACLE_SID"
}

# Create directories
create_directories() {
    print_section "Creating Directory Structure"
    
    mkdir -p ${BACKUP_BASE}/{datafile,archivelog,controlfile,logs}
    mkdir -p ${FRA_BASE}
    
    chmod 755 ${BACKUP_BASE} ${FRA_BASE}
    
    if [ $(id -u) -eq 0 ]; then
        chown oracle:oinstall ${BACKUP_BASE} ${FRA_BASE} 2>/dev/null
    fi
    
    print_status "Directories created successfully"
}

# Configure RMAN
configure_rman() {
    print_section "Configuring RMAN Settings"
    
    rman target / << EOF
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BACKUP_BASE}/controlfile/cf_%F';
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
CONFIGURE DEVICE TYPE DISK PARALLELISM 4;
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 2G;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/%U';
CONFIGURE ARCHIVELOG DELETION POLICY TO BACKED UP 1 TIMES TO DISK;
SHOW ALL;
EXIT;
EOF
    
    if [ $? -eq 0 ]; then
        print_status "RMAN configuration completed successfully"
    else
        print_error "RMAN configuration failed"
        exit 1
    fi
}

# Configure FRA
configure_fra() {
    print_section "Configuring Fast Recovery Area"
    
    sqlplus -s / as sysdba << EOF
ALTER SYSTEM SET db_recovery_file_dest_size=50G;
ALTER SYSTEM SET db_recovery_file_dest='${FRA_BASE}';
SHOW PARAMETER db_recovery_file_dest;
EXIT;
EOF
    
    if [ $? -eq 0 ]; then
        print_status "FRA configured successfully"
    else
        print_error "FRA configuration failed"
    fi
}

# Create backup scripts
create_scripts() {
    print_section "Creating Operational Scripts"
    
    # Create daily backup script
    cat > ${BACKUP_BASE}/daily_backup.sh << 'EOF'
#!/bin/bash
ORACLE_HOME=__ORACLE_HOME__
ORACLE_SID=__ORACLE_SID__
BACKUP_BASE=__BACKUP_BASE__
export PATH=$ORACLE_HOME/bin:$PATH

LOG_FILE=${BACKUP_BASE}/logs/daily_backup_$(date +%Y%m%d_%H%M%S).log

rman target / << EOL >> $LOG_FILE 2>&1
RUN {
    BACKUP DATABASE PLUS ARCHIVELOG;
    DELETE NOPROMPT OBSOLETE;
}
EXIT;
EOL
EOF
    
    # Replace placeholders
    sed -i "s|__ORACLE_HOME__|${ORACLE_HOME}|g" ${BACKUP_BASE}/daily_backup.sh
    sed -i "s|__ORACLE_SID__|${ORACLE_SID}|g" ${BACKUP_BASE}/daily_backup.sh
    sed -i "s|__BACKUP_BASE__|${BACKUP_BASE}|g" ${BACKUP_BASE}/daily_backup.sh
    
    chmod +x ${BACKUP_BASE}/daily_backup.sh
    
    print_status "Backup scripts created"
}

# Main execution
print_section "RMAN Configuration Setup"
check_oracle_env
create_directories
configure_rman
configure_fra
create_scripts

print_section "Setup Completed Successfully"
print_status "Daily backup script: ${BACKUP_BASE}/daily_backup.sh"
print_status "Add to crontab: 0 2 * * * ${BACKUP_BASE}/daily_backup.sh"
```

### 8.2 Windows PowerShell Scripts

#### RMAN Backup PowerShell Script
```powershell
# RMAN Backup Script for Windows
# File: RMAN_Backup.ps1

param(
    [string]$OracleSid = "PRODDB",
    [string]$BackupType = "FULL",
    [string]$BackupBase = "D:\backup\rman",
    [string]$OracleHome = $env:ORACLE_HOME
)

# Configuration
$Compression = "MEDIUM"
$Encryption = $true
$EncryptionPassword = "SecurePassword123"
$ParallelDegree = 4

# Functions
function Write-Status {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Green
    Add-Content -Path $LogFile -Value "[$timestamp] $Message"
}

function Write-Error {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor Red
    Add-Content -Path $LogFile -Value "[$timestamp] ERROR: $Message"
}

# Setup environment
$env:ORACLE_SID = $OracleSid
$env:ORACLE_HOME = $OracleHome
$env:PATH = "$OracleHome\bin;$env:PATH"

# Create log directory
$LogDir = "$BackupBase\logs"
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

$LogFile = "$LogDir\rman_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Write-Status "Starting RMAN backup"
Write-Status "Database: $OracleSid"
Write-Status "Backup Type: $BackupType"

# Create RMAN script
$rmanScript = @"
RUN {
    ALLOCATE CHANNEL c1 TYPE DISK;
    ALLOCATE CHANNEL c2 TYPE DISK;
    ALLOCATE CHANNEL c3 TYPE DISK;
    ALLOCATE CHANNEL c4 TYPE DISK;
    
    SET ENCRYPTION IDENTIFIED BY "$EncryptionPassword";
    
    BACKUP AS COMPRESSED BACKUPSET 
    USING '$Compression'
    DATABASE 
    PLUS ARCHIVELOG 
    TAG '${BackupType}_BACKUP_$(Get-Date -Format 'yyyyMMdd_HHmmss')'
    MAXPIECESIZE 2G;
    
    DELETE NOPROMPT OBSOLETE;
    
    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
    RELEASE CHANNEL c3;
    RELEASE CHANNEL c4;
}
EXIT;
"@

# Execute RMAN backup
$rmanScript | rman target / >> $LogFile 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Status "Backup completed successfully"
} else {
    Write-Error "Backup failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Validate backup
$validateScript = @"
VALIDATE DATABASE;
LIST BACKUP SUMMARY;
EXIT;
"@

$validateScript | rman target / >> $LogFile 2>&1

Write-Status "RMAN backup script completed"
```

#### RMAN Configuration PowerShell Script
```powershell
# RMAN Configuration Setup for Windows
# File: Setup_RMAN_Config.ps1

param(
    [string]$OracleSid = "PRODDB",
    [string]$BackupBase = "D:\backup\rman",
    [string]$FraBase = "D:\fra",
    [string]$OracleHome = $env:ORACLE_HOME
)

# Functions
function Write-Section {
    param([string]$Title)
    Write-Host "`n==== $Title ====" -ForegroundColor Blue
}

function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Setup environment
Write-Section "Setting up Oracle Environment"
$env:ORACLE_SID = $OracleSid
$env:ORACLE_HOME = $OracleHome
$env:PATH = "$OracleHome\bin;$env:PATH"

Write-Status "ORACLE_HOME: $OracleHome"
Write-Status "ORACLE_SID: $OracleSid"

# Create directories
Write-Section "Creating Directory Structure"
$directories = @(
    "$BackupBase\datafile",
    "$BackupBase\archivelog", 
    "$BackupBase\controlfile",
    "$BackupBase\logs",
    $FraBase
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Status "Created directory: $dir"
    }
}

# Configure RMAN
Write-Section "Configuring RMAN"

$rmanConfig = @"
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

$rmanConfig | rman target /

if ($LASTEXITCODE -eq 0) {
    Write-Status "RMAN configuration completed successfully"
} else {
    Write-Error "RMAN configuration failed"
    exit $LASTEXITCODE
}

# Configure FRA
Write-Section "Configuring Fast Recovery Area"

$sqlScript = @"
ALTER SYSTEM SET db_recovery_file_dest_size=50G;
ALTER SYSTEM SET db_recovery_file_dest='$FraBase';
EXIT;
"@

$sqlScript | sqlplus "/ as sysdba"

# Create backup batch file
Write-Section "Creating Backup Script"

$batchScript = @"
@echo off
set ORACLE_HOME=$OracleHome
set ORACLE_SID=$OracleSid
set PATH=%ORACLE_HOME%\bin;%PATH%

echo Starting RMAN backup at %date% %time%

rman target / ^<^< EOF
RUN {
    BACKUP DATABASE PLUS ARCHIVELOG;
    DELETE NOPROMPT OBSOLETE;
}
EXIT;
EOF

echo RMAN backup completed at %date% %time%
"@

$batchScript | Out-File -FilePath "$BackupBase\daily_backup.bat" -Encoding ASCII

Write-Status "Configuration completed successfully!"
Write-Status "Daily backup script: $BackupBase\daily_backup.bat"
```

### 8.3 Scheduling with DBMS_SCHEDULER

#### Create RMAN Backup Job
```sql
-- Create program for RMAN backup
BEGIN
  DBMS_SCHEDULER.CREATE_PROGRAM(
    program_name        => 'RMAN_BACKUP_PROGRAM',
    program_type        => 'EXECUTABLE',
    program_action      => '/backup/rman/daily_backup.sh',
    enabled             => TRUE,
    comments            => 'Daily RMAN backup program'
  );
END;
/

-- Create schedule
BEGIN
  DBMS_SCHEDULER.CREATE_SCHEDULE(
    schedule_name       => 'DAILY_2AM_SCHEDULE',
    start_date          => SYSTIMESTAMP,
    repeat_interval     => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=0',
    comments            => 'Daily at 2 AM'
  );
END;
/

-- Create job
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name            => 'DAILY_RMAN_BACKUP',
    program_name        => 'RMAN_BACKUP_PROGRAM',
    schedule_name       => 'DAILY_2AM_SCHEDULE',
    enabled             => TRUE,
    auto_drop           => FALSE,
    comments            => 'Daily RMAN backup job'
  );
END;
/

-- Monitor job execution
SELECT job_name, state, last_start_date, next_run_date
FROM dba_scheduler_jobs
WHERE job_name = 'DAILY_RMAN_BACKUP';

-- View job run details
SELECT job_name, status, actual_start_date, run_duration
FROM dba_scheduler_job_run_details
WHERE job_name = 'DAILY_RMAN_BACKUP'
ORDER BY actual_start_date DESC;
```

## 9. Performance Optimization

### 9.1 Parallel Processing

#### Configure Optimal Parallelism
```sql
-- Determine optimal parallelism based on CPU
SELECT value FROM v$parameter WHERE name = 'cpu_count';

-- Configure RMAN parallelism (typically CPU count / 2)
CONFIGURE DEVICE TYPE DISK PARALLELISM 8;

-- For large databases, use section size
BACKUP DATABASE SECTION SIZE 10G;

-- Allocate multiple channels with specific settings
RUN {
  ALLOCATE CHANNEL c1 TYPE DISK RATE 200M;
  ALLOCATE CHANNEL c2 TYPE DISK RATE 200M;
  ALLOCATE CHANNEL c3 TYPE DISK RATE 200M;
  ALLOCATE CHANNEL c4 TYPE DISK RATE 200M;
  BACKUP DATABASE;
}
```

### 9.2 Compression Strategies

#### Compression Comparison
| Compression Level | Space Savings | CPU Usage | Speed |
|------------------|---------------|-----------|--------|
| BASIC | 50-60% | Low | Fast |
| LOW | 55-65% | Medium | Medium |
| MEDIUM | 60-70% | Medium | Medium |
| HIGH | 70-80% | High | Slow |

#### Choose Compression Based on Resources
```sql
-- For fast backups with moderate compression
CONFIGURE COMPRESSION ALGORITHM 'BASIC';

-- For balanced performance
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';

-- For maximum space savings (overnight backups)
CONFIGURE COMPRESSION ALGORITHM 'HIGH';

-- Test compression effectiveness
BACKUP VALIDATE DATABASE;
SELECT * FROM v$backup_datafile WHERE completion_time > SYSDATE - 1;
```

### 9.3 Storage Optimization

#### Enable Block Change Tracking
```sql
-- Enable BCT for faster incremental backups
ALTER DATABASE ENABLE BLOCK CHANGE TRACKING USING FILE '${ORACLE_BASE}/oradata/PRODDB/bct_file.bct';

-- Verify BCT status
SELECT * FROM v$block_change_tracking;

-- Monitor BCT effectiveness
SELECT file#, incremental_level, blocks_read, blocks, 
       ROUND(blocks_read/blocks*100,2) pct_read
FROM v$backup_datafile
WHERE incremental_level > 0
ORDER BY completion_time DESC;
```

#### Optimize Backup Piece Size
```sql
-- Configure appropriate piece size
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 4G;

-- Use multiple backup sets for large databases
CONFIGURE MAXSETSIZE TO 10G;

-- Limit backup duration for maintenance windows
BACKUP DATABASE DURATION 4:00 MINIMIZE LOAD;
```

## 10. Best Practices and Guidelines

### 10.1 Backup Best Practices

1. **Test Backups Regularly**
   - Perform monthly restore tests
   - Document restore procedures
   - Validate backup integrity weekly

2. **Implement 3-2-1 Rule**
   - 3 copies of data
   - 2 different storage media
   - 1 offsite copy

3. **Configure Appropriate Retention**
   - Production: 30+ days recovery window
   - Development: 7 days recovery window
   - Archive logs: Based on recovery requirements

4. **Enable Critical Features**
   - Control file autobackup
   - Archive log mode
   - Block change tracking
   - Flashback database (if possible)

5. **Monitor and Alert**
   - Set up email notifications
   - Monitor backup job status
   - Check space utilization
   - Review backup performance

### 10.2 Recovery Best Practices

1. **Document Recovery Procedures**
   - Create step-by-step guides
   - Include contact information
   - Test procedures quarterly

2. **Prioritize Recovery Scenarios**
   - Complete database failure
   - Datafile/tablespace corruption
   - User error recovery
   - Point-in-time recovery

3. **Maintain Recovery Resources**
   - Keep RMAN scripts updated
   - Verify backup locations
   - Test network connectivity
   - Ensure adequate space

4. **Calculate and Document RTO/RPO**
   - RTO: Recovery Time Objective
   - RPO: Recovery Point Objective
   - Test actual recovery times
   - Adjust backup strategy accordingly

### 10.3 Testing and Documentation

#### Disaster Recovery Testing Checklist
- [ ] Verify all backup files are accessible
- [ ] Test control file restoration
- [ ] Perform complete database restore
- [ ] Validate data integrity after restore
- [ ] Document actual recovery time
- [ ] Update recovery procedures
- [ ] Train backup DBAs

#### Documentation Requirements
1. **Backup Configuration**
   - RMAN settings
   - Backup schedules
   - Retention policies
   - Storage locations

2. **Recovery Procedures**
   - Step-by-step instructions
   - Emergency contacts
   - Escalation procedures
   - Decision trees

3. **Testing Results**
   - Test dates and results
   - Issues encountered
   - Improvements made
   - Lessons learned

## Storage Space Calculations

### Compression Ratios
- **BASIC Compression**: 50-60% space reduction
- **MEDIUM Compression**: 60-70% space reduction  
- **HIGH Compression**: 70-80% space reduction

### Space Planning Formula
```
Full Backup Size = Database Size × (1 - Compression Ratio)
Level 0 Size = Full Backup Size
Level 1 Size = Changed Data × (1 - Compression Ratio)
Archive Log Size = Daily Archive Generation × Retention Days
Total Space Required = (Full Backup Size × Redundancy) + (Level 1 Size × Days) + Archive Log Size + 20% Buffer
```

### Example Calculation
```
Database Size: 1TB
Compression: MEDIUM (65% reduction)
Daily Change Rate: 5%
Archive Generation: 50GB/day
Retention: 7 days

Full Backup Size = 1TB × 0.35 = 350GB
Level 1 Size = 50GB × 0.35 = 17.5GB/day
Archive Log Size = 50GB × 7 = 350GB
Total Space = (350GB × 2) + (17.5GB × 6) + 350GB + 20% = 1,466GB
```

## Emergency Contacts and Notes

### Contact Information
- **Primary DBA**: [Name] - [Phone] - [Email]
- **Backup DBA**: [Name] - [Phone] - [Email]
- **System Administrator**: [Name] - [Phone] - [Email]
- **Storage Team**: [Name] - [Phone] - [Email]
- **Management Escalation**: [Name] - [Phone] - [Email]

### Important Notes
1. All production backups use AES256 encryption
2. Backup passwords stored in secure vault
3. Offsite backups synchronized daily
4. DR site updated via Data Guard
5. Monthly DR drills scheduled for first Sunday

## Recovery SOP Execution Summary

### Quick Reference Guide
1. **Assess the Situation**
   - Identify failure type
   - Check available backups
   - Estimate recovery time

2. **Notify Stakeholders**
   - Inform management
   - Update status page
   - Set expectations

3. **Execute Recovery**
   - Follow documented procedures
   - Document all actions
   - Perform validation tests

4. **Post-Recovery Tasks**
   - Take new backup
   - Update documentation
   - Conduct lessons learned
   - Schedule follow-up review

### Critical Commands Reference
```sql
-- Quick status check
SELECT name, open_mode, database_role FROM v$database;
SELECT * FROM v$backup WHERE status = 'ACTIVE';
SELECT * FROM v$recovery_file_dest;

-- Emergency recovery start
STARTUP NOMOUNT;
RESTORE CONTROLFILE FROM AUTOBACKUP;
ALTER DATABASE MOUNT;
RESTORE DATABASE;
RECOVER DATABASE;
ALTER DATABASE OPEN RESETLOGS;
```

---

**Document Version**: 1.0  
**Last Updated**: [Current Date]  
**Next Review**: [Review Date]  
**Document Owner**: Database Administration Team

*This document consolidates all Oracle backup and recovery procedures. For specific scenarios not covered here, consult Oracle documentation or contact the DBA team.*
