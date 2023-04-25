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
