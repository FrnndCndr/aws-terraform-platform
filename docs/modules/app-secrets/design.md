# app-secrets: decisiones de diseño

## Los secretos se crean vacíos

Terraform crea el contenedor del secreto, no su valor. El valor se carga a mano en la consola. Así ningún secreto pasa por los archivos de variables, por la línea de comandos ni por el state de Terraform, y el repositorio puede ser público.

## El contenedor recibe el secreto como variable de entorno

ECS lee cada secreto al arrancar la tarea y lo entrega con el nombre de la lista (`JWT_KEY`). La aplicación no necesita el SDK de AWS para leerlo. Igual que con la contraseña de la base, si el valor cambia, las tareas que ya corren lo reciben al reiniciarse.

## Un secreto vacío detiene el arranque

ECS no arranca una tarea si uno de sus secretos no tiene valor. El orden en un entorno nuevo es: aplicar, cargar los valores, y recién entonces desplegar la imagen que los usa. Mientras tanto, una imagen que no los necesita (por ejemplo `nginx`) puede seguir corriendo, porque la definición de tarea solo cambia cuando se aplica de nuevo.

## Nombres en minúsculas con guiones

El nombre de la variable (`JWT_KEY`) se convierte a `jwt-key` para seguir el patrón `secret-<product>-<nombre>-<environment>`. La variable de entorno conserva su nombre original.

## Plazo de recuperación configurable

AWS no borra un secreto al momento: lo conserva unos días por si se borró por error, y durante ese plazo el nombre queda ocupado. Un entorno de prueba que se destruye y recrea seguido necesita `0`, o el siguiente `apply` falla porque el nombre todavía existe. En producción conviene un plazo largo.

| Perfil | Plazo |
|---|---|
| `minimal` | 0 días |
| `production` | 30 días |

## Llave de cifrado administrada por AWS

Los secretos se cifran con la llave `aws/secretsmanager`. El rol de ejecución de ECS puede leerlos sin permisos extra de KMS.
