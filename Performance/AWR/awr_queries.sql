--------------------------------
---AWR Snapshots
--------------------------------
    set echo off pages 1000 lines 199 trimsp on feed off verify off
    col snap_id for 999999
    col snap_time for a20
    select 
        snap_id, 
        to_char(begin_interval_time,'YYYY-MM-DD HH24:MI') SNAP_TIME 
    from DBA_HIST_SNAPSHOT 
    where 
        begin_interval_time > sysdate-1 and 
        instance_number=1 
    order by 1;

SNAP_ID SNAP_TIME           
------- --------------------
 124300 2013-10-14 12:17    
 124301 2013-10-14 12:33    
 124302 2013-10-14 12:47    
 124303 2013-10-14 13:02    
 124304 2013-10-14 13:17    
 124305 2013-10-14 13:32    


--------------------------------
---AWR Log sync wait
--------------------------------
SET LINESIZE 200 pages 1000 trimsp on feed off
col inst for 9999
col date_time for a26
col log_file_sync_ms for 9999.99
col log_sync_ms_inst1 for 9999.99
col log_sync_ms_inst2 for 9999.99
with report as
(
    select /*+ materialize */
           instance_number INST,
           event_name,
           date_time,
           round((time_ms_end-time_ms_beg)/nullif(count_end-count_beg,0),1) avg_ms
    from (
    select
           s.dbid,
           e.instance_number,
           event_name,
          to_char(s.BEGIN_INTERVAL_TIME,'YYYY-MM-DD DY HH24:MI')||'-'||to_char(s.END_INTERVAL_TIME,'HH24:MI')  date_time,
           total_waits count_end,
           time_waited_micro/1000 time_ms_end,
           Lag (e.time_waited_micro/1000) OVER( PARTITION BY e.event_name,e.instance_number ORDER BY s.snap_id) time_ms_beg,
           Lag (e.total_waits)            OVER( PARTITION BY e.event_name,e.instance_number ORDER BY s.snap_id) count_beg
    from
           DBA_HIST_SYSTEM_EVENT e,
           DBA_HIST_SNAPSHOT s
    where
           s.snap_id=e.snap_id and s.instance_number=e.instance_number
       and e.event_name in ('log file sync')
       and s.dbid=e.dbid
       and begin_interval_time > sysdate-&DAYS
    )
)
select
    date_time,
    sum(decode(inst,1,avg_ms,0)) log_sync_ms_inst1,
    sum(decode(inst,2,avg_ms,0)) log_sync_ms_inst2
from
    report a
group by date_time
order by 1;


--------------------------------
--AWR Cpu Usage
--------------------------------
    define SNAP_START=124300
    define SNAP_END=124305
    -- issues on non HPUX platform

    set echo off pages 1000 lines 199 trimsp on feed off verify off
    col CPU_USAGE for 999.99
    col snaptime for a20
    col load for 99.99

    SELECT
            TO_CHAR (snaptime, 'YYYY/MM/DD HH24:MI') snap_time,
            ROUND (busydelta / (busydelta + idledelta) * 100, 2) CPU,
            LOAD
    FROM
    (
            SELECT
                    s.begin_interval_time snaptime, os1.VALUE - LAG (os1.VALUE) OVER (ORDER BY s.snap_id) busydelta, os2.VALUE - LAG (os2.VALUE) OVER (ORDER BY s.snap_id) idledelta,
                    round(os3.VALUE ,2) as LOAD
            FROM
                    dba_hist_snapshot s, dba_hist_osstat os1, dba_hist_osstat os2,dba_hist_osstat os3
            WHERE
                    s.snap_id = os1.snap_id
                    AND s.snap_id = os2.snap_id
                    AND s.snap_id = os3.snap_id
                    AND s.instance_number = os1.instance_number
                    AND s.instance_number = os2.instance_number
                    AND s.instance_number = os3.instance_number
                    AND s.dbid = os1.dbid
                    AND s.dbid = os2.dbid
                    AND s.dbid = os3.dbid
                    AND os1.stat_name = 'BUSY_TIME'
                    AND os2.stat_name = 'IDLE_TIME'
                    and os3.stat_id =   15
                    AND s.snap_id BETWEEN &SNAP_START and &SNAP_END
    ) where busydelta is not null;


SNAP_TIME               CPU   LOAD
---------------- ---------- ------
2013/10/14 12:33      66.62    .89
2013/10/14 12:47      31.93    .39
2013/10/14 13:02      29.86    .37
2013/10/14 13:17      29.03    .35
2013/10/14 13:32      32.46    .42

---------------- ---------- ------
---AWR Top Queries
---------------- ---------- ------

    define SNAP_START=124300
    define SNAP_END=124305
    define NUM_ROWS=100
    define SORT=8

    set echo off pages 1000 lines 299 trimsp on feed off verify off
    col num for 999 head 'ID|NUM'
    col sql_id for a14
    col snaps for 9999
    col module for a20 trunc
    col schema for a14 trunc
    col exec for 999,999,999
    col elapsed_per_exec for a12   head 'ELAPSED|EXEC'
    col elapsed_total for a11      head 'ELAPSED|TOTAL'
    col log_read_exec for 999,999  head 'LOGICAL|1000s'
    col phy_per_exec  for 999,999  head 'PHYSICAL|1000s'
    col rows_per_exec for 99,999   head 'ROWS|1000s'
    col cpu_per_exec  for 999       head 'CPU|EXEC'
    col sql_text      for a48 trunc

    select 
        rownum num, 
        sql_id, 
        module, 
        schema, 
        exec,
        regexp_substr(NUMTODSINTERVAL(elapsed_per_exec, 'SECOND'),'\d{2}:\d{2}:\d{2}(.\d{2})') as elapsed_per_exec,
        regexp_substr(NUMTODSINTERVAL(elapsed_total, 'SECOND'),'+\d{2} \d{2}:\d{2}:\d{2}') as elapsed_total,
        LOG_READ_EXEC,
        PHY_PER_EXEC,
        ROWS_PER_EXEC,
        cpu_per_exec,
        sql_text
    from
    (
        select a.* , sql_text
        from
        (
            select
                sql_id,
                count(*) snaps,
                min(MODULE) module,
                min(PARSING_SCHEMA_NAME ) schema,
                sum(executions_delta) as EXEC,
                round((sum(elapsed_time_delta) /1000000 / sum(executions_delta)),3) as elapsed_per_exec,
                sum(elapsed_time_delta) /1000000  as elapsed_total,
                round(sum(buffer_gets_delta)/sum(executions_delta)/1000) LOG_READ_EXEC,
                round(sum(disk_reads_delta)/sum(executions_delta)/1000) PHY_PER_EXEC,
                round((sum(rows_processed_delta)/sum(executions_delta)/1000),1) as ROWS_PER_EXEC,
                round( (sum(cpu_time_delta) /1000000 / sum(executions_delta)),2) as cpu_per_exec,
                dbid
            from
                dba_hist_sqlstat
            where
                snap_id between  &SNAP_START and &SNAP_END and dbid in (select dbid from v$database)
                and executions_delta>0  and module like '%'
                group by sql_id,dbid
        ) a ,
        dba_hist_sqltext s
        where a.sql_id=s.sql_id (+) and a.dbid=s.dbid (+)
        order by &SORT desc
    ) b where rownum<=&NUM_ROWS ;
