# bootstrap: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `client` | `string` | Sí | — | Identificador del cliente. Forma parte del nombre del bucket. Solo minúsculas, números y guiones. |
| `aws_profile` | `string` | Sí | — | Perfil de la AWS CLI con el que Terraform se conecta a la cuenta del cliente. |
| `region` | `string` | No | `us-east-1` | Región donde se crea el bucket. |
| `project` | `string` | No | `aws-terraform-platform` | Valor del tag `project` en los recursos. |
| `noncurrent_version_expiration_days` | `number` | No | `90` | Días que se conserva una versión antigua del state antes de eliminarse. |

## Salidas

| Nombre | Descripción |
|---|---|
| `bucket_name` | Nombre del bucket. Es el valor de `bucket` al inicializar el backend de un stack. |
| `bucket_arn` | ARN del bucket. |
| `bucket_region` | Región del bucket. Es el valor de `region` al inicializar el backend de un stack. |

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

Para volver a trabajar sobre un cliente ya creado:

```
terraform -chdir=bootstrap workspace select <client>
```
