DECLARE
  l_principal VARCHAR2(20) := 'APEX_180200';
BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => 'oci_object_storage_acl.xml',
    description  => 'An ACL for the oraclecloud.com website',
    principal    => l_principal,
    is_grant     => TRUE,
    privilege    => 'connect',
    start_date   => SYSTIMESTAMP,
    end_date     => NULL);

  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => 'oci_object_storage_acl.xml',
    host        => 'objectstorage.us-ashburn-1.oraclecloud.com', -- us-ashburn-1 REGION
    lower_port  => 443,
    upper_port  => null);

  COMMIT;
END;
/


-- DROP ACL
-- BEGIN
--   DBMS_NETWORK_ACL_ADMIN.DROP_ACL(
--     acl => 'oci_object_storage_acl.xml');
-- END;

-- CHECK ACL
-- SELECT host FROM dba_network_acls;