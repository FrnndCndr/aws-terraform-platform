# ecs-service: requisito

## Propósito

Ejecutar el backend como un servicio de contenedores en ECS Fargate, registrado en Cloud Map para que la entrada al backend lo encuentre.

## Qué debe cumplir

1. Crea un cluster ECS y un servicio Fargate con la imagen, CPU, memoria y cantidad de tareas indicadas.
2. Envía los registros del contenedor a CloudWatch Logs, con retención configurable.
3. Inyecta variables de entorno y secretos de Secrets Manager en el contenedor.
4. Da al contenedor un rol de IAM al que se pueden agregar políticas desde fuera del módulo.
5. Registra cada tarea en Cloud Map (dirección IP y puerto), para que API Gateway la encuentre.
6. Solo acepta tráfico en el puerto del contenedor desde los security groups indicados.
7. Revierte un despliegue que no logra arrancar tareas sanas.
8. De forma opcional, permite abrir una terminal dentro del contenedor (ECS Exec) y definir un health check del contenedor.

## Qué no hace

- No crea la imagen ni el repositorio.
- No crea balanceador ni autoescalado.

## Costo

| Recurso | Costo mensual aproximado |
|---|---|
| Tarea Fargate de 0,25 vCPU y 0,5 GB (x86) | ~9 USD por tarea encendida todo el mes |
| IP pública de la tarea (si se asigna) | ~3,65 USD por tarea |
| Zona privada de Cloud Map | ~0,50 USD |
| CloudWatch Logs | 0,50 USD por GB ingerido; con poco tráfico, centavos |
| Cluster, roles, security group | Sin costo |

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, el servicio queda con las tareas pedidas en estado `RUNNING` y sus registros aparecen en CloudWatch.
