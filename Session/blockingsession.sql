-- SQL Script: Oracle Blocking Sessions Monitor for L1 DBA
-- Purpose: To identify sessions that are currently blocking other sessions
--          and to see what resource they are blocking.

SET LINESIZE 200
SET PAGESIZE 100
COL BLOCKING_INST_ID FORMAT 99 HEADING 'Blocking|Inst ID'
COL BLOCKING_SID FORMAT 99999 HEADING 'Blocking|SID'
COL BLOCKING_SERIAL# FORMAT 99999 HEADING 'Blocking|Serial#'
COL BLOCKING_USERNAME FORMAT A15 HEADING 'Blocking|User'
COL BLOCKING_PROGRAM FORMAT A25 HEADING 'Blocking|Program'
COL BLOCKED_INST_ID FORMAT 99 HEADING 'Blocked|Inst ID'
COL BLOCKED_SID FORMAT 99999 HEADING 'Blocked|SID'
COL BLOCKED_SERIAL# FORMAT 99999 HEADING 'Blocked|Serial#'
COL BLOCKED_USERNAME FORMAT A15 HEADING 'Blocked|User'
COLLED BLOCKED_PROGRAM FORMAT A25 HEADING 'Blocked|Program'
COL WAIT_EVENT FORMAT A35 HEADING 'Blocked Session|Wait Event'
COL SQL_TEXT FORMAT A60 HEADING 'Blocked Session|SQL Text' WORD_WRAP

SELECT
    s1.inst_id AS blocking_inst_id,
    s1.sid AS blocking_sid,
    s1.serial# AS blocking_serial#,
    s1.username AS blocking_username,
    s1.program AS blocking_program,
    s2.inst_id AS blocked_inst_id,
    s2.sid AS blocked_sid,
    s2.serial# AS blocked_serial#,
    s2.username AS blocked_username,
    s2.program AS blocked_program,
    sw.event AS wait_event,
    sq.sql_text AS sql_text
FROM
    GV$SESSION s1
JOIN
    GV$SESSION s2 ON s1.sid = s2.blocking_session AND s1.inst_id = s2.blocking_instance
LEFT JOIN
    GV$SESSION_WAIT sw ON s2.sid = sw.sid AND s2.inst_id = sw.inst_id
LEFT JOIN
    GV$SQLarea sq ON s2.sql_id = sq.sql_id AND s2.sql_child_number = sq.child_number AND s2.inst_id = sq.inst_id
WHERE
    s2.blocking_session IS NOT NULL
ORDER BY
    s1.inst_id, s1.sid;

PROMPT
PROMPT -- Explanation for L1 DBAs:
PROMPT -- This report identifies sessions that are causing a "bottleneck" by holding a resource
PROMPT -- that other sessions need, making those other sessions wait.
PROMPT --
PROMPT -- Blocking Session (the one causing the wait):
PROMPT --   - Blocking Inst ID: The Oracle RAC instance ID of the blocking session.
PROMPT --   - Blocking SID:     The unique session ID of the blocking session.
PROMPT --   - Blocking Serial#: Used with SID to uniquely identify a session across reboots.
PROMPT --   - Blocking User:    The database user connected for the blocking session.
PROMPT --   - Blocking Program: The application or process name of the blocking session.
PROMPT --                       (e.g., SQLPLUS.EXE, JDBC Thin Client, specific application name)
PROMPT --
PROMPT -- Blocked Session (the one waiting for the resource):
PROMPT --   - Blocked Inst ID:  The Oracle RAC instance ID of the blocked session.
PROMPT --   - Blocked SID:      The unique session ID of the blocked session.
PROMPT --   - Blocked Serial#:  Used with SID to uniquely identify the blocked session.
PROMPT --   - Blocked User:     The database user connected for the blocked session.
PROMPT --   - Blocked Program:  The application or process name of the blocked session.
PROMPT --
PROMPT -- Blocked Session Details:
PROMPT --   - Wait Event:   What the blocked session is currently waiting for.
PROMPT --                   Common blocking events: 'enq: TX - row lock contention', 'enq: TM - contention'
PROMPT --                   If you see these, it confirms a blocking issue.
PROMPT --   - SQL Text:     The SQL statement that the BLOCKED session is trying to execute.
PROMPT --                   Understanding this can help diagnose the problem.
PROMPT --
PROMPT -- What to look for:
PROMPT --   - Any results: If this script returns rows, you have blocking sessions.
PROMPT --   - The 'Blocking Program' and 'Blocking User': Can help identify the source of the issue.
PROMPT --   - The 'Wait Event' of the blocked session: Confirm it's related to locks (e.g., 'enq: TX').
PROMPT --   - The 'SQL Text' of the blocked session: What operation is stuck?
PROMPT --
PROMPT -- Action (for higher level DBAs):
PROMPT --   - Investigate the SQL being run by the blocking session.
PROMPT --   - Determine if the blocking session is idle in transaction or actively running.
PROMPT --   - Potentially terminate the blocking session if it's stuck and impacting critical operations (with caution!).
