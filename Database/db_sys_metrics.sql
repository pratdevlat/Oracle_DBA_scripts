   set feed off pages 100 lines 199 trimsp on 
    col metric_name for a50 trunc
    col value       for 999,999,999.99
    col metric_unit for a30 trunc

    select
        metric_name, 
        value, 
        metric_unit
    from
        v$SYSMETRIC
    where metric_id in (2000,2003,2004,2006,2016,2018,2020,2022,2024,2026, 2030,2034, 2114, 2040,2057, 2058,2065, 2094, 2096, 2104, 2112, 2115, 2090, 2103, 2124, 2135)
    and group_id=2
    order by 1;
