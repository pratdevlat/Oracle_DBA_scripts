# Data Types

## Overview

Oracle provides 22 different SQL data types for use, briefly introduced as follows:
- CHAR: This is a fixed-length string that will be padded with spaces to reach its maximum length. A non-null CHAR(10) contains 10 **bytes** of information. A CHAR field can store up to 2000 bytes of information.
- NCHAR: This is a fixed-length string containing UNICODE formatted data. A non-null NCHAR(10) always contains 10 **characters** of information. An NCHAR field can store up to 2000 bytes of information.
- VARCHAR2: This is a synonym for VARCHAR. This is a variable-length string. Unlike the CHAR type, it will not pad the field or variable with spaces to its maximum length. VARCHAR2(10) can contain 0 to 10 bytes of information, and it can store up to 4000 bytes of information. Starting from Oracle 12c, it can store up to 32767 bytes of information.
- NVARCHAR2: This is a variable-length string containing UNICODE formatted data. NVARCHAR2(10) can contain 0 to 10 **characters** of information, and NVARCHAR2 can store up to 4000 bytes of information. Starting from Oracle 12c, it can store up to 32767 bytes of information.
- RAW: This is a variable-length binary data type, meaning that data stored using this data type will not undergo character set conversion. This type can store up to 2000 bytes of information. Starting from Oracle 12c, it can store up to 32767 bytes of information.
- NUMBER: This data type can store numbers with a precision of up to 38 digits, ranging from 1.0\*10^(-130) to 1.0\*10(126) (exclusive). Numbers of this type are stored in a variable-length format, with a length of 0 to 22 bytes (NULL values have a length of 0).
- BINARY_FLOAT: A 32-bit single-precision floating-point number, supporting at least 6 digits of precision, occupying 5 bytes of storage on disk.
- BINARY_DOUBLE: A 64-bit double-precision floating-point number, supporting at least 15 digits of precision, occupying 9 bytes of storage on disk.
- LONG: Stores up to 2GB of character data. The LONG type is provided only for backward compatibility, so it is strongly recommended not to use the LONG type in new applications; use the CLOB type instead.
- LONG RAW: The LONG RAW type can store up to 2GB of raw binary information. For the same reasons as LONG, it is recommended that all newly developed applications use the BLOB type.
- DATE: This is a 7-byte fixed-width date/time data type, containing 7 attributes in total: century, year within century, month, day within month, hour, minute, and second.
- TIMESTAMP: This is a 7-byte or 11-byte fixed-width date/time data type (higher precision uses 11 bytes). TIMESTAMP can include fractional seconds; TIMESTAMP with fractional seconds can retain up to 9 decimal places.
- TIMESTAMP WITH TIME ZONE: Similar to the previous type, this is a 13-byte fixed-width TIMESTAMP, but it also provides time zone support. Because time zone information is stored with the TIMESTAMP, the time zone information at insertion will be preserved along with the time.
- TIMESTAMP WITH LOCAL TIME ZONE: Similar to TIMESTAMP, this is a 7-byte or 11-byte fixed-width date/time data type (higher precision uses 11 bytes); however, this type is time zone sensitive. If data of this type is inserted or modified, the database will normalize the date/time part of the data, converting it to the database's time zone, by referencing the TIME ZONE provided in the data and the database's own time zone.
- INTERVAL YEAR TO MONTH: This is a 5-byte fixed-width data type used to store a period of time. This type stores the period as years and months.
- INTERVAL DAY TO SECOND: This is an 11-byte fixed-width data type used to store a period of time. This type stores the period as days/hours/minutes/seconds, and can also have up to 9 decimal places for fractional seconds.
- BLOB: In Oracle 10g and later versions, it can store up to (4GB - 1)*(database block size) bytes of data. BLOB contains "binary" data that does not require character set conversion.
- CLOB: In Oracle 10g and later versions, it can store up to (4GB - 1)*(database block size) bytes of data. CLOB is affected by character set conversion. This data type is well-suited for storing large blocks of plain text information.
- NCLOB: In Oracle 10g and later versions, it can store up to (4GB - 1)*(database block size) bytes of data. NCLOB stores information encoded in the database's national character set, and like CLOB, this type is also affected by character set conversion.
- BFILE: This data type can store an Oracle directory object and a filename in a database column, allowing us to read this file. This effectively allows you to access operating system files on the database server in a read-only manner, as if they were stored in a database table.
- ROWID: ROWID is actually the address of a row in a database table; it is 10 bytes long. The information encoded in a ROWID is sufficient not only to locate each row on disk but also to identify the object to which the ROWID points.
- UROWID: UROWID is a universal ROWID used for tables without a fixed ROWID (such as IOTs and tables accessed via heterogeneous database gateways). UROWID typically represents the value of the primary key, so the size of a UROWID varies depending on the object it points to.

Types like INT, INTEGER, SMALLINT, FLOAT, REAL, etc., are actually implemented based on one of the fundamental types listed above; in other words, they are synonyms for Oracle's intrinsic types.

## Character and Binary String Types

Character data types in Oracle include CHAR, VARCHAR2, and their corresponding N-prefixed variants (NCHAR and NVARCHAR2). CHAR and NCHAR types can store 2000 bytes of text, while VARCHAR2 and NVARCHAR2 can hold 4000 bytes.

Data in CHAR, VARCHAR2, NCHAR, and NVARCHAR2 will be converted between different character sets by the database as needed.
