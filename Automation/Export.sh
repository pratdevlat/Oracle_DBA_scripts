#!/bin/bash

# === Configuration ===
ORACLE_DIR="BACKUP_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/export_${TIMESTAMP}.log"
EMAILS="email@email.com"

# === Ensure log directory exists ===
mkdir -p "$LOG_DIR"

# === Prompt user for export type ===
echo "Choose export type:"
echo "1. Schema"
echo "2. Table"
echo "3. Full Database"
read -p "Enter your choice (1/2/3): " EXPORT_TYPE

# === Prompt user for schema or table name based on export type ===
if [ "$EXPORT_TYPE" == "1" ]; then
    read -p "Enter the schema name to export: " SCHEMA_NAME
elif [ "$EXPORT_TYPE" == "2" ]; then
    read -p "Enter the schema name: " SCHEMA_NAME
    read -p "Enter the table name to export: " TABLE_NAME
fi

# === Start logging output ===
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Export started at: $TIMESTAMP ==="
echo "Writing logs to: $LOG_FILE"

# === Run SQLPlus and do export ===
sqlplus -s / as sysdba <<EOF

SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE

DECLARE
    h1 NUMBER;
    job_name VARCHAR2(30) := 'EXPDP_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting Job: ' || job_name);

    IF '$EXPORT_TYPE' = '1' THEN
        h1 := DBMS_DATAPUMP.OPEN(operation => 'EXPORT', job_mode => 'SCHEMA', job_name => job_name);
        DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => '${SCHEMA_NAME}_${TIMESTAMP}_%U.dmp', directory => '${ORACLE_DIR}', filetype => DBMS_DATAPUMP.KU\$_FILE_TYPE_DUMP_FILE);
        DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => '${SCHEMA_NAME}_${TIMESTAMP}.log', directory => '${ORACLE_DIR}', filetype => DBMS_DATAPUMP.KU\$_FILE_TYPE_LOG_FILE);
        DBMS_DATAPUMP.METADATA_FILTER(handle => h1, name => 'SCHEMA_EXPR', value => 'IN (''${SCHEMA_NAME}'')');
        
    ELSIF '$EXPORT_TYPE' = '2' THEN
        h1 := DBMS_DATAPUMP.OPEN(operation => 'EXPORT', job_mode => 'TABLE', job_name => job_name);
        DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => '${SCHEMA_NAME}_${TABLE_NAME}_${TIMESTAMP}_%U.dmp', directory => '${ORACLE_DIR}', filetype => DBMS_DATAPUMP.KU\$_FILE_TYPE_DUMP_FILE);
        DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => '${SCHEMA_NAME}_${TABLE_NAME}_${TIMESTAMP}.log', directory => '${ORACLE_DIR}', filetype => DBMS_DATAPUMP.KU\$_FILE_TYPE_LOG_FILE);
        DBMS_DATAPUMP.METADATA_FILTER(handle => h1, name => 'NAME_EXPR', value => 'IN (''${TABLE_NAME}'')');
        DBMS_DATAPUMP.METADATA_FILTER(handle => h1, name => 'SCHEMA_EXPR', value => 'IN (''${SCHEMA_NAME}'')');

    ELSE
        h1 := DBMS_DATAPUMP.OPEN(operation => 'EXPORT', job_mode => 'FULL', job_name => job_name);
        DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => 'FULL_DB_${TIMESTAMP}_%U.dmp', directory => '${ORACLE_DIR}', filetype => DBMS_DATAPUMP.KU\$_FILE_TYPE_DUMP_FILE);
        DBMS_DATAPUMP.ADD_FILE(handle => h1, filename => 'FULL_DB_${TIMESTAMP}.log', directory => '${ORACLE_DIR}', filetype => DBMS_DATAPUMP.KU\$_FILE_TYPE_LOG_FILE);
    END IF;

    DBMS_DATAPUMP.SET_PARALLEL(handle => h1, degree => 4);
    DBMS_DATAPUMP.START_JOB(h1);
    DBMS_DATAPUMP.DETACH(h1);
END;
/
EXIT;
EOF

# === Get exit status of SQLPlus ===
STATUS=$?

# === Compose Email ===
if [ $STATUS -eq 0 ]; then
    SUBJECT="Export SUCCESS - $TIMESTAMP"
    BODY="Export completed successfully at $(date).\n\nLogs saved at: $LOG_FILE"
else
    SUBJECT="Export FAILED - $TIMESTAMP"
    BODY="Data Pump export failed.\nCheck logs for details: $LOG_FILE"
fi

# === Send Email (uncomment when mailx is configured) ===
# echo -e "$BODY" | mailx -s "$SUBJECT" -a "$LOG_FILE" "$EMAILS"

# === Done ===
echo "=== Export completed with status: $STATUS ==="
