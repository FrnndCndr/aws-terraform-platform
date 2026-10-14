# ecr: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `product` | `string` | Sí | — | Producto SaaS. Forma parte de cada nombre. Ver `docs/architecture/naming.md`. |
| `environment` | `string` | Sí | — | Entorno: `dev` o `prod`. Forma parte de cada nombre. |
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
