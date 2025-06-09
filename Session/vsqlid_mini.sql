-- === 1. Show Session Details for SQL_ID ===
SET LINESIZE 200
SET PAGESIZE 100
PROMPT '========== Session Details =========='

SELECT
    s.sid,
    s.serial#,
    s.username,
    s.status,
    s.osuser,
    s.machine,
    s.program,
    s.sql_id,
    s.sql_child_number,
    s.event,
    s.wait_class,
    s.seconds_in_wait,
    s.state
FROM
    v$session s
WHERE
    s.sql_id = '&sql_id';

-- === 2. Show Current Execution Plan (Cursor) ===
PROMPT '========== Execution Plan =========='

SELECT * 
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', NULL, 'ALLSTATS LAST'));

-- === 3. Show Alternate Plans ===
PROMPT '========== Alternate Plans =========='

-- Option 1: If SQL Baselines exist
SELECT
    sql_handle,
    plan_name,
    enabled,
    accepted,
    fixed,
    optimizer_cost,
    last_verified,
    origin
FROM
    dba_sql_plan_baselines
WHERE
    sql_text LIKE (
        SELECT sql_text 
        FROM v$sqlarea
        WHERE sql_id = '&sql_id'
        AND rownum = 1
    );

-- Option 2: AWR Historical Plans
SELECT
    sql_id,
    plan_hash_value,
    COUNT(*) AS executions,
    ROUND(SUM(cpu_time_delta)/1e6,2) AS cpu_time_sec,
    ROUND(SUM(elapsed_time_delta)/1e6,2) AS elapsed_time_sec
FROM
    dba_hist_sqlstat
WHERE
    sql_id = '&sql_id'
GROUP BY
    sql_id, plan_hash_value
ORDER BY
    cpu_time_sec DESC;

-- === 4. Show Objects Involved (Tables/Indexes) and Stats ===
PROMPT '========== Object Statistics =========='

SELECT
    o.owner,
    o.object_name,
    o.object_type,
    s.num_rows,
    s.blocks,
    s.avg_row_len,
    s.last_analyzed
FROM
    dba_objects o
JOIN
    dba_tab_statistics s
    ON o.owner = s.owner AND o.object_name = s.table_name
WHERE
    o.object_name IN (
        SELECT object_name
        FROM v$sql_plan
        WHERE sql_id = '&sql_id'
    )
ORDER BY
    o.owner, o.object_name;

-- === 5. Run SQL Tuning Advisor ===
PROMPT '========== SQL Tuning Advisor Report =========='

-- Create tuning task
DECLARE
    l_task_name VARCHAR2(30);
BEGIN
    l_task_name := 'SQL_TUNING_' || '&sql_id';
    DBMS_SQLTUNE.DROP_TUNING_TASK(l_task_name); -- drop if exists
    DBMS_SQLTUNE.CREATE_TUNING_TASK(
        sql_id => '&sql_id',
        task_name => l_task_name
    );
    DBMS_SQLTUNE.EXECUTE_TUNING_TASK(l_task_name);

    DBMS_OUTPUT.PUT_LINE('Use the following query to display the report:');
    DBMS_OUTPUT.PUT_LINE('SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK(''' || l_task_name || ''') FROM dual;');
END;
/

-- To display the tuning report
PROMPT 'Run this manually to see the SQL Tuning Advisor output:'
PROMPT 'SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK(''SQL_TUNING_&sql_id'') FROM dual;'
