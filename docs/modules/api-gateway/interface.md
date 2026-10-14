# api-gateway: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `product` | `string` | Sí | — | Producto SaaS. Forma parte de cada nombre. Ver `docs/architecture/naming.md`. |
| `environment` | `string` | Sí | — | Entorno: `dev` o `prod`. Forma parte de cada nombre. |
| `vpc_id` | `string` | Sí | — | VPC donde corre el backend. |
| `vpc_cidr` | `string` | Sí | — | Rango de la VPC. El VPC Link solo puede enviar tráfico dentro de él. |
| `subnet_ids` | `list(string)` | Sí | — | Subnets donde se crean las interfaces del VPC Link. |
| `service_discovery_service_arn` | `string` | Sí | — | ARN del servicio de Cloud Map donde se registran las tareas. |
| `throttling_rate_limit` | `number` | No | `50` | Peticiones por segundo sostenidas. |
| `throttling_burst_limit` | `number` | No | `100` | Peticiones simultáneas admitidas en una ráfaga. |
| `log_retention_days` | `number` | No | `7` | Días que se conservan los registros de acceso. |

## Salidas

| Nombre | Descripción |
|---|---|
| `api_id` | Identificador de la API. |
| `api_endpoint` | URL del endpoint, con `https://`. |
| `endpoint_domain_name` | Dominio del endpoint, sin protocolo. Origen de CloudFront. |
| `vpc_link_security_group_id` | Security group del VPC Link. El backend lo autoriza para recibir tráfico. |
