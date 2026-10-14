# web-app: requisito

## Propósito

Componer los módulos en un entorno completo de una aplicación web: red, sitio estático, backend en contenedores, base de datos y almacenamiento de archivos.

El stack es lo que se aplica. Los módulos no se aplican por separado.

## Qué debe cumplir

1. Un entorno se describe con un archivo de variables. El mismo código sirve para cualquier cliente y entorno.
2. Guarda su state en el bucket de la cuenta del cliente, en una ruta propia de ese cliente y entorno.
3. Todos los recursos llevan el nombre `<client>-<environment>-...` y los tags `client`, `environment`, `project` y `managed_by`.
4. Se conecta a AWS con el perfil indicado en las variables.
5. Entrega como salida los datos que necesita el despliegue de la aplicación.

## Alcance

| Componente | Módulo | Estado |
|---|---|---|
| Red | `network` | Incluido |
| Sitio estático y CloudFront | `static-site` | Incluido |
| Repositorio de imágenes | `ecr` | Incluido |
| Entrada al backend | `api-gateway` | Incluido |
| Backend en contenedores | `ecs-service` | Incluido |
| Base de datos | `rds-postgres` | Incluido |
| Bucket de archivos | `uploads-bucket` | Incluido |
| Certificado del dominio propio | `acm-certificate` | Incluido, opcional |

## Costo

Con la configuración mínima, unos 29 USD al mes con todo encendido:

| Recurso | USD al mes |
|---|---|
| Base de datos (`db.t4g.micro`, 20 GB) | ~14,0 |
| Backend (1 tarea Fargate de 0,25 vCPU y 0,5 GB) | ~9,0 |
| IP pública de la tarea | ~3,7 |
| Registros, imágenes y secreto | ~1,4 |
| API Gateway y zona privada de Cloud Map | ~0,7 |
| Sitio, archivos, red | ~0 |

Con `backend_desired_count = 0` y la base detenida, baja a unos 4 USD. Un dominio propio agrega 0,50 USD por la zona, que se cobra una vez por cliente.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- `terraform plan` con el archivo de variables de ejemplo no muestra errores.
- Tras aplicar, el dominio del sitio responde por HTTPS, y `/api/...` llega al contenedor del backend.
