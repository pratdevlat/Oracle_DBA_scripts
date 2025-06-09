
# Overview

## Database

A collection of operating system files or disks. Oracle 12c provides three different types of databases:

- **Single-tenant database**: Completely self-contained with a full set of data files, control files, redo log files, parameter files, etc. Contains all metadata, data, code, and all application-related metadata, data, and code. All Oracle databases prior to 12c are of this type.

- **Container or root database (CDB)**: Contains a full set of data files, control files, redo log files, and parameter files, but only used to store Oracle's own metadata, internal data, and internal code. It does not store application data or code, only Oracle-specific entities. This database is entirely self-contained and can be mounted and opened independently.

- **Pluggable database (PDB)**: Contains only data files and is not fully self-contained. It must be attached (plugged) to a container database (CDB) to be opened for read and write operations. This database holds only application metadata, objects, data, and code. It relies on the files (control files, redo logs, parameter files) from the CDB.

## Instance

An Oracle instance consists of a set of Oracle background processes/threads and a shared memory region, used by threads/processes running on the same computer. Oracle stores and maintains volatile, non-persistent content here (some of which may be flushed to disk). Importantly, a database instance can exist without disk storage.

Relationships between instances and databases:
- Single-tenant or container databases can be mounted and opened by multiple instances, but an instance can only mount and open one database at any time. An instance can only mount and open one database throughout its lifetime.
- A pluggable database (PDB) can only associate with one container database (CDB) at any given time, thus linking to only one instance. Once an instance opens and mounts a CDB, the included PDBs utilize this instance. An instance can simultaneously serve multiple (up to about 250) PDBs but only one CDB or single-tenant database.

## SGA and Background Processes

Oracle has a large memory area called the System Global Area (SGA), used for (but not limited to):
- Maintaining internal data structures accessible by all processes.
- Caching data from disk, and temporarily caching redo data before it's written to disk.
- Storing parsed SQL plans.

Oracle has a set of processes "attached" to the SGA, with attachment mechanisms varying by OS. In UNIX/Linux environments, these processes attach to a large shared memory segment, while on Windows, they use C calls (malloc()) to allocate memory.

## Connecting to Oracle

### Dedicated Server

Upon login, Oracle creates a new process, usually referred to as a **dedicated server** configuration. A new dedicated server process emerges for each session, creating a one-to-one mapping.

By definition, the dedicated server isn't part of the instance. Client processes communicate directly with the dedicated server over a network channel, which receives and executes SQL.

### Shared Server

Oracle also allows connections via **shared server**. In this mode, the database doesn't create new threads or processes for each user connection.

Oracle uses a pool of "shared processes" to serve multiple users. Shared server is effectively a connection pooling mechanism, sharing processes among sessions. Oracle utilizes one or more **dispatcher processes** to handle client requests. Client processes communicate over a network with a dispatcher, which places requests into a queue in the SGA. The first free shared server picks up the request and processes it. Upon completion, the shared server places responses back into the dispatcher's response queue. Dispatchers monitor this queue and return results to the client.

### Pluggable Database

A pluggable database (PDB) under the multitenant architecture comprises a set of non-self-contained data files, containing only application data and metadata. Oracle-specific data isn't stored here but resides in the container database (CDB). To use or query a PDB, it must be "plugged" into a CDB. The CDB contains only Oracle-specific necessary runtime data and metadata. PDB stores remaining data and metadata.

Oracle designed PDBs and multitenant architecture primarily to:
- Efficiently reduce resource usage by multiple databases/applications on a single host.
- Reduce DBA maintenance efforts for multiple databases/applications on a single host.
