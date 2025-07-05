

**Important Notes:**

  * **Environment Variables:** Before running any script, ensure `ORACLE_HOME` and `ORACLE_SID` are correctly set for your environment. The `BACKUP_BASE` variable should point to your desired backup destination.
  * **Permissions:** The `oracle` user must have read/write permissions to the `BACKUP_BASE` directory.
  * **`DB_RECOVERY_FILE_DEST` (FRA):** For best practice, configure `DB_RECOVERY_FILE_DEST` in your database initialization parameters to point to a Fast Recovery Area, as RMAN often uses it for backups and archive logs if `FORMAT` clause is not specified.
  * **Compression/Encryption:** I've included `COMPRESSED BACKUPSET` as it's a common best practice. For encryption, you'd add `SET ENCRYPTION IDENTIFIED BY "YourPassword"` inside the `RUN` block and configure `ENCRYPTION FOR DATABASE` globally.
  * **Channels:** The `ALLOCATE CHANNEL` commands specify `TYPE DISK`. If you are backing up to tape (SBT\_TAPE), change `TYPE DISK` to `TYPE SBT_TAPE`.
  * **Log Files:** Each script redirects RMAN output to a log file for review.

-----

### 1\. Full Database Backup Script

This script performs a full database backup including archived redo logs, using 8 channels. It also includes `DELETE OBSOLETE` to clean up backups older than your configured retention policy.

```bash
#!/bin/bash
# Script: rman_full_backup.sh
# Description: Performs a full RMAN database backup with 8 channels.

# --- Environment Variables (CONFIGURE THESE) ---
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1 # Adjust to your Oracle Home
export ORACLE_SID=PRODDB                                  # Adjust to your Oracle SID
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman                           # Base directory for RMAN backups

# --- Log File Configuration ---
LOG_DIR="${BACKUP_BASE}/logs"
mkdir -p "${LOG_DIR}" # Ensure log directory exists
LOG_FILE="${LOG_DIR}/rman_full_backup_$(date +%Y%m%d_%H%M%S).log"

echo "Starting RMAN Full Database Backup for ${ORACLE_SID} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_HOME: ${ORACLE_HOME}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_SID: ${ORACLE_SID}" | tee -a "${LOG_FILE}"
echo "Backup destination: ${BACKUP_BASE}" | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
rman target / log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism
  ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch1_%U';
  ALLOCATE CHANNEL ch2 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch2_%U';
  ALLOCATE CHANNEL ch3 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch3_%U';
  ALLOCATE CHANNEL ch4 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch4_%U';
  ALLOCATE CHANNEL ch5 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch5_%U';
  ALLOCATE CHANNEL ch6 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch6_%U';
  ALLOCATE CHANNEL ch7 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch7_%U';
  ALLOCATE CHANNEL ch8 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/full_db_ch8_%U';

  # Perform full database backup with compression, plus archived logs
  BACKUP AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;

  # Delete obsolete backups based on configured retention policy
  DELETE NOPROMPT OBSOLETE;

  # Release channels
  RELEASE CHANNEL ch1;
  RELEASE CHANNEL ch2;
  RELEASE CHANNEL ch3;
  RELEASE CHANNEL ch4;
  RELEASE CHANNEL ch5;
  RELEASE CHANNEL ch6;
  RELEASE CHANNEL ch7;
  RELEASE CHANNEL ch8;
}
EOF

# --- Post-Backup Actions ---
if [ $? -eq 0 ]; then
  echo "RMAN Full Database Backup completed successfully for ${ORACLE_SID} at $(date)" | tee -a "${LOG_FILE}"
else
  echo "RMAN Full Database Backup FAILED for ${ORACLE_SID} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
fi
```

### 2\. Incremental Backup Script (Level 0 and Level 1)

This script can be adapted for Level 0 (baseline) or Level 1 (differential or cumulative) incremental backups. Using 8 channels improves performance for large databases.

```bash
#!/bin/bash
# Script: rman_incremental_backup.sh
# Description: Performs an RMAN incremental backup (Level 0 or Level 1) with 8 channels.

# --- Environment Variables (CONFIGURE THESE) ---
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1 # Adjust to your Oracle Home
export ORACLE_SID=PRODDB                                  # Adjust to your Oracle SID
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman                           # Base directory for RMAN backups

# --- Backup Type Configuration ---
# Set BACKUP_LEVEL to "0" for a Level 0 (Full) Incremental Backup
# Set BACKUP_LEVEL to "1" for a Level 1 (Differential) Incremental Backup
# For CUMULATIVE Level 1, add "CUMULATIVE" after "LEVEL 1" in the RMAN command
BACKUP_LEVEL="1" # Change to "0" for Level 0 backup

# --- Log File Configuration ---
LOG_DIR="${BACKUP_BASE}/logs"
mkdir -p "${LOG_DIR}" # Ensure log directory exists
LOG_FILE="${LOG_DIR}/rman_inc_level${BACKUP_LEVEL}_backup_$(date +%Y%m%d_%H%M%S).log"

echo "Starting RMAN Incremental Level ${BACKUP_LEVEL} Backup for ${ORACLE_SID} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_HOME: ${ORACLE_HOME}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_SID: ${ORACLE_SID}" | tee -a "${LOG_FILE}"
echo "Backup destination: ${BACKUP_BASE}" | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
rman target / log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism
  ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch1_%U';
  ALLOCATE CHANNEL ch2 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch2_%U';
  ALLOCATE CHANNEL ch3 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch3_%U';
  ALLOCATE CHANNEL ch4 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch4_%U';
  ALLOCATE CHANNEL ch5 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch5_%U';
  ALLOCATE CHANNEL ch6 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch6_%U';
  ALLOCATE CHANNEL ch7 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch7_%U';
  ALLOCATE CHANNEL ch8 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/datafile/inc_l${BACKUP_LEVEL}_ch8_%U';

  # Perform incremental backup. Add CUMULATIVE for cumulative incremental backups.
  # Example for Level 0: BACKUP INCREMENTAL LEVEL 0 AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;
  # Example for Level 1 DIFFERENTIAL: BACKUP INCREMENTAL LEVEL 1 AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;
  # Example for Level 1 CUMULATIVE: BACKUP INCREMENTAL LEVEL 1 CUMULATIVE AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;
  BACKUP INCREMENTAL LEVEL ${BACKUP_LEVEL} AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;

  # Delete obsolete backups based on configured retention policy
  DELETE NOPROMPT OBSOLETE;

  # Release channels
  RELEASE CHANNEL ch1;
  RELEASE CHANNEL ch2;
  RELEASE CHANNEL ch3;
  RELEASE CHANNEL ch4;
  RELEASE CHANNEL ch5;
  RELEASE CHANNEL ch6;
  RELEASE CHANNEL ch7;
  RELEASE CHANNEL ch8;
}
EOF

# --- Post-Backup Actions ---
if [ $? -eq 0 ]; then
  echo "RMAN Incremental Level ${BACKUP_LEVEL} Backup completed successfully for ${ORACLE_SID} at $(date)" | tee -a "${LOG_FILE}"
else
  echo "RMAN Incremental Level ${BACKUP_LEVEL} Backup FAILED for ${ORACLE_SID} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
fi
```

### 3\. Archive Log Backup Script

This script backs up all current archived redo logs and then deletes the input files after successful backup, using 8 channels.

```bash
#!/bin/bash
# Script: rman_archivelog_backup.sh
# Description: Backs up all archived redo logs with 8 channels and deletes input after successful backup.

# --- Environment Variables (CONFIGURE THESE) ---
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1 # Adjust to your Oracle Home
export ORACLE_SID=PRODDB                                  # Adjust to your Oracle SID
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman                           # Base directory for RMAN backups

# --- Log File Configuration ---
LOG_DIR="${BACKUP_BASE}/logs"
mkdir -p "${LOG_DIR}" # Ensure log directory exists
LOG_FILE="${LOG_DIR}/rman_archlog_backup_$(date +%Y%m%d_%H%M%S).log"

echo "Starting RMAN Archive Log Backup for ${ORACLE_SID} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_HOME: ${ORACLE_HOME}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_SID: ${ORACLE_SID}" | tee -a "${LOG_FILE}"
echo "Backup destination: ${BACKUP_BASE}" | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
rman target / log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism
  ALLOCATE CHANNEL ch1 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch1_%U';
  ALLOCATE CHANNEL ch2 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch2_%U';
  ALLOCATE CHANNEL ch3 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch3_%U';
  ALLOCATE CHANNEL ch4 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch4_%U';
  ALLOCATE CHANNEL ch5 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch5_%U';
  ALLOCATE CHANNEL ch6 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch6_%U';
  ALLOCATE CHANNEL ch7 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch7_%U';
  ALLOCATE CHANNEL ch8 DEVICE TYPE DISK FORMAT '${BACKUP_BASE}/archivelog/arl_ch8_%U';

  # Backup all archived redo logs and delete input files after successful backup
  BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL DELETE INPUT;

  # Crosscheck and delete expired archive logs from repository
  CROSSCHECK ARCHIVELOG ALL;
  DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;

  # Release channels
  RELEASE CHANNEL ch1;
  RELEASE CHANNEL ch2;
  RELEASE CHANNEL ch3;
  RELEASE CHANNEL ch4;
  RELEASE CHANNEL ch5;
  RELEASE CHANNEL ch6;
  RELEASE CHANNEL ch7;
  RELEASE CHANNEL ch8;
}
EOF

# --- Post-Backup Actions ---
if [ $? -eq 0 ]; then
  echo "RMAN Archive Log Backup completed successfully for ${ORACLE_SID} at $(date)" | tee -a "${LOG_FILE}"
else
  echo "RMAN Archive Log Backup FAILED for ${ORACLE_SID} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
fi
```

### 4\. Database Restore and Point-in-Time Recovery (PITR) Script

This script demonstrates a point-in-time recovery. **Use this script with extreme caution and only in a test environment or during actual disaster recovery.** The database must be in `NOMOUNT` or `MOUNT` state.

```bash
#!/bin/bash
# Script: rman_pitr_recovery.sh
# Description: Performs a Point-in-Time Recovery (PITR) of the database.
#              !!! USE WITH EXTREME CAUTION AND ONLY IN TEST/DR SCENARIOS !!!

# --- Environment Variables (CONFIGURE THESE) ---
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1 # Adjust to your Oracle Home
export ORACLE_SID=PRODDB                                  # Adjust to your Oracle SID
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman                           # Base directory for RMAN backups

# --- Recovery Target (CONFIGURE THIS) ---
# Specify the target time for recovery. Format: 'YYYY-MM-DD HH24:MI:SS'
RECOVERY_TARGET_TIME="2025-07-04 10:00:00"

# --- Log File Configuration ---
LOG_DIR="${BACKUP_BASE}/logs"
mkdir -p "${LOG_DIR}" # Ensure log directory exists
LOG_FILE="${LOG_DIR}/rman_pitr_recovery_$(date +%Y%m%d_%H%M%S).log"

echo "Starting RMAN PITR for ${ORACLE_SID} to ${RECOVERY_TARGET_TIME} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_HOME: ${ORACLE_HOME}" | tee -a "${LOG_FILE}"
echo "Using ORACLE_SID: ${ORACLE_SID}" | tee -a "${LOG_FILE}"
echo "Backup location to restore from: ${BACKUP_BASE}" | tee -a "${LOG_FILE}"

# --- Database State Check and Preparation ---
echo "Checking database status..." | tee -a "${LOG_FILE}"
sqlplus -S / as sysdba << EOF_SQL
  SELECT instance_name, status, database_status FROM v\$instance;
  SHUTDOWN ABORT;
  STARTUP NOMOUNT;
EOF_SQL

if [ $? -ne 0 ]; then
  echo "Failed to shutdown or startup database in NOMOUNT. Exiting." | tee -a "${LOG_FILE}"
  exit 1
fi
echo "Database is in NOMOUNT state." | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
rman target / log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism during restore
  ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch2 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch3 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch4 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch5 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch6 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch7 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch8 DEVICE TYPE DISK;

  # Set the recovery target time
  SET UNTIL TIME "TO_DATE('${RECOVERY_TARGET_TIME}', 'YYYY-MM-DD HH24:MI:SS')";

  # Restore control file from autobackup (if control file is lost or inconsistent)
  # RMAN will search standard locations or the FRA.
  RESTORE CONTROLFILE FROM AUTOBACKUP;

  # Mount the database after control file restore
  ALTER DATABASE MOUNT;

  # Restore database datafiles
  RESTORE DATABASE;

  # Recover database to the specified point in time
  RECOVER DATABASE;

  # Release channels
  RELEASE CHANNEL ch1;
  RELEASE CHANNEL ch2;
  RELEASE CHANNEL ch3;
  RELEASE CHANNEL ch4;
  RELEASE CHANNEL ch5;
  RELEASE CHANNEL ch6;
  RELEASE CHANNEL ch7;
  RELEASE CHANNEL ch8;
}
EOF

# --- Open Database with RESETLOGS ---
if [ $? -eq 0 ]; then
  echo "RMAN restore and recovery successful. Opening database with RESETLOGS..." | tee -a "${LOG_FILE}"
  sqlplus -S / as sysdba << EOF_SQL
    ALTER DATABASE OPEN RESETLOGS;
    SELECT name, open_mode, resetlogs_time FROM v\$database;
EOF_SQL
  if [ $? -eq 0 ]; then
    echo "Database opened successfully with RESETLOGS at $(date)." | tee -a "${LOG_FILE}"
  else
    echo "Failed to open database with RESETLOGS. Manual intervention required." | tee -a "${LOG_FILE}"
    exit 1
  fi
else
  echo "RMAN Restore/Recovery FAILED for ${ORACLE_SID} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
  exit 1
fi

echo "PITR process completed." | tee -a "${LOG_FILE}"
```

### 5\. Tablespace/Datafile Restore and Recovery Script

This script allows you to restore and recover a specific tablespace or datafile. The tablespace/datafile must be taken offline before recovery.

```bash
#!/bin/bash
# Script: rman_ts_df_recovery.sh
# Description: Restores and recovers a specific tablespace or datafile.
#              !!! ENSURE TABLESPACE/DATAFILE IS OFFLINE FIRST !!!

# --- Environment Variables (CONFIGURE THESE) ---
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1 # Adjust to your Oracle Home
export ORACLE_SID=PRODDB                                  # Adjust to your Oracle SID
export PATH=$ORACLE_HOME/bin:$PATH
export BACKUP_BASE=/backup/rman                           # Base directory for RMAN backups

# --- Recovery Target (CONFIGURE ONE OF THESE) ---
# To recover a tablespace:
RECOVERY_TYPE="TABLESPACE"
TARGET_NAME="USERS" # Replace with your tablespace name

# OR to recover a datafile by path:
# RECOVERY_TYPE="DATAFILE_PATH"
# TARGET_NAME="/u01/app/oracle/oradata/PRODDB/users01.dbf" # Replace with your datafile path

# OR to recover a datafile by file number:
# RECOVERY_TYPE="DATAFILE_NUMBER"
# TARGET_NAME="3" # Replace with your datafile number

# --- Log File Configuration ---
LOG_DIR="${BACKUP_BASE}/logs"
mkdir -p "${LOG_DIR}" # Ensure log directory exists
LOG_FILE="${LOG_DIR}/rman_ts_df_recovery_$(echo "${TARGET_NAME}" | tr '/' '_' | tr '.' '_')_$(date +%Y%m%d_%H%M%S).log"

echo "Starting RMAN ${RECOVERY_TYPE} recovery for ${TARGET_NAME} on ${ORACLE_SID} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"

# --- Database State Check and Preparation (Ensure target is OFFLINE) ---
echo "Checking database status and attempting to take ${TARGET_NAME} offline if needed..." | tee -a "${LOG_FILE}"
if [ "${RECOVERY_TYPE}" == "TABLESPACE" ]; then
  sqlplus -S / as sysdba << EOF_SQL
    ALTER TABLESPACE ${TARGET_NAME} OFFLINE IMMEDIATE;
    SELECT tablespace_name, status FROM dba_tablespaces WHERE tablespace_name = UPPER('${TARGET_NAME}');
EOF_SQL
elif [ "${RECOVERY_TYPE}" == "DATAFILE_PATH" ]; then
  sqlplus -S / as sysdba << EOF_SQL
    ALTER DATABASE DATAFILE '${TARGET_NAME}' OFFLINE;
    SELECT file_name, status FROM dba_data_files WHERE file_name = '${TARGET_NAME}';
EOF_SQL
elif [ "${RECOVERY_TYPE}" == "DATAFILE_NUMBER" ]; then
  sqlplus -S / as sysdba << EOF_SQL
    ALTER DATABASE DATAFILE ${TARGET_NAME} OFFLINE;
    SELECT file_id, file_name, status FROM dba_data_files WHERE file_id = ${TARGET_NAME};
EOF_SQL
fi

if [ $? -ne 0 ]; then
  echo "Failed to take ${TARGET_NAME} offline or verify its status. Exiting." | tee -a "${LOG_FILE}"
  exit 1
fi
echo "${TARGET_NAME} is offline or verified." | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
rman target / log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism during restore
  ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch2 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch3 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch4 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch5 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch6 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch7 DEVICE TYPE DISK;
  ALLOCATE CHANNEL ch8 DEVICE TYPE DISK;

  # Restore and Recover based on type
  VAR_TARGET_NAME='${TARGET_NAME}'; # Use variable for RMAN string parsing

  IF '${RECOVERY_TYPE}' = 'TABLESPACE' THEN
    RESTORE TABLESPACE &VAR_TARGET_NAME;
    RECOVER TABLESPACE &VAR_TARGET_NAME;
  ELSIF '${RECOVERY_TYPE}' = 'DATAFILE_PATH' THEN
    RESTORE DATAFILE '&VAR_TARGET_NAME';
    RECOVER DATAFILE '&VAR_TARGET_NAME';
  ELSIF '${RECOVERY_TYPE}' = 'DATAFILE_NUMBER' THEN
    RESTORE DATAFILE &VAR_TARGET_NAME;
    RECOVER DATAFILE &VAR_TARGET_NAME;
  END IF;

  # Release channels
  RELEASE CHANNEL ch1;
  RELEASE CHANNEL ch2;
  RELEASE CHANNEL ch3;
  RELEASE CHANNEL ch4;
  RELEASE CHANNEL ch5;
  RELEASE CHANNEL ch6;
  RELEASE CHANNEL ch7;
  RELEASE CHANNEL ch8;
}
EOF

# --- Bring Tablespace/Datafile Online ---
if [ $? -eq 0 ]; then
  echo "RMAN restore and recovery successful for ${TARGET_NAME}. Bringing it online..." | tee -a "${LOG_FILE}"
  if [ "${RECOVERY_TYPE}" == "TABLESPACE" ]; then
    sqlplus -S / as sysdba << EOF_SQL
      ALTER TABLESPACE ${TARGET_NAME} ONLINE;
      SELECT tablespace_name, status FROM dba_tablespaces WHERE tablespace_name = UPPER('${TARGET_NAME}');
EOF_SQL
  elif [ "${RECOVERY_TYPE}" == "DATAFILE_PATH" ]; then
    sqlplus -S / as sysdba << EOF_SQL
      ALTER DATABASE DATAFILE '${TARGET_NAME}' ONLINE;
      SELECT file_name, status FROM dba_data_files WHERE file_name = '${TARGET_NAME}';
EOF_SQL
  elif [ "${RECOVERY_TYPE}" == "DATAFILE_NUMBER" ]; then
    sqlplus -S / as sysdba << EOF_SQL
      ALTER DATABASE DATAFILE ${TARGET_NAME} ONLINE;
      SELECT file_id, file_name, status FROM dba_data_files WHERE file_id = ${TARGET_NAME};
EOF_SQL
  fi

  if [ $? -eq 0 ]; then
    echo "${TARGET_NAME} brought online successfully at $(date)." | tee -a "${LOG_FILE}"
  else
    echo "Failed to bring ${TARGET_NAME} online. Manual intervention required." | tee -a "${LOG_FILE}"
    exit 1
  fi
else
  echo "RMAN Restore/Recovery FAILED for ${TARGET_NAME} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
  exit 1
fi

echo "Recovery process completed for ${TARGET_NAME}." | tee -a "${LOG_FILE}"
```
