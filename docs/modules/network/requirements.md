# network: requisito

## Propósito

Crear la red de un entorno: una VPC con subnets públicas y privadas repartidas en varias zonas de disponibilidad, y las rutas que definen qué subnets tienen salida a internet.

## Qué debe cumplir

1. Crea una VPC con el rango de direcciones indicado y resolución DNS activa.
2. Crea una subnet pública y una privada por cada zona de disponibilidad pedida.
3. Las subnets públicas tienen ruta a internet a través de un Internet Gateway.
4. Las subnets privadas no tienen ruta a internet, salvo que se active el NAT Gateway.
5. El NAT Gateway es opcional. Si se activa, puede ser uno solo para todas las zonas o uno por zona.
6. Ninguna subnet asigna IP pública de forma automática: cada recurso la pide de forma explícita.
7. Entrega como salida los identificadores de la VPC y de las subnets.

## Qué no hace

- No crea security groups: cada módulo crea los suyos.
- No crea VPC endpoints.
- No crea balanceadores, bases de datos ni cómputo.

## Costo

| Recurso | Costo mensual aproximado |
|---|---|
| VPC, subnets, tablas de ruta, Internet Gateway | Sin costo |
| NAT Gateway (solo si se activa) | ~33 USD por gateway, más ~0,045 USD por GB procesado y ~3,65 USD por su IP pública |

Con el NAT Gateway desactivado, el módulo no tiene costo.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- El plan muestra una VPC, un Internet Gateway, dos subnets por zona y ningún NAT Gateway con la configuración mínima.
