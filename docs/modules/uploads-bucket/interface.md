# uploads-bucket: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `name_prefix` | `string` | Sí | — | Prefijo de los nombres, con la forma `<client>-<environment>`. |
| `cors_allowed_origins` | `list(string)` | No | `[]` | Orígenes del navegador autorizados, por ejemplo `https://dev.ejemplo.cl`. Vacío no crea regla CORS. |
| `versioning_enabled` | `bool` | No | `false` | Conserva las versiones anteriores de cada archivo. |
| `noncurrent_version_expiration_days` | `number` | No | `90` | Con versionado, días que se conserva una versión anterior. |
| `force_destroy` | `bool` | No | `false` | Permite destruir el bucket aunque tenga archivos. |

## Salidas

| Nombre | Descripción |
|---|---|
| `bucket_name` | Nombre del bucket. |
| `bucket_arn` | ARN del bucket. |
| `read_write_policy_json` | Política de IAM que permite listar el bucket y leer, escribir y borrar sus objetos. |

## Nombre del bucket

`<name_prefix>-uploads-<account_id>`. El id de cuenta se obtiene de la sesión activa.
