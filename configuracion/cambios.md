# Registro de Cambios y Comparativa de Hardening (Antes vs Después)

El presente documento registra la evolución del servidor PostgreSQL 16 tras la aplicación de los controles de hardening definidos en el LAB-04.

| Control | Estado Antes | Estado Después | Justificación Técnica |
| :--- | :--- | :--- | :--- |
| **listen_addresses** | `*` (Todas las interfaces) | `localhost` / `10.10.10.20` | Limita el acceso únicamente a las interfaces de red estrictamente necesarias, reduciendo la exposición a redes no autorizadas. |
| **pg_hba.conf** | `host all all 0.0.0.0/0 scram-sha-256`[cite: 1] | `host basedatos_app app_user 10.10.10.0/24 scram-sha-256`| Restringe las conexiones por base de datos, usuario específico, segmento de red permitido y método seguro de autenticación. |
| **Método de autenticación** | `md5` / `trust`[cite: 1] | `scram-sha-256`| Evita el uso de algoritmos vulnerables a ataques de colisión o texto plano, asegurando una derivación de clave robusta. |
| **Usuarios administrativos** | Uso de `postgres` para operaciones generales[cite: 1, 5] | Cuenta `postgres` restringida solo a tareas de DBA directas[cite: 1, 5] | Minimiza el riesgo de compromiso catastrófico al limitar el uso de cuentas superusuario[cite: 1, 5]. |
| **Cuentas de aplicación** | La aplicación usaba rol `SUPERUSER`[cite: 1] | Separación en cuenta `APP` con privilegios estrictos (`GRANT SELECT, INSERT...`)[cite: 1] | Aplica el principio de mínimo privilegio; si la app es vulnerada, no se compromete el motor completo[cite: 1]. |
| **Puerto PostgreSQL** | `5432` predeterminado sin firewall explícito[cite: 1, 6] | `5432` (o puerto alternativo) con regla de firewall restrictiva[cite: 1] | Previene escaneos automatizados y bloquea tráfico no deseado antes de alcanzar el motor de BD[cite: 1]. |
| **TLS / SSL** | `ssl = off` / No forzado[cite: 1] | `ssl = on`, `ssl_min_protocol_version = TLSv1.2`[cite: 1] | Garantiza que todo el tráfico de datos y credenciales en tránsito viaje cifrado[cite: 1]. |
| **Permisos de SO** | Archivos con permisos de lectura para cualquier usuario (`644`)[cite: 1] | `chmod 600` en archivos `.conf`, `chmod 700` en `data_directory` (`postgres:postgres`)[cite: 1] | Protege credenciales y configuraciones sensibles contra lectura/escritura por usuarios locales no autorizados[cite: 1]. |
| **Extensiones** | Extensiones innecesarias habilitadas[cite: 1] | Solo extensiones indispensables (ej. `plpgsql`)[cite: 1] | Elimina código innecesario que pueda contener vulnerabilidades o ampliar la superficie de ataque[cite: 1]. |
| **Conexiones** | `max_connections` excesivo, sin tiempos límite de inactividad[cite: 1] | Configuración de `idle_in_transaction_session_timeout` y `statement_timeout`[cite: 1] | Protege contra la denegación de servicio (DoS) por agotamiento de recursos o sesiones colgadas[cite: 1]. |