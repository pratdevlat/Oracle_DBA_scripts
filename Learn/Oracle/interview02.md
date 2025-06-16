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

# Senior Oracle DBA Interview Questions (10+ Years Experience)
## Questions 1-25: Architecture, Performance, and Core Administration

### 1. You notice that your production RAC database is experiencing high library cache latch contention. Walk me through your troubleshooting approach and potential solutions.

**Answer:** First, I'd identify the contention using AWR reports, focusing on the "Top 5 Timed Events" and "Latch Statistics" sections. I'd look for high waits on library cache latches and examine the latch sleep breakdown.

**Troubleshooting steps:**
- Query `V$LATCH` and `V$LATCH_CHILDREN` to identify specific latch addresses with high gets/misses
- Use `V$LIBRARYCACHE` to check for high reloads and invalidations
- Examine `V$SQL` for statements with high version counts
- Check `V$SQLAREA` for cursor sharing issues

**Root causes and solutions:**
- **Literal SQL without bind variables:** Implement cursor_sharing=FORCE temporarily, then fix applications to use bind variables
- **Large object invalidations:** Identify objects being frequently invalidated using `V$SQL_SHARED_CURSOR`
- **Undersized shared pool:** Increase shared_pool_size, but monitor for over-allocation
- **Hot blocks in library cache:** Use library cache partitioning in newer versions
- **Application design issues:** Work with developers to implement proper connection pooling and statement caching

**Immediate remediation:** I'd consider flushing shared pool during low-activity periods and implementing cursor_sharing as a temporary measure while addressing root causes.

### 2. Your Data Guard primary database crashed during a bulk data load. The standby shows a gap in archive logs. How do you recover and resynchronize?

**Answer:** This scenario requires careful assessment and systematic recovery.

**Assessment phase:**
```sql
-- On standby, check for gaps
SELECT thread#, low_sequence#, high_sequence# 
FROM v$archive_gap;

-- Check current applied sequence
SELECT max(sequence#) FROM v$archived_log 
WHERE applied='YES';
```

**Recovery approach:**
1. **Primary database recovery:** First, recover the primary database using RMAN
2. **Gap resolution:** 
   - If archive logs are available on primary, copy them to standby
   - If logs are missing due to corruption, perform incremental backup-based recovery
   ```sql
   -- On primary
   RMAN> BACKUP INCREMENTAL FROM SCN <standby_scn> DATABASE FORMAT '/backup/incr_%U';
   
   -- On standby
   RMAN> CATALOG START WITH '/backup/incr_';
   RMAN> RECOVER DATABASE NOREDO;
   ```

3. **Alternative approach - Reinitialize standby:**
   - If gap is extensive, faster to recreate standby using RMAN DUPLICATE
   - Ensure primary is stable before starting duplication

**Prevention measures:**
- Implement automatic gap resolution (Oracle 12c+)
- Configure multiple archivelog destinations
- Set up real-time apply with redo transport compression
- Monitor standby lag using Enterprise Manager or custom scripts

### 3. During peak hours, you observe that your OLTP system has high wait events on "enq: TX - row lock contention." How do you identify the blocking sessions and resolve this?

**Answer:** Row lock contention indicates blocking transactions that need immediate attention.

**Immediate identification:**
```sql
-- Find blocking sessions
SELECT 
    s1.sid blocking_sid, s1.serial# blocking_serial,
    s1.username blocking_user, s1.program blocking_program,
    s2.sid blocked_sid, s2.serial# blocked_serial,
    s2.username blocked_user,
    s1.last_call_et blocking_duration_sec,
    l.type, l.lmode, l.request
FROM v$lock l1, v$session s1, v$lock l2, v$session s2
WHERE s1.sid = l1.sid AND s2.sid = l2.sid
    AND l1.block = 1 AND l2.request > 0
    AND l1.id1 = l2.id1 AND l1.id2 = l2.id2;

-- Identify specific objects and rows being locked
SELECT 
    do.object_name, do.object_type,
    l.sid, s.serial#, s.username,
    decode(l.lmode,0,'None',1,'Null',2,'Row-S',3,'Row-X',4,'Share',5,'S/Row-X',6,'Exclusive') lock_mode
FROM v$locked_object l, dba_objects do, v$session s
WHERE l.object_id = do.object_id AND l.session_id = s.sid;
```

**Analysis approach:**
- Check if blocking session is active or idle
- Review SQL being executed by blocking session
- Examine transaction duration and scope
- Identify if it's a deadlock situation

**Resolution strategies:**
1. **Active blocking session:** Contact application team to commit/rollback
2. **Idle blocking session:** Consider killing session after business approval
3. **Application-level deadlock:** Review application logic for lock ordering
4. **Long-running transaction:** Implement checkpointing in batch processes

**Long-term solutions:**
- Implement proper transaction scoping in applications
- Use SELECT FOR UPDATE with NOWAIT where appropriate
- Consider row-level partitioning for hot tables
- Implement application-level queuing for high-contention operations

### 4. You need to upgrade a 11.2.0.4 database to Oracle 19c in a production environment with minimal downtime. What's your detailed approach?

**Answer:** A major version upgrade requires extensive planning and testing.

**Pre-upgrade preparation (2-3 months):**
1. **Compatibility assessment:**
   - Run Pre-Upgrade Information Tool (preupgrd.sql)
   - Check for deprecated features using DBUA or manual scripts
   - Identify applications requiring recertification
   - Review initialization parameters for obsolete settings

2. **Testing strategy:**
   - Create identical test environment with production data subset
   - Perform complete upgrade testing including fallback procedures
   - Test all applications and custom code
   - Performance benchmark comparison

**Upgrade approach options:**
1. **Database Upgrade Assistant (DBUA):** Simplest but longer downtime
2. **Manual upgrade with parallel processing:** More control, potentially faster
3. **Transportable tablespaces:** For very large databases with partitioned downtime
4. **Oracle GoldenGate:** Near-zero downtime but complex setup

**Recommended approach for minimal downtime:**
```bash
# 1. Create guaranteed restore point before upgrade
SQL> CREATE RESTORE POINT pre_upgrade_19c GUARANTEE FLASHBACK DATABASE;

# 2. Run parallel upgrade using catctl.pl
$ORACLE_HOME/perl/bin/perl catctl.pl -n 4 -l /upgrade_logs catupgrd.sql

# 3. Run post-upgrade scripts
@?/rdbms/admin/catuppst.sql
@?/rdbms/admin/utlrp.sql
```

**Fallback strategy:**
- Flashback database to restore point (fastest)
- RMAN restore if flashback unavailable
- Export/import for specific objects if needed

**Post-upgrade validation:**
- Run dbupgdiag.sql to validate upgrade
- Gather dictionary statistics
- Update optimizer statistics
- Test critical application functions
- Monitor performance for first week

### 5. Your ASM diskgroup shows "MOUNT RESTRICTED" status. What are the possible causes and how do you troubleshoot?

**Answer:** MOUNT RESTRICTED indicates ASM diskgroup integrity issues requiring immediate attention.

**Possible causes:**
1. **Disk offline/failure:** Physical disk problems or path issues
2. **Metadata corruption:** ASM metadata inconsistencies
3. **Insufficient redundancy:** Not enough disks for required redundancy level
4. **Authentication issues:** ASM password file problems

**Troubleshooting steps:**
```sql
-- Check diskgroup status and disk conditions
SELECT name, state, type, total_mb, free_mb FROM v$asm_diskgroup;
SELECT path, state, mode_status, header_status FROM v$asm_disk;

-- Check for ASM errors
SELECT message_text, message_level FROM v$asm_operation;
SELECT facility, severity, message_text FROM x$dbgalertext WHERE originating_timestamp > sysdate-1;
```

**Resolution approach:**
1. **For disk failures:**
   ```sql
   -- Add replacement disk
   ALTER DISKGROUP DATA ADD DISK '/dev/raw/raw7';
   
   -- Drop failed disk (forces rebalance)
   ALTER DISKGROUP DATA DROP DISK ASM_DISK_003 FORCE;
   ```

2. **For metadata corruption:**
   ```bash
   # Use amdu to extract metadata
   amdu -diskstring '/dev/raw/raw*' -extract DATA.256.file
   
   # Run ASM validation
   asmcmd> lsdg -g
   asmcmd> lsattr -l -G DATA
   ```

3. **For authentication issues:**
   ```bash
   # Recreate ASM password file
   orapwd file=$ORACLE_HOME/dbs/orapw+ASM password=oracle entries=10
   ```

**Prevention measures:**
- Implement ASM disk monitoring using Grid Infrastructure
- Use ASM preferred mirror read for better availability
- Configure ASM fast mirror resync
- Regular ASM metadata backup using ASMCMD

### 6. You're asked to migrate a 2TB Oracle database to PostgreSQL. What's your comprehensive migration strategy?

**Answer:** Large-scale database migration requires thorough planning and multiple parallel workstreams.

**Assessment phase (4-6 weeks):**
1. **Schema analysis:**
   - Inventory all database objects (tables, indexes, views, procedures, functions)
   - Identify Oracle-specific features (PL/SQL packages, analytical functions, partitioning)
   - Map Oracle data types to PostgreSQL equivalents
   - Document dependencies and constraints

2. **Application analysis:**
   - Review application code for Oracle-specific SQL
   - Identify embedded PL/SQL blocks
   - Catalog all database connections and frameworks used

**Migration strategy:**
1. **Schema migration:**
   ```bash
   # Use ora2pg for initial conversion
   ora2pg -t TABLE -o tables.sql
   ora2pg -t CONSTRAINT -o constraints.sql
   ora2pg -t INDEX -o indexes.sql
   ```

2. **Data migration options:**
   - **For online migration:** Use Oracle GoldenGate with PostgreSQL adapters
   - **For offline migration:** Export/Import with parallel processing
   - **Hybrid approach:** Bulk load historical data, then CDC for recent changes

3. **Code conversion:**
   - Convert PL/SQL packages to PostgreSQL functions (PL/pgSQL)
   - Rewrite Oracle-specific SQL constructs
   - Implement equivalent partitioning strategies
   - Convert Oracle sequences to PostgreSQL serial/identity columns

**Execution approach:**
```bash
# Parallel data export from Oracle
expdp system/password directory=DATA_PUMP_DIR dumpfile=table_%U.dmp 
      parallel=8 tables=schema.table_name

# Convert and load into PostgreSQL
pg_restore -d target_db -j 8 converted_dump.sql
```

**Testing and validation:**
- Data reconciliation using row counts and checksums
- Performance testing with production-like workloads
- Application functionality testing
- Security and privilege validation

**Cutover planning:**
- Incremental data sync using CDC tools
- Application connection string updates
- Rollback procedures and timeline
- Go-live validation checklist

### 7. Your production database is experiencing intermittent ORA-00060 deadlock errors. How do you systematically diagnose and resolve this?

**Answer:** Deadlock resolution requires understanding the lock contention patterns and application behavior.

**Immediate diagnosis:**
```sql
-- Enable deadlock tracing
ALTER SYSTEM SET events '60 trace name errorstack level 3';

-- Check current deadlock information
SELECT * FROM dba_waiters;
SELECT * FROM dba_blockers;

-- Review alert log for deadlock traces
-- Examine trace files in udump directory
```

**Analysis approach:**
1. **Parse deadlock graphs:** Understand which sessions and objects are involved
2. **Identify resource types:** Row locks, table locks, or system locks
3. **Analyze timing patterns:** Peak hours, specific operations, or random occurrence
4. **Review application logic:** Transaction scope and lock acquisition order

**Common deadlock scenarios and solutions:**

1. **Foreign key without index:**
   ```sql
   -- Find unindexed foreign keys
   SELECT c.table_name, c.column_name, c.constraint_name
   FROM user_cons_columns c, user_constraints p
   WHERE c.constraint_name = p.constraint_name
     AND p.constraint_type = 'R'
   MINUS
   SELECT i.table_name, i.column_name, i.index_name  
   FROM user_ind_columns i;
   
   -- Create missing indexes
   CREATE INDEX idx_fk_table_id ON child_table(parent_id);
   ```

2. **Lock ordering issues:**
   - Standardize transaction order across applications
   - Implement consistent primary key ordering in batch updates
   - Use SELECT FOR UPDATE with ORDER BY

3. **Long-running transactions:**
   ```sql
   -- Identify long transactions
   SELECT s.sid, s.serial#, s.username, s.program,
          t.start_time, t.used_ublk, t.used_urec
   FROM v$session s, v$transaction t
   WHERE s.taddr = t.addr
   ORDER BY t.start_time;
   ```

**Prevention strategies:**
- Implement proper exception handling with rollback
- Use NOWAIT or timeout clauses where appropriate
- Reduce transaction scope and duration
- Consider optimistic locking patterns
- Implement retry logic with exponential backoff

### 8. You discover that your RAC database has split-brain symptoms. How do you identify and resolve this critical situation?

**Answer:** Split-brain in RAC is a critical situation requiring immediate attention to prevent data corruption.

**Identification symptoms:**
- Instances showing different cluster membership
- Voting disk access issues
- Network heartbeat failures
- ORA-29740, ORA-29742 errors in alert logs
- CSS daemon (ocssd) restart loops

**Immediate assessment:**
```bash
# Check cluster status on all nodes
crsctl stat res -t

# Verify voting disk access
crsctl query css votedisk

# Check network connectivity
oifcfg getif
ping -I <private_interface> <other_node_private_ip>

# Review CSS logs
tail -f $GRID_HOME/log/<node>/cssd/ocssd.log
```

**Root cause analysis:**
1. **Network issues:**
   - Private interconnect failure
   - Switch/network equipment problems
   - MTU size mismatches

2. **Storage issues:**
   - Voting disk inaccessibility
   - OCR corruption or unavailability
   - Shared storage connectivity problems

3. **Time synchronization:**
   - Clock skew between nodes
   - NTP service issues

**Resolution steps:**

1. **If cluster is still partially functional:**
   ```bash
   # Stop problematic instance gracefully
   srvctl stop instance -d <db_name> -i <instance_name>
   
   # Restart cluster stack if needed
   crsctl stop crs
   crsctl start crs
   ```

2. **If complete cluster restart needed:**
   ```bash
   # Stop all instances and cluster services
   srvctl stop database -d <db_name>
   crsctl stop cluster -all
   
   # Verify and fix voting disk issues
   crsctl replace votedisk <new_voting_disk_path>
   
   # Start cluster services
   crsctl start cluster -all
   ```

3. **Network-related fixes:**
   - Verify private interconnect configuration
   - Check switch configuration and VLAN settings
   - Validate MTU settings across network path
   - Test network latency and packet loss

**Prevention measures:**
- Implement redundant private interconnects
- Use multiple voting disks across different storage arrays
- Configure network bonding/teaming
- Regular cluster health monitoring
- Proper time synchronization setup

### 9. Your database's AWR report shows high "log file sync" wait events. What's your systematic approach to resolve this?

**Answer:** High log file sync waits typically indicate redo log writing bottlenecks affecting commit performance.

**Analysis approach:**
```sql
-- Check current redo log configuration
SELECT group#, thread#, sequence#, bytes/1024/1024 mb, status FROM v$log;
SELECT group#, member FROM v$logfile;

-- Analyze log file sync statistics
SELECT event, total_waits, total_timeouts, time_waited, average_wait
FROM v$system_event WHERE event = 'log file sync';

-- Check redo generation rate
SELECT name, value FROM v$sysstat 
WHERE name IN ('redo size', 'redo writes', 'redo write time');
```

**Root cause investigation:**

1. **Storage performance issues:**
   ```bash
   # Check I/O statistics for redo log files
   iostat -x 1 10
   
   # Verify disk latency for log file locations
   orion -testname redo_test -run advanced
   ```

2. **Redo log sizing issues:**
   ```sql
   -- Check log switch frequency
   SELECT to_char(first_time, 'YYYY-MM-DD HH24') hour,
          count(*) switches
   FROM v$log_history
   WHERE first_time > sysdate - 7
   GROUP BY to_char(first_time, 'YYYY-MM-DD HH24')
   ORDER BY 1;
   ```

3. **Application behavior:**
   ```sql
   -- Identify sessions with high commit rates
   SELECT s.sid, s.serial#, s.username, s.program,
          st.value commits
   FROM v$session s, v$sesstat st, v$statname sn
   WHERE s.sid = st.sid AND st.statistic# = sn.statistic#
     AND sn.name = 'user commits'
   ORDER BY st.value DESC;
   ```

**Resolution strategies:**

1. **Storage optimization:**
   - Move redo logs to faster storage (SSD/NVMe)
   - Separate redo logs from other database files
   - Use raw devices or direct I/O
   - Configure storage array write cache properly

2. **Redo log configuration:**
   ```sql
   -- Add more redo log groups
   ALTER DATABASE ADD LOGFILE GROUP 4 
   ('/u01/oradata/redo04a.log', '/u02/oradata/redo04b.log') 
   SIZE 1G;
   
   -- Increase redo log size
   -- (Requires recreation of all log groups during low activity)
   ```

3. **Application tuning:**
   - Reduce unnecessary commits in batch processes
   - Implement batch commits instead of row-by-row commits
   - Use COMMIT WRITE NOWAIT for non-critical operations
   - Consider using NOLOGGING for bulk operations

4. **Advanced solutions:**
   - Enable commit_logging=BATCH for OLTP workloads
   - Use In-Memory Column Store to reduce redo generation
   - Consider Oracle Real Application Clusters for distributed load

### 10. You need to perform point-in-time recovery to 2 hours ago, but some tablespaces were added after that time. How do you handle this complex recovery scenario?

**Answer:** This scenario requires careful handling of timeline inconsistencies and new tablespaces.

**Assessment phase:**
```sql
-- Identify tablespaces created after target time
SELECT tablespace_name, created 
FROM dba_tablespaces 
WHERE created > (SYSDATE - 2/24);

-- Check for any dropped tablespaces in that timeframe
SELECT tablespace_name, drop_time 
FROM dba_tablespace_usage_metrics 
WHERE drop_time BETWEEN (SYSDATE - 2/24) AND SYSDATE;
```

**Recovery strategy options:**

**Option 1: Exclude new tablespaces from recovery**
```bash
# Shutdown database
shutdown immediate;

# Start in mount mode
startup mount;

# Restore and recover excluding new tablespaces
RMAN> RESTORE DATABASE SKIP TABLESPACE new_tbs1, new_tbs2;
RMAN> RECOVER DATABASE SKIP TABLESPACE new_tbs1, new_tbs2 
      UNTIL TIME "TO_DATE('2024-06-16 14:00:00', 'YYYY-MM-DD HH24:MI:SS')";

# Open database with resetlogs
RMAN> ALTER DATABASE OPEN RESETLOGS;

# Drop the new tablespaces that couldn't be recovered
SQL> DROP TABLESPACE new_tbs1 INCLUDING CONTENTS AND DATAFILES;
```

**Option 2: Partial database recovery with tablespace recreation**
```bash
# Recover to point in time
RMAN> RECOVER DATABASE UNTIL TIME 
      "TO_DATE('2024-06-16 14:00:00', 'YYYY-MM-DD HH24:MI:SS')";

# Open with resetlogs
RMAN> ALTER DATABASE OPEN RESETLOGS;

# Recreate the new tablespaces
SQL> CREATE TABLESPACE new_tbs1 
     DATAFILE '/u01/oradata/new_tbs01.dbf' SIZE 1G;

# Re-import or recreate objects that were in new tablespaces
```

**Option 3: Advanced recovery using auxiliary instance**
```bash
# Create auxiliary instance for recovery
RMAN> DUPLICATE TARGET DATABASE TO auxiliary_db 
      UNTIL TIME "TO_DATE('2024-06-16 14:00:00', 'YYYY-MM-DD HH24:MI:SS')";

# Export required data from auxiliary
expdp system/password directory=DATA_PUMP_DIR 
      dumpfile=recovered_data.dmp schemas=target_schema

# Import into current database after handling tablespace issues
```

**Handling complications:**
1. **Objects spanning multiple tablespaces:** May need to recreate with different storage
2. **Dependencies:** Check for foreign keys, views, synonyms pointing to affected objects
3. **Application impact:** Coordinate with application teams for missing functionality

**Validation steps:**
```sql
-- Verify database consistency
ANALYZE TABLE important_table VALIDATE STRUCTURE CASCADE;

-- Check for invalid objects
SELECT owner, object_name, object_type 
FROM dba_objects WHERE status = 'INVALID';

-- Validate recovered data
SELECT count(*) FROM critical_table 
WHERE last_updated <= TO_DATE('2024-06-16 14:00:00', 'YYYY-MM-DD HH24:MI:SS');
```

### 11. Your database is running out of space in the SYSTEM tablespace. What immediate and long-term actions do you take?

**Answer:** SYSTEM tablespace space issues are critical and require immediate action to prevent database shutdown.

**Immediate assessment:**
```sql
-- Check current space usage
SELECT tablespace_name, bytes/1024/1024/1024 gb_size, 
       maxbytes/1024/1024/1024 gb_max_size,
       (bytes-NVL(maxbytes,bytes))/1024/1024/1024 gb_available
FROM dba_data_files WHERE tablespace_name = 'SYSTEM';

-- Identify space usage by segment
SELECT owner, segment_name, segment_type, bytes/1024/1024 mb
FROM dba_segments 
WHERE tablespace_name = 'SYSTEM' 
ORDER BY bytes DESC;

-- Check for objects that shouldn't be in SYSTEM
SELECT owner, table_name, tablespace_name
FROM dba_tables 
WHERE tablespace_name = 'SYSTEM' 
  AND owner NOT IN ('SYS','SYSTEM','OUTLN','DBSNMP');
```

**Immediate actions (next 15 minutes):**

1. **Add space immediately:**
   ```sql
   -- Add datafile if possible
   ALTER TABLESPACE SYSTEM 
   ADD DATAFILE '/u01/oradata/system02.dbf' SIZE 1G 
   AUTOEXTEND ON NEXT 100M MAXSIZE 2G;
   
   -- Or resize existing datafile
   ALTER DATABASE DATAFILE '/u01/oradata/system01.dbf' 
   RESIZE 2G;
   ```

2. **Emergency cleanup:**
   ```sql
   -- Purge recyclebin
   PURGE DBA_RECYCLEBIN;
   
   -- Shrink audit trail if using database auditing
   DELETE FROM sys.aud$ WHERE timestamp# < SYSDATE - 30;
   COMMIT;
   ```

**Root cause analysis:**
```sql
-- Check for SYSTEM tablespace growth patterns
SELECT to_char(timestamp, 'YYYY-MM-DD'), 
       max(bytes)/1024/1024/1024 max_gb
FROM dba_hist_tbspc_space_usage 
WHERE tablespace_name = 'SYSTEM'
GROUP BY to_char(timestamp, 'YYYY-MM-DD')
ORDER BY 1;

-- Identify recent object growth
SELECT owner, segment_name, segment_type,
       bytes/1024/1024 current_mb
FROM dba_segments 
WHERE tablespace_name = 'SYSTEM'
  AND owner NOT IN ('SYS','SYSTEM')
ORDER BY bytes DESC;
```

**Long-term resolution:**

1. **Move non-system objects:**
   ```sql
   -- Create proper tablespace for application objects
   CREATE TABLESPACE USERS_DATA
   DATAFILE '/u01/oradata/users01.dbf' SIZE 500M
   AUTOEXTEND ON NEXT 100M MAXSIZE 2G;
   
   -- Move tables to appropriate tablespace
   ALTER TABLE app_user.large_table MOVE TABLESPACE USERS_DATA;
   
   -- Rebuild indexes
   ALTER INDEX app_user.idx_large_table REBUILD TABLESPACE USERS_DATA;
   ```

2. **Implement monitoring:**
   ```sql
   -- Create space monitoring script
   CREATE OR REPLACE PROCEDURE monitor_system_space AS
   BEGIN
     FOR rec IN (SELECT tablespace_name, 
                        round(used_percent,2) pct_used
                 FROM dba_tablespace_usage_metrics
                 WHERE tablespace_name = 'SYSTEM')
     LOOP
       IF rec.pct_used > 85 THEN
         -- Send alert or automatically extend
         dbms_output.put_line('SYSTEM tablespace ' || rec.pct_used || '% full');
       END IF;
     END LOOP;
   END;
   ```

3. **Preventive measures:**
   - Set up automated monitoring with 80% threshold alerts
   - Implement tablespace quotas for non-system users
   - Regular audit trail cleanup procedures
   - Establish proper data placement standards
   - Configure autoextend with reasonable maxsize limits

### 12. You're implementing Oracle Data Guard for a mission-critical database. Walk through your complete setup and testing strategy.

**Answer:** Data Guard implementation for mission-critical systems requires meticulous planning and comprehensive testing.

**Pre-implementation planning:**
1. **Requirements gathering:**
   - RTO (Recovery Time Objective) and RPO (Recovery Point Objective) requirements
   - Network bandwidth and latency measurements
   - Standby server sizing and storage requirements
   - Compliance and regulatory requirements

2. **Architecture decisions:**
   - Physical vs. Logical standby (Physical for most use cases)
   - Synchronous vs. Asynchronous transport (SYNC for zero data loss)
   - Real-time apply vs. Delayed apply
   - Multiple standby locations for disaster recovery

**Implementation steps:**

**Phase 1: Primary database preparation**
```sql
-- Enable force logging
ALTER DATABASE FORCE LOGGING;

-- Configure archive log mode
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- Set up initialization parameters
ALTER SYSTEM SET log_archive_config='DG_CONFIG=(PRIMARY,STANDBY)';
ALTER SYSTEM SET log_archive_dest_1='LOCATION=/u01/archive/ VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=PRIMARY';
ALTER SYSTEM SET log_archive_dest_2='SERVICE=STANDBY LGWR SYNC AFFIRM VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=STANDBY';
ALTER SYSTEM SET log_archive_dest_state_2=ENABLE;
ALTER SYSTEM SET remote_login_passwordfile=EXCLUSIVE;
ALTER SYSTEM SET fal_server=STANDBY;
ALTER SYSTEM SET fal_client=PRIMARY;
```

**Phase 2: Standby database creation**
```bash
# Create standby database using RMAN DUPLICATE
rman target sys/password@PRIMARY auxiliary sys/password@STANDBY

DUPLICATE TARGET DATABASE FOR STANDBY FROM ACTIVE DATABASE
SPFILE
PARAMETER_VALUE_CONVERT 'PRIMARY','STANDBY'
SET db_unique_name='STANDBY'
SET log_archive_dest_1='LOCATION=/u01/archive/'
SET log_archive_dest_2='SERVICE=PRIMARY LGWR SYNC AFFIRM VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=PRIMARY'
SET fal_server='PRIMARY'
SET fal_client='STANDBY';
```

**Phase 3: Configure Data Guard Broker**
```bash
# Enable Data Guard Broker
dgmgrl sys/password@PRIMARY
DGMGRL> CREATE CONFIGURATION 'DG_CONFIG' AS PRIMARY DATABASE IS 'PRIMARY' CONNECT IDENTIFIER IS 'PRIMARY';
DGMGRL> ADD DATABASE 'STANDBY' AS CONNECT IDENTIFIER IS 'STANDBY';
DGMGRL> ENABLE CONFIGURATION;
```

**Testing strategy:**

**Functional testing:**
```bash
# Test log transport and apply
DGMGRL> SHOW CONFIGURATION;
DGMGRL> SHOW DATABASE 'PRIMARY';
DGMGRL> SHOW DATABASE 'STANDBY';

# Verify log shipping
SQL> ALTER SYSTEM SWITCH LOGFILE;
SQL> SELECT max(sequence#) FROM v$archived_log WHERE applied='YES';
```

**Failover testing:**
```bash
# Test switchover (planned)
DGMGRL> SWITCHOVER TO 'STANDBY';

# Test failover (unplanned)
DGMGRL> FAILOVER TO 'STANDBY';

# Test flashback after failover
SQL> SELECT current_scn FROM v$database;
RMAN> FLASHBACK DATABASE TO SCN <scn_before_failover>;
```

**Performance testing:**
- Measure redo transport overhead during peak loads
- Test network saturation scenarios
- Validate apply performance with different lag scenarios
- Test backup operations on standby database

**Monitoring and alerting:**
```sql
-- Create monitoring views
CREATE OR REPLACE VIEW dg_status AS
SELECT name, value, datum_time 
FROM v$dataguard_stats
WHERE name IN ('transport lag', 'apply lag', 'apply finish time');

-- Set up automated monitoring
CREATE OR REPLACE PROCEDURE check_dg_lag AS
  v_transport_lag NUMBER;
  v_apply_lag NUMBER;
BEGIN
  SELECT value INTO v_transport_lag 
  FROM v$dataguard_stats WHERE name = 'transport lag';
  
  IF v_transport_lag > 300 THEN -- 5 minutes
    -- Send alert
    dbms_output.put_line('High transport lag: ' || v_transport_lag);
  END IF;
END;
```

