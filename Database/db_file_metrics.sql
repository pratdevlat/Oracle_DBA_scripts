   define SORT=4

    set pages 900 verify off line 132 feed off
    col tablespace_name     for a30
    col file_id             for 999999
    col AVERAGE_READ_TIME   for 999.99
    col AVERAGE_WRITE_TIME  for 999.99
    col PHYSICAL_READS      for 999,999,999.99
    col PHYSICAL_WRITES     for 999,999,999.99
    select  * from
    (
    select
        tablespace_name, 
        m.file_id,
        m.AVERAGE_READ_TIME AVERAGE_READ_TIME,
        m.AVERAGE_WRITE_TIME AVERAGE_WRITE_TIME,
        m.PHYSICAL_READS as PHYSICAL_READS,
        m.PHYSICAL_WRITES as PHYSICAL_WRITES
    from
        v$FILEMETRIC m,
        dba_data_files d
    where
        m.file_id=d.file_id
    order by &SORT  desc
    ) where rownum<30 ;
