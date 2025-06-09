# Redo and Undo

Redo (redo information) is information recorded in Oracle online (or archived) redo log files, which can be used to "replay" (or redo) transactions when a database fails. Undo (rollback information) is information recorded by Oracle in undo segments, primarily used to cancel or roll back transactions.

## What is Redo

Redo log files are crucial to Oracle databases; they are the transaction logs of the database. Oracle maintains two types of redo log files: online redo log files and archived redo log files. Both types of redo log files are used for recovery, and their main purpose is to be used when a database instance or media failure occurs.

Archived redo log files are essentially copies of "old" online redo log files that have been filled. When the database fills an online redo log file, the ARCn process creates a copy of it in another location. Of course, it can also keep multiple copies locally or on a remote server.

Every Oracle database has at least two online redo log groups, and each group has at least one member (redo log file). These online redo log groups are used in a circular fashion. Oracle first writes to the log files in group 1, and when it reaches the end of the files in group 1, it switches to log file group 2 and starts writing to the files in this group. When log file group 2 is full, Oracle will switch back to log file group 1 again.

Redo logs are probably the most important recovery structure in the database, but without other components (such as undo segments, distributed transaction recovery, etc.), redo logs alone cannot do anything.

## What is Undo

Conceptually, undo is the opposite of redo. When data is modified, the database generates undo information so that the data can be reverted to its pre-modification state if needed in the future. The multi-versioning mechanism is implemented by using this undo information. In addition, when an executing transaction or statement fails for some reason, or when you request a rollback with a ROLLBACK statement, Oracle also needs to use this undo information to restore the data to its pre-modification state. Redo is used to replay transactions during failure (i.e., recover transactions), while undo is used to cancel the effect of a statement or a set of statements. Unlike redo, undo is stored in a special set of segments within the database, called undo segments.

There is often a misunderstanding about undo, where people believe that undo "physically" restores the database to its state before a certain statement or transaction, but this is not actually the case. The database only "logically" restores the data to its original state; certain modifications are "logically" undone, but the data structure and the database blocks themselves may be significantly different after rollback (compared to their state before the transaction or statement began). The reason is that in all multi-user systems, there can be tens, hundreds, or even thousands of concurrent transactions. One of the main functions of the database is to coordinate their concurrent access to data. It is highly likely that blocks modified by one transaction are also being modified by other transactions at the same time. Therefore, you cannot simply revert a block to its state before the transaction began, as this would undo the work of other transactions!

## How Redo and Undo Work Together

Although undo information is stored in undo tablespaces and undo segments, it is also protected by redo. In other words, the database treats undo as it treats table data or index data; modifications to undo generate redo, which is written to the log buffer and then to the log files. Similar to non-undo data in the database, undo data is written to undo segments and also placed in the buffer cache.

### INSERT-UPDATE-DELETE-COMMIT Example Scenario

#### 1. INSERT
After an INSERT occurs, the block buffer cache contains modified undo blocks, index blocks, and table data blocks, all of which are "protected" by corresponding entries in the redo log buffer.

Before flushing the modified data blocks to disk, the redo information in the redo log buffer is written to disk. This way, if a crash occurs, all modifications can be replayed using this redo information to restore the SGA to its current state, and then the database also has corresponding undo information to roll back uncommitted transactions.

#### 2. UPDATE
UPDATE operations are largely similar to INSERTs, but UPDATEs generate more UNDO; this is because UPDATEs need to save an image of the data before modification. The database...
