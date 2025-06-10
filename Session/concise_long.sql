-- SQL Script: Comprehensive Long Running Session Monitor
-- Purpose: To provide detailed insights into active, long-running database sessions,
--          including performance metrics and current SQL text.
--          This script is for monitoring ONLY and has no impact on the database.

SET LINESIZE 280
SET PAGESIZE 100
SET FEEDBACK OFF -- Suppress "rows selected" message
SET VERIFY OFF   -- Suppress substitution variable verification

-- Column Definitions and Formatting
COL INST_ID FORMAT 99 HEADING 'Inst|ID'
COL SID FORMAT 99999 HEADING 'SID'
COL SERIAL# FORMAT 99999 HEADING 'Serial#'
COL USERNAME FORMAT A15 HEADING 'DB User'
COL OSUSER FORMAT A15 HEADING 'OS User'
COL PROGRAM FORMAT A30 HEADING 'Client Program'
COL MODULE FORMAT A25 HEADING 'Module'
COL STATUS FORMAT A10 HEADING 'Status'
COL LAST_CALL_ET_SEC FORMAT 9999999 HEADING 'Active|Seconds'
COL SQL_ID FORMAT A15 HEADING 'SQL ID'
COL SQL_CHILD_NUMBER FORMAT 9999 HEADING 'Child#'
COL SQL_EXEC_ID FORMAT 9999999999 HEADING 'SQL_Exec_ID'
COL SQL_EXEC_START FORMAT A20 HEADING 'SQL Start Time'
COL ELAPSED_TIME_SEC FORMAT 9999999999 HEADING 'SQL Elapsed|Seconds'
COL CPU_TIME_SEC FORMAT 9999999999 HEADING 'CPU|Seconds'
COL USER_IO_WAIT_TIME_SEC FORMAT 9999999999 HEADING 'I/O Wait|Seconds'
COL APPLICATION_WAIT_TIME_SEC FORMAT 9999999999 HEADING 'App Wait|Seconds'
COL CONCURRENCY_WAIT_TIME_SEC FORMAT 9999999999 HEADING 'Conc Wait|Seconds'
COL CLUSTER_WAIT_TIME_SEC FORMAT 9999999999 HEADING 'Cluster Wait|Seconds'
COL PHY_READ_BLKS FORMAT 9999999999 HEADING 'Physical|Reads'
COL LOG_READ_BLKS FORMAT 9999999999 HEADING 'Logical|Reads'
COL CURRENT_WAIT_EVENT FORMAT A30 HEADING 'Current Wait Event'
COL WAIT_SEC FORMAT 99999 HEADING 'Wait|Sec'
COL BLOCK_PROGRESS_PCT FORMAT 999.99 HEADING 'Progress %'
COL TIME_REMAINING_MIN FORMAT 999999 HEADING 'Time|Remaining|Mins'
COL SQL_TEXT FORMAT A80 HEADING 'Current SQL Statement (First 80 Chars)' WORD_WRAP

-- Define the threshold for "long running" in SECONDS
-- Adjust this value based on your environment's typical workload
DEFINE LONG_RUNNING_THRESHOLD_SECONDS = 300 -- Default: 5 minutes (300 seconds)

SELECT
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.osuser,
    s.program,
    s.module,
    s.status,
    s.last_call_et AS last_call_et_sec, -- Time in seconds since last database call
    s.sql_id,
    s.sql_child_number,
    s.sql_exec_id,
    TO_CHAR(s.sql_exec_start, 'YYYY-MM-DD HH24:MI:SS') AS sql_exec_start,
    -- Total elapsed time of the current SQL execution (from V$SQL_MONITOR/V$ACTIVE_SESSION_HISTORY if available)
    -- Fallback to s.last_call_et if sql_exec_start not available
    ROUND((SYSDATE - s.sql_exec_start) * 24 * 60 * 60) AS elapsed_time_sec,
    s.cpu_time_total AS cpu_time_sec,
    s.user_io_wait_time_total AS user_io_wait_time_sec,
    s.application_wait_time_total AS application_wait_time_sec,
    s.concurrency_wait_time_total AS concurrency_wait_time_sec,
    s.cluster_wait_time_total AS cluster_wait_time_sec,
    s.physical_reads AS phy_read_blks, -- Physical reads for the current SQL execution
    s.logical_reads AS log_read_blks,   -- Logical reads for the current SQL execution
    s.event AS current_wait_event,
    s.seconds_in_wait AS wait_sec,
    -- Progress for long operations (e.g., large sorts, backup/recovery, data loads)
    ROUND(CASE WHEN sl.totalwork != 0 THEN (sl.sofar / sl.totalwork) * 100 ELSE 0 END, 2) AS block_progress_pct,
    FLOOR(sl.time_remaining / 60) AS time_remaining_min,
    REPLACE(DBMS_LOB.SUBSTR(sq.sql_fulltext, 80, 1), CHR(10), ' ') AS sql_text
FROM
    GV$SESSION s
LEFT JOIN
    GV$SQLAREA sq ON s.sql_id = sq.sql_id AND s.sql_child_number = sq.child_number AND s.inst_id = sq.inst_id
LEFT JOIN
    GV$SESSION_LONGOPS sl ON s.sid = sl.sid AND s.inst_id = sl.inst_id
                         AND s.serial# = sl.serial#
                         AND sl.opname NOT LIKE '%aggregate%' -- Exclude internal aggregate operations
                         AND sl.totalwork > 0 -- Only show longops with reported progress
WHERE
    s.status = 'ACTIVE' -- Only show sessions currently executing
    AND s.type = 'USER' -- Exclude background processes
    AND s.last_call_et > &LONG_RUNNING_THRESHOLD_SECONDS -- Greater than our defined threshold
    AND s.sid != SYS_CONTEXT('USERENV', 'SID') -- Exclude the current session running this query
ORDER BY
    s.inst_id, last_call_et_sec DESC;

PROMPT
PROMPT ---
PROMPT -- Analysis and Interpretation for DBAs (All Levels)
PROMPT ---
PROMPT -- This report provides a detailed view of active sessions exceeding the defined long-running threshold
PROMPT -- (currently &LONG_RUNNING_THRESHOLD_SECONDS seconds). It's a read-only script designed for monitoring
PROMPT -- and diagnostic purposes, with no impact on the database.
PROMPT --
PROMPT -- Key Metrics for Analysis:
PROMPT --
PROMPT -- 1.  **Session Identification**:
PROMPT --     - **Inst ID, SID, Serial#**: Uniquely identifies the session.
PROMPT --     - **DB User, OS User, Client Program, Module**: Helps pinpoint the application, user, and source of the activity.
PROMPT --
PROMPT -- 2.  **Duration and Status**:
PROMPT --     - **Active Seconds**: Time in seconds since the session's last database call. A constantly increasing value
PROMPT --       for an 'ACTIVE' session indicates it's still busy.
PROMPT --     - **SQL Start Time**: When the current SQL statement began execution.
PROMPT --     - **SQL Elapsed Seconds**: Total time (in seconds) that the current SQL statement has been running.
PROMPT --
PROMPT -- 3.  **Resource Consumption (from V$SESSION)**:
PROMPT --     - **CPU Seconds**: Total CPU time consumed by the session's operations. High CPU time indicates a CPU-bound process.
PROMPT --     - **I/O Wait Seconds**: Total time spent waiting for I/O operations to complete (e.g., reading from disk). High I/O wait suggests
PROMPT --       poor indexing, full table/index scans, or slow storage.
PROMPT --     - **App Wait Seconds**: Time spent waiting for application-level events (e.g., row cache lock, library cache lock).
PROMPT --     - **Conc Wait Seconds**: Time spent waiting for concurrency-related events (e.g., latch contention, enqueue contention).
PROMPT --     - **Cluster Wait Seconds**: Time spent waiting for Cache Fusion related events in a RAC environment.
PROMPT --     - **Physical Reads (Blocks)**: Number of data blocks read directly from disk.
PROMPT --     - **Logical Reads (Blocks)**: Number of data blocks read from buffer cache (memory) or disk. High logical reads can indicate inefficient SQL.
PROPT --
PROMPT -- 4.  **Current Activity & Progress**:
PROMPT --     - **SQL ID, Child#**: Identifiers for the currently executing SQL. Use `DBMS_XPLAN.DISPLAY_AWR` or `V$SQL_PLAN` with these for execution plan analysis.
PROMPT --     - **Current Wait Event**: What the session is *currently* waiting for. This is crucial for diagnosing bottlenecks.
PROMPT --       - `CPU time`: Session is actively working on CPU.
PROMPT --       - `db file sequential/scattered read`: Waiting for I/O.
PROMPT --       - `enq: TX - row lock contention`: Blocked by another transaction (check blocking sessions).
PROMPT --       - `log file sync`: Waiting for redo to be written to disk (commit-related).
PROMPT --       - `library cache lock/pin`: Contention on shared pool objects.
PROMPT --     - **Wait Sec**: Duration of the *current* wait event.
PROMPT --     - **Progress %**: For long operations (reported in `V$SESSION_LONGOPS`), this shows estimated completion.
PROMPT --     - **Time Remaining Mins**: Estimated time until completion for long operations.
PROMPT --     - **Current SQL Statement**: The start of the SQL being executed. Use `SELECT SQL_FULLTEXT FROM V$SQL WHERE SQL_ID = '...'` for the full text.
PROMPT --
PROMPT -- Diagnostic Flow:
PROMPT -- 1.  **Identify Long-Running Sessions**: Start by examining `Active Seconds`.
PROMPT -- 2.  **Understand "What"**: Look at `Client Program`, `DB User`, and `Current SQL Statement` to identify the operation.
PROMPT -- 3.  **Understand "Why"**:
PROMPT --     - Check `Current Wait Event`: Is it CPU-bound, I/O-bound, waiting on locks, or something else?
PROMPT --     - Review resource metrics (`CPU Seconds`, `I/O Wait Seconds`, `Physical Reads`, `Logical Reads`).
PROMPT -- 4.  **Check Progress**: For operations reporting `Progress %` and `Time Remaining`, assess if it's normal behavior for a large task.
PROMPT --
PROMPT -- Further Investigation (based on findings):
PROMPT --   - If **blocked**: Use a blocking session script (`GV$SESSION` `BLOCKING_SESSION` column).
PROMPT --   - If **high CPU/I/O**: Analyze the SQL execution plan (`DBMS_XPLAN.DISPLAY_AWR`, `V$SQL_PLAN`), consider missing indexes, statistics, or inefficient joins.
PROMPT --   - If **application/concurrency waits**: Investigate the application code, database design, or potential contention points.
PROMPT --   - Use **ASH (`V$ACTIVE_SESSION_HISTORY`)** for a granular historical view of activity.
PROMPT --   - Use **AWR/Statspack reports** for broader performance trends.
PROMPT --
PROMPT -- Important Note: This script is for observation only. Any actions (e.g., killing sessions, modifying SQL,
PROMPT -- changing parameters) must be performed by experienced DBAs with a clear understanding of the impact.
SET FEEDBACK ON
SET VERIFY ON
