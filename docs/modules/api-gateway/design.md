# api-gateway: decisiones de diseño

## API Gateway en lugar de un balanceador

Las tareas de Fargate cambian de IP en cada despliegue, así que CloudFront necesita una dirección estable para enrutar la API. Un balanceador de aplicación la da, pero cobra unos 24 USD al mes por existir (el balanceador y sus dos IP públicas). Una API HTTP cobra por petición: con poco tráfico, el costo es casi cero.

El cambio a un balanceador conviene cuando el tráfico supera decenas de millones de peticiones al mes, o cuando el backend necesita algo que API Gateway no admite: peticiones de más de 30 segundos, de más de 10 MB, o WebSockets.

## VPC Link y Cloud Map

API Gateway vive fuera de la VPC. El VPC Link crea interfaces de red dentro de ella, por donde pasa el tráfico hacia las tareas. Para saber a qué IP y puerto enviarlo, API Gateway consulta Cloud Map, donde ECS registra cada tarea.

Las interfaces del VPC Link van en las subnets privadas: no necesitan salida a internet, y desde ahí alcanzan a las tareas por la red interna de la VPC. Su security group solo permite enviar tráfico dentro del rango de la VPC.

## Una sola ruta que lo reenvía todo

La ruta `$default` envía cualquier método y ruta al backend, con la ruta original. El backend recibe `/api/...` tal como la pidió el navegador. Las rutas de la API se definen en el backend, no en Terraform.

## Etapa `$default` con despliegue automático

La API tiene una sola etapa, `$default`, sin prefijo en la URL. Cada cambio de configuración se publica solo.

## Límite de peticiones

El endpoint de API Gateway es público. Un límite de 50 peticiones por segundo (ráfagas de 100) acota el costo si alguien lo llama de forma abusiva. Se sube con las variables cuando el tráfico real lo pida.

## Registro de acceso

Cada petición queda en CloudWatch Logs en formato JSON: método, ruta, estado, latencia y, si falla, el error de la integración. Es la primera fuente para diagnosticar un error entre CloudFront y el backend.

## Riesgo aceptado: el endpoint es alcanzable sin CloudFront

El dominio `execute-api` responde a cualquiera que lo conozca, sin pasar por CloudFront. Se acepta en el entorno mínimo. Se cierra haciendo que CloudFront agregue una cabecera secreta y que el backend rechace las peticiones que no la traen.

## El backend no recibe el dominio del sitio

CloudFront envía a API Gateway la cabecera `Host` del endpoint `execute-api`, no la del sitio. Si el backend arma URL absolutas, debe tomar el dominio del sitio de su configuración, no de la petición.
