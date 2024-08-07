ow to fix send email (Example to fix send email in Rman backup  server 
BEGIN
DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
acl => '/sys/acls/utl_mail.xml',
description => 'Permissions for smtp gate',
principal => 'USER',
is_grant => TRUE,
privilege => 'connect'
);
COMMIT;
END;
/

BEGIN
DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
acl => '/sys/acls/utl_mail.xml',
description => 'Permissions for smtp gate',
principal => 'USER',
is_grant => TRUE,
privilege => 'resolve'
);
COMMIT;
END;
/

BEGIN
DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
acl => '/sys/acls/utl_mail.xml',
host => '*.DBA.com',
lower_port => 25,
upper_port => null);
COMMIT;
END;
/

BEGIN
DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
acl => '/sys/acls/utl_mail.xml',
host => ' tlv.DBA.com',
lower_port => 25,
upper_port => null);
COMMIT;
END;

/
SELECT acl,principal,privilege,is_grant,TO_CHAR(start_date, 'DD-MON-YYYY HH24:MI') AS start_date,TO_CHAR(end_date, 'DD-MON-YYYY') AS end_date FROM   dba_network_acl_privileges;
SELECT host, lower_port, upper_port, acl FROM   dba_network_acls;
