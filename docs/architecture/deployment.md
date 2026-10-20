# Despliegue de la aplicación

## Quién hace qué

| Qué | Con qué | Cuándo |
|---|---|---|
| Infraestructura: red, base, servicio, buckets, permisos | Terraform, desde este repositorio | Cuando cambia la infraestructura |
| Versiones del backend y del frontend | Pipeline de GitHub Actions, desde el repositorio de cada aplicación | En cada cambio de código |
| Versiones, sin pipeline | `scripts/deploy-backend.ps1` y `scripts/deploy-frontend.ps1`, desde este repositorio | Cliente sin GitHub, pipeline caído o emergencia |

Terraform no despliega versiones de la aplicación. Si lo hiciera, el pipeline y Terraform se disputarían la imagen del backend, y un `apply` cualquiera podría devolver el backend a una versión vieja. Ver `docs/modules/ecs-service/design.md`.

## Ramas y entornos

```
rama de trabajo ──PR──▶ dev ──PR──▶ main
                         │            │
                    despliega dev   despliega prod
```

| Rama | Recibe código de | Al recibirlo |
|---|---|---|
| `dev` | PR de cualquier rama, con la verificación en verde | Despliega a `dev` |
| `main` | Solo PR desde `dev`, con la verificación en verde | Despliega a `prod` |

- Mergear el PR de `dev` a `main` es la decisión de publicar. `main` siempre refleja lo que corre en prod.
- Un arreglo urgente también pasa primero por `dev`.
- Mientras no exista `prod`, no hay workflow de despliegue a prod: un merge a `main` solo verifica.

`main` solo acepta código de `dev` por dos reglas de GitHub en cada repositorio:

1. Regla de rama en `main`: PR obligatorio, sin push directo ni force push.
2. El chequeo `source-branch` como requerido: falla si la rama de origen del PR no es `dev`, y mientras falle GitHub no deja mergear.

## Pipeline del backend

Al recibir un push en `dev`:

1. Asume el rol del backend por OIDC, desde el environment de GitHub `dev`.
2. Construye la imagen con la etiqueta `<versión>-<commit corto>`. Nunca `latest`.
3. Revisa que la imagen no contenga archivos `.env`. Si encuentra alguno, falla sin subir nada.
4. Sube la imagen a ECR.
5. Toma la última revisión de la definición de tarea, cambia solo la imagen del contenedor, registra una revisión nueva y actualiza el servicio.
6. Espera a que el servicio quede estable y comprueba que la ruta de salud responda 200.

Si las tareas nuevas no arrancan, el circuit breaker de ECS vuelve a la revisión anterior y el workflow falla.

Un cambio de la definición de tarea hecho con Terraform (variables, secretos, CPU) entra en el siguiente despliegue. Para aplicarlo antes, se lanza el workflow a mano.

### Variables de primer arranque

Una variable que la aplicación usa solo la primera vez, por ejemplo la que carga los datos iniciales de la base, se activa en el `.tfvars` del entorno solo para el primer despliegue. Después se desactiva y se aplica. Si quedara activa, correría en cada despliegue y en cada reinicio de las tareas, porque el pipeline conserva las variables de la definición de tarea.

## Pipeline del frontend

Al recibir un push en `dev`:

1. Asume el rol del frontend por OIDC.
2. Instala dependencias y construye el sitio.
3. Revisa la salida: tiene `index.html` y no apunta a `localhost` ni a `execute-api`.
4. Sincroniza la carpeta con el bucket del sitio, borrando lo que ya no existe, e invalida la caché de CloudFront.
5. Comprueba que el sitio responda 200.

## Prod

Al mergear `dev` en `main`:

- **Backend:** no se reconstruye. Se despliega la imagen que ya se construyó y probó en `dev` para ese mismo commit.
- **Frontend:** se construye desde el mismo commit con la configuración pública de prod, porque esa configuración queda fija en los archivos del sitio al construirlo.

Prod usa sus propios roles (`github_environment = "production"`) y el environment de GitHub `production`, que solo admite la rama `main`.

## Configuración en GitHub

En cada repositorio de la aplicación:

| Qué | Valor |
|---|---|
| Environment `dev` | Rama permitida: `dev` |
| Environment `production` | Rama permitida: `main`. Se crea junto con prod |
| Regla de rama en `main` | PR obligatorio, sin push directo ni force push, chequeo `source-branch` requerido |

Variables del environment, todas de `terraform output` del stack `web-app`. Ninguna es secreta: los permisos los da el rol, no una llave.

| Variable | Backend | Frontend | Salida de Terraform |
|---|---|---|---|
| `AWS_REGION` | Sí | Sí | Región del stack |
| `AWS_ROLE_ARN` | Sí | Sí | `github_backend_role_arn` / `github_frontend_role_arn` |
| `ECR_REPOSITORY_URL` | Sí | | `ecr_repository_url` |
| `ECS_CLUSTER` | Sí | | `ecs_cluster_name` |
| `ECS_SERVICE` | Sí | | `ecs_service_name` |
| `TASK_DEFINITION_FAMILY` | Sí | | `ecs_task_definition_family` |
| `CONTAINER_NAME` | Sí | | `backend_container_name` |
| `HEALTH_URL` | Sí | | `site_url` + ruta de salud de la aplicación |
| `SITE_BUCKET` | | Sí | `site_bucket_name` |
| `DISTRIBUTION_ID` | | Sí | `site_distribution_id` |
| `SITE_URL` | | Sí | `site_url` |

## Plantillas

`templates/github-actions/` tiene los workflows genéricos, sin nombres de producto ni de cliente:

| Archivo | Qué hace |
|---|---|
| `deploy-backend.yml` | Pipeline del backend |
| `deploy-frontend.yml` | Pipeline del frontend |
| `source-branch.yml` | Chequeo de que un PR a `main` venga de `dev` |

Se copian a `.github/workflows/` del repositorio de la aplicación. Lo propio de cada aplicación (Dockerfile, comandos de build, carpeta de salida, versión) se ajusta en las líneas marcadas por variables.

## Despliegue manual

Para un cliente sin GitHub Actions, o si el pipeline no está disponible. Hacen lo mismo que el pipeline, con las credenciales del perfil del entorno y los datos de `terraform output`.

```
.\scripts\deploy-backend.ps1 -Product <product> -Environment <environment> -Version <etiqueta>
.\scripts\deploy-frontend.ps1 -Product <product> -Environment <environment> -SourcePath <carpeta construida>
```

- `deploy-backend.ps1` despliega una imagen que ya está en ECR. No construye.
- `deploy-frontend.ps1` sube una carpeta ya construida. No construye, porque cada aplicación se construye distinto.

## Alta de un cliente nuevo con pipeline

1. `bootstrap` con `create_github_oidc_provider = true`, o sin él si la cuenta ya tiene el proveedor.
2. `github_owner` y los repositorios en `clientes/<product>/<environment>.tfvars`. Si los repositorios emiten el formato inmutable del `sub`, también sus id (ver `docs/modules/github-oidc/interface.md`). Luego `apply` del stack.
3. Environments, variables y regla de rama en GitHub.
4. Copiar las plantillas al repositorio de cada aplicación.
5. Un push a `dev` despliega. Después, `terraform plan` debe mostrar `No changes`.

## Cambio de organización de GitHub

Cuando los repositorios pasan a otra organización, se cambia `github_owner` en los `.tfvars` de cada entorno (y `github_owner_id`, si se usa el formato inmutable; los id de los repositorios no cambian) y se aplica. Los roles pasan a confiar en la organización nueva, y la anterior deja de poder desplegar. Se revisa que los environments y sus variables se hayan movido con el repositorio.
