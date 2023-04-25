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
