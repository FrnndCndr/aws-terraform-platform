# ecr: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `name_prefix` | `string` | Sí | — | Prefijo de los nombres, con la forma `<client>-<environment>`. |
| `service_name` | `string` | No | `backend` | Nombre del servicio dueño de las imágenes. |
| `image_tag_mutability` | `string` | No | `MUTABLE` | `MUTABLE` permite reutilizar una etiqueta (por ejemplo `latest`); `IMMUTABLE` lo impide. |
| `max_image_count` | `number` | No | `10` | Cantidad de imágenes que se conservan. |
| `force_delete` | `bool` | No | `false` | Permite destruir el repositorio aunque tenga imágenes. |

## Salidas

| Nombre | Descripción |
|---|---|
| `repository_name` | Nombre del repositorio. |
| `repository_url` | URL del repositorio, destino de `docker push`. |
| `repository_arn` | ARN del repositorio. |
