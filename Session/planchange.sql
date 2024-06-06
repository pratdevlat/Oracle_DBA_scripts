set lines 1000 pages 9999
COL instance_number FOR 9999 HEA 'Inst';
COL end_time HEA 'End Time';
COL plan_hash_value HEA 'Plan|Hash Value';
COL executions_total FOR 999,999 HEA 'Execs|Total';
COL rows_per_exec HEA 'Rows Per Exec';
COL et_secs_per_exec HEA 'Elap Secs|Per Exec';
COL cpu_secs_per_exec HEA 'CPU Secs|Per Exec';
COL io_secs_per_exec HEA 'IO Secs|Per Exec';
COL cl_secs_per_exec HEA 'Clus Secs|Per Exec';
COL ap_secs_per_exec HEA 'App Secs|Per Exec';
COL cc_secs_per_exec HEA 'Conc Secs|Per Exec';
COL pl_secs_per_exec HEA 'PLSQL Secs|Per Exec';
COL ja_secs_per_exec HEA 'Java Secs|Per Exec';
SELECT 'gv$dba_hist_sqlstat' source,h.instance_number,
       TO_CHAR(CAST(s.begin_interval_time AS DATE), 'DD-MM-YYYY HH24:MI') snap_time,
       TO_CHAR(CAST(s.end_interval_time AS DATE), 'DD-MM-YYYY HH24:MI') end_time,
       h.sql_id,
       h.plan_hash_value, 
       h.executions_total,
       TO_CHAR(ROUND(h.rows_processed_total / h.executions_total), '999,999,999,999') rows_per_exec,
       TO_CHAR(ROUND(h.elapsed_time_total / h.executions_total / 1e6, 3), '999,990.000') et_secs_per_exec,
       TO_CHAR(ROUND(h.cpu_time_total / h.executions_total / 1e6, 3), '999,990.000') cpu_secs_per_exec,
       TO_CHAR(ROUND(h.iowait_total / h.executions_total / 1e6, 3), '999,990.000') io_secs_per_exec,
       TO_CHAR(ROUND(h.clwait_total / h.executions_total / 1e6, 3), '999,990.000') cl_secs_per_exec,
       TO_CHAR(ROUND(h.apwait_total / h.executions_total / 1e6, 3), '999,990.000') ap_secs_per_exec,
       TO_CHAR(ROUND(h.ccwait_total / h.executions_total / 1e6, 3), '999,990.000') cc_secs_per_exec,
       TO_CHAR(ROUND(h.plsexec_time_total / h.executions_total / 1e6, 3), '999,990.000') pl_secs_per_exec,
       TO_CHAR(ROUND(h.javexec_time_total / h.executions_total / 1e6, 3), '999,990.000') ja_secs_per_exec
  FROM dba_hist_sqlstat h, 
       dba_hist_snapshot s
 WHERE h.sql_id = '&sql_id'
   AND h.executions_total > 0 
   AND s.snap_id = h.snap_id
   AND s.dbid = h.dbid
   AND s.instance_number = h.instance_number
UNION ALL  
SELECT 'gv$sqlarea_plan_hash' source,h.inst_id, 
       TO_CHAR(sysdate, 'DD-MM-YYYY HH24:MI') snap_time,
       TO_CHAR(sysdate, 'DD-MM-YYYY HH24:MI') end_time,
       h.sql_id,
       h.plan_hash_value, 
       h.executions,
       TO_CHAR(ROUND(h.rows_processed / h.executions), '999,999,999,999') rows_per_exec,
       TO_CHAR(ROUND(h.elapsed_time / h.executions / 1e6, 3), '999,990.000') et_secs_per_exec,
       TO_CHAR(ROUND(h.cpu_time / h.executions / 1e6, 3), '999,990.000') cpu_secs_per_exec,
       TO_CHAR(ROUND(h.USER_IO_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') io_secs_per_exec,
       TO_CHAR(ROUND(h.CLUSTER_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') cl_secs_per_exec,
       TO_CHAR(ROUND(h.APPLICATION_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') ap_secs_per_exec,
       TO_CHAR(ROUND(h.CLUSTER_WAIT_TIME / h.executions / 1e6, 3), '999,990.000') cc_secs_per_exec,
       TO_CHAR(ROUND(h.PLSQL_EXEC_TIME / h.executions / 1e6, 3), '999,990.000') pl_secs_per_exec,
       TO_CHAR(ROUND(h.JAVA_EXEC_TIME / h.executions / 1e6, 3), '999,990.000') ja_secs_per_exec
  FROM gv$sqlarea_plan_hash h 
 WHERE h.sql_id = '&sql_id'
   AND h.executions > 0 
order by source ;
