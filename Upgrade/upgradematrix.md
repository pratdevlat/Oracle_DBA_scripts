# Oracle Database Upgrade Matrix: 10g to 23ai

## Direct Upgrade Paths Matrix

| Source Version | Target Version | Direct Upgrade | Method | Notes |
|---------------|----------------|----------------|---------|-------|
| **10.1.0.x** | 10.2.0.x | ✅ YES | DBUA/Manual | Standard upgrade |
| **10.1.0.x** | 11.1.0.x | ✅ YES | DBUA/Manual | Skip 10.2 |
| **10.1.0.x** | 11.2.0.x | ✅ YES | DBUA/Manual | Most common |
| **10.1.0.x** | 12.1.0.x | ❌ NO | Multi-hop | Via 11.2 |
| **10.1.0.x** | 12.2.0.x | ❌ NO | Multi-hop | Via 11.2 |
| **10.1.0.x** | 18c | ❌ NO | Multi-hop | Via 11.2→12.2 |
| **10.1.0.x** | 19c | ❌ NO | Multi-hop | Via 11.2→12.2 |
| **10.1.0.x** | 21c | ❌ NO | Multi-hop | Via 11.2→19c |
| **10.1.0.x** | 23ai | ❌ NO | Multi-hop | Via 11.2→19c |
| **10.2.0.x** | 11.1.0.x | ✅ YES | DBUA/Manual | Standard upgrade |
| **10.2.0.x** | 11.2.0.x | ✅ YES | DBUA/Manual | Recommended |
| **10.2.0.x** | 12.1.0.x | ❌ NO | Multi-hop | Via 11.2 |
| **10.2.0.x** | 12.2.0.x | ❌ NO | Multi-hop | Via 11.2 |
| **10.2.0.x** | 18c | ❌ NO | Multi-hop | Via 11.2→12.2 |
| **10.2.0.x** | 19c | ❌ NO | Multi-hop | Via 11.2→12.2 |
| **10.2.0.x** | 21c | ❌ NO | Multi-hop | Via 11.2→19c |
| **10.2.0.x** | 23ai | ❌ NO | Multi-hop | Via 11.2→19c |
| **11.1.0.x** | 11.2.0.x | ✅ YES | DBUA/Manual | Standard upgrade |
| **11.1.0.x** | 12.1.0.x | ✅ YES | DBUA/Manual | Direct supported |
| **11.1.0.x** | 12.2.0.x | ✅ YES | DBUA/Manual | Direct supported |
| **11.1.0.x** | 18c | ❌ NO | Multi-hop | Via 12.2 |
| **11.1.0.x** | 19c | ❌ NO | Multi-hop | Via 12.2 |
| **11.1.0.x** | 21c | ❌ NO | Multi-hop | Via 12.2→19c |
| **11.1.0.x** | 23ai | ❌ NO | Multi-hop | Via 12.2→19c |
| **11.2.0.x** | 12.1.0.x | ✅ YES | DBUA/Manual | Direct supported |
| **11.2.0.x** | 12.2.0.x | ✅ YES | DBUA/Manual | Recommended |
| **11.2.0.x** | 18c | ✅ YES | DBUA/Manual | Direct supported |
| **11.2.0.x** | 19c | ✅ YES | DBUA/Manual | Direct supported |
| **11.2.0.x** | 21c | ❌ NO | Multi-hop | Via 19c |
| **11.2.0.x** | 23ai | ❌ NO | Multi-hop | Via 19c |
| **12.1.0.x** | 12.2.0.x | ✅ YES | DBUA/Manual | Standard upgrade |
| **12.1.0.x** | 18c | ✅ YES | DBUA/Manual | Direct supported |
| **12.1.0.x** | 19c | ✅ YES | DBUA/Manual | Direct supported |
| **12.1.0.x** | 21c | ✅ YES | DBUA/Manual | Direct supported |
| **12.1.0.x** | 23ai | ❌ NO | Multi-hop | Via 19c |
| **12.2.0.x** | 18c | ✅ YES | DBUA/Manual | Direct supported |
| **12.2.0.x** | 19c | ✅ YES | DBUA/Manual | Direct supported |
| **12.2.0.x** | 21c | ✅ YES | DBUA/Manual | Direct supported |
| **12.2.0.x** | 23ai | ✅ YES | DBUA/Manual | Direct supported |
| **18c** | 19c | ✅ YES | DBUA/Manual | Direct supported |
| **18c** | 21c | ✅ YES | DBUA/Manual | Direct supported |
| **18c** | 23ai | ✅ YES | DBUA/Manual | Direct supported |
| **19c** | 21c | ✅ YES | DBUA/Manual | Direct supported |
| **19c** | 23ai | ✅ YES | DBUA/Manual | Direct supported |
| **21c** | 23ai | ✅ YES | DBUA/Manual | Direct supported |

## Multi-Hop Upgrade Paths

### From 10.1.0.x
```
10.1.0.x → 11.2.0.4 → 12.2.0.1 → 19c → 23ai
10.1.0.x → 11.2.0.4 → 19c → 23ai
```

### From 10.2.0.x
```
10.2.0.x → 11.2.0.4 → 12.2.0.1 → 19c → 23ai
10.2.0.x → 11.2.0.4 → 19c → 23ai
```

### From 11.1.0.x
```
11.1.0.x → 12.2.0.1 → 19c → 23ai
11.1.0.x → 11.2.0.4 → 19c → 23ai
```

### From 11.2.0.x to 21c/23ai
```
11.2.0.x → 19c → 21c → 23ai
11.2.0.x → 19c → 23ai
```

### From 12.1.0.x to 23ai
```
12.1.0.x → 19c → 23ai
12.1.0.x → 21c → 23ai
```

## Version-Specific Requirements

### Oracle 10g Requirements
```sql
-- Minimum versions for direct upgrades
10.1.0.5 or higher → 11.2.0.x
10.2.0.4 or higher → 11.2.0.x
```

### Oracle 11g Requirements
```sql
-- Minimum versions for direct upgrades
11.1.0.7 or higher → 12.1.0.x, 12.2.0.x
11.2.0.2 or higher → 12.1.0.x, 12.2.0.x, 18c, 19c
```

### Oracle 12c Requirements
```sql
-- Minimum versions for direct upgrades
12.1.0.2 or higher → 12.2.0.x, 18c, 19c, 21c
12.2.0.1 or higher → 18c, 19c, 21c, 23ai
```

### Oracle 18c/19c Requirements
```sql
-- All versions support direct upgrade to 21c, 23ai
18.3.0.0 or higher → 19c, 21c, 23ai
19.3.0.0 or higher → 21c, 23ai
```

## Recommended Upgrade Paths

### Path 1: Conservative (Minimal Risk)
```
10.x → 11.2.0.4 → 12.2.0.1 → 19c → 23ai
```

### Path 2: Balanced (Recommended)
```
10.x → 11.2.0.4 → 19c → 23ai
11.x → 12.2.0.1 → 19c → 23ai
12.x → 19c → 23ai
```

### Path 3: Aggressive (Fastest)
```
11.2.0.x → 19c → 23ai
12.2.0.x → 23ai (direct)
18c/19c → 23ai (direct)
```

## Upgrade Methods by Version

### DBUA (Database Upgrade Assistant)
```bash
# Available for all supported direct upgrades
dbua -silent -responseFile /path/to/response.rsp
```

### Manual Upgrade Scripts
```sql
-- Pre-12c
@$ORACLE_HOME/rdbms/admin/catupgrd.sql

-- 12c and later
@$ORACLE_HOME/rdbms/admin/catctl.pl catupgrd.sql
```

### AutoUpgrade (19c and later)
```bash
# Available for upgrades to 19c, 21c, 23ai
java -jar autoupgrade.jar -config config.cfg -mode analyze
java -jar autoupgrade.jar -config config.cfg -mode deploy
```

## Platform-Specific Considerations

### Linux/Unix
```bash
# Check compatibility
./runInstaller -executePrereqs -silent
```

### Windows
```cmd
# Check compatibility
setup.exe -executePrereqs -silent
```

### Cloud Platforms
```bash
# OCI - Use cloud-specific tools
oci db system upgrade
```

## Pre-Upgrade Checks by Version

### 10g to 11g
```sql
@$ORACLE_HOME/rdbms/admin/utlu111i.sql
```

### 11g to 12c
```sql
@$ORACLE_HOME/rdbms/admin/utlu121i.sql
```

### 12c to 18c/19c
```sql
@$ORACLE_HOME/rdbms/admin/utlu122i.sql
```

### 18c/19c to 21c/23ai
```sql
@$ORACLE_HOME/rdbms/admin/utlu122i.sql
```

## Unsupported Direct Upgrades

### Cannot Skip More Than 2 Major Versions
```
❌ 10.x → 18c/19c/21c/23ai (skip 11g, 12c)
❌ 11.x → 21c/23ai (skip 12c, 18c/19c)
❌ 12.1.x → 23ai (skip 18c/19c, 21c)
```

### Deprecated Versions
```
❌ 9i → Any version (End of support)
❌ 8i → Any version (End of support)
```

## Quick Decision Matrix

| Current Version | Target: 19c | Target: 21c | Target: 23ai |
|----------------|------------|------------|-------------|
| **10.1.x** | Via 11.2 | Via 11.2→19c | Via 11.2→19c |
| **10.2.x** | Via 11.2 | Via 11.2→19c | Via 11.2→19c |
| **11.1.x** | Via 12.2 | Via 12.2→19c | Via 12.2→19c |
| **11.2.x** | ✅ Direct | Via 19c | Via 19c |
| **12.1.x** | ✅ Direct | ✅ Direct | Via 19c |
| **12.2.x** | ✅ Direct | ✅ Direct | ✅ Direct |
| **18c** | ✅ Direct | ✅ Direct | ✅ Direct |
| **19c** | N/A | ✅ Direct | ✅ Direct |
| **21c** | N/A | N/A | ✅ Direct |

## Commands for Version Check

```sql
-- Check current version
SELECT banner FROM v$version;

-- Check compatibility
SELECT name, value FROM v$parameter WHERE name = 'compatible';

-- Check component versions
SELECT comp_name, version, status FROM dba_registry;

-- Check patch level
SELECT patch_id, patch_uid, version, action, status, description 
FROM dba_registry_sqlpatch ORDER BY action_time DESC;
```

## Upgrade Time Estimates

| Database Size | 10g→11g | 11g→12c | 12c→19c | 19c→23ai |
|--------------|---------|---------|---------|----------|
| < 100GB | 2-4 hrs | 3-6 hrs | 2-4 hrs | 2-4 hrs |
| 100GB-1TB | 4-8 hrs | 6-12 hrs | 4-8 hrs | 4-8 hrs |
| 1TB-10TB | 8-16 hrs | 12-24 hrs | 8-16 hrs | 8-16 hrs |
| > 10TB | 16+ hrs | 24+ hrs | 16+ hrs | 16+ hrs |

*Times include backup, upgrade, and validation phases*
