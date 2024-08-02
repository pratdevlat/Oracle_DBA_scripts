#!/usr/bin/bash
#---------------------------------------------------------------------------
# Description : Provides output  for each running database on
#               on a machine
#---------------------------------------------------------------------------

ORATAB=/etc/oratab
#echo "INSTANCE_NAME, FILE_NAME"

# Step through running instances
#ps -ef | grep ora_smon_ | grep -v grep | cut -b58-70
awk -F: '!/^#/ && NF > 2 && $2 != "N" {print $1}' /etc/oratab | while read LINE #---- run command till cut first to adjust for databse name
do
    # Assign the ORACLE_SID
    ORACLE_SID=$LINE
    export ORACLE_SID

    #Find ORACLE_HOME info for current instance
    ORATABLINE=`grep $LINE $ORATAB`
    ORACLE_HOME=`echo $ORATABLINE | cut -f2 -d:`
    export ORACLE_HOME
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib
    export LD_LIBRARY_PATH

    # Put $ORACLE_HOME/bin into PATH and export.
    PATH=$ORACLE_HOME/bin:/bin:/usr/bin:/etc ; export PATH

    echo "===========================================================================" $ORACLE_SID "=================================================================================="
    # Get SGA
    sqlplus -s "/ as sysdba" <<EOF
    @psuchecklist.sql
EOF
    echo "  "

    $ORACLE_HOME/OPatch/opatch lspatches

done
