-- Create Cloud Center Interfacee tables

-- Identity Domains
-- Will store all managed identity domains information
create table identity_domains (
    domain_name varchar2(64) not null primary key, -- Identity domain name.
    region varchar2(64) not null, -- Identity domain region (example: us-ashburn-1).
    tenant_ocid varchar2(128) not null, -- Identity domain Tenant OCID (example: ocid1.tenancy.oc1..abcdefghijklmnop...).
    creation_date varchar2(64), -- Identity domain creation date, filled automatically by CCI.
    administrator_ocid varchar2(256), -- OCI non federated User OCID belonging to the Administrators group.
    administrator_key_fingerprint varchar2(256), -- One of the OCI non federated User''s key fingerprint.
    administrator_private_key varchar2(4000), -- The associated OCI non federated User''s private key (RSA format).
);

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