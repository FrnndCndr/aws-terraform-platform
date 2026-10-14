# api-gateway: requisito

## Propósito

Dar al backend un punto de entrada estable por HTTPS, que reenvía cada petición a una tarea de ECS en la VPC.

## Qué debe cumplir

1. Crea una API HTTP de API Gateway que envía todas las peticiones al backend, sin cambiar la ruta.
2. Llega a las tareas a través de un VPC Link, buscándolas en Cloud Map.
3. Limita la cantidad de peticiones por segundo.
4. Registra cada petición en CloudWatch Logs, con retención configurable.
5. Entrega como salida el dominio del endpoint, que es el origen de CloudFront para la API.

## Qué no hace

- No autentica usuarios: eso es responsabilidad del backend.
- No crea dominio propio: el acceso público es a través de CloudFront.

## Límites

| Límite | Valor |
|---|---|
| Duración máxima de una petición | 30 segundos |
| Tamaño máximo de una petición | 10 MB |
| WebSockets | No soportados |

## Costo

| Recurso | Costo aproximado |
|---|---|
| API HTTP | 1 USD por millón de peticiones |
| VPC Link | Sin costo |
| Registros de acceso | 0,50 USD por GB ingerido |

Con poco tráfico, centavos al mes.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, una petición al endpoint llega al contenedor y queda en el registro de acceso.
