   set feed off pages 100 lines 150 

    col scn format          999,999,999,999,999,999,999,999
    col scn_per_day format  999,999,999,999,999,999,999,999
    col scn_alert   for a20

    col db_name for a15
    col verison for a12
    col current_date for a20
    select name db_name, version, to_char(sysdate,'DD-MON-YYYY HH24:MI') current_date from v$instance, v$database;

    select
        to_char(first_time,'YYYY/MM/DD HH24:MI') first_time,
        scn,
        scn_per_day,
        case when scn_per_day>5*PERCENTILE_DISC(0.5) WITHIN GROUP (order by scn_per_day desc ) over (partition by null) then '*SCN JUMPED*' else '' end as scn_alert
    from
    (
        select first_time, scn,scn - lag(scn) over(order by first_time) scn_per_day
        from
        (
            select first_time,first_change# as scn
            from v$log_history a
            where first_time>sysdate-14 and first_time=(select min(first_time) from v$log_history b where trunc(a.first_time)=trunc(b.first_time))
            union all
            select sysdate first_time, dbms_flashback.get_system_change_number from dual
        )
    )
    order by 1;

    prompt
    define LOWTHRESHOLD=10
    define MIDTHRESHOLD=62
    define VERBOSE=FALSE

    set veri off;
    set feedback off;

    set serverout on
    DECLARE
         verbose boolean:=&&VERBOSE;
    BEGIN
        For C in (
            select
                version,
                date_time,
                dbms_flashback.get_system_change_number current_scn,
                round(indicator,1) indicator,
                nvl((select 1 from v$parameter where name='_external_scn_rejection_threshold_hours' and value='24'),0) parameter
            from
            (
                select
                version,
                to_char(SYSDATE,'YYYY/MM/DD HH24:MI:SS') DATE_TIME,
                ((((
                    ((to_number(to_char(sysdate,'YYYY'))-1988)*12*31*24*60*60) +
                    ((to_number(to_char(sysdate,'MM'))-1)*31*24*60*60) +
                    (((to_number(to_char(sysdate,'DD'))-1))*24*60*60) +
                    (to_number(to_char(sysdate,'HH24'))*60*60) +
                    (to_number(to_char(sysdate,'MI'))*60) +
                    (to_number(to_char(sysdate,'SS')))
                    ) * (16*1024)) - dbms_flashback.get_system_change_number)
                / (16*1024*60*60*24)
                ) indicator
                from v$instance
            )
         ) LOOP
      dbms_output.put_line( '-------------------------------------------------------------------------------------------------------------------------------' );

      IF C.version > '10.2.0.5.0' and C.version NOT LIKE '9.2%' THEN
            IF C.indicator>&MIDTHRESHOLD THEN
                dbms_output.put_line('Result: A - SCN Headroom is good ='|| C.indicator || ' ( Low T=&LOWTHRESHOLD, Med T=&MIDTHRESHOLD )' );
                IF (C.version < '11.2.0.2' and C.parameter =0 ) THEN
                    dbms_output.put_line('Apply Patch AND set _external_scn_rejection_threshold_hours=24 after apply.');
                END IF;
            ELSIF C.indicator<=&LOWTHRESHOLD THEN
                dbms_output.put_line('***** Result: C - SCN Headroom is low *****  ='|| C.indicator || ' ( Low T=&LOWTHRESHOLD, Med T=&MIDTHRESHOLD )' );
                dbms_output.put_line('If you have not already done so apply the latest recommended patches right now' );
                IF (C.version < '11.2.0.2' and C.parameter =0 ) THEN
                    dbms_output.put_line('set _external_scn_rejection_threshold_hours=24 after apply');
                END IF;
                dbms_output.put_line('AND contact Oracle support immediately.' );
            ELSE
                dbms_output.put_line('**** Result: B - SCN Headroom is low ****  ='|| C.indicator || ' ( Low T=&LOWTHRESHOLD, Med T=&MIDTHRESHOLD )');
                dbms_output.put_line('If you have not already done so apply the latest recommended patches right now');
                IF (C.version < '11.2.0.2' and C.parameter =0 ) THEN
                    dbms_output.put_line('AND set _external_scn_rejection_threshold_hours=24 after apply.');
                END IF;
            END IF;
      ELSE
            IF C.indicator<=&MIDTHRESHOLD THEN
                dbms_output.put_line('**** Result: C - SCN Headroom is low ****  ='|| C.indicator || ' ( Low T=&LOWTHRESHOLD, Med T=&MIDTHRESHOLD )' );
                dbms_output.put_line('If you have not already done so apply the latest recommended patches right now' );
                IF (C.version >= '10.1.0.5.0' and C.version <= '10.2.0.5.0' and C.version NOT LIKE '9.2%' and C.parameter =0 ) THEN
                  dbms_output.put_line(', set _external_scn_rejection_threshold_hours=24 after apply');
                END IF;
                dbms_output.put_line('AND contact Oracle support immediately.' );
            ELSE
                dbms_output.put_line('Result: A - SCN Headroom is good  ='|| C.indicator || ' ( Low T=&LOWTHRESHOLD, Med T=&MIDTHRESHOLD )' );
                IF (C.version >= '10.1.0.5.0' and C.version <= '10.2.0.5.0' and C.version NOT LIKE '9.2%' and C.parameter =0 ) THEN
                    dbms_output.put_line('AND set _external_scn_rejection_threshold_hours=24 after apply.');
                END IF;
            END IF;
      END IF;
     END LOOP;
      dbms_output.put_line( '-------------------------------------------------------------------------------------------------------------------------------' );
    end;
    /
