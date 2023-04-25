  set pages 90 verify off line 199 feed off trimsp off verify off
    col DATE_DAY for a16
    col H00 for 999
    col H01 for 999
    col H02 for 999
    col H03 for 999
    col H04 for 999
    col H05 for 999
    col H06 for 999
    col H07 for 999
    col H08 for 999
    col H09 for 999
    col H10 for 999
    col H11 for 999
    col H12 for 999
    col H13 for 999
    col H14 for 999
    col H15 for 999
    col H16 for 999
    col H17 for 999
    col H18 for 999
    col H19 for 999
    col H20 for 999
    col H21 for 999
    col H22 for 999
    col H23 for 999
    SELECT
           TO_CHAR (FIRST_TIME, 'YYYY/MM/DD DY') AS DATE_DAY,
           SUM (DECODE(F_HOUR, 0,1,0)) H00,
           SUM (DECODE(F_HOUR, 1,1,0)) H01,
           SUM (DECODE(F_HOUR, 2,1,0)) H02,
           SUM (DECODE(F_HOUR, 3,1,0)) H03,
           SUM (DECODE(F_HOUR, 4,1,0)) H04,
           SUM (DECODE(F_HOUR, 5,1,0)) H05,
           SUM (DECODE(F_HOUR, 6,1,0)) H06,
           SUM (DECODE(F_HOUR, 7,1,0)) H07,
           SUM (DECODE(F_HOUR, 8,1,0)) H08,
           SUM (DECODE(F_HOUR, 9,1,0)) H09,
           SUM (DECODE(F_HOUR,10,1,0)) H10,
           SUM (DECODE(F_HOUR,11,1,0)) H11,
           SUM (DECODE(F_HOUR,12,1,0)) H12,
           SUM (DECODE(F_HOUR,13,1,0)) H13,
           SUM (DECODE(F_HOUR,14,1,0)) H14,
           SUM (DECODE(F_HOUR,15,1,0)) H15,
           SUM (DECODE(F_HOUR,16,1,0)) H16,
           SUM (DECODE(F_HOUR,17,1,0)) H17,
           SUM (DECODE(F_HOUR,18,1,0)) H18,
           SUM (DECODE(F_HOUR,19,1,0)) H19,
           SUM (DECODE(F_HOUR,20,1,0)) H20,
           SUM (DECODE(F_HOUR,21,1,0)) H21,
           SUM (DECODE(F_HOUR,22,1,0)) H22,
           SUM (DECODE(F_HOUR,23,1,0)) H23
    FROM
        (
            SELECT
                  FIRST_TIME, TO_NUMBER(TO_CHAR (FIRST_TIME, 'HH24')) F_HOUR
            FROM
                  V$LOG_HISTORY
            WHERE
                  FIRST_TIME>SYSDATE-30
        )
    GROUP BY
           TO_CHAR (FIRST_TIME, 'YYYY/MM/DD DY')
    ORDER BY 1;

    col DATE_DAY for a19
    col INST_1_GB for 999,999
    col INST_2_GB for 999,999
    col INST_3_GB for 999,999
    col TOTAL_GB for 999,999
    break on report
    compute sum of INST_1_GB on report
    compute sum of INST_2_GB on report
    compute sum of TOTAL_GB on report

    SELECT
           to_char(FIRST_TIME,'YYYY/MM/DD DY') DATE_DAY,
           sum(case when thread#=1 then blocks*block_size else 0 end)/1024/1024/1024 INST_1_GB,
           sum(case when thread#=2 then blocks*block_size else 0 end)/1024/1024/1024 INST_2_GB,
           sum(blocks*block_size)/1024/1024/1024 TOTAL_GB
    FROM
           v$archived_log a
    WHERE
           FIRST_TIME > trunc(SYSDATE) - 7
    group by to_char(FIRST_TIME,'YYYY/MM/DD DY')
    order by 1;

    SELECT
           to_char(FIRST_TIME,'YYYY/MM/DD DY HH24') DATE_DAY,
           sum(case when thread#=1 then blocks*block_size else 0 end)/1024/1024/1024 INST_1_GB,
           sum(case when thread#=2 then blocks*block_size else 0 end)/1024/1024/1024 INST_2_GB,
           sum(blocks*block_size)/1024/1024/1024 TOTAL_GB
    FROM
           v$archived_log a
    WHERE
           FIRST_TIME > trunc(SYSDATE) - 1
    group by to_char(FIRST_TIME,'YYYY/MM/DD DY HH24')
    order by 1;
