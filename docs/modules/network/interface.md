# network: interfaz

## Variables

| Nombre | Tipo | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|---|
| `name_prefix` | `string` | Sí | — | Prefijo de los nombres de los recursos, con la forma `<client>-<environment>`. |
| `vpc_cidr` | `string` | Sí | — | Rango de direcciones de la VPC, en notación CIDR con máscara `/16`. |
| `az_count` | `number` | No | `2` | Cantidad de zonas de disponibilidad. Entre 2 y 3. |
| `excluded_zone_ids` | `list(string)` | No | `[]` | Zonas de disponibilidad (por id, por ejemplo `use1-az3`) que no se usan. |
| `enable_nat_gateway` | `bool` | No | `false` | Crea NAT Gateway y da salida a internet a las subnets privadas. |
| `single_nat_gateway` | `bool` | No | `true` | Con NAT activo: `true` crea uno solo para todas las zonas; `false` crea uno por zona. |

## Salidas

| Nombre | Descripción |
|---|---|
| `vpc_id` | Identificador de la VPC. |
| `vpc_cidr` | Rango de direcciones de la VPC. |
| `public_subnet_ids` | Identificadores de las subnets públicas, una por zona. |
| `private_subnet_ids` | Identificadores de las subnets privadas, una por zona. |
| `availability_zones` | Zonas de disponibilidad usadas. |

## Rangos de las subnets

Las subnets se calculan a partir de `vpc_cidr`, cada una con máscara `/20` (4.096 direcciones). Para `10.20.0.0/16`:

| Subnet | Zona 1 | Zona 2 | Zona 3 |
|---|---|---|---|
| Pública | `10.20.0.0/20` | `10.20.16.0/20` | `10.20.32.0/20` |
| Privada | `10.20.128.0/20` | `10.20.144.0/20` | `10.20.160.0/20` |

## Uso

```hcl
module "network" {
  source = "../../modules/network"

  name_prefix = "ejemplo-dev"
  vpc_cidr    = "10.20.0.0/16"
}
```
