# dns-zone: requisito

## Propósito

Crear la zona de Route 53 del dominio propio de un cliente. La zona es compartida por todos sus entornos.

## Qué debe cumplir

1. Crea una zona hospedada pública para el dominio.
2. Entrega como salida los cuatro servidores de nombres de la zona, que se cargan en el registrador del dominio.
3. La zona no se puede destruir por accidente con `terraform destroy`.
4. Guarda su state en el bucket de la cuenta, en una ruta propia del cliente.

## Paso manual

Después del primer `apply`, los servidores de nombres se cargan en NIC Chile (o el registrador del dominio). Hasta que la delegación propaga, nada en internet resuelve los registros de la zona.

Si el dominio ya tiene registros en uso (correo, otro sitio), hay que recrearlos en la zona antes de delegar.

## Costo

0,50 USD al mes por la zona, más 0,40 USD por millón de consultas. Las consultas a registros alias hacia recursos de AWS no se cobran.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras delegar, `nslookup -type=NS <dominio>` devuelve los servidores de nombres de la zona.
