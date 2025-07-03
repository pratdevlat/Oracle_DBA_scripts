# Ora2Pg Migration Standard Operating Procedure (SOP)

## Overview

This document provides step-by-step instructions for migrating an Oracle database to PostgreSQL using Ora2Pg. It is designed for database administrators, including junior DBAs, to safely and correctly perform the migration.

## Prerequisites

### System Requirements

- Linux/Unix operating system (recommended) or Windows
- Perl 5.10 or higher
- Sufficient disk space for data export (2-3x the size of your Oracle database)
- Network connectivity between source Oracle and target PostgreSQL servers

### Required Software

1. **Oracle Instant Client** (Basic, SDK, and SQL*Plus packages)
1. **PostgreSQL client tools** (psql)
1. **Perl modules**: DBI, DBD::Oracle, DBD::Pg (optional for direct import)
1. **Ora2Pg** software

## Phase 1: Environment Setup

### Step 1.1: Install Oracle Instant Client

```bash
# Download and install Oracle Instant Client (example for version 12.2)
sudo rpm -ivh oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
sudo rpm -ivh oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm
sudo rpm -ivh oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm

# Set environment variables
export ORACLE_HOME=/usr/lib/oracle/12.2/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH

# Add to ~/.bashrc for persistence
echo "export ORACLE_HOME=/usr/lib/oracle/12.2/client64" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
echo "export PATH=\$ORACLE_HOME/bin:\$PATH" >> ~/.bashrc
```

**Why this is important**: Oracle Instant Client provides the necessary libraries for Ora2Pg to connect to Oracle databases.

### Step 1.2: Install Required Perl Modules

```bash
# Install DBD::Oracle
sudo perl -MCPAN -e 'install DBD::Oracle'

# Install DBD::Pg (for direct import)
sudo perl -MCPAN -e 'install DBD::Pg'

# Install other required modules
sudo perl -MCPAN -e 'install Time::HiRes'
sudo perl -MCPAN -e 'install Compress::Zlib'
```

### Step 1.3: Install Ora2Pg

```bash
# Download Ora2Pg (replace X.X with version)
wget https://github.com/darold/ora2pg/archive/refs/tags/vX.X.tar.gz
tar xzf vX.X.tar.gz
cd ora2pg-X.X/

# Install
perl Makefile.PL
make
sudo make install

# Verify installation
ora2pg --version
```

## Phase 2: Migration Assessment

### Step 2.1: Create Project Structure

```bash
# Create migration project
ora2pg --project_base /migration --init_project my_migration

# Navigate to project directory
cd /migration/my_migration
```

This creates a organized directory structure:

- `schema/` - PostgreSQL DDL files
- `sources/` - Original Oracle code
- `data/` - Exported data files
- `config/` - Configuration files
- `reports/` - Assessment reports

### Step 2.2: Configure Database Connection

Edit `config/ora2pg.conf`:

```ini
# Oracle connection settings
ORACLE_DSN  dbi:Oracle:host=oracle_server;sid=ORCL;port=1521
ORACLE_USER system
ORACLE_PWD  oracle_password

# PostgreSQL connection (for direct import)
PG_DSN      dbi:Pg:dbname=target_db;host=pg_server;port=5432
PG_USER     postgres
PG_PWD      pg_password

# Schema to migrate
SCHEMA      HR

# Enable schema export
EXPORT_SCHEMA 1
```

### Step 2.3: Run Migration Assessment

```bash
# Generate migration assessment report
ora2pg -c config/ora2pg.conf -t SHOW_REPORT --estimate_cost > reports/assessment.txt

# Generate HTML report
ora2pg -c config/ora2pg.conf -t SHOW_REPORT --estimate_cost --dump_as_html > reports/assessment.html
```

**Review the assessment report** to understand:

- Migration complexity level (A, B, or C)
- Estimated person-days required
- Objects that need manual intervention
- Unsupported features

## Phase 3: Schema Export

### Step 3.1: Export Database Objects

Run the provided export script or execute manually:

```bash
# Make export script executable
chmod +x export_schema.sh

# Run full schema export
./export_schema.sh

# Or export objects individually:
ora2pg -c config/ora2pg.conf -t TABLE -o schema/tables/tables.sql
ora2pg -c config/ora2pg.conf -t SEQUENCE -o schema/sequences/sequences.sql
ora2pg -c config/ora2pg.conf -t VIEW -o schema/views/views.sql
ora2pg -c config/ora2pg.conf -t TRIGGER -o schema/triggers/triggers.sql
ora2pg -c config/ora2pg.conf -t FUNCTION -o schema/functions/functions.sql
ora2pg -c config/ora2pg.conf -t PROCEDURE -o schema/procedures/procedures.sql
ora2pg -c config/ora2pg.conf -t PACKAGE -o schema/packages/packages.sql
```

### Step 3.2: Review and Fix Schema Issues

Common fixes required:

1. **Data Type Conversions**: Review `MODIFY_TYPE` settings

```ini
# Example: Force specific type conversions
MODIFY_TYPE EMPLOYEES:HIRE_DATE:date,EMPLOYEES:SALARY:numeric(10,2)
```

1. **Reserved Words**: Enable quoting if needed

```ini
PRESERVE_CASE 0
USE_RESERVED_WORDS 1
```

1. **Unsupported Features**: Comment out or rewrite:
- Oracle-specific functions
- Hierarchical queries (CONNECT BY)
- Model clauses
- Pivot operations

## Phase 4: Pre-Import Setup

### Step 4.1: Create Target PostgreSQL Database

```sql
-- Connect as postgres superuser
CREATE DATABASE target_db ENCODING 'UTF8';

-- Create schema if needed
\c target_db
CREATE SCHEMA IF NOT EXISTS hr;

-- Set search path
ALTER DATABASE target_db SET search_path TO hr,public;
```

### Step 4.2: Install Required PostgreSQL Extensions

```sql
-- Required for UUID support
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- For Oracle compatibility (optional)
CREATE EXTENSION IF NOT EXISTS orafce;

-- For spatial data (if needed)
CREATE EXTENSION IF NOT EXISTS postgis;

-- For foreign data wrapper (if using FDW)
CREATE EXTENSION IF NOT EXISTS oracle_fdw;
```

## Phase 5: Schema Import

### Step 5.1: Import Objects in Correct Order

```bash
# 1. Import tables (without constraints and indexes)
psql -U postgres -d target_db -f schema/tables/tables.sql

# 2. Import sequences
psql -U postgres -d target_db -f schema/sequences/sequences.sql

# 3. Import views
psql -U postgres -d target_db -f schema/views/views.sql

# 4. Import types
psql -U postgres -d target_db -f schema/types/types.sql

# 5. Import functions
psql -U postgres -d target_db -f schema/functions/functions.sql

# 6. Import procedures (if PG >= 11)
psql -U postgres -d target_db -f schema/procedures/procedures.sql

# 7. Import packages
psql -U postgres -d target_db -f schema/packages/packages.sql
```

### Step 5.2: Verify Schema Creation

```sql
-- Check all tables created
\dt hr.*

-- Check functions
\df hr.*

-- Check for errors in PostgreSQL log
tail -f /var/log/postgresql/postgresql-*.log
```

## Phase 6: Data Migration

### Step 6.1: Configure Data Export Settings

Edit `config/ora2pg.conf`:

```ini
# Data export configuration
DATA_LIMIT 10000          # Rows per batch
FILE_PER_TABLE 1          # Separate file per table
TRUNCATE_TABLE 1          # Truncate before loading
DISABLE_SEQUENCE 1        # Don't update sequences during load
COPY_FREEZE 1            # Optimize for initial load

# For large tables, use parallel export
PARALLEL_TABLES 4        # Number of tables in parallel
JOBS 4                   # Parallel processes per table
```

### Step 6.2: Export Data

```bash
# Export all data using COPY format (fastest)
ora2pg -c config/ora2pg.conf -t COPY -b data/

# For specific tables only
ora2pg -c config/ora2pg.conf -t COPY -a "EMPLOYEES DEPARTMENTS" -b data/

# Monitor progress
watch -n 1 'ls -lh data/*.dat | tail -20'
```

### Step 6.3: Import Data

```bash
# Disable foreign keys during import
psql -U postgres -d target_db -c "SET session_replication_role = replica;"

# Import data files
for file in data/*.dat; do
    table=$(basename $file .dat)
    echo "Loading $table..."
    psql -U postgres -d target_db -c "\COPY hr.$table FROM '$file'"
done

# Re-enable foreign keys
psql -U postgres -d target_db -c "SET session_replication_role = DEFAULT;"
```

## Phase 7: Post-Migration Tasks

### Step 7.1: Create Constraints and Indexes

```bash
# Import primary keys and unique constraints
psql -U postgres -d target_db -f schema/tables/CONSTRAINTS_tables.sql

# Import indexes (can be parallelized)
ora2pg -c config/ora2pg.conf -t LOAD -i schema/tables/INDEXES_tables.sql -j 4

# Import foreign keys
psql -U postgres -d target_db -f schema/tables/FKEYS_tables.sql

# Import triggers
psql -U postgres -d target_db -f schema/triggers/triggers.sql
```

### Step 7.2: Update Sequences

```bash
# Generate sequence update script
ora2pg -c config/ora2pg.conf -t SEQUENCE_VALUES -o data/sequences_values.sql

# Apply sequence updates
psql -U postgres -d target_db -f data/sequences_values.sql
```

### Step 7.3: Update Statistics

```sql
-- Analyze all tables for query planner
ANALYZE;

-- Or for specific schema
ANALYZE hr.employees;
ANALYZE hr.departments;
```

## Phase 8: Validation

### Step 8.1: Row Count Validation

```bash
# Run automated validation
ora2pg -c config/ora2pg.conf -t TEST_COUNT > reports/row_count_validation.txt

# Review any discrepancies
grep "ERRORS" reports/row_count_validation.txt
```

### Step 8.2: Data Validation

```bash
# Validate data content (first 10000 rows by default)
ora2pg -c config/ora2pg.conf -t TEST_DATA > reports/data_validation.txt

# Check for differences
grep "ERRORS" reports/data_validation.txt
```

### Step 8.3: Object Validation

```bash
# Compare all objects between Oracle and PostgreSQL
ora2pg -c config/ora2pg.conf -t TEST > reports/object_validation.txt
```

## Phase 9: Application Testing

### Step 9.1: Update Application Connection Strings

```properties
# Old Oracle connection
jdbc:oracle:thin:@oracle_server:1521:ORCL

# New PostgreSQL connection
jdbc:postgresql://pg_server:5432/target_db?currentSchema=hr
```

### Step 9.2: Common Application Changes

1. **Sequence Usage**:
   
   ```sql
   -- Oracle
   SELECT employees_seq.NEXTVAL FROM dual;
   
   -- PostgreSQL
   SELECT NEXTVAL('employees_seq');
   ```
1. **Date/Time Functions**:
   
   ```sql
   -- Oracle
   SELECT SYSDATE FROM dual;
   
   -- PostgreSQL
   SELECT CURRENT_TIMESTAMP;
   ```
1. **String Concatenation**:
   
   ```sql
   -- Oracle
   SELECT first_name || ' ' || last_name FROM employees;
   
   -- PostgreSQL (same, but be aware of NULL handling)
   SELECT first_name || ' ' || last_name FROM employees;
   ```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. ORA-24345: A Truncation Error

**Problem**: BLOB/CLOB data exceeds LongReadLen setting
**Solution**:

```ini
# Increase in ora2pg.conf
LONGREADLEN 10485760  # 10MB
DATA_LIMIT 1000      # Reduce batch size
```

#### 2. Out of Memory Errors

**Problem**: Large data exports consuming too much memory
**Solution**:

```ini
DATA_LIMIT 1000      # Reduce batch size
BLOB_LIMIT 100       # Limit BLOB processing
```

#### 3. Character Encoding Issues

**Problem**: Special characters not migrating correctly
**Solution**:

```ini
NLS_LANG AMERICAN_AMERICA.AL32UTF8
CLIENT_ENCODING UTF8
```

#### 4. Foreign Key Violations

**Problem**: Data import fails due to FK constraints
**Solution**:

```bash
# Use DEFER_FKEY option
DEFER_FKEY 1

# Or drop/recreate FKs
DROP_FKEY 1
```

#### 5. Function/Procedure Compilation Errors

**Problem**: PL/SQL code not compatible with PL/pgSQL
**Solution**:

- Review functions in `sources/functions/`
- Manually fix syntax differences
- Common changes needed:
  - Replace `DECODE` with `CASE`
  - Replace `NVL` with `COALESCE`
  - Fix parameter declarations
  - Update exception handling

### Performance Optimization Tips

1. **For Large Tables** (>10GB):
- Use `PARALLEL_TABLES` and `JOBS` for parallel processing
- Consider partitioning in PostgreSQL
- Export/import in chunks using `WHERE` clauses
1. **For Many Small Tables**:
- Set `FILE_PER_TABLE 0` to use single file
- Increase `DATA_LIMIT` to 50000+
1. **For BLOB/CLOB Heavy Tables**:
- Process separately with lower `DATA_LIMIT`
- Consider using `--blob_to_lo` for large objects
- Use `DISABLE_BLOB_EXPORT` to skip initially

## Rollback Procedures

If migration fails at any point:

1. **Schema Issues**: Drop and recreate schema
   
   ```sql
   DROP SCHEMA hr CASCADE;
   CREATE SCHEMA hr;
   ```
1. **Data Issues**: Truncate tables and restart data load
   
   ```sql
   TRUNCATE TABLE hr.employees CASCADE;
   ```
1. **Complete Rollback**: Drop database and restart
   
   ```sql
   DROP DATABASE target_db;
   ```

## Sign-off Checklist

- [ ] All tables migrated successfully
- [ ] Row counts match between source and target
- [ ] All constraints and indexes created
- [ ] Sequences set to correct values
- [ ] Application connection tested
- [ ] Performance baseline established
- [ ] Backup of migrated database completed
- [ ] Documentation updated
- [ ] Stakeholders notified
