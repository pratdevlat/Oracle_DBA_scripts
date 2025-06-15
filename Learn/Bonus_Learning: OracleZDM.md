# Oracle Zero Downtime Migration (ZDM) - Complete Guide

## What is Oracle ZDM?

Oracle Zero Downtime Migration (ZDM) is an Oracle Cloud service and on-premises solution that enables database migrations with minimal downtime. It automates the migration process and provides a unified approach for moving Oracle databases between different environments.

### Key Concepts

- **Zero Downtime**: Minimizes application downtime during migration (typically minutes)
- **Automation**: Reduces manual steps and human errors
- **Flexibility**: Supports various migration scenarios
- **Monitoring**: Provides real-time migration status and progress tracking

## ZDM Architecture

### Components

1. **ZDM Service Host**: The server where ZDM software is installed
1. **Source Database**: The database being migrated from
1. **Target Database**: The destination database
1. **ZDM Repository**: Stores migration metadata and job information

### Migration Flow

```
Source DB → ZDM Service Host → Target DB
     ↓              ↓              ↓
  Data Pump    Job Orchestration  Data Import
  Backup/Restore   Monitoring     Validation
```

## Supported Migration Types

### 1. Logical Migration

- Uses Oracle Data Pump (expdp/impdp)
- Suitable for smaller databases
- Platform independent
- Schema-level or full database migration

### 2. Physical Migration

- Uses RMAN backup/restore
- Faster for large databases
- Platform dependent (same OS/architecture)
- Block-level copying

### 3. Online Migration

- Uses Oracle GoldenGate or Data Guard
- Continuous replication during migration
- Minimal downtime
- Real-time data synchronization

## Prerequisites

### System Requirements

- Oracle Database 11.2.0.4+ (source)
- Oracle Database 12.1+ (target)
- ZDM 21.1+ software
- Sufficient storage space
- Network connectivity between source and target

### Permissions Required

```sql
-- Source database user permissions
GRANT CREATE SESSION TO zdm_user;
GRANT SELECT_CATALOG_ROLE TO zdm_user;
GRANT EXP_FULL_DATABASE TO zdm_user;
GRANT DATAPUMP_EXP_FULL_DATABASE TO zdm_user;

-- Target database user permissions
GRANT CREATE SESSION TO zdm_user;
GRANT IMP_FULL_DATABASE TO zdm_user;
GRANT DATAPUMP_IMP_FULL_DATABASE TO zdm_user;
GRANT CREATE USER TO zdm_user;
```

## Installation and Setup

### 1. Download and Install ZDM

```bash
# Download ZDM software from Oracle Support
# Extract the software
unzip zdm-21.4.zip

# Run the installer
./zdminstall.sh -zdmhome /u01/app/zdm -zdmbase /u01/app/zdmbase
```

### 2. Configure ZDM Service

```bash
# Start ZDM service
zdmservice start

# Check service status
zdmservice status

# Configure database connections
zdmcli configure database -sourcesid SOURCEDB -sourcenode sourcehost \
  -targetsid TARGETDB -targetnode targethost
```

## ZDM Command Line Interface (CLI)

### Basic Commands Structure

```bash
zdmcli <operation> <object> [options]
```

### Common Operations

- `migrate database`: Start migration
- `query job`: Check job status
- `suspend job`: Pause migration
- `resume job`: Resume migration
- `abort job`: Cancel migration

## Migration Workflow

### 1. Pre-Migration Assessment

```bash
# Assess source database
zdmcli migrate database -sourcesid SOURCEDB -sourcenode sourcehost \
  -targetsid TARGETDB -targetnode targethost -assess

# Example output:
# Assessment completed successfully
# Database size: 500GB
# Estimated migration time: 4 hours
# Recommended migration type: Physical
```

### 2. Migration Execution

```bash
# Start logical migration
zdmcli migrate database -sourcesid SOURCEDB -sourcenode sourcehost \
  -targetsid TARGETDB -targetnode targethost \
  -migration logical \
  -sourceuserdir /home/oracle/.zdm \
  -targetuserdir /home/oracle/.zdm

# Start physical migration
zdmcli migrate database -sourcesid SOURCEDB -sourcenode sourcehost \
  -targetsid TARGETDB -targetnode targethost \
  -migration physical \
  -backupdir /backup/zdm
```

### 3. Monitor Migration Progress

```bash
# Query job status
zdmcli query job -jobid 123

# Example output:
# Job ID: 123
# Status: RUNNING
# Phase: DATA_PUMP_EXPORT
# Progress: 45%
# Elapsed Time: 2h 15m
# Estimated Remaining: 1h 30m
```

## Practical Examples

### Example 1: Simple Logical Migration

```bash
# Scenario: Migrate PRODDB from server1 to server2
# Database size: 100GB

# Step 1: Configure
zdmcli configure database -sourcesid PRODDB -sourcenode server1 \
  -targetsid TESTDB -targetnode server2 \
  -sourceuser oracle -targetuser oracle

# Step 2: Assess
zdmcli migrate database -sourcesid PRODDB -sourcenode server1 \
  -targetsid TESTDB -targetnode server2 -assess

# Step 3: Execute migration
zdmcli migrate database -sourcesid PRODDB -sourcenode server1 \
  -targetsid TESTDB -targetnode server2 \
  -migration logical \
  -sourceuserdir /home/oracle/.zdm \
  -targetuserdir /home/oracle/.zdm \
  -dumplocation /shared/dump
```

### Example 2: Physical Migration with RMAN

```bash
# Scenario: Large database migration (1TB+)
# Same platform (Linux x86_64)

# Step 1: Prepare backup location
mkdir -p /backup/zdm/PRODDB
chown oracle:oinstall /backup/zdm/PRODDB

# Step 2: Execute physical migration
zdmcli migrate database -sourcesid PRODDB -sourcenode server1 \
  -targetsid PRODDB -targetnode server2 \
  -migration physical \
  -backupdir /backup/zdm \
  -sourceuserdir /home/oracle/.zdm \
  -targetuserdir /home/oracle/.zdm
```

### Example 3: Online Migration with GoldenGate

```bash
# Scenario: Mission-critical database with minimal downtime requirement

# Step 1: Configure GoldenGate
zdmcli migrate database -sourcesid PRODDB -sourcenode server1 \
  -targetsid PRODDB -targetnode server2 \
  -migration online \
  -ggadmin ggadmin \
  -gghome /u01/app/goldengate

# Step 2: Start online migration
# This will set up replication and sync data continuously
```

## Migration Phases Explained

### Logical Migration Phases

1. **PREINIT**: Pre-migration checks and setup
1. **EXPORT**: Data Pump export from source
1. **BACKUP_RESTORE**: Optional backup operations
1. **IMPORT**: Data Pump import to target
1. **POSTINIT**: Post-migration tasks and validation

### Physical Migration Phases

1. **PREINIT**: Pre-migration setup
1. **BACKUP**: RMAN backup of source database
1. **RESTORE**: RMAN restore to target
1. **RECOVER**: Database recovery operations
1. **POSTINIT**: Final configuration and validation

## Monitoring and Troubleshooting

### Check Job Details

```bash
# Get detailed job information
zdmcli query job -jobid 123 -details

# View job logs
zdmcli query job -jobid 123 -log
```

### Common Status Values

- **INITIALIZED**: Job created but not started
- **RUNNING**: Migration in progress
- **SUSPENDED**: Job paused
- **SUCCEEDED**: Migration completed successfully
- **FAILED**: Migration failed
- **ABORTED**: Migration cancelled

### Troubleshooting Common Issues

#### Issue 1: Insufficient Space

```bash
# Error: Not enough space in dump directory
# Solution: Check and increase space
df -h /shared/dump

# Add more space or change dump location
zdmcli modify job -jobid 123 -dumplocation /larger/dump/dir
```

#### Issue 2: Network Connectivity

```bash
# Error: Cannot connect to target database
# Solution: Verify tnsnames.ora and network connectivity
tnsping TARGETDB
sqlplus zdm_user/password@TARGETDB
```

## Best Practices

### Pre-Migration

1. **Test migrations** in non-production environments first
1. **Validate connectivity** between source and target
1. **Ensure sufficient storage** space (3x database size for logical)
1. **Schedule during maintenance windows** for critical systems
1. **Create database backups** before migration

### During Migration

1. **Monitor job progress** regularly
1. **Check log files** for warnings or errors
1. **Avoid system changes** on source database
1. **Maintain network stability** between systems

### Post-Migration

1. **Validate data integrity** using checksums or counts
1. **Test application connectivity** to new database
1. **Update connection strings** and TNS entries
1. **Monitor performance** and optimize if needed
1. **Clean up temporary files** and dump files

## Advanced Configuration

### Custom Parameter Files

```bash
# Create response file for automated migrations
cat > migrate_response.rsp << EOF
SOURCE_DB_SID=PRODDB
SOURCE_DB_HOST=server1
TARGET_DB_SID=TESTDB
TARGET_DB_HOST=server2
MIGRATION_TYPE=logical
DUMP_LOCATION=/shared/dump
PARALLEL_DEGREE=4
EOF

# Use response file
zdmcli migrate database -responsefile migrate_response.rsp
```

### Performance Tuning

```bash
# Increase parallelism for Data Pump
zdmcli migrate database ... -parallel 8

# Use compression for exports
zdmcli migrate database ... -compression MEDIUM

# Specify tablespace remapping
zdmcli migrate database ... -remap_tablespace USERS:USERS_NEW
```

## Security Considerations

### Encryption in Transit

```bash
# Enable encryption for Data Pump
zdmcli migrate database ... -encryption PASSWORD -encryptionpassword mypassword
```

### Secure Connections

```bash
# Use wallet for database connections
zdmcli configure database ... -sourcewallet /oracle/wallet \
  -targetwallet /oracle/wallet
```

## Conclusion

Oracle ZDM simplifies database migrations by providing:

- Automated migration workflows
- Multiple migration methods
- Comprehensive monitoring
- Minimal downtime capabilities
- Built-in validation and error handling

Choose the appropriate migration type based on your requirements:

- **Logical**: For cross-platform migrations and smaller databases
- **Physical**: For same-platform migrations and large databases
- **Online**: For mission-critical systems requiring minimal downtime

Always test migrations thoroughly in development environments before executing in production.
