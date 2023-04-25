##########################################################################
    # need to get permission for x$bh                                        #
    # create or replace view x$bh as select * from x$bh;                     #
    # grant select on x$bh to public;                                        #
    ##########################################################################

    set lines 132 tab off pages 5000 feed off

    column owner format a25
    column object_name format a30
    column mem_block format 999,999,999
    column Percent format 999.9
    column TB_Block format 999,999,999
    column buffer format a10

    col name for a15 heading "Buffer Name"
    col buffers for 999,999,999 heading "Blocks"
    col mb for 999,999,999 heading "Size (Mb)"

    select name, buffers, buffers/1024/1024*8192 MB from v$BUFFER_POOL where buffers>0;

    break on buffer
    compute sum of mem_block on buffer

    select * from 
    (
        select
                buffer_pool_id buffer,
                owner, object_name, mem_block, tb_block, mem_block/tb_block*100 Percent
        from (
                select /*+ ordered use_hash(bh,o) */
                        u.name owner,
                        o.name object_name,
                        sum(mem_block) mem_block ,
                        sum(s.BLOCKS) tb_block,
                        min(s.BUFFER_POOL) buffer_pool_id
                from
                        (select obj,count(*) mem_block from sys.x$bh where ts#<>(select ts# from sys.ts$ where name='SYSTEM') group by obj) bh,
                        sys.obj$ o,
                        sys.user$ u,
                        dba_segments s
                WHERE
                        o.dataobj#  = bh.obj
                        and o.owner#=u.user#
                        and s. owner=u.name
                        and s.segment_name=o.name
                group by u.name,o.name
        )
        order by 1 desc,mem_block
    ) where rownum<50;
