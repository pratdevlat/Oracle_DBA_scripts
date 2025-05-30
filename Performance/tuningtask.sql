---------- Create tuning Task from time limit
set linesize 200
set pagesize 2000
set serveroutput on
declare
  l_sql_tune_task_id varchar2(100);
begin
  l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
                          sql_id => 'SQL_ID',
                          scope => dbms_sqltune.scope_comprehensive,
                         time_limit => 240,
                          task_name => 'SQL_ID_AWR_tuning_task',
                          description => 'tuning task for statement SQL_ID');
  dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
end;
/ 

------------  Create tuning Task from snap id
DECLARE
  l_sql_tune_task_id VARCHAR2(100);
BEGIN
  l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          begin_snap =>&begin_snap,
                          end_snap => &end_snap,
                          sql_id => 'SQL_ID',
                          scope => DBMS_SQLTUNE.scope_comprehensive,
                          time_limit => 260, --- use according to query executed
                          task_name => 'SQL_ID_AWR_tuning_task',
                          description => 'Tuning task for statement SQL_ID in AWR.');
  DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/

------ execute tuning task
EXEC DBMS_SQLTUNE.execute_tuning_task(task_name => 'SQL_ID_AWR_tuning_task');

----- get recommendataion report

 SET LONG 90000;
SET PAGESIZE 1000
SET LINESIZE 20000
SELECT DBMS_SQLTUNE.report_tuning_task('SQL_ID_AWR_tuning_task') AS recommendations FROM dual;

/
