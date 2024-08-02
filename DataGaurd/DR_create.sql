Git link : https://github.com/poornimaa/RDBMS-Oracle-DR-DataGuard/tree/master/Scripts/dg_build_scripts


Creating a Physical Standby database using RMAN restore database from service (Doc ID 2283978.1)
https://support.oracle.com/epmos/faces/SearchDocDisplay?_adf.ctrl-state=70jexvfr4_200&_afrLoop=280010726678574#aref_section221

RMAN duplicate command to restore standby from L0 production backup

Note : Make sure standby database should be started in nomount stage before restoring from duplicate 

$Cat standby_duplicate.sh
export ORACLE_SID=DBNAME
export ORACLE_HOME=oracle_home_path
export PATH=$PATH:$ORACLE_HOME/bin
rman auxiliary / log=path_to_logfile <<EOF                     
run {
        allocate auxiliary channel c1 device type disk;
        allocate auxiliary channel c2 device type disk;
        allocate auxiliary channel c3 device type disk;
        allocate auxiliary channel c4 device type disk;
        allocate auxiliary channel c5 device type disk;
        allocate auxiliary channel c6 device type disk;
        allocate auxiliary channel c7 device type disk;
        allocate auxiliary channel c8 device type disk;
                allocate auxiliary channel c9 device type disk;
                allocate auxiliary channel c10 device type disk;
                allocate auxiliary channel c11 device type disk;
                allocate auxiliary channel c12 device type disk;
                allocate auxiliary channel c13 device type disk;
                allocate auxiliary channel c14 device type disk;
                allocate auxiliary channel c15 device type disk;
                allocate auxiliary channel c16 device type disk;
                allocate auxiliary channel c17 device type disk;
                allocate auxiliary channel c18 device type disk;
                allocate auxiliary channel c19 device type disk;
                allocate auxiliary channel c20 device type disk;
                allocate auxiliary channel c21 device type disk;
                allocate auxiliary channel c22 device type disk;
                allocate auxiliary channel c23 device type disk;
                allocate auxiliary channel c24 device type disk;
                allocate auxiliary channel c25 device type disk;
                allocate auxiliary channel c26 device type disk;
                allocate auxiliary channel c27 device type disk;
                allocate auxiliary channel c28 device type disk;
                allocate auxiliary channel c29 device type disk;
                allocate auxiliary channel c30 device type disk;
                DUPLICATE TARGET DATABASE FOR STANDBY nofilenamecheck BACKUP LOCATION 'backup_file_location';
}
exit;
EOF

