# web-app: decisiones de diseño

## El stack compone, los módulos crean

Cada módulo crea los recursos de una responsabilidad y no conoce a los demás. El stack los conecta: pasa las salidas de uno como variables de otro (por ejemplo, las subnets de `network` al balanceador). Así un módulo se puede reutilizar en otro stack sin modificarlo.

## Nombres uniformes

El stack entrega `product` y `environment` a todos los módulos, y cada módulo arma sus nombres con el patrón `<servicio>-<product>-<propósito>-<environment>`. Los nombres quedan uniformes, y dos entornos o dos productos no chocan en la misma cuenta. El patrón completo está en `docs/architecture/naming.md`.

## Los tags se aplican en el provider

`default_tags` del provider agrega `product`, `client`, `environment`, `project` y `managed_by` a todos los recursos que los admiten. Ningún módulo repite esos tags, y un recurso nuevo los recibe sin que nadie tenga que recordarlo. Sirven para filtrar costos por cliente y entorno en la facturación de AWS.

## El backend se configura al inicializar

`backend.tf` declara el backend S3 sin bucket, key, región ni perfil. Esos valores cambian con cada cliente y entorno, y el bloque `backend` de Terraform no admite variables. Se entregan en `terraform init` con `-backend-config`. El bloqueo nativo de S3 (`use_lockfile`) sí queda fijo en el código, porque aplica a todos.

## El perfil de AWS es una variable

El provider recibe `aws_profile` desde el archivo de variables. El código no depende de un nombre de perfil ni del tipo de credencial que hay detrás.

## `environment` solo admite `dev` o `prod`

Una validación rechaza otros valores. Evita crear por error un entorno con un nombre mal escrito, que tendría recursos y state propios.

## Las versiones están fijadas en un solo lugar

La versión mínima de Terraform y la del provider de AWS se declaran en el stack. Los módulos declaran qué provider necesitan, sin configurarlo: lo heredan del stack.

## Las conexiones entre módulos

| Desde | Hacia | Qué pasa |
|---|---|---|
| `network` | Todos | VPC y subnets |
| `ecs-service` | `api-gateway` | Servicio de Cloud Map, destino de la integración |
| `api-gateway` | `ecs-service` | Security group del VPC Link, autorizado en el backend |
| `api-gateway` | `static-site` | Dominio del endpoint, origen de `/api/*` |
| `ecs-service` | `rds-postgres` | Security group del backend, autorizado en la base |
| `rds-postgres` | `ecs-service` | Dirección de la base y secreto de la contraseña |
| `static-site` | `uploads-bucket` | Dominio del sitio, origen autorizado por CORS |
| `uploads-bucket` | `ecs-service` | Nombre del bucket y política de acceso |
| `ecr` | `ecs-service` | Repositorio de la imagen |
| `ecr`, `ecs-service` | `github-oidc` | Repositorio, servicio y roles del servicio, recursos del rol del backend |
| `static-site` | `github-oidc` | Bucket y distribución, recursos del rol del frontend |

Varias conexiones van en ambos sentidos entre los mismos módulos. Terraform lo admite porque las dependencias se resuelven entre recursos, no entre módulos: el security group del backend no depende de la base, y la regla de la base que lo autoriza sí.

## Dónde corre el backend

Sin NAT Gateway, las tareas van en las subnets públicas con IP pública: es su única salida a internet. Con NAT Gateway, el stack las mueve a las subnets privadas y quita la IP pública. El cambio es una variable.

## Imagen del backend

`backend_image_tag` (o `backend_image`) es la imagen con que se crea el servicio. Mientras no exista la imagen propia, `backend_image` apunta a una imagen pública (por ejemplo `nginx`) para comprobar que todo el camino funciona.

Las versiones siguientes no se publican con Terraform: las despliega el pipeline de GitHub Actions, o `scripts/deploy-backend.ps1`. Cambiar la etiqueta y aplicar solo registra una revisión de la definición de tarea, que entra con el siguiente despliegue. El motivo está en `docs/modules/ecs-service/design.md`, y el flujo completo en `docs/architecture/deployment.md`.

## Roles de despliegue opcionales

Con `github_owner`, el stack crea los roles que GitHub Actions asume para desplegar el backend y el frontend de este entorno. Busca el proveedor OIDC de la cuenta por su URL; lo crea `bootstrap`, o ya existía. Sin `github_owner`, no crea roles ni busca el proveedor: el entorno se despliega con los scripts.

`github_environment` vale por defecto lo mismo que `environment`. Se cambia cuando el environment de GitHub tiene otro nombre, por ejemplo `production` para `prod`.

Cuando los repositorios cambian de organización, se cambia `github_owner` (y `github_owner_id` con el formato inmutable) y se aplica: los roles pasan a confiar en la organización nueva.

## Dominio propio opcional

Con `site_domain_name`, el stack busca la zona de Route 53 por su nombre (`dns_zone_name`), emite el certificado y crea el registro del sitio. La zona la crea antes el stack `dns-zone`. Sin dominio, el sitio usa el dominio de CloudFront y el resto no cambia.

Los orígenes autorizados por CORS en el bucket de archivos incluyen el dominio de CloudFront y, si existe, el propio.

## La plataforma se adapta a los nombres de cada aplicación

Cada aplicación lee su configuración con sus propios nombres de variables. En lugar de obligar a todas a usar los mismos, el stack expone `backend_env_names`: los datos son siempre los mismos (dirección, puerto, base, usuario, contraseña, bucket) y solo cambia con qué nombre llegan. Una aplicación nueva se integra con un archivo de variables, sin cambios de código en ella ni en la plataforma.

## Secretos de la aplicación

Las llaves de la aplicación (firma de tokens, credenciales de correo u otros servicios) se crean vacías con el módulo `app-secrets` y se cargan a mano. El stack las inyecta junto con las credenciales de la base. El orden en un entorno nuevo es: aplicar, cargar los valores, desplegar la imagen que los usa.

## Rotación de la contraseña de la base

El backend recibe la contraseña al arrancar. Para que una rotación no lo deje sin conexión, el stack rota la contraseña cada 365 días en vez de cada 7. Antes de acortar ese plazo, el backend debe leer el secreto en tiempo de ejecución.
