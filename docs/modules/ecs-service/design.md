# ecs-service: decisiones de diseño

## Fargate

Fargate ejecuta los contenedores sin servidores que administrar: no hay instancias que parchar ni escalar. Se paga por la CPU y memoria de cada tarea mientras corre.

## Dos roles de IAM separados

- **Rol de ejecución:** lo usa ECS para bajar la imagen, escribir los registros y leer los secretos al arrancar la tarea. El código de la aplicación no lo ve.
- **Rol de la tarea:** lo usa la aplicación al llamar a AWS, por ejemplo para firmar URL de S3. Arranca sin permisos; cada permiso se agrega con `task_role_policies`.

Separarlos evita que la aplicación herede los permisos de ECS, y que ECS herede los de la aplicación.

## Los permisos llegan desde fuera

El módulo no sabe qué recursos usa la aplicación. Quien conoce el recurso publica la política que da acceso a él (por ejemplo, `uploads-bucket` publica la de su bucket) y el stack la entrega aquí. El módulo queda reutilizable para cualquier servicio.

## Secretos en variables de entorno

ECS lee los secretos de Secrets Manager al arrancar cada tarea y los entrega como variables de entorno. No pasan por Terraform ni quedan en la definición de la tarea: solo su ARN. Un secreto JSON se puede abrir por campo con `json_key`.

Consecuencia: si un secreto cambia, las tareas que ya corren conservan el valor anterior hasta reiniciarse.

## Registro en Cloud Map

Cada tarea se registra en un espacio de nombres privado de Cloud Map, con su IP y su puerto (registro SRV). API Gateway consulta ese registro para saber a qué tarea enviar cada petición. Cuando una tarea se detiene, ECS la quita del registro.

El espacio de nombres crea una zona privada de Route 53, que es la que cobra 0,50 USD al mes.

La configuración de salud del registro usa `failure_threshold = 1`. AWS marcó ese argumento como obsoleto (siempre vale 1), y Terraform muestra un aviso de deprecación al validar. Se mantiene explícito porque omitirlo puede hacer que Terraform recree el registro en cada `apply`.

## Solo acepta tráfico de quien se indique

El security group de las tareas solo abre el puerto del contenedor a los security groups de `ingress_security_group_ids`. Aunque la tarea tenga IP pública, nadie más puede conectarse. La salida a internet queda abierta, porque la tarea necesita bajar su imagen y hablar con servicios de AWS.

## La imagen la despliega el pipeline, no Terraform

Terraform compara el código con lo que existe en AWS y, en cada `apply`, corrige las diferencias. Si el pipeline despliega la versión `0.3.0` y el código dice `0.2.0`, el siguiente `apply`, aunque sea para cambiar otra cosa, devolvería el backend a `0.2.0`.

Para evitarlo, el servicio ignora qué definición de tarea está usando (`ignore_changes = [task_definition]`). Las responsabilidades quedan separadas:

- **Terraform** crea el servicio y es dueño de la definición de tarea: CPU, memoria, variables de entorno, secretos, registros, roles y la imagen inicial.
- **El pipeline** (o `scripts/deploy-backend.ps1`) despliega versiones: toma la última revisión de la familia, cambia solo la imagen, registra una revisión nueva y actualiza el servicio.

Consecuencia: un cambio de la definición de tarea hecho con Terraform, por ejemplo una variable de entorno nueva, registra una revisión, pero el servicio no la usa hasta el siguiente despliegue. Como el despliegue parte de la última revisión, el cambio no se pierde: entra con la próxima versión, o antes si se lanza un despliegue a mano.

`lifecycle` no admite valores que vengan de variables, así que el comportamiento es el mismo para todos los entornos y clientes.

## Despliegues que se revierten solos

El circuit breaker de ECS detecta un despliegue cuyas tareas no logran arrancar y vuelve a la versión anterior. Sin él, una imagen rota deja el servicio reintentando sin fin.

## Arquitectura x86 por defecto

Graviton (`ARM64`) cuesta cerca de 20 % menos, pero la imagen debe estar construida para ARM. `X86_64` funciona con imágenes construidas en cualquier PC o pipeline común. Se cambia con `cpu_architecture` cuando la imagen lo soporte.

## ECS Exec opcional

Con `enable_execute_command`, se puede abrir una terminal dentro del contenedor con `aws ecs execute-command`. Es la forma más simple de llegar a la base de datos privada para revisar datos o correr migraciones, sin un servidor bastión. Agrega al rol de la tarea los permisos de Systems Manager que necesita.

## Health check opcional

Un health check del contenedor ejecuta un comando dentro de la imagen, por ejemplo `curl`. No todas las imágenes traen esas herramientas, por eso es opcional. Sin él, una tarea en ejecución se considera sana.
