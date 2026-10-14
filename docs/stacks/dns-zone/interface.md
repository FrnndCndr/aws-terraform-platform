# dns-zone: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `product` | `string` | Sí | — | Producto dueño del dominio. |
| `client` | `string` | Sí | — | Empresa dueña del producto. Va como tag. |
| `aws_profile` | `string` | Sí | — | Perfil de la AWS CLI de la cuenta del cliente. |
| `region` | `string` | No | `us-east-1` | Región del provider. Route 53 es global. |
| `project` | `string` | No | `aws-terraform-platform` | Valor del tag `project`. |
| `domain_name` | `string` | Sí | — | Dominio del cliente, por ejemplo `ejemplo.cl`. |

## Salidas

| Nombre | Descripción |
|---|---|
| `zone_id` | Identificador de la zona. |
| `name_servers` | Los cuatro servidores de nombres que se cargan en el registrador. |

## Uso

```
terraform -chdir=stacks/dns-zone init \
  -backend-config="bucket=<bucket del state>" \
  -backend-config="key=<product>/dns-zone/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="profile=<aws_profile>"

terraform -chdir=stacks/dns-zone apply \
  -var-file=../../clientes/<product>/naming.tfvars \
  -var="aws_profile=<aws_profile>" \
  -var="domain_name=<dominio>"
```

`naming.tfvars` trae también `backend_service_name` y `db_name`, que este stack no usa. Terraform muestra un aviso de variable no declarada; no afecta el resultado.

El stack `web-app` encuentra la zona por su nombre, con la variable `dns_zone_name`.
