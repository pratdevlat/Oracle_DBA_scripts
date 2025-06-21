Oracle DBA BAU SQL Scripts Inventory

As an experienced Oracle DBA, you’ll appreciate the value of a well-curated set of SQL scripts for BAU activities. This inventory provides a comprehensive starting point. Always test these scripts in a non-production environment before deploying them to your production systems.

Important Considerations Before Use
	•	Permissions: Ensure the Oracle user executing these scripts has the necessary privileges (SELECT_CATALOG_ROLE, DBA role, specific object privileges).
	•	Schema: Most scripts query V$ views or DBA_ views.
	•	Customization: Adjust scripts based on your environment (schema names, tablespace names, retention policies).
	•	Error Handling: Add error handling and logging for automation.
	•	Tooling: Consider Oracle Enterprise Manager or third-party tools for advanced monitoring.

Contents

1. Monitoring and Diagnostics

1.1 Database Health Check Script

This script provides a quick overview of critical database parameters.

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
FROM V$INSTANCE I, V$DATABASE D;

SELECT 'Alert Log Location: ' || VALUE AS ALERT_LOG_LOCATION
FROM V$DIAG_INFO
WHERE NAME = 'Default Trace File' AND KEY = 'ADR_HOME';

1.2 Long-Running Queries

Identifies long-running SQL statements to pinpoint performance bottlenecks.

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
    S.SID, S.SERIAL#, S.USERNAME, S.OSUSER, S.PROGRAM, S.MODULE,
    S.WAIT_CLASS, S.EVENT, SQL.SQL_ID, SQL.SQL_TEXT,
    TRUNC(LAST_CALL_ET / 3600) || 'h ' ||
    TRUNC(MOD(LAST_CALL_ET, 3600) / 60) || 'm ' ||
    MOD(MOD(LAST_CALL_ET, 3600), 60) || 's' AS ELAPSED_TIME
FROM V$SESSION S, V$SQLAREA SQL
WHERE S.SQL_ID = SQL.SQL_ID(+)
AND S.STATUS = 'ACTIVE'
AND S.TYPE = 'USER'
AND S.LAST_CALL_ET > 300
ORDER BY LAST_CALL_ET DESC;

1.3 Sessions Causing Blocking

Identifies blocking sessions affecting performance.

-- Sessions Causing Blocking
SET LINESIZE 200
SET PAGESIZE 50

COLUMN BLOCKER_SID FORMAT 99999 HEADING 'BLOCKER_SID'
COLUMN BLOCKED_SID FORMAT 99999 HEADING 'BLOCKED_SID'
COLUMN WAIT_EVENT FORMAT A30 HEADING 'WAIT_EVENT'
COLUMN WAIT_TIME FORMAT 9999999 HEADING 'WAIT_TIME_CS'

-- [Complete SQL as provided]

2. Performance Tuning

2.1 Identify High Resource-Consuming Queries

-- High Resource-Consuming Queries
SET LINESIZE 200
SET PAGESIZE 50

-- [Complete SQL as provided]

3. Backup and Recovery

3.1 RMAN Backup Scripts

Example scripts for RMAN backups and restorations.

-- RMAN Full Database Backup
RUN {
    ALLOCATE CHANNEL d1 TYPE DISK;
    ALLOCATE CHANNEL d2 TYPE DISK;
    BACKUP DATABASE PLUS ARCHIVELOG DELETE INPUT;
    RELEASE CHANNEL d1;
    RELEASE CHANNEL d2;
}

4. Space Management

4.4 Tablespace Utilization and Growth Prediction

Analyzes current tablespace usage and predicts growth.

-- Tablespace Utilization and Growth Prediction
SET LINESIZE 200
SET PAGESIZE 50

-- [Complete SQL as provided]

5. Security and Audit

5.1 User Privileges Review

-- User Roles Review
SET LINESIZE 200
SET PAGESIZE 50

-- [Complete SQL as provided]

6. High Availability and Standby Management

6.1 Data Guard Synchronization Checks

Critical for monitoring Data Guard environment.

-- Data Guard Transport Lag and Apply Lag
SET LINESIZE 200
SET PAGESIZE 50

-- [Complete SQL as provided]

7. Patching and Upgrades

7.1 Database Version Checks

Simple database version identification.

SELECT VERSION FROM V$INSTANCE;

8. Routine Maintenance

8.1 Statistics Gathering Scripts

Manual statistics gathering examples.

EXEC DBMS_STATS.GATHER_SCHEMA_STATS(OWNNAME => 'YOUR_SCHEMA_NAME', OPTIONS => 'GATHER AUTO');

Ensure to adjust scripts based on your Oracle environment and compliance requirements.