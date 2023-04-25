--------------------------------
---Tablespace Size Query
----------------------------
set pages 49999 lin 120
col tablespace_name for a32 tru
col "Total GB"  for 999,999.9
col "GB Used"   for 999,999.9
col "GB Free"   for 99,999.9
col "Pct Free"  for 999.9
col "Pct Used"  for 999.9
comp sum of "Total GB"  on report
comp sum of "GB Used"   on report
comp sum of "GB Free"   on report
break on report
Select A.Tablespace_Name, B.Total/1024/1024/1024 "Total GB",
       (B.Total-a.Total_Free)/1024/1024/1024 "GB Used",
       A.Total_Free/1024/1024/1024 "GB Free",
       (A.Total_Free/B.Total) * 100 "Pct Free",
       ((B.Total-A.Total_Free)/B.Total) * 100 "Pct Used"
  From (Select Tablespace_Name, Sum(Bytes) Total_Free
          From Sys.Dba_Free_Space
         Group By Tablespace_Name     ) A
     , (Select Tablespace_Name, Sum(Bytes) Total
          From Sys.Dba_Data_Files
         Group By Tablespace_Name     ) B
Where A.Tablespace_Name 
  A.Tablespace_Name = B.Tablespace_Name
Order By 1
/

--------------------------------
---Database size query
--------------------------
SET SERVEROUTPUT ON

DECLARE
   v_tot_db_size_mb NUMBER;
   v_tot_free_space_mb NUMBER;
   v_tot_used_space_mb NUMBER;
   v_timestamp TIMESTAMP;
BEGIN
   -- Get the total size of the database in GB
   SELECT SUM(bytes)/1024/1024/1024 INTO v_tot_db_size_gb FROM dba_data_files;
   
   -- Get the total amount of free space in GB
   SELECT SUM(bytes)/1024/1024/1024 INTO v_tot_free_space_gb FROM dba_free_space;
   
   -- Calculate the total used space in GB
   v_tot_used_space_mb := v_tot_db_size_gb - v_tot_free_space_gb;
   
   -- Get the current timestamp
   SELECT SYSTIMESTAMP INTO v_timestamp FROM dual;
   
   -- Print the results
   DBMS_OUTPUT.PUT_LINE('Timestamp: ' || v_timestamp);
   DBMS_OUTPUT.PUT_LINE('Total database size (GB): ' || v_tot_db_size_gb);
   DBMS_OUTPUT.PUT_LINE('Total free space (GB): ' || v_tot_free_space_gb);
   DBMS_OUTPUT.PUT_LINE('Total used space (GB): ' || v_tot_used_space_gb);
END;
/
--------------------------------
--Database growth monthly
----------------------------------
SET SERVEROUTPUT ON
DECLARE
   v_begin_date DATE := TO_DATE('2022-01-01', 'YYYY-MM-DD');
   v_end_date DATE := ADD_MONTHS(v_begin_date, 12);
   v_month_start DATE;
   v_month_end DATE;
   v_month_growth NUMBER;
BEGIN
   DBMS_OUTPUT.PUT_LINE('MONTH, GROWTH (MB)');
   WHILE v_begin_date < v_end_date LOOP
      v_month_start := v_begin_date;
      v_month_end := LAST_DAY(v_begin_date);
      SELECT (SUM(bytes) / 1024 / 1024 / 1024 ) INTO v_month_growth
      FROM v$datafile
      WHERE creation_time BETWEEN v_month_start AND v_month_end;
      DBMS_OUTPUT.PUT_LINE(TO_CHAR(v_begin_date, 'YYYY-MM') || ', ' || v_month_growth);
      v_begin_date := ADD_MONTHS(v_begin_date, 1);
   END LOOP;
END;
/
--------------------------------
----Database growth by day and 7 day
--------------------------------

select min(creation_time) "Create Time", ts.name, round(sum(df.bytes)/1024/1024) curr_size_mb,round( (sum(df.bytes)/1024/1024)/round(sysdate-min(creation_time)),1) growth_per_day,round( (sum(df.bytes)/1024/1024)/round(sysdate-min(creation_time)) * 7,1) growth_7_days from v$datafile df ,v$tablespace ts where df.ts#=ts.ts# group by df.ts#,ts.name order by df.ts#;





