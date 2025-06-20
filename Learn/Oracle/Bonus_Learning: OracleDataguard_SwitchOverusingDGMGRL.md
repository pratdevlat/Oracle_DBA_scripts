# Standard Operating Procedure: Oracle Data Guard Switchover Using DGMGRL

## 1. Purpose and Scope

### 1.1 Purpose
This Standard Operating Procedure (SOP) provides detailed instructions for performing a planned switchover between primary and standby databases in an Oracle Data Guard configuration using the Data Guard Broker command-line interface (DGMGRL). This procedure ensures minimal downtime, automated coordination, and data integrity during role transitions.

### 1.2 Scope
This SOP applies to:
- Oracle Database 11.2.0.1 and later versions
- Oracle Database 12c, 19c, and 21c
- Physical standby database configurations managed by Data Guard Broker
- Single instance and RAC environments
- All Oracle Cloud Infrastructure database services with Data Guard Broker enabled

### 1.3 Key Advantages of Using DGMGRL
- Automated coordination of switchover steps
- Built-in validation and health checks
- Simplified command syntax
- Automatic updating of broker configuration
- Support for fast-start failover configurations

## 2. Pre-requisites and Assumptions

### 2.1 Environment Requirements
- Oracle Database Enterprise Edition 11.2.0.1 or later
- Data Guard Broker configured and enabled
- Physical standby database in broker configuration
- Network connectivity between all databases in configuration
- Static service registration for DGMGRL connectivity

### 2.2 Broker Configuration Requirements
```sql
-- Verify on Primary and Standby
SQL> SHOW PARAMETER dg_broker_start
-- Should return TRUE

SQL> SHOW PARAMETER dg_broker_config_file
-- Verify broker configuration files exist
```

### 2.3 Assumptions
- DBA has SYSDBA privileges on all databases
- Data Guard Broker configuration is healthy
- No configuration warnings or errors exist
- Standby database is synchronized with primary
- DGMGRL can connect to all databases in configuration

### 2.4 Static Service Registration
Ensure static service registration in listener.ora:
```
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = <db_unique_name>_DGMGRL.<domain>)
      (ORACLE_HOME = <oracle_home>)
      (SID_NAME = <instance_name>)
    )
  )
```

## 3. Pre-Switchover Checks

### 3.1 Connect to Data Guard Broker

```bash
dgmgrl sys/<password>@<primary_db>

# Or connect without password
dgmgrl /
DGMGRL> CONNECT sys/<password>@<primary_db>
```

### 3.2 Verify Broker Configuration

#### 3.2.1 Show Configuration Overview
```
DGMGRL> SHOW CONFIGURATION;

Configuration - <configuration_name>

  Protection Mode: MaxPerformance
  Members:
  <primary_db>   - Primary database
    <standby_db> - Physical standby database

Fast-Start Failover: DISABLED

Configuration Status:
SUCCESS   (status updated <timestamp>)
```

#### 3.2.2 Show Detailed Configuration
```
DGMGRL> SHOW CONFIGURATION VERBOSE;
```

### 3.3 Verify Database Status

#### 3.3.1 Check Primary Database
```
DGMGRL> SHOW DATABASE '<primary_db>';

Database - <primary_db>

  Role:               PRIMARY
  Intended State:     TRANSPORT-ON
  Instance(s):
    <instance_name>

Database Status:
SUCCESS
```

#### 3.3.2 Check Standby Database
```
DGMGRL> SHOW DATABASE '<standby_db>';

Database - <standby_db>

  Role:               PHYSICAL STANDBY
  Intended State:     APPLY-ON
  Transport Lag:      0 seconds (computed <n> seconds ago)
  Apply Lag:          0 seconds (computed <n> seconds ago)
  Average Apply Rate: <n> KByte/s
  Real Time Query:    ON
  Instance(s):
    <instance_name>

Database Status:
SUCCESS
```

### 3.4 Validate Database Properties

#### 3.4.1 Check Critical Properties
```
DGMGRL> SHOW DATABASE '<standby_db>' 'InconsistentProperties';
DGMGRL> SHOW DATABASE '<standby_db>' 'InconsistentLogXptProps';
```

#### 3.4.2 Verify Log Transport
```
DGMGRL> SHOW DATABASE '<primary_db>' 'LogXptStatus';
DGMGRL> SHOW DATABASE '<standby_db>' 'LogXptStatus';
```

### 3.5 Check for Configuration Warnings

```
DGMGRL> SHOW CONFIGURATION;
DGMGRL> SHOW DATABASE '<primary_db>';
DGMGRL> SHOW DATABASE '<standby_db>';
```

**Warning:** Resolve any warnings before proceeding with switchover.

### 3.6 Validate Switchover Readiness

```
DGMGRL> VALIDATE DATABASE '<standby_db>';

  Member '<standby_db>' successfully validated
```

### 3.7 Check Fast-Start Failover Status

```
DGMGRL> SHOW FAST_START FAILOVER;
```

**Note:** If Fast-Start Failover is enabled, consider the impact on the observer.

## 4. Switchover Procedure

### 4.1 Final Pre-Switchover Validation

#### 4.1.1 Verify Configuration Status
```
DGMGRL> SHOW CONFIGURATION;
```
Ensure status shows SUCCESS.

#### 4.1.2 Check Database States
```
DGMGRL> SHOW DATABASE '<primary_db>';
DGMGRL> SHOW DATABASE '<standby_db>';
```

### 4.2 Disable Fast-Start Failover (If Enabled)

```
DGMGRL> DISABLE FAST_START FAILOVER;
```

### 4.3 Execute Switchover Command

#### 4.3.1 Basic Switchover
```
DGMGRL> SWITCHOVER TO '<standby_db>';
```

#### 4.3.2 Switchover with Verification
```
DGMGRL> SWITCHOVER TO '<standby_db>' VERIFY;
```

#### 4.3.3 Immediate Switchover (Forces Disconnection)
```
DGMGRL> SWITCHOVER TO '<standby_db>' IMMEDIATE;
```

### 4.4 Monitor Switchover Progress

The switchover process will display progress messages:
```
Performing switchover NOW, please wait...
Operation requires a connection to instance "<instance>" on database "<standby_db>"
Connecting to instance "<instance>"...
Connected as SYSDBA.
New primary database "<standby_db>" is opening...
Operation requires start up of instance "<instance>" on database "<primary_db>"
Starting instance "<instance>"...
ORACLE instance started.
Database mounted.
Switchover succeeded, new primary is "<standby_db>"
```

### 4.5 Switchover Completion

Upon successful completion, verify the new configuration:
```
DGMGRL> SHOW CONFIGURATION;

Configuration - <configuration_name>

  Protection Mode: MaxPerformance
  Members:
  <standby_db>  - Primary database
    <primary_db> - Physical standby database

Fast-Start Failover: DISABLED

Configuration Status:
SUCCESS   (status updated <timestamp>)
```

## 5. Post-Switchover Validation

### 5.1 Verify New Roles

```
DGMGRL> SHOW DATABASE '<new_primary>' VERBOSE;
DGMGRL> SHOW DATABASE '<new_standby>' VERBOSE;
```

### 5.2 Check Configuration Health

```
DGMGRL> SHOW CONFIGURATION;
DGMGRL> SHOW CONFIGURATION LAG;
```

### 5.3 Validate Log Transport

```
DGMGRL> SHOW DATABASE '<new_primary>' 'LogXptStatus';
```

### 5.4 Monitor Apply Lag

```
DGMGRL> SHOW DATABASE '<new_standby>' 'ApplyLag';
DGMGRL> SHOW DATABASE '<new_standby>' 'TransportLag';
```

### 5.5 Re-enable Fast-Start Failover (If Required)

```
DGMGRL> ENABLE FAST_START FAILOVER;
```

### 5.6 Verify Services

```
DGMGRL> SHOW DATABASE '<new_primary>' 'StaticConnectIdentifier';
DGMGRL> SHOW DATABASE '<new_standby>' 'StaticConnectIdentifier';
```

## 6. Troubleshooting and Recovery

### 6.1 Common Issues and Solutions

#### 6.1.1 ORA-16541: Database is not enabled
**Solution:**
```
DGMGRL> ENABLE DATABASE '<database_name>';
```

#### 6.1.2 ORA-16665: Timeout waiting for the result from a member
**Solution:**
- Check network connectivity
- Verify static service registration
- Ensure listener is running
```
DGMGRL> SHOW DATABASE '<database_name>' 'StaticConnectIdentifier';
```

#### 6.1.3 ORA-16810: Multiple errors or warnings detected
**Solution:**
```
DGMGRL> SHOW DATABASE '<database_name>' 'StatusReport';
DGMGRL> SHOW DATABASE '<database_name>' 'InconsistentProperties';
```

#### 6.1.4 ORA-16627: Operation disallowed since no standby databases
**Solution:**
Verify standby database is part of broker configuration:
```
DGMGRL> SHOW CONFIGURATION;
```

### 6.2 Diagnostic Commands

#### 6.2.1 Detailed Status Report
```
DGMGRL> SHOW DATABASE '<database_name>' 'StatusReport';
```

#### 6.2.2 Check Broker Log Files
```
DGMGRL> SHOW DATABASE '<database_name>' 'LogFileLocation';
```

#### 6.2.3 Monitor Real-Time Apply
```
DGMGRL> SHOW DATABASE '<standby_db>' 'RecvQEntries';
```

### 6.3 Enable Broker Tracing

```
DGMGRL> EDIT CONFIGURATION SET PROPERTY TraceLevel=USER;
```

Trace levels: USER, SUPPORT, DEBUG

### 6.4 Fix Configuration Issues

#### 6.4.1 Reinstate Failed Database
```
DGMGRL> REINSTATE DATABASE '<database_name>';
```

#### 6.4.2 Reset Property Values
```
DGMGRL> EDIT DATABASE '<database_name>' RESET PROPERTY '<property_name>';
```

## 7. Rollback Plan

### 7.1 Switchback to Original Configuration

If needed to return to original roles:
```
DGMGRL> SWITCHOVER TO '<original_primary>';
```

### 7.2 Disable/Enable Configuration

If configuration is in an inconsistent state:
```
DGMGRL> DISABLE CONFIGURATION;
DGMGRL> ENABLE CONFIGURATION;
```

### 7.3 Remove and Re-add Database

For severe issues:
```
DGMGRL> REMOVE DATABASE '<database_name>' PRESERVE DESTINATIONS;
DGMGRL> ADD DATABASE '<database_name>' AS CONNECT IDENTIFIER IS '<connect_string>';
```

### 7.4 Complete Configuration Recreation

If broker configuration is corrupted:
1. On all databases:
```sql
SQL> ALTER SYSTEM SET dg_broker_start=FALSE;
```

2. Remove broker configuration files:
```bash
rm $ORACLE_HOME/dbs/dr1<SID>.dat
rm $ORACLE_HOME/dbs/dr2<SID>.dat
```

3. Recreate configuration:
```sql
SQL> ALTER SYSTEM SET dg_broker_start=TRUE;
```

4. In DGMGRL:
```
DGMGRL> CREATE CONFIGURATION '<config_name>' AS PRIMARY DATABASE IS '<primary_db>' CONNECT IDENTIFIER IS '<connect_string>';
DGMGRL> ADD DATABASE '<standby_db>' AS CONNECT IDENTIFIER IS '<connect_string>';
DGMGRL> ENABLE CONFIGURATION;
```

## 8. Appendix

### 8.1 DGMGRL Command Reference

#### Configuration Management
```
SHOW CONFIGURATION [VERBOSE];
ENABLE CONFIGURATION;
DISABLE CONFIGURATION;
REMOVE CONFIGURATION [PRESERVE DESTINATIONS];
```

#### Database Management
```
SHOW DATABASE [VERBOSE] '<database_name>';
ENABLE DATABASE '<database_name>';
DISABLE DATABASE '<database_name>';
REMOVE DATABASE '<database_name>' [PRESERVE DESTINATIONS];
```

#### Switchover Commands
```
SWITCHOVER TO '<database_name>' [VERIFY];
SWITCHOVER TO '<database_name>' [IMMEDIATE];
SWITCHOVER TO '<database_name>' [WAIT <seconds>];
```

#### Validation Commands
```
VALIDATE DATABASE '<database_name>';
VALIDATE DATABASE '<database_name>' DATAFILE ALL;
VALIDATE DATABASE '<database_name>' SPFILE;
```

#### Property Management
```
SHOW DATABASE '<database_name>' '<property_name>';
EDIT DATABASE '<database_name>' SET PROPERTY '<property_name>'='<value>';
EDIT DATABASE '<database_name>' RESET PROPERTY '<property_name>';
```

### 8.2 Key Database Properties

| Property | Description | Example |
|----------|-------------|---------|
| LogXptMode | Redo transport mode | ASYNC, SYNC |
| DelayMins | Apply delay in minutes | 0-∞ |
| ApplyInstanceTimeout | Timeout for apply instance | 120 |
| ReopenSecs | Seconds before retry connection | 300 |
| NetTimeout | Network timeout | 30 |
| StaticConnectIdentifier | Static connection string | host:port/service |

### 8.3 Monitoring Scripts

#### 8.3.1 Create Monitoring Script
```bash
#!/bin/bash
# monitor_dg.sh
dgmgrl -silent sys/<password>@<primary> <<EOF
show configuration lag;
show database '<primary>' 'LogXptStatus';
show database '<standby>' 'ApplyLag';
exit;
EOF
```

#### 8.3.2 Automated Health Check
```
DGMGRL> HOST echo "show configuration;" | dgmgrl -silent sys/<password>
```

### 8.4 Best Practices

1. **Regular Configuration Validation**
   - Run `VALIDATE DATABASE` weekly
   - Check for warnings daily
   - Monitor lag metrics continuously

2. **Maintain Broker Health**
   - Keep broker configuration files on shared storage in RAC
   - Ensure static service registration is correct
   - Test DGMGRL connectivity regularly

3. **Switchover Planning**
   - Always use VERIFY option first
   - Document current configuration before changes
   - Have rollback plan ready
   - Test in non-production environments

4. **Fast-Start Failover Considerations**
   - Understand observer placement
   - Plan for observer during switchover
   - Consider using multiple observers (12c+)

5. **Performance Optimization**
   - Set appropriate LogXptMode (ASYNC for most cases)
   - Configure sufficient network bandwidth
   - Monitor and tune based on lag metrics

### 8.5 Differences Between Versions

| Feature | 11.2 | 12c | 19c/21c |
|---------|------|-----|---------|
| Multiple Observers | No | Yes | Enhanced |
| Validate Database | Basic | Enhanced | Comprehensive |
| Property Management | Limited | Extended | Full-featured |
| CDB Support | No | Yes | Optimized |
| Application Continuity | No | Yes | Integrated |
| Switchover Verification | Basic | VERIFY option | Enhanced VERIFY |

### 8.6 Log File Locations

#### Broker Log Files
```
# Primary location
$ORACLE_BASE/diag/rdbms/<db_unique_name>/<instance_name>/trace/drm<instance>.log

# Alert log entries
$ORACLE_BASE/diag/rdbms/<db_unique_name>/<instance_name>/trace/alert_<instance>.log
```

#### Configuration Files
```
# Default locations
$ORACLE_HOME/dbs/dr1<ORACLE_SID>.dat
$ORACLE_HOME/dbs/dr2<ORACLE_SID>.dat
```

### 8.7 Emergency Contact Information

- **Primary DBA:** _________________________
- **Secondary DBA:** _________________________
- **Application Team:** _________________________
- **Network Team:** _________________________
- **Oracle Support:** 1-800-223-1711

### 8.8 External References

- Oracle Data Guard Broker Administrator's Guide
- My Oracle Support (MOS) - https://support.oracle.com
- MOS Note 1305019.1 - Data Guard Physical Standby Switchover Best Practices using the Broker
- MOS Note 1582179.1 - Oracle Data Guard Broker Configuration and Troubleshooting Best Practices
- Oracle MAA Best Practices - https://www.oracle.com/goto/maa

---

**Document Version:** 1.0  
**Last Updated:** Current as of Oracle Database 21c  
**Author:** _________________________  
**Approval:** _________________________  
**Date:** _________________________
