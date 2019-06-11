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