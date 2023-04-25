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
