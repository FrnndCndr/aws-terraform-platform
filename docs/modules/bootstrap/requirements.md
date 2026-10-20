# bootstrap: requisito

## Propósito

Crear, en una cuenta AWS, el bucket S3 donde se guarda el state de Terraform de todos los entornos de un cliente.

Se aplica una vez por cuenta, antes que cualquier otro código del repositorio. Los demás stacks dependen de que este bucket exista.

## Por qué existe como paso aparte

Un stack guarda su state en un bucket, pero ese bucket también hay que crearlo. `bootstrap` resuelve ese orden: es el único código del repositorio que usa state local, y crea el bucket que usan los demás.

## Qué debe cumplir

1. Crea un bucket S3 con nombre `tfstate-<client>-<account_id>`.
2. El bucket tiene versionado activo.
3. El contenido se cifra en reposo.
4. Todo acceso público está bloqueado.
5. Solo se aceptan conexiones cifradas (HTTPS).
6. El bucket no se puede destruir por accidente con `terraform destroy`.
7. Las versiones antiguas del state se eliminan pasado un plazo configurable.
8. Entrega como salida el nombre del bucket, su ARN y su región.
9. De forma opcional, crea el proveedor OIDC de GitHub de la cuenta, que usan los roles de despliegue de todos los entornos.

## Qué no hace

- No crea tabla DynamoDB: el bloqueo usa el mecanismo nativo de S3.
- No crea usuarios, roles ni permisos. Los roles de despliegue los crea cada entorno con `github-oidc`.
- No crea recursos de red, base de datos ni cómputo.

## Costo

Centavos de dólar al mes. Un bucket con archivos de state de pocos kilobytes y sus versiones no alcanza un costo apreciable.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, el bucket existe, tiene versionado activo y su acceso público está bloqueado.
- Un stack inicializa su backend contra el bucket sin errores.
