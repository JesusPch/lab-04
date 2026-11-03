# lab-04

### Preguntas
Actividad 1 — Identificar la superficie de ataque
Pregunta
¿Por qué conocer la superficie de ataque debe preceder al hardening?

Respuesta:

No es posible restringir o asegurar lo que se desconoce. Identificar previamente las interfaces, puertos, roles, conexiones activas y servicios expuestos permite establecer una línea base y un diagnóstico preciso de qué elementos son legítimos y cuáles representan una exposición innecesaria para la operación. Esto evita aplicar restricciones a ciegas que puedan interrumpir el servicio o dejar vectores de ataque desatendidos.

Actividad 2 — Identificar los archivos de configuraciónPregunta¿Por qué es importante conocer la ubicación física de estos archivos?

Protección a nivel del Sistema Operativo: Permite restringir el acceso a los archivos mediante permisos de sistema de archivos (chmod 600 / chown postgres:postgres), evitando que usuarios locales no autorizados lean credenciales o modifiquen parámetros del servidor.

Estrategia de respaldos e integridad: Permite diferenciar la política de copia de seguridad entre configuraciones y los datos físicos de la base de datos.

Aislamiento de almacenamiento: Facilita la separación de carpetas críticas (como logs de auditoría o archivos de datos) en particiones dedicadas para evitar que el llenado del disco colapse el motor

Actividad 3 — Revisar listen_addresses
Análisis de Arquitectura
Considera el escenario A:Internet -> Firewall -> Servidor PostgreSQL (5432)
Frente al escenario B:Internet -> X -> Firewall -> Red Privada -> Servidor PostgreSQL (5432)

Explicación:

La segunda arquitectura (Escenario B) reduce significativamente mejor la exposición. En el primer escenario, el servidor PostgreSQL está expuesto directamente en la zona de contacto con el firewall perimetral, permitiendo que cualquier tráfico que atraviese el firewall alcance directamente el motor. En el segundo escenario, el servidor reside en un segmento de red privada aislada (VLAN interna). Esto añade capas de aislamiento donde el puerto 5432 solo es accesible desde IP autorizadas dentro de la red interna, impidiendo que escaneos directos o ataques desde Internet lleguen a la interfaz de la base de datos.

Actividad 5 — Analizar una regla permisivaDada la regla conceptual: host all all 0.0.0.0/0 scram-sha-256   

¿Qué bases de datos permite? Permite el acceso a todas las bases de datos (all).   

¿Qué usuarios permite? Permite el acceso a todos los usuarios/roles (all).   

¿Qué direcciones de origen permite? Permite cualquier dirección IPv4 del mundo (0.0.0.0/0).   

¿Qué método de autenticación utiliza? scram-sha-256.   

¿Por qué puede representar una exposición innecesaria? Porque otorga acceso remoto universal. Aunque la autenticación sea fuerte, permite que cualquier host en Internet intente ataques de fuerza bruta, escaneo de usuarios o explotación de vulnerabilidades en el protocolo de autenticación contra cualquier base de datos del servidor.   
