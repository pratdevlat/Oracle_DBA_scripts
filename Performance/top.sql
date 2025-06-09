-- SQL Script: Top Resource-Consuming SQLs (CPU, I/O, Memory) - All-in-One

-- Current SQLs (from V$SQL)
-- ------------------------
SET LINESIZE 200
SET PAGESIZE 100

PROMPT "========== Current High-Resource SQLs =========="
SELECT
    sql_id,
    child_number,
    parsing_schema_name,
    executions,
    ROUND(cpu_time / 1e6, 2) AS cpu_time_sec,
    ROUND(elapsed_time / 1e6, 2) AS elapsed_time_sec,
    buffer_gets,
    disk_reads,
    rows_processed,
    ROUND(sharable_mem / 1024 / 1024, 2) AS sharable_mem_mb,
    SUBSTR(sql_text, 1, 100) AS sql_text
FROM
    v$sql
WHERE
    executions > 0
ORDER BY
    cpu_time DESC,
    disk_reads DESC,
    sharable_mem DESC
FETCH FIRST 20 ROWS ONLY;

-- Historical SQLs (from AWR, requires Diagnostics Pack)
-- ----------------------------------------------------
PROMPT "\n========== Historical High-Resource SQLs (AWR) =========="

-- Define snapshot range - customize as needed
DEFINE start_snap = 100;
DEFINE end_snap = 110;

SELECT
    s.sql_id,
    p.parsing_schema_name,
    SUM(s.cpu_time_delta) / 1e6 AS cpu_time_sec,
    SUM(s.elapsed_time_delta) / 1e6 AS elapsed_time_sec,
    SUM(s.buffer_gets_delta) AS buffer_gets,
    SUM(s.disk_reads_delta) AS disk_reads,
    SUM(s.executions_delta) AS executions,
    SUBSTR(q.sql_text, 1, 100) AS sql_text
FROM
    dba_hist_sqlstat s
JOIN
    dba_hist_sqltext q ON s.sql_id = q.sql_id
JOIN
    dba_hist_snapshot p ON s.snap_id = p.snap_id
WHERE
    s.snap_id BETWEEN &start_snap AND &end_snap
GROUP BY
    s.sql_id,
    p.parsing_schema_name,
    q.sql_text
ORDER BY
    cpu_time_sec DESC,
    disk_reads DESC,
    buffer_gets DESC
FETCH FIRST 20 ROWS ONLY;

-- Notes:
-- 1. Adjust &start_snap and &end_snap to your snapshot range.
-- 2. For V$SQL, you get currently cached statements only.
-- 3. For AWR, you get historical resource usage.
