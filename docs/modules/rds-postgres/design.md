# rds-postgres: decisiones de diseño

## RDS y no Aurora

RDS PostgreSQL con `db.t4g.micro` es la opción más barata que sigue siendo una base administrada: respaldos, parches y cifrado los hace AWS. Aurora cuesta más y se justifica con alta carga o alta disponibilidad. Si se adopta, se agrega como un módulo aparte.

## La contraseña la genera AWS

Con `manage_master_user_password`, RDS genera la contraseña y la guarda en Secrets Manager. Terraform nunca la conoce, así que no queda en el state ni en ningún archivo. El backend la recibe desde el secreto.

## La rotación de la contraseña

AWS rota la contraseña administrada cada 7 días por defecto. Si el backend recibe la contraseña al arrancar, como variable de entorno, sigue usando la anterior después de una rotación y sus conexiones nuevas fallan hasta que la tarea se reinicia.

`master_password_rotation_days` permite alargar el intervalo. La solución de fondo es que el backend lea el secreto en tiempo de ejecución y lo vuelva a leer si la conexión falla por autenticación; con eso, el intervalo puede volver a ser corto.

## Privada y con acceso restringido

La base vive en subnets privadas, sin IP pública. Su security group solo abre el puerto 5432 a los security groups de `allowed_security_group_ids`. No tiene reglas de salida: una base de datos no inicia conexiones.

## PostgreSQL exige conexiones cifradas

Desde la versión 15, RDS PostgreSQL rechaza por defecto las conexiones sin SSL. La cadena de conexión del backend debe pedir SSL (por ejemplo `sslmode=require`).

## Versión mayor fija, menores automáticas

Se indica solo la versión mayor (`17`). AWS aplica las versiones menores, que traen parches de seguridad, en la ventana de mantenimiento. Cambiar de versión mayor es una decisión explícita.

## Protección contra borrado activada por defecto

`deletion_protection` y el respaldo final están activos por defecto: un `destroy` accidental no borra datos. En un entorno de prueba que se destruye y recrea seguido, se desactivan desde su archivo de variables.

El respaldo final se llama `<name_prefix>-postgres-final`. Si ya existe uno con ese nombre, de un `destroy` anterior, hay que borrarlo antes del siguiente.

## Una sola zona por defecto

Multi-AZ duplica el costo de la instancia a cambio de que la base siga disponible si falla una zona. Se activa con `multi_az` en producción.

## Almacenamiento gp3, cifrado

gp3 es el tipo de disco de uso general más barato. El almacenamiento y los respaldos se cifran con la llave administrada por RDS, sin costo.
