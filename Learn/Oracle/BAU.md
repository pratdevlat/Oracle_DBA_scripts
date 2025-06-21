As an experienced Oracle DBA, you'll appreciate the value of a well-curated set of SQL scripts for BAU activities. This inventory aims to provide a comprehensive starting point. While the scripts provided are generally robust, always test them in a non-production environment before deploying them to your production systems.
Important Considerations Before Use:
 * Permissions: Ensure the Oracle user executing these scripts has the necessary privileges (e.g., SELECT_CATALOG_ROLE, DBA role, or specific object privileges).
 * Schema: Most scripts query V$ views or DBA_ views, which are standard.
 * Customization: Some scripts might need minor adjustments based on your specific environment (e.g., schema names, tablespace names, retention policies).
 * Error Handling: For production-level automation, consider adding error handling and logging to your shell or PL/SQL wrappers around these scripts.
 * Tooling: For more advanced monitoring and performance analysis, consider using Oracle's Enterprise Manager (OEM) or other third-party tools in conjunction with these scripts.
1. Monitoring and Diagnostics
1.1. Database Health Check Script
This script provides a quick overview of critical database parameters, including uptime, open cursors, session count, and alert log location.
-- Database Health Check Script
SET LINESIZE 200
SET PAGESIZE 50

COLUMN HOST_NAME FORMAT A20
COLUMN INSTANCE_NAME FORMAT A15
COLUMN VERSION FORMAT A15
COLUMN STATUS FORMAT A10
COLUMN STARTUP_TIME FORMAT A20
COLUMN LOG_MODE FORMAT A10
COLUMN FLASHBACK_ON FORMAT A15

SELECT
    SYS_CONTEXT('USERENV', 'HOST') AS HOST_NAME,
    I.INSTANCE_NAME,
    I.VERSION,
    I.STATUS,
    TO_CHAR(I.STARTUP_TIME, 'YYYY-MM-DD HH24:MI:SS') AS STARTUP_TIME,
    D.LOG_MODE,
    D.FLASHBACK_ON,
    (SELECT COUNT(*) FROM V$SESSION WHERE STATUS = 'ACTIVE') AS ACTIVE_SESSIONS,
    (SELECT COUNT(*) FROM V$SESSION) AS TOTAL_SESSIONS,
    (SELECT VALUE FROM V$PARAMETER WHERE NAME = 'open_cursors') AS OPEN_CURSORS_PARAM,
    (SELECT SUM(VALUE) FROM V$SESSTAT WHERE STATISTIC# = (SELECT STATISTIC# FROM V$STATNAME WHERE NAME = 'opened cursors current')) AS OPENED_CURSORS_CURRENT
FROM
    V$INSTANCE I,
    V$DATABASE D;

SELECT 'Alert Log Location: ' || VALUE AS ALERT_LOG_LOCATION
FROM V$DIAG_INFO
WHERE NAME = 'Default Trace File' AND KEY = 'ADR_HOME';

SELECT 'Flash Recovery Area Usage (GB):' FROM DUAL;
SELECT
    ROUND(SPACE_LIMIT / 1024 / 1024 / 1024, 2) AS FRA_LIMIT_GB,
    ROUND(SPACE_USED / 1024 / 1024 / 1024, 2) AS FRA_USED_GB,
    ROUND(SPACE_RECLAIMABLE / 1024 / 1024 / 1024, 2) AS FRA_RECLAIMABLE_GB,
    ROUND((SPACE_USED / SPACE_LIMIT) * 100, 2) AS FRA_USED_PERCENT
FROM
    V$RECOVERY_FILE_DEST;

1.2. Long-Running Queries
This script identifies SQL statements that have been executing for a long time, helping to pinpoint potential performance bottlenecks.
-- Long-Running Queries
SET LINESIZE 200
SET PAGESIZE 50

COLUMN SID FORMAT 99999
COLUMN SERIAL# FORMAT 99999
COLUMN USERNAME FORMAT A15
COLUMN PROGRAM FORMAT A30
COLUMN MODULE FORMAT A30
COLUMN EVENT FORMAT A30
COLUMN SQL_TEXT FORMAT A60 WRAP
COLUMN ELAPSED_SECONDS FORMAT 999999999

SELECT
    S.SID,
    S.SERIAL#,
    S.USERNAME,
    S.OSUSER,
    S.PROGRAM,
    S.MODULE,
    S.WAIT_CLASS,
    S.EVENT,
    SQL.SQL_ID,
    SQL.SQL_TEXT,
    TRUNC(LAST_CALL_ET / 3600) || 'h ' ||
    TRUNC(MOD(LAST_CALL_ET, 3600) / 60) || 'm ' ||
    MOD(MOD(LAST_CALL_ET, 3600), 60) || 's' AS ELAPSED_TIME
FROM
    V$SESSION S,
    V$SQLAREA SQL
WHERE
    S.SQL_ID = SQL.SQL_ID(+)
AND S.STATUS = 'ACTIVE'
AND S.TYPE = 'USER'
AND S.LAST_CALL_ET > 300 -- Adjust threshold (seconds) as needed, e.g., 300 seconds (5 minutes)
ORDER BY
    LAST_CALL_ET DESC;

1.3. Sessions Causing Blocking
This script helps identify sessions that are blocking other sessions, which can lead to application slowdowns.
-- Sessions Causing Blocking
SET LINESIZE 200
SET PAGESIZE 50

COLUMN BLOCKER_SID FORMAT 99999 HEADING 'BLOCKER_SID'
COLUMN BLOCKER_USERNAME FORMAT A15 HEADING 'BLOCKER_USERNAME'
COLUMN BLOCKER_PROGRAM FORMAT A30 HEADING 'BLOCKER_PROGRAM'
COLUMN BLOCKED_SID FORMAT 99999 HEADING 'BLOCKED_SID'
COLUMN BLOCKED_USERNAME FORMAT A15 HEADING 'BLOCKED_USERNAME'
COLUMN BLOCKED_PROGRAM FORMAT A30 HEADING 'BLOCKED_PROGRAM'
COLUMN WAIT_EVENT FORMAT A30 HEADING 'WAIT_EVENT'
COLUMN WAIT_TIME FORMAT 9999999 HEADING 'WAIT_TIME_CS'

SELECT
    L.SID AS BLOCKER_SID,
    S1.USERNAME AS BLOCKER_USERNAME,
    S1.PROGRAM AS BLOCKER_PROGRAM,
    S1.OSUSER AS BLOCKER_OSUSER,
    S1.MACHINE AS BLOCKER_MACHINE,
    S1.SQL_ID AS BLOCKER_SQL_ID,
    S2.SID AS BLOCKED_SID,
    S2.USERNAME AS BLOCKED_USERNAME,
    S2.PROGRAM AS BLOCKED_PROGRAM,
    S2.OSUSER AS BLOCKED_OSUSER,
    S2.MACHINE AS BLOCKED_MACHINE,
    S2.SQL_ID AS BLOCKED_SQL_ID,
    W.EVENT AS WAIT_EVENT,
    W.WAIT_TIME_MICRO AS WAIT_TIME
FROM
    V$LOCK L,
    V$SESSION S1,
    V$SESSION S2,
    V$ACTIVE_SESSION_HISTORY W
WHERE
    L.BLOCK = 1
AND L.REQUEST = 0
AND S1.SID = L.SID
AND L.ID1 = S2.P1RAW
AND L.ID2 = S2.P2RAW
AND S2.EVENT = 'enq: TX - row lock contention' -- Or other blocking events
AND S2.SESSION_ID = W.SESSION_ID(+)
AND S2.SERIAL# = W.SESSION_SERIAL_NUM(+)
ORDER BY
    L.SID, W.WAIT_TIME_MICRO DESC;

2. Performance Tuning
2.1. Identify High Resource-Consuming Queries
This script helps identify SQL statements consuming significant CPU or I/O resources from the AWR views. Requires Diagnostics Pack license.
-- High Resource-Consuming Queries (requires Diagnostics Pack license)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN SQL_TEXT FORMAT A70 WRAP
COLUMN ELAPSED_TIME_PER_EXEC FORMAT 99999999.99 HEADING 'ELAPSED_SEC_PER_EXEC'
COLUMN CPU_TIME_PER_EXEC FORMAT 99999999.99 HEADING 'CPU_SEC_PER_EXEC'
COLUMN DISK_READS_PER_EXEC FORMAT 99999999 HEADING 'DISK_READS_PER_EXEC'
COLUMN BUFFER_GETS_PER_EXEC FORMAT 99999999 HEADING 'BUFFER_GETS_PER_EXEC'

SELECT
    S.SQL_ID,
    S.PLAN_HASH_VALUE,
    TRUNC(S.ELAPSED_TIME_DELTA / 1000000 / S.EXECUTIONS_DELTA) AS ELAPSED_TIME_PER_EXEC,
    TRUNC(S.CPU_TIME_DELTA / 1000000 / S.EXECUTIONS_DELTA) AS CPU_TIME_PER_EXEC,
    TRUNC(S.DISK_READS_DELTA / S.EXECUTIONS_DELTA) AS DISK_READS_PER_EXEC,
    TRUNC(S.BUFFER_GETS_DELTA / S.EXECUTIONS_DELTA) AS BUFFER_GETS_PER_EXEC,
    S.EXECUTIONS_DELTA AS EXECUTIONS,
    SQL.SQL_TEXT
FROM
    DBA_HIST_SQLSTAT S,
    DBA_HIST_SQLTEXT SQL
WHERE
    S.DBID = (SELECT DBID FROM V$DATABASE)
AND S.SNAP_ID = (SELECT MAX(SNAP_ID) FROM DBA_HIST_SNAPSHOT) -- Latest snapshot
AND S.SQL_ID = SQL.SQL_ID
AND S.DBID = SQL.DBID
AND S.EXECUTIONS_DELTA > 0
ORDER BY
    (S.ELAPSED_TIME_DELTA / S.EXECUTIONS_DELTA) DESC NULLS LAST, -- Order by elapsed time per execution
    (S.CPU_TIME_DELTA / S.EXECUTIONS_DELTA) DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY; -- Adjust to see top N queries

2.2. Index Usage Analysis
This script helps identify unused or rarely used indexes, which can be candidates for removal or consolidation to improve DML performance and reduce storage.
-- Index Usage Analysis (requires appropriate permissions on DBA_IND_STATISTICS)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN OWNER FORMAT A15
COLUMN INDEX_NAME FORMAT A30
COLUMN TABLE_NAME FORMAT A30
COLUMN USAGE FORMAT A10
COLUMN MONITORING FORMAT A10

SELECT
    I.OWNER,
    I.INDEX_NAME,
    I.TABLE_NAME,
    DECODE(S.USED, 'YES', 'USED', 'NO', 'UNUSED') AS USAGE,
    I.MONITORING
FROM
    ALL_INDEXES I
LEFT JOIN
    V$OBJECT_USAGE S ON I.INDEX_NAME = S.INDEX_NAME AND I.OWNER = S.OWNER
WHERE
    I.OWNER NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DBSNMP', 'SYSMAN', 'APEX_040200', 'APEX_PUBLIC_USER', 'ANONYMOUS', 'FLOWS_FILES', 'ORDSYS', 'MDSYS', 'OLAPSYS', 'EXFSYS', 'WMSYS', 'XDB', 'CTXSYS', 'ORDPLUGINS', 'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'MDDATA', 'AUDSYS', 'GSMADMIN_INTERNAL', 'LBACSYS', 'DIP', 'REMOTE_SCHEDULER_AGENT', 'APPQOSSYS', 'DVSYS', 'OJVMSYS', 'GGSYS') -- Exclude system schemas
AND I.INDEX_TYPE NOT LIKE '%LOB%'
AND S.MONITORING = 'YES' -- Only show indexes with monitoring enabled
ORDER BY
    S.USED, I.OWNER, I.TABLE_NAME, I.INDEX_NAME;

-- To enable monitoring for an index:
-- ALTER INDEX schema.index_name MONITORING USAGE;

-- To disable monitoring:
-- ALTER INDEX schema.index_name NOMONITORING USAGE;

2.3. AWR and ADDM Report Generation
These commands are executed in SQL*Plus. AWR and ADDM reports are invaluable for in-depth performance analysis. Requires Diagnostics Pack license.
-- AWR Report Generation (SQL*Plus Command)
-- Replace <begin_snap_id>, <end_snap_id>, and <report_name>

-- 1. Find the latest snapshot IDs:
SELECT SNAP_ID, BEGIN_INTERVAL_TIME, END_INTERVAL_TIME FROM DBA_HIST_SNAPSHOT ORDER BY SNAP_ID DESC;

-- 2. Generate AWR report:
-- @$ORACLE_HOME/rdbms/admin/awrrpt.sql

-- Follow the prompts:
-- Enter the number of days of snapshots to choose from: [e.g., 7]
-- Enter the Begin Snapshot Id: [e.g., 12345]
-- Enter the End Snapshot Id: [e.g., 12350]
-- Enter the Report Type (html or text): [e.g., html]
-- Enter the name of the AWR report file: [e.g., my_awr_report]

-- ADDM Report Generation (SQL*Plus Command)
-- Replace <begin_snap_id>, <end_snap_id>, and <report_name>

-- @$ORACLE_HOME/rdbms/admin/addmrpt.sql

-- Follow the prompts:
-- Enter the number of days of snapshots to choose from: [e.g., 7]
-- Enter the Begin Snapshot Id: [e.g., 12345]
-- Enter the End Snapshot Id: [e.g., 12350]
-- Enter the Report Type (html or text): [e.g., html]
-- Enter the name of the ADDM report file: [e.g., my_addm_report]

3. Backup and Recovery
3.1. RMAN Backup Scripts
RMAN scripts are typically executed from the OS command line. Here are examples for full and archivelog backups.
-- RMAN Full Database Backup Script (Example)
-- Save as, e.g., full_backup.rman

# full_backup.rman
RUN {
    ALLOCATE CHANNEL d1 TYPE DISK;
    ALLOCATE CHANNEL d2 TYPE DISK;
    BACKUP DATABASE PLUS ARCHIVELOG DELETE INPUT;
    -- Optionally, delete obsolete backups:
    -- DELETE OBSOLETE;
    RELEASE CHANNEL d1;
    RELEASE CHANNEL d2;
}

-- How to execute:
-- rman target / cmdfile full_backup.rman log full_backup.log

-- RMAN Archivelog Backup Script (Example)
-- Save as, e.g., archivelog_backup.rman

# archivelog_backup.rman
RUN {
    ALLOCATE CHANNEL d1 TYPE DISK;
    BACKUP ARCHIVELOG ALL DELETE INPUT;
    RELEASE CHANNEL d1;
}

-- How to execute:
-- rman target / cmdfile archivelog_backup.rman log archivelog_backup.log

-- RMAN Check Backup Status
-- From RMAN prompt:
-- LIST BACKUP SUMMARY;
-- LIST BACKUP OF DATABASE;
-- REPORT OBSOLETE;
-- CROSSCHECK BACKUP;
-- DELETE EXPIRED BACKUP;

-- RMAN Database Restore and Recover (Example - DANGER, USE WITH CAUTION!)
-- This is a high-level example. Actual recovery depends on your scenario.
-- Ensure database is mounted (not open).
-- SHUTDOWN IMMEDIATE;
-- STARTUP MOUNT;

-- In RMAN:
-- RESTORE DATABASE;
-- RECOVER DATABASE;
-- ALTER DATABASE OPEN;

3.2. Data Pump Export/Import Scripts
Data Pump is typically executed from the OS command line.
-- Data Pump Full Export (Example)
-- Save as, e.g., full_export.sh

#!/bin/bash
export ORACLE_SID=your_oracle_sid
export ORACLE_HOME=/path/to/your/oracle/home

expdp system/your_password@your_tns_alias \
    DIRECTORY=DATA_PUMP_DIR \
    DUMPFILE=full_db_$(date +%Y%m%d%H%M%S).dmp \
    LOGFILE=full_db_export_$(date +%Y%m%d%H%M%S).log \
    FULL=Y \
    JOB_NAME=FULL_EXPORT_$(date +%Y%m%d%H%M%S)

-- Data Pump Schema Export (Example)
-- Save as, e.g., schema_export.sh

#!/bin/bash
export ORACLE_SID=your_oracle_sid
export ORACLE_HOME=/path/to/your/oracle/home

expdp system/your_password@your_tns_alias \
    DIRECTORY=DATA_PUMP_DIR \
    DUMPFILE=your_schema_$(date +%Y%m%d%H%M%S).dmp \
    LOGFILE=your_schema_export_$(date +%Y%m%d%H%M%S).log \
    SCHEMAS=YOUR_SCHEMA_NAME \
    JOB_NAME=SCHEMA_EXPORT_YOUR_SCHEMA_NAME_$(date +%Y%m%d%H%M%S)

-- Data Pump Schema Import (Example)
-- Save as, e.g., schema_import.sh

#!/bin/bash
export ORACLE_SID=your_oracle_sid
export ORACLE_HOME=/path/to/your/oracle/home

impdp system/your_password@your_tns_alias \
    DIRECTORY=DATA_PUMP_DIR \
    DUMPFILE=your_schema_YYYYMMDDHHMMSS.dmp \
    LOGFILE=your_schema_import_YYYYMMDDHHMMSS.log \
    SCHEMAS=YOUR_SCHEMA_NAME \
    REMAP_SCHEMA=OLD_SCHEMA:NEW_SCHEMA \
    JOB_NAME=SCHEMA_IMPORT_YOUR_SCHEMA_NAME \
    TABLE_EXISTS_ACTION=REPLACE -- or SKIP, APPEND, TRUNCATE

-- To check Data Pump jobs:
-- SELECT * FROM DBA_DATAPUMP_JOBS;
-- SELECT * FROM V$DATAPUMP_JOB;

3.3. Archive Log Management
This script shows current archivelog information. RMAN is typically used for deletion.
-- Archive Log Information
SET LINESIZE 200
SET PAGESIZE 50

COLUMN NAME FORMAT A60
COLUMN STATUS FORMAT A10
COLUMN FIRST_TIME FORMAT A20
COLUMN NEXT_TIME FORMAT A20
COLUMN ARCHIVED FORMAT A10

SELECT
    SEQUENCE#,
    NAME,
    APPLIED,
    STATUS,
    TO_CHAR(FIRST_TIME, 'YYYY-MM-DD HH24:MI:SS') AS FIRST_TIME,
    TO_CHAR(NEXT_TIME, 'YYYY-MM-DD HH24:MI:SS') AS NEXT_TIME,
    DECODE(ARCHIVED, 'YES', 'ARCHIVED', 'NO', 'NOT ARCHIVED') AS ARCHIVED
FROM
    V$ARCHIVED_LOG
ORDER BY
    SEQUENCE# DESC
FETCH FIRST 20 ROWS ONLY; -- Adjust to see more recent archive logs

-- RMAN command to delete applied archivelogs (via OS command line):
-- rman target /
-- DELETE ARCHIVELOG ALL COMPLETED BEFORE 'SYSDATE - 7'; -- Delete archivelogs older than 7 days
-- DELETE NOLOG ARCHIVELOG ALL BACKED UP 1 TIMES TO DEVICE TYPE DISK;

4. Space Management
4.4. Tablespace Utilization and Growth Prediction
This script provides current tablespace usage and estimates growth based on historical data (requires Diagnostics Pack license for DBA_HIST_TBSPC_SPACE_USAGE).
-- Tablespace Utilization and Growth Prediction
SET LINESIZE 200
SET PAGESIZE 50

COLUMN TABLESPACE_NAME FORMAT A20
COLUMN TOTAL_SIZE_GB FORMAT 999999.99
COLUMN USED_SIZE_GB FORMAT 999999.99
COLUMN FREE_SIZE_GB FORMAT 999999.99
COLUMN USED_PERCENT FORMAT 999.99

SELECT
    D.TABLESPACE_NAME,
    ROUND(SUM(D.BYTES) / 1024 / 1024 / 1024, 2) AS TOTAL_SIZE_GB,
    ROUND(SUM(D.BYTES - NVL(F.BYTES, 0)) / 1024 / 1024 / 1024, 2) AS USED_SIZE_GB,
    ROUND(SUM(NVL(F.BYTES, 0)) / 1024 / 1024 / 1024, 2) AS FREE_SIZE_GB,
    ROUND((SUM(D.BYTES - NVL(F.BYTES, 0)) / SUM(D.BYTES)) * 100, 2) AS USED_PERCENT
FROM
    DBA_DATA_FILES D
LEFT JOIN
    DBA_FREE_SPACE F ON D.FILE_ID = F.FILE_ID AND D.TABLESPACE_NAME = F.TABLESPACE_NAME
GROUP BY
    D.TABLESPACE_NAME
ORDER BY
    USED_PERCENT DESC;

-- Tablespace Growth Prediction (requires Diagnostics Pack license)
-- This query provides a basic growth rate per tablespace based on the last 30 days.
-- More sophisticated prediction might involve trend analysis over a longer period.
SELECT
    TS.TABLESPACE_NAME,
    ROUND(SUM(SPACE_USED_DELTA * 8192) / 1024 / 1024 / 1024 / 30, 2) AS AVG_DAILY_GROWTH_GB
FROM
    DBA_HIST_TBSPC_SPACE_USAGE TS
WHERE
    TS.BEGIN_SNAP_ID >= (SELECT MAX(SNAP_ID) - 30 FROM DBA_HIST_SNAPSHOT) -- Last 30 days
GROUP BY
    TS.TABLESPACE_NAME
ORDER BY
    AVG_DAILY_GROWTH_GB DESC;

4.5. Datafile Usage Check
This script shows the details of each datafile, including its size and current usage.
-- Datafile Usage Check
SET LINESIZE 200
SET PAGESIZE 50

COLUMN FILE_NAME FORMAT A70
COLUMN TABLESPACE_NAME FORMAT A20
COLUMN TOTAL_SIZE_MB FORMAT 999999.99
COLUMN USED_SIZE_MB FORMAT 999999.99
COLUMN FREE_SIZE_MB FORMAT 999999.99
COLUMN USED_PERCENT FORMAT 999.99

SELECT
    D.FILE_NAME,
    D.TABLESPACE_NAME,
    ROUND(D.BYTES / 1024 / 1024, 2) AS TOTAL_SIZE_MB,
    ROUND((D.BYTES - NVL(F.BYTES, 0)) / 1024 / 1024, 2) AS USED_SIZE_MB,
    ROUND(NVL(F.BYTES, 0) / 1024 / 1024, 2) AS FREE_SIZE_MB,
    ROUND(((D.BYTES - NVL(F.BYTES, 0)) / D.BYTES) * 100, 2) AS USED_PERCENT,
    D.AUTOEXTENSIBLE,
    D.MAXBYTES / 1024 / 1024 AS MAX_SIZE_MB
FROM
    DBA_DATA_FILES D
LEFT JOIN
    DBA_FREE_SPACE F ON D.FILE_ID = F.FILE_ID AND D.TABLESPACE_NAME = F.TABLESPACE_NAME
ORDER BY
    D.TABLESPACE_NAME, D.FILE_NAME;

4.6. Identification of Fragmentation and Methods for Reorganization
Identifying fragmentation in Oracle is complex. Tablespace fragmentation is typically handled by automatic segment space management (ASSM). For table/index fragmentation, ANALYZE TABLE ... COMPUTE STATISTICS can give an indication, but the most direct way to reduce fragmentation is often by rebuilding the object.
-- Check Table Fragmentation (High-level indication)
-- This query provides a simple metric (chain_cnt) that can indicate row chaining/migration.
-- A high chain_cnt might suggest fragmentation, but it's not a definitive measure of performance impact.
SET LINESIZE 200
SET PAGESIZE 50

COLUMN OWNER FORMAT A15
COLUMN TABLE_NAME FORMAT A30
COLUMN NUM_ROWS FORMAT 9999999999
COLUMN AVG_ROW_LEN FORMAT 999999
COLUMN CHAIN_CNT FORMAT 99999999

SELECT
    OWNER,
    TABLE_NAME,
    NUM_ROWS,
    AVG_ROW_LEN,
    CHAIN_CNT
FROM
    ALL_TABLES
WHERE
    OWNER NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DBSNMP', 'SYSMAN', 'APEX_040200', 'APEX_PUBLIC_USER', 'ANONYMOUS', 'FLOWS_FILES', 'ORDSYS', 'MDSYS', 'OLAPSYS', 'EXFSYS', 'WMSYS', 'XDB', 'CTXSYS', 'ORDPLUGINS', 'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'MDDATA', 'AUDSYS', 'GSMADMIN_INTERNAL', 'LBACSYS', 'DIP', 'REMOTE_SCHEDULER_AGENT', 'APPQOSSYS', 'DVSYS', 'OJVMSYS', 'GGSYS')
AND CHAIN_CNT > 0 -- Focus on tables with chained rows
ORDER BY
    CHAIN_CNT DESC;

-- Methods for Reorganization:

-- 1. Online Table Reorganization (requires Oracle Partitioning or Advanced Compression Options for some methods)
-- ALTER TABLE schema.table_name MOVE TABLESPACE new_tablespace_name; -- This rebuilds the table.
-- ALTER TABLE schema.table_name MOVE; -- Moves to the same tablespace (rebuilds).
-- ALTER TABLE schema.table_name SHRINK SPACE CASCADE; -- For segments in ASSM tablespaces.

-- 2. Online Index Reorganization
-- ALTER INDEX schema.index_name REBUILD ONLINE;

-- 3. Export/Import (Full table rebuild)
-- Use Data Pump to export the table, then truncate and import. This is a more drastic method.

-- 4. Create Table As Select (CTAS) and then rename
-- CREATE TABLE new_table AS SELECT * FROM old_table;
-- DROP TABLE old_table;
-- ALTER TABLE new_table RENAME TO old_table;
-- (Requires recreating indexes, constraints, triggers, grants)

5. Security and Audit
5.1. User Privileges Review
These scripts help review granted roles and system/object privileges for users.
-- User Roles Review
SET LINESIZE 200
SET PAGESIZE 50

COLUMN GRANTED_ROLE FORMAT A30
COLUMN GRANTEE FORMAT A30
COLUMN ADMIN_OPTION FORMAT A10

SELECT
    GRANTEE,
    GRANTED_ROLE,
    ADMIN_OPTION
FROM
    DBA_ROLE_PRIVS
WHERE
    GRANTEE NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DBSNMP', 'SYSMAN', 'APEX_040200', 'APEX_PUBLIC_USER', 'ANONYMOUS', 'FLOWS_FILES', 'ORDSYS', 'MDSYS', 'OLAPSYS', 'EXFSYS', 'WMSYS', 'XDB', 'CTXSYS', 'ORDPLUGINS', 'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'MDDATA', 'AUDSYS', 'GSMADMIN_INTERNAL', 'LBACSYS', 'DIP', 'REMOTE_SCHEDULER_AGENT', 'APPQOSSYS', 'DVSYS', 'OJVMSYS', 'GGSYS')
ORDER BY
    GRANTEE, GRANTED_ROLE;

-- User System Privileges Review
SET LINESIZE 200
SET PAGESIZE 50

COLUMN GRANTEE FORMAT A30
COLUMN PRIVILEGE FORMAT A40
COLUMN ADMIN_OPTION FORMAT A10

SELECT
    GRANTEE,
    PRIVILEGE,
    ADMIN_OPTION
FROM
    DBA_SYS_PRIVS
WHERE
    GRANTEE NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DBSNMP', 'SYSMAN', 'APEX_040200', 'APEX_PUBLIC_USER', 'ANONYMOUS', 'FLOWS_FILES', 'ORDSYS', 'MDSYS', 'OLAPSYS', 'EXFSYS', 'WMSYS', 'XDB', 'CTXSYS', 'ORDPLUGINS', 'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'MDDATA', 'AUDSYS', 'GSMADMIN_INTERNAL', 'LBACSYS', 'DIP', 'REMOTE_SCHEDULER_AGENT', 'APPQOSSYS', 'DVSYS', 'OJVMSYS', 'GGSYS')
ORDER BY
    GRANTEE, PRIVILEGE;

-- User Object Privileges Review (Example for a specific schema/object)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN GRANTEE FORMAT A30
COLUMN OWNER FORMAT A15
COLUMN TABLE_NAME FORMAT A30
COLUMN PRIVILEGE FORMAT A20
COLUMN GRANTABLE FORMAT A10

SELECT
    GRANTEE,
    OWNER,
    TABLE_NAME,
    PRIVILEGE,
    GRANTABLE
FROM
    DBA_TAB_PRIVS
WHERE
    OWNER = 'YOUR_SCHEMA_NAME' -- Specify the schema
-- AND TABLE_NAME = 'YOUR_TABLE_NAME' -- Optionally specify a table
ORDER BY
    GRANTEE, TABLE_NAME, PRIVILEGE;

5.2. Audit Trail Queries
These queries help inspect the audit trail (if enabled). Unified Auditing is recommended for newer Oracle versions.
-- Standard Audit Trail (if enabled)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN OS_USERNAME FORMAT A20
COLUMN USERNAME FORMAT A20
COLUMN TIMESTAMP FORMAT A25
COLUMN ACTION_NAME FORMAT A20
COLUMN OBJECT_SCHEMA FORMAT A20
COLUMN OBJECT_NAME FORMAT A30
COLUMN SQL_TEXT FORMAT A70 WRAP

SELECT
    OS_USERNAME,
    USERNAME,
    TO_CHAR(TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP,
    ACTION_NAME,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    SQL_TEXT
FROM
    DBA_AUDIT_TRAIL
WHERE
    TIMESTAMP > SYSDATE - 7 -- Last 7 days
ORDER BY
    TIMESTAMP DESC
FETCH FIRST 100 ROWS ONLY;

-- Unified Audit Trail (recommended for 12c and later)
-- First, ensure unified auditing is enabled and policies are created.
-- Example: CREATE AUDIT POLICY login_audits_policy ACTIONS ALL ON LOGIN;
-- AUDIT POLICY login_audits_policy;

SET LINESIZE 200
SET PAGESIZE 50

COLUMN DBUSERNAME FORMAT A20
COLUMN EVENT_TIMESTAMP FORMAT A25
COLUMN ACTION_NAME FORMAT A20
COLUMN OBJECT_SCHEMA FORMAT A20
COLUMN OBJECT_NAME FORMAT A30
COLUMN SQL_TEXT FORMAT A70 WRAP

SELECT
    DBUSERNAME,
    TO_CHAR(EVENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') AS EVENT_TIMESTAMP,
    ACTION_NAME,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    SQL_TEXT
FROM
    UNIFIED_AUDIT_TRAIL
WHERE
    EVENT_TIMESTAMP > SYSDATE - 7 -- Last 7 days
ORDER BY
    EVENT_TIMESTAMP DESC
FETCH FIRST 100 ROWS ONLY;

5.3. Password Expiration and Security Settings
This script checks password expiration status and other important security-related parameters.
-- Password Expiration and User Status
SET LINESIZE 200
SET PAGESIZE 50

COLUMN USERNAME FORMAT A30
COLUMN ACCOUNT_STATUS FORMAT A20
COLUMN EXPIRY_DATE FORMAT A20
COLUMN PROFILE FORMAT A20
COLUMN AUTHENTICATION_TYPE FORMAT A20

SELECT
    USERNAME,
    ACCOUNT_STATUS,
    TO_CHAR(EXPIRY_DATE, 'YYYY-MM-DD HH24:MI:SS') AS EXPIRY_DATE,
    PROFILE,
    AUTHENTICATION_TYPE
FROM
    DBA_USERS
WHERE
    ACCOUNT_STATUS NOT IN ('OPEN', 'EXPIRED') -- Filter for locked/expired users
ORDER BY
    EXPIRY_DATE NULLS LAST, USERNAME;

-- Password Policy Settings (from profiles)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN PROFILE FORMAT A30
COLUMN RESOURCE_NAME FORMAT A30
COLUMN LIMIT FORMAT A30

SELECT
    P.PROFILE,
    R.RESOURCE_NAME,
    R.LIMIT
FROM
    DBA_PROFILES P,
    DBA_PROFILE_LIMITS R
WHERE
    P.PROFILE = R.PROFILE
AND R.RESOURCE_NAME IN ('FAILED_LOGIN_ATTEMPTS', 'PASSWORD_LIFE_TIME', 'PASSWORD_REUSE_TIME', 'PASSWORD_REUSE_GRACE_TIME', 'PASSWORD_VERIFY_FUNCTION')
ORDER BY
    P.PROFILE, R.RESOURCE_NAME;

6. High Availability and Standby Management
6.1. Data Guard Synchronization Checks
These scripts are critical for monitoring the health and synchronization of your Data Guard environment.
-- Data Guard Broker Status (DGMGRL command line is preferred for administration)
-- From OS command line: dgmgrl sys/password@primary_tns
-- DGMGRL> SHOW CONFIGURATION;
-- DGMGRL> SHOW DATABASE VERBOSE ALL;

-- Data Guard Standby Log Application Lag
SET LINESIZE 200
SET PAGESIZE 50

COLUMN NAME FORMAT A20
COLUMN SEQUENCE# FORMAT 99999999
COLUMN APPLIED FORMAT A10
COLUMN REGISTERED FORMAT A10
COLUMN THREAD# FORMAT 999
COLUMN FIRST_CHANGE# FORMAT 99999999999
COLUMN NEXT_CHANGE# FORMAT 99999999999

SELECT
    A.THREAD#,
    MAX(A.SEQUENCE#) AS LAST_ARCHIVED_SEQUENCE,
    MAX(B.SEQUENCE#) AS LAST_APPLIED_SEQUENCE,
    (MAX(A.SEQUENCE#) - MAX(B.SEQUENCE#)) AS LAG_COUNT
FROM
    V$ARCHIVED_LOG A,
    V$ARCHIVED_LOG B
WHERE
    A.DEST_ID = 1 -- Primary destination (adjust if needed)
AND B.DEST_ID = 2 -- Standby destination (adjust if needed)
AND A.APPLIED = 'YES' -- Only consider applied logs on primary (for comparison)
AND B.APPLIED = 'YES' -- Only consider applied logs on standby
GROUP BY
    A.THREAD#
ORDER BY
    A.THREAD#;

-- Data Guard Transport Lag and Apply Lag (V$DATAGUARD_STATS)
-- This view provides more comprehensive lag metrics for Data Guard 10gR2 and later.
SET LINESIZE 200
SET PAGESIZE 50

COLUMN NAME FORMAT A30
COLUMN VALUE FORMAT A20
COLUMN UNIT FORMAT A20
COLUMN TIME_COMPUTED FORMAT A25

SELECT
    NAME,
    VALUE,
    UNIT,
    TO_CHAR(TIME_COMPUTED, 'YYYY-MM-DD HH24:MI:SS') AS TIME_COMPUTED
FROM
    V$DATAGUARD_STATS
WHERE
    NAME IN ('transport lag', 'apply lag', 'apply finish time', 'redo apply rate')
ORDER BY
    TIME_COMPUTED DESC;

-- Data Guard Log File Gap
SELECT
    LF.THREAD#,
    LF.SEQUENCE# AS GAP_SEQUENCE
FROM
    V$ARCHIVED_LOG LF
WHERE
    LF.DEST_ID = 2 -- Standby destination
AND LF.APPLIED = 'NO'
AND NOT EXISTS (
    SELECT 1
    FROM V$ARCHIVED_LOG AP
    WHERE AP.THREAD# = LF.THREAD#
    AND AP.SEQUENCE# = LF.SEQUENCE#
    AND AP.DEST_ID = 1 -- Primary destination
    AND AP.APPLIED = 'YES'
)
ORDER BY LF.THREAD#, LF.SEQUENCE#;

6.2. RAC Cluster Status Scripts
These scripts help monitor the health and interconnect status of your Oracle Real Application Clusters (RAC).
-- RAC Instance Status
SET LINESIZE 200
SET PAGESIZE 50

COLUMN INST_ID FORMAT 99
COLUMN INSTANCE_NAME FORMAT A15
COLUMN HOST_NAME FORMAT A20
COLUMN STATUS FORMAT A10
COLUMN DATABASE_STATUS FORMAT A15
COLUMN STARTUP_TIME FORMAT A20

SELECT
    INST_ID,
    INSTANCE_NAME,
    HOST_NAME,
    STATUS,
    DATABASE_STATUS,
    TO_CHAR(STARTUP_TIME, 'YYYY-MM-DD HH24:MI:SS') AS STARTUP_TIME
FROM
    GV$INSTANCE
ORDER BY
    INST_ID;

-- RAC Interconnect Status (GV$IPC_STATS)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN INST_ID FORMAT 99
COLUMN STAT_NAME FORMAT A30
COLUMN VALUE FORMAT 999999999999999

SELECT
    INST_ID,
    STAT_NAME,
    VALUE
FROM
    GV$IPC_STATS
WHERE
    STAT_NAME IN ('GCS Messages Received', 'GCS Messages Sent', 'GES Messages Received', 'GES Messages Sent', 'kcmr message received count')
ORDER BY
    INST_ID, STAT_NAME;

-- RAC Cache Fusion Latency (GV$CR_BLOCK_SERVER)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN INST_ID FORMAT 99
COLUMN CURRENT_BLOCK_RECEIVE_TIME FORMAT 999999999999999 HEADING 'CR_BLOCK_RECEIVE_TIME_MICROSEC'
COLUMN TOTAL_CR_BLOCKS_SENT FORMAT 999999999999999

SELECT
    INST_ID,
    CURRENT_BLOCK_RECEIVE_TIME,
    TOTAL_CR_BLOCKS_SENT
FROM
    GV$CR_BLOCK_SERVER
ORDER BY
    INST_ID;

6.3. ASM Diskgroup Health Scripts
These scripts monitor the health and usage of your Automatic Storage Management (ASM) diskgroups.
-- ASM Diskgroup Usage
SET LINESIZE 200
SET PAGESIZE 50

COLUMN NAME FORMAT A20
COLUMN TYPE FORMAT A10
COLUMN TOTAL_MB FORMAT 99999999
COLUMN FREE_MB FORMAT 99999999
COLUMN USED_PERCENT FORMAT 999.99
COLUMN USABLE_FILE_MB FORMAT 99999999

SELECT
    NAME,
    TYPE,
    TOTAL_MB,
    FREE_MB,
    ROUND((1 - (FREE_MB / TOTAL_MB)) * 100, 2) AS USED_PERCENT,
    USABLE_FILE_MB
FROM
    V$ASM_DISKGROUP
ORDER BY
    USED_PERCENT DESC;

-- ASM Disk Status
SET LINESIZE 200
SET PAGESIZE 50

COLUMN DISK_GROUP_NAME FORMAT A20
COLUMN DISK_NAME FORMAT A20
COLUMN PATH FORMAT A50
COLUMN HEADER_STATUS FORMAT A15
COLUMN MODE_STATUS FORMAT A15
COLUMN STATE FORMAT A10
COLUMN READS FORMAT 9999999999
COLUMN WRITES FORMAT 9999999999
COLUMN BYTES_READ FORMAT 999999999999 HEADING 'BYTES_READ_GB'
COLUMN BYTES_WRITTEN FORMAT 999999999999 HEADING 'BYTES_WRITTEN_GB'

SELECT
    DG.NAME AS DISK_GROUP_NAME,
    D.NAME AS DISK_NAME,
    D.PATH,
    D.HEADER_STATUS,
    D.MODE_STATUS,
    D.STATE,
    D.READS,
    D.WRITES,
    ROUND(D.BYTES_READ / 1024 / 1024 / 1024, 2) AS BYTES_READ_GB,
    ROUND(D.BYTES_WRITTEN / 1024 / 1024 / 1024, 2) AS BYTES_WRITTEN_GB
FROM
    V$ASM_DISK D,
    V$ASM_DISKGROUP DG
WHERE
    D.GROUP_NUMBER = DG.GROUP_NUMBER
ORDER BY
    DISK_GROUP_NAME, DISK_NAME;

7. Patching and Upgrades
7.1. Database Version Checks
Simple script to identify the exact database version.
-- Database Version Check
SELECT * FROM V$VERSION;

-- Or simply:
SELECT VERSION FROM V$INSTANCE;

7.2. PSU/RU Patch Level Identification
Identifying the Patch Set Update (PSU) or Release Update (RU) level is crucial for patching and compliance.
-- PSU/RU Patch Level Identification
-- Method 1: Using SQL (if OPatch inventory is accessible via SQL)
SET LINESIZE 200
SET PAGESIZE 50

COLUMN PATCH_ID FORMAT A10
COLUMN PATCH_UID FORMAT A10
COLUMN DESCRIPTION FORMAT A70 WRAP
COLUMN INSTALL_TIME FORMAT A25

SELECT
    PATCH_ID,
    PATCH_UID,
    DESCRIPTION,
    TO_CHAR(INSTALL_TIME, 'YYYY-MM-DD HH24:MI:SS') AS INSTALL_TIME
FROM
    DBA_REGISTRY_SQLPATCH
ORDER BY
    INSTALL_TIME DESC;

-- Method 2: Using OPatch (preferred and most accurate)
-- This is an OS command. You'll typically run this from the Oracle Home.
-- Navigate to your Oracle Home, then to the OPatch directory:
-- cd $ORACLE_HOME/OPatch
-- ./opatch lsinventory -detail

-- This will provide a detailed list of all applied patches, including PSUs/RUs.

8. Routine Maintenance
8.1. Statistics Gathering Scripts
Automated statistics gathering is handled by DBMS_STATS and typically runs as part of the default maintenance window. However, you might need to run it manually for specific schemas or objects.
-- Check Last Statistics Gathering Time for Tables
SET LINESIZE 200
SET PAGESIZE 50

COLUMN OWNER FORMAT A15
COLUMN TABLE_NAME FORMAT A30
COLUMN LAST_ANALYZED FORMAT A20
COLUMN STALE_STATS FORMAT A10

SELECT
    OWNER,
    TABLE_NAME,
    TO_CHAR(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS') AS LAST_ANALYZED,
    DBMS_STATS.GET_PREF('STALE_PERCENT',OWNER,TABLE_NAME) AS STALE_STATS_THRESHOLD,
    DECODE(DBMS_STATS.GET_STALE_STATS(OWNER, TABLE_NAME), 1, 'YES', 'NO') AS STALE_STATS -- Requires 11gR2+
FROM
    ALL_TABLES
WHERE
    OWNER NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DBSNMP', 'SYSMAN', 'APEX_040200', 'APEX_PUBLIC_USER', 'ANONYMOUS', 'FLOWS_FILES', 'ORDSYS', 'MDSYS', 'OLAPSYS', 'EXFSYS', 'WMSYS', 'XDB', 'CTXSYS', 'ORDPLUGINS', 'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'MDDATA', 'AUDSYS', 'GSMADMIN_INTERNAL', 'LBACSYS', 'DIP', 'REMOTE_SCHEDULER_AGENT', 'APPQOSSYS', 'DVSYS', 'OJVMSYS', 'GGSYS')
ORDER BY
    LAST_ANALYZED DESC NULLS LAST;

-- Manual Statistics Gathering for a Schema (Example)
-- EXEC DBMS_STATS.GATHER_SCHEMA_STATS(OWNNAME => 'YOUR_SCHEMA_NAME', OPTIONS => 'GATHER AUTO', ESTIMATE_PERCENT => DBMS_STATS.AUTO_SAMPLE_SIZE, DEGREE => DBMS_STATS.AUTO_DEGREE, CASCADE => TRUE, NO_INVALIDATE => FALSE);

-- Manual Statistics Gathering for a Table (Example)
-- EXEC DBMS_STATS.GATHER_TABLE_STATS(OWNNAME => 'YOUR_SCHEMA_NAME', TABNAME => 'YOUR_TABLE_NAME', OPTIONS => 'GATHER AUTO', ESTIMATE_PERCENT => DBMS_STATS.AUTO_SAMPLE_SIZE, DEGREE => DBMS_STATS.AUTO_DEGREE, CASCADE => TRUE, NO_INVALIDATE => FALSE);

-- Check Global Statistics Preferences
SELECT
    DBMS_STATS.GET_PREF('AUTOSTATS_TARGET') AS AUTOSTATS_TARGET,
    DBMS_STATS.GET_PREF('DEGREE') AS DEGREE,
    DBMS_STATS.GET_PREF('METHOD_OPT') AS METHOD_OPT,
    DBMS_STATS.GET_PREF('CASCADE') AS CASCADE,
    DBMS_STATS.GET_PREF('NO_INVALIDATE') AS NO_INVALIDATE
FROM
    DUAL;

8.2. Schema Comparison Scripts
Schema comparison is best done with specialized tools, but a basic SQL script can highlight differences in object counts.
-- Schema Object Count Comparison (High-level)
-- Run this script on both databases you want to compare and then compare the output.
SET LINESIZE 200
SET PAGESIZE 50

COLUMN OWNER FORMAT A30
COLUMN OBJECT_TYPE FORMAT A30
COLUMN OBJECT_COUNT FORMAT 9999999999

SELECT
    OWNER,
    OBJECT_TYPE,
    COUNT(*) AS OBJECT_COUNT
FROM
    ALL_OBJECTS
WHERE
    OWNER NOT IN ('SYS', 'SYSTEM', 'OUTLN', 'DBSNMP', 'SYSMAN', 'APEX_040200', 'APEX_PUBLIC_USER', 'ANONYMOUS', 'FLOWS_FILES', 'ORDSYS', 'MDSYS', 'OLAPSYS', 'EXFSYS', 'WMSYS', 'XDB', 'CTXSYS', 'ORDPLUGINS', 'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'MDDATA', 'AUDSYS', 'GSMADMIN_INTERNAL', 'LBACSYS', 'DIP', 'REMOTE_SCHEDULER_AGENT', 'APPQOSSYS', 'DVSYS', 'OJVMSYS', 'GGSYS')
GROUP BY
    OWNER, OBJECT_TYPE
ORDER BY
    OWNER, OBJECT_TYPE;

-- For detailed schema comparison (DDL differences), you would typically use:
-- 1. Oracle SQL Developer: Tools -> Database Diff
-- 2. Oracle SQLcl: DDL command and then compare files.
-- 3. Third-party schema comparison tools (e.g., Redgate, Quest Toad).
-- 4. DBMS_METADATA.GET_DDL: To extract DDL for specific objects and then compare them.

-- Example using DBMS_METADATA (advanced for individual object comparison)
-- SELECT DBMS_METADATA.GET_DDL('TABLE', 'YOUR_TABLE_NAME', 'YOUR_SCHEMA_NAME') FROM DUAL;
-- SELECT DBMS_METADATA.GET_DDL('INDEX', 'YOUR_INDEX_NAME', 'YOUR_SCHEMA_NAME') FROM DUAL;

