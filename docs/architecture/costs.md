# Costos del entorno dev

El entorno `dev` en configuración mínima cuesta unos 29 USD al mes con todos sus recursos encendidos. Las cifras salen de la calculadora de precios de AWS para la región `us-east-1`, con tarifas de lista antes de descuentos (sin niveles gratuitos ni créditos), en USD y sin impuestos, para un mes de 730 horas.

## Resumen

| Servicio | Recurso de Terraform | Especificación | USD al mes |
|---|---|---|---|
| RDS for PostgreSQL | `rds-postgres` | `db.t4g.micro`, Single-AZ, 20 GB gp3 | 13,98 |
| ECS Fargate | `ecs-service` | 1 tarea de 0,25 vCPU y 0,5 GB, x86_64 | 9,01 |
| IPv4 pública | `ecs-service` | 1 dirección, de la tarea de Fargate | 3,65 |
| Route 53 | `ecs-service` (Cloud Map) | 1 zona, 1 millón de consultas | 0,90 |
| CloudWatch Logs | `ecs-service`, `api-gateway` | 1 GB ingerido, 0,3 GB almacenado | 0,51 |
| Secrets Manager | `rds-postgres` | 1 secreto | 0,40 |
| S3 | `static-site`, `uploads-bucket`, `bootstrap` | 6 GB y 121.000 peticiones | 0,24 |
| ECR | `ecr` | 1 GB almacenado | 0,10 |
| API Gateway | `api-gateway` | HTTP API, 100.000 peticiones | 0,10 |
| CloudFront | `static-site` | 1 GB de transferencia | 0,09 |
| VPC | `network` | 2 zonas, subnets, Internet Gateway, sin NAT Gateway | 0 |
| **Total** | | | **28,98** |

## Detalle por servicio

### RDS for PostgreSQL

| Especificación | Valor |
|---|---|
| Motor | PostgreSQL 17 |
| Clase de instancia | `db.t4g.micro` (2 vCPU Graviton, 1 GB de memoria) |
| Despliegue | Single-AZ |
| Almacenamiento | 20 GB gp3, cifrado, sin crecimiento automático |
| Respaldos | Automáticos, 7 días de retención |
| Acceso | Subnets privadas, sin IP pública |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Instancia `db.t4g.micro` | 730 h | 11,68 |
| Almacenamiento gp3 | 20 GB | 2,30 |
| Respaldos | Hasta el tamaño de la base | 0 |

### ECS Fargate

| Especificación | Valor |
|---|---|
| Sistema y arquitectura | Linux, x86_64 |
| Tareas | 1, encendida 730 h |
| CPU y memoria | 0,25 vCPU y 0,5 GB |
| Almacenamiento efímero | 20 GB (incluido) |
| Red | Subnet pública con IP pública; solo acepta tráfico del VPC Link |

| Uso | Cantidad | USD al mes |
|---|---|---|
| vCPU | 182,5 vCPU-hora (0,25 × 730) | 7,39 |
| Memoria | 365 GB-hora (0,5 × 730) | 1,62 |

### IPv4 pública

| Especificación | Valor |
|---|---|
| Direcciones | 1, asignada a la tarea de Fargate |
| Motivo | Sin NAT Gateway, es la salida a internet de la tarea |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Dirección en uso | 730 h | 3,65 |

### Route 53

| Especificación | Valor |
|---|---|
| Zona | Privada, creada por el espacio de nombres DNS de Cloud Map |
| Registros | SRV del servicio del backend, uno por tarea |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Zona hospedada | 1 | 0,50 |
| Consultas DNS | 1 millón | 0,40 |

API Gateway encuentra las tareas con la API de Cloud Map, no por DNS, así que el volumen real de consultas debería quedar muy por debajo del millón cotizado.

### CloudWatch Logs

| Especificación | Valor |
|---|---|
| Grupos | Logs del contenedor y logs de acceso de API Gateway |
| Retención | 7 días |
| Container Insights | Desactivado |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Ingesta | 1 GB | 0,50 |
| Almacenamiento | 0,3 GB | 0,01 |

### Secrets Manager

| Especificación | Valor |
|---|---|
| Secretos | 1, la contraseña de la base, administrada por RDS |
| Rotación | Cada 365 días |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Secreto | 1 | 0,40 |
| Llamadas a la API | Unas pocas por arranque de tarea | ~0 |

### S3

| Bucket | Especificación |
|---|---|
| Sitio estático | Standard, privado, solo lo lee CloudFront |
| Archivos subidos | Standard, privado, sin versionado, URL prefirmadas, CORS para el sitio |
| State de Terraform | Standard, versionado, compartido por los entornos del cliente |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Almacenamiento del sitio y del state | 1 GB | 0,02 |
| Almacenamiento de archivos subidos | 5 GB | 0,12 |
| Peticiones PUT, COPY, POST, LIST | 11.000 | 0,06 |
| Peticiones GET y otras | 110.000 | 0,04 |

### ECR

| Especificación | Valor |
|---|---|
| Repositorios | 1, privado, del backend |
| Imágenes conservadas | Hasta 10 |
| Análisis | Básico al subir, sin costo |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Almacenamiento | 1 GB | 0,10 |

### API Gateway

| Especificación | Valor |
|---|---|
| Tipo | HTTP API, etapa `$default` |
| Integración | VPC Link hacia Cloud Map, sin costo |
| Límite de peticiones | 50 por segundo, ráfagas de 100 |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Peticiones a la HTTP API | 100.000 | 0,10 |

La HTTP API cobra 1 USD por millón de peticiones. Una REST API cobraría 3,50 USD por millón; el módulo crea una HTTP API.

### CloudFront

| Especificación | Valor |
|---|---|
| Distribuciones | 1, sitio y API en el mismo dominio |
| Price class | `PriceClass_100` (Norteamérica y Europa) |
| Función | 1 CloudFront Function en viewer-request |

| Uso | Cantidad | USD al mes |
|---|---|---|
| Transferencia a internet | 1 GB | 0,09 |

CloudFront incluye sin costo 1 TB de transferencia, 10 millones de peticiones y 2 millones de invocaciones de funciones al mes. Con ese nivel gratuito, el costo real con poco tráfico es 0.

### VPC

| Especificación | Valor |
|---|---|
| Rango | `10.20.0.0/16` |
| Zonas de disponibilidad | 2 |
| Subnets | 2 públicas y 2 privadas, `/20` |
| Salida a internet | Internet Gateway; sin NAT Gateway |

La VPC, las subnets, las tablas de rutas, el Internet Gateway y el VPC Link no tienen costo.

## Sin costo o fuera de la estimación

| Elemento | Motivo |
|---|---|
| Cluster ECS, roles de IAM, security groups | No tienen costo |
| VPC Link de API Gateway | No tiene costo |
| Consultas a Cloud Map desde API Gateway | 1 USD por millón; con poco tráfico, centavos |
| Certificado de ACM (con dominio propio) | Gratuito |
| Análisis de imágenes en ECR | El básico es gratuito |

## Cómo bajar el costo

| Acción | USD al mes |
|---|---|
| Todo encendido | ~29 |
| Tarea en 0 y base detenida | ~4 |
| Entorno destruido | ~0 |

AWS vuelve a encender una base detenida a los 7 días.

## Dominio propio

Usar un dominio propio agrega una zona pública de Route 53, de 0,50 USD al mes, compartida por los entornos del cliente, y 0,40 USD por millón de consultas. Las consultas a registros alias hacia CloudFront no se cobran.
