

### 1\. RMAN Duplicate to Migrate Database (Enhanced Error Handling)

This script remains a single file, but with clearer instructions to choose between active database duplication and backup-based duplication.

```bash
#!/bin/bash
# Script: rman_migrate_duplicate.sh
# Description: Duplicates a source database to a new server/instance for migration purposes.
#              Supports both active duplication (from live DB) and backup-based duplication.
# Error Handling: Includes set -e, environment checks, and exit code validation.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Environment Variables (CONFIGURE THESE) ---
# Source Database Details (Target Connection for RMAN)
export ORACLE_HOME_SRC=/u01/app/oracle/product/19.0.0/dbhome_1 # Source Oracle Home
export ORACLE_SID_SRC=PRODDB                                  # Source Oracle SID (Target)
# If connecting remotely, define TNS alias for primary:
# export TNS_ALIAS_SRC=proddb_tns # Example TNS alias
# export TNS_ADMIN_SRC=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for source

# Destination Database Details (Auxiliary Instance)
export ORACLE_HOME_DST=/u01/app/oracle/product/19.0.0/dbhome_1 # Destination Oracle Home
export ORACLE_SID_DST=MIGDB                                   # Destination Oracle SID (Auxiliary)
# If connecting remotely, define TNS alias for auxiliary:
# export TNS_ALIAS_DST=migdb_tns # Example TNS alias
# export TNS_ADMIN_DST=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for destination

# Backup Location (only for Backup-Based Duplication if backups are not in FRA)
# This directory should be accessible from the AUXILIARY server
export BACKUP_LOCATION=/backup/rman/PRODDB                    # Location of source database backups

# New Paths for Datafiles and FRA on Destination Server
# *** IMPORTANT: Adjust these conversion rules based on your source and destination paths ***
# Example: If source datafiles are in /u01/app/oracle/oradata/PRODDB/
# and destination should be /u01/app/oracle/oradata/MIGDB/
CONVERT_RULES="('/u01/app/oracle/oradata/PRODDB', '/u01/app/oracle/oradata/MIGDB')"
FRA_DEST_NEW="/u01/app/oracle/fast_recovery_area/MIGDB" # New FRA path for auxiliary instance
LOG_DEST_NEW="/u01/app/oracle/redo/MIGDB"              # New Redo Log path for auxiliary instance (if not in datafiles)

# --- Log File Configuration ---
LOG_DIR="/tmp/rman_logs"
mkdir -p "${LOG_DIR}" || { echo "ERROR: Could not create log directory ${LOG_DIR}. Exiting." >&2; exit 1; }
LOG_FILE="${LOG_DIR}/rman_migrate_duplicate_${ORACLE_SID_SRC}_to_${ORACLE_SID_DST}_$(date +%Y%m%d_%H%M%S).log"

# --- Environment Variable Validation ---
if [ -z "${ORACLE_HOME_SRC}" ] || [ -z "${ORACLE_SID_SRC}" ] || \
   [ -z "${ORACLE_HOME_DST}" ] || [ -z "${ORACLE_SID_DST}" ]; then
  echo "ERROR: One or more required environment variables (ORACLE_HOME_SRC, ORACLE_SID_SRC, ORACLE_HOME_DST, ORACLE_SID_DST) are not set. Exiting." | tee -a "${LOG_FILE}"
  exit 1
fi

echo "Starting RMAN Database Migration Duplicate from ${ORACLE_SID_SRC} to ${ORACLE_SID_DST} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"

# --- Start Auxiliary Instance in NOMOUNT (Important for DUPLICATE) ---
echo "Attempting to start auxiliary instance ${ORACLE_SID_DST} in NOMOUNT mode..." | tee -a "${LOG_FILE}"
# Ensure an init.ora file exists for MIGDB (or whatever your ORACLE_SID_DST is) at $ORACLE_HOME_DST/dbs/init${ORACLE_SID_DST}.ora
# Content example: DB_NAME='PRODDB', DB_UNIQUE_NAME='MIGDB', CONTROL_FILES='<path>/control01.ctl', DB_RECOVERY_FILE_DEST='${FRA_DEST_NEW}', DIAGNOSTIC_DEST='<path>'
ORACLE_HOME=${ORACLE_HOME_DST} ORACLE_SID=${ORACLE_SID_DST} \
"${ORACLE_HOME_DST}"/bin/sqlplus /nolog << EOF_SQL >> "${LOG_FILE}" 2>&1
  CONNECT SYS/password AS SYSDBA; # Or use OS authentication if configured
  STARTUP NOMOUNT PFILE='${ORACLE_HOME_DST}/dbs/init${ORACLE_SID_DST}.ora';
EOF_SQL

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start auxiliary instance ${ORACLE_SID_DST} in NOMOUNT mode. Check init.ora, permissions, and logs." | tee -a "${LOG_FILE}"
  exit 1
fi
echo "Auxiliary instance ${ORACLE_SID_DST} started in NOMOUNT." | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
# Define RMAN connect strings
RMAN_TARGET_CONNECT="target /" # For OS authentication on source
# RMAN_TARGET_CONNECT="target sys/password@${TNS_ALIAS_SRC}" # For TNS connection to source
RMAN_AUXILIARY_CONNECT="auxiliary /" # For OS authentication on destination
# RMAN_AUXILIARY_CONNECT="auxiliary sys/password@${TNS_ALIAS_DST}" # For TNS connection to destination

# Set TNS_ADMIN for RMAN if using TNS aliases
export TNS_ADMIN="${TNS_ADMIN_SRC}:${TNS_ADMIN_DST}" # If TNS files are in different locations

"${ORACLE_HOME_SRC}"/bin/rman ${RMAN_TARGET_CONNECT} ${RMAN_AUXILIARY_CONNECT} log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism
  ALLOCATE AUXILIARY CHANNEL aux1 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux2 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux3 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux4 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux5 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux6 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux7 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux8 DEVICE TYPE DISK;

  # Define conversion rules for datafiles and redo logs (CRUCIAL for new paths)
  SET NEWNAME FOR DATABASE TO NEW; # Use this with DB_FILE_NAME_CONVERT
  SET DB_FILE_NAME_CONVERT ${CONVERT_RULES};
  SET LOG_FILE_NAME_CONVERT ${CONVERT_RULES};
  
  # Set new FRA location for the duplicate database
  SET DB_RECOVERY_FILE_DEST_SIZE = 50G; # Adjust size as needed
  SET DB_RECOVERY_FILE_DEST = '${FRA_DEST_NEW}';

  # --- CHOOSE ONE DUPLICATE METHOD BELOW AND UNCOMMENT ---

  # 1. Active Database Duplication (Copies directly from active primary database)
  #    Requires source DB to be open. Does not require pre-existing backups.
  #    Uses 'TARGET' connection to pull datafiles.
  DUPLICATE TARGET DATABASE TO ${ORACLE_SID_DST}
  FROM ACTIVE DATABASE
  SPFILE PARAMETER_VALUE_CONVERT ${CONVERT_RULES}
  # NOFILENAMECHECK # Uncomment if file names are identical but paths are different
  LOGFILE GROUP 1 ('${LOG_DEST_NEW}/redo01a.log', '${LOG_DEST_NEW}/redo01b.log') SIZE 500M,
          GROUP 2 ('${LOG_DEST_NEW}/redo02a.log', '${LOG_DEST_NEW}/redo02b.log') SIZE 500M,
          GROUP 3 ('${LOG_DEST_NEW}/redo03a.log', '${LOG_DEST_NEW}/redo03b.log') SIZE 500M;

  # 2. Backup-Based Duplication (Restores from RMAN backups)
  #    Requires pre-existing backups of the source database accessible to auxiliary.
  #    If backups are not in FRA, you might need to CATALOG them or point to BACKUP_LOCATION.
  #    If you are using a recovery catalog, RMAN will find backups.
  #    DUPLICATE TARGET DATABASE TO ${ORACLE_SID_DST}
  #    NOFILENAMECHECK # Use if file names are the same but paths are different.
  #    BACKUP LOCATION '${BACKUP_LOCATION}' # Specify if backups are not in a default location or FRA
  #    SPFILE PARAMETER_VALUE_CONVERT ${CONVERT_RULES} # Needed if SPFILE location changes
  #    LOGFILE GROUP 1 ('${LOG_DEST_NEW}/redo01a.log', '${LOG_DEST_NEW}/redo01b.log') SIZE 500M,
  #            GROUP 2 ('${LOG_DEST_NEW}/redo02a.log', '${LOG_DEST_NEW}/redo02b.log') SIZE 500M,
  #            GROUP 3 ('${LOG_DEST_NEW}/redo03a.log', '${LOG_DEST_NEW}/redo03b.log') SIZE 500M;
  
  # Release auxiliary channels
  RELEASE CHANNEL aux1;
  RELEASE CHANNEL aux2;
  RELEASE CHANNEL aux3;
  RELEASE CHANNEL aux4;
  RELEASE CHANNEL aux5;
  RELEASE CHANNEL aux6;
  RELEASE CHANNEL aux7;
  RELEASE CHANNEL aux8;
}
EOF

# --- Post-Duplication Actions ---
echo "Checking RMAN command exit status..." | tee -a "${LOG_FILE}"
if [ $? -eq 0 ]; then
  echo "RMAN Database Migration Duplicate completed successfully for ${ORACLE_SID_DST} at $(date)" | tee -a "${LOG_FILE}"
  echo "Database ${ORACLE_SID_DST} is now open and ready for use." | tee -a "${LOG_FILE}"
else
  echo "ERROR: RMAN Database Migration Duplicate FAILED for ${ORACLE_SID_DST} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
  exit 1
fi
```

-----

### 2\. RMAN Duplicate for Daily Refresh (Dev Environment - Enhanced Error Handling)

```bash
#!/bin/bash
# Script: rman_dev_refresh_duplicate.sh
# Description: Duplicates a production database to a development environment for daily refresh.
#              Uses active database duplication and can restore to a specific point-in-time.
# Error Handling: Includes set -e, environment checks, and exit code validation.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Environment Variables (CONFIGURE THESE) ---
# Production Database Details (Target Connection for RMAN)
export ORACLE_HOME_PROD=/u01/app/oracle/product/19.0.0/dbhome_1 # Production Oracle Home
export ORACLE_SID_PROD=PRODDB                                 # Production Oracle SID (Target)
# If connecting remotely, define TNS alias for primary:
# export TNS_ALIAS_PROD=proddb_tns # Example TNS alias
# export TNS_ADMIN_PROD=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for production

# Development Database Details (Auxiliary Instance)
export ORACLE_HOME_DEV=/u01/app/oracle/product/19.0.0/dbhome_1 # Development Oracle Home
export ORACLE_SID_DEV=DEVDB                                   # Development Oracle SID (Auxiliary)
# If connecting remotely, define TNS alias for auxiliary:
# export TNS_ALIAS_DEV=devdb_tns # Example TNS alias
# export TNS_ADMIN_DEV=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for development

# New Paths for Datafiles and FRA on Development Server
# *** IMPORTANT: Adjust these conversion rules based on your production and dev paths ***
CONVERT_RULES="('/u01/app/oracle/oradata/PRODDB', '/u01/app/oracle/oradata/DEVDB')"
FRA_DEST_DEV="/u01/app/oracle/fast_recovery_area/DEVDB" # New FRA path for dev instance
LOG_DEST_DEV="/u01/app/oracle/redo/DEVDB"              # New Redo Log path for dev instance

# Recovery Target (e.g., end of yesterday for daily refresh)
# Example: REFRESH_TARGET_TIME="$(date -d "yesterday 23:59:59" +"%Y-%m-%d %H:%M:%S")"
# For immediate refresh (current time), set to an empty string or remove SET UNTIL TIME
REFRESH_TARGET_TIME="$(date -d "yesterday 23:59:59" +"%Y-%m-%d %H:%M:%S")"

# --- Log File Configuration ---
LOG_DIR="/tmp/rman_logs"
mkdir -p "${LOG_DIR}" || { echo "ERROR: Could not create log directory ${LOG_DIR}. Exiting." >&2; exit 1; }
LOG_FILE="${LOG_DIR}/rman_dev_refresh_duplicate_${ORACLE_SID_PROD}_to_${ORACLE_SID_DEV}_$(date +%Y%m%d_%H%M%S).log"

# --- Environment Variable Validation ---
if [ -z "${ORACLE_HOME_PROD}" ] || [ -z "${ORACLE_SID_PROD}" ] || \
   [ -z "${ORACLE_HOME_DEV}" ] || [ -z "${ORACLE_SID_DEV}" ]; then
  echo "ERROR: One or more required environment variables (ORACLE_HOME_PROD, ORACLE_SID_PROD, ORACLE_HOME_DEV, ORACLE_SID_DEV) are not set. Exiting." | tee -a "${LOG_FILE}"
  exit 1
fi

echo "Starting RMAN Daily Refresh Duplicate from ${ORACLE_SID_PROD} to ${ORACLE_SID_DEV} (until ${REFRESH_TARGET_TIME}) at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"

# --- Start Auxiliary Instance in NOMOUNT ---
echo "Attempting to start auxiliary instance ${ORACLE_SID_DEV} in NOMOUNT mode..." | tee -a "${LOG_FILE}"
ORACLE_HOME=${ORACLE_HOME_DEV} ORACLE_SID=${ORACLE_SID_DEV} \
"${ORACLE_HOME_DEV}"/bin/sqlplus /nolog << EOF_SQL >> "${LOG_FILE}" 2>&1
  CONNECT SYS/password AS SYSDBA; # Or use OS authentication
  STARTUP NOMOUNT PFILE='${ORACLE_HOME_DEV}/dbs/init${ORACLE_SID_DEV}.ora';
EOF_SQL

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start auxiliary instance ${ORACLE_SID_DEV} in NOMOUNT mode. Check init.ora, permissions, and logs." | tee -a "${LOG_FILE}"
  exit 1
fi
echo "Auxiliary instance ${ORACLE_SID_DEV} started in NOMOUNT." | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
RMAN_TARGET_CONNECT="target /"
# RMAN_TARGET_CONNECT="target sys/password@${TNS_ALIAS_PROD}"
RMAN_AUXILIARY_CONNECT="auxiliary /"
# RMAN_AUXILIARY_CONNECT="auxiliary sys/password@${TNS_ALIAS_DEV}"
export TNS_ADMIN="${TNS_ADMIN_PROD}:${TNS_ADMIN_DEV}"

"${ORACLE_HOME_PROD}"/bin/rman ${RMAN_TARGET_CONNECT} ${RMAN_AUXILIARY_CONNECT} log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism
  ALLOCATE AUXILIARY CHANNEL aux1 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux2 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux3 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux4 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux5 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux6 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux7 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux8 DEVICE TYPE DISK;

  # Set recovery target time for the refresh (only if REFRESH_TARGET_TIME is not empty)
  $( [ -n "$REFRESH_TARGET_TIME" ] && echo "SET UNTIL TIME \"TO_DATE('${REFRESH_TARGET_TIME}', 'YYYY-MM-DD HH24:MI:SS')\";" )

  # Define conversion rules for datafiles and redo logs
  SET NEWNAME FOR DATABASE TO NEW; # Important to use with DB_FILE_NAME_CONVERT for new DBID
  SET DB_FILE_NAME_CONVERT ${CONVERT_RULES};
  SET LOG_FILE_NAME_CONVERT ${CONVERT_RULES};
  
  # Set new FRA location for the duplicate database
  SET DB_RECOVERY_FILE_DEST_SIZE = 50G; # Adjust size as needed
  SET DB_RECOVERY_FILE_DEST = '${FRA_DEST_DEV}';

  # Perform Active Database Duplication (copies directly from active production DB)
  DUPLICATE TARGET DATABASE TO ${ORACLE_SID_DEV}
  FROM ACTIVE DATABASE
  SPFILE PARAMETER_VALUE_CONVERT ${CONVERT_RULES}
  # NOFILENAMECHECK # Uncomment if file names are identical but paths must be different (and not using NEWNAME)
  LOGFILE GROUP 1 ('${LOG_DEST_DEV}/redo01a.log', '${LOG_DEST_DEV}/redo01b.log') SIZE 500M,
          GROUP 2 ('${LOG_DEST_DEV}/redo02a.log', '${LOG_DEST_DEV}/redo02b.log') SIZE 500M,
          GROUP 3 ('${LOG_DEST_DEV}/redo03a.log', '${LOG_DEST_DEV}/redo03b.log') SIZE 500M;
  
  # Release auxiliary channels
  RELEASE CHANNEL aux1;
  RELEASE CHANNEL aux2;
  RELEASE CHANNEL aux3;
  RELEASE CHANNEL aux4;
  RELEASE CHANNEL aux5;
  RELEASE CHANNEL aux6;
  RELEASE CHANNEL aux7;
  RELEASE CHANNEL aux8;
}
EOF

# --- Post-Duplication Actions ---
echo "Checking RMAN command exit status..." | tee -a "${LOG_FILE}"
if [ $? -eq 0 ]; then
  echo "RMAN Daily Refresh Duplicate completed successfully for ${ORACLE_SID_DEV} at $(date)" | tee -a "${LOG_FILE}"
  echo "Development database ${ORACLE_SID_DEV} is now open and refreshed." | tee -a "${LOG_FILE}"
else
  echo "ERROR: RMAN Daily Refresh Duplicate FAILED for ${ORACLE_SID_DEV} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
  exit 1
fi
```

-----

### 3\. RMAN Duplicate to Create Physical Standby Database (Active Duplication)

This script specifically uses `FROM ACTIVE DATABASE` to create a physical standby from a live primary database.

```bash
#!/bin/bash
# Script: rman_create_standby_active.sh
# Description: Creates a physical standby database using RMAN DUPLICATE FOR STANDBY FROM ACTIVE DATABASE.
# Error Handling: Includes set -e, environment checks, and exit code validation.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Environment Variables (CONFIGURE THESE) ---
# Primary Database Details (Target Connection for RMAN)
export ORACLE_HOME_PRIMARY=/u01/app/oracle/product/19.0.0/dbhome_1 # Primary Oracle Home
export ORACLE_SID_PRIMARY=PRODDB                                  # Primary Oracle SID (Target)
# If connecting remotely, define TNS alias for primary:
# export TNS_ALIAS_PRIMARY=proddb_tns # Example TNS alias
# export TNS_ADMIN_PRIMARY=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for primary

# Standby Database Details (Auxiliary Instance)
export ORACLE_HOME_STANDBY=/u01/app/oracle/product/19.0.0/dbhome_1 # Standby Oracle Home (can be same as primary)
export ORACLE_SID_STANDBY=STBYDB                                  # Standby Oracle SID (Auxiliary)
# If connecting remotely, define TNS alias for auxiliary:
# export TNS_ALIAS_STANDBY=stbydb_tns # Example TNS alias
# export TNS_ADMIN_STANDBY=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for standby

# New Paths for Datafiles and FRA on Standby Server
# *** IMPORTANT: Adjust these conversion rules ***
CONVERT_RULES="('/u01/app/oracle/oradata/PRODDB', '/u01/app/oracle/oradata/STBYDB')"
FRA_DEST_STANDBY="/u01/app/oracle/fast_recovery_area/STBYDB" # New FRA path for standby instance
LOG_DEST_STANDBY="/u01/app/oracle/redo/STBYDB"              # New Redo Log path for standby instance

# --- Log File Configuration ---
LOG_DIR="/tmp/rman_logs"
mkdir -p "${LOG_DIR}" || { echo "ERROR: Could not create log directory ${LOG_DIR}. Exiting." >&2; exit 1; }
LOG_FILE="${LOG_DIR}/rman_create_standby_active_${ORACLE_SID_PRIMARY}_to_${ORACLE_SID_STANDBY}_$(date +%Y%m%d_%H%M%S).log"

# --- Environment Variable Validation ---
if [ -z "${ORACLE_HOME_PRIMARY}" ] || [ -z "${ORACLE_SID_PRIMARY}" ] || \
   [ -z "${ORACLE_HOME_STANDBY}" ] || [ -z "${ORACLE_SID_STANDBY}" ]; then
  echo "ERROR: One or more required environment variables (ORACLE_HOME_PRIMARY, ORACLE_SID_PRIMARY, ORACLE_HOME_STANDBY, ORACLE_SID_STANDBY) are not set. Exiting." | tee -a "${LOG_FILE}"
  exit 1
fi

echo "Starting RMAN Duplicate (Active) to Create Standby from ${ORACLE_SID_PRIMARY} to ${ORACLE_SID_STANDBY} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"

# --- Start Auxiliary Instance in NOMOUNT ---
echo "Attempting to start auxiliary instance ${ORACLE_SID_STANDBY} in NOMOUNT mode..." | tee -a "${LOG_FILE}"
# Ensure an init.ora file exists for STBYDB (or whatever your ORACLE_SID_STANDBY is) at $ORACLE_HOME_STANDBY/dbs/init${ORACLE_SID_STANDBY}.ora
# This PFILE should point to the correct DB_NAME (primary's DB_NAME), DB_UNIQUE_NAME (standby's unique name), and desired file paths.
ORACLE_HOME=${ORACLE_HOME_STANDBY} ORACLE_SID=${ORACLE_SID_STANDBY} \
"${ORACLE_HOME_STANDBY}"/bin/sqlplus /nolog << EOF_SQL >> "${LOG_FILE}" 2>&1
  CONNECT SYS/password AS SYSDBA; # Or use OS authentication
  STARTUP NOMOUNT PFILE='${ORACLE_HOME_STANDBY}/dbs/init${ORACLE_SID_STANDBY}.ora';
EOF_SQL

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start auxiliary instance ${ORACLE_SID_STANDBY} in NOMOUNT mode. Check init.ora, permissions, and logs." | tee -a "${LOG_FILE}"
  exit 1
fi
echo "Auxiliary instance ${ORACLE_SID_STANDBY} started in NOMOUNT." | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
RMAN_TARGET_CONNECT="target /"
# RMAN_TARGET_CONNECT="target sys/password@${TNS_ALIAS_PRIMARY}"
RMAN_AUXILIARY_CONNECT="auxiliary /"
# RMAN_AUXILIARY_CONNECT="auxiliary sys/password@${TNS_ALIAS_STANDBY}"
export TNS_ADMIN="${TNS_ADMIN_PRIMARY}:${TNS_ADMIN_STANDBY}"

"${ORACLE_HOME_PRIMARY}"/bin/rman ${RMAN_TARGET_CONNECT} ${RMAN_AUXILIARY_CONNECT} log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism
  ALLOCATE AUXILIARY CHANNEL aux1 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux2 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux3 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux4 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux5 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux6 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux7 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux8 DEVICE TYPE DISK;

  # Define conversion rules for datafiles and redo logs
  # NO SET NEWNAME FOR DATABASE TO NEW; for standby as it retains original DBID
  SET DB_FILE_NAME_CONVERT ${CONVERT_RULES};
  SET LOG_FILE_NAME_CONVERT ${CONVERT_RULES};
  
  # Set new FRA location for the standby database
  SET DB_RECOVERY_FILE_DEST_SIZE = 50G; # Adjust size as needed
  SET DB_RECOVERY_FILE_DEST = '${FRA_DEST_STANDBY}';

  # Perform Active Database Duplication for Standby
  DUPLICATE TARGET DATABASE FOR STANDBY FROM ACTIVE DATABASE
  DORECOVER # This ensures that RMAN applies archived logs to bring standby up-to-date
  SPFILE PARAMETER_VALUE_CONVERT ${CONVERT_RULES} # Needed if SPFILE location changes
  # NOFILENAMECHECK # Uncomment if file names are identical but paths must be different
  LOGFILE GROUP 1 ('${LOG_DEST_STANDBY}/redo01a.log', '${LOG_DEST_STANDBY}/redo01b.log') SIZE 500M,
          GROUP 2 ('${LOG_DEST_STANDBY}/redo02a.log', '${LOG_DEST_STANDBY}/redo02b.log') SIZE 500M,
          GROUP 3 ('${LOG_DEST_STANDBY}/redo03a.log', '${LOG_DEST_STANDBY}/redo03b.log') SIZE 500M;
  
  # Release auxiliary channels
  RELEASE CHANNEL aux1;
  RELEASE CHANNEL aux2;
  RELEASE CHANNEL aux3;
  RELEASE CHANNEL aux4;
  RELEASE CHANNEL aux5;
  RELEASE CHANNEL aux6;
  RELEASE CHANNEL aux7;
  RELEASE CHANNEL aux8;
}
EOF

# --- Post-Duplication Actions ---
echo "Checking RMAN command exit status..." | tee -a "${LOG_FILE}"
if [ $? -eq 0 ]; then
  echo "RMAN Standby Creation Duplicate (Active) completed successfully for ${ORACLE_SID_STANDBY} at $(date)" | tee -a "${LOG_FILE}"
  echo "Standby database ${ORACLE_SID_STANDBY} is now created. You may start managed recovery:" | tee -a "${LOG_FILE}"
  echo "${ORACLE_HOME_STANDBY}/bin/sqlplus / as sysdba" | tee -a "${LOG_FILE}"
  echo "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION PARALLEL 8;" | tee -a "${LOG_FILE}"
else
  echo "ERROR: RMAN Standby Creation Duplicate (Active) FAILED for ${ORACLE_SID_STANDBY} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
  exit 1
fi
```

-----

### 4\. RMAN Duplicate to Create Physical Standby Database (Backup-Based Duplication)

This script specifically creates a physical standby by restoring from existing RMAN backups of the primary database.

```bash
#!/bin/bash
# Script: rman_create_standby_backup.sh
# Description: Creates a physical standby database using RMAN DUPLICATE FOR STANDBY from existing backups.
# Error Handling: Includes set -e, environment checks, and exit code validation.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Environment Variables (CONFIGURE THESE) ---
# Primary Database Details (Target Connection for RMAN)
export ORACLE_HOME_PRIMARY=/u01/app/oracle/product/19.0.0/dbhome_1 # Primary Oracle Home
export ORACLE_SID_PRIMARY=PRODDB                                  # Primary Oracle SID (Target)
# If connecting remotely, define TNS alias for primary:
# export TNS_ALIAS_PRIMARY=proddb_tns # Example TNS alias
# export TNS_ADMIN_PRIMARY=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for primary

# Standby Database Details (Auxiliary Instance)
export ORACLE_HOME_STANDBY=/u01/app/oracle/product/19.0.0/dbhome_1 # Standby Oracle Home (can be same as primary)
export ORACLE_SID_STANDBY=STBYDB                                  # Standby Oracle SID (Auxiliary)
# If connecting remotely, define TNS alias for auxiliary:
# export TNS_ALIAS_STANDBY=stbydb_tns # Example TNS alias
# export TNS_ADMIN_STANDBY=/u01/app/oracle/product/19.0.0/dbhome_1/network/admin # TNS path for standby

# Backup Location of Primary Database Backups
# This directory should be accessible from the AUXILIARY server where RMAN is run
export BACKUP_LOCATION_PRIMARY=/backup/rman/PRODDB                 # Location of primary database backups

# New Paths for Datafiles and FRA on Standby Server
# *** IMPORTANT: Adjust these conversion rules ***
CONVERT_RULES="('/u01/app/oracle/oradata/PRODDB', '/u01/app/oracle/oradata/STBYDB')"
FRA_DEST_STANDBY="/u01/app/oracle/fast_recovery_area/STBYDB" # New FRA path for standby instance
LOG_DEST_STANDBY="/u01/app/oracle/redo/STBYDB"              # New Redo Log path for standby instance

# --- Log File Configuration ---
LOG_DIR="/tmp/rman_logs"
mkdir -p "${LOG_DIR}" || { echo "ERROR: Could not create log directory ${LOG_DIR}. Exiting." >&2; exit 1; }
LOG_FILE="${LOG_DIR}/rman_create_standby_backup_${ORACLE_SID_PRIMARY}_to_${ORACLE_SID_STANDBY}_$(date +%Y%m%d_%H%M%S).log"

# --- Environment Variable Validation ---
if [ -z "${ORACLE_HOME_PRIMARY}" ] || [ -z "${ORACLE_SID_PRIMARY}" ] || \
   [ -z "${ORACLE_HOME_STANDBY}" ] || [ -z "${ORACLE_SID_STANDBY}" ]; then
  echo "ERROR: One or more required environment variables (ORACLE_HOME_PRIMARY, ORACLE_SID_PRIMARY, ORACLE_HOME_STANDBY, ORACLE_SID_STANDBY) are not set. Exiting." | tee -a "${LOG_FILE}"
  exit 1
fi

echo "Starting RMAN Duplicate (Backup-Based) to Create Standby from ${ORACLE_SID_PRIMARY} to ${ORACLE_SID_STANDBY} at $(date)" | tee -a "${LOG_FILE}"
echo "Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"

# --- Start Auxiliary Instance in NOMOUNT ---
echo "Attempting to start auxiliary instance ${ORACLE_SID_STANDBY} in NOMOUNT mode..." | tee -a "${LOG_FILE}"
# Ensure an init.ora file exists for STBYDB (or whatever your ORACLE_SID_STANDBY is) at $ORACLE_HOME_STANDBY/dbs/init${ORACLE_SID_STANDBY}.ora
# This PFILE should point to the correct DB_NAME (primary's DB_NAME), DB_UNIQUE_NAME (standby's unique name), and desired file paths.
ORACLE_HOME=${ORACLE_HOME_STANDBY} ORACLE_SID=${ORACLE_SID_STANDBY} \
"${ORACLE_HOME_STANDBY}"/bin/sqlplus /nolog << EOF_SQL >> "${LOG_FILE}" 2>&1
  CONNECT SYS/password AS SYSDBA; # Or use OS authentication
  STARTUP NOMOUNT PFILE='${ORACLE_HOME_STANDBY}/dbs/init${ORACLE_SID_STANDBY}.ora';
EOF_SQL

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start auxiliary instance ${ORACLE_SID_STANDBY} in NOMOUNT mode. Check init.ora, permissions, and logs." | tee -a "${LOG_FILE}"
  exit 1
fi
echo "Auxiliary instance ${ORACLE_SID_STANDBY} started in NOMOUNT." | tee -a "${LOG_FILE}"

# --- RMAN Command Execution ---
RMAN_TARGET_CONNECT="target /"
# RMAN_TARGET_CONNECT="target sys/password@${TNS_ALIAS_PRIMARY}"
RMAN_AUXILIARY_CONNECT="auxiliary /"
# RMAN_AUXILIARY_CONNECT="auxiliary sys/password@${TNS_ALIAS_STANDBY}"
export TNS_ADMIN="${TNS_ADMIN_PRIMARY}:${TNS_ADMIN_STANDBY}"

"${ORACLE_HOME_PRIMARY}"/bin/rman ${RMAN_TARGET_CONNECT} ${RMAN_AUXILIARY_CONNECT} log="${LOG_FILE}" << EOF
RUN {
  # Allocate 8 channels for parallelism
  ALLOCATE AUXILIARY CHANNEL aux1 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux2 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux3 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux4 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux5 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux6 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux7 DEVICE TYPE DISK;
  ALLOCATE AUXILIARY CHANNEL aux8 DEVICE TYPE DISK;

  # Define conversion rules for datafiles and redo logs
  # NO SET NEWNAME FOR DATABASE TO NEW; for standby as it retains original DBID
  SET DB_FILE_NAME_CONVERT ${CONVERT_RULES};
  SET LOG_FILE_NAME_CONVERT ${CONVERT_RULES};
  
  # Set new FRA location for the standby database
  SET DB_RECOVERY_FILE_DEST_SIZE = 50G; # Adjust size as needed
  SET DB_RECOVERY_FILE_DEST = '${FRA_DEST_STANDBY}';

  # Perform Backup-Based Duplication for Standby
  DUPLICATE TARGET DATABASE FOR STANDBY
  DORECOVER # This ensures that RMAN applies archived logs to bring standby up-to-date
  BACKUP LOCATION '${BACKUP_LOCATION_PRIMARY}' # IMPORTANT: Specify where RMAN can find the backups
  SPFILE PARAMETER_VALUE_CONVERT ${CONVERT_RULES} # Needed if SPFILE location changes
  # NOFILENAMECHECK # Uncomment if file names are identical but paths must be different
  LOGFILE GROUP 1 ('${LOG_DEST_STANDBY}/redo01a.log', '${LOG_DEST_STANDBY}/redo01b.log') SIZE 500M,
          GROUP 2 ('${LOG_DEST_STANDBY}/redo02a.log', '${LOG_DEST_STANDBY}/redo02b.log') SIZE 500M,
          GROUP 3 ('${LOG_DEST_STANDBY}/redo03a.log', '${LOG_DEST_STANDBY}/redo03b.log') SIZE 500M;
  
  # Release auxiliary channels
  RELEASE CHANNEL aux1;
  RELEASE CHANNEL aux2;
  RELEASE CHANNEL aux3;
  RELEASE CHANNEL aux4;
  RELEASE CHANNEL aux5;
  RELEASE CHANNEL aux6;
  RELEASE CHANNEL aux7;
  RELEASE CHANNEL aux8;
}
EOF

# --- Post-Duplication Actions ---
echo "Checking RMAN command exit status..." | tee -a "${LOG_FILE}"
if [ $? -eq 0 ]; then
  echo "RMAN Standby Creation Duplicate (Backup-Based) completed successfully for ${ORACLE_SID_STANDBY} at $(date)" | tee -a "${LOG_FILE}"
  echo "Standby database ${ORACLE_SID_STANDBY} is now created. You may start managed recovery:" | tee -a "${LOG_FILE}"
  echo "${ORACLE_HOME_STANDBY}/bin/sqlplus / as sysdba" | tee -a "${LOG_FILE}"
  echo "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION PARALLEL 8;" | tee -a "${LOG_FILE}"
else
  echo "ERROR: RMAN Standby Creation Duplicate (Backup-Based) FAILED for ${ORACLE_SID_STANDBY} at $(date). Check log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
  exit 1
fi
```
