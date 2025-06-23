# Oracle GoldenGate Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Administration](#administration)
5. [Configuration](#configuration)
6. [Homogeneous Replication](#homogeneous-replication)
7. [Heterogeneous Replication](#heterogeneous-replication)
8. [Upgrade](#upgrade)
9. [Downgrade](#downgrade)
10. [Troubleshooting](#troubleshooting)
11. [Performance Tuning](#performance-tuning)
12. [Security](#security)
13. [Best Practices](#best-practices)

---

# Overview

## What is Oracle GoldenGate?

Oracle GoldenGate is a comprehensive software package for real-time data integration and replication in heterogeneous IT environments. It enables the replication of data transactions from one database to another with minimal impact on the performance of the operational systems.

### Key Features

- **Real-time data replication**: Captures and delivers transactional data changes in real-time
- **Low impact on source systems**: Minimal performance overhead on production systems
- **Heterogeneous platform support**: Works across different operating systems and database platforms
- **Transformation capabilities**: Ability to transform data during replication
- **Conflict detection and resolution**: Built-in mechanisms to handle data conflicts
- **High availability**: Supports active-active and active-passive configurations

### Use Cases

1. **Zero-downtime migrations**: Migrate databases with minimal downtime
2. **Real-time business intelligence**: Provide real-time data feeds to data warehouses
3. **Disaster recovery**: Maintain synchronized disaster recovery sites
4. **Data distribution**: Distribute data across multiple locations
5. **Operational reporting**: Offload reporting workloads from production systems

---

# Architecture

## Core Components

### Extract Process
The Extract process runs on the source system and performs the following functions:
- **Initial Load Extract**: Captures existing data from source tables
- **Change Data Capture**: Captures ongoing transactional changes
- **Trail File Generation**: Writes captured data to trail files

### Replicat Process
The Replicat process runs on the target system and:
- **Reads trail files**: Processes data from trail files
- **Applies changes**: Applies transactions to target database
- **Maintains transaction integrity**: Ensures ACID properties are maintained

### Manager Process
The Manager process is the control center that:
- **Starts and stops processes**: Manages Extract and Replicat processes
- **Monitors performance**: Tracks process health and performance
- **Manages resources**: Allocates ports and manages trail files

### Collector Process
The Collector process:
- **Receives data over TCP/IP**: Accepts data from remote Extract processes
- **Writes to trail files**: Creates local trail files from received data

### Trail Files
Trail files are:
- **Sequential files**: Contain captured transaction data
- **Platform independent**: Can be read across different platforms
- **Encrypted and compressed**: Support security and space optimization

## Data Flow Architecture

```
Source Database → Extract → Trail Files → Replicat → Target Database
                     ↓
                Manager Process
                     ↓
                Collector Process
```

## Deployment Topologies

### One-Way Replication
- Single source to single target
- Unidirectional data flow
- Common for reporting and DR scenarios

### Bidirectional Replication
- Two-way replication between systems
- Conflict detection and resolution required
- Used for active-active configurations

### Broadcast Replication
- One source to multiple targets
- Data distribution scenario
- Common for data warehousing

### Consolidation Replication
- Multiple sources to single target
- Data aggregation scenario
- Used for data consolidation projects

---

# Installation

## System Requirements

### Hardware Requirements
- **CPU**: Minimum 2 cores, recommended 4+ cores
- **Memory**: Minimum 4GB RAM, recommended 8GB+
- **Disk Space**: Minimum 2GB, recommended 10GB+ for trail files
- **Network**: Reliable network connectivity between source and target

### Software Requirements
- **Operating System**: Linux, Windows, AIX, Solaris, HP-UX
- **Database**: Oracle, SQL Server, MySQL, PostgreSQL, DB2, Teradata
- **Java**: JRE 1.8 or higher (for GoldenGate Director)

## Pre-Installation Tasks

### Database Preparation

#### Oracle Database Preparation
```sql
-- Enable supplemental logging
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;

-- Enable force logging (recommended)
ALTER DATABASE FORCE LOGGING;

-- Create GoldenGate user
CREATE USER gguser IDENTIFIED BY password;

-- Grant necessary privileges
GRANT DBA TO gguser;
GRANT SELECT ANY DICTIONARY TO gguser;
GRANT FLASHBACK ANY TABLE TO gguser;
```

#### SQL Server Database Preparation
```sql
-- Enable change data capture
EXEC sys.sp_cdc_enable_db;

-- Create GoldenGate user
CREATE LOGIN gguser WITH PASSWORD = 'password';
CREATE USER gguser FOR LOGIN gguser;

-- Grant necessary permissions
ALTER ROLE db_owner ADD MEMBER gguser;
```

### Environment Setup
```bash
# Set environment variables
export OGG_HOME=/opt/oracle/goldengate
export LD_LIBRARY_PATH=$OGG_HOME:$LD_LIBRARY_PATH
export PATH=$OGG_HOME:$PATH

# Create necessary directories
mkdir -p $OGG_HOME/dirprm
mkdir -p $OGG_HOME/dirdat
mkdir -p $OGG_HOME/dirrpt
mkdir -p $OGG_HOME/dirchk
```

## Installation Steps

### Interactive Installation
1. **Download GoldenGate software** from Oracle Support
2. **Extract the installation files**
   ```bash
   unzip V123456-01.zip
   cd fbo_ggs_Linux_x64_shiphome/Disk1
   ```
3. **Run the installer**
   ```bash
   ./runInstaller
   ```
4. **Follow the GUI wizard**
   - Select installation type
   - Choose installation directory
   - Configure database connectivity
   - Review and install

### Silent Installation
```bash
# Create response file
cat > gg_install.rsp << EOF
oracle.install.responseFileVersion=/oracle/install/rspfmt_ogginstall_response_schema_v12_1_2
INSTALL_OPTION=ORA12c
SOFTWARE_LOCATION=/opt/oracle/goldengate
START_MANAGER=true
MANAGER_PORT=7809
DATABASE_LOCATION=/opt/oracle/product/12.1.0/dbhome_1
INVENTORY_LOCATION=/opt/oracle/oraInventory
UNIX_GROUP_NAME=oinstall
EOF

# Run silent installation
./runInstaller -silent -responseFile /path/to/gg_install.rsp
```

### Post-Installation Configuration
```bash
# Start GGSCI
cd $OGG_HOME
./ggsci

# Create subdirectories
GGSCI> CREATE SUBDIRS

# Edit Manager parameter file
GGSCI> EDIT PARAMS MGR
```

Manager parameter file example:
```
PORT 7809
DYNAMICPORTLIST 7810-7820
AUTORESTART EXTRACT *, WAITMINUTES 2, RETRIES 5
LAGREPORTHOURS 1
LAGINFOMINUTES 30
LAGCRITICALMINUTES 45
PURGEOLDEXTRACTS ./dirdat/*, USECHECKPOINTS, MINKEEPHOURS 2
```

---

# Administration

## GGSCI Command Line Interface

### Basic Commands
```bash
# Start GGSCI
./ggsci

# Get help
GGSCI> HELP

# Show version
GGSCI> INFO ALL

# View processes
GGSCI> INFO MANAGER
GGSCI> INFO EXTRACT *
GGSCI> INFO REPLICAT *
```

### Manager Process Management
```bash
# Start Manager
GGSCI> START MANAGER

# Stop Manager
GGSCI> STOP MANAGER

# Check Manager status
GGSCI> INFO MANAGER

# View Manager parameters
GGSCI> VIEW PARAMS MGR
```

### Extract Process Management
```bash
# Add Extract
GGSCI> ADD EXTRACT ext1, TRANLOG, BEGIN NOW

# Add Extract trail
GGSCI> ADD EXTTRAIL ./dirdat/lt, EXTRACT ext1

# Start Extract
GGSCI> START EXTRACT ext1

# Stop Extract
GGSCI> STOP EXTRACT ext1

# Check Extract status
GGSCI> INFO EXTRACT ext1, DETAIL

# View Extract statistics
GGSCI> STATS EXTRACT ext1
```

### Replicat Process Management
```bash
# Add Replicat
GGSCI> ADD REPLICAT rep1, EXTTRAIL ./dirdat/rt

# Start Replicat
GGSCI> START REPLICAT rep1

# Stop Replicat
GGSCI> STOP REPLICAT rep1

# Check Replicat status
GGSCI> INFO REPLICAT rep1, DETAIL

# View Replicat statistics
GGSCI> STATS REPLICAT rep1
```

## File Management

### Trail File Management
```bash
# View trail files
GGSCI> INFO EXTRACT ext1, SHOWCH

# Purge old trail files
GGSCI> PURGE EXTTRAIL ./dirdat/lt*

# Show trail file contents
GGSCI> VIEW GGSEVT
```

### Parameter File Management
```bash
# Edit Extract parameters
GGSCI> EDIT PARAMS ext1

# View Extract parameters
GGSCI> VIEW PARAMS ext1

# Edit Replicat parameters
GGSCI> EDIT PARAMS rep1
```

## Monitoring and Maintenance

### Log File Analysis
```bash
# View Extract report
GGSCI> VIEW REPORT ext1

# View Replicat report
GGSCI> VIEW REPORT rep1

# Check process errors
GGSCI> SEND EXTRACT ext1, SHOWTRANS
```

### Performance Monitoring
```bash
# Show lag information
GGSCI> LAG EXTRACT ext1
GGSCI> LAG REPLICAT rep1

# Show statistics
GGSCI> STATS EXTRACT ext1, LATEST
GGSCI> STATS REPLICAT rep1, HOURLY
```

---

# Configuration

## Extract Configuration

### Basic Extract Parameter File
```
EXTRACT ext1
USERID gguser, PASSWORD password
EXTTRAIL ./dirdat/lt
DYNAMICRESOLUTION
GETTRUNCATES
TRANLOGOPTIONS EXCLUDEUSER gguser

TABLE schema1.table1;
TABLE schema1.table2;
TABLE schema2.*;
```

### Advanced Extract Parameters
```
EXTRACT ext1
USERID gguser, PASSWORD password
EXTTRAIL ./dirdat/lt

-- Filtering options
TABLE schema1.employees, WHERE (department_id > 10);
TABLE schema1.orders, FILTER (@DATENOW() - @DATE(order_date) < 30);

-- Column mapping and transformation
TABLE schema1.products, COLSEXCEPT (internal_notes);
TABLE schema1.customers, COLS (customer_id, name, UPPER(email) AS email);

-- Transaction options
TRANLOGOPTIONS EXCLUDEUSER (gguser, batch_user)
TRANLOGOPTIONS INTEGRATEDPARAMS (max_sga_size 256)
```

## Replicat Configuration

### Basic Replicat Parameter File
```
REPLICAT rep1
ASSUMETARGETDEFS
USERID gguser, PASSWORD password
DISCARDFILE ./dirrpt/rep1.dsc, PURGE

MAP schema1.table1, TARGET schema2.table1;
MAP schema1.table2, TARGET schema2.table2;
MAP schema2.*, TARGET schema3.*;
```

### Advanced Replicat Parameters
```
REPLICAT rep1
ASSUMETARGETDEFS
USERID gguser, PASSWORD password
DISCARDFILE ./dirrpt/rep1.dsc, PURGE
HANDLECOLLISIONS

-- Error handling
REPERROR (DEFAULT, EXCEPTION)
REPERROR (1, IGNORE)
REPERROR (1403, IGNORE)

-- Batch processing
BATCHSQL
BATCHTRANSOPS 1000
GROUPTRANSOPS 10000

-- Mapping with transformations
MAP schema1.employees, TARGET schema2.employees,
COLMAP (
    employee_id = employee_id,
    full_name = first_name || ' ' || last_name,
    hire_date = @DATE('YYYY-MM-DD', 'MM/DD/YYYY', hire_date)
);
```

## Data Definition Language (DDL) Support

### DDL Configuration
```
-- In Extract parameter file
EXTRACT ext1
DDL INCLUDE MAPPED OBJNAME schema1.*
DDL INCLUDE UNMAPPED OBJNAME schema1.*

-- In Replicat parameter file
REPLICAT rep1
DDL
DDLOPTIONS ADDTRANDATA
DDLOPTIONS REPORT
```

### DDL Filtering
```
-- Include specific DDL operations
DDL INCLUDE MAPPED OBJTYPE TABLE OPTYPE CREATE, ALTER, DROP

-- Exclude specific DDL operations
DDL EXCLUDE MAPPED OBJTYPE INDEX

-- DDL with transformations
DDL INCLUDE MAPPED, SQLEXEC (
    "CREATE TABLE target_schema.&&1 AS SELECT * FROM source_schema.&&1 WHERE 1=2",
    ONERROR IGNORE
)
```

---

# Homogeneous Replication

## Oracle to Oracle Replication

### Architecture Overview
Homogeneous replication between Oracle databases is the most common GoldenGate implementation, offering:
- Native Oracle integration
- Integrated Extract mode
- Supplemental logging optimization
- Advanced conflict resolution

### Step-by-Step Configuration

#### 1. Source Database Setup
```sql
-- Enable supplemental logging
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;

-- Create GoldenGate user
CREATE USER ggadmin IDENTIFIED BY password;
GRANT DBA TO ggadmin;

-- Add supplemental logging for specific tables
ALTER TABLE hr.employees ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

#### 2. Target Database Setup
```sql
-- Create GoldenGate user
CREATE USER ggadmin IDENTIFIED BY password;
GRANT DBA TO ggadmin;

-- Prepare target tables (if not existing)
CREATE TABLE hr.employees AS SELECT * FROM hr.employees@source_db WHERE 1=2;
```

#### 3. Extract Configuration
```
EXTRACT ext_hr
USERID ggadmin, PASSWORD password
EXTTRAIL ./dirdat/hr
TRANLOGOPTIONS INTEGRATEDPARAMS (max_sga_size 256)

-- Table specifications
TABLE hr.employees;
TABLE hr.departments;
TABLE hr.jobs;
```

#### 4. Data Pump Configuration
```
EXTRACT dpump_hr
USERID ggadmin, PASSWORD password
PASSTHRU
RMTHOST target_server, MGRPORT 7809
RMTTRAIL ./dirdat/hr

TABLE hr.*;
```

#### 5. Replicat Configuration
```
REPLICAT rep_hr
ASSUMETARGETDEFS
USERID ggadmin, PASSWORD password
DISCARDFILE ./dirrpt/rep_hr.dsc, PURGE

-- Conflict resolution
HANDLECOLLISIONS
RESOLVECONFLICT (UPDATEROWEXISTS, (DEFAULT, OVERWRITE))
RESOLVECONFLICT (INSERTROWEXISTS, (DEFAULT, OVERWRITE))

-- Table mapping
MAP hr.employees, TARGET hr.employees;
MAP hr.departments, TARGET hr.departments;
MAP hr.jobs, TARGET hr.jobs;
```

#### 6. Implementation Steps
```bash
# Add Extract
GGSCI> ADD EXTRACT ext_hr, INTEGRATED TRANLOG, BEGIN NOW
GGSCI> ADD EXTTRAIL ./dirdat/hr, EXTRACT ext_hr

# Add Data Pump
GGSCI> ADD EXTRACT dpump_hr, EXTTRAILSOURCE ./dirdat/hr
GGSCI> ADD RMTTRAIL ./dirdat/hr, EXTRACT dpump_hr

# Add Replicat
GGSCI> ADD REPLICAT rep_hr, EXTTRAIL ./dirdat/hr

# Start processes
GGSCI> START EXTRACT ext_hr
GGSCI> START EXTRACT dpump_hr
GGSCI> START REPLICAT rep_hr
```

## SQL Server to SQL Server Replication

### Change Data Capture Setup
```sql
-- Enable CDC on database
USE master;
EXEC sys.sp_cdc_enable_db;

-- Enable CDC on tables
USE source_db;
EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name = 'employees',
    @role_name = NULL;
```

### Extract Configuration for SQL Server
```
EXTRACT ext_emp
SOURCEDB source_db, USERID gguser, PASSWORD password
EXTTRAIL ./dirdat/em
TRANLOGOPTIONS CONVERTUCS2TOUTF8

-- Handle SQL Server specific data types
DBOPTIONS SUPPRESSTRIGGERS
GETTRUNCATES

TABLE dbo.employees;
TABLE dbo.departments;
```

### Replicat Configuration for SQL Server
```
REPLICAT rep_emp
TARGETDB target_db, USERID gguser, PASSWORD password
ASSUMETARGETDEFS
DISCARDFILE ./dirrpt/rep_emp.dsc, PURGE

-- SQL Server specific options
HANDLECOLLISIONS
BATCHSQL
BATCHTRANSOPS 1000

MAP dbo.employees, TARGET dbo.employees;
MAP dbo.departments, TARGET dbo.departments;
```

---

# Heterogeneous Replication

## Oracle to SQL Server Replication

### Challenges in Heterogeneous Replication
- **Data type mapping**: Different data types between platforms
- **Character set conversion**: Handling different character sets
- **NULL handling**: Different NULL representations
- **Case sensitivity**: Handling case-sensitive vs case-insensitive databases

### Configuration Example

#### Extract from Oracle
```
EXTRACT ext_o2s
USERID ggadmin, PASSWORD password
EXTTRAIL ./dirdat/o2s
GETTRUNCATES

-- Data type conversions
SOURCECHARSET UTF8
TARGETCHARSET UTF8

-- Handle Oracle-specific features
FETCHOPTIONS NOUSESNAPSHOT
TRANLOGOPTIONS EXCLUDEUSER ggadmin

TABLE hr.employees, COLS (
    employee_id,
    first_name,
    last_name,
    email,
    hire_date,
    salary DECIMAL(10,2)
);
```

#### Replicat to SQL Server
```
REPLICAT rep_o2s
TARGETDB sqlserver_db, USERID gguser, PASSWORD password
DISCARDFILE ./dirrpt/rep_o2s.dsc, PURGE

-- Character set handling
SOURCECHARSET UTF8
TARGETCHARSET UTF8

-- Handle collisions
HANDLECOLLISIONS
RESOLVECONFLICT (UPDATEROWEXISTS, (DEFAULT, OVERWRITE))

-- Data type mapping
MAP hr.employees, TARGET dbo.employees,
COLMAP (
    employee_id = employee_id,
    first_name = first_name,
    last_name = last_name,
    email = LOWER(email),
    hire_date = @DATE('YYYY-MM-DD', 'DD-MON-YYYY', hire_date),
    salary = @NUMSTR(salary)
);
```

## MySQL to Oracle Replication

### MySQL Configuration
```sql
-- Enable binary logging
SET GLOBAL log_bin = ON;
SET GLOBAL binlog_format = ROW;

-- Create GoldenGate user
CREATE USER 'gguser'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'gguser'@'%';
FLUSH PRIVILEGES;
```

### Extract from MySQL
```
EXTRACT ext_m2o
SOURCEDB mysql_db@mysql_server:3306, USERID gguser, PASSWORD password
EXTTRAIL ./dirdat/m2o

-- MySQL specific parameters
TRANLOGOPTIONS ALTLOGDEST REMOTE
DYNAMICRESOLUTION

-- Handle MySQL data types
FETCHOPTIONS USELATESTVERSION

TABLE employees.employees;
TABLE employees.departments;
```

### Replicat to Oracle
```
REPLICAT rep_m2o
USERID ggadmin, PASSWORD password
ASSUMETARGETDEFS
DISCARDFILE ./dirrpt/rep_m2o.dsc, PURGE

-- Handle MySQL to Oracle conversions
HANDLECOLLISIONS
BATCHSQL

-- Data transformation for compatibility
MAP employees.employees, TARGET hr.employees,
COLMAP (
    employee_id = employee_id,
    first_name = UPPER(first_name),
    last_name = UPPER(last_name),
    email = email,
    hire_date = @DATE('DD-MON-YYYY', 'YYYY-MM-DD', hire_date)
);
```

## Data Type Mapping Tables

### Oracle to SQL Server
| Oracle Type | SQL Server Type | Notes |
|-------------|----------------|-------|
| VARCHAR2(n) | NVARCHAR(n) | Character data |
| NUMBER(p,s) | DECIMAL(p,s) | Numeric data |
| DATE | DATETIME2 | Date/time data |
| CLOB | NVARCHAR(MAX) | Large text |
| BLOB | VARBINARY(MAX) | Binary data |

### Oracle to MySQL
| Oracle Type | MySQL Type | Notes |
|-------------|------------|-------|
| VARCHAR2(n) | VARCHAR(n) | Character data |
| NUMBER(p,s) | DECIMAL(p,s) | Numeric data |
| DATE | DATETIME | Date/time data |
| CLOB | LONGTEXT | Large text |
| BLOB | LONGBLOB | Binary data |

---

# Upgrade

## Planning the Upgrade

### Pre-Upgrade Assessment
1. **Current version inventory**
   ```bash
   GGSCI> INFO ALL
   GGSCI> INFO VERSION
   ```

2. **Compatibility matrix review**
   - Source/target database versions
   - Operating system compatibility
   - GoldenGate version compatibility

3. **Resource requirements**
   - Disk space for new installation
   - Memory requirements
   - Network bandwidth

### Upgrade Strategies

#### Rolling Upgrade (Zero Downtime)
1. **Upgrade target environment first**
2. **Test replication functionality**
3. **Upgrade source environment**
4. **Validate complete setup**

#### Big Bang Upgrade (Planned Downtime)
1. **Stop all GoldenGate processes**
2. **Backup current installation**
3. **Upgrade all components simultaneously**
4. **Restart and validate**

## Step-by-Step Upgrade Process

### Phase 1: Preparation
```bash
# Backup current installation
tar -czf ogg_backup_$(date +%Y%m%d).tar.gz $OGG_HOME

# Document current configuration
GGSCI> INFO ALL > pre_upgrade_status.txt
GGSCI> INFO MANAGER DETAIL >> pre_upgrade_status.txt

# Export parameter files
cd $OGG_HOME/dirprm
tar -czf params_backup.tar.gz *.prm
```

### Phase 2: Target Environment Upgrade
```bash
# Download new GoldenGate version
wget https://updates.oracle.com/download/goldengate_19.1.0.zip

# Create new installation directory
mkdir -p /opt/oracle/goldengate19

# Install new version
unzip goldengate_19.1.0.zip -d /opt/oracle/goldengate19

# Update environment variables
export OGG_HOME=/opt/oracle/goldengate19
```

### Phase 3: Configuration Migration
```bash
# Copy parameter files
cp /opt/oracle/goldengate12/dirprm/*.prm $OGG_HOME/dirprm/

# Create subdirectories
GGSCI> CREATE SUBDIRS

# Update parameter files for new version
GGSCI> EDIT PARAMS MGR
```

### Phase 4: Process Recreation
```bash
# Stop old processes (if running)
# Note: This is done on a rolling basis

# Add processes with new version
GGSCI> ADD REPLICAT rep1, EXTTRAIL ./dirdat/rt, NODBCHECKPOINT

# Start new processes
GGSCI> START REPLICAT rep1
```

### Phase 5: Source Environment Upgrade
```bash
# After target validation, upgrade source
# Follow similar steps as target upgrade

# Update Extract processes
GGSCI> STOP EXTRACT ext1
GGSCI> DELETE EXTRACT ext1
GGSCI> ADD EXTRACT ext1, INTEGRATED TRANLOG, BEGIN NOW
GGSCI> START EXTRACT ext1
```

## Version-Specific Upgrade Considerations

### 12.1 to 12.3 Upgrade
- **Integrated Extract**: Automatically enabled
- **Coordinated Replicat**: New feature available
- **Microservices Architecture**: Optional migration

### 12.3 to 19.1 Upgrade
- **Enhanced security**: New encryption options
- **REST APIs**: Management interface changes
- **Microservices**: Recommended architecture

### Microservices Architecture Migration
```bash
# Create deployment
oggca.sh -silent -responseFile deployment.rsp

# Configure services
curl -X POST http://localhost:9011/services/v2/deployments/ogg/config \
     -H "Content-Type: application/json" \
     -d @config.json
```

---

# Downgrade

## When to Consider Downgrade

### Common Scenarios
- **Performance degradation** with new version
- **Compatibility issues** with existing systems
- **Critical bugs** in new version
- **Rollback requirements** after failed upgrade

## Downgrade Planning

### Pre-Downgrade Checklist
1. **Verify backup availability**
2. **Document current configuration**
3. **Check trail file compatibility**
4. **Plan for data synchronization gaps**

### Downgrade Limitations
- **Trail file format changes** may not be backward compatible
- **New features** will be lost
- **Supplemental logging** requirements may differ

## Downgrade Process

### Phase 1: Assessment
```bash
# Check trail file versions
GGSCI> INFO EXTRACT ext1, SHOWCH

# Verify backup integrity
tar -tzf ogg_backup_20231201.tar.gz

# Document current positions
GGSCI> INFO EXTRACT *, DETAIL > downgrade_positions.txt
```

### Phase 2: Process Shutdown
```bash
# Stop all processes gracefully
GGSCI> STOP EXTRACT *
GGSCI> STOP REPLICAT *
GGSCI> STOP MANAGER
```

### Phase 3: Installation Restoration
```bash
# Remove current installation
rm -rf $OGG_HOME

# Restore previous version
cd /opt/oracle
tar -xzf ogg_backup_20231201.tar.gz

# Update environment variables
export OGG_HOME=/opt/oracle/goldengate12
```

### Phase 4: Configuration Restoration
```bash
# Start GGSCI with previous version
cd $OGG_HOME
./ggsci

# Verify subdirectories
GGSCI> INFO ALL

# Check parameter files
GGSCI> VIEW PARAMS MGR
```

### Phase 5: Process Recreation
```bash
# Add processes if needed
GGSCI> ADD EXTRACT ext1, TRANLOG, BEGIN NOW
GGSCI> ADD EXTTRAIL ./dirdat/lt, EXTRACT ext1

# Start Manager
GGSCI> START MANAGER

# Start processes
GGSCI> START EXTRACT ext1
GGSCI> START REPLICAT rep1
```

## Trail File Compatibility

### Handling Version Mismatches
```bash
# Convert trail files if necessary
GGSCI> CONVERT TRAIL ./dirdat/lt* TO ./dirdat/new_lt*

# Alternative: Use intermediate conversion
EXTRACT conv_ext
SOURCEDB source_db
EXTTRAIL ./dirdat/converted_lt
PASSTHRU
TABLE *.*;
```

---

# Troubleshooting

## Common Issues and Solutions

### Process Startup Issues

#### Manager Won't Start
```bash
# Check Manager parameter file
GGSCI> VIEW PARAMS MGR

# Common issues:
# 1. Port already in use
PORT 7810  # Change port number

# 2. Insufficient privileges
# Grant appropriate OS privileges to GoldenGate user

# 3. Network configuration
# Check firewall and network connectivity
```

#### Extract Won't Start
```bash
# Check Extract status
GGSCI> INFO EXTRACT ext1, DETAIL

# View Extract report
GGSCI> VIEW REPORT ext1

# Common solutions:
# 1. Database connectivity
USERID gguser, PASSWORD password  # Verify credentials

# 2. Supplemental logging
ALTER TABLE schema.table ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

# 3. Archive log mode
ALTER DATABASE ARCHIVELOG;
```

#### Replicat Won't Start
```bash
# Check Replicat status
GGSCI> INFO REPLICAT rep1, DETAIL

# Common issues:
# 1. Target table doesn't exist
GGSCI> EDIT PARAMS rep1
# Add: HANDLECOLLISIONS

# 2. Trail file issues
GGSCI> ALTER REPLICAT rep1, BEGIN NOW

# 3. Checkpoint issues
GGSCI> DELETE REPLICAT rep1
GGSCI> ADD REPLICAT rep1, EXTTRAIL ./dirdat/rt, NODBCHECKPOINT
```

### Performance Issues

#### High Lag Times
```bash
# Check lag
GGSCI> LAG EXTRACT ext1
GGSCI> LAG REPLICAT rep1

# Solutions:
# 1. Parallel processing
REPLICAT rep1
MAXAPPLIEDPARALLEL 4
MAXTRANSOPS 10000

# 2. Batch processing
BATCHSQL
BATCHTRANSOPS 1000

# 3. Optimize trail files
EXTRACT ext1
EXTTRAIL ./dirdat/lt, MEGABYTES 1024
```

#### Slow Apply Rates
```bash
# Enable statistics
GGSCI> START REPLICAT rep1, ATCSN 12345

# Optimize Replicat parameters
REPLICAT rep1
GROUPTRANSOPS 10000
BATCHSQL
BATCHTRANSOPS 1000
BULKLOAD
```

### Data Consistency Issues

#### Missing Transactions
```bash
# Check Extract position
GGSCI> INFO EXTRACT ext1, SHOWCH

# Verify supplemental logging
SELECT * FROM dba_log_groups WHERE owner = 'SCHEMA_NAME';

# Check for filtered transactions
GGSCI> STATS EXTRACT ext1, REPORTDETAIL
```

#### Duplicate Key Errors
```bash
# Enable collision handling
REPLICAT rep1
HANDLECOLLISIONS
RESOLVECONFLICT (INSERTROWEXISTS, (DEFAULT, OVERWRITE))
RESOLVECONFLICT (UPDATEROWEXISTS, (DEFAULT, OVERWRITE))
RESOLVECONFLICT (DELETEROWNOTFOUND, (DEFAULT, IGNORE))
```

## Error Codes and Resolutions

### Common Error Codes

#### OGG-00664: OCI Error
```
Cause: Oracle database connectivity issue
Solution:
1. Check database connectivity
2. Verify user privileges
3. Check TNS configuration
```

#### OGG-01224: TCP/IP Error
```
Cause: Network connectivity issue
Solution:
1. Check network connectivity
2. Verify firewall settings
3. Check port availability
```

#### OGG-00519: Fatal Error
```
Cause: Process abended
Solution:
1. Check process report file
2. Review parameter file
3. Check database logs
```

## Diagnostic Tools

### Log Analysis
```bash
# Extract logs
tail -f $OGG_HOME/ggserr.log

# Process-specific logs
GGSCI> VIEW REPORT ext1
GGSCI> VIEW REPORT rep1

# Manager logs
cat $OGG_HOME/dirrpt/MGR.rpt
```

### Performance Monitoring
```bash
# Real-time statistics
GGSCI> STATS EXTRACT ext1, LATEST, REPORTDETAIL
GGSCI> STATS REPLICAT rep1,
