SELECT
    extname,
    extversion
FROM pg_extension
ORDER BY extname;

SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;