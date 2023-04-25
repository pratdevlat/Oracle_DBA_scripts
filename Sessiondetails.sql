----Active Sessions Short
----------------------------

    set linesize    240
    set pages       900
    set feedback    off
    set verify  off

    col SID         for 99999 trunc
    col running_sec for a11 head "ELAP_SEC"
    col inst_id     for 9 trunc head "I"
    col serial#     for 99999 trunc     head SER#
    col username    for a13 trunc       head "USERNAME"
    col osuser      for a10 trunc       head "OSUSER"
    col status      for a3 trunc            head "STAT"
    col machine     for a10 trunc
    col process     for a7 trunc        head "RPID"
    col spid        for a6 trunc        head "SPID"
    col program     for a23 trunc
    col module      for a13 trunc
    col temp_mb     for 999999              head "TEMP_MB"
    col undo_mb     for 999999              head "UNDO_MB"
    col logon_time  for a11
    col rm_grp      for a5 trunc
    col sql_id      for a13
    col sql         for a110 trunc
    col tsps        for a6 trunc

    with showsess as
    (
       SELECT /*+ materialize first_rows */ distinct
                inst_id,
                sid,
                serial#,
                username,
                substr(osuser,1,10) osuser,
                status,
                process,
                replace(replace(replace(machine,'.att.com',''),'ITSERVICES\',''),'WORKGROUP\','') machine,
                replace(program,'(TNS V1-V3)','') program,
                regexp_substr(NUMTODSINTERVAL(nvl((SYSDATE-SQL_EXEC_START)*24*60*60,last_call_et), 'SECOND'),'+\d{2} \d{2}:\d{2}:\d{2}') running_sec,
                action,
                sql_id
        FROM
                gv$session sess
        WHERE
              status='ACTIVE' and username is not null and (nvl(sess.username,'%') like '$USER_NAME' )
        ORDER BY running_sec desc,4,1,2,3
    )
    select distinct
        a.inst_id,
        sid,
        serial#,
        username,
        osuser,
        status,
        process,
        machine,
        program,
        running_sec,
        a.sql_id,
        decode(a.action,null,'',a.action||', ')||replace(s.sql_text,chr(13),' ') sql
   from showsess a, gv$sqlarea s
    where rownum<50 and a.sql_id = s.sql_id (+) and a.inst_id=s.inst_id(+) ORDER BY running_sec desc,4,1,2,3 ;
 
 
 ----Active Session Full
------------------------
    set linesize    240
    set pages       900
    set feedback    off
    set verify  off

    col SID         for 99999 trunc
    col running_sec for a11 head "ELAP_SEC"
    col inst_id     for 9 trunc head "I"
    col serial#     for 99999 trunc     head SER#
    col username    for a13 trunc       head "USERNAME"
    col osuser      for a10 trunc       head "OSUSER"
    col status      for a3 trunc            head "STAT"
    col machine     for a10 trunc
    col process     for a7 trunc        head "RPID"
    col spid        for a6 trunc        head "SPID"
    col program     for a18 trunc
    col module      for a13 trunc
    col temp_mb     for 999999              head "TEMP_MB"
    col undo_mb     for 999999              head "UNDO_MB"
    col logon_time  for a11
    col rm_grp      for a5 trunc
    col sql_id      for a13
    col sql         for a47 trunc
    col tsps        for a6 trunc
    with show_sess as
    (
        select /*+ materialize */ * from
        (
            select * from gv$session
            where
                 status='ACTIVE' and username is not null
            order by nvl((SYSDATE-SQL_EXEC_START)*24*60*60,last_call_et) desc
        )
        where rownum<50
    )
    SELECT /*+ no_merge(s) */ distinct
            sess.inst_id,
            sess.sid,
            sess.serial#,
            sess.username,
            rm.rm_grp,
            substr(osuser,1,10) osuser,
            status,
            sess.process,
            proc.spid,
            replace(replace(replace(sess.machine,'.att.com',''),'ITSERVICES\',''),'WORKGROUP\','') machine,
            replace(sess.program,'(TNS V1-V3)','') program,
            regexp_substr(NUMTODSINTERVAL(nvl((SYSDATE-SQL_EXEC_START)*24*60*60,last_call_et), 'SECOND'),'+\d{2} \d{2}:\d{2}:\d{2}') running_sec,
            TEMP_MB, UNDO_MB,
            s.sql_id ,
            TSPS.NAME TSPS,
            decode(sess.action,null,'',sess.action||', ')||replace(s.sql_text,chr(13),' ') sql
    FROM
            show_sess sess,
            gv$process proc,
            gv$sqlarea s,
            (select inst_id, ses_addr as saddr,sum(used_ublk/128) UNDO_MB from gv$transaction group by inst_id, ses_addr) undo,
            (select session_addr as saddr, SESSION_NUM serial#, sum((blocks/128)) TEMP_MB from gv$sort_usage group by  session_addr, SESSION_NUM) tmp,
            (SELECT distinct se.inst_id, se.sid, co.name rm_grp FROM gv$rsrc_session_info se, gv$rsrc_consumer_group co WHERE se.current_consumer_group_id = co.id) rm,
            (select inst_id,sid,serial#,event,t.name from gv$session ls, sys.file$ f, sys.ts$ t where status='ACTIVE' and ls.p1text in ('file number','file#') and 
              ls.p1=f.file#  and f.ts#=t.ts#) tsps
    WHERE sess.inst_id=proc.inst_id (+)
    and   sess.saddr=tmp.saddr (+) and sess.serial#=tmp.serial# (+)
    and   sess.sid=rm.sid (+) and sess.inst_id=rm.inst_id(+)
    and   sess.sid=tsps.sid (+) and sess.inst_id=tsps.inst_id(+) and sess.serial#=tsps.serial#(+)
    AND   sess.paddr=proc.addr (+)
    and   sess.sql_id = s.sql_id (+) and sess.inst_id=s.inst_id(+)
    and   sess.saddr=undo.saddr (+) and sess.inst_id=undo.inst_id(+)
    ORDER BY running_sec desc,4,1,2,3
    ;



----Parallel Sessions
----------------------------------------

    set pages 1000 lines 290 feedback off trims on
    break on STS skip 1
    alter session set "_hash_join_enabled"=true;
    col Mstr for 99999
    col SQL_TEXT for a80 trunc
    col STS for a3 trunc
    compute sum of para on STS
    compute sum of temp_gb on STS
    compute sum of undo_gb on STS
    compute sum of reqpar on STS
    col sql_id for a13
    col para for 9999
    col reqpar for 9999
    col Machine for a12 trunc
    col module for a14 trunc
    col usr for a12 trunc head USER_NAME
    col secs for a12 head "ELAPSED"
    col temp_gb for 9999.9
    col undo_gb for 9999.9
    col serial# for 9999999
    col rm_grp for a8 trunc
    col Os_User for a10 trunc
    col log_time for a5 head LOGIN
    col i for 9
    set heading on
    WITH SHOWPARALLEL as
    (
        select /*+ ordered use_hash(a,b,t,p,undo,tmp) */
            a.inst_id as i,
            a.qcsid Mstr,
            b.serial#,
            count(*)-1 para ,
            sum(req_degree) / nvl(avg(degree)+0.01,1) reqpar,
            b.status as STS,
            b.sql_id,
            b.module,
            replace(replace(b.machine,'ITSERVICES\',''),'WORKGROUP\','') machine ,
            osuser Os_User,
            b.username usr,
            max(regexp_substr(NUMTODSINTERVAL(nvl((SYSDATE-SQL_EXEC_START)*24*60*60,last_call_et), 'SECOND'),'+\d{2} \d{2}:\d{2}:\d{2}')) secs,
            sum(temp_gb) as temp_gb ,
            sum(undo_gb) as undo_gb ,
            to_char(logon_time,'HH24:MI') log_time
        from  gv$px_session a, gv$session  b,
            (select inst_id, ses_addr as saddr,sum(used_ublk/128/1024) UNDO_GB from gv\$transaction group by inst_id, ses_addr) undo,
            (select inst_id, session_addr as saddr, SESSION_NUM serial#, sum((blocks/128/1024)) TEMP_GB from gv\$sort_usage group by inst_id, session_addr, SESSION_NUM) tmp
        where
            a.qcsid = b.sid and a.inst_id=b.inst_id
            and   a.saddr=undo.saddr (+) and a.inst_id=undo.inst_id (+)
            and   a.saddr=tmp.saddr (+) and a.serial#=tmp.serial# (+) and a.inst_id=tmp.inst_id (+)
        group by
            a.inst_id,a.qcsid,b.serial#,b.process ,b.machine,b.osuser,b.username,b.sql_id,b.module,logon_time,b.status
        order by b.status, secs desc,sql_id
    )
    select
        distinct
        prl.*,
        sql_text
    from
        showparallel prl, gv$sqlarea t
    where
        prl.sql_id=t.sql_id (+)
        and  prl.i=t.inst_id (+)  order by sts, secs desc, prl.sql_id;


----------------------------------------------------------------
----Check when last time object is used
----------------------------------------------------------------
select sql_id , sql_text
from dba_hist_sqltext
where
lower(sql_text) like lower('%&sqltext%')
and sql_id=nvl('&sqlid',sql_id)
and dbid=nvl('&dbid',dbid)
/



------------------------
----Session History
------------------------
    set feedback off echo off tab off trimout on trimspool on linesize 250 pagesize 1000 verify off
    
    define min_to_check=20
    
    col inst_id for 99 head 'I'
    col machine for a9 word_wrapped
    col module for a25 head MODULE trunc
    col AVG_SECS_PER_EXEC  for 99,999.99 heading 'Avg Secs|Per Exec'
    col CPU_PCT for 999.9 heading 'CPU PCT'
    col IO_PCT for 999.9 heading 'IO PCT'
    col EXECUTIONS for 999,999,999 heading 'Total Execs|Per SQL_ID'
    col OSUSER for a9 word_wrapped
    col TXT for a30 word_wrapped  heading 'TXT'
    col SQL for a110 heading SQL trunc
    col sess for a12 heading 'Active|SID:SERIAL#' justify center
    col username for a8
    col QC_SID for a10 heading 'PQ|SID:SERIAL#' justify center

    prompt #######################################################################
    prompt # Summary: Top 20 CPU consuming  SQLIDs for last &min_to_check minutes
    prompt #######################################################################
    --
    select distinct ash.inst_id, ash.sql_id,ash.cpu_pct,cc.module,replace(replace(substr(cc.sql_text,1,300),chr(10),' '),chr(13),' ') as SQL
    FROM
    (
        select
            inst_id,
            sql_id,
            round(ratio_to_report (CPU) over () *100,2) as cpu_pct
        from
        (
            select inst_id, sql_id,sum(decode(session_state,'ON CPU',1,0)) CPU
            from gv$active_session_history
            where session_state='ON CPU'
            and sample_time > sysdate - ((1/1440)* &min_to_check )
            and sql_id is not null
            group by inst_id,sql_id,event,wait_class,session_state
            order by 2 desc
        )
        where rownum < 21
    ) ash,
    gv$sqlarea cc
    where ash.sql_id  = cc.sql_id(+) and ash.inst_id=cc.inst_id(+)
    order by 3 desc;

    prompt
    prompt #######################################################################
    prompt # Summary: Top 20 CPU consuming  SQLIDs for last &min_to_check minutes
    prompt #######################################################################
    --
    select distinct ash.inst_id, ash.sql_id,ash.io_pct,cc.module,replace(replace(substr(cc.sql_text,1,300),chr(10),' '),chr(13),' ') as SQL
    FROM
    (
    select
         inst_id, 
         sql_id,
         round(ratio_to_report (IO) over () *100,2) as io_pct
    from
    (
        select ash.inst_id, ash.sql_id,sum(decode(ash.session_state,'WAITING',decode(en.wait_class,'User I/O',1,0),0)) IO
        from gv$active_session_history ash , gv$event_name en
        where ash.sql_id is not null and en.event#=ash.event# and en.inst_id=ash.inst_id
        and ash.sample_time > sysdate - ((1/1440)* &min_to_check )
        group by ash.inst_id,sql_id
        order by 3 desc
    )
    where rownum < 21
    ) ash,
    gv$sqlarea cc
    where ash.sql_id  = cc.sql_id(+) and ash.inst_id=cc.inst_id(+)
    order by 3 desc
;

#######################################################################
# Summary: Top 20 CPU consuming  SQLIDs for last 20 minutes
#######################################################################



#######################################################################
# Summary: Top 20 CPU consuming  SQLIDs for last 20 minutes
#######################################################################




----------------------------
----Session By SID
----------------------------
    set verify off feedback off linesize 200 pagesize 90 echo off
    define session_id=378

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







----------------------------
----Session Cursors By SID
----------------------------
define session_id=5158

    set pages 0 head off feed off lines 9999 trimsp on long 1000000
    col line for a2000
    select /*+ ordered */ chr(10)||rownum||' - '||s.sql_id||') '||sql_fulltext  as line
    from
            v$open_cursor o,
            v$sqlarea s
    where 
        o.sql_id=s.sql_id and 
        sid='&session_id';



----Top Session from Session Metric
------------------------------------
    define SORT=5 -- CPU

    set pages 100 lines 190 feedback off trims on verify off
    col sql_text for a25 trunc
    col sid for 99999
    col log_reads for 9,999,999
    col phys_reads for 9,999,999 head PHY|MB
    col pga_mb for 999 head PGA|MB
    col cpu for 99,999
    col status for a3 head STS trunc
    col sql_id for a13
    col prev_sql_id for a13
    col module for a30 trunc
    col user_name for a11 trunc
    col mins for 9999
    col shadow for a7
    col os_user for a8 trunc
    col log_time for a5 head LOGIN
    set heading on

    select * from 
    (
        SELECT  m.session_id sid,
                s.username user_name,
                round(m.logical_reads/((end_time-begin_time)*24*60*60),2) log_reads,
                round(m.physical_reads/((end_time-begin_time)*24*60*60),2) phys_reads,
                m.cpu cpu,
                m.pga_memory /1024/1024 as pga_mb,
                s.module,
                s.osuser os_user,
                p.spid shadow,
                TO_CHAR (s.logon_time, 'HH24:MI') log_time,
                s.sql_id,
                s.prev_sql_id,
                t.sql_text
        FROM 
            v$sessmetric m, 
            v$session s, 
            v$process p, 
            v$sqlarea t
        WHERE     
            m.logical_reads > 100
            AND m.session_id = s.sid
            AND m.session_serial_num = s.serial#
            AND s.paddr = p.addr(+)
            AND t.sql_id(+) = s.sql_id
        ORDER BY &SORT DESC
    )
    where rownum<30;

--------------------------------  
--------  Session Locks and Waits
------------------------------------
    set pages 200 lines 199 verify off

    col name for a35 head "LOCKED OBJECT"
    col status head STATUS
    col inst_id for 9 head "INS"
    col process for a6 head "OS PROC" trunc
    col session_id for 99999 head SID
    col serial# for 999999
    col os_user_name for a12 head "OS USER"  trunc
    col oracle_username for a18 head "LOCKING USER" trunc
    col username for a15
    col program for a40 trunc
    col load_time for a14 trunc
    col sid for 9999999

    prompt =============================
    prompt ==   Current  Row Locks    ==
    prompt =============================

    select /*+ use_hash(a,b,c,d) */
        a.session_id,b.serial#,b.status,a.oracle_username,a.os_user_name,a.process, start_time, c.name,program
    from
        sys.obj$ c,
        v$session b,
        v$locked_object a,
        v$transaction d
    where
        a.session_id=b.sid and
        c.obj#=a.object_id and
        a.xidusn=d.xidusn and
        a.xidsqn=d.xidsqn and
        a.xidslot=d.xidslot
    order by start_time desc;




------------------------------------
----Session BLocks and Library Locks
----------------------------------------
set linesize    240
    set pages       900
    set feedback    off
    set verify  off

    prompt ========================
    prompt ==  Blocking  Locks   ==
    prompt ========================
        col block_wait  for a4 head "TYPE" trunc
        col running_sec for a8 head "ELAP_SEC"
        col wait_sec    for a8 head "WAIT_SEC"
        col inst_id     for 9 trunc head "I"
        col serial#     for 99999 trunc     head SER#
        col username    for a13 trunc       head "USERNAME"
        col osuser      for a10 trunc       head "OSUSER"
        col status      for a3 trunc        head "STAT"
        col machine     for a10 trunc
        col process     for a7 trunc        head "RPID"
        col spid        for a6 trunc        head "SPID"
        col program     for a15 trunc
        col module      for a13 trunc
        col sql_id      for a13
        col Prev_sql_id      for a13
        col event       for a14 trunc
        col block_sesstat for a9 trunc
        col req_rowid   for a20 trunc
        col ptext       for a30 trunc

    with LOCKS as
    (
        SELECT /*+ materialize */
            DECODE(request,0,'Holder','Waiter') block_wait,sid,inst_id, id1, id2, lmode, request, type
        FROM GV$LOCK
        WHERE (id1, id2, type) IN
        (
            SELECT id1, id2, type FROM GV$LOCK WHERE request>0
        )
        ORDER BY id1, request
    )
    select /*+ use_nl(l,s) */
            l.block_wait,
            l.id1,
            s.inst_id,
            s.sid,
            s.serial#,
            s.username,
            s.osuser,
            s.status,
            process,
            machine,
            program,
            regexp_substr(NUMTODSINTERVAL(nvl((SYSDATE-SQL_EXEC_START)*24*60*60,last_call_et), 'SECOND'),'\d{2}:\d{2}:\d{2}') running_sec,
            regexp_substr(NUMTODSINTERVAL(seconds_in_wait, 'SECOND'),'\d{2}:\d{2}:\d{2}') wait_sec,
            sql_id,prev_sql_id,
            EVENT,
            blocking_session_status AS BLOCK_SESSTAT,
            DECODE (SIGN (NVL (s.ROW_WAIT_OBJ#, -1)),-1, 'NONE',DBMS_ROWID.ROWID_CREATE (1,s.ROW_WAIT_OBJ#, s.ROW_WAIT_FILE#, s.ROW_WAIT_BLOCK#, s.ROW_WAIT_ROW#)) req_rowid
    from
        locks l,
        gv$session s,
        dba_objects o
    where
        s.sid=l.sid and
        s.inst_id=l.inst_id and
        s.p2 = o.object_id (+)
        order by  l.id1, l.request;

    prompt
    prompt ========================
    prompt ==  Libaray locks     ==
    prompt ========================
    set lines 199 trimsp on pages 1000 echo on
    col w_inst_id for 999999
    col h_inst_id for 999999
    col waiting_session for 999999
    col holding_session for 999999
    col lock_or_pin for a15
    col address for a18
    col mode_held for a14
    col mode_requested for a14
    col host_spid for a10
    col db_host for a15

    SELECT /*+ ordered use_nl(w1,h1) */
              w1.inst_id w_inst_id,
              w1.sid waiting_session,
              h1.inst_id h_inst_id,
              h1.sid holding_session,
              hi.host_name db_host,
              p.spid db_host_spid,
              w.kgllktype lock_or_pin,
              w.kgllkhdl address,
              DECODE (h.kgllkmod,     0, 'None',    1, 'Null',    2, 'Share',  3, 'Exclusive',  'Unknown') mode_held,
              DECODE (w.kgllkreq,     0, 'None',    1, 'Null',    2, 'Share',  3, 'Exclusive',  'Unknown') mode_requested
    FROM
              dba_kgllock w,
              dba_kgllock h,
              gv$session w1,
              gv$session h1,
              gv$instance hi,
              gv$process p
    WHERE
              (((h.kgllkmod != 0) AND (h.kgllkmod != 1) AND ((h.kgllkreq = 0) OR (h.kgllkreq = 1)))
              AND (((w.kgllkmod = 0) OR (w.kgllkmod = 1)) AND ((w.kgllkreq != 0) AND (w.kgllkreq != 1))))
              AND w.kgllktype = h.kgllktype
              AND w.kgllkhdl = h.kgllkhdl
              AND w.kgllkuse = w1.saddr
              AND h.kgllkuse = h1.saddr
              AND hi.instance_number=h1.inst_id
              AND p.addr (+) = h1.paddr
              AND p.inst_id (+) = h1.inst_id;
			  
			  
			 
			 
			 
------------------------------------			 
----Monitor SQL progress
------------------------------------
--------get the SQL_ID from V$SESSION and then run below

set pages 2000 lines 2000 verify off trimsp on feed off
col inst_id for 99 head "i|n"
col ses head "start|time"         for a6
col pli head "plan|line"     for 9999
col par head "plan|parent"     for 9999
col plo head "plan|operation"     for a35 trunc
col obj head "plan|object"        for a30 trunc
col typ head "plan object|type"          for a15 trunc
col wam head "work|mem(mb)"  for 99999.9
col wat head "work|temp(mb)" for 99999.9
col mint for a12 head "first|change"
col maxt for a12 head "last|change"
col sid for 999999
col starts for 9,999,999,999 head "start|rows"
col output_rows for 9,999,999,999 head "output|rows"
break on inst_id skip 1
break on sid skip 1

-- by sid

select
        inst_id ,
        sid,
        to_char(sql_exec_start,'hh24:mi') ses,
        plan_line_id pli,
        rpad(' ',plan_depth)||plan_operation||' '||plan_options as plo,
        plan_object_name obj,
        plan_object_type typ,
        starts,
        output_rows,
        workarea_mem/1024/1024 wam,
        workarea_tempseg/1024/1024 wat,
        to_char(first_change_time,'MM/DD hh24:mi') mint ,
        to_char(last_change_time,'MM/DD hh24:mi')  maxt
from
    gv$sql_plan_monitor a
where sid=$SID
order by 1,2,plan_line_id;

-- by sql_id

select
        inst_id ,
        sid,
        to_char(sql_exec_start,'hh24:mi') ses,
        plan_line_id pli,
        rpad(' ',plan_depth)||plan_operation||' '||plan_options as plo,
        plan_object_name obj,
        plan_object_type typ,
        starts,
        output_rows,
        workarea_mem/1024/1024 wam,
        workarea_tempseg/1024/1024 wat,
        to_char(first_change_time,'MM/DD hh24:mi') mint ,
        to_char(last_change_time,'MM/DD hh24:mi')  maxt
from
    gv$sql_plan_monitor a
where SQL_ID = '$sqlid' and sql_exec_start=(select max(sql_exec_start) from gv$sql_plan_monitor where SQL_ID = '$sqlid')
order by 1,2,plan_line_id;


----RMAN Session detail
set linesize 240 pagesize 2000
col Hours format 999.99
col INPUT_TYPE for a25
col STATUS format a10
col RMAN_Bkup_start_time for a25
col RMAN_Bkup_end_time for a25
select * from (select SESSION_KEY, INPUT_TYPE, STATUS,
to_char(START_TIME,'mm-dd-yyyy hh24:mi:ss') as RMAN_Bkup_start_time,
to_char(END_TIME,'mm-dd-yyyy hh24:mi:ss') as RMAN_Bkup_end_time,
elapsed_seconds/3600 Hours from V$RMAN_BACKUP_JOB_DETAILS 
order by session_key desc) where ROWNUM <=2;
