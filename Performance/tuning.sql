prompt This query will extract the sql text for a give SQLID
set linesize 200
set pagesize 2000
set long 99000
select sql_text
---from gv$sqltext
from dba_hist_sqltext
where sql_id = '&sqlId'
/

prompt this query shows the sql id progrss

set line 200
col TARGET for a10;
col CLIENT_TOOL for a20;
col SQL_FULLTEXT for a20;
col PARSING_SCHEMA_NAME for a10;

SELECT 
opname
target,
ar.sql_id,
ROUND((sofar/totalwork),4)*100 Percentage_Complete,
start_time,
CEIL(TIME_REMAINING  /60) MAX_TIME_REMAINING_IN_MIN,
FLOOR(ELAPSED_SECONDS/60) TIME_SPENT_IN_MIN,
AR.SQL_FULLTEXT,
AR.PARSING_SCHEMA_NAME,
AR.MODULE client_tool
FROM gV$SESSION_LONGOPS L, V$SQLAREA AR
WHERE L.SQL_ID = AR.SQL_ID 
AND TOTALWORK > 0
AND ar.users_executing > 0
AND sofar != totalwork
and ar.sql_ID ='&sql_id';
