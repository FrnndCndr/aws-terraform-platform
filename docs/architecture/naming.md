# Nombres

Los nombres de todos los recursos se arman a partir del producto y el entorno. El producto se define en `clientes/<product>/naming.tfvars`; ningún nombre de producto ni de cliente está escrito en el código.

## El patrón

```
<servicio>-<product>-<propósito>-<environment>
```

| Parte | Qué es | Ejemplo |
|---|---|---|
| `servicio` | Abreviatura del servicio de AWS, fija en cada módulo | `s3`, `ecs`, `rds` |
| `product` | El producto SaaS | `ejemplo` |
| `propósito` | Para qué sirve el recurso, cuando el servicio tiene más de uno. Se omite si no hace falta | `static-site`, `upload-files` |
| `environment` | El entorno | `dev` |

Leer el nombre basta para saber qué es, de qué producto y de qué entorno, sin abrir el recurso.

## Los valores

| Variable | Dónde se define | Qué es | Ejemplo |
|---|---|---|---|
| `product` | `naming.tfvars` | El producto SaaS. Forma parte de cada nombre. | `ejemplo` |
| `client` | `naming.tfvars` | La empresa dueña del producto. Va solo como tag, para filtrar costos. | `ejemplo-corp` |
| `backend_service_name` | `naming.tfvars` | El propósito del servicio del backend. | `api` |
| `db_name` | `naming.tfvars` | La base que se crea dentro de PostgreSQL. | `app` |
| `environment` | `<environment>.tfvars` | El entorno: `dev` o `prod`. | `dev` |

Todos admiten solo minúsculas, números y guiones (`db_name`, además, guion bajo en lugar de guion). Cambiar un valor después de aplicar reemplaza los recursos que lo usan: se eligen una vez.

## Nombres por servicio

Con `product = "ejemplo"`, `environment = "dev"` y `backend_service_name = "api"`:

| Servicio | Nombre | Módulo |
|---|---|---|
| VPC | `vpc-ejemplo-dev` | `network` |
| Subnets | `subnet-ejemplo-public-<zona>-dev`, `subnet-ejemplo-private-<zona>-dev` | `network` |
| Internet Gateway | `igw-ejemplo-dev` | `network` |
| Tablas de rutas | `rt-ejemplo-public-dev`, `rt-ejemplo-private-<zona>-dev` | `network` |
| NAT Gateway y su IP | `nat-ejemplo-<zona>-dev`, `eip-ejemplo-nat-<zona>-dev` | `network` |
| Bucket del sitio | `s3-ejemplo-static-site-dev-<account_id>` | `static-site` |
| Acceso de CloudFront al bucket | `oac-ejemplo-static-site-dev` | `static-site` |
| CloudFront Function | `cff-ejemplo-rewrite-index-dev` | `static-site` |
| Repositorio de imágenes | `ecr-ejemplo-api-dev` | `ecr` |
| Cluster ECS | `ecs-ejemplo-dev` | `ecs-service` |
| Servicio ECS | `ecs-ejemplo-api-dev` | `ecs-service` |
| Definición de tarea | `task-ejemplo-api-dev` | `ecs-service` |
| Roles de IAM | `iam-ejemplo-api-execution-dev`, `iam-ejemplo-api-task-dev` | `ecs-service` |
| Security group del backend | `secgroup-ejemplo-api-dev` | `ecs-service` |
| Logs del backend | `/ecs/ejemplo-api-dev` | `ecs-service` |
| Espacio de Cloud Map | `ejemplo-dev.internal` | `ecs-service` |
| API HTTP | `apigw-ejemplo-api-dev` | `api-gateway` |
| VPC Link y su security group | `vpclink-ejemplo-api-dev`, `secgroup-ejemplo-vpc-link-dev` | `api-gateway` |
| Logs de acceso de la API | `/aws/apigateway/ejemplo-api-dev` | `api-gateway` |
| Base de datos | `rds-ejemplo-postgres-dev` | `rds-postgres` |
| Grupo de subnets y security group de la base | `dbsubnet-ejemplo-postgres-dev`, `secgroup-ejemplo-postgres-dev` | `rds-postgres` |
| Respaldo final de la base | `rds-ejemplo-postgres-dev-final` | `rds-postgres` |
| Bucket de archivos subidos | `s3-ejemplo-upload-files-dev-<account_id>` | `uploads-bucket` |
| Secretos de la aplicación | `secret-ejemplo-<nombre>-dev`, por ejemplo `secret-ejemplo-jwt-key-dev` | `app-secrets` |

## Excepciones

| Recurso | Nombre | Motivo |
|---|---|---|
| Security groups | Empiezan con `secgroup-`, no `sg-` | AWS reserva el prefijo `sg-` para los ids de los security groups y rechaza nombres que empiecen así. |
| Buckets de S3 | Terminan en `-<account_id>` | Los nombres de S3 son únicos en todo AWS, no solo en la cuenta. El id de cuenta evita que otro los tome antes, o que ocupe el nombre mientras el entorno está destruido. Se lee de la sesión activa. |
| Logs | Ruta con `/`, sin abreviatura de servicio | Convención de CloudWatch: la ruta ya dice el servicio. |
| Espacio de Cloud Map | `<product>-<environment>.internal` | Es un nombre de dominio interno. |
| Secreto de la contraseña de la base | Lo nombra RDS (`rds!db-...`) | RDS lo crea y no permite elegir el nombre. |
| Bucket de state | `tfstate-<identificador>-<account_id>` | Se crea una vez por cuenta, con `bootstrap`, antes que cualquier producto. |
| Zona de Route 53 | El dominio | Su nombre es el dominio mismo. |

## Producto, no cliente, en el nombre

Una empresa puede tener varios productos en la misma cuenta de AWS. Con el producto en el nombre, no chocan. El cliente queda en el tag `client`, que basta para separar la facturación por empresa.

## Tags

Todos los recursos llevan, mediante `default_tags` del provider:

| Tag | Valor |
|---|---|
| `product` | `product` |
| `client` | `client` |
| `environment` | `environment` |
| `project` | `aws-terraform-platform` |
| `managed_by` | `terraform` |

Los recursos de red, que en la consola se identifican por su tag `Name`, llevan además `Name` con el nombre de la tabla.
