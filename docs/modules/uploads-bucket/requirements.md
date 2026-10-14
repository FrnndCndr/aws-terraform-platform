# uploads-bucket: requisito

## Propósito

Crear el bucket privado donde se guardan los archivos que suben los usuarios, y publicar la política que da acceso a él.

## Qué debe cumplir

1. Crea un bucket S3 privado, cifrado, con el acceso público bloqueado y que solo acepta conexiones HTTPS.
2. Acepta peticiones del navegador desde los orígenes indicados (CORS), para subidas y descargas con URL prefirmadas.
3. El versionado es opcional.
4. Elimina las subidas por partes que quedaron incompletas.
5. Entrega como salida una política de IAM que permite leer, escribir y borrar objetos del bucket.

## Qué no hace

- No genera URL prefirmadas: las genera el backend.
- No sirve archivos públicos.

## Costo

0,023 USD por GB almacenado al mes, más centavos por cada mil peticiones. Con pocos archivos, cercano a cero.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, el backend sube y descarga un archivo con URL prefirmadas desde el navegador.
- El bucket no es accesible por su URL directa.
