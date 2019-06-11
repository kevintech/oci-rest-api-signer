# oci-rest-api-signer
JAVA Helper to sign Oracle Cloud Infrastructure API requests performed in PL/SQL. Based on [@loiclefevre project](https://github.com/loiclefevre/dbone/tree/master/oci-rest-api-signer "@loiclefevre project").

## Installation
Source properly your environment then invoke **loadjava** command line as following:
```Bash
$ loadjava -oci8 -user <user name>/<password>@//<server hostname or IP>:<port 1521?>/<database service name> -verbose tomitribe-http-signatures-1.0.jar
$ loadjava -oci8 -user <user name>/<password>@//<server hostname or IP>:<port 1521?>/<database service name> -verbose guava-23.0.jar
$ loadjava -oci8 -user <user name>/<password>@//<server hostname or IP>:<port 1521?>/<database service name> -verbose OCIRESTAPIHelper.java
```

## Check Installation
Using your favorite SQL tool (SQLcl, SQL Developer, sqlplus...), create the appropriate PL/SQL functions
```SQL
create or replace FUNCTION OCIRESTAPIHelper_About RETURN Varchar2
AS
LANGUAGE JAVA NAME 'OCIRESTAPIHelper.about () return java.lang.String';

/
```

And test it (compiling the very first time):
```SQL
select OCIRESTAPIHelper_About from dual;
```

## Create Main Functions
[Helper Functions](./create_plsql_functions.sql "Helper Functions") For the other (main) functions, install them as following:
```SQL
create or replace FUNCTION signGetRequest( p_date_header in varchar2, p_path in varchar2, p_host_header in varchar2, p_compartment_ocid in varchar2, p_administrator_ocid in varchar2, p_administrator_key_fingerprint in varchar2, p_administrator_private_key in varchar2) RETURN Varchar2
AS
LANGUAGE JAVA NAME 'OCIRESTAPIHelper.signGetRequest (java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String) return java.lang.String';

/

create or replace FUNCTION signHeadRequest( p_date_header in varchar2, p_path in varchar2, p_host_header in varchar2, p_compartment_ocid in varchar2, p_administrator_ocid in varchar2, p_administrator_key_fingerprint in varchar2, p_administrator_private_key in varchar2) RETURN Varchar2
AS
LANGUAGE JAVA NAME 'OCIRESTAPIHelper.signHeadRequest (java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String) return java.lang.String';

/

create or replace FUNCTION signDeleteRequest( p_date_header in varchar2, p_path in varchar2, p_host_header in varchar2, p_compartment_ocid in varchar2, p_administrator_ocid in varchar2, p_administrator_key_fingerprint in varchar2, p_administrator_private_key in varchar2) RETURN Varchar2
AS
LANGUAGE JAVA NAME 'OCIRESTAPIHelper.signDeleteRequest (java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String) return java.lang.String';

/

create or replace FUNCTION signPutRequest( p_date_header in varchar2, p_path in varchar2, p_host_header in varchar2, p_body in varchar2, p_compartment_ocid in varchar2, p_administrator_ocid in varchar2, p_administrator_key_fingerprint in varchar2, p_administrator_private_key in varchar2, p_is_special in boolean) RETURN Varchar2
AS
LANGUAGE JAVA NAME 'OCIRESTAPIHelper.signPutRequest (java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String, boolean) return java.lang.String';

/

create or replace FUNCTION signPostRequest( p_date_header in varchar2, p_path in varchar2, p_host_header in varchar2, p_body in varchar2, p_compartment_ocid in varchar2, p_administrator_ocid in varchar2, p_administrator_key_fingerprint in varchar2, p_administrator_private_key in varchar2, p_is_special in boolean) RETURN Varchar2
AS
LANGUAGE JAVA NAME 'OCIRESTAPIHelper.signPostRequest (java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String, boolean) return java.lang.String';

/

-- useful to provide the HTTP header x-content-sha256 for PUT and POST methods
create or replace FUNCTION calculateSHA256( p_body in varchar2 ) RETURN Varchar2
AS
LANGUAGE JAVA NAME 'OCIRESTAPIHelper.calculateSHA256 (java.lang.String) return java.lang.String';

/
```

## Create a Wallet and install OCI Certificate
Create your wallet with auto-login
```bash
orapki wallet create -wallet /home/oracle/wallet -pwd <your-password> -auto_login
```

Add the [OCI Certificate](./objectstorage_us-ashburn-1_oraclecloud_com.p7b "OCI Certificate") file to your wallet, this file includes all the 3 certificates
```bash
orapki wallet add -wallet /home/oracle/wallet/ -trusted_cert -cert ./objectstorage_us-ashburn-1_oraclecloud_com.p7b -pwd <your-password>
```

Remove the end site certificate. [Please read this](https://stackoverflow.com/a/19527985 "Please read this")
```bash
orapki wallet remove -wallet wallet -alias 'CN=objectstorage.us-ashburn-1.oraclecloud.com' -trusted_cert
```

## Create and assign a Network Access Control List (ACL)
Grant the connect and resolve privileges for host oraclecloud.com to your APEX user
```SQL
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
```

## Create Identity Domains table to store your OCI configuration
- [Identity Domains](./OCI_IDENTITY_DOMAINS.sql "Identity Domains"): Create identity_domains table and insert your own values
```SQL
create table identity_domains (
    domain_name varchar2(64) not null primary key,
    region varchar2(64) not null,
    tenant_ocid varchar2(128) not null,
    creation_date varchar2(64),
    administrator_ocid varchar2(256),
    administrator_key_fingerprint varchar2(256),
    administrator_private_key varchar2(4000),
);
```
```SQL
INSERT INTO identity_domains (
    tenant_ocid,
    region,
    administrator_ocid,
    administrator_key_fingerprint,
    administrator_private_key,
    domain_name )
VALUES(
    'ocid1.tenancy.oc1..aaaaaaaa.........',
    'us-ashburn-1',
    'ocid1.user.oc1..aaaaaaaa.........',
    '93:3e:8f:b8:c0:.........',
    '-----BEGIN RSA PRIVATE KEY-----',
    'storage-bucket-images')
commit;
```

## Example: listing buckets from OCI Object Store
[OCI_OBJECTSTORAGE_LIST_BUCKETS.sql](./OCI_OBJECTSTORAGE_LIST_BUCKETS.sql "OCI_OBJECTSTORAGE_LIST_BUCKETS.sql"): Create a function receiving the identity domain name and namespace as parameters
```SQL
set define off
set serveroutput on size unlimited

create or replace function listBuckets( p_identity_domain_name in varchar2, p_namespace in varchar2 ) return CLOB is
  g_wallet_path VARCHAR2(200):= 'file:/home/oracle/wallet';    -- Replace with DB Wallet location
  g_wallet_pwd VARCHAR2(200):= null;                           -- Replace with DB Wallet location
  g_OCI_API_VERSION VARCHAR2(16):= '20160918';                 -- Oracle Cloud Infrastructure API version
  l_url VARCHAR2(512);                                         -- REST API endpoint URL
  l_response CLOB;                                             -- JSON Response (i.e. the list of users)
  l_date_header varchar2(128);                                 -- Properly formatted HTTP date header
  l_host_header varchar2(128);                                 -- Properly formatted HTTP host header
  l_service_uri varchar2(512);                                 -- REST API endpoint URI
  l_users_filter varchar2(512);                                -- Filter used in the request
  l_method varchar2(16) := 'get';                              -- HTTP GET method     
  l_tenant_ocid identity_domains.tenant_ocid%TYPE;             -- Column containing the Identity Domain Tenant OCID
  l_region identity_domains.region%TYPE;                       -- Column containing the Identity Domain Region (us-ashburn-1 etc...)
  l_administrator_ocid identity_domains.administrator_ocid%TYPE;      -- Column containing the Administrator OCID
  l_administrator_key_fingerprint identity_domains.administrator_key_fingerprint%TYPE;     -- Column containing the Administrator key fingerprint
  l_administrator_private_key identity_domains.administrator_private_key%TYPE;             -- Column containing the Administrator private key
begin
  -- Gather all required data
  select tenant_ocid, region, administrator_ocid, administrator_key_fingerprint, administrator_private_key 
  into l_tenant_ocid, l_region, l_administrator_ocid, l_administrator_key_fingerprint, l_administrator_private_key 
  from identity_domains where p_identity_domain_name = p_identity_domain_name;
      
  --Build request Headers
  select to_char(CAST ( current_timestamp at time zone 'GMT' as timestamp with time zone),'Dy, DD Mon YYYY HH24:MI:SS TZR','NLS_DATE_LANGUAGE=''AMERICAN''') into l_date_header from dual;
  apex_web_service.g_request_headers(1).name := 'date';
  apex_web_service.g_request_headers(1).value := l_date_header;
      
  l_host_header := 'objectstorage.' || l_region || '.oraclecloud.com';
  apex_web_service.g_request_headers(2).name := 'host';
  apex_web_service.g_request_headers(2).value := l_host_header;
  
  l_service_uri := '/n/' || p_namespace || '/b';
  
  l_users_filter := 'compartmentId=' || replace(l_tenant_ocid,':','%3A');-- || '&' || 'limit=50';
      
  apex_web_service.g_request_headers(3).name := 'Authorization';
  apex_web_service.g_request_headers(3).value := signGetRequest( l_date_header, l_service_uri || '?' || l_users_filter, l_host_header, l_tenant_ocid, l_administrator_ocid, l_administrator_key_fingerprint, l_administrator_private_key );
      
  l_url := 'https://' || l_host_header || l_service_uri || '?' || l_users_filter;    
      
  l_response := apex_web_service.make_rest_request( 
    p_url => l_url,
    p_http_method => 'GET',
    p_wallet_path => g_wallet_path
  );
      
  return l_response; -- in JSON format

end;
/
```

## Credits
This guide is based on the following work:
- [loiclefevre/dbone](https://github.com/loiclefevre/dbone/tree/master/oci-rest-api-signer): Oracle Cloud Infrastructure (OCI) Advanced HTTP Signature for OCI REST API integration in PL/SQL

I fixed the Sign PUT Request method to exclude some headers in [special implementation cases](https://docs.cloud.oracle.com/iaas/Content/API/Concepts/signingrequests.htm#five)
