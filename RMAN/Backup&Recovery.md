-- =========================================================================
-- ORACLE DATABASE RECOVERY STANDARD OPERATING PROCEDURES (SOP)
-- Author: Database Administrator
-- Version: 1.0
-- Date: SYSDATE
-- =========================================================================

-- Common Pre-Recovery Checks
-- =========================================================================
PROMPT ========================================
PROMPT PRE-RECOVERY SYSTEM CHECKS
PROMPT ========================================

-- Check database status
SELECT name, open_mode, database_role FROM v$database;

-- Check instance status
SELECT instance_name, status, startup_time FROM v$instance;

-- Check archivelog mode
SELECT log_mode FROM v$database;

-- Check backup status
SELECT * FROM v$backup WHERE status = 'ACTIVE';

-- Check available backups
SELECT * FROM v$backup_set WHERE completion_time > SYSDATE - 30;

-- =========================================================================
-- 1. COMPLETE DATABASE RESTORE AND POINT-IN-TIME RECOVERY
-- =========================================================================

PROMPT ========================================
PROMPT 1. COMPLETE DATABASE RESTORE AND PITR
PROMPT ========================================

-- STEP 1.1: Pre-Recovery Verification
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

-- STEP 1.2: Database Shutdown
PROMPT Step 1.2: Shutdown Database
SHUTDOWN IMMEDIATE;

-- STEP 1.3: Startup in MOUNT mode
PROMPT Step 1.3: Startup Database in MOUNT mode
STARTUP MOUNT;

-- STEP 1.4: RMAN Restore Commands
PROMPT Step 1.4: Execute RMAN Restore (Run in RMAN)
/*
RMAN Commands to execute:
RESTORE DATABASE;
*/

-- STEP 1.5: RMAN Recovery Commands
PROMPT Step 1.5: Execute RMAN Recovery to Point-in-Time
/*
RMAN Commands for Point-in-Time Recovery:
RECOVER DATABASE UNTIL TIME 'YYYY-MM-DD HH24:MI:SS';
-- OR
RECOVER DATABASE UNTIL SCN <scn_number>;
-- OR
RECOVER DATABASE UNTIL SEQUENCE <sequence_number>;
*/

-- STEP 1.6: Open Database with RESETLOGS
PROMPT Step 1.6: Open Database with RESETLOGS
ALTER DATABASE OPEN RESETLOGS;

-- STEP 1.7: Post-Recovery Verification
PROMPT Step 1.7: Post-Recovery Verification
SELECT name, open_mode, resetlogs_time FROM v$database;

-- Check for invalid objects
SELECT owner, object_type, COUNT(*) 
FROM dba_objects 
WHERE status = 'INVALID' 
GROUP BY owner, object_type;

-- =========================================================================
-- 2. INDIVIDUAL TABLESPACE AND DATAFILE RECOVERY
-- =========================================================================

PROMPT ========================================
PROMPT 2. TABLESPACE AND DATAFILE RECOVERY
PROMPT ========================================

-- STEP 2.1: Identify Damaged Tablespace/Datafile
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

-- STEP 2.2: Take Tablespace Offline
PROMPT Step 2.2: Take Tablespace Offline
-- Replace 'TABLESPACE_NAME' with actual tablespace name
ALTER TABLESPACE TABLESPACE_NAME OFFLINE IMMEDIATE;

-- STEP 2.3: RMAN Restore Tablespace/Datafile
PROMPT Step 2.3: Execute RMAN Restore (Run in RMAN)
/*
RMAN Commands for Tablespace Recovery:
RESTORE TABLESPACE tablespace_name;
-- OR for specific datafile:
RESTORE DATAFILE 'datafile_path';
-- OR by file number:
RESTORE DATAFILE file_number;
*/

-- STEP 2.4: RMAN Recover Tablespace/Datafile
PROMPT Step 2.4: Execute RMAN Recovery (Run in RMAN)
/*
RMAN Commands for Recovery:
RECOVER TABLESPACE tablespace_name;
-- OR for specific datafile:
RECOVER DATAFILE 'datafile_path';
-- OR by file number:
RECOVER DATAFILE file_number;
*/

-- STEP 2.5: Bring Tablespace Online
PROMPT Step 2.5: Bring Tablespace Online
ALTER TABLESPACE TABLESPACE_NAME ONLINE;

-- STEP 2.6: Verify Recovery
PROMPT Step 2.6: Verify Tablespace Recovery
SELECT 
    tablespace_name,
    status,
    contents,
    logging
FROM dba_tablespaces 
WHERE tablespace_name = 'TABLESPACE_NAME';

-- Verify datafile status
SELECT 
    file_name,
    tablespace_name,
    status,
    enabled
FROM dba_data_files 
WHERE tablespace_name = 'TABLESPACE_NAME';

-- =========================================================================
-- 3. ARCHIVE LOG RECOVERY AND INCOMPLETE RECOVERY
-- =========================================================================

PROMPT ========================================
PROMPT 3. ARCHIVE LOG AND INCOMPLETE RECOVERY
PROMPT ========================================

-- STEP 3.1: Check Archive Log Status
PROMPT Step 3.1: Check Archive Log Status
SELECT 
    sequence#,
    name,
    dest_id,
    status,
    archived,
    applied,
    deleted,
    completion_time
FROM v$archived_log 
WHERE completion_time > SYSDATE - 7
ORDER BY sequence#;

-- Check for gaps in archive logs
SELECT 
    thread#,
    low_sequence#,
    high_sequence#
FROM v$archive_gap;

-- STEP 3.2: Current SCN and Time Information
PROMPT Step 3.2: Current Recovery Information
SELECT 
    current_scn,
    to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') as current_time
FROM v$database;

-- Check last applied archive log
SELECT 
    sequence#,
    applied,
    completion_time
FROM v$archived_log 
WHERE applied = 'YES'
ORDER BY sequence# DESC;

-- STEP 3.3: Database Recovery Commands
PROMPT Step 3.3: Incomplete Recovery Options

-- Option A: Cancel-based Recovery
PROMPT Option A: Cancel-based Recovery
/*
SQL Commands:
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
RECOVER DATABASE UNTIL CANCEL;
-- When prompted, type CANCEL to stop recovery
ALTER DATABASE OPEN RESETLOGS;
*/

-- Option B: Time-based Recovery
PROMPT Option B: Time-based Recovery
/*
SQL Commands:
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
RECOVER DATABASE UNTIL TIME 'YYYY-MM-DD HH24:MI:SS';
ALTER DATABASE OPEN RESETLOGS;
*/

-- Option C: SCN-based Recovery
PROMPT Option C: SCN-based Recovery
/*
SQL Commands:
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
RECOVER DATABASE UNTIL SCN scn_number;
ALTER DATABASE OPEN RESETLOGS;
*/

-- STEP 3.4: RMAN Archive Log Restore
PROMPT Step 3.4: RMAN Archive Log Restore Commands
/*
RMAN Commands:
RESTORE ARCHIVELOG FROM SEQUENCE start_seq TO end_seq;
-- OR
RESTORE ARCHIVELOG FROM TIME 'start_time' TO 'end_time';
-- OR
RESTORE ARCHIVELOG FROM SCN start_scn TO end_scn;
*/

-- =========================================================================
-- 4. CONTROL FILE RESTORATION AND RECOVERY
-- =========================================================================

PROMPT ========================================
PROMPT 4. CONTROL FILE RECOVERY
PROMPT ========================================

-- STEP 4.1: Check Control File Status
PROMPT Step 4.1: Check Control File Status
SELECT 
    name,
    status,
    is_recovery_dest_file,
    block_size,
    file_size_blks
FROM v$controlfile;

-- Check control file backup information
SELECT 
    autobackup_date,
    autobackup_count,
    keep_option,
    keep_until
FROM v$controlfile_record_section 
WHERE type = 'BACKUP';

-- STEP 4.2: Control File Recovery Scenarios

-- Scenario A: All Control Files Lost
PROMPT Scenario A: All Control Files Lost
/*
SQL Commands:
SHUTDOWN ABORT;
STARTUP NOMOUNT;
-- Then in RMAN:
RESTORE CONTROLFILE FROM AUTOBACKUP;
-- OR
RESTORE CONTROLFILE FROM 'backup_location';
ALTER DATABASE MOUNT;
RESTORE DATABASE;
RECOVER DATABASE;
ALTER DATABASE OPEN RESETLOGS;
*/

-- Scenario B: Some Control Files Lost
PROMPT Scenario B: Some Control Files Lost
/*
Steps:
1. SHUTDOWN IMMEDIATE;
2. Copy existing control file to missing location
3. STARTUP;
*/

-- Scenario C: Control File Corruption
PROMPT Scenario C: Control File Corruption
/*
SQL Commands:
SHUTDOWN ABORT;
STARTUP NOMOUNT;
-- In RMAN:
RESTORE CONTROLFILE FROM 'backup_location';
ALTER DATABASE MOUNT;
RECOVER DATABASE;
ALTER DATABASE OPEN RESETLOGS;
*/

-- STEP 4.3: Verify Control File Recovery
PROMPT Step 4.3: Verify Control File Recovery
SELECT 
    name,
    status,
    checkpoint_change#,
    checkpoint_time
FROM v$controlfile;

-- =========================================================================
-- 5. BLOCK-LEVEL RECOVERY AND CORRUPTION HANDLING
-- =========================================================================

PROMPT ========================================
PROMPT 5. BLOCK-LEVEL RECOVERY
PROMPT ========================================

-- STEP 5.1: Identify Corrupted Blocks
PROMPT Step 5.1: Identify Corrupted Blocks
SELECT 
    file#,
    block#,
    blocks,
    corruption_change#,
    corruption_type
FROM v$database_block_corruption;

-- Check for logical corruption
SELECT 
    owner,
    segment_name,
    segment_type,
    tablespace_name,
    file_id,
    block_id,
    blocks
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

-- STEP 5.2: RMAN Block Recovery
PROMPT Step 5.2: Execute RMAN Block Recovery
/*
RMAN Commands:
BLOCKRECOVER DATAFILE file_number BLOCK block_number;
-- OR
BLOCKRECOVER DATAFILE 'datafile_path' BLOCK block_number;
-- OR recover multiple blocks:
BLOCKRECOVER DATAFILE file_number BLOCK block_number1, block_number2;
*/

-- STEP 5.3: Verify Block Recovery
PROMPT Step 5.3: Verify Block Recovery
-- Check if corruption is resolved
SELECT 
    file#,
    block#,
    blocks,
    corruption_change#,
    corruption_type
FROM v$database_block_corruption;

-- Validate affected segments
-- Replace with actual segment name
ANALYZE TABLE schema.table_name VALIDATE STRUCTURE CASCADE;

-- =========================================================================
-- 6. DISASTER RECOVERY AND TOTAL SYSTEM FAILURE
-- =========================================================================

PROMPT ========================================
PROMPT 6. DISASTER RECOVERY PROCEDURES
PROMPT ========================================

-- STEP 6.1: Assess System Damage
PROMPT Step 6.1: System Damage Assessment
/*
Check the following:
1. Database files status
2. Archive logs availability
3. Control files status
4. Parameter files status
5. Backup availability
*/

SELECT 
    'Database Files' as component,
    COUNT(*) as total_files,
    SUM(CASE WHEN status = 'AVAILABLE' THEN 1 ELSE 0 END) as available,
    SUM(CASE WHEN status != 'AVAILABLE' THEN 1 ELSE 0 END) as damaged
FROM v$datafile
UNION ALL
SELECT 
    'Control Files' as component,
    COUNT(*) as total_files,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) as available,
    SUM(CASE WHEN status IS NOT NULL THEN 1 ELSE 0 END) as damaged
FROM v$controlfile;

-- STEP 6.2: Complete System Recovery
PROMPT Step 6.2: Complete System Recovery Process
/*
Recovery Steps:
1. Restore Oracle software (if needed)
2. Restore parameter files
3. Restore control files
4. Restore database files
5. Restore archive logs
6. Perform recovery
7. Open database
*/

-- STEP 6.3: RMAN Complete Recovery Commands
PROMPT Step 6.3: RMAN Complete Recovery Commands
/*
RMAN Recovery Script:
STARTUP NOMOUNT;
RESTORE SPFILE FROM AUTOBACKUP;
SHUTDOWN IMMEDIATE;
STARTUP NOMOUNT;
RESTORE CONTROLFILE FROM AUTOBACKUP;
ALTER DATABASE MOUNT;
RESTORE DATABASE;
RECOVER DATABASE;
ALTER DATABASE OPEN RESETLOGS;
*/

-- STEP 6.4: Post-Recovery Validation
PROMPT Step 6.4: Post-Recovery Validation
-- Check database status
SELECT 
    name,
    open_mode,
    database_role,
    protection_mode,
    protection_level
FROM v$database;

-- Check datafile status
SELECT 
    file#,
    name,
    status,
    enabled,
    checkpoint_change#,
    checkpoint_time
FROM v$datafile;

-- Check tablespace status
SELECT 
    tablespace_name,
    status,
    contents,
    logging
FROM dba_tablespaces
ORDER BY tablespace_name;

-- Check invalid objects
SELECT 
    owner,
    object_type,
    COUNT(*) as invalid_count
FROM dba_objects 
WHERE status = 'INVALID'
GROUP BY owner, object_type
ORDER BY owner, object_type;

-- STEP 6.5: Final System Verification
PROMPT Step 6.5: Final System Verification
-- Test database connectivity
SELECT 
    'Database Connection Test' as test_name,
    USER as connected_user,
    TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') as test_time
FROM dual;

-- Check key application tables (customize as needed)
SELECT 
    table_name,
    num_rows,
    last_analyzed
FROM user_tables
WHERE table_name IN ('IMPORTANT_TABLE1', 'IMPORTANT_TABLE2')
ORDER BY table_name;

-- =========================================================================
-- EMERGENCY CONTACTS AND NOTES
-- =========================================================================

PROMPT ========================================
PROMPT EMERGENCY PROCEDURES COMPLETED
PROMPT ========================================

PROMPT Recovery SOP Execution Summary:
PROMPT 1. Always verify backup availability before starting recovery
PROMPT 2. Document all recovery steps and timings
PROMPT 3. Validate database integrity after recovery
PROMPT 4. Update disaster recovery documentation
PROMPT 5. Schedule full backup after successful recovery

PROMPT Emergency Contacts:
PROMPT - DBA Team: [Contact Information]
PROMPT - System Administrator: [Contact Information]
PROMPT - Management: [Contact Information]

-- End of Recovery SOP Script
