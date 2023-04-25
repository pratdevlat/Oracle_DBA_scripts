set pages 90 verify off line 180 feed off
alter session set nls_date_format='DD-MON-YYYY HH24:MI';
column host_name                 for a10
column force_logging             for a9 head FORCE_LOG
column flashback_on              for a9 head FLASH trunc
column database_role             for a15
column instance_name             for a10 head INSTANCE
column version                   for a10
column SUPPLEMENTAL_LOG_DATA_MIN for a6 head SUPMIN trunc
column SUPPLEMENTAL_LOG_DATA_PK for a6 head SUP_PK
column SUPPLEMENTAL_LOG_DATA_UI for a6 head SUP_UI
column ARCHIVELOG_COMPRESSION   for a7 head ARC_ZIP trunc
column sessions_current         for 999,999 head SESS_CUR
column sessions_highwater       for 999,999 head SESS_MAX
column MB                       for 999,999.9 head DB_GB
column global_name              for a40
column sga                      for 999,999 head SGA_MB

select 
---    dbid, 
    host_name,
    name, 
    instance_name, 
    version, 
    log_mode, 
    archiver,
    flashback_on,
---- force_logging,
---- SUPPLEMENTAL_LOG_DATA_MIN,
---- SUPPLEMENTAL_LOG_DATA_PK,
---- SUPPLEMENTAL_LOG_DATA_UI,
---- ARCHIVELOG_COMPRESSION,
    created, 
    STARTUP_TIME,
    database_role 
from 
    v$instance, 
    v$database;

SELECT 
    sessions_current, 
    sessions_highwater, 
    sga,  
    global_name
FROM  v$process, v$license,  v$version, v$database, v$instance,
      (select sum(value)/1024/1024 sga from v$sga),
      (select global_name from global_name)
WHERE rownum = 1;
