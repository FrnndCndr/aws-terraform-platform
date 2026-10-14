# acm-certificate: requisito

## Propósito

Emitir un certificado HTTPS de ACM para un dominio propio y validarlo de forma automática por DNS.

## Qué debe cumplir

1. Solicita un certificado de ACM para el dominio y sus nombres alternativos.
2. Crea en la zona de Route 53 los registros que demuestran la propiedad del dominio.
3. Espera a que ACM emita el certificado antes de entregarlo.
4. Entrega como salida el ARN del certificado validado.

## Requisito previo

La zona de Route 53 del dominio debe existir y estar delegada desde el registrador (NIC Chile). Sin delegación, ACM no ve los registros de validación y el `apply` espera hasta agotar el tiempo.

## Costo

Sin costo: los certificados públicos de ACM son gratuitos y se renuevan solos.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, el certificado aparece como emitido en la consola de ACM.
