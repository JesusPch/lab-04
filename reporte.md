# LAB-04 — Hardening y configuración segura de PostgreSQL

## Objetivo
Aplicar un proceso integral de hardening sobre un servidor PostgreSQL en un entorno controlado, identificando configuraciones inseguras, reduciendo la superficie de exposición y estableciendo controles estrictos de acceso a nivel de red, autenticación, autorización y sistema operativo. Al finalizar, se compara el estado inicial con el posterior al hardening para justificar técnicamente cada control implementado.

---

## Entorno
* **Motor de Base de Datos:** PostgreSQL 16 (Entorno de ejecución / inspección v18).
* **Cliente de Administración:** pgAdmin 4 / `psql`.
* **Sistema Operativo:** Linux (Ubuntu/Debian).
* **Archivos y Rutas Principales del Sistema:**
  * Archivo de configuración global (`config_file`): `/etc/postgresql/18/main/postgresql.conf`
  * Archivo de autenticación HBA (`hba_file`): `/etc/postgresql/18/main/pg_hba.conf`
  * Archivo de identidades (`ident_file`): `/etc/postgresql/18/main/pg_ident.conf`
  * Directorio de datos (`data_directory`): `/var/lib/postgresql/18/main`

---

## Superficie de ataque inicial

Se evaluó la superficie de exposición del servidor mediante la ejecución de consultas de inspección inicial:

| Elemento | Estado inicial registrado | ¿Es necesario para producción? | Riesgo identificado |
| :--- | :--- | :--- | :--- |
| **Puerto PostgreSQL** | `5432` | Sí | Mínimo si cuenta con filtrado por firewall y reglas HBA específicas. |
| **Interfaces de escucha** | `localhost` | Sí (solo red local) | Mínimo. En el estado inicial sólo escucha localmente en `127.0.0.1`. |
| **Conexiones remotas** | Sin conexiones externas activas | No | Mínimo. Solo se identifican procesos locales mediante pgAdmin 4. |
| **Usuarios administrativos** | Operación con rol `postgres` | No | **Alto.** El uso continuo de la cuenta superusuario expone la base de datos a daños globales. |
| **Cifrado SSL/TLS** | `ssl = on` | Sí | Mínimo. El canal de comunicación se encuentra cifrado en tránsito. |
| **Métodos de autenticación** | `scram-sha-256` | Sí | Mínimo. Cumple con el estándar de cifrado y derivación de contraseñas recomendado. |

---

## Hallazgos
Durante la fase de inspección y análisis del escenario (Comercializadora Norte S.A. de C.V.), se detectaron los siguientes problemas y vulnerabilidades:

1. **Uso de Cuentas Administrativas:** La aplicación interna y las conexiones generales se realizan mediante la cuenta superusuario `postgres`.
2. **Reglas HBA Permisivas:** Existencia o riesgo de configuración de reglas del tipo `0.0.0.0/0` en `pg_hba.conf`, permitiendo intentos de acceso desde cualquier origen IPv4.
3. **Falta de Tiempos Límite (Timeouts):** Sesiones inactivas o transacciones colgadas que no son terminadas automáticamente, lo que puede provocar saturación en `max_connections`.
4. **Exposición de Permisos en Sistema Operativo:** Riesgo de que archivos sensibles (`pg_hba.conf` y `postgresql.conf`) mantengan permisos de lectura para usuarios no autorizados del sistema operativo.
5. **Ausencia de Documentación de Baseline:** No existía una línea base formalizada ni un checklist de seguridad para auditar el cumplimiento del servidor.

---

## Cambios realizados

1. **Restricción de Interfaces de Escucha (`listen_addresses`):** Configurado para escuchar únicamente en las IP locales/privadas requeridas (`localhost` o `10.10.10.20`), evitando escuchar en `*`.
2. **Refinamiento de Reglas en `pg_hba.conf`:** Eliminación de cualquier regla global `0.0.0.0/0` y creación de reglas específicas delimitando `DATABASE + USER + ADDRESS (CIDR) + METHOD`.
3. **Separación de Roles y Aplicación del Mínimo Privilegio:**
   * Creación del rol `app_user` para la aplicación web con privilegios limitados únicamente a su base de datos (`NO SUPERUSER`, `NO CREATEROLE`).
   * Aislamiento de la cuenta `postgres` solo para labores directas de administración (DBA).
4. **Protección a Nivel de Sistema Operativo:** Ajuste de permisos en el sistema de archivos (`chmod 600` para configuraciones y `chmod 700` para `data_directory` asignados a `postgres:postgres`).
5. **Configuración de Tiempos de Espera (Timeouts):** Ajuste de los parámetros `idle_in_transaction_session_timeout` y `statement_timeout` para mitigar bloqueos y prevenir denegación de servicio (DoS).
6. **Políticas de Firewall:** Establecimiento de reglas de Allowlist para permitir el puerto 5432 únicamente desde el segmento de red autorizado.

---

## Justificación de los cambios

| Cambio Aplicado | Justificación Técnica |
| :--- | :--- |
| **Ajustar `listen_addresses`** | Reduce la superficie de exposición de red impidiendo que el motor acepte peticiones desde interfaces no confiables o públicas. |
| **Restringir `pg_hba.conf`** | Aplica el principio de mínimo privilegio en el control de acceso, garantizando que solo IP y usuarios autorizados intenten autenticarse. |
| **Forzar `scram-sha-256`** | Protege las credenciales contra ataques de interceptación en tránsito y evita guardar claves en hashes vulnerables a colisiones. |
| **Separar cuenta de App vs DBA** | Mitiga el impacto de vulnerabilidades como Inyección SQL (SQLi); si la app es comprometida, el atacante no obtiene privilegios del sistema. |
| **Permisos de SO (`chmod 600/700`)** | Evita que usuarios locales del servidor lean configuraciones sensibles o alteren archivos de datos evadiendo el motor de BD. |
| **Configurar Timeouts** | Protege la disponibilidad del motor liberando procesos colgados y evitando el agotamiento de memoria y conexiones (`max_connections`). |

---

## Verificación

Se ejecutó el script de validación `sql/04-verificacion.sql` para comprobar la correcta aplicación de las medidas de hardening:

1. **Estado de Cifrado TLS:** Verificado mediante `pg_stat_ssl`, confirmando que el canal utiliza cifrado TLSv1.2/TLSv1.3 activo (`ssl = true`).
2. **Conexiones Activas:** Consulta a `pg_stat_activity` confirmando que solo operan clientes autenticados desde IP permitidas y con los roles correspondientes.
3. **Parámetros de Red y Seguridad:** Confirmación mediante `SHOW listen_addresses;`, `SHOW ssl;` y `SHOW password_encryption;` mostrando los valores seguros esperados.

```sql
-- Consulta utilizada para verificar la seguridad de la conexión
SELECT pid, usename, client_addr, ssl, version, cipher 
FROM pg_stat_ssl 
WHERE pid = pg_backend_pid();
```



# Actividad 30 — Preguntas del Informe (Síntesis Final)

### 1. ¿Cuál era la principal superficie de ataque?
Conexiones remotas escuchando en todas las interfaces, reglas de `pg_hba.conf` excesivamente permisivas (como `0.0.0.0/0`) y el uso rutinario de usuarios administrativos (`postgres`) para tareas operativas[cite: 1].

### 2. ¿Qué configuración representaba el mayor riesgo?
Permitir conexiones remotas universales desde cualquier origen (`0.0.0.0/0`) combinadas con cuentas de aplicación conectadas con privilegios de `SUPERUSER`[cite: 1].

### 3. ¿Qué cambio produjo la mayor reducción de exposición?
Restringir `listen_addresses` a la IP/interfaz estrictamente requerida y ajustar `pg_hba.conf` a rangos CIDR específicos y usuarios dedicados[cite: 1].

### 4. ¿Qué diferencia existe entre firewall y pg_hba.conf?
El firewall filtra y bloquea el tráfico a nivel de red antes de ingresar al servidor (Capas 3 y 4 del modelo OSI)[cite: 1]. `pg_hba.conf` es un mecanismo interno de PostgreSQL que evalúa y autentica las conexiones que ya lograron acceder al puerto del motor (Capa 7)[cite: 1].

### 5. ¿Qué diferencia existe entre autenticación y autorización?
* **Autenticación:** Proceso mediante el cual el sistema verifica la identidad del usuario (¿Quién eres?)[cite: 1].
* **Autorización:** Proceso que determina a qué recursos y comandos tiene permiso de acceder un usuario ya autenticado (¿Qué puedes hacer?)[cite: 1].

### 6. ¿Por qué una cuenta de aplicación no debe ser SUPERUSER?
Porque viola el principio de mínimo privilegio[cite: 1]. Si la aplicación sufre una vulnerabilidad (como Inyección SQL), un atacante heredaría privilegios totales sobre el servidor, pudiendo borrar bases de datos, alterar roles o ejecutar comandos del sistema operativo[cite: 1].

### 7. ¿Por qué cambiar el puerto de PostgreSQL no constituye hardening suficiente?
Porque únicamente reduce el ruido de escaneos automatizados simples (seguridad por oscuridad)[cite: 1]. No reemplaza los mecanismos de autenticación, la autorización ni las reglas de filtrado en el firewall[cite: 1].

### 8. ¿Por qué listen_addresses='*' puede ser innecesario?
Porque expone el servicio de PostgreSQL en todas las interfaces de red físicas y virtuales disponibles en el servidor, incrementando la superficie de ataque hacia redes no confiables o públicas[cite: 1].

### 9. ¿Qué papel tiene el sistema operativo en la seguridad de PostgreSQL?
El sistema operativo resguarda la base del entorno; es responsable de proteger los archivos físicos de datos y configuración mediante permisos de archivo (`chmod 600/700`), asegurando que usuarios locales no autorizados no puedan leer credenciales o modificar datos directamente en disco[cite: 1].

### 10. ¿Qué controles deberían revisarse periódicamente?
Reglas de `pg_hba.conf`, roles y privilegios asignados en la base de datos, actualización de parches de seguridad del motor, permisos en el sistema de archivos del SO, directivas del firewall y registros de auditoría/logs[cite: 1].
