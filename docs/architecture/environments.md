# Entornos y perfiles

Un despliegue combina tres archivos de variables: un **perfil** que define el tamaño, el **naming** del producto y el archivo del **entorno**. El código es el mismo para todos.

## Los tres archivos

| Archivo | Qué define | Dónde vive | En git |
|---|---|---|---|
| `profiles/<perfil>.tfvars` | Tamaño y protecciones: tareas, base de datos, NAT, retenciones | En el repositorio | Sí |
| `clientes/<product>/naming.tfvars` | Producto, cliente y nombres de servicios | Una carpeta por producto | Solo `ejemplo/` |
| `clientes/<product>/<environment>.tfvars` | Entorno, perfil de AWS, red, imagen, dominio | Una carpeta por producto | Solo `ejemplo/` |

Terraform los lee en orden y el último prevalece. Así, un archivo de entorno puede cambiar un valor puntual del perfil sin crear un perfil nuevo.

Cada producto tiene además `clientes/<product>/backend.hcl`, con el bucket y la región del state. No es un archivo de variables: lo lee `terraform init`. La `key` y el perfil de AWS no van ahí, porque cambian con el entorno.

```hcl
bucket = "tfstate-ejemplo-123456789012"
region = "us-east-1"
```

## Perfiles

| Variable | `minimal` | `production` |
|---|---|---|
| NAT Gateway | No | Sí, uno |
| Tareas del backend | 1 | 2 |
| Base de datos | `db.t4g.micro`, una zona | `db.t4g.micro`, Multi-AZ |
| Crecimiento del almacenamiento | No | Hasta 100 GB |
| Respaldos | 7 días | 14 días |
| Protección contra borrado de la base | No | Sí |
| Respaldo final al borrar | No | Sí |
| Cambios de la base | Al momento | En la ventana de mantenimiento |
| Versionado del bucket de archivos | No | Sí |
| Borrar buckets y repositorio con contenido | Sí | No |
| Etiquetas de imagen | Reutilizables | Inmutables |
| ECS Exec | Activo | Inactivo |
| Retención de logs | 7 días | 30 días |
| Costo aproximado | ~29 USD al mes | ~85 USD al mes |

`minimal` sirve para probar: se destruye y se recrea sin trabas. `production` protege los datos y tolera la falla de una zona.

## Un entorno, dos momentos

`dev` nace con el perfil `minimal` mientras el producto está en sus primeras pruebas. Cuando se lanza `prod`, `dev` pasa al perfil `production` para que las pruebas ocurran en las mismas condiciones que producción.

Pasar de un perfil a otro es aplicar el mismo entorno con el otro perfil. El state y los nombres no cambian: Terraform modifica lo existente (agrega el NAT Gateway, pasa la base a Multi-AZ, suma una tarea) sin crear un entorno nuevo.

| Momento | Perfil | Entorno |
|---|---|---|
| Pruebas iniciales del MVP | `minimal` | `dev` |
| `dev` escalado, igual a producción | `production` | `dev` |
| Producción | `production` | `prod` |

## Script

`scripts/tf.ps1` arma los comandos a partir del producto, el entorno y el perfil:

```
.\scripts\tf.ps1 -Product ejemplo -Environment dev -Profile minimal -Command plan
```

| Parámetro | Obligatorio | Valores |
|---|---|---|
| `-Product` | Sí | Nombre de la carpeta en `clientes/` |
| `-Environment` | Sí | `dev` o `prod` |
| `-Profile` | Para `plan`, `apply` y `destroy` | Nombre de un archivo de `profiles/`, sin extensión |
| `-Command` | Sí | `init`, `plan`, `apply`, `destroy` u `output` |
| `-DryRun` | No | Muestra los comandos de Terraform sin ejecutarlos |

Qué hace:

1. Comprueba que existan los archivos del producto, del entorno y del perfil, y se detiene con un mensaje si falta alguno.
2. Lee `aws_profile` del archivo del entorno.
3. Ejecuta `terraform init -reconfigure` sobre `stacks/web-app`, con `backend.hcl`, la key `<product>/<environment>/terraform.tfstate` y el perfil de AWS. Siempre reinicializa, para que nunca opere sobre el state de otro producto o entorno.
4. Ejecuta el comando pedido con los tres archivos de variables. `output` no los necesita.

`apply` y `destroy` siguen pidiendo confirmación (`yes`): el script no la omite.

## Comandos sin el script

Inicializar el backend, una vez por producto y entorno:

```
terraform -chdir=stacks/web-app init \
  -backend-config="bucket=<bucket del state>" \
  -backend-config="key=<product>/<environment>/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="profile=<aws_profile>"
```

Planificar y aplicar:

```
terraform -chdir=stacks/web-app plan \
  -var-file=../../profiles/<perfil>.tfvars \
  -var-file=../../clientes/<product>/naming.tfvars \
  -var-file=../../clientes/<product>/<environment>.tfvars
```

`apply` usa los mismos tres archivos.

## Un producto nuevo

1. Copiar `clientes/ejemplo/` a `clientes/<product>/`.
2. Editar `naming.tfvars` con el producto, el cliente y los nombres de servicios.
3. Editar `backend.hcl` con el bucket de state de la cuenta.
4. Editar `dev.tfvars` con el perfil de AWS, el rango de red y la imagen.
5. Ejecutar `.\scripts\tf.ps1 -Product <product> -Environment dev -Profile minimal -Command plan`.

La carpeta del producto no se versiona: solo `clientes/ejemplo/` va al repositorio.
