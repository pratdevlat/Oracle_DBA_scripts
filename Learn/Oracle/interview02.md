# Oracle DBA Interview Questions & Answers

## 150 Scenario-Based Questions for 10+ Years Experienced DBAs

### **Section 1: Oracle Architecture & Internals (1-25)**

**1. You notice SGA_TARGET is set to 8GB but total SGA components show 12GB. What’s happening and how do you resolve it?**

**Answer:** This indicates manual sizing of SGA components that exceed the SGA_TARGET. Oracle won’t shrink manually sized components below their set values. Resolution:

- Check individual component sizes: `SELECT component, current_size FROM v$sga_dynamic_components;`
- Either increase SGA_TARGET or set individual components to 0 to allow automatic management
- Use `ALTER SYSTEM SET sga_target=12G` or `ALTER SYSTEM SET shared_pool_size=0`

**2. During a critical production issue, you find that background process PMON has died. What are your immediate actions?**

**Answer:**

- Check alert log for PMON death reason
- Oracle instance will automatically restart PMON, but if it keeps dying:
- Identify root cause (memory corruption, OS issues, bugs)
- If instance becomes unstable, perform controlled shutdown and startup
- Check for memory leaks: `SELECT * FROM v$process WHERE background = 1`
- Apply emergency patches if it’s a known Oracle bug

**3. Explain the complete process flow when a user executes SELECT statement that requires physical I/O.**

**Answer:**

1. **Parse Phase:** Check shared pool for existing parsed statement
1. **Optimization:** CBO generates execution plan using statistics
1. **Row Source Generation:** Creates row source tree
1. **Execution:**
- Check buffer cache for required blocks
- If not found, server process issues I/O request to DBWR
- DBWR reads from datafiles into buffer cache
- Data returned through row sources to client
1. **Fetch:** Results returned to user process via SQL*Net

**4. Your database is showing high ‘log file sync’ waits but redo log files are on fast SSD. What could be the issue?**

**Answer:**

- **Possible causes:**
  - Application issuing too frequent commits
  - LGWR process not getting enough CPU
  - Network latency between client and database
  - OS I/O scheduler issues
- **Diagnosis:**
  - Check commit frequency: `SELECT name, value FROM v$sysstat WHERE name LIKE '%commit%'`
  - Monitor LGWR: `SELECT * FROM v$osstat WHERE stat_name LIKE '%CPU%'`
- **Solutions:** Batch commits, tune network, adjust OS I/O scheduler

**5. How do you handle a situation where TEMP tablespace is full during a critical batch job?**

**Answer:**

```sql
-- Immediate actions:
-- 1. Check current usage
SELECT tablespace_name, sum(bytes_used)/1024/1024 MB_USED, 
       sum(bytes_free)/1024/1024 MB_FREE
FROM v$temp_space_header;

-- 2. Add temporary tempfile immediately
ALTER TABLESPACE temp ADD TEMPFILE '/path/temp02.dbf' SIZE 5G AUTOEXTEND ON;

-- 3. Identify sessions using most temp space
SELECT s.sid, s.username, t.blocks * 8192/1024/1024 MB_USED
FROM v$session s, v$tempseg_usage t
WHERE s.saddr = t.session_addr
ORDER BY t.blocks DESC;

-- 4. Long-term: Resize temp tablespace and tune queries
```

**6. Describe the internal working of Oracle’s checkpoint mechanism.**

**Answer:**

- **Triggered by:** Log switches, timeout (every 3 seconds), manual checkpoint, shutdown
- **Process:**
1. CKPT process signals DBWR to write dirty buffers
1. DBWR writes changed blocks from buffer cache to datafiles
1. CKPT updates datafile headers with SCN
1. CKPT updates control file with checkpoint information
- **Types:** Complete, incremental, parallel
- **Monitoring:** `SELECT * FROM v$instance_recovery` for checkpoint progress

**7. You’re seeing ‘cursor: pin S wait on X’ events. Explain the cause and resolution.**

**Answer:**

- **Cause:** Hard parsing of SQL statements causing library cache contention
- **Root causes:**
  - Not using bind variables (literal SQL)
  - Version count explosion
  - Insufficient shared pool size
- **Resolution:**

```sql
-- Identify problematic SQL
SELECT sql_text, version_count, loads, invalidations 
FROM v$sqlarea WHERE version_count > 20;

-- Solutions:
-- 1. Implement bind variables
-- 2. Increase shared_pool_size
-- 3. Use CURSOR_SHARING=FORCE (temporary)
-- 4. Pin frequently used packages
```

**8. Explain Oracle’s read consistency mechanism and how it handles long-running queries.**

**Answer:**

- **Read Consistency:** Oracle provides statement-level read consistency using undo data
- **Mechanism:**
1. When query starts, Oracle notes current SCN
1. For any block modified after query start, Oracle reconstructs original image using undo
1. Long queries may get “snapshot too old” if undo is overwritten
- **Parameters:** UNDO_RETENTION, UNDO_TABLESPACE sizing
- **Monitoring:** `SELECT * FROM v$undostat` for undo usage patterns

**9. How does Oracle handle deadlock detection and resolution?**

**Answer:**

- **Detection:** PMON process checks for deadlocks every 3 seconds
- **Algorithm:** Waits-for graph analysis to detect circular dependencies
- **Resolution:**
  - Oracle chooses victim (usually session with least undo)
  - Rolls back victim’s statement
  - Other sessions proceed
- **Monitoring:** Check alert log for deadlock graphs
- **Prevention:** Consistent locking order in applications

**10. Describe Oracle’s automatic memory management and its limitations.**

**Answer:**

- **AMM:** MEMORY_TARGET manages total memory (SGA + PGA)
- **ASMM:** SGA_TARGET manages only SGA components
- **Limitations:**
  - Cannot be used with HugePages on Linux
  - Some components have minimum sizes
  - May not be optimal for specialized workloads
- **Best Practices:** Use ASMM for most environments, manual for performance-critical systems

**11. Your production database crashed with ORA-00600. Walk through your diagnosis approach.**

**Answer:**

```sql
-- 1. Check alert log for complete error stack
-- 2. Look for dump files in DIAGNOSTIC_DEST
-- 3. Search My Oracle Support for the specific ORA-600 arguments
-- 4. Check for:
SELECT * FROM v$diag_problem;  -- Automatic diagnostic info
-- 5. Generate support bundle if needed
-- 6. Apply emergency patches if available
-- 7. If data corruption, use RMAN to restore/recover affected datafiles
```

**12. Explain the difference between library cache pin and library cache lock waits.**

**Answer:**

- **Library Cache Pin:** Waiting to pin object in shared mode (reading)
- **Library Cache Lock:** Waiting to lock object in exclusive mode (compilation/DDL)
- **Causes:**
  - Pin: High hard parsing, version count issues
  - Lock: DDL operations on heavily used objects, package compilation
- **Resolution:** Use bind variables, schedule DDL during low usage, pin packages

**13. How do you handle a situation where control file is corrupted in RAC environment?**

**Answer:**

```sql
-- 1. Shutdown all instances immediately
-- 2. Restore control file from backup or recreate:
RMAN> RESTORE CONTROLFILE FROM AUTOBACKUP;
-- Or recreate using trace:
-- 3. Mount database on one node
STARTUP MOUNT;
-- 4. Recover if necessary
RECOVER DATABASE;
-- 5. Open database
ALTER DATABASE OPEN RESETLOGS;
-- 6. Start other RAC instances
-- 7. Recreate standby control files if Data Guard is configured
```

**14. Describe Oracle’s block checking mechanisms and when to use them.**

**Answer:**

- **DB_BLOCK_CHECKING:** Checks block consistency during DML (FULL, MEDIUM, LOW)
- **DB_BLOCK_CHECKSUM:** Adds checksum to detect I/O corruption (TYPICAL, FULL)
- **Usage:**
  - CHECKSUM: Always enable TYPICAL in production
  - CHECKING: Use MEDIUM for critical systems (5-10% overhead)
- **Detection:** Corrupted blocks logged in alert log and v$database_block_corruption

**15. Your database is experiencing high CPU usage but wait events show mostly CPU time. How do you proceed?**

**Answer:**

```sql
-- 1. Check top SQL by CPU usage
SELECT sql_id, cpu_time/1000000 cpu_seconds, executions
FROM v$sql ORDER BY cpu_time DESC;

-- 2. Analyze execution plans for CPU-intensive operations
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR('sql_id'));

-- 3. Check for:
-- - Missing indexes causing full table scans
-- - Inefficient joins (nested loops on large sets)
-- - PL/SQL loops processing large datasets
-- - Recursive SQL from dictionary queries

-- 4. Use ASH to identify CPU hotspots
SELECT sql_id, count(*) FROM v$active_session_history 
WHERE session_state = 'ON CPU' GROUP BY sql_id;
```

**16. Explain Oracle’s undo retention guarantee and its implications.**

**Answer:**

- **Guarantee:** When RETENTION GUARANTEE is set, Oracle never overwrites unexpired undo
- **Implications:**
  - DML may fail with “unable to extend” if undo tablespace is full
  - Undo tablespace must be sized for longest query + retention period
  - Use with caution in OLTP systems
- **Monitoring:** `SELECT retention, tuned_undoretention FROM dba_hist_undostat`
- **Alternative:** Use RETENTION NOGUARANTEE with proper sizing

**17. How do you troubleshoot ORA-01555 “snapshot too old” errors?**

**Answer:**

- **Causes:**
1. Insufficient undo retention
1. Small undo tablespace
1. High DML activity overwriting undo
1. Delayed block cleanout
- **Solutions:**

```sql
-- Increase undo retention
ALTER SYSTEM SET undo_retention = 3600;

-- Check undo usage patterns
SELECT begin_time, end_time, undoblks, maxquerylen 
FROM v$undostat ORDER BY begin_time DESC;

-- Add undo space if needed
ALTER TABLESPACE undotbs1 ADD DATAFILE 'undo02.dbf' SIZE 2G;

-- For delayed block cleanout: Enable INITRANS properly
```

**18. Describe the complete Oracle startup process from OS level to database open.**

**Answer:**

1. **OS Level:** Oracle binaries loaded, shared memory allocated
1. **NOMOUNT:**
- Background processes started (PMON, SMON, DBWR, LGWR, CKPT)
- SGA allocated and initialized
- Control file location read from parameter file
1. **MOUNT:**
- Control files opened and read
- Database structure information loaded
- Datafile and redo log locations identified
1. **OPEN:**
- Datafiles opened
- Redo logs opened for recovery if needed
- Dictionary cache loaded
- Database available for users

**19. You notice that SMON process is consuming high CPU. What could be the reasons?**

**Answer:**

- **Possible Causes:**
1. Large number of temporary segments to clean up
1. Dictionary cache cleanup after heavy DDL
1. Space management in locally managed tablespaces
1. Coalescing free space in dictionary-managed tablespaces
- **Investigation:**

```sql
-- Check temporary segment usage
SELECT tablespace_name, count(*) FROM dba_segments 
WHERE segment_type LIKE '%TEMPORARY%' GROUP BY tablespace_name;

-- Monitor SMON activity
SELECT * FROM v$sysstat WHERE name LIKE '%smon%';
```

**20. Explain Oracle’s adaptive cursor sharing and its impact on performance.**

**Answer:**

- **Purpose:** Handle bind variable peeking issues by creating multiple child cursors
- **Mechanism:**
1. Oracle monitors execution statistics for different bind values
1. Creates new child cursor if performance varies significantly
1. Marks cursor as bind-sensitive and bind-aware
- **Impact:**
  - Positive: Better plans for different data distributions
  - Negative: Increased memory usage, potential cursor explosion
- **Management:** Monitor version_count in v$sql, use SQL Plan Baselines

**21. How do you handle ora-00257 “archiver stuck” error during production hours?**

**Answer:**

```sql
-- Immediate actions (do NOT delete archive logs without backup):
-- 1. Check archive destination space
SELECT dest_name, status, error FROM v$archive_dest;

-- 2. Free up space in archive destination or add new destination
ALTER SYSTEM SET log_archive_dest_2='LOCATION=/new/archive/path';

-- 3. If FRA is full:
SELECT space_limit/1024/1024/1024 GB_LIMIT, 
       space_used/1024/1024/1024 GB_USED 
FROM v$recovery_file_dest;

-- Increase FRA size temporarily
ALTER SYSTEM SET db_recovery_file_dest_size=50G;

-- 4. Backup and remove old archives
RMAN> BACKUP ARCHIVELOG ALL DELETE INPUT;
```

**22. Describe Oracle’s Data Guard FSFO (Fast-Start Failover) decision-making process.**

**Answer:**

- **Observer Role:** Monitors primary and standby databases
- **Decision Process:**
1. Observer detects primary database failure
1. Checks if conditions for automatic failover are met:
  - FastStartFailoverThreshold exceeded
  - Standby database is synchronized
  - No user connections on primary (if configured)
1. Initiates failover to standby database
1. Reinstate old primary as standby when available
- **Configuration:** FastStartFailoverTarget, FastStartFailoverThreshold

**23. How do you diagnose and resolve shared pool fragmentation?**

**Answer:**

```sql
-- Diagnose fragmentation
SELECT pool, name, bytes FROM v$sgastat 
WHERE pool = 'shared pool' ORDER BY bytes DESC;

-- Check free memory chunks
SELECT chunk_size, free_space FROM v$shared_pool_reserved;

-- Solutions:
-- 1. Pin large packages during startup
EXEC DBMS_SHARED_POOL.KEEP('PACKAGE_NAME');

-- 2. Use shared pool reserved area
ALTER SYSTEM SET shared_pool_reserved_size=50M;

-- 3. Increase shared pool size
ALTER SYSTEM SET shared_pool_size=1G;

-- 4. Flush shared pool during maintenance window
ALTER SYSTEM FLUSH SHARED_POOL;
```

**24. Explain the role of MMON and MMNL background processes.**

**Answer:**

- **MMON (Manageability Monitor):**
  - Captures AWR snapshots every hour
  - Writes ASH data from memory to disk
  - Performs space management for AWR repository
  - Issues alerts for metrics threshold violations
- **MMNL (Manageability Monitor Lite):**
  - Writes ASH data to disk when buffer is full
  - Works with MMON for continuous ASH data capture
- **Monitoring:** Check DBA_HIST_SNAPSHOT for AWR collection health

**25. How do you handle a situation where database hangs and you cannot connect?**

**Answer:**

```bash
# 1. Try connecting as SYSDBA locally
export ORACLE_SID=PRODDB
sqlplus / as sysdba

# 2. If that fails, use ORADEBUG to diagnose
sqlplus -prelim / as sysdba
oradebug setmypid
oradebug hanganalyze 3
oradebug systemstate 266

# 3. Check OS level
ps -ef | grep oracle
ipcs -m  # Check shared memory

# 4. If needed, kill Oracle processes
oradebug setorapid <process_id>
oradebug suspend

# 5. Last resort: shutdown abort
shutdown abort
startup
```

### **Section 2: Backup, Recovery & Data Guard (26-50)**

**26. During RMAN backup, you get “ORA-19809: limit exceeded for recovery files”. How do you resolve without losing backup history?**

**Answer:**

```sql
-- 1. Check FRA usage
SELECT space_limit/1024/1024/1024 GB_LIMIT, 
       space_used/1024/1024/1024 GB_USED,
       number_of_files FROM v$recovery_file_dest;

-- 2. Temporary increase FRA size
ALTER SYSTEM SET db_recovery_file_dest_size=100G;

-- 3. Clean up obsolete backups
RMAN> DELETE OBSOLETE;

-- 4. Move older backups to different location
RMAN> BACKUP BACKUPSET ALL FORMAT '/backup/location/backup_%s_%p_%t';
RMAN> DELETE BACKUPSET tag='old_backups';

-- 5. Adjust retention policy if needed
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
```

**27. Your standby database is lagging by 6 hours. Walk through your troubleshooting approach.**

**Answer:**

```sql
-- 1. Check archive gap on primary
SELECT thread#, low_sequence#, high_sequence# 
FROM v$archive_gap;

-- 2. Check transport service on primary
SELECT dest_name, status, error FROM v$archive_dest_status;

-- 3. Check apply service on standby
SELECT process, status, thread#, sequence# FROM v$managed_standby;

-- 4. Check for apply delays
SELECT name, value FROM v$dataguard_stats 
WHERE name = 'apply lag';

-- 5. Resolve issues:
-- - Network: Check connectivity, bandwidth
-- - Apply: Increase parallelism
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE PARALLEL 4;
-- - Transport: Fix archive destination issues
```

**28. You need to perform point-in-time recovery to yesterday 2 PM, but you discover archive log from yesterday 1 PM is missing. What are your options?**

**Answer:**

```sql
-- Options in order of preference:
-- 1. Check for the missing archive log in all possible locations
SELECT name FROM v$archived_log WHERE sequence# = <missing_seq>;

-- 2. If available, restore from standby database
-- On standby: Copy the archive log to primary location

-- 3. Perform incomplete recovery to last available archive log
RMAN> RUN {
  SET UNTIL SEQUENCE <last_available_seq>;
  RESTORE DATABASE;
  RECOVER DATABASE;
  ALTER DATABASE OPEN RESETLOGS;
}

-- 4. If critical data loss, check for:
-- - Flashback Database (if enabled)
-- - Export dumps from before the issue
-- - Logical standby for data extraction
```

**29. Describe your approach to validate RMAN backup integrity before a major upgrade.**

**Answer:**

```sql
-- 1. Test backup validity
RMAN> VALIDATE BACKUPSET <backupset_number>;
RMAN> VALIDATE DATABASE;

-- 2. Test restore to alternate location
RMAN> RUN {
  SET NEWNAME FOR DATABASE TO '/test/location/%b';
  RESTORE DATABASE;
  SWITCH DATABASE TO COPY;
  RECOVER DATABASE;
  ALTER DATABASE OPEN RESETLOGS;
}

-- 3. Validate archive log backups
RMAN> VALIDATE ARCHIVELOG ALL;

-- 4. Check backup catalog consistency
RMAN> CROSSCHECK BACKUP;
RMAN> CROSSCHECK ARCHIVELOG ALL;

-- 5. Document recovery procedures
-- Create step-by-step recovery scripts
```

**30. How do you handle block corruption detected during backup?**

**Answer:**

```sql
-- 1. Identify corrupted blocks
SELECT file#, block#, blocks, corruption_type 
FROM v$database_block_corruption;

-- 2. For data blocks - use RMAN block recovery
RMAN> RECOVER DATAFILE 4 BLOCK 123, 124;

-- 3. For index blocks - rebuild index
ALTER INDEX index_name REBUILD;

-- 4. If RMAN backup also corrupt, use alternate methods:
-- - Restore from older backup
-- - Use Data Pump export if logical corruption
-- - Extract data using ROWID ranges avoiding corrupt blocks

-- 5. Investigate root cause
-- Check hardware, storage, memory issues
```

**31. Your Data Guard environment needs a rolling upgrade. Describe the complete process.**

**Answer:**

```sql
-- Phase 1: Upgrade Physical Standby
-- 1. Stop redo apply on standby
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;

-- 2. Shutdown standby database
SHUTDOWN IMMEDIATE;

-- 3. Upgrade Oracle software on standby server
-- Install new Oracle version

-- 4. Upgrade standby database
STARTUP UPGRADE;
@catupgrd.sql

-- Phase 2: Switchover
-- 5. Switchover to upgraded standby
-- On Primary:
ALTER DATABASE COMMIT TO SWITCHOVER TO PHYSICAL STANDBY;
-- On Standby (now Primary):
ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY;

-- Phase 3: Upgrade Old Primary (now Standby)
-- 6. Repeat upgrade process on old primary
-- 7. Start redo apply
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT;
```

**32. RMAN backup is failing with “ORA-27072: File I/O error”. How do you troubleshoot?**

**Answer:**

```bash
# 1. Check OS level errors
dmesg | grep -i error
tail -f /var/log/messages

# 2. Check file system space and permissions
df -h /backup/location
ls -la /backup/location

# 3. Test file system I/O
dd if=/dev/zero of=/backup/location/test bs=1M count=100

# 4. Check Oracle file permissions
ls -la $ORACLE_HOME/dbs

# 5. RMAN diagnostics
RMAN> SHOW ALL;
RMAN> CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/alternate/path/%U';

# 6. If hardware issue, move backup to different storage
RMAN> CONFIGURE CHANNEL DEVICE TYPE DISK CONNECT 'sys/password@remote_db';
```

**33. How do you perform disaster recovery when both primary and standby databases are lost, but you have RMAN backups?**

**Answer:**

```sql
-- 1. Setup new hardware/OS environment
-- 2. Install Oracle software (same version as backup)
-- 3. Restore SPFILE
RMAN> SET DBID <database_id>;
RMAN> RESTORE SPFILE FROM AUTOBACKUP;

-- 4. Start instance in NOMOUNT
STARTUP NOMOUNT;

-- 5. Restore control file
RMAN> RESTORE CONTROLFILE FROM AUTOBACKUP;
ALTER DATABASE MOUNT;

-- 6. Catalog all backup pieces if needed
RMAN> CATALOG START WITH '/backup/location/';

-- 7. Restore and recover database
RMAN> RESTORE DATABASE;
RMAN> RECOVER DATABASE;
ALTER DATABASE OPEN RESETLOGS;

-- 8. Validate database integrity
SELECT COUNT(*) FROM dba_objects WHERE status = 'INVALID';
```

**34. Explain the difference between RESETLOGS and NORESETLOGS recovery scenarios.**

**Answer:**

- **RESETLOGS Required:**
  - Incomplete recovery (point-in-time)
  - Recovery with backup control file
  - Recovery after opening with RESETLOGS previously
  - Creates new incarnation, resets log sequence to 1
- **NORESETLOGS (Complete Recovery):**
  - All redo applied up to current time
  - No data loss
  - Continues with existing log sequence
- **Implications of RESETLOGS:**
  - Previous backups become unusable
  - New backup strategy needed immediately
  - Standby database needs recreation

**35. How do you handle archive log shipping failure in Data Guard due to network issues?**

**Answer:**

```sql
-- 1. Check network connectivity
-- On primary: tnsping standby_service

-- 2. Check archive destination status
SELECT dest_name, status, error FROM v$archive_dest_status;

-- 3. Enable archive log gap resolution
-- On standby:
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT;

-- 4. Manual archive log transfer if needed
-- Copy missing logs manually and register
ALTER DATABASE REGISTER LOGFILE '/path/to/archive/log';

-- 5. Configure multiple archive destinations for redundancy
ALTER SYSTEM SET log_archive_dest_2='SERVICE=standby1 ASYNC';
ALTER SYSTEM SET log_archive_dest_3='SERVICE=standby2 ASYNC';

-- 6. Enable automatic gap resolution
ALTER SYSTEM SET log_archive_dest_state_2=ENABLE;
```

**36. Your RMAN catalog database is corrupted. How do you recover RMAN metadata?**

**Answer:**

```sql
-- 1. If catalog database is recoverable:
RMAN TARGET / CATALOG rman/password@catalog_db
RMAN> RECOVER CATALOG;

-- 2. If catalog database is lost, recreate from control file:
-- Create new catalog database
RMAN> CREATE CATALOG;

-- Resync from all target databases
RMAN TARGET / CATALOG rman/password@new_catalog
RMAN> RESYNC CATALOG;

-- 3. If control file info is also lost:
-- Use LIST and CROSSCHECK commands to rebuild metadata
RMAN> CROSSCHECK BACKUP;
RMAN> CROSSCHECK ARCHIVELOG ALL;

-- 4. Catalog external backups if needed
RMAN> CATALOG START WITH '/backup/location/';
```

**37. How do you implement and test a backup strategy for a 24x7 OLTP system?**

**Answer:**

```sql
-- 1. Design strategy:
-- Daily incremental level 1 backups
-- Weekly level 0 backup during maintenance window
-- Archive log backups every 15 minutes
-- Block change tracking for faster incrementals

-- 2. Implementation:
-- Enable block change tracking
ALTER DATABASE ENABLE BLOCK CHANGE TRACKING;

-- Configure RMAN settings
RMAN> CONFIGURE BACKUP OPTIMIZATION ON;
RMAN> CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
RMAN> CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;

-- 3. Backup scripts:
-- Daily incremental:
BACKUP INCREMENTAL LEVEL 1 DATABASE PLUS ARCHIVELOG DELETE INPUT;

-- 4. Testing:
-- Monthly restore tests to different server
-- Document RTO/RPO measurements
-- Validate backup integrity regularly
```

**38. Describe your approach to migrate a large database (5TB+) with minimal downtime using Data Guard.**

**Answer:**

```sql
-- Phase 1: Setup Physical Standby
-- 1. Create standby database on target system
-- Use RMAN duplicate or manual setup

-- 2. Configure Data Guard
-- Primary:
ALTER SYSTEM SET log_archive_dest_2='SERVICE=standby ASYNC';

-- Phase 2: Minimize Downtime
-- 3. Keep standby synchronized
-- Monitor apply lag: SELECT value FROM v$dataguard_stats WHERE name = 'apply lag';

-- 4. During maintenance window:
-- Switch over to standby (becomes new primary)
ALTER DATABASE COMMIT TO SWITCHOVER TO PHYSICAL STANDBY;

-- 5. Redirect applications to new primary
-- Update connection strings/DNS

-- 6. Old primary becomes standby or decommissioned
-- Total downtime: 15-30 minutes for large databases
```

**39. How do you recover from a situation where all online redo logs are corrupted?**

**Answer:**

```sql
-- This is a serious situation requiring incomplete recovery:

-- 1. Shutdown database immediately if still running
SHUTDOWN ABORT;

-- 2. Startup mount and check damage
STARTUP MOUNT;
SELECT group#, status FROM v$log;

-- 3. If all log groups corrupted, perform point-in-time recovery
RMAN> RUN {
  SET UNTIL SCN <scn_before_corruption>;
  RESTORE DATABASE;
  RECOVER DATABASE;
  ALTER DATABASE OPEN RESETLOGS;
}

-- 4. If some logs readable, try:
RECOVER DATABASE USING BACKUP CONTROLFILE UNTIL CANCEL;
-- Apply available logs, then CANCEL and OPEN RESETLOGS

-- 5. Post-recovery actions:
-- Full backup immediately
-- Recreate standby databases
-- Validate data integrity
```

**40. How do you handle RMAN-03002 “failure during compilation of command” errors?**

**Answer:**

```sql
-- 1. Check RMAN command syntax
-- Validate script for proper RMAN syntax

-- 2. Check database connectivity
RMAN> SHOW ALL;
RMAN> LIST BACKUP SUMMARY;

-- 3. Common causes and solutions:
-- - Invalid file paths: Check file system permissions
-- - Insufficient privileges: Ensure SYSDBA connection
-- - Catalog issues: RESYNC CATALOG;

-- 4. Enable RMAN debugging
RMAN> SET ECHO ON;
RMAN> DEBUG ON;

-- 5. Check for specific errors in RMAN log
-- Look for underlying ORA- errors in alert log
```

**41. Your standby database shows “ORA-16191: Primary log shipping client not logged on standby”. How do you resolve?**

**Answer:**

```sql
-- 1. Check network connectivity between primary and standby
-- From primary: tnsping standby_service_name

-- 2. Verify service configuration on standby
-- Check listener status: lsnrctl status

-- 3. Check archive destination configuration on primary
SELECT dest_name, status, error FROM v$archive_dest_status;

-- 4. Verify authentication setup
-- Ensure password file exists and is synchronized
-- Check REMOTE_LOGIN_PASSWORDFILE parameter

-- 5. Restart log transport service
ALTER SYSTEM SET log_archive_dest_state_2=DEFER;
ALTER SYSTEM SET log_archive_dest_state_2=ENABLE;

-- 6. Check for firewall/network security issues
-- Test port connectivity: telnet standby_host 1521
```

**42. How do you perform a tablespace point-in-time recovery (TSPITR) in Oracle 12c+?**

**Answer:**

```sql
-- Prerequisites: Tablespace must be self-contained

-- 1. Check dependencies
EXEC DBMS_TTS.TRANSPORT_SET_CHECK('tablespace_name', TRUE);
SELECT * FROM transport_set_violations;

-- 2. Take tablespace offline
ALTER TABLESPACE tablespace_name OFFLINE IMMEDIATE;

-- 3. Perform TSPITR using RMAN
RMAN> RECOVER TABLESPACE tablespace_name 
      UNTIL TIME "TO_DATE('2024-01-15 14:00:00', 'YYYY-MM-DD HH24:MI:SS')"
      AUXILIARY DESTINATION '/aux/location/';

-- 4. Bring tablespace online
ALTER TABLESPACE tablespace_name ONLINE;

-- 5. Validate recovered data
-- Check object counts, data consistency
```

**43. Describe the complete process of converting a single-instance database to RAC using DBCA.**

**Answer:**

```bash
# 1. Prerequisites
# - Shared storage configured (ASM recommended)
# - Cluster software installed and configured
# - Oracle software installed on all nodes

# 2. Convert database to cluster database
dbca -silent -convertToRAC \
  -sourceDB PRODDB \
  -nodelist node1,node2 \
  -storageType ASM \
  -diskGroupName DATA

# 3. Post-conversion tasks:
# - Configure services for load balancing
# - Update client connection strings
# - Test failover scenarios
# - Configure Data Guard if required

# 4. Validation
# Check cluster database status
SELECT inst_id, instance_name, status FROM gv$instance;
```

**44. How do you handle recovery when the SYSTEM tablespace datafile is corrupted?**

**Answer:**

```sql
-- Critical situation - SYSTEM tablespace contains data dictionary

-- 1. Shutdown database immediately
SHUTDOWN ABORT;

-- 2. Try to startup mount (may fail if control file references bad datafile)
```