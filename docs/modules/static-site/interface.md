# static-site: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `product` | `string` | Sí | — | Producto SaaS. Forma parte de cada nombre. Ver `docs/architecture/naming.md`. |
| `environment` | `string` | Sí | — | Entorno: `dev` o `prod`. Forma parte de cada nombre. |
| `force_destroy` | `bool` | No | `false` | Permite destruir el bucket aunque tenga archivos. |
| `price_class` | `string` | No | `PriceClass_100` | Conjunto de ubicaciones de CloudFront. `PriceClass_100` usa Norteamérica y Europa. |
| `domain_names` | `list(string)` | No | `[]` | Dominios propios de la distribución. Vacío usa el dominio de CloudFront. |
| `certificate_arn` | `string` | No | `null` | ARN del certificado de ACM en `us-east-1`. Obligatorio si `domain_names` no está vacío. |
| `dns_zone_id` | `string` | No | `null` | Zona de Route 53 donde se crean los registros alias de `domain_names`. `null` no crea registros. |
| `api_origin_domain_name` | `string` | No | `null` | Nombre DNS del backend. Si se indica, se crea el enrutamiento de la API. |
| `api_path_pattern` | `string` | No | `/api/*` | Patrón de ruta que se envía al backend. |
| `api_origin_protocol_policy` | `string` | No | `https-only` | Protocolo hacia el backend: `https-only` o `http-only`. |

## Salidas

| Nombre | Descripción |
|---|---|
| `bucket_name` | Nombre del bucket del sitio. Destino de la subida de archivos. |
| `bucket_arn` | ARN del bucket. |
| `distribution_id` | Identificador de la distribución. Se usa para invalidar la caché tras un despliegue. |
| `distribution_arn` | ARN de la distribución. |
| `distribution_domain_name` | Dominio de CloudFront de la distribución. |
| `distribution_hosted_zone_id` | Zona de Route 53 de CloudFront, destino de los registros alias. |

## Nombre del bucket

`s3-<product>-static-site-<environment>-<account_id>`. El id de cuenta se obtiene de la sesión activa.

## Uso

Sitio solo, con el dominio de CloudFront:

```hcl
module "static_site" {
  source = "../../modules/static-site"

  product       = "ejemplo"
  environment   = "dev"
  force_destroy = true
}
```

Sitio y API en el mismo dominio:

```hcl
module "static_site" {
  source = "../../modules/static-site"

  product                = "ejemplo"
  environment            = "dev"
  api_origin_domain_name = module.api_gateway.endpoint_domain_name
}
```
