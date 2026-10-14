# app-secrets: requisito

## Propósito

Crear en Secrets Manager los secretos que necesita la aplicación (llaves de firma, credenciales de terceros), vacíos, para que su valor se cargue a mano y nunca pase por Terraform.

## Qué debe cumplir

1. Crea un secreto por cada nombre de la lista, sin valor.
2. Nombra cada secreto con el patrón del proyecto: `secret-<product>-<nombre>-<environment>`, con el nombre en minúsculas y guiones.
3. Entrega como salida un mapa de nombre de variable a ARN del secreto, que el stack usa para inyectarlos en el contenedor.
4. El plazo de recuperación al borrar un secreto es configurable.

## Qué no hace

- No escribe el valor de ningún secreto: Terraform nunca lo conoce y no queda en el state.
- No crea la contraseña de la base de datos: esa la administra RDS.

## Paso manual

Después de aplicar, se carga el valor de cada secreto en la consola de Secrets Manager (o con `aws secretsmanager put-secret-value`). Mientras un secreto no tenga valor, ECS no puede arrancar las tareas que lo usan.

## Costo

0,40 USD al mes por secreto, más 0,05 USD por cada 10.000 llamadas. Con dos o tres secretos, entre 0,80 y 1,20 USD al mes.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, los secretos existen vacíos en Secrets Manager.
