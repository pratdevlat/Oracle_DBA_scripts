# Indexes

## Overview

Oracle provides several different types of indexes:
- B\*Tree index: This is the most commonly used index in Oracle and most other databases. A B\*Tree is structured like a binary tree, allowing for fast access to a single row of data by its key value, or locating multiple rows within a range of key values; accessing data through this index usually only requires a few I/Os. It's important to note that the B in B\*Tree does not stand for binary, but for balanced. A B\*Tree index is not a binary tree. In addition to regular B\*Tree indexes, the following types are also considered B\*Tree indexes.
    - Index-organized table (IOT): This is a table, but its storage is also a B\*Tree structure. Data in an IOT is stored and sorted by the primary key.
    - B\*Tree cluster index: This is an approximate variant of a traditional B\*Tree index. A B\*Tree cluster index is an index built on a cluster key. In a traditional B\*Tree index, the key points to the row level; however, in a B\*Tree cluster, a cluster key points to a block that contains data related to that cluster key.
    - Descending index: In a descending index, data is arranged in "largest to smallest" order (descending), rather than "smallest to largest" (ascending).
    - Reverse key index: This is also a B\*Tree index, but the bytes within the key are "reversed." If increasing data is continuously inserted into an index, reverse key indexes will result in a more even distribution of this data. Oracle reverses the bytes of the data to be stored before placing it into the index, so that data that might have been adjacent in the index originally will be far apart after byte reversal. By reversing bytes, insertions into the index can be distributed across multiple blocks.
- Bitmap index: In a B\*Tree, there is usually a one-to-one relationship between index entries and rows: one index entry points to one row of data. For bitmap indexes, one index entry can point to multiple rows of data simultaneously via a bitmap. Bitmap indexes are suitable for highly repetitive data (highly repetitive means that, compared to the total number of rows in the table, the data has only a few distinct values), and the data is usually read-only.
- Bitmap join index: Denormalization of data is usually achieved through tables, but this type of index can also denormalize data.
- Function-based index: These indexes are themselves B\*Tree indexes or bitmap indexes, but they store a calculated result of one or more columns, rather than the original column data. This type of index can be thought of as an index on a virtual column (or derived column).
- Application domain index: Application domain indexes are indexes you build and store yourself, which may be stored within Oracle or outside Oracle. You tell the optimizer how selective the index is and what the execution cost is, and the optimizer decides whether to use your index based on the information you provide.

## B\*Tree Index

B\*Tree indexes are the most common type of index structure in databases, and their implementation is very similar to a binary search tree. Their goal is to minimize the time Oracle spends searching for data.

The blocks at the lowest level of the tree are called leaf nodes or leaf blocks, which contain individual index keys and a rowid (pointing to the indexed row). Internal blocks above the leaf nodes are called branch blocks, and data searches pass through these blocks to ultimately reach the leaf nodes.

The structure of the index leaf node level is actually a doubly linked list. If we need to search for data within a certain range (also called an index range scan), once the starting leaf node (the first value in the range) is found, the subsequent work becomes much easier. At this point, there is no need to scan the index structure from the beginning; one only needs to scan forward or backward through the leaf nodes.

One characteristic of B\*Trees is that all leaf blocks should be on the same level of the tree. This level is also called the height of the index, and all traversals from the root block of the index to a leaf block will visit the same number of blocks. The index is height-balanced. Most B\*Tree indexes have a height of 2 or 3, even with millions of records. This means that finding the first leaf block through the index only takes 2 or 3 I/Os.
