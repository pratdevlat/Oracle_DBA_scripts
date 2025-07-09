# Oracle Data Guard Post-Switchover: Database Unique Name Swap Guide

## Overview

This document provides detailed procedures for swapping database unique names after a successful Oracle Data Guard switchover. The switchover has already been completed, and databases are operational in their new roles.

**Prerequisites:**

- Switchover has been successfully completed
- Former primary is now standby (mounted state)
- Former standby is now primary (open state)
- Both databases are operational

## Current State Assessment

### Step 1: Verify Current Configuration

```sql
-- On NEW PRIMARY (former standby)
SELECT name, database_role, db_unique_name, open_mode FROM v$database;

-- Expected output:
-- NAME      DATABASE_ROLE    DB_UNIQUE_NAME    OPEN_MODE
-- PROD      PRIMARY          PROD_STANDBY      READ WRITE

-- On NEW STANDBY (former primary)
SELECT name, database_role, db_unique_name, open_mode FROM v$database;

-- Expected output:
-- NAME      DATABASE_ROLE    DB_UNIQUE_NAME    OPEN_MODE
-- PROD      PHYSICAL STANDBY PROD_PRIMARY      MOUNTED
```

### Step 2: Check Data Guard Configuration Status

```sql
-- On NEW PRIMARY
SELECT dest_name, status, destination, db_unique_name 
FROM v$archive_dest_status 
WHERE status = 'VALID';

-- Verify log transport services are working
SELECT dest_id, status, error FROM v$archive_dest;
```

## Database Unique Name Swap Procedure

### Step 3: Stop Log Transport Services

```sql
-- On NEW PRIMARY
ALTER SYSTEM SET log_archive_dest_state_2=DEFER;

-- Verify service is deferred
SELECT dest_id, status FROM v$archive_dest WHERE dest_id = 2;
```

### Step 4: Update DB_UNIQUE_NAME on New Primary

```sql
-- On NEW PRIMARY (currently has DB_UNIQUE_NAME = 'PROD_STANDBY')
ALTER SYSTEM SET DB_UNIQUE_NAME='PROD_PRIMARY' SCOPE=SPFILE;

-- Verify the change is pending
SHOW PARAMETER db_unique_name;
```

### Step 5: Update DB_UNIQUE_NAME on New Standby

```sql
-- On NEW STANDBY (currently has DB_UNIQUE_NAME = 'PROD_PRIMARY')
ALTER SYSTEM SET DB_UNIQUE_NAME='PROD_STANDBY' SCOPE=SPFILE;

-- Verify the change is pending
SHOW PARAMETER db_unique_name;
```

### Step 6: Update Log Archive Destination Parameters

```sql
-- On NEW PRIMARY
-- Update destination to point to new standby unique name
ALTER SYSTEM SET log_archive_dest_2='SERVICE=PROD_STANDBY LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=PROD_STANDBY' SCOPE=SPFILE;

-- On NEW STANDBY
-- Update FAL (Fetch Archive Log) parameters
ALTER SYSTEM SET fal_server='PROD_PRIMARY' SCOPE=SPFILE;
ALTER SYSTEM SET fal_client='PROD_STANDBY' SCOPE=SPFILE;
```

### Step 7: Restart New Standby Database

```sql
-- On NEW STANDBY
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;

-- Verify new unique name is active
SELECT name, database_role, db_unique_name, open_mode FROM v$database;
-- Expected: DB_UNIQUE_NAME should now be 'PROD_STANDBY'
```

### Step 8: Restart New Primary Database

```sql
-- On NEW PRIMARY
SHUTDOWN IMMEDIATE;
STARTUP;

-- Verify new unique name is active
SELECT name, database_role, db_unique_name, open_mode FROM v$database;
-- Expected: DB_UNIQUE_NAME should now be 'PROD_PRIMARY'
```

### Step 9: Re-enable Log Transport Services

```sql
-- On NEW PRIMARY
ALTER SYSTEM SET log_archive_dest_state_2=ENABLE;

-- Verify service is enabled
SELECT dest_id, status, destination FROM v$archive_dest WHERE dest_id = 2;
```

## Verification and Validation

### Step 10: Verify Data Guard Configuration

```sql
-- On NEW PRIMARY
SELECT dest_name, status, destination, db_unique_name, gap_status 
FROM v$archive_dest_status 
WHERE dest_id = 2;

-- Expected output:
-- DEST_NAME    STATUS    DESTINATION          DB_UNIQUE_NAME    GAP_STATUS
-- LOG_ARCHIVE_DEST_2    VALID    PROD_STANDBY    PROD_STANDBY    NO GAP
```

### Step 11: Test Log Transport and Apply

```sql
-- On NEW PRIMARY
ALTER SYSTEM SWITCH LOGFILE;

-- Wait 30 seconds, then check on NEW STANDBY
SELECT sequence#, applied FROM v$archived_log 
WHERE dest_id = 1 
ORDER BY sequence# DESC 
FETCH FIRST 5 ROWS ONLY;
```

### Step 12: Verify MRP (Managed Recovery Process) Status

```sql
-- On NEW STANDBY
SELECT process, status, client_process, sequence# 
FROM v$managed_standby 
WHERE process = 'MRP0';

-- Expected output should show MRP0 process is APPLYING_LOG
```

### Step 13: Check Data Guard Broker Configuration (if using)

```sql
-- Connect to DGMGRL
dgmgrl sys/password@PROD_PRIMARY

-- Check configuration
SHOW CONFIGURATION;

-- Expected output should show correct unique names:
-- PROD_PRIMARY - Primary database
-- PROD_STANDBY - Physical standby database
```

## TNS Configuration Updates

### Step 14: Update TNS Names (if required)

```bash
# Update tnsnames.ora on all client machines and database servers
vi $ORACLE_HOME/network/admin/tnsnames.ora

# Ensure TNS aliases match the new unique names
PROD_PRIMARY =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = primary-host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = PROD)
    )
  )

PROD_STANDBY =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = standby-host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = PROD)
    )
  )
```

### Step 15: Test TNS Connectivity

```bash
# Test connection to both databases
tnsping PROD_PRIMARY
tnsping PROD_STANDBY

# Test SQL connectivity
sqlplus sys/password@PROD_PRIMARY as sysdba
sqlplus sys/password@PROD_STANDBY as sysdba
```

## Final Validation

### Step 16: Comprehensive Health Check

```sql
-- On NEW PRIMARY
SELECT 
    'PRIMARY' as database_role,
    name,
    db_unique_name,
    database_role,
    open_mode,
    log_mode
FROM v$database;

-- On NEW STANDBY
SELECT 
    'STANDBY' as database_role,
    name,
    db_unique_name,
    database_role,
    open_mode,
    log_mode
FROM v$database;
```

### Step 17: Monitor Alert Logs

```bash
# Check alert logs for any errors
tail -f $ORACLE_BASE/diag/rdbms/prod/prod/trace/alert_prod.log

# Look for:
# - No ORA- errors
# - Successful log transport messages
# - Successful log apply messages
```

### Step 18: Final Data Guard Status Check

```sql
-- On NEW PRIMARY
SELECT 
    dest_id,
    dest_name,
    status,
    destination,
    db_unique_name,
    synchronization_status,
    archived_seq#,
    applied_seq#
FROM v$archive_dest_status
WHERE dest_id = 2;
```

## Rollback Procedure (Emergency Only)

### If Issues Arise During Process:

```sql
-- 1. Stop log transport
ALTER SYSTEM SET log_archive_dest_state_2=DEFER;

-- 2. Revert DB_UNIQUE_NAME parameters
-- On NEW PRIMARY
ALTER SYSTEM SET DB_UNIQUE_NAME='PROD_STANDBY' SCOPE=SPFILE;

-- On NEW STANDBY
ALTER SYSTEM SET DB_UNIQUE_NAME='PROD_PRIMARY' SCOPE=SPFILE;

-- 3. Restart both databases
-- 4. Re-enable log transport with original settings
```

## Post-Completion Checklist

- [ ] DB_UNIQUE_NAME correctly swapped on both databases
- [ ] Log transport services operational
- [ ] Log apply services operational
- [ ] No gaps in archive log sequence
- [ ] Alert logs show no errors
- [ ] TNS connectivity tested successfully
- [ ] Data Guard Broker configuration updated (if applicable)
- [ ] Application connectivity verified
- [ ] Monitoring systems updated with new configuration
- [ ] Documentation updated with new roles

## Troubleshooting Common Issues

### Issue 1: ORA-16714 - The value of parameter DB_UNIQUE_NAME is not unique

**Solution:**

```sql
-- Ensure unique names are different between primary and standby
-- Check current values on both databases
SELECT db_unique_name FROM v$database;
```

### Issue 2: Log transport not working after restart

**Solution:**

```sql
-- Check archive destination status
SELECT dest_id, status, error FROM v$archive_dest WHERE dest_id = 2;

-- Re-enable if deferred
ALTER SYSTEM SET log_archive_dest_state_2=ENABLE;
```

### Issue 3: ORA-16191 - Primary log shipping client not logged on standby

**Solution:**

```sql
-- Check TNS connectivity from primary to standby
-- Verify LOG_ARCHIVE_DEST_2 parameter points to correct service
SHOW PARAMETER log_archive_dest_2;
```

## Important Notes

1. **Timing**: Complete this process during a maintenance window
1. **Monitoring**: Monitor alert logs continuously during the process
1. **Backup**: Ensure recent backups are available before starting
1. **Testing**: Test in non-production environment first
1. **Validation**: Each step must be validated before proceeding to the next

-----

**Document Version**: 1.0  
**Environment**: Oracle Data Guard 19c+  
**Last Updated**: [Current Date]  
**Process Duration**: Approximately 30-45 minutes