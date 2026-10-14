# uploads-bucket: decisiones de diseño

## URL prefirmadas

El navegador no sube los archivos al backend: le pide una URL prefirmada y sube directo a S3. Una URL prefirmada es un enlace firmado con las credenciales del backend, válido para una sola operación sobre un solo archivo durante pocos minutos.

- El archivo no pasa por el contenedor, que no necesita memoria ni tiempo para recibirlo.
- No aplica el límite de 10 MB por petición de API Gateway.
- El bucket nunca es público: sin URL vigente, no hay acceso.

## CORS solo para el sitio

El navegador bloquea las peticiones a otro dominio salvo que ese dominio las autorice. La regla CORS autoriza solo los orígenes del sitio, con los métodos `GET`, `PUT`, `POST` y `HEAD`. Expone la cabecera `ETag`, que el navegador necesita para completar subidas por partes.

## El módulo publica su propia política de acceso

El bucket no sabe quién lo usa. Publica una política de IAM que da acceso de lectura y escritura a sus objetos, y el stack se la entrega al rol de la tarea del backend. Así el permiso es mínimo (solo este bucket) y el módulo sirve para cualquier consumidor.

## Versionado opcional

Con versionado, sobrescribir o borrar un archivo conserva la versión anterior, que se puede recuperar. Las versiones anteriores se eliminan a los 90 días (configurable) para que el almacenamiento no crezca sin límite. Se activa en producción; en un entorno de prueba no hace falta.

## Subidas incompletas

Una subida por partes que se interrumpe deja fragmentos que cobran almacenamiento y no se ven en la consola. Una regla de ciclo de vida los elimina a los 7 días.

## Mismas protecciones que el resto de los buckets

Acceso público bloqueado, ACL deshabilitadas, cifrado SSE-S3 y una política que rechaza las conexiones sin HTTPS.
