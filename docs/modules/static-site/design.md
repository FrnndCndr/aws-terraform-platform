# static-site: decisiones de diseño

## El bucket es privado y solo CloudFront lo lee

El bucket no usa el alojamiento web de S3 ni tiene acceso público. CloudFront accede con Origin Access Control: firma cada petición, y la política del bucket acepta únicamente las que vienen de esta distribución. Nadie puede saltarse CloudFront y leer el bucket por su URL.

Origin Access Control reemplaza a Origin Access Identity, el mecanismo anterior, que AWS mantiene solo por compatibilidad.

## Las rutas se resuelven con una CloudFront Function

S3 no sabe que `/ruta/` significa `/ruta/index.html`. Una función en el borde reescribe la ruta antes de pedir el archivo: si termina en `/` agrega `index.html`; si no tiene extensión agrega `/index.html`.

Se prefiere a las respuestas de error personalizadas (devolver `index.html` ante un 403 o 404) porque estas se aplican a toda la distribución: un 404 legítimo de la API se convertiría en la página del sitio con código 200.

## El enrutamiento de la API vive en este módulo

Una distribución de CloudFront se define completa en un solo recurso, con todos sus orígenes y comportamientos. Para que el sitio y la API compartan dominio, el origen del backend se declara aquí como variable opcional. Si no se indica, la distribución solo sirve el sitio.

Compartir dominio evita configurar CORS entre el sitio y la API, y deja un único punto de entrada con HTTPS.

## La API no se guarda en caché

El comportamiento de la API usa la política administrada `CachingDisabled` y reenvía al backend todas las cabeceras, cookies y parámetros, salvo la cabecera `Host`. Admite todos los métodos HTTP. El contenido del sitio usa `CachingOptimized`.

## HTTPS hacia el backend por defecto

CloudFront habla con el backend por HTTPS (`https-only`), que es lo que exige API Gateway. `http-only` queda para un origen sin certificado, como un balanceador sin dominio propio. El usuario siempre usa HTTPS contra CloudFront.

## Dominio propio opcional

Sin dominio, la distribución usa su dominio `*.cloudfront.net` y el certificado por defecto de CloudFront. Con dominio, recibe el ARN de un certificado de ACM, que debe estar en `us-east-1` porque CloudFront solo acepta certificados de esa región. El certificado se crea fuera de este módulo.

Si recibe `dns_zone_id`, el módulo crea los registros alias (`A` e `AAAA`) de cada dominio hacia la distribución. El registro vive junto al recurso al que apunta: se crea y se borra con él. Un registro alias apunta a un recurso de AWS en vez de a una IP, sigue funcionando si CloudFront cambia sus direcciones, y sus consultas no se cobran.

## `PriceClass_100` por defecto

CloudFront cobra distinto según las ubicaciones desde las que entrega. `PriceClass_100` usa solo Norteamérica y Europa, las más baratas. Los usuarios de otras regiones reciben el contenido desde esas ubicaciones, con algo más de latencia. Se cambia cuando el tráfico lo justifique.

## `force_destroy` desactivado por defecto

Un bucket con archivos no se puede destruir salvo que `force_destroy` esté activo. En entornos de prueba se activa para poder destruir y recrear el stack; en producción se deja desactivado para no perder el sitio por un `destroy` accidental.

## Limitación conocida

Una ruta que no existe devuelve el error 403 de S3 en lugar de la página 404 del sitio, porque CloudFront no tiene permiso para listar el bucket y S3 responde igual a "no existe" y "no autorizado".
