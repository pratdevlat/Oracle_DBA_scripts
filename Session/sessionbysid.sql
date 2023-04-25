    set verify off feedback off linesize 200 pagesize 90 echo off
    define session_id=378 -----sid

    col username format a22 head 'User Name' trunc
    col osuser format a12
    col inst_id for 99 head 'I'
    col sid format 99999
    col spid format a8     head "SHADOW"
    col process format a8  head "PROCESS"
    col serial# head Ser# format 99999999
    col terminal format a18 trunc
    col program  format a20 trunc
    col machine format a20  trunc
    col running_sec format a15   head "RUNNING_SECS"
    col sql_id for a13
    col sql for a110 trunc

    break on username on sid on serial# on osuser
    select 
        s.inst_id,
        s.username, osuser,
        s.sid, s.serial#,
        s.program,s.terminal,
        s.machine,s.process,
        p.spid,s.status,
        to_char(logon_time,'DD/MM/YYYY HH24:MI') logon_time,
        regexp_substr(NUMTODSINTERVAL(last_call_et, 'SECOND'),'+\d{2} \d{2}:\d{2}:\d{2}') running_sec
    from 
        gv$session s, 
        gv$process p
    where 
        p.addr (+) = s.paddr 
        and p.inst_id (+) = s.inst_id
        and s.sid=&session_id;
        
    prompt 
    set pages 0
    select 
        'Rows processed = ' || ROWS_PROCESSED || 
        ' (sql_id='||s.sql_id||')  first load time = ' || 
        FIRST_LOAD_TIME || '   ('||sid||','||serial#||')' ||chr(10) as sql, 
        'Event = ' || event
    from
        gv$sqlarea a , 
        gv$session s
    where 
        s.sid = &session_id
        and s.sql_id = a.sql_id 
        and s.inst_id=a.inst_id;
