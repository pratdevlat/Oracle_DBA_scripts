set feed off echo off verify off pages 140 lines 199 trimsp on
break on inst_id skip 1
col name for a15
col buffers for 999,999,999
col gb for 9999.99
col resize_state for a15
column ALLOC_GB format 999.99
column USED_GB format  999.99
column FREE_GB format  999.99
column pool format a15

prompt
prompt ##################################################################################
prompt #                                   SGAINFO                                      #
prompt ##################################################################################
column mb format 99,999,999
column SGA_RESOURCE format a39
column NAME for a31
SELECT
    INST_ID,
    NAME as SGA_RESOURCE,
    BYTES/1024/1024/1024 GB ,
    RESIZEABLE
FROM GV$SGAINFO
ORDER BY 1,3 DESC ;

prompt
prompt ##################################################################################
prompt #                                   SGASTAT                                      #
prompt ##################################################################################

col pool for a14 trunc
col inst_id for 99999
col name for a25 trunc
SELECT INST_ID,POOL,NAME,GB
FROM
    (
        SELECT
            INST_ID,
            POOL,
            NAME,
            BYTES/(1024*1024*1024) GB ,
            ROW_NUMBER() OVER (PARTITION BY INST_ID ORDER BY BYTES DESC,INST_ID) AS ROWN
        FROM GV$SGASTAT
        WHERE NAME NOT IN ('buffer_cache','free memory','log_buffer')
    ORDER BY 1,BYTES DESC
) where ROWN<20;

prompt
prompt ##################################################################################
prompt #                              DATABASE CACHE ADVISE                             #
prompt ##################################################################################
col size_factor for 99.999
col ESTD_PHYSICAL_READ_FACTOR for 999.99 head 'ESTD_PHYR|FACTOR'
col ESTD_PCT_OF_DB_TIME_FOR_READS for 999.99 head 'ESTD_PCT|FOR_READ'
col curr for a5
col advice_status for a4 head STAT
col name for a10 head POOL

break on inst_id skip 1 on name skip 1
SELECT inst_id, name, advice_status, curr, gb, size_factor, ESTD_PHYSICAL_READ_FACTOR, ESTD_PCT_OF_DB_TIME_FOR_READS
FROM
(
    SELECT
        inst_id,
        name,
        advice_status,
        size_for_estimate/1024 as GB,
        size_factor,
        case when size_factor=1 then '--->' else '' end curr,
        ESTD_PHYSICAL_READ_FACTOR,
        ESTD_PCT_OF_DB_TIME_FOR_READS,
        ROW_NUMBER() OVER (PARTITION BY INST_ID, NAME ORDER BY size_for_estimate) rn
        FROM GV$db_cache_advice
)
WHERE mod(rn,3)=0 OR size_factor = 1
ORDER BY INST_ID, NAME, GB;


prompt
prompt ##################################################################################
prompt #                              PGA INFO                                          #
prompt ##################################################################################
clear break
break on inst_id skip 1
col name for a30

SELECT inst_id, name, ROUND(VALUE /1024/1024/1024,2) AS GB
  FROM gv$pgastat a
  WHERE name IN ('aggregate PGA target parameter', 'total PGA inuse', 'total PGA allocated')
  order by 1,2 desc;

prompt
prompt ##################################################################################
prompt #                              PGA ADVISOR                                       #
prompt ##################################################################################
column estd_pga_cache_hit_percentage format 9,999.9 head 'ESTD_PGA|HIT_PCT'
column PGA_TARGET_FACTOR format 99.99 head 'PGA_TARGET|FACTOR'
col ESTD_OVERALLOC_COUNT for 999.99 head 'ESTD_OVER|COUNT'

SELECT
    inst_id,
    ROUND(pga_target_for_estimate / (1024 * 1024*1024 ),2) GB,
    PGA_TARGET_FACTOR,
    estd_pga_cache_hit_percentage,
    estd_overalloc_count
  FROM gv$pga_target_advice
where
    PGA_TARGET_FACTOR between 0.5 and 4
order by 1,2;
