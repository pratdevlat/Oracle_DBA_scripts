create or replace procedure           RMAN_REPORT_MAIL(p_out OUT VARCHAR2)  is
v_html CLOB;--varchar2(32000);
v_html2 CLOB;
v_html3 CLOB;
v_count number;
v_text VARCHAR2(32000);
v_subject VARCHAR2(32000);
v_to VARCHAR2(100);
v_is_detailed NUMBER := 0; -- is detailed 0-no, 1-yes
v_is_summary NUMBER :=0;-- is summary 0-no, 1-yes
v_last_backup NUMBER ;

cursor C_SUMMARY is
          SELECT Rbs.Db_Name
               ,lpad(to_char(Rbs.Num_Backupsets),15) backupset_count
               ,to_char(Rbs.Oldest_Backup_Time,'DD-MON-RRRR HH24:MI:SS') Oldest_Backup_Time
               ,to_char(Rbs.Newest_Backup_Time,'DD-MON-RRRR HH24:MI:SS') Newest_Backup_Time
               ,rbs.original_input_bytes_display input_size
               ,rbs.output_bytes_display         output_size
               ,lpad(to_char(round(rbs.compression_ratio,2)),18) compression_ratio
               ,trunc(SYSDATE) - TRUNC(Rbs.Newest_Backup_Time) Days_since_last_bckp
           FROM   Rman.Rc_Backup_Set_Summary Rbs 
           ORDER BY  Rbs.Newest_Backup_Time      
           ; 

cursor C_DETAIL is
          select d.db_name,
                   d.controlfile_included,
                   d.incremental_level,
                   d.pieces,
                   to_char(d.start_time,'DD-MON-RRRR HH24:MI:SS') start_time,
                   to_char(d.completion_time,'DD-MON-RRRR HH24:MI:SS') completion_time,
                   d.original_input_bytes_display,
                   d.output_bytes_display,
                   d.compressed,
                   d.compression_ratio,
                   d.time_taken_display time_taken
            from rman.RC_BACKUP_SET_DETAILS d
            WHERE rownum <10
            ORDER BY d.completion_time;

CURSOR C_PIECES IS
/*         SELECT  SUM(1) OVER (PARTITION BY rd.name ORDER BY to_char(max(bp.completion_time),'DD-MON-RRRR HH24:MI:SS')) seq
                ,rd.name db_name
                ,reverse(substr(reverse(bp.handle),instr(reverse(bp.handle),'/')+1)) path_of_backup
                ,to_char(min(bp.start_time),'DD-MON-RRRR HH24:MI:SS') start_time
                ,to_char(max(bp.completion_time),'DD-MON-RRRR HH24:MI:SS') completion_time
                ,sum(bp.elapsed_seconds) elapsed_seconds
                ,DECODE (bp.status,'A','available','U','unavailable','D','deleted','X','expired',bp.status) status

                ,CASE 
                   WHEN sum(bp.bytes) > 1073741824 THEN rpad(ROUND(sum(bp.bytes)/1024/1024/1024,2),7,' ')||' GB' 
                   ELSE rpad(ROUND(sum(bp.bytes)/1024/1024,2),7,' ')||' MB'
                 END size_GB
                 ,trunc(SYSDATE) - TRUNC(max(bp.completion_time)) Days_since_last_bckp
         FROM   rman.rc_database rd,
                rman.Rc_Backup_Piece bp
         WHERE rd.db_key=bp.db_key
         GROUP BY rd.name 
                ,reverse(substr(reverse(bp.handle),instr(reverse(bp.handle),'/')+1))
                ,DECODE (bp.status,'A','available','U','unavailable','D','deleted','X','expired',bp.status) 
         ORDER BY 2,5;*/
         /*SELECT  SUM(1) OVER (PARTITION BY rd.name ORDER BY to_char(max(bp.completion_time),'DD-MON-RRRR HH24:MI:SS')) seq
                ,rd.name db_name
                ,reverse(substr(reverse(bp.handle),instr(reverse(bp.handle),'/')+1)) path_of_backup
                ,to_char(min(bp.start_time),'DD-MON-RRRR HH24:MI:SS') start_time
                ,to_char(max(bp.completion_time),'DD-MON-RRRR HH24:MI:SS') completion_time
                ,sum(bp.elapsed_seconds) elapsed_seconds
               -- ,DECODE (bp.status,'A','available','U','unavailable','D','deleted','X','expired',bp.status) status

                ,CASE 
                   WHEN sum(bp.bytes) > 1073741824 THEN rpad(ROUND(sum(bp.bytes)/1024/1024/1024,2),7,' ')||' GB' 
                   ELSE rpad(ROUND(sum(bp.bytes)/1024/1024,2),7,' ')||' MB'
                 END size_GB
                 ,trunc(SYSDATE) - TRUNC(max(bp.completion_time)) Days_since_last_bckp

                 ,(SELECT rs.status FROM rman.rc_rman_status rs WHERE rd.name = rs.db_name AND rs.rsr_key=bp.rsr_key) status
                 --,bp.set_stamp
         FROM   rman.rc_database rd,
                rman.Rc_Backup_Piece bp
         WHERE rd.db_key=bp.db_key         
         GROUP BY rd.name 
                ,reverse(substr(reverse(bp.handle),instr(reverse(bp.handle),'/')+1))
                ,DECODE (bp.status,'A','available','U','unavailable','D','deleted','X','expired',bp.status) 
                ,bp.rsr_key
         ORDER BY 2,5;*/

         SELECT  SUM(1) OVER (PARTITION BY db_name ORDER BY /*days_since_last_bckp*/to_char(max(to_date(completion_time)),'DD-MON-RRRR') ASC) seq
                ,db_name
                ,path_of_BACKUP
                /*,to_char(MIN(to_date(start_time)),'DD-MON-RRRR') start_time
                ,to_char(max(to_date(completion_time)),'DD-MON-RRRR') completion_time
                ,sum(elapsed_seconds) elapsed_seconds*/
                -- corrected the timing calculation
                ,to_char(MIN((start_time)),'DD-MON-RRRR HH24:MI:SS') start_time
                ,to_char(max((completion_time)),'DD-MON-RRRR HH24:MI:SS') completion_time
                --,sum(elapsed_seconds) elapsed_seconds
                ,trunc((max(completion_time)-MIN(start_time))*24*60*60,2) elapsed_seconds
                ,round(sum(size_mb),2) size_mb
                ,days_since_last_bckp
                ,status 
         FROM 
         (
         SELECT  --SUM(1) OVER (PARTITION BY rd.name ORDER BY to_char(max(bp.completion_time),'DD-MON-RRRR HH24:MI:SS')) seq
                         rd.name db_name
                         ,reverse(substr(reverse(bp.handle),instr(reverse(bp.handle),'/')+1)) path_of_backup
                         ,min(bp.start_time) start_time
                         ,max(bp.completion_time) completion_time
                         ,sum(bp.elapsed_seconds) elapsed_seconds
                          ,sum(bp.bytes)/1024/1024  size_MB
                          ,trunc(SYSDATE) - TRUNC(max(bp.completion_time)) Days_since_last_bckp
                          ,(SELECT rs.status FROM rman.rc_rman_status rs WHERE rd.name = rs.db_name AND rs.rsr_key=bp.rsr_key) status
                  FROM   rman.rc_database rd,
                         rman.Rc_Backup_Piece bp
                  WHERE rd.db_key=bp.db_key         
                  GROUP BY rd.name 
                         ,reverse(substr(reverse(bp.handle),instr(reverse(bp.handle),'/')+1))
                         ,DECODE (bp.status,'A','available','U','unavailable','D','deleted','X','expired',bp.status) 
                         ,bp.rsr_key
                  ORDER BY 1,4)
         GROUP BY
               db_name
                ,path_of_BACKUP
                ,days_since_last_bckp
                ,status          
         ORDER BY  db_name,  completion_time ;

begin
v_count :=0;

/* This part will handle the logic regarding to when to send the mail          */
/* If there are problems with the RMAN backup then the mail should be sent     */
/* Untill the logic defined a constant, the mail will always be sent v_count=1 */
v_count:=1;

if v_count>0 then 
   -- create the html to send via mail
    v_html := '<html>
    <body>
    <h3>prathmesh RMAN Monitor Report</h3>

    <HR WIDTH="100%" COLOR="#6699FF" SIZE="3">
    <h4> </h4>';

    IF v_is_summary=1 THEN
    v_html :='
    <h4><big><u>Summary</u></big>
    <table border="1" 
    bgcolor="white"
    BORDERCOLOR ="#6699FF"
    CELLSPACING=1
    WIDTH=100%
    align="center"
    >
    <tr bgcolor="#E6E6E6"><b>
      <td><font size="2" face="Times">DB Name</td>
      <!--<td><font size="2" face="Times">Backupset Count</td>-->
      <td><font size="2" face="Times">Oldest Backup Time</td>
      <td><font size="2" face="Times">Newest Backup Time</td>
      <td><font size="2" face="Times">Input Size</td>
      <td><font size="2" face="Times">Output Size</td>
      <td><font size="2" face="Times">Compression Ratio</td>
      <td><font size="2" face="Times">Days since last bckp</td>
    </b></tr>   
    ';
    for aa in C_SUMMARY LOOP
       IF aa.days_since_last_bckp=0 THEN
        v_html := v_html||'<tr align="center" bgcolor="#A9F5A9"><b>
                            <td><font size="2" face="Times">'||aa.db_name||'</td>
                            <!--<td><font size="2" face="Times">'||aa.backupset_count||'</td>-->
                            <td><font size="2" face="Times">'||aa.oldest_backup_time||'</td>
                            <td><font size="2" face="Times">'||aa.newest_backup_time||'</td>
                            <td><font size="2" face="Times">'||aa.input_size||'</td>
                            <td><font size="2" face="Times">'||aa.output_size||'</td>
                            <td><font size="2" face="Times">'||aa.compression_ratio||'</td>
                            <td><font size="2" face="Times">'||aa.days_since_last_bckp||'</td>
                          </b></tr>';
       ELSE 
          IF aa.days_since_last_bckp=1 THEN
            v_html := v_html||'<tr align="center" bgcolor="#F4FA58"><b>
                               <td><font size="2" face="Times">'||aa.db_name||'</td>
                               <!--<td><font size="2" face="Times">'||aa.backupset_count||'</td>-->
                               <td><font size="2" face="Times">'||aa.oldest_backup_time||'</td>
                               <td><font size="2" face="Times">'||aa.newest_backup_time||'</td>
                               <td><font size="2" face="Times">'||aa.input_size||'</td>
                               <td><font size="2" face="Times">'||aa.output_size||'</td>
                               <td><font size="2" face="Times">'||aa.compression_ratio||'</td>
                               <td><font size="2" face="Times">'||aa.days_since_last_bckp||'</td>
                             </b></tr>';             
          ELSE
            v_html := v_html||'<tr align="center" bgcolor="#FA5882"><b>
                               <td><font size="2" face="Times">'||aa.db_name||'</td>
                               <!--<td><font size="2" face="Times">'||aa.backupset_count||'</td>-->
                               <td><font size="2" face="Times">'||aa.oldest_backup_time||'</td>
                               <td><font size="2" face="Times">'||aa.newest_backup_time||'</td>
                               <td><font size="2" face="Times">'||aa.input_size||'</td>
                               <td><font size="2" face="Times">'||aa.output_size||'</td>
                               <td><font size="2" face="Times">'||aa.compression_ratio||'</td>
                               <td><font size="2" face="Times">'||aa.days_since_last_bckp||'</td>
                             </b></tr>';
        END IF;
      END IF;
    END LOOP;
    END IF;
    IF v_is_detailed=1 THEN
          -- Details table in the HTML page
          v_html := v_html||'

          </table>
          <HR WIDTH="100%" COLOR="#6699FF" SIZE="3">
          <h4><big><u>Details</u></big>
          <table border="1" 
          bgcolor="white"
          BORDERCOLOR ="#6699FF"
          CELLSPACING=1
          WIDTH=100%    
          >
          <tr bgcolor="#E6E6E6"><b>
            <td><font size="2" face="Times">DB Name</td>
            <td><font size="2" face="Times">Controlfile Included</td>
            <td><font size="2" face="Times">Incremental Level</td>
            <td><font size="2" face="Times">Pieces</td>
            <td><font size="2" face="Times">Start Time</td>
            <td><font size="2" face="Times">Completion Time</td>
            <td><font size="2" face="Times">Original Input Size</td>
            <td><font size="2" face="Times">Output Bytes Size</td>
            <td><font size="2" face="Times">Compressed</td>
            <td><font size="2" face="Times">Compression_ratio</td>
            <td><font size="2" face="Times">Time Taken</td>
          </b></tr>   
          ';

          for bb in C_DETAIL loop
              v_html := v_html||'<tr align="center">
                                  <td><font size="2" face="Times">'||bb.db_name||'</td>
                                  <td><font size="2" face="Times">'||bb.controlfile_included||'</td>
                                  <td><font size="2" face="Times">'||bb.incremental_level||'</td>
                                  <td><font size="2" face="Times">'||bb.pieces||'</td>
                                  <td><font size="2" face="Times">'||bb.start_time||'</td>
                                  <td><font size="2" face="Times">'||bb.completion_time||'</td>
                                  <td><font size="2" face="Times">'||bb.original_input_bytes_display||'</td>
                                  <td><font size="2" face="Times">'||bb.output_bytes_display||'</td>
                                  <td><font size="2" face="Times">'||bb.compressed||'</td>
                                  <td><font size="2" face="Times">'||bb.compression_ratio||'</td>
                                  <td><font size="2" face="Times">'||bb.time_taken||'</td>
                                </tr>';
          end loop;

         /* v_html := v_html||'
          </table>
          <HR WIDTH="100%" COLOR="#6699FF" SIZE="3">
          </body>
          </html>';*/
    ELSE NULL;
       /*v_html := v_html||'
       </table>
       <HR WIDTH="100%" COLOR="#6699FF" SIZE="3">
       </body>
       </html>';*/
    END IF;

    /*add the pieces cursor*/

    v_html := v_html||'

          </table>
          <!--<HR WIDTH="100%" COLOR="#6699FF" SIZE="3">-->
          <h4><big><u>Backup Sets Summary</u></big>
                    <br></br>
          <table border="1" 
          bgcolor="white"
          BORDERCOLOR ="#6699FF".
          CELLSPACING=1
          WIDTH=100%    
          >
          <tr align="center" bgcolor="#E6E6E6"><b>
            <td><font size="2" face="Times">Updated Backup => </td>
            <td bgcolor="#A9F5A9"><font size="2" face="Times" color="#A9F5A9">DB</td>
            <td bgcolor="white" BORDERCOLOR ="WHITE"><font size="2" face="Times" color="WHITE">space</td>
            <td><font size="2" face="Times">1 Day Outdate => </td>
            <td bgcolor="#F4FA58"><font size="2" face="Times" color="#F4FA58">DB</td>
            <td bgcolor="white" BORDERCOLOR ="WHITE"><font size="2" face="Times" color="WHITE">space</td>
            <td><font size="2" face="Times">Out Of DATE =></td>
            <td bgcolor="#FA5882"><font size="2" face="Times" color="#FA5882">DB<br></br></td>
          </b></tr>
          </table>
          <br></br>
          <table border="1" 
          bgcolor="white"
          BORDERCOLOR ="#6699FF"
          CELLSPACING=1
          WIDTH=100%    
          >
          <tr align="center" bgcolor="#E6E6E6"><b>
            <td><font size="2" face="Times">Seq (per DB)</td>
            <td><font size="2" face="Times">DB Name</td>
            <td><font size="2" face="Times">Status</td>
            <td><font size="2" face="Times">Start Time</td>
            <td><font size="2" face="Times">Completion Time</td>
            <td><font size="2" face="Times">Elapsed Time<br></br>(Seconds)</td>
            <td><font size="2" face="Times">Size</td>
            <td><font size="2" face="Times">Path of Backup</td>
            <td><font size="2" face="Times">Days Since<br></br>Last Backup</td>
          </b></tr>   
          ';

          for cc in C_PIECES loop
              SELECT          
                  --rd.name db_name
                  --,to_char(max(bp.completion_time),'DD-MON-RRRR HH24:MI:SS') completion_time
                  trunc(SYSDATE) - TRUNC(max(bp.completion_time)) Days_since_last_bckp
               INTO v_last_backup
               FROM   rman.rc_database rd,
                      rman.Rc_Backup_Piece bp
               WHERE rd.db_key=bp.db_key
                     AND rd.name=cc.db_name
               GROUP BY rd.name  
               ;
              -- set line colors:
              IF (cc.status='COMPLETED' AND v_last_backup=0) THEN
              --IF v_last_backup=0 THEN
                 v_html := v_html||'<tr align="center" bgcolor="#A9F5A9"><b>
                                     <td><font size="2" face="Times">'||cc.seq||'</td>
                                     <td align="left"><font size="2" face="Times">'||cc.db_name||'</td>
                                     <td><font size="2" face="Times">'||cc.status||'</td>
                                     <td><font size="2" face="Times">'||cc.start_time||'</td>
                                     <td><font size="2" face="Times">'||cc.completion_time||'</td>
                                     <td><font size="2" face="Times">'||round(cc.elapsed_seconds)||'</td>                                  
                                     <td><font size="2" face="Times">'||cc.size_mb||'</td>
                                     <td align="left"><font size="2" face="Times">'||cc.path_of_backup||'</td>
                                     <td><font size="2" face="Times">'||cc.days_since_last_bckp||'</td>
                                   </b></tr>';
                ELSE 
                   IF cc.status='COMPLETED' AND (v_last_backup BETWEEN 1 AND 1) THEN
                   --IF v_last_backup BETWEEN 1 AND 1 THEN
                     v_html := v_html||'<tr align="center" bgcolor="#F4FA58"><b>
                                     <td><font size="2" face="Times">'||cc.seq||'</td>
                                     <td align="left"><font size="2" face="Times">'||cc.db_name||'</td>
                                     <td><font size="2" face="Times">'||cc.status||'</td>
                                     <td><font size="2" face="Times">'||cc.start_time||'</td>
                                     <td><font size="2" face="Times">'||cc.completion_time||'</td>
                                     <td><font size="2" face="Times">'||round(cc.elapsed_seconds)||'</td>                                  
                                     <td><font size="2" face="Times">'||cc.size_mb||'</td>
                                     <td align="left"><font size="2" face="Times">'||cc.path_of_backup||'</td>
                                     <td><font size="2" face="Times">'||cc.days_since_last_bckp||'</td>
                                      </b></tr>';             
                   ELSE
                     v_html := v_html||'<tr align="center" bgcolor="#FA5882"><b>
                                     <td><font size="2" face="Times">'||cc.seq||'</td>
                                     <td align="left"><font size="2" face="Times">'||cc.db_name||'</td>
                                     <td><font size="2" face="Times">'||nvl(cc.status,'UNKNOWN')||'</td>
                                     <td><font size="2" face="Times">'||cc.start_time||'</td>
                                     <td><font size="2" face="Times">'||cc.completion_time||'</td>
                                     <td><font size="2" face="Times">'||round(cc.elapsed_seconds)||'</td>                                  
                                     <td><font size="2" face="Times">'||cc.size_mb||'</td>
                                     <td align="left"><font size="2" face="Times">'||cc.path_of_backup||'</td>
                                     <td><font size="2" face="Times">'||cc.days_since_last_bckp||'</td>
                                      </b></tr>';
                 END IF;
              END IF;

              IF length(v_html) > 32000
                 THEN 
                    v_html2 := v_html2||v_html;
                    v_html := ''; 
                    --EXIT;
              END IF;
          end loop;
    DBMS_OUTPUT.PUT_LINE('finished preparing the HTML'); 

    v_html := v_html||' </table>';

    /*IF length(v_html) > 32000
       THEN    
       v_html := v_html||'<BR></BR>
       <h4><big><u>Report is too long to be displayed...</u></big>
       <BR></BR>';
       v_html2 := v_html2||v_html;
       END IF;*/
     v_html := v_html||'<HR WIDTH="100%" COLOR="#6699FF" SIZE="3">
       </body>
       </html>';

    v_html3 := v_html2||v_html;

    v_subject := 'prathmesh RMAN Monitor Report for '||to_char(SYSDATE, 'DD-Mon-RRRR');
    v_to :='DBA@int.prathmesh.com';

    --v_to :='DBA@TLV.prathmesh.com';


    --v_to := 'tamirla@prathmesh.com';
    --DBMS_OUTPUT.PUT_LINE('length: '||length(v_html3));
    --v_html3 := substr(v_html3,1,30000);
    BEGIN
    IF length(v_html3) > 31000 THEN

    v_text := 'Since the Report is too long, it is attached.';


    prathmesh_send_mail_att(p_to          => v_to,
            p_from        => 'RMAN_CATALOG@prathmesh.COM',
            p_subject     => v_subject,
            p_text_msg    => v_text,
            p_attach_name => 'RMAN_Catalog_Report.html',
            p_attach_mime => 'html',
            p_attach_clob => v_html3,
            p_smtp_host   => 'tlv.corp.prathmesh.com');

     ELSE  
      prathmesh_html_email(p_to => v_to,
                    p_from => 'RMAN_CATALOG@prathmesh.COM',
                    p_subject => v_subject ,
                    p_text => 'RMAN Catalog',
                    --p_html => substr(v_html3,1,60000),
                    p_html => v_html3,
                    p_smtp_hostname => 'tlv.corp.prathmesh.com',
                    p_smtp_portnum => 25);                           
      COMMIT;
    END IF;  
    EXCEPTION WHEN OTHERS THEN p_out := 'Failed in send mail part';
    END; 
    p_out := 'prathmesh RMAN Monitor Report completed successfully on ' ||to_char(SYSDATE,'DD-Mon-RRRR HH24:MI:SS');
else null;      
end if;     
exception
    when others 
    THEN
      DBMS_OUTPUT.PUT_LINE('Error in report send mail procedure'); 
      DBMS_OUTPUT.PUT_LINE('Error: '||substr(SQLERRM,1,250));  
      p_out := 'Error :'|| SQLCODE || ' - ' || substr(SQLERRM,1,150);
      --DBMS_OUTPUT.PUT_LINE('length(v_html): '||length(v_html));  
      raise;                              
end RMAN_REPORT_MAIL;
