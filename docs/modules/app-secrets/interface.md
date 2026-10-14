# app-secrets: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `product` | `string` | Sí | — | Producto SaaS. Forma parte de cada nombre. |
| `environment` | `string` | Sí | — | Entorno: `dev` o `prod`. Forma parte de cada nombre. |
| `secret_names` | `list(string)` | No | `[]` | Nombres de las variables de entorno que se leen de un secreto, por ejemplo `JWT_KEY`. Solo mayúsculas, números y guion bajo. |
| `recovery_window_days` | `number` | No | `7` | Días que AWS conserva un secreto borrado antes de eliminarlo. `0` lo elimina al momento. |

## Salidas

| Nombre | Descripción |
|---|---|
| `secret_arns` | Mapa de nombre de variable a ARN del secreto. |

## Nombres

`JWT_KEY` con `product = "ejemplo"` y `environment = "dev"` crea el secreto `secret-ejemplo-jwt-key-dev`.
