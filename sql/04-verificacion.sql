SHOW ssl;
SHOW ssl_min_protocol_version;

SELECT
    pid,
    usename,
    client_addr,
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();

SHOW listen_addresses;
SHOW port;
SHOW password_encryption;

SELECT
    pid,
    usename,
    datname,
    client_addr,
    application_name
FROM pg_stat_activity;

SELECT pid, usename, datname, client_addr, client_port, application_name 
FROM pg_stat_activity;
SELECT type, database, user_name, address, auth_method 
FROM pg_hba_file_rules;

SELECT rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin 
FROM pg_roles 
ORDER BY rolname;

SELECT pid, ssl, version, cipher 
FROM pg_stat_ssl 
WHERE pid = pg_backend_pid();