-- =====================================================
-- ORACLE DATA GUARD ESSENTIAL SCRIPTS COLLECTION
-- =====================================================

-- =====================================================
-- 1. DATA GUARD STATUS CHECK SCRIPT
-- =====================================================

-- Check Data Guard Status and Configuration
SELECT 
    database_role,
    open_mode,
    protection_mode,
    protection_level,
    switchover_status,
    dataguard_broker,
    force_logging,
    log_mode
FROM v$database;

-- Check Archive Log Gap
SELECT 
    thread#,
    max(sequence#) "Last Sequence Generated"
FROM v$archived_log 
WHERE resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
GROUP BY thread#;

-- Check Applied Logs on Standby
SELECT 
    thread#,
    max(sequence#) "Last Sequence Applied"
FROM v$archived_log 
WHERE resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
AND applied = 'YES'
GROUP BY thread#;

-- =====================================================
-- 2. DATA GUARD LAG MONITORING SCRIPT
-- =====================================================

-- Transport Lag (Time difference between log generation and receipt)
SELECT 
    name,
    value,
    time_computed,
    datum_time
FROM v$dataguard_stats 
WHERE name IN ('transport lag', 'apply lag');

-- Detailed Lag Analysis
SELECT 
    al.thread#,
    al.sequence#,
    al.applied,
    al.completion_time,
    CASE 
        WHEN al.completion_time IS NOT NULL THEN
            ROUND((SYSDATE - al.completion_time) * 24 * 60, 2)
        ELSE NULL
    END AS lag_minutes
FROM v$archived_log al
WHERE al.resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
ORDER BY al.thread#, al.sequence# DESC;

-- =====================================================
-- 3. REDO LOG MONITORING SCRIPT
-- =====================================================

-- Check Redo Log Status
SELECT 
    group#,
    thread#,
    sequence#,
    bytes/1024/1024 as size_mb,
    members,
    archived,
    status,
    first_change#,
    first_time
FROM v$log
ORDER BY group#;

-- Check Redo Log Members
SELECT 
    lf.group#,
    lf.member,
    lf.status,
    l.bytes/1024/1024 as size_mb
FROM v$logfile lf, v$log l
WHERE lf.group# = l.group#
ORDER BY lf.group#, lf.member;

-- Check Standby Redo Logs
SELECT 
    group#,
    thread#,
    sequence#,
    bytes/1024/1024 as size_mb,
    used,
    status
FROM v$standby_log
ORDER BY group#;

-- =====================================================
-- 4. ARCHIVE LOG MONITORING SCRIPT
-- =====================================================

-- Archive Log Generation Rate (Last 24 hours)
SELECT 
    TO_CHAR(first_time, 'YYYY-MM-DD HH24') as hour,
    thread#,
    COUNT(*) as logs_generated,
    SUM(blocks * block_size)/1024/1024 as mb_generated
FROM v$archived_log
WHERE first_time >= SYSDATE - 1
AND resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
GROUP BY TO_CHAR(first_time, 'YYYY-MM-DD HH24'), thread#
ORDER BY 1, 2;

-- Archive Destination Status
SELECT 
    dest_id,
    dest_name,
    status,
    type,
    database_mode,
    recovery_mode,
    protection_mode,
    synchronized,
    affirm,
    error
FROM v$archive_dest_status
WHERE status != 'INACTIVE';

-- =====================================================
-- 5. MRP (MANAGED RECOVERY PROCESS) MONITORING
-- =====================================================

-- Check MRP Status
SELECT 
    process,
    status,
    thread#,
    sequence#,
    block#,
    blocks
FROM v$managed_standby
WHERE process LIKE 'MRP%' OR process LIKE 'RFS%';

-- Detailed Recovery Progress
SELECT 
    item,
    units,
    sofar,
    total,
    ROUND((sofar/total)*100, 2) as pct_complete
FROM v$recovery_progress
WHERE item = 'Active Apply Rate';

-- =====================================================
-- 6. DGMGRL BROKER CONFIGURATION SCRIPTS
-- =====================================================

-- Enable Data Guard Broker (Run on Primary)
/*
ALTER SYSTEM SET dg_broker_start=TRUE;
ALTER SYSTEM SET dg_broker_config_file1='/u01/app/oracle/product/19.0.0/dbhome_1/dbs/dr1ORCL.dat';
ALTER SYSTEM SET dg_broker_config_file2='/u01/app/oracle/product/19.0.0/dbhome_1/dbs/dr2ORCL.dat';
*/

-- DGMGRL Commands (Run from command line)
/*
dgmgrl /
CREATE CONFIGURATION 'DG_CONFIG' AS PRIMARY DATABASE IS 'ORCL' CONNECT IDENTIFIER IS 'ORCL';
ADD DATABASE 'ORCLSTBY' AS CONNECT IDENTIFIER IS 'ORCLSTBY' MAINTAINED AS PHYSICAL;
ENABLE CONFIGURATION;
SHOW CONFIGURATION;
SHOW DATABASE 'ORCL';
SHOW DATABASE 'ORCLSTBY';
*/

-- =====================================================
-- 7. SWITCHOVER PREPARATION SCRIPTS
-- =====================================================

-- Pre-Switchover Checks
-- Check if Primary is ready for switchover
SELECT switchover_status FROM v$database;
-- Should show 'TO STANDBY' or 'SESSIONS ACTIVE'

-- Check if Standby is ready for switchover
SELECT switchover_status FROM v$database;
-- Should show 'NOT ALLOWED' or 'SESSIONS ACTIVE'

-- Check for Active Sessions (if SESSIONS ACTIVE)
SELECT 
    sid,
    serial#,
    username,
    program,
    status,
    logon_time
FROM v$session
WHERE username IS NOT NULL
AND username NOT IN ('SYS', 'SYSTEM')
ORDER BY logon_time;

-- =====================================================
-- 8. FAILOVER PREPARATION SCRIPTS
-- =====================================================

-- Check if Standby can be activated
SELECT 
    thread#,
    max(sequence#) as max_seq
FROM v$archived_log
WHERE resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
GROUP BY thread#;

-- Check for any gaps in archive logs
SELECT 
    thread#,
    low_sequence#,
    high_sequence#
FROM v$archive_gap;

-- =====================================================
-- 9. PERFORMANCE MONITORING SCRIPTS
-- =====================================================

-- Redo Apply Rate
SELECT 
    TO_CHAR(first_time, 'YYYY-MM-DD HH24:MI') as time,
    thread#,
    sequence#,
    (next_change# - first_change#) as changes,
    ROUND((next_change# - first_change#)/
          ((next_time - first_time) * 24 * 60 * 60), 2) as changes_per_sec
FROM v$archived_log
WHERE first_time >= SYSDATE - 1/24  -- Last hour
AND applied = 'YES'
ORDER BY first_time DESC;

-- Network Transmission Rate
SELECT 
    dest_name,
    archived_seq#,
    applied_seq#,
    (archived_seq# - applied_seq#) as gap,
    ROUND(((archived_seq# - applied_seq#) * 
           (SELECT AVG(blocks * block_size) FROM v$archived_log 
            WHERE first_time >= SYSDATE - 1))/1024/1024, 2) as gap_mb
FROM v$archive_dest_status
WHERE status = 'VALID';

-- =====================================================
-- 10. TROUBLESHOOTING SCRIPTS
-- =====================================================

-- Check for Errors in Alert Log Equivalent
SELECT 
    message_text,
    originating_timestamp,
    module_id,
    process_id
FROM v$diag_alert_ext
WHERE originating_timestamp >= SYSDATE - 1
AND message_text LIKE '%ORA-%'
ORDER BY originating_timestamp DESC;

-- Check Data Guard Broker Status
SELECT 
    severity,
    error_code,
    message,
    timestamp
FROM v$dataguard_status
WHERE timestamp >= SYSDATE - 1
ORDER BY timestamp DESC;

-- Check for Corruption
SELECT 
    file#,
    block#,
    blocks,
    corruption_change#,
    corruption_type
FROM v$database_block_corruption;

-- =====================================================
-- 11. MAINTENANCE SCRIPTS
-- =====================================================

-- Clear Archive Logs (Use with caution)
/*
-- On Primary (after ensuring standby is in sync)
DELETE FROM v$archived_log WHERE first_time < SYSDATE - 7;

-- Using RMAN (Recommended)
RMAN> DELETE ARCHIVELOG UNTIL TIME 'SYSDATE - 7';
*/

-- Force Log Switch (For testing)
ALTER SYSTEM SWITCH LOGFILE;

-- Cancel Managed Recovery (On Standby)
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;

-- Start Managed Recovery (On Standby)
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;

-- =====================================================
-- 12. MONITORING VIEWS SUMMARY
-- =====================================================

-- Key Views for Data Guard Monitoring:
-- v$database - Database role and protection mode
-- v$dataguard_stats - Transport and apply lag statistics
-- v$archived_log - Archive log information
-- v$log - Online redo log status
-- v$standby_log - Standby redo log status
-- v$archive_dest_status - Archive destination status
-- v$managed_standby - Recovery process status
-- v$recovery_progress - Recovery progress information
-- v$dataguard_status - Data Guard broker status
-- v$archive_gap - Archive log gaps

-- =====================================================
-- 13. QUICK HEALTH CHECK SCRIPT
-- =====================================================

-- Comprehensive Health Check
SELECT 'Database Role' as metric, database_role as value FROM v$database
UNION ALL
SELECT 'Open Mode', open_mode FROM v$database
UNION ALL
SELECT 'Protection Mode', protection_mode FROM v$database
UNION ALL
SELECT 'Switchover Status', switchover_status FROM v$database
UNION ALL
SELECT 'Force Logging', force_logging FROM v$database
UNION ALL
SELECT 'Log Mode', log_mode FROM v$database
UNION ALL
SELECT 'Broker Enabled', dataguard_broker FROM v$database;

-- =====================================================
-- 14. VERSION-SPECIFIC FEATURES AND SCRIPTS
-- =====================================================

-- Oracle 11g Specific Features
-- =============================
-- Real-time apply (11.1+)
-- Active Data Guard (11.1+)
-- Snapshot Standby (11.1+)
-- Rolling upgrades with physical standby (11.2.0.1+)

-- Oracle 12c Specific Features and Scripts
-- ========================================
-- SYSDG privilege (12.1+)
CREATE USER dataguard_admin IDENTIFIED BY password;
GRANT SYSDG TO dataguard_admin;

-- Multitenant Data Guard (12.1+)
-- Check PDB status in multitenant environment
SELECT 
    con_id,
    name,
    open_mode,
    database_role
FROM v$pdbs
WHERE con_id > 2;

-- Oracle 18c/19c Specific Features and Scripts
-- ============================================
-- DML Redirection (19c+)
-- Check DML redirection status
SELECT name, value FROM v$parameter WHERE name = 'data_guard_sync_latency';

-- In-Memory with Multi-Instance Redo Apply (19c+)
SELECT 
    feature_name,
    feature_info,
    con_id
FROM v$feature_usage_statistics 
WHERE feature_name LIKE '%Data Guard%' OR feature_name LIKE '%In-Memory%';

-- Fast-Start Failover Observe-only mode (19c+)
-- Use in DGMGRL: ENABLE FAST_START FAILOVER OBSERVE ONLY;

-- Auto Flashback Standby (19c+)
SELECT value FROM v$parameter WHERE name = 'data_guard_auto_flashback';

-- Oracle 21c Specific Features and Scripts
-- ========================================
-- PREPARE DATABASE FOR DATA GUARD command (21c+)
-- Run from DGMGRL:
/*
PREPARE DATABASE FOR DATA GUARD 
WITH DB_UNIQUE_NAME IS 'standby_db'
     DB_RECOVERY_FILE_DEST IS '/u01/app/oracle/fast_recovery_area'
     DB_RECOVERY_FILE_DEST_SIZE IS 20G;
*/

-- Check if database is prepared for Data Guard (21c+)
SELECT 
    name,
    value 
FROM v$parameter 
WHERE name IN (
    'db_files',
    'log_buffer', 
    'db_block_checksum',
    'db_lost_write_protect',
    'db_flashback_retention_target'
);

-- Attention Log monitoring (21c+)
SELECT name, value FROM v$diag_info WHERE name = 'Attention Log';

-- Oracle 23c/23ai Specific Features and Scripts
-- =============================================
-- New Data Guard Broker views (23c+)

-- V$DG_BROKER_ROLE_CHANGE - Track role transitions
SELECT 
    database_name,
    transition_time,
    old_role,
    new_role,
    transition_type,
    reason
FROM v$dg_broker_role_change
ORDER BY transition_time DESC;

-- V$DG_BROKER_DATABASE_PROPS - Direct SQL access to broker properties
SELECT 
    database_name,
    property_name,
    property_value,
    property_type
FROM v$dg_broker_database_props
WHERE property_name IN ('TransportLagThreshold', 'ApplyLagThreshold');

-- V$DG_BROKER_CONFIG_PROPS - Broker configuration properties
SELECT 
    property_name,
    property_value,
    property_type
FROM v$dg_broker_config_props
WHERE property_name LIKE '%Threshold%';

-- Per-PDB Data Guard (23c+) - Multitenant enhancement
SELECT 
    pdb_name,
    role,
    open_mode,
    switchover_status
FROM dba_pdbs p, v$database d
WHERE p.con_id = d.con_id;

-- DrainTimeout property (21c+, enhanced in 23c)
-- Check drain timeout settings
SELECT name, value FROM v$parameter WHERE name = 'drain_timeout';

-- Raft Replication support (23c+)
SELECT 
    name,
    value 
FROM v$parameter 
WHERE name LIKE '%raft%';

-- True Cache monitoring (23c+)
SELECT 
    name,
    value
FROM v$parameter 
WHERE name LIKE '%true_cache%';

-- =====================================================
-- 15. VERSION COMPATIBILITY MATRIX
-- =====================================================

-- View availability by version:
-- v$database - All versions (8i+)
-- v$dataguard_stats - 10g+
-- v$managed_standby - All versions
-- v$archive_dest_status - All versions  
-- v$recovery_progress - 10g+
-- v$dataguard_status - 10g+ (enhanced in each version)
-- v$standby_log - 9i+ (required for 11g+ real-time apply)
-- v$recovery_file_dest - 10g+
-- v$dg_broker_role_change - 23c+
-- v$dg_broker_database_props - 23c+
-- v$dg_broker_config_props - 23c+

-- Parameter availability by version:
-- log_archive_dest_n - All versions
-- log_archive_config - 9i+
-- data_guard_sync_latency - 19c+
-- data_guard_auto_flashback - 19c+
-- drain_timeout - 21c+
-- dg_broker_start - 9i+
-- dg_broker_config_file1/2 - 9i+

-- =====================================================
-- 16. LEGACY VERSION SCRIPTS (11g/12c SPECIFIC)
-- =====================================================

-- For Oracle 11g - Use these instead of newer equivalents
-- =======================================================

-- 11g: Check if Real-time Apply is enabled
SELECT 
    'Real-time Apply: ' || 
    CASE WHEN COUNT(*) > 0 THEN 'ENABLED' ELSE 'DISABLED' END as status
FROM v$managed_standby 
WHERE process LIKE 'MRP%' AND status = 'APPLYING_LOG';

-- 11g: Snapshot Standby conversion status
SELECT 
    'Snapshot Standby: ' ||
    CASE WHEN open_mode = 'READ WRITE' AND database_role = 'SNAPSHOT STANDBY' 
         THEN 'ACTIVE' 
         ELSE 'INACTIVE' 
    END as status
FROM v$database;

-- For Oracle 12c - Multitenant specific
-- ====================================

-- 12c: Check container database Data Guard configuration
SELECT 
    'Container: ' || name as database_name,
    database_role,
    open_mode,
    cdb
FROM v$database;

-- 12c: Check if SYSDG user exists
SELECT 
    username,
    account_status,
    created
FROM dba_users 
WHERE username IN (
    SELECT grantee FROM dba_role_privs WHERE granted_role = 'SYSDG'
);

-- =====================================================
-- 17. TROUBLESHOOTING BY VERSION
-- =====================================================

-- Common issues by version:

-- 11g Issues:
-- ORA-16766: Redo Apply is stopped
-- Solution: Check MRP process and restart if needed
SELECT process, status FROM v$managed_standby WHERE process LIKE 'MRP%';
-- ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;

-- 12c Issues: 
-- ORA-65040: operation not allowed from within a pluggable database
-- Solution: Connect to CDB$ROOT for Data Guard operations

-- 19c Issues:
-- DML redirection failures
-- Check: SELECT name, value FROM v$parameter WHERE name = 'data_guard_sync_latency';

-- 21c Issues:
-- PREPARE DATABASE command failures
-- Check: Ensure adequate space for FRA and proper permissions

-- 23c Issues:
-- New views not accessible
-- Check: Database compatibility and version
SELECT * FROM v$version WHERE banner LIKE 'Oracle Database%';

-- =====================================================
-- 18. DGMGRL VERSION-SPECIFIC COMMANDS
-- =====================================================

-- All versions:
-- SHOW CONFIGURATION
-- SHOW DATABASE database_name
-- ENABLE/DISABLE CONFIGURATION
-- SWITCHOVER TO database_name
-- FAILOVER TO database_name

-- 11g+:
-- ENABLE FAST_START FAILOVER
-- SHOW FAST_START FAILOVER

-- 12c+:
-- EDIT DATABASE database_name SET PROPERTY property=value
-- VALIDATE DATABASE database_name

-- 19c+:
-- ENABLE FAST_START FAILOVER OBSERVE ONLY
-- EDIT DATABASE database_name SET PARAMETER parameter=value

-- 21c+:
-- PREPARE DATABASE FOR DATA GUARD WITH ...

-- 23c+:
-- Enhanced property management through SQL
-- Direct access to broker properties via v$ views

-- =====================================================
-- END OF VERSION-SPECIFIC SCRIPTS
-- =====================================================

-- USAGE NOTES:
-- 1. Run these scripts as SYS, SYSTEM, or SYSDG user (SYSDG available 12c+)
-- 2. Some scripts are specific to Primary or Standby - noted in comments
-- 3. DGMGRL commands should be run from command line, not SQL*Plus
-- 4. Always test switchover/failover procedures in non-production first
-- 5. Monitor performance impact of frequent executions
-- 6. Adjust time ranges in scripts based on your monitoring needs
-- 7. Check Oracle version compatibility before using version-specific features
-- 8. For 12c+ multitenant, ensure you're connected to the right container
-- 9. 21c PREPARE DATABASE command greatly simplifies initial setup
-- 10. 23c introduces significant observability improvements with new v$ views
