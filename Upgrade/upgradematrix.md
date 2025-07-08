###  Oracle Database Upgrade Matrix: 10g to 23ai

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

## System Requirements by Database Version

### Oracle 10g Requirements

#### 10.1.0.x (10gR1)
**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 3 (Update 4+), RHEL 4 (all updates)
- Oracle Linux 4, Oracle Linux 5

**SUSE Linux:**
- SUSE 9 SP1+, SUSE 10

**Windows:**
- Windows 2000 SP4
- Windows XP Professional SP2
- Windows Server 2003 (Standard/Enterprise)

**AIX:**
- AIX 5L v5.1 (ML 4+)
- AIX 5L v5.2 (ML 2+)
- AIX 5L v5.3

**Solaris:**
- Solaris 8 (patch 108434-18+)
- Solaris 9 (patch 112233-12+)
- Solaris 10

**HP-UX:**
- HP-UX 11.11 (B.11.11)
- HP-UX 11.23 (B.11.23)

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux packages
rpm -qa | grep -E "(binutils|compat-libstdc|elfutils|gcc|glibc|libaio|libgcc|libstdc|make|sysstat)"

# Required packages for 10.1.0.x
binutils-2.15.92.0.2
compat-libstdc++-33-3.2.3
elfutils-libelf-0.97
gcc-3.4.3
gcc-c++-3.4.3
glibc-2.3.4-2.9
glibc-devel-2.3.4-2.9
libaio-0.3.105
libgcc-3.4.3
libstdc++-3.4.3
libstdc++-devel-3.4.3
make-3.80
sysstat-5.0.5

# Kernel parameters check
cat /proc/sys/kernel/shmmax    # >= 2147483648
cat /proc/sys/kernel/shmmni    # >= 4096
cat /proc/sys/kernel/shmall    # >= 2097152
cat /proc/sys/fs/file-max      # >= 65536
cat /proc/sys/net/ipv4/ip_local_port_range  # 1024 65000
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 512 MB (1 GB recommended)
Disk Space: 1.5 GB for software + database size
Swap: 2x RAM or 2 GB minimum
CPU: 400 MHz processor (x86 or x86_64)
```

**Pre-Upgrade Checks:**
```sql
-- Check minimum version for upgrade
SELECT banner FROM v$version; -- Must be 10.1.0.5 or higher
-- Check timezone file version
SELECT version FROM v$timezone_file;
-- Check character set
SELECT value FROM nls_database_parameters WHERE parameter = 'NLS_CHARACTERSET';
```

#### 10.2.0.x (10gR2)
**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 3 (Update 6+), RHEL 4 (all updates), RHEL 5
- Oracle Linux 4, Oracle Linux 5

**SUSE Linux:**
- SUSE 9 SP3+, SUSE 10, SUSE 11

**Windows:**
- Windows 2000 SP4
- Windows XP Professional SP2+
- Windows Server 2003 (Standard/Enterprise/R2)
- Windows Vista (Business/Enterprise/Ultimate)
- Windows Server 2008

**AIX:**
- AIX 5L v5.1 (ML 9+)
- AIX 5L v5.2 (ML 5+)
- AIX 5L v5.3 (all MLs)

**Solaris:**
- Solaris 8 (patch 108434-18+)
- Solaris 9 (patch 112233-12+)
- Solaris 10 (all updates)

**HP-UX:**
- HP-UX 11.11 (B.11.11)
- HP-UX 11.23 (B.11.23)
- HP-UX 11.31 (B.11.31)

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 4 packages
binutils-2.15.92.0.2
compat-libstdc++-33-3.2.3
elfutils-libelf-0.97
gcc-3.4.4
gcc-c++-3.4.4
glibc-2.3.4-2.13
glibc-devel-2.3.4-2.13
libaio-0.3.105
libgcc-3.4.4
libstdc++-3.4.4
libstdc++-devel-3.4.4
make-3.80
sysstat-5.0.5

# RHEL/Oracle Linux 5 packages
binutils-2.17.50.0.6
compat-libstdc++-33-3.2.3
elfutils-libelf-0.125
gcc-4.1.1
gcc-c++-4.1.1
glibc-2.5-12
glibc-devel-2.5-12
libaio-0.3.106
libgcc-4.1.1
libstdc++-4.1.1
libstdc++-devel-4.1.1
make-3.81
sysstat-7.0.0

# Package installation
yum install binutils compat-libstdc++-33 elfutils-libelf gcc gcc-c++ \
    glibc glibc-devel libaio libgcc libstdc++ libstdc++-devel make sysstat

# Kernel parameters
echo "kernel.shmmax = 4294967296" >> /etc/sysctl.conf
echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
echo "kernel.shmall = 1048576" >> /etc/sysctl.conf
echo "fs.file-max = 65536" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 1024 65000" >> /etc/sysctl.conf
sysctl -p
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 1 GB (2 GB recommended)
Disk Space: 1.5 GB for software + database size
Swap: 2x RAM or 2 GB minimum
CPU: 550 MHz processor (x86 or x86_64)
```

**Pre-Upgrade Checks:**
```sql
-- Must be 10.2.0.4 or higher
SELECT banner FROM v$version;
-- Check ASM if used
SELECT name, state FROM v$asm_diskgroup;
```

### Oracle 11g Requirements

#### 11.1.0.x (11gR1)
**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 4 (Update 7+), RHEL 5 (all updates)
- Oracle Linux 4 (Update 7+), Oracle Linux 5

**SUSE Linux:**
- SUSE 10 SP1+, SUSE 11

**Windows:**
- Windows XP Professional SP2+
- Windows Server 2003 (Standard/Enterprise/R2) SP2+
- Windows Vista (Business/Enterprise/Ultimate) SP1+
- Windows Server 2008

**AIX:**
- AIX 5L v5.3 (TL 7+)
- AIX 6.1 (all TLs)

**Solaris:**
- Solaris 10 (Update 6+)
- Solaris 11

**HP-UX:**
- HP-UX 11.23 (B.11.23)
- HP-UX 11.31 (B.11.31)

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 5 packages for 11.1.0.x
binutils-2.17.50.0.6
compat-libstdc++-33-3.2.3
elfutils-libelf-0.125
elfutils-libelf-devel-0.125
gcc-4.1.2
gcc-c++-4.1.2
glibc-2.5-24
glibc-common-2.5
glibc-devel-2.5
glibc-headers-2.5
kernel-headers-2.6.18
libaio-0.3.106
libaio-devel-0.3.106
libgcc-4.1.2
libgomp-4.1.2
libstdc++-4.1.2
libstdc++-devel-4.1.2
make-3.81
sysstat-7.0.2

# Additional packages for 11g
unixODBC-2.2.11
unixODBC-devel-2.2.11

# Installation command
yum install binutils compat-libstdc++-33 elfutils-libelf \
    elfutils-libelf-devel gcc gcc-c++ glibc glibc-common \
    glibc-devel glibc-headers kernel-headers libaio \
    libaio-devel libgcc libgomp libstdc++ libstdc++-devel \
    make sysstat unixODBC unixODBC-devel

# Kernel parameters for 11g
echo "kernel.shmmax = 4398046511104" >> /etc/sysctl.conf
echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
echo "kernel.shmall = 1073741824" >> /etc/sysctl.conf
echo "fs.file-max = 6815744" >> /etc/sysctl.conf
echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
echo "net.core.rmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.rmem_max = 4194304" >> /etc/sysctl.conf
echo "net.core.wmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.wmem_max = 1048576" >> /etc/sysctl.conf
sysctl -p
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 1 GB (2 GB recommended)
Disk Space: 3.5 GB for software
Swap: 2x RAM (up to 16 GB)
CPU: 1 GHz processor (x86_64 only)
Temp Space: 400 MB in /tmp
```

**Pre-Upgrade Checks:**
```sql
-- Must be 11.1.0.7 or higher for 12c upgrade
SELECT banner FROM v$version;
-- Check for deprecated features
@$ORACLE_HOME/rdbms/admin/utlu112i.sql
```

#### 11.2.0.x (11gR2)
**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 4 (Update 8+), RHEL 5 (all updates), RHEL 6
- Oracle Linux 4 (Update 8+), Oracle Linux 5, Oracle Linux 6

**SUSE Linux:**
- SUSE 10 SP2+, SUSE 11, SUSE 11 SP1

**Windows:**
- Windows XP Professional SP3
- Windows Server 2003 (Standard/Enterprise/R2) SP2+
- Windows Vista (Business/Enterprise/Ultimate) SP2+
- Windows Server 2008 SP2+
- Windows 7 (Professional/Enterprise/Ultimate)
- Windows Server 2008 R2

**AIX:**
- AIX 5L v5.3 (TL 8+)
- AIX 6.1 (TL 2+)
- AIX 7.1

**Solaris:**
- Solaris 10 (Update 6+)
- Solaris 11

**HP-UX:**
- HP-UX 11.23 (B.11.23)
- HP-UX 11.31 (B.11.31)

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 5 packages for 11.2.0.x
binutils-2.17.50.0.6
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-4.1.2
gcc-c++-4.1.2
glibc-2.5-58
glibc-devel-2.5-58
kernel-headers-2.6.18
libaio-0.3.106
libaio-devel-0.3.106
libgcc-4.1.2
libstdc++-4.1.2
libstdc++-devel-4.1.2
make-3.81
sysstat-7.0.2

# RHEL/Oracle Linux 6 packages for 11.2.0.x
binutils-2.20.51.0.2
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-4.4.4
gcc-c++-4.4.4
glibc-2.12-1.7
glibc-devel-2.12-1.7
ksh-20100621
libaio-0.3.107
libaio-devel-0.3.107
libgcc-4.4.4
libstdc++-4.4.4
libstdc++-devel-4.4.4
make-3.81
sysstat-9.0.4

# Installation for RHEL 6
yum install binutils compat-libcap1 compat-libstdc++-33 \
    gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel \
    libgcc libstdc++ libstdc++-devel make sysstat

# Additional packages for x86_64
yum install glibc.i686 libgcc.i686 libstdc++.i686 libaio.i686

# Kernel parameters for 11.2.0.x
echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.conf
echo "fs.file-max = 6815744" >> /etc/sysctl.conf
echo "kernel.shmall = 2097152" >> /etc/sysctl.conf
echo "kernel.shmmax = 536870912" >> /etc/sysctl.conf
echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
echo "kernel.sem = 250 32000 100 128" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
echo "net.core.rmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.rmem_max = 4194304" >> /etc/sysctl.conf
echo "net.core.wmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.wmem_max = 1048576" >> /etc/sysctl.conf
sysctl -p

# User limits
echo "oracle soft nproc 2047" >> /etc/security/limits.conf
echo "oracle hard nproc 16384" >> /etc/security/limits.conf
echo "oracle soft nofile 1024" >> /etc/security/limits.conf
echo "oracle hard nofile 65536" >> /etc/security/limits.conf
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 1 GB (4 GB recommended)
Disk Space: 3.5 GB for software
Swap: Equal to RAM (up to 16 GB)
CPU: 1 GHz processor (x86_64 only)
Temp Space: 1 GB in /tmp
```

**Pre-Upgrade Checks:**
```sql
-- Must be 11.2.0.2 or higher for direct upgrade to 18c/19c
SELECT banner FROM v$version;
-- Check compatible parameter
SELECT value FROM v$parameter WHERE name = 'compatible';
-- Check for invalid objects
SELECT COUNT(*) FROM dba_objects WHERE status = 'INVALID';
```

### Oracle 12c Requirements

#### 12.1.0.x (12cR1)
**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 5 (Update 6+), RHEL 6 (all updates), RHEL 7
- Oracle Linux 5 (Update 6+), Oracle Linux 6, Oracle Linux 7

**SUSE Linux:**
- SUSE 11 SP1+, SUSE 12

**Windows:**
- Windows 7 (Professional/Enterprise/Ultimate) SP1
- Windows 8 (Pro/Enterprise)
- Windows Server 2008 R2 SP1
- Windows Server 2012
- Windows Server 2012 R2

**AIX:**
- AIX 6.1 (TL 6+)
- AIX 7.1 (all TLs)

**Solaris:**
- Solaris 10 (Update 9+)
- Solaris 11, 11.1, 11.2

**HP-UX:**
- HP-UX 11.31 (B.11.31)

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 6 packages for 12.1.0.x
binutils-2.20.51.0.2
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-4.4.7
gcc-c++-4.4.7
glibc-2.12
glibc-devel-2.12
ksh-20120801
libaio-0.3.107
libaio-devel-0.3.107
libgcc-4.4.7
libstdc++-4.4.7
libstdc++-devel-4.4.7
libXi-1.7.2
libXtst-1.2.2
make-3.81
sysstat-9.0.4

# RHEL/Oracle Linux 7 packages for 12.1.0.x
binutils-2.23.52.0.1
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-4.8.2
gcc-c++-4.8.2
glibc-2.17
glibc-devel-2.17
ksh-20120801
libaio-0.3.109
libaio-devel-0.3.109
libgcc-4.8.2
libstdc++-4.8.2
libstdc++-devel-4.8.2
libXi-1.7.4
libXtst-1.2.2
make-3.82
sysstat-10.1.5

# Installation for RHEL 7
yum install binutils compat-libcap1 compat-libstdc++-33 \
    gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel \
    libgcc libstdc++ libstdc++-devel libXi libXtst make sysstat

# Additional 32-bit packages for x86_64
yum install glibc.i686 libgcc.i686 libstdc++.i686 libaio.i686

# CVU (Cluster Verification Utility) packages
yum install bc bind-utils nfs-utils smartmontools

# Kernel parameters for 12c
echo "fs.aio-max-nr = 1048576" >> /etc/sysctl.conf
echo "fs.file-max = 6815744" >> /etc/sysctl.conf
echo "kernel.shmall = 2097152" >> /etc/sysctl.conf
echo "kernel.shmmax = 4398046511104" >> /etc/sysctl.conf
echo "kernel.shmmni = 4096" >> /etc/sysctl.conf
echo "kernel.sem = 250 32000 100 128" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 9000 65500" >> /etc/sysctl.conf
echo "net.core.rmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.rmem_max = 4194304" >> /etc/sysctl.conf
echo "net.core.wmem_default = 262144" >> /etc/sysctl.conf
echo "net.core.wmem_max = 1048576" >> /etc/sysctl.conf
echo "kernel.panic_on_oops = 1" >> /etc/sysctl.conf
sysctl -p

# Security limits
echo "oracle soft nofile 1024" >> /etc/security/limits.conf
echo "oracle hard nofile 65536" >> /etc/security/limits.conf
echo "oracle soft nproc 2047" >> /etc/security/limits.conf
echo "oracle hard nproc 16384" >> /etc/security/limits.conf
echo "oracle soft stack 10240" >> /etc/security/limits.conf
echo "oracle hard stack 32768" >> /etc/security/limits.conf
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 2 GB (4 GB recommended)
Disk Space: 6.4 GB for software
Swap: Equal to RAM (between 1-16 GB)
CPU: 1 GHz processor (64-bit only)
Temp Space: 1 GB in /tmp
```

**Pre-Upgrade Checks:**
```sql
-- Must be 12.1.0.2 or higher for some upgrades
SELECT banner FROM v$version;
-- Check PDB configuration
SELECT name, open_mode FROM v$pdbs;
-- Check for deprecated parameters
SELECT name, value FROM v$parameter WHERE isdeprecated = 'TRUE';
```

#### 12.2.0.x (12cR2)
**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 6 (Update 4+), RHEL 7 (all updates)
- Oracle Linux 6 (Update 4+), Oracle Linux 7

**SUSE Linux:**
- SUSE 12 SP1+

**Windows:**
- Windows 7 (Professional/Enterprise/Ultimate) SP1
- Windows 8.1 (Pro/Enterprise)
- Windows 10 (Pro/Enterprise/Education)
- Windows Server 2012 R2
- Windows Server 2016

**AIX:**
- AIX 7.1 (TL 1+)
- AIX 7.2

**Solaris:**
- Solaris 11.3+

**HP-UX:**
- HP-UX 11.31 (B.11.31)

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 7 packages for 12.2.0.x
bc-1.06.95
binutils-2.25.1
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-4.8.5
gcc-c++-4.8.5
glibc-2.17
glibc-devel-2.17
ksh-20120801
libaio-0.3.109
libaio-devel-0.3.109
libgcc-4.8.5
libstdc++-4.8.5
libstdc++-devel-4.8.5
libXi-1.7.4
libXtst-1.2.2
make-3.82
nfs-utils-1.3.0
net-tools-2.0
smartmontools-6.2
sysstat-10.1.5
xdpyinfo-1.3.2

# Installation for RHEL 7 (12.2.0.x)
yum install bc binutils compat-libcap1 compat-libstdc++-33 \
    gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel \
    libgcc libstdc++ libstdc++-devel libXi libXtst make \
    nfs-utils net-tools smartmontools sysstat xdpyinfo

# For multitenant architecture support
yum install psmisc

# X11 packages for GUI installation
yum groupinstall "X Window System"
yum install xorg-x11-xauth xorg-x11-fonts-* xorg-x11-font-utils

# Kernel parameters for 12.2.0.x
cat >> /etc/sysctl.conf << 'EOF'
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.panic_on_oops = 1
EOF
sysctl -p

# Security limits for 12.2.0.x
cat >> /etc/security/limits.conf << 'EOF'
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft stack 10240
oracle hard stack 32768
oracle soft memlock 134217728
oracle hard memlock 134217728
EOF

# Create oracle user and groups
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
useradd -u 54321 -g oinstall -G dba,oper oracle
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 2 GB (8 GB recommended)
Disk Space: 7.5 GB for software
Swap: Equal to RAM (between 1-16 GB)
CPU: 1 GHz processor (64-bit only)
Temp Space: 1 GB in /tmp
```

**Pre-Upgrade Checks:**
```sql
-- Must be 12.2.0.1 or higher for 23ai direct upgrade
SELECT banner FROM v$version;
-- Check multitenant configuration
SELECT cdb, con_id FROM v$database;
-- Check for timezone file version
SELECT version FROM v$timezone_file;
```

### Oracle 18c Requirements

**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 6 (Update 8+), RHEL 7 (all updates), RHEL 8
- Oracle Linux 6 (Update 8+), Oracle Linux 7, Oracle Linux 8

**SUSE Linux:**
- SUSE 12 SP3+, SUSE 15

**Windows:**
- Windows Server 2012 R2
- Windows Server 2016
- Windows Server 2019

**AIX:**
- AIX 7.1 (TL 4+)
- AIX 7.2 (all TLs)

**Solaris:**
- Solaris 11.4+

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 7 packages for 18c
bc-1.06.95
binutils-2.27
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-4.8.5
gcc-c++-4.8.5
glibc-2.17
glibc-devel-2.17
ksh-20120801
libaio-0.3.109
libaio-devel-0.3.109
libgcc-4.8.5
libstdc++-4.8.5
libstdc++-devel-4.8.5
libXi-1.7.4
libXtst-1.2.2
make-3.82
nfs-utils-1.3.0
net-tools-2.0
smartmontools-6.2
sysstat-10.1.5
xdpyinfo-1.3.2

# RHEL/Oracle Linux 8 packages for 18c
bc-1.07.1
binutils-2.30
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-8.2.1
gcc-c++-8.2.1
glibc-2.28
glibc-devel-2.28
ksh-20120801
libaio-0.3.112
libaio-devel-0.3.112
libgcc-8.2.1
libstdc++-8.2.1
libstdc++-devel-8.2.1
libXi-1.7.9
libXtst-1.2.3
make-4.2.1
nfs-utils-2.3.3
net-tools-2.0
smartmontools-6.6
sysstat-11.7.3
xdpyinfo-1.3.2

# Installation for RHEL 8
dnf install bc binutils compat-libcap1 compat-libstdc++-33 \
    gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel \
    libgcc libstdc++ libstdc++-devel libXi libXtst make \
    nfs-utils net-tools smartmontools sysstat xdpyinfo

# Additional packages for Oracle 18c
dnf install libnsl libnsl.i686 libnsl2 libnsl2.i686

# Kernel parameters for 18c
cat >> /etc/sysctl.conf << 'EOF'
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.panic_on_oops = 1
vm.swappiness = 1
vm.dirty_background_ratio = 3
vm.dirty_ratio = 80
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
EOF
sysctl -p
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 2 GB (8 GB recommended)
Disk Space: 8.5 GB for software
Swap: Equal to RAM (between 1-16 GB)
CPU: 1 GHz 64-bit processor
Temp Space: 1 GB in /tmp
```

### Oracle 19c Requirements

**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 6 (Update 10+), RHEL 7 (all updates), RHEL 8, RHEL 9
- Oracle Linux 6 (Update 10+), Oracle Linux 7, Oracle Linux 8, Oracle Linux 9

**SUSE Linux:**
- SUSE 12 SP4+, SUSE 15 SP1+

**Windows:**
- Windows Server 2012 R2
- Windows Server 2016
- Windows Server 2019
- Windows Server 2022

**AIX:**
- AIX 7.1 (TL 5+)
- AIX 7.2 (all TLs)
- AIX 7.3

**Solaris:**
- Solaris 11.4+

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 8 packages for 19c
bc-1.07.1
binutils-2.30
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-8.3.1
gcc-c++-8.3.1
glibc-2.28
glibc-devel-2.28
ksh-20120801
libaio-0.3.112
libaio-devel-0.3.112
libgcc-8.3.1
libstdc++-8.3.1
libstdc++-devel-8.3.1
libXi-1.7.9
libXtst-1.2.3
make-4.2.1
nfs-utils-2.3.3
net-tools-2.0
smartmontools-6.6
sysstat-11.7.3
xdpyinfo-1.3.2

# RHEL/Oracle Linux 9 packages for 19c
bc-1.07.1
binutils-2.35.2
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-11.2.1
gcc-c++-11.2.1
glibc-2.34
glibc-devel-2.34
ksh-20120801
libaio-0.3.111
libaio-devel-0.3.111
libgcc-11.2.1
libstdc++-11.2.1
libstdc++-devel-11.2.1
libXi-1.7.10
libXtst-1.2.3
make-4.3
nfs-utils-2.5.4
net-tools-2.0
smartmontools-7.2
sysstat-12.5.4
xdpyinfo-1.3.2

# Installation for RHEL 9
dnf install bc binutils compat-libcap1 compat-libstdc++-33 \
    gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel \
    libgcc libstdc++ libstdc++-devel libXi libXtst make \
    nfs-utils net-tools smartmontools sysstat xdpyinfo \
    libnsl libnsl.i686 libnsl2 libnsl2.i686

# Additional packages for 19c features
dnf install policycoreutils-python-utils

# Kernel parameters for 19c
cat >> /etc/sysctl.conf << 'EOF'
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.panic_on_oops = 1
vm.swappiness = 1
vm.dirty_background_ratio = 3
vm.dirty_ratio = 80
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
EOF
sysctl -p
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 2 GB (8 GB recommended)
Disk Space: 9.5 GB for software
Swap: Equal to RAM (between 1-16 GB)
CPU: 1 GHz 64-bit processor
Temp Space: 1 GB in /tmp
```

### Oracle 21c Requirements

**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 7 (Update 6+), RHEL 8, RHEL 9
- Oracle Linux 7 (Update 6+), Oracle Linux 8, Oracle Linux 9

**SUSE Linux:**
- SUSE 12 SP5+, SUSE 15 SP2+

**Windows:**
- Windows Server 2016
- Windows Server 2019
- Windows Server 2022

**AIX:**
- AIX 7.2 (TL 3+)
- AIX 7.3

**Solaris:**
- Solaris 11.4+

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 8 packages for 21c
bc-1.07.1
binutils-2.30
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-8.5.0
gcc-c++-8.5.0
glibc-2.28
glibc-devel-2.28
ksh-20120801
libaio-0.3.112
libaio-devel-0.3.112
libgcc-8.5.0
libstdc++-8.5.0
libstdc++-devel-8.5.0
libXi-1.7.10
libXtst-1.2.3
make-4.2.1
nfs-utils-2.3.3
net-tools-2.0
smartmontools-7.1
sysstat-11.7.3
xdpyinfo-1.3.2

# Installation for RHEL 8 (21c)
dnf install bc binutils compat-libcap1 compat-libstdc++-33 \
    gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel \
    libgcc libstdc++ libstdc++-devel libXi libXtst make \
    nfs-utils net-tools smartmontools sysstat xdpyinfo \
    libnsl libnsl.i686 libnsl2 libnsl2.i686

# Kernel parameters for 21c (same as 19c)
cat >> /etc/sysctl.conf << 'EOF'
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.panic_on_oops = 1
vm.swappiness = 1
vm.dirty_background_ratio = 3
vm.dirty_ratio = 80
EOF
sysctl -p
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 2 GB (8 GB recommended)
Disk Space: 10.7 GB for software
Swap: Equal to RAM (between 1-16 GB)
CPU: 1 GHz 64-bit processor
Temp Space: 1 GB in /tmp
```

### Oracle 23ai Requirements

**Operating System Support:**

**RHEL/Oracle Linux:**
- RHEL 8 (Update 4+), RHEL 9
- Oracle Linux 8 (Update 4+), Oracle Linux 9

**SUSE Linux:**
- SUSE 15 SP3+

**Ubuntu:**
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS

**Windows:**
- Windows Server 2019
- Windows Server 2022

**Cloud Platforms:**
- Oracle Cloud Infrastructure (OCI)
- Amazon Web Services (AWS)
- Microsoft Azure
- Google Cloud Platform (GCP)

**Linux Package Requirements:**
```bash
# RHEL/Oracle Linux 8/9 packages for 23ai
bc-1.07.1
binutils-2.35
compat-libcap1-1.10
compat-libstdc++-33-3.2.3
gcc-11.3.1
gcc-c++-11.3.1
glibc-2.34
glibc-devel-2.34
ksh-20120801
libaio-0.3.111
libaio-devel-0.3.111
libgcc-11.3.1
libstdc++-11.3.1
libstdc++-devel-11.3.1
libXi-1.7.10
libXtst-1.2.3
make-4.3
nfs-utils-2.5.4
net-tools-2.0
smartmontools-7.3
sysstat-12.5.4
xdpyinfo-1.3.2

# Ubuntu packages for 23ai
apt-get update
apt-get install -y bc binutils build-essential gcc g++ \
    libc6-dev ksh libaio1 libaio-dev libgcc-s1 libstdc++6 \
    libstdc++-11-dev libxi6 libxtst6 make nfs-common \
    net-tools smartmontools sysstat x11-utils

# Installation for RHEL 9 (23ai)
dnf install bc binutils compat-libcap1 compat-libstdc++-33 \
    gcc gcc-c++ glibc glibc-devel ksh libaio libaio-devel \
    libgcc libstdc++ libstdc++-devel libXi libXtst make \
    nfs-utils net-tools smartmontools sysstat xdpyinfo \
    libnsl libnsl.i686 libnsl2 libnsl2.i686

# AI-specific packages
dnf install python3 python3-pip python3-devel
pip3 install numpy pandas scikit-learn

# Kernel parameters for 23ai
cat >> /etc/sysctl.conf << 'EOF'
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
kernel.panic_on_oops = 1
vm.swappiness = 1
vm.dirty_background_ratio = 3
vm.dirty_ratio = 80
# AI workload optimizations
vm.nr_hugepages = 1024
kernel.numa_balancing = 0
EOF
sysctl -p

# Security limits for 23ai
cat >> /etc/security/limits.conf << 'EOF'
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft stack 10240
oracle hard stack 32768
oracle soft memlock 134217728
oracle hard memlock 134217728
# AI workload limits
oracle soft as unlimited
oracle hard as unlimited
EOF
```

**Hardware Requirements:**
```bash
# Minimum Requirements
RAM: 4 GB (16 GB recommended for AI features)
Disk Space: 12.8 GB for software
Swap: Equal to RAM (between 1-32 GB)
CPU: 2 GHz 64-bit processor (multi-core recommended)
Temp Space: 2 GB in /tmp
# For AI features: GPU support recommended
```

## Platform-Specific Package Commands

### AIX Package Requirements
```bash
# AIX 7.1/7.2/7.3 filesets
bos.adt.base
bos.adt.lib
bos.adt.libm
bos.perf.libperfstat
bos.perf.perfstat
bos.perf.proctools
rsct.basic.hacmp
rsct.compat.basic.hacmp
xlC.aix61.rte
xlC.rte

# Check AIX packages
lslpp -l | grep -E "(xlC|bos\.adt)"

# Install missing packages
smitty install_software
```

### Windows Requirements
```cmd
# Windows components check
dism /online /get-features | findstr -i "NetFx"
dism /online /get-features | findstr -i "IIS"

# Required Windows features
.NET Framework 4.7.2 or higher
Microsoft Visual C++ 2017 Redistributable
Windows PowerShell 5.1 or higher

# PowerShell verification
$PSVersionTable.PSVersion
```

### Solaris Package Requirements
```bash
# Solaris 11.4+ packages
pkg list gcc
pkg list system/header
pkg list system/library/math
pkg list system/library/c++/sunpro

# Install required packages
pkg install gcc-7
pkg install system/header
pkg install developer/build/make
```

## Cross-Platform Validation Script
```bash
#!/bin/bash
# Platform detection and package validation

OS=$(uname -s)
case $OS in
  Linux)
    if [ -f /etc/redhat-release ]; then
      echo "RHEL/Oracle Linux detected"
      rpm -qa | grep -E "(gcc|glibc|libaio|binutils)"
    elif [ -f /etc/SuSE-release ]; then
      echo "SUSE detected"
      zypper search --installed-only gcc glibc libaio
    elif [ -f /etc/lsb-release ]; then
      echo "Ubuntu detected"
      dpkg -l | grep -E "(gcc|libc6|libaio)"
    fi
    ;;
  AIX)
    echo "AIX detected"
    lslpp -l | grep -E "(xlC|bos\.adt)"
    ;;
  SunOS)
    echo "Solaris detected"
    pkg list | grep -E "(gcc|system/library)"
    ;;
  *)
    echo "Unsupported OS: $OS"
    ;;
esac
```

**Pre-Upgrade Checks:**
```sql
-- All 18c versions support upgrade to 19c/21c/23ai
SELECT banner FROM v$version;
-- Check patch level
SELECT patch_id, version, status FROM dba_registry_sqlpatch;
```


## Version Compatibility Matrix

```sql
-- Check compatibility before upgrade
SELECT 
    CASE 
        WHEN SUBSTR(banner,1,INSTR(banner,' ')-1) = 'Oracle' THEN
            SUBSTR(banner,INSTR(banner,'Release')+8,10)
        ELSE 'Unknown'
    END as current_version
FROM v$version WHERE banner LIKE 'Oracle%';

-- Memory requirements check
SELECT 
    ROUND(value/1024/1024/1024,2) as sga_gb,
    ROUND((SELECT value FROM v$parameter WHERE name = 'pga_aggregate_target')/1024/1024/1024,2) as pga_gb
FROM v$parameter WHERE name = 'sga_target';
```

## Minimum Version Requirements for Direct Upgrades

| Source | Target | Minimum Source Version | Notes |
|--------|--------|----------------------|-------|
| 10.1.x | 11.2.x | 10.1.0.5 | Must apply patches |
| 10.2.x | 11.2.x | 10.2.0.4 | Must apply patches |
| 11.1.x | 12.1.x | 11.1.0.7 | Critical patches required |
| 11.1.x | 12.2.x | 11.1.0.7 | Critical patches required |
| 11.2.x | 12.1.x | 11.2.0.2 | Timezone updates needed |
| 11.2.x | 12.2.x | 11.2.0.2 | Timezone updates needed |
| 11.2.x | 18c | 11.2.0.2 | Latest patches recommended |
| 11.2.x | 19c | 11.2.0.2 | Latest patches recommended |
| 12.1.x | 12.2.x | 12.1.0.2 | Apply latest PSUs |
| 12.1.x | 18c | 12.1.0.2 | Apply latest PSUs |
| 12.1.x | 19c | 12.1.0.2 | Apply latest PSUs |
| 12.1.x | 21c | 12.1.0.2 | Apply latest PSUs |
| 12.2.x | 18c | 12.2.0.1 | Apply latest PSUs |
| 12.2.x | 19c | 12.2.0.1 | Apply latest PSUs |
| 12.2.x | 21c | 12.2.0.1 | Apply latest PSUs |
| 12.2.x | 23ai | 12.2.0.1 | Latest patches required |
| 18c | 19c | 18.3.0.0 | Any version |
| 18c | 21c | 18.3.0.0 | Any version |
| 18c | 23ai | 18.3.0.0 | Latest patches recommended |
| 19c | 21c | 19.3.0.0 | Any version |
| 19c | 23ai | 19.3.0.0 | Latest patches recommended |
| 21c | 23ai | 21.3.0.0 | Any version |

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
