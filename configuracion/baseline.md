# Propuesta de Línea Base de Seguridad (Security Baseline) — PostgreSQL 16

Esta línea base establece la configuración mínima aceptable de seguridad para instancias de PostgreSQL 16 dentro de la organización Comercializadora Norte S.A. de C.V[cite: 1].

---

## 1. Seguridad de Red y Exposición
* **Interfaces autorizadas:** `listen_addresses` debe configurarse explícitamente a las IP locales o de servicio (nunca `*` a menos que sea una IP privada controlada)[cite: 1].
* **Puerto de servicio:** Puerto 5432 documentado y monitoreado[cite: 1].
* **Firewall:** Regla de Allowlist estricta en el firewall del servidor que solo permita el puerto 5432 desde la red de administración (DBA) y los servidores de aplicación autorizados[cite: 1].
* **Segmentación:** La base de datos debe residir en una VLAN/subred aislada, sin acceso directo desde Internet[cite: 1].

---

## 2. Autenticación y Credenciales
* **Método de autenticación:** Obligatorio `scram-sha-256` en todas las entradas de `pg_hba.conf`[cite: 1].
* **Política de credenciales:** Ningún usuario debe utilizar contraseñas en blanco o débiles.
* **Cuentas administrativas:** La cuenta `postgres` debe ser utilizada únicamente para tareas de mantenimiento y administración directamente por el personal DBA[cite: 1, 5].

---

## 3. Autorización y Control de Acceso (Roles)
* **Separación de funciones:** Se deben definir 3 tipos de cuentas[cite: 1]:
  1. **DBA:** Tareas administrativas completas (`SUPERUSER`)[cite: 1].
  2. **APP:** Credencial de aplicación con privilegios mínimos requeridos sobre esquemas y tablas específicas (`NO SUPERUSER`, `NO CREATEROLE`)[cite: 1].
  3. **CONSULTA:** Cuentas de lectura exclusiva para reportes/auditoría (`SELECT` únicamente)[cite: 1].
* **Principio de Mínimo Privilegio:** Ninguna aplicación web o servicio de terceros debe conectarse como `SUPERUSER`[cite: 1].

---

## 4. Configuración del Motor
* **Parámetros de timeouts:** 
  * `statement_timeout`: Configurado para interrumpir consultas desmedidas.
  * `idle_in_transaction_session_timeout`: Máximo 60000ms (1 min) para evitar bloqueos por transacciones colgadas[cite: 1].
* **Extensiones:** Revisión periódica de `pg_extension`. No instalar extensiones no aprobadas por el DBA[cite: 1].
* **Gestión de conexiones:** Limitar `max_connections` a la capacidad real del servidor y reservar conexiones con `superuser_reserved_connections`[cite: 1].

---

## 5. Permisos del Sistema Operativo
* **Propietario de archivos:** Todos los archivos de configuración y datos deben ser propiedad exclusiva del usuario `postgres:postgres`[cite: 1].
* **Permisos del directorio de datos:** `chmod 700` sobre `data_directory` (`/var/lib/postgresql/18/main`)[cite: 1, 13].
* **Permisos de archivos de configuración:** `chmod 600` sobre `postgresql.conf`, `pg_hba.conf` y `pg_ident.conf`[cite: 1].

---

## 6. Cifrado y Comunicaciones
* **Cifrado en tránsito (TLS):** `ssl = on` habilitado[cite: 1, 7].
* **Protocolo mínimo:** `ssl_min_protocol_version = TLSv1.2`[cite: 1].
* **Protección de credenciales:** Almacenamiento seguro de llaves privadas y certificados SSL en el servidor.

---

## 7. Mantenimiento y Auditoría
* **Logs de auditoría:** Habilitar `log_connections = on` y `log_disconnections = on` para auditoría de accesos[cite: 1].
* **Actualizaciones:** Aplicación periódica de parches de seguridad liberados por la comunidad de PostgreSQL[cite: 1].
* **Revisiones periódicas:** Ejecución trimestral del Hardening Checklist para verificar desviaciones de esta línea base[cite: 1].