# aws-terraform-platform

Plataforma de Terraform para levantar en AWS la infraestructura de un SaaS B2B: sitio web, backend en contenedores, base de datos PostgreSQL y almacenamiento de archivos. El mismo código sirve para cualquier producto; cada producto se describe con unos pocos archivos de variables.

## Qué crea

```
Usuario ──HTTPS──> CloudFront ──┬── (por defecto) ──> S3 (sitio estático)
                                └── /api/* ─────────> API Gateway ──> ECS Fargate ──> RDS PostgreSQL
                                                                           └──────> S3 (archivos subidos)
```

| Capa | Servicio de AWS |
|---|---|
| Sitio web | S3 privado + CloudFront |
| Entrada al backend | API Gateway (HTTP API) con VPC Link y Cloud Map |
| Backend | ECS Fargate, imágenes en ECR |
| Base de datos | RDS PostgreSQL, contraseña administrada por AWS en Secrets Manager |
| Archivos de usuarios | S3 privado, con URL prefirmadas |
| Red | VPC con subnets públicas y privadas en dos zonas |
| Dominio propio (opcional) | Route 53 y certificado de ACM |

Sitio y API comparten un solo dominio: CloudFront envía `/api/*` al backend y el resto al sitio. Detalle en [docs/architecture/overview.md](docs/architecture/overview.md).

## Requisitos

| Herramienta | Versión |
|---|---|
| Terraform | 1.10 o superior |
| AWS CLI | v2 |
| TFLint | Para verificar el código |
| PowerShell | 5.1 o superior, para `scripts/tf.ps1` |

Además, una cuenta de AWS y un perfil de la AWS CLI con permisos de administrador sobre ella (`aws configure --profile <perfil>` o `aws configure sso`). Las credenciales nunca se escriben en este repositorio: Terraform usa el perfil por su nombre.

## Estructura

```
aws-terraform-platform/
├── bootstrap/           bucket del state de Terraform, una vez por cuenta
├── modules/             un módulo por responsabilidad
├── stacks/
│   ├── web-app/         compone los módulos: el entorno completo
│   └── dns-zone/        zona DNS del dominio, opcional
├── profiles/
│   ├── minimal.tfvars       tamaño mínimo, para pruebas
│   └── production.tfvars    tamaño de producción
├── clientes/
│   └── ejemplo/         un producto de ejemplo (copiar para uno nuevo)
│       ├── naming.tfvars    producto, empresa, nombres de servicios
│       ├── backend.hcl      bucket del state
│       ├── dev.tfvars       entorno dev
│       └── prod.tfvars      entorno prod
├── scripts/tf.ps1       ejecuta Terraform con los archivos de un producto
└── docs/                arquitectura, módulos y stacks
```

Solo `clientes/ejemplo/` se versiona. Las carpetas de productos reales tienen ids de cuenta y nombres de clientes, y quedan fuera del repositorio por `.gitignore`.

## Guía de uso

### 1. Preparar la cuenta (una vez por cuenta)

Crear el bucket donde Terraform guarda su state:

```
terraform -chdir=bootstrap init
terraform -chdir=bootstrap workspace new <identificador>
terraform -chdir=bootstrap apply -var="client=<identificador>" -var="aws_profile=<perfil>"
```

Anotar el nombre del bucket que muestra al terminar (`tfstate-<identificador>-<account_id>`). Detalle en [docs/modules/bootstrap/](docs/modules/bootstrap/requirements.md).

### 2. Crear la carpeta del producto

Copiar `clientes/ejemplo/` a `clientes/<producto>/` y editar:

| Archivo | Qué completar |
|---|---|
| `naming.tfvars` | `product` (nombre del producto), `client` (empresa dueña), `backend_service_name` y `db_name` |
| `backend.hcl` | El bucket del paso 1 y la región |
| `dev.tfvars` | `aws_profile`, rango de red (`vpc_cidr`) e imagen del backend |

Mientras no exista la imagen propia del backend, `dev.tfvars` puede usar `public.ecr.aws/nginx/nginx:stable` en el puerto 80 para probar que todo el camino funciona.

Los nombres de los recursos siguen el patrón `<servicio>-<producto>-<propósito>-<entorno>`, por ejemplo `ecs-miproducto-api-dev`. Ver [docs/architecture/naming.md](docs/architecture/naming.md).

### 3. Revisar el plan

```
.\scripts\tf.ps1 -Product <producto> -Environment dev -Profile minimal -Command plan
```

El script inicializa el state del producto y entorno, y muestra lo que se crearía. No crea nada. Con `-DryRun` imprime los comandos sin ejecutarlos.

### 4. Crear la infraestructura

```
.\scripts\tf.ps1 -Product <producto> -Environment dev -Profile minimal -Command apply
```

Terraform muestra el plan y pide `yes`. Tarda entre 15 y 20 minutos. Al terminar imprime las salidas: URL del sitio, repositorio ECR, endpoint de la API, dirección de la base.

### 5. Desplegar la aplicación

La infraestructura no incluye el código de la aplicación:

| Qué | Cómo |
|---|---|
| Backend | Subir la imagen a `ecr_repository_url`, poner su etiqueta en `backend_image_tag` (y quitar `backend_image`) y aplicar |
| Sitio | `aws s3 sync <carpeta del build> s3://<site_bucket_name>` y luego invalidar la caché de CloudFront (`site_distribution_id`) |
| Base de datos | Las migraciones de la aplicación |

El backend recibe estas variables de entorno: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` y `UPLOADS_BUCKET`. Debe conectarse a PostgreSQL con SSL. Ver [docs/stacks/web-app/interface.md](docs/stacks/web-app/interface.md).

### 6. Dominio propio (opcional)

1. Crear la zona pública del dominio en Route 53 (desde la consola, o con el stack `stacks/dns-zone`, no ambos).
2. Cargar sus 4 servidores de nombres en el registrador del dominio.
3. Cuando `nslookup -type=NS <dominio>` devuelva los servidores de AWS, agregar al archivo del entorno:

```hcl
dns_zone_name    = "<dominio>"
site_domain_name = "dev.<dominio>"
```

4. Aplicar. Terraform crea el certificado HTTPS, lo valida y crea el registro del sitio.

### 7. Escalar y pasar a producción

| Momento | Comando |
|---|---|
| Pruebas iniciales | `-Environment dev -Profile minimal` |
| `dev` igual a producción | `-Environment dev -Profile production` |
| Producción | `-Environment prod -Profile production` |

Cambiar de perfil sobre el mismo entorno modifica lo existente; no crea un entorno nuevo. Ver [docs/architecture/environments.md](docs/architecture/environments.md).

## Costos

| Perfil | USD al mes, aproximado |
|---|---|
| `minimal` | ~29 |
| `production` | ~85 |
| Entorno destruido | ~0 |

Detalle por servicio en [docs/architecture/costs.md](docs/architecture/costs.md). Para no pagar entre pruebas: `-Command destroy` con el perfil `minimal`, que no protege los datos.

## Verificar el código

```
terraform fmt -check -recursive
terraform -chdir=stacks/web-app validate
tflint --recursive
```

## Documentación

Toda la documentación está en [docs/](docs/README.md): arquitectura, nombres, entornos, costos y cada módulo con su requisito, interfaz y decisiones de diseño.

## Limitaciones

- API Gateway corta las peticiones a los 30 segundos, admite hasta 10 MB por petición y no soporta WebSockets.
- El endpoint de API Gateway es alcanzable sin pasar por CloudFront.
- Una región por despliegue (`us-east-1` por defecto, que es la que exige CloudFront para sus certificados).
- Sin CI todavía: los comandos se ejecutan desde el computador de quien opera.
