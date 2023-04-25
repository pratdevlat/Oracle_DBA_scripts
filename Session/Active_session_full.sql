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
