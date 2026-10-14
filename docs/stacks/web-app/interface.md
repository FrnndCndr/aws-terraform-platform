# web-app: interfaz

## Variables

### Entorno

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `client` | `string` | Sí | — | Identificador del cliente. Solo minúsculas, números y guiones. |
| `environment` | `string` | Sí | — | Entorno: `dev` o `prod`. |
| `aws_profile` | `string` | Sí | — | Perfil de la AWS CLI con el que Terraform se conecta a la cuenta del cliente. |
| `region` | `string` | No | `us-east-1` | Región de los recursos. |
| `project` | `string` | No | `aws-terraform-platform` | Valor del tag `project`. |
| `log_retention_days` | `number` | No | `7` | Días que se conservan los registros del backend y de la API. |

### Red

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `vpc_cidr` | `string` | Sí | — | Rango de direcciones de la VPC, con máscara `/16`. |
| `az_count` | `number` | No | `2` | Cantidad de zonas de disponibilidad. |
| `excluded_zone_ids` | `list(string)` | No | `["use1-az3"]` | Zonas de disponibilidad (por id) que no se usan. |
| `enable_nat_gateway` | `bool` | No | `false` | Crea NAT Gateway. Con NAT, las tareas del backend pasan a las subnets privadas, sin IP pública. |
| `single_nat_gateway` | `bool` | No | `true` | Con NAT activo, uno solo para todas las zonas. |

### Sitio y dominio

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `site_force_destroy` | `bool` | No | `false` | Permite destruir el bucket del sitio aunque tenga archivos. |
| `site_price_class` | `string` | No | `PriceClass_100` | Conjunto de ubicaciones de CloudFront. |
| `dns_zone_name` | `string` | No | `null` | Zona de Route 53 del dominio, creada por el stack `dns-zone`. |
| `site_domain_name` | `string` | No | `null` | Dominio del sitio en este entorno, por ejemplo `dev.ejemplo.cl`. Requiere `dns_zone_name`. Sin él, se usa el dominio de CloudFront. |

### Backend

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `backend_image` | `string` | No | `null` | Imagen completa del backend. `null` usa el repositorio ECR del entorno con `backend_image_tag`. |
| `backend_image_tag` | `string` | No | `latest` | Etiqueta de la imagen en el repositorio ECR. |
| `backend_container_port` | `number` | No | `8080` | Puerto en el que escucha el backend. |
| `backend_cpu` | `number` | No | `256` | CPU de la tarea (1024 = 1 vCPU). |
| `backend_memory` | `number` | No | `512` | Memoria de la tarea, en MB. |
| `backend_cpu_architecture` | `string` | No | `X86_64` | `X86_64` o `ARM64`. |
| `backend_desired_count` | `number` | No | `1` | Cantidad de tareas. |
| `backend_environment` | `map(string)` | No | `{}` | Variables de entorno adicionales del backend. |
| `backend_health_check` | `object` | No | `null` | Health check del contenedor. Ver `ecs-service`. |
| `backend_enable_execute_command` | `bool` | No | `false` | Permite abrir una terminal en el contenedor con ECS Exec. |
| `ecr_image_tag_mutability` | `string` | No | `MUTABLE` | `MUTABLE` o `IMMUTABLE`. |
| `ecr_force_delete` | `bool` | No | `false` | Permite destruir el repositorio aunque tenga imágenes. |
| `api_throttling_rate_limit` | `number` | No | `50` | Peticiones por segundo sostenidas en API Gateway. |
| `api_throttling_burst_limit` | `number` | No | `100` | Ráfaga máxima en API Gateway. |

### Base de datos

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `db_name` | `string` | No | `app` | Nombre de la base. |
| `db_engine_version` | `string` | No | `17` | Versión mayor de PostgreSQL. |
| `db_instance_class` | `string` | No | `db.t4g.micro` | Clase de instancia. |
| `db_allocated_storage_gb` | `number` | No | `20` | Almacenamiento inicial, en GB. |
| `db_max_allocated_storage_gb` | `number` | No | `null` | Límite del crecimiento automático del almacenamiento. |
| `db_multi_az` | `bool` | No | `false` | Copia en otra zona. |
| `db_backup_retention_days` | `number` | No | `7` | Días de respaldos automáticos. |
| `db_deletion_protection` | `bool` | No | `true` | Impide borrar la base. |
| `db_skip_final_snapshot` | `bool` | No | `false` | Borra la base sin respaldo final. |
| `db_apply_immediately` | `bool` | No | `false` | Aplica los cambios de la base al momento. |
| `db_password_rotation_days` | `number` | No | `365` | Días entre rotaciones de la contraseña administrada. |

### Archivos subidos

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `uploads_versioning` | `bool` | No | `false` | Versionado del bucket de archivos. |
| `uploads_force_destroy` | `bool` | No | `false` | Permite destruir el bucket de archivos aunque tenga contenido. |

## Variables de entorno que recibe el backend

| Variable | Origen |
|---|---|
| `DB_HOST` | Dirección de la base |
| `DB_PORT` | Puerto de la base |
| `DB_NAME` | Nombre de la base |
| `DB_USERNAME` | Secreto de la base, campo `username` |
| `DB_PASSWORD` | Secreto de la base, campo `password` |
| `UPLOADS_BUCKET` | Nombre del bucket de archivos |

`backend_environment` agrega más variables. Si repite un nombre de esta tabla, prevalece el de la tabla. ECS agrega por su cuenta `AWS_REGION`.

## Salidas

| Nombre | Descripción |
|---|---|
| `vpc_id` | Identificador de la VPC. |
| `public_subnet_ids` | Subnets públicas. |
| `private_subnet_ids` | Subnets privadas. |
| `site_bucket_name` | Bucket donde se suben los archivos del sitio. |
| `site_distribution_id` | Distribución de CloudFront, para invalidar la caché. |
| `site_url` | URL del sitio. |
| `ecr_repository_url` | Destino de `docker push` del backend. |
| `ecs_cluster_name` | Cluster del backend. |
| `ecs_service_name` | Servicio del backend. Se usa para forzar un nuevo despliegue. |
| `backend_log_group_name` | Registros del backend en CloudWatch. |
| `api_endpoint` | Endpoint de API Gateway. |
| `db_address` | Dirección de la base. |
| `db_secret_arn` | Secreto con el usuario y la contraseña de la base. |
| `uploads_bucket_name` | Bucket de archivos subidos. |

## Archivo de variables

Un archivo por cliente y entorno, en `clientes/<client>/<environment>.tfvars`. El de ejemplo, para un entorno de prueba que se destruye y recrea seguido:

```hcl
client      = "ejemplo"
environment = "dev"
aws_profile = "ejemplo-dev"

vpc_cidr = "10.20.0.0/16"

site_force_destroy = true

backend_image                  = "public.ecr.aws/nginx/nginx:stable"
backend_container_port         = 80
backend_enable_execute_command = true
ecr_force_delete               = true

db_deletion_protection = false
db_skip_final_snapshot = true
db_apply_immediately   = true

uploads_force_destroy = true
```

`backend_image` apunta a una imagen pública de `nginx` mientras no exista la imagen propia en ECR. Con dominio propio se agregan:

```hcl
dns_zone_name    = "ejemplo.cl"
site_domain_name = "dev.ejemplo.cl"
```

Solo `clientes/ejemplo/` se versiona. Los archivos de clientes reales quedan fuera del repositorio.

## Uso

Inicializar el backend, una vez por cliente y entorno:

```
terraform -chdir=stacks/web-app init \
  -backend-config="bucket=<bucket del state>" \
  -backend-config="key=<client>/<environment>/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="profile=<aws_profile>"
```

Planificar y aplicar:

```
terraform -chdir=stacks/web-app plan  -var-file=../../clientes/<client>/<environment>.tfvars
terraform -chdir=stacks/web-app apply -var-file=../../clientes/<client>/<environment>.tfvars
```

Para cambiar de cliente o entorno en el mismo directorio de trabajo, se repite `init` con la nueva configuración y la opción `-reconfigure`.
