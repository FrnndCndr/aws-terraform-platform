# ecs-service: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `product` | `string` | Sí | — | Producto SaaS. Forma parte de cada nombre. Ver `docs/architecture/naming.md`. |
| `environment` | `string` | Sí | — | Entorno: `dev` o `prod`. Forma parte de cada nombre. |
| `service_name` | `string` | No | `backend` | Nombre del servicio y de su contenedor. |
| `vpc_id` | `string` | Sí | — | VPC donde corren las tareas. |
| `subnet_ids` | `list(string)` | Sí | — | Subnets donde corren las tareas. |
| `assign_public_ip` | `bool` | No | `false` | Da IP pública a cada tarea. Necesario en subnets públicas sin NAT Gateway. |
| `image` | `string` | Sí | — | Imagen del contenedor, con su etiqueta. |
| `container_port` | `number` | No | `8080` | Puerto en el que escucha el contenedor. |
| `cpu` | `number` | No | `256` | CPU de la tarea, en unidades (1024 = 1 vCPU). |
| `memory` | `number` | No | `512` | Memoria de la tarea, en MB. |
| `cpu_architecture` | `string` | No | `X86_64` | `X86_64` o `ARM64`. Debe coincidir con la arquitectura de la imagen. |
| `desired_count` | `number` | No | `1` | Cantidad de tareas. `0` detiene el servicio sin destruirlo. |
| `container_environment` | `map(string)` | No | `{}` | Variables de entorno del contenedor. |
| `secrets` | `map(object)` | No | `{}` | Variables de entorno que salen de Secrets Manager. Clave: nombre de la variable. Valor: `{ secret_arn, json_key }`; `json_key` es opcional y elige un campo de un secreto JSON. |
| `task_role_policies` | `map(string)` | No | `{}` | Políticas de IAM (JSON) que se agregan al rol del contenedor. Clave: nombre de la política. |
| `ingress_security_group_ids` | `map(string)` | No | `{}` | Security groups que pueden llegar al puerto del contenedor. Clave: etiqueta descriptiva. |
| `health_check` | `object` | No | `null` | Health check del contenedor: `command` (lista), y opcionales `interval_seconds` (30), `timeout_seconds` (5), `retries` (3), `start_period_seconds` (30). |
| `enable_execute_command` | `bool` | No | `false` | Permite abrir una terminal en el contenedor con ECS Exec. |
| `log_retention_days` | `number` | No | `7` | Días que se conservan los registros. |

## Salidas

| Nombre | Descripción |
|---|---|
| `cluster_name` | Nombre del cluster. |
| `service_name` | Nombre del servicio ECS. |
| `security_group_id` | Security group de las tareas. Otros módulos lo usan para aceptar su tráfico. |
| `task_role_name` | Nombre del rol del contenedor. |
| `task_role_arn` | ARN del rol del contenedor. |
| `execution_role_arn` | ARN del rol que usa ECS para bajar la imagen y leer secretos. |
| `service_discovery_service_arn` | ARN del servicio en Cloud Map. Destino de la integración de API Gateway. |
| `log_group_name` | Grupo de CloudWatch Logs del contenedor. |
