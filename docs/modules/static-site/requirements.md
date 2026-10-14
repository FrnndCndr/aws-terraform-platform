# static-site: requisito

## Propósito

Publicar un sitio web estático: un bucket S3 privado con los archivos y una distribución de CloudFront que los sirve por HTTPS. La misma distribución puede enrutar las peticiones de la API hacia el backend, para que el sitio y la API compartan dominio.

## Qué debe cumplir

1. Crea un bucket S3 privado, cifrado y con el acceso público bloqueado.
2. Crea una distribución de CloudFront que sirve el contenido del bucket por HTTPS y redirige HTTP a HTTPS.
3. Solo esa distribución puede leer el bucket.
4. Las rutas del sitio se resuelven a su `index.html`: `/ruta/` y `/ruta` sirven `/ruta/index.html`.
5. De forma opcional, envía las peticiones que coinciden con un patrón de ruta (por ejemplo `/api/*`) a un origen de backend, sin caché.
6. De forma opcional, usa un dominio propio con un certificado de ACM, y crea sus registros alias en Route 53. Sin él, usa el dominio de CloudFront.
7. Entrega como salida el nombre del bucket y los datos de la distribución.

## Qué no hace

- No sube los archivos del sitio: eso lo hace el pipeline de despliegue.
- No crea certificados ni zonas DNS.
- No crea el backend ni su balanceador.

## Supuesto sobre el sitio

El sitio se genera como export estático con una carpeta por ruta (`/ruta/index.html`). En Next.js corresponde a `output: 'export'` con `trailingSlash: true`.

## Costo

| Recurso | Costo mensual aproximado |
|---|---|
| Bucket S3 | 0,023 USD por GB almacenado |
| CloudFront | Sin costo hasta 1 TB de transferencia y 10 millones de peticiones al mes; después, desde 0,085 USD por GB |
| CloudFront Function | Sin costo hasta 2 millones de invocaciones al mes |

Con poco tráfico, el costo es cercano a cero.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar y subir un `index.html`, el dominio de la distribución lo muestra por HTTPS.
- El bucket no es accesible por su URL directa.
