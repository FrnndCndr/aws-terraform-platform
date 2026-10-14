# acm-certificate: decisiones de diseño

## Validación por DNS

ACM emite el certificado cuando comprueba que quien lo pide controla el dominio. Con validación por DNS, la prueba es un registro en la zona del dominio. Terraform lo crea, y ACM renueva el certificado solo mientras el registro exista. La alternativa, por correo, exige que alguien apruebe un mensaje en cada renovación.

## La salida espera la emisión

El ARN que entrega el módulo sale del recurso de validación, no de la solicitud. Así, quien use el certificado (CloudFront) no lo recibe hasta que está emitido, y no falla por usar un certificado pendiente.

## La región importa

CloudFront solo acepta certificados de `us-east-1`. El módulo crea el certificado en la región del provider; con la región del proyecto (`us-east-1`) sirve para CloudFront sin configuración adicional.

## Reemplazo sin corte

Cambiar los dominios de un certificado obliga a crear uno nuevo. El nuevo se crea antes de borrar el anterior, para que CloudFront nunca quede sin certificado.
