# bootstrap: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `client` | `string` | Sí | — | Identificador del cliente. Forma parte del nombre del bucket. Solo minúsculas, números y guiones. |
| `aws_profile` | `string` | Sí | — | Perfil de la AWS CLI con el que Terraform se conecta a la cuenta del cliente. |
| `region` | `string` | No | `us-east-1` | Región donde se crea el bucket. |
| `project` | `string` | No | `aws-terraform-platform` | Valor del tag `project` en los recursos. |
| `noncurrent_version_expiration_days` | `number` | No | `90` | Días que se conserva una versión antigua del state antes de eliminarse. |
| `create_github_oidc_provider` | `bool` | No | `false` | Crea el proveedor OIDC de GitHub de la cuenta. `false` si el cliente no usa GitHub Actions o si la cuenta ya lo tiene. |

## Salidas

| Nombre | Descripción |
|---|---|
| `bucket_name` | Nombre del bucket. Es el valor de `bucket` al inicializar el backend de un stack. |
| `bucket_arn` | ARN del bucket. |
| `bucket_region` | Región del bucket. Es el valor de `region` al inicializar el backend de un stack. |
| `github_oidc_provider_arn` | ARN del proveedor OIDC de GitHub. `null` si no se creó. |

## Tags

Todos los recursos llevan estos tags mediante `default_tags` del provider:

| Tag | Valor |
|---|---|
| `client` | Valor de `client`. |
| `project` | Valor de `project`. |
| `managed_by` | `terraform` |

No lleva tag `environment`: el bucket es compartido por todos los entornos del cliente.

## Uso

```
terraform -chdir=bootstrap init
terraform -chdir=bootstrap workspace new <client>
terraform -chdir=bootstrap apply -var="client=<client>" -var="aws_profile=<aws_profile>"
```

Con despliegue desde GitHub Actions, se agrega `-var="create_github_oidc_provider=true"`. Se puede agregar después sobre un cliente ya creado: solo crea el proveedor.

Para volver a trabajar sobre un cliente ya creado:

```
terraform -chdir=bootstrap workspace select <client>
```
