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
