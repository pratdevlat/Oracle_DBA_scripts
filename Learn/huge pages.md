# **HugePages in Oracle Database: Overview and Calculator**

---

****## What are HugePages?****

**HugePages** (also called **Large Pages**) are a Linux kernel feature that allows Oracle to allocate SGA memory using larger memory pages than the default (typically 4 KB).

**Benefits:**

* Reduced page table overhead.
* Improved Translation Lookaside Buffer (TLB) efficiency.
* Reduced memory fragmentation.

**Default page size:** 4 KB
**Typical HugePage size:** 2 MB (some systems support 1 GB).

---

## 2️ Why Use HugePages in Oracle?

✅ **Better Performance**: Fewer page table entries, less CPU spent managing memory.

✅ **Non-Swappable**: Keeps the SGA resident in memory, preventing paging.

✅ **Recommended**: Especially when SGA is >4 GB or for multi-instance environments.

---

## 3️ How to Calculate HugePages?

### Manual Method:

1. **Total SGA usage** (sum of SGA\_TARGET, SGA\_MAX\_SIZE, or use `ipcs -m`).
2. **Divide by HugePage size** (usually 2 MB).

Example:

```
SGA size = 20 GB
HugePage size = 2 MB

Required HugePages = (20 * 1024) / 2 = 10240
```

### Official Oracle Calculator:

Oracle provides a Perl script in Metalink:

* **Doc ID 401749.1** — *HugePages on Linux: What It Is... and What It Is Not...*

Use the script:

```
cd $ORACLE_HOME/rdbms/admin
sqlplus / as sysdba
SQL> ! ./hugepages_settings.sh
```

---

## 4️ Quick Commands

* **Check HugePages Usage:**

  ```bash
  grep HugePages_Total /proc/meminfo
  grep Hugepagesize /proc/meminfo
  ```

* **Reserve HugePages:**
  Edit `/etc/sysctl.conf`:

  ```conf
  vm.nr_hugepages = <calculated_value>
  ```

  Then reload:

  ```bash
  sysctl -p
  ```

---

## 5️ HugePages Calculator Script

🔗 **Download from Oracle Metalink:**

[MOS Doc ID 401749.1 — HugePages on Linux: What It Is... and What It Is Not...](https://support.oracle.com/epmos/faces/DocumentDisplay?id=401749.1)

(Note: Requires Oracle Support login)
 ```bash
#!/bin/bash
#
# hugepages_settings.sh
#
# Linux bash script to compute values for the
# recommended HugePages/HugeTLB configuration
# on Oracle Linux
#
# Note: This script does calculation for all shared memory
# segments available when the script is run, no matter it
# is an Oracle RDBMS shared memory segment or not.
#
# This script is provided by Doc ID 401749.1 from My Oracle Support
# http://support.oracle.com

# Welcome text
echo "
This script is provided by Doc ID 401749.1 from My Oracle Support
(http://support.oracle.com) where it is intended to compute values for
the recommended HugePages/HugeTLB configuration for the current shared
memory segments on Oracle Linux. Before proceeding with the execution please note following:
 * For ASM instance, it needs to configure ASMM instead of AMM.
 * The 'pga_aggregate_target' is outside the SGA and
   you should accommodate this while calculating the overall size.
 * In case you changes the DB SGA size,
   as the new SGA will not fit in the previous HugePages configuration,
   it had better disable the whole HugePages,
   start the DB with new SGA size and run the script again.
And make sure that:
 * Oracle Database instance(s) are up and running
 * Oracle Database Automatic Memory Management (AMM) is not setup
   (See Doc ID 749851.1)
 * The shared memory segments can be listed by command:
     # ipcs -m


Press Enter to proceed..."

read

# Check for the kernel version
KERN=`uname -r | awk -F. '{ printf("%d.%d\n",$1,$2); }'`

# Find out the HugePage size
HPG_SZ=`grep Hugepagesize /proc/meminfo | awk '{print $2}'`
if [ -z "$HPG_SZ" ];then
    echo "The hugepages may not be supported in the system where the script is being executed."
    exit 1
fi

# Initialize the counter
NUM_PG=0

# Cumulative number of pages required to handle the running shared memory segments
for SEG_BYTES in `ipcs -m | cut -c44-300 | awk '{print $1}' | grep "[0-9][0-9]*"`
do
    MIN_PG=`echo "$SEG_BYTES/($HPG_SZ*1024)" | bc -q`
    if [ $MIN_PG -gt 0 ]; then
        NUM_PG=`echo "$NUM_PG+$MIN_PG+1" | bc -q`
    fi
done

RES_BYTES=`echo "$NUM_PG * $HPG_SZ * 1024" | bc -q`

# An SGA less than 100MB does not make sense
# Bail out if that is the case
if [ $RES_BYTES -lt 100000000 ]; then
    echo "***********"
    echo "** ERROR **"
    echo "***********"
    echo "Sorry! There are not enough total of shared memory segments allocated for
HugePages configuration. HugePages can only be used for shared memory segments
that you can list by command:

    # ipcs -m

of a size that can match an Oracle Database SGA. Please make sure that:
 * Oracle Database instance is up and running
 * Oracle Database Automatic Memory Management (AMM) is not configured"
    exit 1
fi

# Finish with results
    echo "Recommended setting: vm.nr_hugepages = $NUM_PG";

# End
  ```
---

## 6️⃣ Summary Table

| Item                  | Description                                |
| --------------------- | ------------------------------------------ |
| Default Page Size     | 4 KB                                       |
| Typical HugePage Size | 2 MB (or 1 GB on some systems)             |
| Benefits              | Less CPU overhead, improved TLB efficiency |
| Tool                  | hugepages\_settings.sh script              |
| Oracle Doc ID         | 401749.1 (My Oracle Support)               |



* Check **granule size**: 4MB (<1GB SGA) or 16MB (>1GB SGA).

---
