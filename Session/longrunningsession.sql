-- SQL Script: Oracle Long Running Sessions Monitor for L1 DBA
-- Purpose: To identify sessions that have been actively running for a long time,
--          which might indicate a stuck process, inefficient query, or large batch job.

SET LINESIZE 200
SET PAGESIZE 100
COL INST_ID FORMAT 99 HEADING 'Inst|ID'
COL SID FORMAT 99999 HEADING 'SID'
COL SERIAL# FORMAT 99999 HEADING 'Serial#'
COL USERNAME FORMAT A15 HEADING 'User'
COL OSUSER FORMAT A15 HEADING 'OS User'
COL PROGRAM FORMAT A25 HEADING 'Program'
COL STATUS FORMAT A10 HEADING 'Status'
COL LAST_CALL_ET_MIN FORMAT 999999 HEADING 'Active For|Minutes'
COL SQL_ID FORMAT A15 HEADING 'SQL ID'
COL SQL_TEXT FORMAT A60 HEADING 'Current SQL Text' WORD_WRAP

-- Define the threshold for "long running" in SECONDS
-- Adjust this value based on your environment's typical workload
DEFINE LONG_RUNNING_THRESHOLD_SECONDS = 300 -- 5 minutes (300 seconds)

SELECT
    s.inst_id,
    s.sid,
    s.serial#,
    s.username,
    s.osuser,
    s.program,
    s.status,
    FLOOR(s.last_call_et / 60) AS last_call_et_min, -- Convert seconds to minutes
    s.sql_id,
    sq.sql_text
FROM
    GV$SESSION s
LEFT JOIN
    GV$SQLarea sq ON s.sql_id = sq.sql_id AND s.sql_child_number = sq.child_number AND s.inst_id = sq.inst_id
WHERE
    s.status = 'ACTIVE' -- Only show sessions currently executing
    AND s.type = 'USER' -- Exclude background processes
    AND s.last_call_et > &LONG_RUNNING_THRESHOLD_SECONDS -- Greater than our defined threshold
    AND s.sid != SYS_CONTEXT('USERENV', 'SID') -- Exclude the current session running this query
ORDER BY
    s.inst_id, last_call_et_min DESC;

PROMPT
PROMPT -- Explanation for L1 DBAs:
PROMPT -- This report helps find sessions that have been running for a suspiciously long time.
PROMPT -- This could mean a query is stuck, very inefficient, or it's a long but legitimate batch job.
PROMPT --
PROMPT -- INST_ID:        The Oracle RAC instance ID of the session.
PROMPT -- SID:            The unique session ID.
PROMPT -- SERIAL#:        Used with SID to uniquely identify a session.
PROMPT -- USER:           The database user connected.
PROMPT -- OS USER:        The operating system user running the client program.
PROMPT -- PROGRAM:        The application or process name (e.g., SQLPLUS.EXE, Java, app name).
PROMPT -- STATUS:         Should be 'ACTIVE' (meaning it's currently executing something).
PROMPT -- Active For Minutes: How many minutes the session has been actively running its current call.
PROMPT --                     This is the key metric for "long running."
PROMPT -- SQL ID:         A unique identifier for the SQL statement currently being executed.
PROMPT -- Current SQL Text: The actual SQL statement the session is running.
PROMPT --
PROMPT -- What to look for:
PROMPT --   - Sessions with a very high 'Active For Minutes' value.
PROMPT --   - Repetitive SQL_TEXT for multiple sessions, especially if they are all very long running.
PROMPT --   - Any sessions that are 'ACTIVE' but seem stuck (e.g., their 'Active For Minutes' keeps increasing
PROMPT --     significantly without completing).
PROMPT --
PROMPT -- Threshold: Currently set to 5 minutes (300 seconds). You can change this value (line 12: DEFINE LONG_RUNNING_THRESHOLD_SECONDS).
PROMPT --            Adjust it based on what's considered "normal" long-running for your specific database.
PROMPT --
PROMPT -- Action (for higher level DBAs):
PROMPT --   - Review the 'Current SQL Text' to understand what the session is doing.
PROMPT --   - Check if the SQL is performing a large data load, report, or complex calculation (might be normal).
PROMPT --   - Use SQL_ID to check its execution plan and past performance.
PROMPT --   - Consider if the session needs to be terminated if it's stuck or causing performance issues (with extreme caution!).
