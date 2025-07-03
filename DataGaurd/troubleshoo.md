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
