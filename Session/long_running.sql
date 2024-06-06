/*************************************************************************
Check the ALL Active/Inactive session
**************************************************************************/

set linesize 750 pages 9999
column box format a30
column spid format a10
column username format a30 
column program format a30
column os_user format a20
col LOGON_TIME for a20  

select b.inst_id,b.sid,b.serial#,a.spid, substr(b.machine,1,30) box,to_char (b.logon_time, 'dd-mon-yyyy hh24:mi:ss') logon_time,
 substr(b.username,1,30) username,
 substr(b.osuser,1,20) os_user,
 substr(b.program,1,30) program,status,b.last_call_et AS last_call_et_secs,b.sql_id 
 from gv$session b,gv$process a 
 where b.paddr = a.addr 
 and a.inst_id = b.inst_id  
 and type='USER'
 order by logon_time;

/*************************************************************************
Check the all Active session
**************************************************************************/

set linesize 750 pages 9999
column box format a30
column spid format a10
column username format a30 
column program format a30
column os_user format a20
col LOGON_TIME for a20  

select b.inst_id,b.sid,b.serial#,a.spid, substr(b.machine,1,30) box,to_char (b.logon_time, 'dd-mon-yyyy hh24:mi:ss') logon_time,
 substr(b.username,1,30) username,
 substr(b.osuser,1,20) os_user,
 substr(b.program,1,30) program,status,b.last_call_et AS last_call_et_secs,b.sql_id 
 from gv$session b,gv$process a 
 where b.paddr = a.addr 
 and a.inst_id = b.inst_id  
 and type='USER' and b.status='ACTIVE'
 order by logon_time;


/*************************************************************************
Check the ALL Active/Inactive sessions by SID
**************************************************************************/

set linesize 750 pages 9999
column box format a30
column spid format a10
column username format a30 
column program format a30
column os_user format a20
col LOGON_TIME for a20  

select b.inst_id,b.sid,b.serial#,a.spid, substr(b.machine,1,30) box,to_char (b.logon_time, 'dd-mon-yyyy hh24:mi:ss') logon_time,
 substr(b.username,1,30) username,
 substr(b.osuser,1,20) os_user,
 substr(b.program,1,30) program,status,b.last_call_et AS last_call_et_secs,b.sql_id 
 from gv$session b,gv$process a 
 where b.paddr = a.addr 
 and a.inst_id = b.inst_id  
 and type='USER' and b.SID='&SID'
-- and b.status='ACTIVE'
-- and b.status='INACTIVE'
 order by logon_time;

/*************************************************************************
Check the ALL Active/Inactive sessions by Username
**************************************************************************/

set linesize 750 pages 9999
column box format a30
column spid format a10
column username format a30 
column program format a30
column os_user format a20
col LOGON_TIME for a20  

select b.inst_id,b.sid,b.serial#,a.spid, substr(b.machine,1,30) box,to_char (b.logon_time, 'dd-mon-yyyy hh24:mi:ss') logon_time,
 substr(b.username,1,30) username,
 substr(b.osuser,1,20) os_user,
 substr(b.program,1,30) program,status,b.last_call_et AS last_call_et_secs,b.sql_id 
 from gv$session b,gv$process a 
 where b.paddr = a.addr 
 and a.inst_id = b.inst_id  
 and type='USER' and b.username='&username'
-- and b.status='ACTIVE'
-- and b.status='INACTIVE'
 order by logon_time;


/*************************************************************************
SQL Monitor
**************************************************************************/
set lines 1000 pages 9999 
column sid format 9999 
column serial for 999999
column status format a15
column username format a10 
column sql_text format a80
column module format a30
col program for a30
col SQL_EXEC_START for a20

SELECT * FROM
       (SELECT status,inst_id,sid,SESSION_SERIAL# as Serial,username,sql_id,SQL_PLAN_HASH_VALUE,
     MODULE,program,
         TO_CHAR(sql_exec_start,'dd-mon-yyyy hh24:mi:ss') AS sql_exec_start,
         ROUND(elapsed_time/1000000)                      AS "Elapsed (s)",
         ROUND(cpu_time    /1000000)                      AS "CPU (s)",
         substr(sql_text,1,30) sql_text
       FROM gv$sql_monitor where status='EXECUTING' and module not like '%emagent%' 
       ORDER BY sql_exec_start  desc
       );

/*************************************************************************
---- Sql-Monitor report for a sql_id         ( Like OEM report)
**************************************************************************/
column text_line format a254
set lines 750 pages 9999
set long 20000 longchunksize 20000
select 
 dbms_sqltune.report_sql_monitor_list() text_line 
from dual;

select 
 dbms_sqltune.report_sql_monitor() text_line 
from dual;
