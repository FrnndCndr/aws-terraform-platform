# github-oidc: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `product` | `string` | Sí | — | Producto SaaS. Forma parte de cada nombre. |
| `environment` | `string` | Sí | — | Entorno: `dev` o `prod`. Forma parte de cada nombre. |
| `oidc_provider_arn` | `string` | Sí | — | ARN del proveedor OIDC de GitHub de la cuenta. |
| `github_owner` | `string` | Sí | — | Organización o usuario de GitHub dueño de los repositorios. |
| `github_owner_id` | `string` | No | `null` | Id numérico de la organización o usuario. Con él, la confianza usa el formato inmutable del `sub`; `null` usa el formato por nombre. |
| `github_environment` | `string` | Sí | — | Environment de GitHub desde el que se despliega, por ejemplo `dev`. |
| `backend_repository` | `string` | No | `null` | Repositorio del backend, sin el owner. `null` no crea el rol del backend. |
| `backend_repository_id` | `string` | No | `null` | Id numérico del repositorio del backend. Obligatorio con `github_owner_id` y `backend_repository`. |
| `backend_service_name` | `string` | No | `backend` | Propósito del servicio del backend en el nombre del rol. |
| `ecr_repository_arn` | `string` | No | `null` | Repositorio ECR del entorno. Obligatorio con `backend_repository`. |
| `ecs_service_arn` | `string` | No | `null` | Servicio ECS del entorno. Obligatorio con `backend_repository`. |
| `ecs_pass_role_arns` | `list(string)` | No | `[]` | Rol de ejecución y rol de la tarea del servicio. Obligatorio con `backend_repository`. |
| `frontend_repository` | `string` | No | `null` | Repositorio del frontend, sin el owner. `null` no crea el rol del frontend. |
| `frontend_repository_id` | `string` | No | `null` | Id numérico del repositorio del frontend. Obligatorio con `github_owner_id` y `frontend_repository`. |
| `site_bucket_arn` | `string` | No | `null` | Bucket del sitio. Obligatorio con `frontend_repository`. |
| `site_distribution_arn` | `string` | No | `null` | Distribución de CloudFront del sitio. Obligatorio con `frontend_repository`. |

## Salidas

| Nombre | Descripción |
|---|---|
| `backend_role_arn` | ARN del rol del backend. `null` si no se creó. Valor de `role-to-assume` en el workflow. |
| `frontend_role_arn` | ARN del rol del frontend. `null` si no se creó. |

## Nombres

Con `product = "ejemplo"`, `environment = "dev"` y `backend_service_name = "api"`:

| Rol | Nombre |
|---|---|
| Backend | `iam-ejemplo-api-deploy-dev` |
| Frontend | `iam-ejemplo-static-site-deploy-dev` |

## Id de GitHub

Los id se consultan con la CLI de GitHub:

```
gh api orgs/<owner> --jq .id
gh api repos/<owner>/<repo> --jq .id
gh api repos/<owner>/<repo>/actions/oidc/customization/sub
```

El último dice si el repositorio emite el formato inmutable (`use_immutable_subject: true`). Los id van como texto en los `.tfvars`.

## Uso en el workflow

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    environment: dev
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
```

`environment` en el job es lo que hace que el token lleve `environment:dev` en el `sub`. Sin él, AWS rechaza el rol.
