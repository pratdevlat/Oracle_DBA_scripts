    define sql_id='<SQL_ID_HERE>'
    
    set feed off pages 300 lines 199 recsep off trimsp on verify off
    alter session set nls_date_format='MM/DD/YY HH24:MI:SS';

    set pages 0 head off feed off lines 4000 trimsp on
    select distinct
      dbms_lob.substr(sql_text,4000,     1),
      dbms_lob.substr(sql_text,4000,  4001),
      dbms_lob.substr(sql_text,4000,  8001),
      dbms_lob.substr(sql_text,4000, 12001),
      dbms_lob.substr(sql_text,4000, 16001),
      dbms_lob.substr(sql_text,4000, 20001),
      dbms_lob.substr(sql_text,4000, 24001),
      dbms_lob.substr(sql_text,4000, 28001),
      dbms_lob.substr(sql_text,4000, 32001),
      dbms_lob.substr(sql_text,4000, 36001),
      dbms_lob.substr(sql_text,4000, 40001),
      dbms_lob.substr(sql_text,4000, 44001),
      dbms_lob.substr(sql_text,4000, 48001),
      dbms_lob.substr(sql_text,4000, 52001),
      dbms_lob.substr(sql_text,4000, 56001,
      dbms_lob.substr(sql_text,4000, 60001)
    from v$sql
    where sql_id = '&sql_id';

    prompt =========================================================================================================================
    set pages 0 feed off lines 300 trimsp on
    prompt
    SELECT * FROM
    (
             select * from TABLE(dbms_xplan.display_cursor('&sql_id',(select max(child_number) from gv$sql where sql_id='&sql_id'),'-NOTE')) a 
    )
    where
        plan_table_output not like '%cpu costing is off%' and
        plan_table_output not like '-----' and
        plan_table_output not like 'Note' and
        plan_table_output not like '%Plan hash value%' and
        plan_table_output not like '%An uncaught error%' and
        plan_table_output not like '--------------------' and
        plan_table_output not like 'SQL_ID%' and
        length(trim(plan_table_output))> 0
        ;
