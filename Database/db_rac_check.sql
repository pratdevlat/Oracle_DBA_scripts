  clear breaks
    set feed off pages 1000 lines 199 trimsp on

    col service_id for 99999
    col name for a36 trunc
    col network_name for a36 trunc
    col enabled for a7
    col failover_type for a10
    col blocked for a7
    col inst_id for 99999
    col sessions for 999,999,999
    col username for a30
    col service_name for a32
    col machine for a32
    col services for a130
        col inst_id for 9999 head INST

    select
        inst_id,
        LISTAGG(name, ', ') WITHIN GROUP (order by name) services
    from gv$active_services
    where name not like 'SYS%' and name not like 'GGATE%'
    group by inst_id
    order by 1;

        col db_name for a8
        col host_name for a10
        col instance_name for a10 head instance
        col services for a20 head WRONG_SERVICE
        col alert for a12
        col command for a100
        select
        *
        from
        (
            select
                inst_id,
                instance_name,
                case
                    when inst_id=1 and (instr(services,db_name||'_2')>0 or instr(services,db_name||'_3')>0 or instr(services,db_name||'2')>0 or instr(services,db_name||'3')>0) then '** Issue **'
                    when inst_id=2 and (instr(services,db_name||'_1')>0 or instr(services,db_name||'_3')>0 or instr(services,db_name||'1')>0 or instr(services,db_name||'3')>0) then '** Issue **'
                    when inst_id=3 and (instr(services,db_name||'_1')>0 or instr(services,db_name||'_2')>0 or instr(services,db_name||'1')>0 or instr(services,db_name||'2')>0) then '** Issue **'
                    else ''
                end Alert ,
                services,
                host_name,
                'srvctl relocate service -d '||db_name||' -s '||services||' -i '||instance_name||' -t '||db_name||decode(inst_id,1,2,1)||' -f' command
            from
            (
                select
                    lower(d.name) db_name,
                    s.inst_id,
                    host_name,
                    i.instance_name,
                    s.name as services
                from gv$active_services s, gv$instance i, v$database d
                where s.inst_id=i.inst_id and s.name not like 'SYS%' and s.name not like 'GGATE%' and s.name not like '%XDB%'
            )
            order by 1,2
        ) where alert is not null;
