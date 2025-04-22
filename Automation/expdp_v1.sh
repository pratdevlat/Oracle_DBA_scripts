#!/bin/bash

# === Configuration ===
EXPORT_DIR="BACKUP_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="expdp_export_${TIMESTAMP}.log"
PARALLEL=$(( $(nproc) / 2 ))
if [ $PARALLEL -lt 1 ]; then
  PARALLEL=1
fi

# === Prompt user for export type ===
echo "Choose export type:"
echo "1. Schema"
echo "2. Table (Single or Multiple)"
echo "3. Full Database"
read -p "Enter your choice (1/2/3): " EXPORT_TYPE

# === Schema Export ===
if [ "$EXPORT_TYPE" == "1" ]; then
    read -p "Enter the schema name to export: " SCHEMA_NAME
    DUMP_FILE="${SCHEMA_NAME}_schema_${TIMESTAMP}.dmp"

    expdp "/ as sysdba" \
      schemas=${SCHEMA_NAME} \
      directory=${EXPORT_DIR} \
      dumpfile=${DUMP_FILE} \
      logfile=${LOG_FILE} \
      parallel=${PARALLEL} \
      reuse_dumpfiles=y

# === Table Export ===
elif [ "$EXPORT_TYPE" == "2" ]; then
    read -p "Enter comma-separated table names (e.g., hr.emp,hr.dept,hr.sales) : " TABLES
    DUMP_FILE="tables_export_${TIMESTAMP}.dmp"

    expdp "/ as sysdba" \
      tables=${TABLES} \
      directory=${EXPORT_DIR} \
      dumpfile=${DUMP_FILE} \
      logfile=${LOG_FILE} \
      parallel=${PARALLEL} \
      reuse_dumpfiles=y

# === Full Export ===
elif [ "$EXPORT_TYPE" == "3" ]; then
    DUMP_FILE="full_export_${TIMESTAMP}.dmp"

    expdp "/ as sysdba" \
      full=y \
      directory=${EXPORT_DIR} \
      dumpfile=${DUMP_FILE} \
      logfile=${LOG_FILE} \
      parallel=${PARALLEL} \
      reuse_dumpfiles=y
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# === Done ===
STATUS=$?
if [ $STATUS -eq 0 ]; then
    echo "Export SUCCESS. Dump: $DUMP_FILE, Log: $LOG_FILE"
else
    echo "Export FAILED. Check log: $LOG_FILE"
fi
