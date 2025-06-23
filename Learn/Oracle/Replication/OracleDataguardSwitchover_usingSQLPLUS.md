# Standard Operating Procedure: Oracle Data Guard Switchover Using SQL*Plus

## 1. Purpose and Scope

### 1.1 Purpose
This Standard Operating Procedure (SOP) provides detailed instructions for performing a planned switchover between primary and standby databases in an Oracle Data Guard configuration using SQL*Plus commands. The procedure ensures minimal downtime and data integrity during role transitions.

### 1.2 Scope
This SOP applies to:
- Oracle Database 11.2.0.1 and later versions
- Oracle Database 12c (12.1 and 12.2)
- Physical standby database configurations
- Single instance and RAC environments
- All Oracle Cloud Infrastructure database services

### 1.3 Document References
- Oracle Support Document 1578787.1: "12c Data Guard Switchover Best Practices using SQLPLUS"
- Oracle Support Document 1304939.1: "11.2 Data Guard Physical Standby Switchover Best Practices using SQL*Plus"

## 2. Pre-requisites and Assumptions

### 2.1 Environment Requirements
- Oracle Database Enterprise Edition 11.2.0.1 or later
- Data Guard physical standby configuration properly established
- Network connectivity between primary and standby sites
- Sufficient archiver processes (LOG_ARCHIVE_MAX_PROCESSES ≥ 4)
- Compatible parameter set identically on primary and standby

### 2.2 Supported Configurations
- Single Instance to Single Instance
- RAC to RAC
- Single Instance to RAC
- RAC to Single Instance
- Container Database (CDB) environments (12c only)

### 2.3 Assumptions
- DBA has SYSDBA privileges on both primary and standby databases
- Alert logs and trace file locations are accessible
- No unresolved archive log gaps exist
- Standby database is synchronized with primary

### 2.4 Required Initialization Parameters
```sql
-- Verify on Primary
SQL> SHOW PARAMETER log_archive_config
SQL> SHOW PARAMETER log_archive_dest_2
SQL> SHOW PARAMETER log_archive_dest_state_2
SQL> SHOW PARAMETER compatible
```

## 3. Pre-Switchover Checks

### 3.1 Verify Data Guard Configuration Status

#### 3.1.1 Check Database Roles
```sql
-- On Primary
SQL> SELECT DB_UNIQUE_NAME, DATABASE_ROLE, OPEN_MODE FROM V$DATABASE;

-- On Standby
SQL> SELECT DB_UNIQUE_NAME, DATABASE_ROLE, OPEN_MODE FROM V$DATABASE;
```

#### 3.1.2 Verify Switchover Readiness (12c)
```sql
-- On Primary (12c only)
SQL> ALTER DATABASE SWITCHOVER TO <standby_db_unique_name> VERIFY;
```

**Note:** This command verifies release version, redo shipping, and MRP status. If successful, you'll see "Database altered."

### 3.2 Verify Log Transport and Apply Services

#### 3.2.1 Check Archive Destination Status
```sql
-- On Primary
SQL> SELECT DEST_ID, STATUS, ERROR, GAP_STATUS, SYNCHRONIZED 
     FROM V$ARCHIVE_DEST_STATUS 
     WHERE STATUS <> 'INACTIVE';
```

#### 3.2.2 Verify Managed Recovery Process
```sql
-- On Standby
SQL> SELECT PROCESS, STATUS, THREAD#, SEQUENCE# 
     FROM V$MANAGED_STANDBY 
     WHERE PROCESS LIKE 'MRP%';

-- For 12.2 and later use:
SQL> SELECT NAME, ROLE, THREAD#, SEQUENCE#, ACTION 
     FROM V$DATAGUARD_PROCESS;
```

#### 3.2.3 Check Real-Time Apply Status
```sql
-- On Primary
SQL> SELECT RECOVERY_MODE FROM V$ARCHIVE_DEST_STATUS WHERE DEST_ID=2;
```

Expected output: `MANAGED REAL TIME APPLY`

### 3.3 Check for Archive Log Gaps

#### 3.3.1 Identify Current Sequences
```sql
-- On Primary
SQL> SELECT THREAD#, MAX(SEQUENCE#) FROM V$LOG_HISTORY GROUP BY THREAD#;

-- On Standby
SQL> SELECT THREAD#, MAX(SEQUENCE#) 
     FROM V$ARCHIVED_LOG 
     WHERE APPLIED = 'YES' 
       AND RESETLOGS_CHANGE# = (SELECT RESETLOGS_CHANGE# 
                                FROM V$DATABASE_INCARNATION 
                                WHERE STATUS = 'CURRENT')
     GROUP BY THREAD#;
```

**Warning:** If gap > 3 sequences, resolve before proceeding.

### 3.4 Verify Online Redo Logs Status

#### 3.4.1 Check ORL Status on Standby
```sql
-- On Standby
SQL> SELECT DISTINCT L.GROUP# 
     FROM V$LOG L, V$LOGFILE LF
     WHERE L.GROUP# = LF.GROUP#
       AND L.STATUS NOT IN ('UNUSED', 'CLEARING', 'CLEARING_CURRENT');
```

#### 3.4.2 Clear Online Redo Logs if Needed
```sql
-- On Standby (if previous query returns rows)
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
SQL> ALTER DATABASE CLEAR LOGFILE GROUP <group_number>;
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;
```

### 3.5 Verify Tempfiles and Datafiles

#### 3.5.1 Compare Tempfiles
```sql
-- Run on both Primary and Standby
SQL> SELECT TMP.NAME FILENAME, BYTES, TS.NAME TABLESPACE
     FROM V$TEMPFILE TMP, V$TABLESPACE TS 
     WHERE TMP.TS#=TS.TS#
     ORDER BY TABLESPACE;
```

#### 3.5.2 Check Datafile Status
```sql
-- On Standby
SQL> SELECT NAME FROM V$DATAFILE WHERE STATUS='OFFLINE';
```

### 3.6 Check Switchover Status
```sql
-- On Primary
SQL> SELECT SWITCHOVER_STATUS FROM V$DATABASE;
```

Expected values: `TO STANDBY` or `SESSIONS ACTIVE`

## 4. Switchover Procedure

### 4.1 Enable Tracing (Optional but Recommended)
```sql
-- On both Primary and Standby
SQL> ALTER SYSTEM SET log_archive_trace=8191;
```

### 4.2 Cancel Apply Delay on Standby
```sql
-- On Standby
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE 
     USING CURRENT LOGFILE NODELAY DISCONNECT FROM SESSION;
```

### 4.3 Create Guaranteed Restore Points (Optional)
```sql
-- On Standby
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
SQL> CREATE RESTORE POINT SWITCHOVER_START_GRP GUARANTEE FLASHBACK DATABASE;
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;

-- On Primary
SQL> CREATE RESTORE POINT SWITCHOVER_START_GRP GUARANTEE FLASHBACK DATABASE;
```

### 4.4 Shutdown Secondary RAC Instances (If Applicable)
```sql
-- On all secondary primary instances
SQL> SHUTDOWN ABORT;
```

### 4.5 Initiate Switchover on Primary

#### 4.5.1 Verify Switchover Status
```sql
SQL> SELECT SWITCHOVER_STATUS FROM V$DATABASE;
```

#### 4.5.2 Execute Switchover Command
```sql
SQL> ALTER DATABASE COMMIT TO SWITCHOVER TO PHYSICAL STANDBY WITH SESSION SHUTDOWN;
```

**Note:** Monitor alert log for "Switchover: Complete - Database shutdown required"

### 4.6 Complete Switchover on Standby

#### 4.6.1 Verify Standby Received End-of-Redo
Check alert log for "Identified End-Of-Redo for thread X sequence Y"

#### 4.6.2 Check Switchover Status
```sql
SQL> SELECT SWITCHOVER_STATUS FROM V$DATABASE;
```

Expected: `TO PRIMARY` or `SESSIONS ACTIVE`

#### 4.6.3 Convert Standby to Primary
```sql
SQL> ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY WITH SESSION SHUTDOWN;
```

#### 4.6.4 Open New Primary Database
```sql
SQL> ALTER DATABASE OPEN;
```

### 4.7 Restart New Standby Database

#### 4.7.1 Shutdown and Mount
```sql
-- On new standby (former primary)
SQL> SHUTDOWN ABORT;
SQL> STARTUP MOUNT;
```

#### 4.7.2 Start Managed Recovery
```sql
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;
```

### 4.8 Update Oracle Clusterware (RAC Only)
```bash
# On new primary
srvctl modify database -db <db_unique_name> -role PRIMARY

# On new standby
srvctl modify database -db <db_unique_name> -role PHYSICAL_STANDBY
```

## 5. Post-Switchover Validation

### 5.1 Confirm Role Transition
```sql
-- On both databases
SQL> SELECT DB_UNIQUE_NAME, DATABASE_ROLE, OPEN_MODE FROM V$DATABASE;
```

### 5.2 Validate Log Shipping

#### 5.2.1 Force Log Switch
```sql
-- On new primary
SQL> ALTER SYSTEM SWITCH LOGFILE;
```

#### 5.2.2 Verify Archive Destination
```sql
-- On new primary
SQL> SELECT DEST_ID, ERROR, STATUS 
     FROM V$ARCHIVE_DEST_STATUS 
     WHERE DEST_ID=2;
```

### 5.3 Validate Apply Process
```sql
-- On new standby
SQL> SELECT THREAD#, SEQUENCE#, PROCESS, STATUS 
     FROM V$MANAGED_STANDBY;

-- Verify applied logs
SQL> SELECT MAX(SEQUENCE#), THREAD# 
     FROM V$ARCHIVED_LOG 
     WHERE APPLIED='YES' 
     GROUP BY THREAD#;
```

### 5.4 Reset Trace Level
```sql
-- On both databases
SQL> ALTER SYSTEM SET log_archive_trace=0;
```

### 5.5 Re-enable Jobs
```sql
-- On new standby
SQL> ALTER SYSTEM SET job_queue_processes=<original_value> SCOPE=BOTH;
```

### 5.6 Drop Guaranteed Restore Points
```sql
-- On both databases (if created)
SQL> DROP RESTORE POINT SWITCHOVER_START_GRP;
```

## 6. Troubleshooting and Recovery

### 6.1 Common Issues and Solutions

#### 6.1.1 ORA-16470: Redo Apply is not running
**Solution:**
```sql
-- On standby
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
SQL> ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;
```

#### 6.1.2 ORA-16475: Succeeded with warnings
**Check alert log for specific warnings:**
- Dirty online redo logs: Set LOG_FILE_NAME_CONVERT properly
- No standby destinations defined: Configure LOG_ARCHIVE_DEST_n on standby

#### 6.1.3 ORA-16139: Media recovery required
**Solution:** Start managed recovery on the affected database

#### 6.1.4 UNRESOLVABLE GAP Status
**Solution:**
```sql
-- Check for closed threads
SQL> SELECT thread#, instance, status FROM v$thread;
SQL> ALTER DATABASE DISABLE THREAD <n>; -- For CLOSED threads

-- Verify archive destinations
SQL> SHOW PARAMETER log_archive_dest
```

### 6.2 Diagnostic Queries

#### 6.2.1 Check Data Guard Status
```sql
-- Comprehensive status check
SQL> SELECT DB_UNIQUE_NAME, DATABASE_ROLE, PROTECTION_MODE, 
            PROTECTION_LEVEL, OPEN_MODE, SWITCHOVER_STATUS
     FROM V$DATABASE;
```

#### 6.2.2 Monitor Apply Lag
```sql
-- On standby
SQL> SELECT NAME, VALUE, UNIT FROM V$DATAGUARD_STATS 
     WHERE NAME IN ('transport lag', 'apply lag');
```

### 6.3 Alert Log Analysis
```bash
# Locate alert log
SQL> SHOW PARAMETER background_dump_dest

# Monitor in real-time
tail -f <background_dump_dest>/alert_<SID>.log
```

## 7. Rollback Plan

### 7.1 Switchover Failure Before Primary Conversion

If switchover fails before primary is converted to standby:
1. Cancel the switchover operation
2. Verify primary is still in PRIMARY role
3. Restart services and applications
4. Investigate root cause in alert logs

### 7.2 Switchover Failure After Primary Conversion

#### 7.2.1 Using Flashback Database (if GRP created)
```sql
-- On both databases
SQL> SHUTDOWN IMMEDIATE;
SQL> STARTUP MOUNT;
SQL> FLASHBACK DATABASE TO RESTORE POINT SWITCHOVER_START_GRP;
SQL> ALTER DATABASE OPEN RESETLOGS;
```

#### 7.2.2 Manual Recovery Method
1. Start the original primary in MOUNT mode
2. Start managed recovery
3. Let it catch up with current primary
4. Perform another switchover to restore original roles

### 7.3 Verification After Rollback
```sql
-- Verify database roles
SQL> SELECT DB_UNIQUE_NAME, DATABASE_ROLE FROM V$DATABASE;

-- Check Data Guard configuration
SQL> SELECT * FROM V$DATAGUARD_CONFIG;
```

## 8. Appendix

### 8.1 SQL*Plus Command Reference

#### Key Commands for Switchover
```sql
-- Switchover commands
ALTER DATABASE SWITCHOVER TO <db_unique_name> VERIFY;  -- 12c only
ALTER DATABASE COMMIT TO SWITCHOVER TO PHYSICAL STANDBY [WITH SESSION SHUTDOWN];
ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY [WITH SESSION SHUTDOWN];

-- Recovery commands
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT; -- Without real-time apply

-- Diagnostic views
V$DATABASE
V$DATAGUARD_CONFIG
V$DATAGUARD_STATS
V$MANAGED_STANDBY
V$ARCHIVE_DEST_STATUS
V$ARCHIVED_LOG
```

### 8.2 Log File Locations

#### Alert Log Location
```sql
-- 11g
SQL> SHOW PARAMETER background_dump_dest

-- 12c and later
SQL> SELECT VALUE FROM V$DIAG_INFO WHERE NAME = 'Diag Trace';
```

#### Trace Files
- Pattern: `<instance_name>_mrp*.trc` for managed recovery process traces
- Location: Same as alert log directory

### 8.3 Key Differences Between 11.2 and 12c

| Feature | 11.2 | 12c |
|---------|------|-----|
| Switchover Verify | Not available | `ALTER DATABASE SWITCHOVER TO <name> VERIFY` |
| V$MANAGED_STANDBY | Primary view | Deprecated in 12.2 |
| V$DATAGUARD_PROCESS | Not available | Available in 12.2+ |
| CDB Switchover | N/A | Switchover at CDB level only |
| MRP Behavior | Stops after EOR | Continues running after EOR |
| Automatic ORL Clear | Manual process | Automatic with proper configuration |

### 8.4 Best Practices

1. **Always perform pre-switchover checks** - Never skip verification steps
2. **Monitor alert logs** - Keep alert logs open during switchover
3. **Test in non-production** - Practice switchover procedures regularly
4. **Document environment** - Maintain current documentation of configuration
5. **Plan maintenance window** - Allow sufficient time for switchover and validation
6. **Backup before switchover** - Ensure recent backups exist
7. **Coordinate with stakeholders** - Notify all affected parties before switchover

### 8.5 External References

- Oracle Data Guard Concepts and Administration Guide
- My Oracle Support (MOS) - https://support.oracle.com
- Oracle Documentation - https://docs.oracle.com
- MOS Note 1288640.1 - Managed Recovery Fails After Upgrade
- MOS Note 1305019.1 - Data Guard Broker Switchover Best Practices

---

**Document Version:** 1.0  
**Last Updated:** Based on Oracle Support Documents 1578787.1 and 1304939.1  
**Approval:** _________________________  
**Date:** _________________________
