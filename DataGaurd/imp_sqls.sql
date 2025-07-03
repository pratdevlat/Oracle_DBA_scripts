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

-- =====================================================
-- ORACLE DATA GUARD DAILY TROUBLESHOOTING SQL SCRIPTS
-- =====================================================

-- =====================================================
-- 1. QUICK HEALTH CHECK DASHBOARD
-- =====================================================

-- Daily Status Overview (Run on both Primary and Standby)
SELECT 
    'DATABASE ROLE' as metric,
    database_role as value,
    CASE 
        WHEN database_role = 'PRIMARY' THEN '✓ Primary Active'
        WHEN database_role = 'PHYSICAL STANDBY' THEN '✓ Standby Role'
        ELSE '⚠ Check Role Status'
    END as status
FROM v$database
UNION ALL
SELECT 
    'OPEN MODE',
    open_mode,
    CASE 
        WHEN database_role = 'PRIMARY' AND open_mode = 'READ WRITE' THEN '✓ Primary Open'
        WHEN database_role = 'PHYSICAL STANDBY' AND open_mode IN ('MOUNTED', 'READ ONLY', 'READ ONLY WITH APPLY') THEN '✓ Standby Normal'
        ELSE '⚠ Check Open Mode'
    END
FROM v$database
UNION ALL
SELECT 
    'SWITCHOVER STATUS',
    switchover_status,
    CASE 
        WHEN switchover_status IN ('TO STANDBY', 'NOT ALLOWED', 'SESSIONS ACTIVE') THEN '✓ Ready'
        ELSE '⚠ Check Status: ' || switchover_status
    END
FROM v$database
UNION ALL
SELECT 
    'PROTECTION MODE',
    protection_mode,
    '✓ Current Mode'
FROM v$database
UNION ALL
SELECT 
    'ARCHIVE LOG MODE',
    log_mode,
    CASE log_mode 
        WHEN 'ARCHIVELOG' THEN '✓ Enabled' 
        ELSE '❌ Must Enable Archivelog' 
    END
FROM v$database
UNION ALL
SELECT 
    'FORCE LOGGING',
    force_logging,
    CASE force_logging 
        WHEN 'YES' THEN '✓ Enabled' 
        ELSE '⚠ Should Enable Force Logging' 
    END
FROM v$database;

-- =====================================================
-- 2. LAG ANALYSIS AND ALERTS
-- =====================================================

-- Critical Lag Check (Run on Standby)
SELECT 
    CASE 
        WHEN name = 'transport lag' THEN '🚛 TRANSPORT LAG'
        WHEN name = 'apply lag' THEN '⚙️ APPLY LAG'
        ELSE name
    END as lag_type,
    value,
    time_computed,
    CASE 
        WHEN name = 'transport lag' AND EXTRACT(HOUR FROM TO_DSINTERVAL(value)) >= 1 THEN '❌ CRITICAL: > 1 hour'
        WHEN name = 'apply lag' AND EXTRACT(HOUR FROM TO_DSINTERVAL(value)) >= 1 THEN '❌ CRITICAL: > 1 hour'
        WHEN name = 'transport lag' AND EXTRACT(MINUTE FROM TO_DSINTERVAL(value)) >= 30 THEN '⚠ WARNING: > 30 minutes'
        WHEN name = 'apply lag' AND EXTRACT(MINUTE FROM TO_DSINTERVAL(value)) >= 30 THEN '⚠ WARNING: > 30 minutes'
        WHEN name = 'transport lag' AND EXTRACT(MINUTE FROM TO_DSINTERVAL(value)) >= 5 THEN '⚡ CAUTION: > 5 minutes'
        WHEN name = 'apply lag' AND EXTRACT(MINUTE FROM TO_DSINTERVAL(value)) >= 5 THEN '⚡ CAUTION: > 5 minutes'
        ELSE '✓ NORMAL'
    END as alert_level,
    CASE 
        WHEN name = 'transport lag' THEN 'Check network, redo generation rate, archive dest'
        WHEN name = 'apply lag' THEN 'Check MRP process, I/O performance, apply rate'
        ELSE 'Monitor trend'
    END as troubleshooting_hint
FROM v$dataguard_stats 
WHERE name IN ('transport lag', 'apply lag')
ORDER BY name;

-- Sequence Gap Analysis
WITH primary_seq AS (
    SELECT thread#, MAX(sequence#) as max_primary_seq
    FROM v$archived_log 
    WHERE resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
    GROUP BY thread#
),
applied_seq AS (
    SELECT thread#, MAX(sequence#) as max_applied_seq
    FROM v$archived_log 
    WHERE resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
    AND applied = 'YES'
    GROUP BY thread#
)
SELECT 
    p.thread#,
    p.max_primary_seq as primary_sequence,
    NVL(a.max_applied_seq, 0) as applied_sequence,
    (p.max_primary_seq - NVL(a.max_applied_seq, 0)) as sequence_gap,
    CASE 
        WHEN (p.max_primary_seq - NVL(a.max_applied_seq, 0)) = 0 THEN '✓ NO GAP'
        WHEN (p.max_primary_seq - NVL(a.max_applied_seq, 0)) <= 2 THEN '⚡ MINOR GAP'
        WHEN (p.max_primary_seq - NVL(a.max_applied_seq, 0)) <= 10 THEN '⚠ MODERATE GAP'
        ELSE '❌ CRITICAL GAP'
    END as gap_status,
    CASE 
        WHEN (p.max_primary_seq - NVL(a.max_applied_seq, 0)) > 2 THEN 'Check MRP process and archive dest status'
        ELSE 'Normal operation'
    END as action_required
FROM primary_seq p
LEFT JOIN applied_seq a ON p.thread# = a.thread#
ORDER BY p.thread#;

-- =====================================================
-- 3. PROCESS MONITORING
-- =====================================================

-- MRP/Apply Process Health Check (Run on Standby)
SELECT 
    process,
    pid,
    status,
    thread#,
    sequence#,
    block#,
    blocks,
    CASE 
        WHEN process = 'MRP0' AND status = 'APPLYING_LOG' THEN '✓ ACTIVE APPLY'
        WHEN process = 'MRP0' AND status = 'WAIT_FOR_LOG' THEN '⏳ WAITING FOR REDO'
        WHEN process = 'MRP0' AND status = 'IDLE' THEN '💤 IDLE - Check if apply is started'
        WHEN process LIKE 'PR%' AND status = 'APPLYING_LOG' THEN '✓ PARALLEL APPLY ACTIVE'
        WHEN process LIKE 'RFS' AND status = 'IDLE' THEN '✓ RFS READY'
        WHEN process LIKE 'RFS' AND status = 'RECEIVING' THEN '📥 RECEIVING REDO'
        ELSE '⚠ CHECK STATUS: ' || status
    END as process_status,
    CASE 
        WHEN process = 'MRP0' AND status NOT IN ('APPLYING_LOG', 'WAIT_FOR_LOG') THEN 'START: ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT'
        WHEN process LIKE 'RFS' AND status = 'ERROR' THEN 'Check network connectivity and archive destinations'
        ELSE 'Monitor'
    END as recommended_action
FROM v$managed_standby 
WHERE process IS NOT NULL
ORDER BY process, thread#;

-- Archive Destination Status (Run on Primary)
SELECT 
    dest_id,
    dest_name,
    status,
    type,
    database_mode,
    recovery_mode,
    archived_seq#,
    applied_seq#,
    (archived_seq# - applied_seq#) as sequence_lag,
    error,
    CASE 
        WHEN status = 'VALID' THEN '✓ OPERATIONAL'
        WHEN status = 'DEFERRED' THEN '⏸️ DEFERRED - May need manual intervention'
        WHEN status = 'ERROR' THEN '❌ ERROR - Immediate attention required'
        WHEN status = 'DISABLED' THEN '🔴 DISABLED - Check configuration'
        ELSE '⚠ UNKNOWN STATUS'
    END as health_status,
    CASE 
        WHEN status = 'ERROR' AND error LIKE '%ORA-01034%' THEN 'Standby database not available'
        WHEN status = 'ERROR' AND error LIKE '%ORA-00257%' THEN 'Archive destination full'
        WHEN status = 'ERROR' AND error LIKE '%ORA-12541%' THEN 'Network connectivity issue'
        WHEN status = 'DEFERRED' THEN 'Use: ALTER SYSTEM LOG_ARCHIVE_DEST_STATE_n=ENABLE'
        ELSE 'Check error details and alert log'
    END as troubleshooting_tip
FROM v$archive_dest_status 
WHERE status != 'INACTIVE'
ORDER BY dest_id;

-- =====================================================
-- 4. PERFORMANCE ANALYSIS
-- =====================================================

-- Redo Generation Rate (Last Hour)
SELECT 
    TO_CHAR(first_time, 'YYYY-MM-DD HH24') as hour,
    thread#,
    COUNT(*) as logs_generated,
    ROUND(SUM(blocks * block_size)/1024/1024, 2) as mb_generated,
    ROUND(AVG(blocks * block_size)/1024/1024, 2) as avg_mb_per_log,
    CASE 
        WHEN COUNT(*) > 100 THEN '🔥 HIGH ACTIVITY'
        WHEN COUNT(*) > 50 THEN '⚡ MODERATE ACTIVITY'
        WHEN COUNT(*) > 10 THEN '✓ NORMAL ACTIVITY'
        ELSE '💤 LOW ACTIVITY'
    END as activity_level
FROM v$archived_log
WHERE first_time >= SYSDATE - 1/24  -- Last hour
AND resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
GROUP BY TO_CHAR(first_time, 'YYYY-MM-DD HH24'), thread#
ORDER BY 1 DESC, 2;

-- Apply Rate Analysis (Run on Standby)
SELECT 
    TO_CHAR(first_time, 'HH24:MI') as apply_time,
    thread#,
    sequence#,
    blocks,
    ROUND(blocks * 8192 / 1024 / 1024, 2) as size_mb,
    completion_time,
    next_time,
    ROUND((next_time - first_time) * 24 * 60 * 60, 2) as apply_duration_seconds,
    CASE 
        WHEN (next_time - first_time) * 24 * 60 * 60 > 300 THEN '🐌 SLOW APPLY > 5min'
        WHEN (next_time - first_time) * 24 * 60 * 60 > 60 THEN '⚠ DELAYED APPLY > 1min'
        ELSE '✓ NORMAL APPLY'
    END as apply_performance
FROM v$archived_log
WHERE applied = 'YES'
AND first_time >= SYSDATE - 2/24  -- Last 2 hours
AND resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
ORDER BY first_time DESC, thread#, sequence#
FETCH FIRST 20 ROWS ONLY;

-- =====================================================
-- 5. STORAGE AND SPACE MONITORING
-- =====================================================

-- Archive Log Space Usage
SELECT 
    dest_name,
    space_limit/1024/1024/1024 as space_limit_gb,
    space_used/1024/1024/1024 as space_used_gb,
    space_used/space_limit*100 as percent_used,
    CASE 
        WHEN space_used/space_limit*100 >= 90 THEN '❌ CRITICAL: >90% full'
        WHEN space_used/space_limit*100 >= 80 THEN '⚠ WARNING: >80% full'
        WHEN space_used/space_limit*100 >= 70 THEN '⚡ CAUTION: >70% full'
        ELSE '✓ NORMAL: <70% full'
    END as space_status,
    CASE 
        WHEN space_used/space_limit*100 >= 90 THEN 'URGENT: Clean old archives or expand storage'
        WHEN space_used/space_limit*100 >= 80 THEN 'Plan archive cleanup or storage expansion'
        ELSE 'Monitor space usage'
    END as action_needed
FROM v$recovery_file_dest
UNION ALL
SELECT 
    'ARCHIVE_DEST_' || dest_id as dest_name,
    NULL as space_limit_gb,
    NULL as space_used_gb,
    NULL as percent_used,
    CASE 
        WHEN status = 'VALID' THEN '✓ DESTINATION AVAILABLE'
        ELSE '⚠ CHECK DESTINATION: ' || status
    END as space_status,
    'Monitor individual destination space' as action_needed
FROM v$archive_dest_status 
WHERE status != 'INACTIVE' AND dest_id > 1;

-- Redo Log Status and Size Analysis
SELECT 
    'ONLINE REDO LOGS' as log_type,
    l.group#,
    l.thread#,
    l.sequence#,
    ROUND(l.bytes/1024/1024, 2) as size_mb,
    l.members,
    l.status,
    l.archived,
    CASE 
        WHEN l.status = 'CURRENT' THEN '✓ CURRENT LOG'
        WHEN l.status = 'ACTIVE' THEN '⚡ ACTIVE LOG'
        WHEN l.status = 'INACTIVE' AND l.archived = 'YES' THEN '✓ ARCHIVED'
        WHEN l.status = 'INACTIVE' AND l.archived = 'NO' THEN '⚠ NOT ARCHIVED'
        ELSE '❓ CHECK STATUS'
    END as log_health,
    CASE 
        WHEN l.status = 'INACTIVE' AND l.archived = 'NO' THEN 'Force log switch or check archiver'
        WHEN l.bytes < 100*1024*1024 THEN 'Consider larger redo log size for performance'
        ELSE 'Normal'
    END as recommendation
FROM v$log l
UNION ALL
SELECT 
    'STANDBY REDO LOGS' as log_type,
    sl.group#,
    sl.thread#,
    sl.sequence#,
    ROUND(sl.bytes/1024/1024, 2) as size_mb,
    NULL as members,
    sl.status,
    NULL as archived,
    CASE 
        WHEN sl.status = 'UNASSIGNED' THEN '✓ AVAILABLE'
        WHEN sl.status = 'ACTIVE' THEN '📥 RECEIVING REDO'
        ELSE '❓ ' || sl.status
    END as log_health,
    CASE 
        WHEN sl.bytes != (SELECT MAX(bytes) FROM v$log) THEN 'Standby redo log size should match online redo logs'
        ELSE 'Size matches online redo logs'
    END as recommendation
FROM v$standby_log sl
ORDER BY log_type, group#;

-- =====================================================
-- 6. ERROR DETECTION AND ANALYSIS
-- =====================================================

-- Recent Errors from Alert Log (12c+)
SELECT 
    TO_CHAR(originating_timestamp, 'YYYY-MM-DD HH24:MI:SS') as error_time,
    message_text,
    module_id,
    process_id,
    CASE 
        WHEN message_text LIKE '%ORA-00257%' THEN '💾 ARCHIVE DEST FULL'
        WHEN message_text LIKE '%ORA-16191%' THEN '🔄 PRIMARY LOG SHIPPING'
        WHEN message_text LIKE '%ORA-16401%' THEN '⚠ DATA GUARD CONFIG'
        WHEN message_text LIKE '%ORA-01034%' THEN '🔌 DATABASE UNAVAILABLE'
        WHEN message_text LIKE '%ORA-12541%' THEN '🌐 NETWORK ERROR'
        WHEN message_text LIKE '%ORA-16766%' THEN '⏹️ REDO APPLY STOPPED'
        WHEN message_text LIKE '%ORA-00600%' THEN '❌ INTERNAL ERROR'
        ELSE '❓ OTHER ERROR'
    END as error_category,
    CASE 
        WHEN message_text LIKE '%ORA-00257%' THEN 'Clear archive logs or expand storage'
        WHEN message_text LIKE '%ORA-16191%' THEN 'Check archive destination and network'
        WHEN message_text LIKE '%ORA-16766%' THEN 'Restart managed recovery'
        WHEN message_text LIKE '%ORA-01034%' THEN 'Check standby database availability'
        WHEN message_text LIKE '%ORA-12541%' THEN 'Check listener and network connectivity'
        ELSE 'Review Oracle documentation for specific error'
    END as suggested_action
FROM v$diag_alert_ext
WHERE originating_timestamp >= SYSDATE - 1  -- Last 24 hours
AND message_text LIKE '%ORA-%'
ORDER BY originating_timestamp DESC
FETCH FIRST 10 ROWS ONLY;

-- Data Guard Status Messages (Check for warnings/errors)
SELECT 
    TO_CHAR(timestamp, 'YYYY-MM-DD HH24:MI:SS') as message_time,
    severity,
    error_code,
    message,
    CASE severity
        WHEN 'Error' THEN '❌ ERROR'
        WHEN 'Warning' THEN '⚠ WARNING'
        WHEN 'Informational' THEN 'ℹ️ INFO'
        ELSE '❓ ' || severity
    END as alert_level,
    CASE 
        WHEN severity = 'Error' THEN 'Immediate investigation required'
        WHEN severity = 'Warning' THEN 'Monitor and plan corrective action'
        ELSE 'Review for trends'
    END as priority
FROM v$dataguard_status
WHERE timestamp >= SYSDATE - 1  -- Last 24 hours
ORDER BY timestamp DESC, severity DESC
FETCH FIRST 15 ROWS ONLY;

-- =====================================================
-- 7. NETWORK AND CONNECTIVITY CHECKS
-- =====================================================

-- Archive Transport Network Performance
SELECT 
    dest_id,
    dest_name,
    net_timeout,
    reopen_secs,
    max_failure,
    binding,
    CASE 
        WHEN net_timeout > 60 THEN '⚠ HIGH TIMEOUT: ' || net_timeout || 's'
        WHEN reopen_secs > 600 THEN '⚠ LONG REOPEN: ' || reopen_secs || 's'
        ELSE '✓ NORMAL TIMEOUTS'
    END as timeout_status,
    CASE 
        WHEN net_timeout > 60 THEN 'Consider reducing NET_TIMEOUT for faster failure detection'
        WHEN reopen_secs > 600 THEN 'Consider reducing REOPEN for faster reconnection'
        ELSE 'Timeouts within normal range'
    END as tuning_advice
FROM v$archive_dest 
WHERE status = 'VALID'
AND dest_id > 1;

-- =====================================================
-- 8. BACKUP AND RECOVERY READINESS
-- =====================================================

-- Backup Status for Data Guard Databases
SELECT 
    'CONTROLFILE BACKUP' as backup_type,
    TO_CHAR(MAX(completion_time), 'YYYY-MM-DD HH24:MI:SS') as last_backup,
    ROUND(SYSDATE - MAX(completion_time), 1) as days_old,
    CASE 
        WHEN MAX(completion_time) >= SYSDATE - 1 THEN '✓ RECENT'
        WHEN MAX(completion_time) >= SYSDATE - 7 THEN '⚡ AGING'
        ELSE '⚠ OLD BACKUP'
    END as backup_health
FROM v$backup_controlfile
UNION ALL
SELECT 
    'DATAFILE BACKUP' as backup_type,
    TO_CHAR(MAX(completion_time), 'YYYY-MM-DD HH24:MI:SS') as last_backup,
    ROUND(SYSDATE - MAX(completion_time), 1) as days_old,
    CASE 
        WHEN MAX(completion_time) >= SYSDATE - 1 THEN '✓ RECENT'
        WHEN MAX(completion_time) >= SYSDATE - 7 THEN '⚡ AGING'
        ELSE '⚠ OLD BACKUP'
    END as backup_health
FROM v$backup_datafile
WHERE file# = 1  -- Check system datafile as representative
UNION ALL
SELECT 
    'ARCHIVE LOG BACKUP' as backup_type,
    TO_CHAR(MAX(completion_time), 'YYYY-MM-DD HH24:MI:SS') as last_backup,
    ROUND(SYSDATE - MAX(completion_time), 1) as days_old,
    CASE 
        WHEN MAX(completion_time) >= SYSDATE - 1 THEN '✓ RECENT'
        WHEN MAX(completion_time) >= SYSDATE - 7 THEN '⚡ AGING'
        ELSE '⚠ OLD BACKUP'
    END as backup_health
FROM v$backup_archivelog
ORDER BY backup_type;

-- =====================================================
-- 9. CAPACITY PLANNING ALERTS
-- =====================================================

-- Redo Generation Trend Analysis
WITH hourly_redo AS (
    SELECT 
        TO_CHAR(first_time, 'YYYY-MM-DD HH24') as hour,
        SUM(blocks * block_size)/1024/1024/1024 as gb_generated
    FROM v$archived_log
    WHERE first_time >= SYSDATE - 7  -- Last 7 days
    AND resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
    GROUP BY TO_CHAR(first_time, 'YYYY-MM-DD HH24')
),
daily_avg AS (
    SELECT AVG(gb_generated) as avg_daily_gb
    FROM hourly_redo
)
SELECT 
    h.hour,
    ROUND(h.gb_generated, 2) as gb_generated,
    ROUND(d.avg_daily_gb, 2) as avg_daily_gb,
    ROUND((h.gb_generated / d.avg_daily_gb - 1) * 100, 1) as percent_variance,
    CASE 
        WHEN h.gb_generated > d.avg_daily_gb * 2 THEN '🔥 VERY HIGH: 200%+ of average'
        WHEN h.gb_generated > d.avg_daily_gb * 1.5 THEN '⚡ HIGH: 150%+ of average'
        WHEN h.gb_generated < d.avg_daily_gb * 0.5 THEN '💤 LOW: <50% of average'
        ELSE '✓ NORMAL: Within expected range'
    END as activity_assessment
FROM hourly_redo h, daily_avg d
WHERE h.hour >= TO_CHAR(SYSDATE - 1, 'YYYY-MM-DD HH24')  -- Last 24 hours
ORDER BY h.hour DESC;

-- =====================================================
-- 10. AUTOMATED DAILY HEALTH REPORT
-- =====================================================

-- Comprehensive Daily Health Summary
SELECT '=== ORACLE DATA GUARD DAILY HEALTH REPORT ===' as report_section FROM dual
UNION ALL
SELECT 'Report Generated: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM dual
UNION ALL
SELECT '================================================' FROM dual
UNION ALL
SELECT '1. DATABASE STATUS' FROM dual
UNION ALL
SELECT '   Role: ' || database_role || ' | Mode: ' || open_mode || ' | Protection: ' || protection_mode FROM v$database
UNION ALL
SELECT '2. CURRENT LAG STATUS' FROM dual
UNION ALL
SELECT '   ' || name || ': ' || value FROM v$dataguard_stats WHERE name IN ('transport lag', 'apply lag')
UNION ALL
SELECT '3. RECENT APPLY ACTIVITY' FROM dual
UNION ALL
SELECT '   Logs Applied (Last Hour): ' || COUNT(*) || ' logs' 
FROM v$archived_log 
WHERE applied = 'YES' 
AND completion_time >= SYSDATE - 1/24
AND resetlogs_change# = (SELECT resetlogs_change# FROM v$database)
UNION ALL
SELECT '4. SPACE UTILIZATION' FROM dual
UNION ALL
SELECT '   FRA Usage: ' || ROUND(space_used/space_limit*100, 1) || '%' 
FROM v$recovery_file_dest 
WHERE ROWNUM = 1
UNION ALL
SELECT '5. PROCESS STATUS' FROM dual
UNION ALL
SELECT '   ' || process || ': ' || status 
FROM v$managed_standby 
WHERE process IN ('MRP0', 'RFS') 
AND ROWNUM <= 3
UNION ALL
SELECT '6. RECENT ERRORS (Last 24h)' FROM dual
UNION ALL
SELECT '   Error Count: ' || COUNT(*) 
FROM v$diag_alert_ext
WHERE originating_timestamp >= SYSDATE - 1
AND message_text LIKE '%ORA-%'
UNION ALL
SELECT '================================================' FROM dual
UNION ALL
SELECT 'END OF REPORT' FROM dual;

-- =====================================================
-- 11. EMERGENCY TROUBLESHOOTING COMMANDS
-- =====================================================

-- Emergency Stop/Start Commands (Documentation)
/*
-- STOP APPLY PROCESS (Run on Standby)
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;

-- START APPLY PROCESS (Run on Standby)
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;

-- START REAL-TIME APPLY (Run on Standby)
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;

-- CLEAR LOG FILE (Emergency - Use with caution)
ALTER DATABASE CLEAR LOGFILE GROUP <group_number>;

-- RESTART ARCHIVE DESTINATION (Run on Primary)
ALTER SYSTEM LOG_ARCHIVE_DEST_STATE_<n>=DEFER;
ALTER SYSTEM LOG_ARCHIVE_DEST_STATE_<n>=ENABLE;

-- FORCE LOG SWITCH (Run on Primary)
ALTER SYSTEM SWITCH LOGFILE;

-- CHECK FOR CORRUPTION
SELECT * FROM v$database_block_corruption;

-- EMERGENCY BACKUP COMMAND
BACKUP DATABASE FORMAT '/backup_location/emergency_%d_%T_%s_%p.bkp';
*/

-- =====================================================
-- 12. QUICK REFERENCE - COMMON ISSUES AND SOLUTIONS
-- =====================================================

/*
QUICK TROUBLESHOOTING REFERENCE:

1. HIGH LAG ISSUES:
   - Transport Lag: Check network, archive destinations, redo generation rate
   - Apply Lag: Check MRP process, I/O performance, parallel apply settings
   
2. MRP NOT RUNNING:
   - ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
   
3. ARCHIVE DESTINATION ERRORS:
   - Check: v$archive_dest_status for specific error codes
   - Network: Test TNS connectivity
   - Space: Check archive destination space
   
4. SEQUENCE GAPS:
   - Query: v$archive_gap
   - Manual copy: Copy missing archive logs from primary
   - Auto resolution: Restart MRP process
   
5. SWITCHOVER ISSUES:
   - Check: switchover_status in v$database
   - Ensure: No active sessions (if required)
   - Verify: Archive log synchronization
   
6. PERFORMANCE PROBLEMS:
   - Monitor: Redo generation rate and apply rate
   - Tune: Archive destination parameters
   - Consider: Parallel apply, compression, faster networks

7. SPACE ISSUES:
   - Monitor: v$recovery_file_dest for FRA usage
   - Clean: Old archive logs (with caution)
   - Expand: Storage if needed

8. NETWORK ISSUES:
   - Test: TNS connectivity between sites
   - Check: Listener status and configuration
   - Monitor: Network timeout parameters
*/

-- =====================================================
-- END OF TROUBLESHOOTING SCRIPTS
-- =====================================================

-- USAGE INSTRUCTIONS:
-- 1. Run health checks daily during maintenance windows
-- 2. Monitor lag and performance metrics continuously
-- 3. Set up automated alerts for critical thresholds
-- 4. Keep emergency procedures readily available
-- 5. Document all changes and observations
-- 6. Test recovery procedures regularly
-- 7. Maintain baseline performance metrics for comparison****

-- 8. For 12c+ multitenant, ensure you're connected to the right container
-- 9. 21c PREPARE DATABASE command greatly simplifies initial setup
-- 10. 23c introduces significant observability improvements with new v$ views
