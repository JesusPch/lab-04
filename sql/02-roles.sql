SELECT
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles
ORDER BY rolname;

SELECT rolname 
FROM pg_roles 
WHERE rolsuper = true;

SELECT rolname 
FROM pg_roles 
WHERE rolcanlogin = true;