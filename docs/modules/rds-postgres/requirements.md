# rds-postgres: requisito

## Propósito

Crear la base de datos PostgreSQL de un entorno en RDS, privada y con la contraseña administrada por AWS.

## Qué debe cumplir

1. Crea una instancia RDS PostgreSQL en subnets privadas, sin acceso público.
2. Solo acepta conexiones en el puerto 5432 desde los security groups indicados.
3. AWS genera la contraseña del usuario administrador y la guarda en Secrets Manager. La contraseña no pasa por Terraform ni queda en el state.
4. Cifra el almacenamiento y hace respaldos automáticos diarios.
5. La clase de instancia, el almacenamiento, Multi-AZ, la retención de respaldos y la protección contra borrado son configurables.
6. Entrega como salida la dirección, el puerto, el nombre de la base y el ARN del secreto.

## Qué no hace

- No crea usuarios, esquemas ni tablas: eso lo hacen las migraciones de la aplicación.
- No crea réplicas de lectura.

## Costo

| Recurso | Costo mensual aproximado |
|---|---|
| `db.t4g.micro`, una zona | ~11,7 USD |
| `db.t4g.micro`, Multi-AZ | ~23,4 USD |
| Almacenamiento gp3 | 0,115 USD por GB; 20 GB = ~2,3 USD |
| Respaldos | Sin costo hasta el tamaño de la base |
| Secreto de la contraseña | ~0,40 USD |

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, una tarea del backend se conecta con el usuario y la contraseña del secreto.
- La base no es alcanzable desde internet.
