# dns-zone: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `client` | `string` | Sí | — | Identificador del cliente. |
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
  -backend-config="key=<client>/dns-zone/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="profile=<aws_profile>"

terraform -chdir=stacks/dns-zone apply \
  -var="client=<client>" \
  -var="aws_profile=<aws_profile>" \
  -var="domain_name=<dominio>"
```

El stack `web-app` encuentra la zona por su nombre, con la variable `dns_zone_name`.
