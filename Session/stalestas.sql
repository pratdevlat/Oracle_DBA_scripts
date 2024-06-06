##########################Longrunning stale stats

select OWNER,TABLE_NAME,LAST_ANALYZED,STALE_STATS from DBA_TAB_STATISTICS where STALE_STATS='YES' and OWNER='&owner';

########################################statistics of objects of a specific sql id 

set lines 300 set pages 300
col table_name for a40
col owner for a30 
select distinct owner, table_name, STALE_STATS, last_analyzed, stattype_locked
  from dba_tab_statistics
  where (owner, table_name) in
  (select distinct owner, table_name
          from dba_tables
          where ( table_name)
          in ( select object_name
                  from gv$sql_plan
                  where upper(sql_id) = upper('&sql_id') and object_name is not null))
  --and STALE_STATS='YES'
/
