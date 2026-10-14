# acm-certificate: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `domain_name` | `string` | Sí | — | Dominio principal del certificado, por ejemplo `dev.ejemplo.cl`. |
| `subject_alternative_names` | `list(string)` | No | `[]` | Otros dominios que cubre el mismo certificado. |
| `zone_id` | `string` | Sí | — | Zona de Route 53 donde se crean los registros de validación. |

## Salidas

| Nombre | Descripción |
|---|---|
| `certificate_arn` | ARN del certificado, disponible solo cuando ACM lo emitió. |
