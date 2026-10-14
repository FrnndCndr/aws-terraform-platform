# rds-postgres: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `name_prefix` | `string` | Sí | — | Prefijo de los nombres, con la forma `<client>-<environment>`. |
| `vpc_id` | `string` | Sí | — | VPC de la base. |
| `subnet_ids` | `list(string)` | Sí | — | Subnets privadas, en al menos dos zonas. |
| `allowed_security_group_ids` | `map(string)` | No | `{}` | Security groups que pueden conectarse al puerto 5432. Clave: etiqueta descriptiva. |
| `engine_version` | `string` | No | `17` | Versión mayor de PostgreSQL. AWS aplica las versiones menores. |
| `instance_class` | `string` | No | `db.t4g.micro` | Clase de instancia. |
| `allocated_storage_gb` | `number` | No | `20` | Almacenamiento inicial, en GB. |
| `max_allocated_storage_gb` | `number` | No | `null` | Límite del crecimiento automático del almacenamiento. `null` lo desactiva. |
| `db_name` | `string` | No | `app` | Nombre de la base que se crea. |
| `master_username` | `string` | No | `postgres` | Usuario administrador. |
| `multi_az` | `bool` | No | `false` | Mantiene una copia en otra zona que toma el control si la principal falla. |
| `backup_retention_days` | `number` | No | `7` | Días que se conservan los respaldos automáticos. |
| `deletion_protection` | `bool` | No | `true` | Impide borrar la base. |
| `skip_final_snapshot` | `bool` | No | `false` | Borra la base sin respaldo final. |
| `apply_immediately` | `bool` | No | `false` | Aplica los cambios al momento, en vez de esperar la ventana de mantenimiento. |
| `master_password_rotation_days` | `number` | No | `null` | Días entre rotaciones de la contraseña. `null` deja el valor de AWS (7 días). |

## Salidas

| Nombre | Descripción |
|---|---|
| `address` | Dirección DNS de la base. |
| `port` | Puerto de la base. |
| `db_name` | Nombre de la base. |
| `master_user_secret_arn` | ARN del secreto con el usuario y la contraseña, en JSON (`username`, `password`). |
| `security_group_id` | Security group de la base. |
| `instance_identifier` | Identificador de la instancia RDS. |
