# Oracle Database Query Performance Troubleshooting Guide

## 100+ Questions & Solutions for DBAs

### **Section 1: Basic Query Performance Issues (1-25)**

**1. Query is running slower than usual - where do I start?**

- Check AWR/ADDM reports for the time period
- Use SQL*Plus: `@?/rdbms/admin/awrrpt.sql`
- Look for top SQL statements by elapsed time, CPU, and I/O

**2. How do I identify the slowest queries currently running?**

```sql
SELECT sql_id, elapsed_time/1000000 elapsed_sec, cpu_time/1000000 cpu_sec, 
       executions, sql_text
FROM v$sql 
WHERE elapsed_time > 10000000 
ORDER BY elapsed_time DESC;
```

**3. A specific SQL_ID is performing poorly - how do I analyze it?**

```sql
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', NULL, 'ADVANCED'));
```

**4. How do I check if statistics are stale for a table?**

```sql
SELECT table_name, num_rows, last_analyzed, stale_stats
FROM user_tab_statistics
WHERE table_name = 'YOUR_TABLE';
```

**Solution**: Gather fresh statistics using `DBMS_STATS.GATHER_TABLE_STATS`

**5. Query plan changed suddenly - how do I find the previous good plan?**

```sql
SELECT plan_hash_value, timestamp, elapsed_time_avg
FROM dba_hist_sqlstat
WHERE sql_id = '&sql_id'
ORDER BY timestamp;
```

**Solution**: Use SQL Plan Baselines or create a stored outline

**6. How do I force Oracle to use a specific index?**

```sql
SELECT /*+ INDEX(table_alias index_name) */ columns
FROM table_name table_alias
WHERE conditions;
```

**7. Full table scan instead of index - why?**

- Check if index exists: `SELECT * FROM user_indexes WHERE table_name = 'TABLE_NAME'`
- Verify index statistics are current
- Check if query is using functions on indexed columns
  **Solution**: Rebuild index stats or create function-based index

**8. How do I check buffer cache hit ratio?**

```sql
SELECT name, value FROM v$sysstat 
WHERE name IN ('db block gets', 'consistent gets', 'physical reads');
```

**Solution**: Hit ratio should be >95%. If low, increase db_cache_size

**9. Query waiting on disk I/O - how to optimize?**

```sql
SELECT event, total_waits, average_wait
FROM v$system_event
WHERE event LIKE '%read%'
ORDER BY total_waits DESC;
```

**Solution**: Add indexes, partition tables, or move to faster storage

**10. How do I identify missing indexes?**

```sql
SELECT * FROM user_tables t
WHERE NOT EXISTS (
    SELECT 1 FROM user_indexes i 
    WHERE i.table_name = t.table_name
);
```

**Solution**: Analyze execution plans and create appropriate indexes

**11. Parallel query not using all CPUs - why?**

```sql
SELECT name, value FROM v$parameter 
WHERE name LIKE 'parallel%';
```

**Solution**: Adjust parallel_max_servers, parallel_degree_policy

**12. How do I check for blocking sessions?**

```sql
SELECT blocking_session, sid, serial#, username, status, machine
FROM v$session
WHERE blocking_session IS NOT NULL;
```

**13. Undo segments causing slowness - how to check?**

```sql
SELECT tablespace_name, status, sum(bytes)/1024/1024 MB
FROM dba_undo_extents
GROUP BY tablespace_name, status;
```

**14. How do I monitor real-time SQL execution?**

```sql
SELECT sql_id, status, last_call_et, machine, program
FROM v$session
WHERE status = 'ACTIVE' AND type = 'USER';
```

**15. Sort operations spilling to temp - how to fix?**

```sql
SELECT name, value FROM v$sysstat 
WHERE name LIKE '%sort%';
```

**Solution**: Increase pga_aggregate_target or sort_area_size

**16. How do I check table fragmentation?**

```sql
SELECT table_name, num_rows, blocks, avg_row_len,
       (blocks * 8192) / (num_rows * avg_row_len) fragmentation_ratio
FROM user_tables
WHERE num_rows > 0;
```

**17. Bind variable peeking causing issues - how to disable?**

```sql
ALTER SYSTEM SET "_optim_peek_user_binds" = FALSE;
```

**18. How do I check for cursor sharing issues?**

```sql
SELECT sql_text, version_count, executions
FROM v$sqlarea
WHERE version_count > 5
ORDER BY version_count DESC;
```

**19. Library cache contention - how to identify?**

```sql
SELECT event, total_waits, average_wait
FROM v$system_event
WHERE event LIKE '%library cache%';
```

**20. How do I check automatic workload repository (AWR) retention?**

```sql
SELECT retention, topnsql FROM dba_hist_wr_control;
```

**21. Query using wrong join method - how to force nested loop?**

```sql
SELECT /*+ USE_NL(a,b) */ columns
FROM table1 a, table2 b
WHERE a.id = b.id;
```

**22. How do I check current wait events for a session?**

```sql
SELECT sid, event, wait_time, seconds_in_wait
FROM v$session_wait
WHERE sid = &session_id;
```

**23. Large result set causing memory issues - how to optimize?**

```sql
SELECT /*+ FIRST_ROWS(100) */ columns
FROM large_table
WHERE conditions
ORDER BY indexed_column;
```

**24. How do I check segment advisor recommendations?**

```sql
SELECT tablespace_name, segment_name, recommendations
FROM dba_advisor_recommendations
WHERE task_name LIKE '%SEGMENT%';
```

**25. Optimizer choosing wrong cardinality estimates - how to fix?**

```sql
SELECT /*+ CARDINALITY(table_alias 1000) */ columns
FROM table_name table_alias;
```

### **Section 2: Advanced Performance Tuning (26-50)**

**26. How do I create a SQL Plan Baseline?**

```sql
DECLARE
  l_plans_loaded PLS_INTEGER;
BEGIN
  l_plans_loaded := DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE(
    sql_id => '&sql_id'
  );
END;
/
```

**27. Adaptive cursor sharing causing plan instability - how to manage?**

```sql
SELECT sql_id, child_number, is_bind_sensitive, is_bind_aware
FROM v$sql
WHERE sql_id = '&sql_id';
```

**28. How do I check for recursive SQL overhead?**

```sql
SELECT sql_text, executions, elapsed_time
FROM v$sql
WHERE command_type IN (47, 7)  -- PL/SQL and others
ORDER BY elapsed_time DESC;
```

**29. Result cache not being used - how to enable?**

```sql
SELECT /*+ RESULT_CACHE */ columns
FROM table_name
WHERE conditions;
```

**30. How do I analyze partition pruning effectiveness?**

```sql
SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id', NULL, 'ADVANCED'))
WHERE plan_table_output LIKE '%partition%';
```

**31. Star transformation not working - how to enable?**

```sql
ALTER SESSION SET star_transformation_enabled = TRUE;
SELECT /*+ STAR_TRANSFORMATION */ columns FROM fact_table f, dim1 d1, dim2 d2;
```

**32. How do I check for column statistics histograms?**

```sql
SELECT column_name, num_distinct, histogram, num_buckets
FROM user_tab_col_statistics
WHERE table_name = 'YOUR_TABLE';
```

**33. Materialized view not being used by query rewrite - why?**

```sql
SELECT * FROM user_mv_capabilities_table
WHERE statement_id = (SELECT statement_id FROM user_mv_capabilities_table WHERE rownum = 1);
```

**34. How do I enable SQL trace for a specific session?**

```sql
ALTER SESSION SET sql_trace = TRUE;
-- Or for another session:
EXEC DBMS_SESSION.SET_SQL_TRACE(session_id => 123, serial_num => 456, sql_trace => TRUE);
```

**35. 10053 trace shows wrong selectivity - how to fix?**

```sql
ALTER SESSION SET EVENTS '10053 trace name context forever, level 1';
-- Then run your query and check the trace file
```

**36. How do I check for invisible columns affecting performance?**

```sql
SELECT column_name, hidden_column FROM user_tab_cols
WHERE table_name = 'YOUR_TABLE' AND hidden_column = 'YES';
```

**37. Virtual columns not being used in queries - how to optimize?**

```sql
CREATE INDEX idx_virtual ON table_name (virtual_column_expression);
```

**38. How do I check automatic SQL tuning advisor results?**

```sql
SELECT task_name, status, recommendation_count
FROM dba_advisor_tasks
WHERE advisor_name = 'SQL Tuning Advisor';
```

**39. SQL Profile recommended but not implemented - how to apply?**

```sql
EXEC DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name => 'task_name', task_owner => 'SYS');
```

**40. How do I check for extended statistics?**

```sql
SELECT extension_name, extension FROM user_stat_extensions
WHERE table_name = 'YOUR_TABLE';
```

**41. Bloom filter not being used in joins - how to enable?**

```sql
ALTER SESSION SET "_bloom_filter_enabled" = TRUE;
```

**42. How do I check for SQL plan directives?**

```sql
SELECT directive_id, type, state, reason FROM dba_sql_plan_directives
WHERE state != 'PERMANENT';
```

**43. Adaptive plans causing performance regression - how to disable?**

```sql
ALTER SESSION SET optimizer_adaptive_plans = FALSE;
```

**44. How do I check for cardinality feedback?**

```sql
SELECT sql_id, child_number, cardinality_feedback FROM v$sql
WHERE sql_id = '&sql_id';
```

**45. In-memory column store not being used - why?**

```sql
SELECT segment_name, inmemory, inmemory_priority
FROM v$im_segments
WHERE segment_name = 'YOUR_TABLE';
```

**46. How do I check for automatic indexing recommendations?**

```sql
SELECT * FROM dba_auto_index_recommendations
WHERE status = 'CANDIDATE';
```

**47. Query rewrite with materialized views failing - how to debug?**

```sql
ALTER SESSION SET query_rewrite_enabled = TRUE;
ALTER SESSION SET query_rewrite_integrity = TRUSTED;
```

**48. How do I check for SQL plan management baselines?**

```sql
SELECT sql_handle, plan_name, enabled, accepted
FROM dba_sql_plan_baselines
WHERE sql_text LIKE '%your_query_text%';
```

**49. Parallel DML not working - how to enable?**

```sql
ALTER SESSION ENABLE PARALLEL DML;
INSERT /*+ PARALLEL(target_table, 4) */ INTO target_table SELECT * FROM source_table;
```

**50. How do I check for automatic memory management conflicts?**

```sql
SELECT component, current_size, min_size, max_size
FROM v$sga_dynamic_components;
```

### **Section 3: Wait Events and Locking Issues (51-75)**

**51. High ‘db file sequential read’ waits - how to resolve?**

```sql
SELECT event, total_waits, average_wait, wait_class
FROM v$system_event
WHERE event = 'db file sequential read';
```

**Solution**: Check for missing indexes, optimize single-block reads

**52. ‘enq: TX - row lock contention’ - how to identify blocking session?**

```sql
SELECT s1.username || '@' || s1.machine blocking_user,
       s2.username || '@' || s2.machine blocked_user
FROM v$lock l1, v$session s1, v$lock l2, v$session s2
WHERE s1.sid = l1.sid AND s2.sid = l2.sid
AND l1.id1 = l2.id1 AND l1.id2 = l2.id2
AND l1.request = 0 AND l2.lmode = 0;
```

**53. High ‘log file sync’ waits - how to optimize?**

```sql
SELECT name, value FROM v$sysstat 
WHERE name IN ('redo size', 'user commits', 'user rollbacks');
```

**Solution**: Faster storage for redo logs, optimize commit frequency

**54. ‘buffer busy waits’ events - how to resolve?**

```sql
SELECT class, count FROM v$waitstat
WHERE class IN ('data block', 'segment header', 'free list');
```

**Solution**: Increase freelists, use ASSM, partition hot tables

**55. How do I check for library cache latch contention?**

```sql
SELECT name, gets, misses, sleeps, immediate_gets, immediate_misses
FROM v$latch
WHERE name LIKE '%library cache%';
```

**56. ‘gc buffer busy acquire’ in RAC - how to resolve?**

```sql
SELECT inst_id, event, total_waits, average_wait
FROM gv$system_event
WHERE event LIKE '%gc buffer busy%';
```

**Solution**: Review application partitioning, consider table/index partitioning

**57. How do I identify hot blocks in buffer cache?**

```sql
SELECT obj object_name, count(*) buffer_count
FROM v$bh b, obj$ o
WHERE b.obj = o.obj#
GROUP BY obj
ORDER BY count(*) DESC;
```

**58. Deadlock detected - how to analyze?**

```sql
SELECT * FROM v$lock
WHERE type = 'TM' AND lmode = 0;
-- Check alert log for deadlock graph
```

**59. ‘latch: cache buffers chains’ - how to resolve?**

```sql
SELECT addr, latch#, level#, name, gets, misses, sleeps
FROM v$latch_children
WHERE name = 'cache buffers chains'
ORDER BY sleeps DESC;
```

**60. How do I check for checkpoint performance issues?**

```sql
SELECT name, value FROM v$sysstat
WHERE name IN ('DBWR checkpoints', 'background checkpoints completed');
```

**61. ‘log buffer space’ waits - how to fix?**

```sql
SELECT name, value FROM v$sysstat
WHERE name = 'redo buffer allocation retries';
```

**Solution**: Increase log_buffer parameter

**62. How do I identify sessions waiting for locks?**

```sql
SELECT s.sid, s.serial#, s.username, s.machine, w.event, w.seconds_in_wait
FROM v$session s, v$session_wait w
WHERE s.sid = w.sid AND w.event LIKE '%enq:%';
```

**63. ‘gc current block 2-way’ high in RAC - how to optimize?**

```sql
SELECT inst_id, sql_id, count(*) 
FROM gv$active_session_history
WHERE event = 'gc current block 2-way'
GROUP BY inst_id, sql_id;
```

**64. How do I check for undo contention?**

```sql
SELECT name, value FROM v$sysstat
WHERE name IN ('undo change vector size', 'redo entries');
```

**65. ‘direct path read’ waits high - normal or issue?**

```sql
SELECT sql_id, count(*) FROM v$active_session_history
WHERE event = 'direct path read'
GROUP BY sql_id
ORDER BY count(*) DESC;
```

**Solution**: Usually normal for large table scans, consider parallel query

**66. How do I check for sequence cache contention?**

```sql
SELECT sequence_name, cache_size, order_flag, cycle_flag
FROM user_sequences
WHERE last_number - cache_size < 100;
```

**67. ‘cursor: pin S wait on X’ - how to resolve?**

```sql
SELECT sql_text, version_count, loads, invalidations
FROM v$sqlarea
WHERE version_count > 10;
```

**Solution**: Use bind variables, increase shared_pool_size

**68. How do I identify sessions causing high physical reads?**

```sql
SELECT s.sid, s.username, st.value physical_reads
FROM v$session s, v$sesstat st, v$statname sn
WHERE s.sid = st.sid AND st.statistic# = sn.statistic#
AND sn.name = 'physical reads'
ORDER BY st.value DESC;
```

**69. ‘rdbms ipc reply’ waits in RAC - how to investigate?**

```sql
SELECT inst_id, event, p1, p2, p3, count(*)
FROM gv$active_session_history
WHERE event = 'rdbms ipc reply'
GROUP BY inst_id, event, p1, p2, p3;
```

**70. How do I check for temp tablespace contention?**

```sql
SELECT tablespace_name, total_blocks, used_blocks, free_blocks
FROM v$sort_segment;
```

**71. ‘SQL*Net break/reset to client’ - how to resolve?**

```sql
SELECT machine, program, count(*) FROM v$session
WHERE last_call_et > 3600
GROUP BY machine, program;
```

**Solution**: Check network connectivity, kill idle sessions

**72. How do I identify expensive recursive SQL?**

```sql
SELECT sql_text, executions, elapsed_time, cpu_time
FROM v$sql
WHERE sql_text LIKE 'DECLARE%' OR sql_text LIKE 'BEGIN%'
ORDER BY elapsed_time DESC;
```

**73. ‘free buffer waits’ - how to resolve?**

```sql
SELECT name, value FROM v$sysstat
WHERE name IN ('free buffer requested', 'free buffer inspected');
```

**Solution**: Increase buffer cache, check for inefficient queries

**74. How do I check for segment space management issues?**

```sql
SELECT tablespace_name, segment_space_management, extent_management
FROM dba_tablespaces;
```

**75. ‘gc current grant 2-way’ in RAC - how to minimize?**

```sql
SELECT object_name, count(*) FROM gv$active_session_history ash, dba_objects obj
WHERE ash.current_obj# = obj.object_id
AND event = 'gc current grant 2-way'
GROUP BY object_name;
```

### **Section 4: RAC-Specific Performance Issues (76-100)**

**76. How do I check cluster interconnect performance?**

```sql
SELECT name, value FROM gv$sysstat
WHERE name LIKE '%gc%' AND inst_id = 1
UNION ALL
SELECT name, value FROM gv$sysstat
WHERE name LIKE '%gc%' AND inst_id = 2;
```

**77. Cluster wait time high - how to identify cause?**

```sql
SELECT inst_id, event, total_waits, time_waited
FROM gv$system_event
WHERE event LIKE 'gc%'
ORDER BY time_waited DESC;
```

**78. How do I check for services balancing issues?**

```sql
SELECT service_name, inst_id, stat_name, value
FROM gv$service_stats
WHERE service_name = 'YOUR_SERVICE';
```

**79. Global cache efficiency low - how to improve?**

```sql
SELECT 
  (SELECT value FROM gv$sysstat WHERE name = 'gc current blocks received' AND inst_id = 1) /
  (SELECT value FROM gv$sysstat WHERE name = 'gc current blocks served' AND inst_id = 1) efficiency_node1
FROM dual;
```

**80. How do I identify cross-instance calls?**

```sql
SELECT sql_id, count(*) cross_instance_calls
FROM gv$active_session_history
WHERE event LIKE 'gc%'
GROUP BY sql_id
ORDER BY count(*) DESC;
```

**81. Node affinity not working - how to check?**

```sql
SELECT machine, inst_id, count(*) 
FROM gv$session
WHERE username IS NOT NULL
GROUP BY machine, inst_id;
```

**82. How do I check cluster database performance?**

```sql
SELECT inst_id, metric_name, value
FROM gv$sysmetric
WHERE metric_name LIKE '%Cluster%';
```

**83. Parallel query slaves unevenly distributed - how to fix?**

```sql
SELECT inst_id, count(*) slaves
FROM gv$px_session
GROUP BY inst_id;
```

**Solution**: Set parallel_force_local=FALSE, check services configuration

**84. How do I check for split-brain or network partitioning?**

```sql
SELECT inst_id, database_status, instance_status, active_state
FROM gv$instance;
```

**85. Cache fusion performance poor - how to analyze?**

```sql
SELECT class, gc_buffer_busy, gc_buffer_busy_acquire, gc_buffer_busy_release
FROM gv$waitstat
WHERE inst_id IN (1,2);
```

**86. How do I check cluster resource usage?**

```sql
SELECT inst_id, resource_name, current_utilization, max_utilization
FROM gv$resource_limit
WHERE resource_name IN ('processes', 'sessions');
```

**87. Load balancing not working properly - how to verify?**

```sql
SELECT service_name, inst_id, value
FROM gv$service_stats
WHERE stat_name = 'DB CPU';
```

**88. How do I check for voting disk issues?**

```sql
-- Check from OS level
SELECT name, voting_file FROM v$asm_disk WHERE voting_file = 'Y';
```

**89. Sequence ordering causing performance issues in RAC?**

```sql
SELECT sequence_name, cache_size, order_flag
FROM dba_sequences
WHERE order_flag = 'Y';
```

**Solution**: Remove ORDER clause or increase cache size

**90. How do I check cluster verification utility results?**

```bash
# Run from command line
cluvfy comp nodereach -n node1,node2 -verbose
```

**91. Application failover taking too long - how to optimize?**

```sql
SELECT service_name, failover_method, failover_type, failover_retries
FROM dba_services;
```

**92. How do I check for clock synchronization issues?**

```sql
SELECT inst_id, to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS') current_time
FROM gv$instance;
```

**93. Cluster database links performing poorly - how to optimize?**

```sql
SELECT db_link, owner, username, host, created
FROM dba_db_links;
```

**94. How do I check SCAN listener performance?**

```sql
-- Check SCAN configuration
SELECT name, value FROM v$parameter WHERE name = 'remote_listener';
```

**95. TAF (Transparent Application Failover) not working - how to debug?**

```sql
SELECT username, machine, failover_type, failover_method, failed_over
FROM v$session
WHERE username = 'YOUR_USER';
```

**96. How do I check cluster-wide AWR reports?**

```sql
@?/rdbms/admin/awrgrpt.sql  -- Global AWR report
```

**97. Cluster file system performance issues - how to identify?**

```sql
SELECT name, value FROM gv$sysstat
WHERE name LIKE '%file%' AND name LIKE '%time%';
```

**98. How do I check for memory pressure across nodes?**

```sql
SELECT inst_id, component, current_size/1024/1024 size_mb
FROM gv$sga_dynamic_components
WHERE component IN ('shared pool', 'buffer cache');
```

**99. Cluster nodes running different patch levels - how to verify?**

```sql
SELECT inst_id, version, banner FROM gv$version
WHERE banner LIKE '%Database%';
```

**100. How do I check for cluster database triggers causing delays?**

```sql
SELECT owner, trigger_name, triggering_event, status
FROM dba_triggers
WHERE base_object_type = 'DATABASE';
```

### **Bonus Section: Emergency Performance Diagnostics (101-110)**

**101. Database completely hung - emergency diagnosis?**

```sql
-- Check for blocking locks
SELECT * FROM v$session WHERE blocking_session IS NOT NULL;
-- Check wait events
SELECT event, count(*) FROM v$session_wait GROUP BY event;
```

**102. All queries suddenly slow - what to check first?**

```sql
-- Check system stats
SELECT * FROM v$sysstat WHERE name IN ('CPU used by this session', 'physical reads');
-- Check parameters
SELECT name, value FROM v$parameter WHERE ismodified = 'TRUE';
```

**103. How to kill a runaway query immediately?**

```sql
SELECT sid, serial# FROM v$session WHERE sql_id = '&problematic_sql_id';
ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;
```

**104. Memory errors occurring - how to diagnose?**

```sql
SELECT component, current_size, min_size, max_size, granule_size
FROM v$sga_dynamic_components;
```

**105. How to enable emergency monitoring?**

```sql
ALTER SYSTEM SET timed_statistics = TRUE;
ALTER SYSTEM SET max_dump_file_size = UNLIMITED;
```

**106. Database running out of temp space - immediate action?**

```sql
SELECT tablespace_name, sum(bytes)/1024/1024 MB_USED
FROM v$temp_extent_pool
GROUP BY tablespace_name;
-- Add temp file immediately
ALTER TABLESPACE temp ADD TEMPFILE '/path/tempfile.dbf' SIZE 1G;
```

**107. How to trace all sessions for performance analysis?**

```sql
ALTER SYSTEM SET sql_trace = TRUE;
-- Or use ORADEBUG for system-wide tracing
```

**108. Undo tablespace full - emergency resolution?**

```sql
SELECT tablespace_name, sum(bytes)/1024/1024 MB_USED
FROM dba_undo_extents
WHERE status = 'ACTIVE'
GROUP BY tablespace_name;
-- Add undo datafile
ALTER TABLESPACE undotbs1 ADD DATAFILE '/path/undo02.dbf' SIZE 1G;
```

**109. How to check if database is in emergency mode?**

```sql
SELECT database_status, instance_status FROM v$instance;
SELECT * FROM v$recovery_file_dest;
```

**110. Complete system performance snapshot for analysis?**

```sql
-- Generate comprehensive report
@?/rdbms/admin/awrrpt.sql
-- Export system state
ALTER SYSTEM DUMP SYSTEMSTATE LEVEL 266;
-- Capture session information
CREATE TABLE perf_snapshot AS 
SELECT sysdate snapshot_time, s.*, sw.event, sw.wait_time
FROM v$session s, v$session_wait sw
WHERE s.sid = sw.sid;
```

## **Key Performance Monitoring Queries**

### **Daily Health Check Script**

```sql
-- Buffer Cache Hit Ratio
SELECT ROUND((1 - (phyrds.value / (dbget.value + conget.value))) * 100, 2) "Buffer Cache Hit Ratio"
FROM v$sysstat phyrds, v$sysstat dbget, v$sysstat conget
WHERE phyrds.name = 'physical reads'
AND dbget.name = 'db block gets'
AND conget.name = 'consistent gets';

-- Library Cache Hit Ratio
SELECT ROUND((1 - (reloads/pins)) * 100, 2) "Library Cache Hit Ratio"
FROM v$librarycache
WHERE namespace = 'SQL AREA';

-- Top 10 Wait Events
SELECT event, time_waited, average_wait
FROM v$system_event
WHERE event NOT LIKE '%idle%'
ORDER BY time_waited DESC
FETCH FIRST 10 ROWS ONLY;
```

## **Best Practices Summary**

1. **Always gather statistics** before performance analysis
1. **Use AWR/ADDM reports** for historical analysis
1. **Monitor wait events** to identify bottlenecks
1. **Check execution plans** before and after changes
1. **Use SQL Plan Baselines** for plan stability
1. **Monitor RAC-specific metrics** for cluster databases
1. **Keep emergency scripts ready** for critical situations
1. **Document all changes** and their impact
1. **Use proper indexing strategies** based on query patterns
1. **Regular maintenance** of statistics and space management

-----

*This guide covers the most common performance issues DBAs face daily. Each solution should be tested in a development environment before applying to production systems.*