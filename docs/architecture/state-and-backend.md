# State y backend

## Qué es el state

Terraform guarda en un archivo, el state, la lista de recursos que creó y sus identificadores en AWS. Con él compara lo que el código describe contra lo que existe y decide qué crear, cambiar o borrar. Sin el state, Terraform no reconoce los recursos existentes e intenta crearlos de nuevo.

## Dónde se guarda

El state se guarda en un bucket S3 dentro de la cuenta AWS del cliente, no en el computador de quien ejecuta Terraform.

- Un state local se pierde con el equipo y no se comparte con otras personas ni con un pipeline.
- El bucket tiene versionado: una versión dañada del state se recupera desde la anterior.
- El bucket vive en la cuenta del cliente: al entregar la cuenta se entrega también el state, y nadie fuera de esa cuenta lo lee.

El bucket lo crea el módulo [bootstrap](../modules/bootstrap/requirements.md), una vez por cuenta.

## Un state por cliente y entorno

Cada combinación de cliente y entorno tiene su propio state, en una ruta (`key`) distinta del bucket:

```
<product>/<environment>/terraform.tfstate
```

| Producto | Entorno | Cuenta AWS | Bucket | Key |
|---|---|---|---|---|
| ejemplo | dev | cuenta de ejemplo | `tfstate-ejemplo-<account_id>` | `ejemplo/dev/terraform.tfstate` |
| ejemplo | prod | cuenta de ejemplo | `tfstate-ejemplo-<account_id>` | `ejemplo/prod/terraform.tfstate` |
| ejemplo | zona DNS (compartida) | cuenta de ejemplo | `tfstate-ejemplo-<account_id>` | `ejemplo/dns-zone/terraform.tfstate` |

Los entornos de un mismo producto comparten cuenta y bucket, y se separan por la `key`. Varios productos de una misma empresa pueden compartir cuenta y bucket: el producto en la `key` los separa. Clientes distintos tienen cuentas y buckets distintos. Así, un cambio en un cliente no puede leer ni modificar el state de otro: las credenciales de una cuenta no alcanzan el bucket de la otra.

## Cómo se conecta un stack al state

El backend se declara sin valores fijos y se completa al inicializar:

```
terraform -chdir=stacks/web-app init \
  -backend-config="bucket=<bucket>" \
  -backend-config="key=<product>/<environment>/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="profile=<aws_profile>"
```

El bucket, la key y el perfil cambian entre clientes, por eso no se escriben en el código. El mismo stack sirve para cualquier cliente.

## Bloqueo de ejecuciones simultáneas

El backend usa el bloqueo nativo de S3 (`use_lockfile = true`). Mientras un `apply` corre, Terraform escribe un archivo de bloqueo junto al state; un segundo `apply` sobre el mismo state falla en lugar de correr en paralelo y corromperlo.

Este bloqueo no necesita una tabla DynamoDB, que era el mecanismo anterior. Requiere Terraform 1.10 o superior.

## Credenciales

Terraform se conecta a AWS con un perfil de la AWS CLI. El nombre del perfil es una variable (`aws_profile`), con un valor por cliente y entorno. El código no distingue el tipo de credencial detrás del perfil: funciona igual con llaves de un usuario IAM o con credenciales temporales de IAM Identity Center.

## El state contiene datos sensibles

El state puede incluir valores que AWS devuelve al crear recursos. Por eso:

- El bucket no es público y está cifrado.
- Ningún archivo de state se versiona en git.
- Las contraseñas de base de datos las genera y guarda AWS en Secrets Manager, de modo que no pasan por variables de Terraform.
