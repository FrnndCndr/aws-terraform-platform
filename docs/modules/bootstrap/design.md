# bootstrap: decisiones de diseño

## El nombre del bucket incluye el id de cuenta

El bucket se llama `tfstate-<client>-<account_id>`. Los nombres de S3 son únicos entre todas las cuentas de AWS; el id de cuenta evita colisiones con buckets de terceros y deja claro a qué cuenta pertenece. El id se obtiene de la sesión activa, no de una variable, de modo que no se escribe en ningún archivo.

## Un bucket por cuenta, compartido por los entornos

Cada cliente tiene su cuenta AWS, y su bucket guarda el state de todos sus entornos, separados por la `key`. Un bucket por entorno duplicaría recursos sin mejorar el aislamiento, porque el límite de seguridad es la cuenta.

## State local, con un workspace por cliente

`bootstrap` no puede guardar su state en el bucket que él mismo crea, así que usa state local. Como el mismo código se aplica en la cuenta de cada cliente, cada uno usa un workspace de Terraform propio: el state queda en `terraform.tfstate.d/<client>/`, separado del de los demás.

Este state local no se versiona en git. Si se pierde, el bucket sigue existiendo en AWS y se recupera con `terraform import`.

## Versionado activo

Cada escritura del state crea una versión nueva. Si un `apply` deja el state dañado, o alguien lo sobrescribe por error, se restaura la versión anterior desde S3.

## Las versiones antiguas expiran

Sin límite, las versiones se acumulan para siempre. Una regla de ciclo de vida elimina las versiones no vigentes pasados 90 días (configurable). La versión vigente nunca se elimina.

## Cifrado con llaves administradas por S3 (SSE-S3)

El contenido se cifra en reposo con `AES256`. Se prefiere a una llave propia de KMS porque no tiene costo ni requiere administrar permisos de llave. Una llave de KMS agrega cerca de 1 USD al mes por llave y un punto más de configuración; se justifica cuando un cliente exige controlar o auditar el uso de la llave.

## Acceso público bloqueado y solo HTTPS

Las cuatro opciones de bloqueo de acceso público están activas: ninguna ACL ni política puede exponer el bucket. Además, una política del bucket rechaza toda petición que no use HTTPS, para que el state no viaje sin cifrar.

## Propiedad de objetos forzada al dueño del bucket

Las ACL quedan deshabilitadas (`BucketOwnerEnforced`). El acceso se controla solo con políticas, que es el modelo que AWS recomienda y evita permisos dispersos por objeto.

## Protección contra destrucción

El bucket lleva `prevent_destroy`: un `terraform destroy` sobre `bootstrap` falla en lugar de borrar el state de todos los entornos del cliente. Eliminar el bucket exige quitar esa protección a propósito.

## Sin tabla DynamoDB

El bloqueo de ejecuciones simultáneas usa el mecanismo nativo de S3 (`use_lockfile`), que se configura en el backend de cada stack. `bootstrap` no crea nada para el bloqueo: es un recurso menos que pagar y mantener.

## Tags en inglés

Los tags son `client`, `project` y `managed_by`, igual que el resto de los identificadores del código.
