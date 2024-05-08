
prompt "DR details"

column dbTime format a30
column behind format a60
set linesize 120
select to_char(controlfile_time, 'mm/dd/yyyy hh24:mi') "dbTime", floor((sysdate-controlfile_time)*24)||' hours ' || floor(mod((sysdate-controlfile_time)*(1440),60))||' minutes behind' behind from v$database;


prompt "Check Last Archive Log Received and Applied"


set linesize 2000 colsep | pagesize 2000
 SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
   FROM
   (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
   (SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
   WHERE
ARCH.THREAD# = APPL.THREAD#;


prompt "Monitor Managed Standby process"


column Process   format a7
column Status    format a12
column Group#    format 999
column Thread#   format 999
column Sequence# format 999999

Select
   Process,
   Status,
   Group#,
   Thread#,
   Sequence#
From
   gv$managed_standby;
