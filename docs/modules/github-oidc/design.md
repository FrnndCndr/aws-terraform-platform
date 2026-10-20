# github-oidc: decisiones de diseño

## OIDC en lugar de llaves

GitHub Actions presenta a AWS un token firmado que dice qué repositorio, rama y environment ejecuta el workflow. AWS lo valida contra el proveedor OIDC de la cuenta y entrega credenciales que expiran en una hora. No hay llaves de larga duración que guardar en GitHub, rotar o que puedan filtrarse.

## La confianza se amarra al environment de GitHub

Cada rol acepta solo el `sub` de su repositorio y environment (ver "Formato inmutable del `sub`"), con la audiencia `sts.amazonaws.com`. Se usa el environment, no la rama, porque GitHub permite fijar en cada environment qué ramas pueden desplegar y exigir aprobaciones. La regla queda repartida:

- **GitHub** decide qué rama entra a qué environment (por ejemplo, solo `dev` al environment `dev`).
- **AWS** exige que el token venga de ese repositorio y de ese environment.

Un workflow que corre sin environment, o desde un fork, presenta otro `sub` y no puede asumir el rol.

## Formato inmutable del `sub`

GitHub puede emitir el `sub` en dos formatos, según la configuración de cada repositorio (`use_immutable_subject`):

| Formato | `sub` |
|---|---|
| Por nombre | `repo:<owner>/<repo>:environment:<env>` |
| Inmutable | `repo:<owner>@<owner_id>/<repo>@<repo_id>:environment:<env>` |

El formato inmutable agrega los id numéricos de la organización y del repositorio. Protege contra que alguien ocupe el nombre de un repositorio borrado o renombrado y despliegue con su rol, porque el id nuevo no coincide.

El módulo arma el formato que el repositorio usa: con `github_owner_id` y el id de cada repositorio, el inmutable; sin ellos, el de por nombre. La comparación es exacta (`StringEquals`), así que un formato equivocado rechaza el rol con `Not authorized to perform sts:AssumeRoleWithWebIdentity`. El formato que emite un repositorio se consulta en `repos/<owner>/<repo>/actions/oidc/customization/sub` de la API de GitHub.

Si el repositorio pasa a otra organización, su id se mantiene y cambian el nombre y el id de la organización.

## Un rol por parte de la aplicación

El backend y el frontend tienen roles separados, cada uno con la confianza de su propio repositorio. Si el repositorio del frontend se ve comprometido, no puede tocar el backend, y al revés. Si las dos partes viven en el mismo repositorio, los dos roles confían en él.

## Permisos mínimos

| Rol | Puede | Sobre |
|---|---|---|
| Backend | Iniciar sesión en ECR | Toda la cuenta: la acción no admite un recurso |
| Backend | Subir y leer imágenes | El repositorio ECR del entorno |
| Backend | Leer y registrar definiciones de tarea | Toda la cuenta: las acciones no admiten un recurso |
| Backend | Actualizar y consultar el servicio | El servicio ECS del entorno |
| Backend | Entregar roles a ECS (`iam:PassRole`) | Solo el rol de ejecución y el rol de la tarea del servicio, y solo hacia `ecs-tasks.amazonaws.com` |
| Frontend | Listar el bucket | El bucket del sitio |
| Frontend | Subir, leer y borrar archivos | Los objetos del bucket del sitio |
| Frontend | Crear y consultar invalidaciones | La distribución del sitio |

Registrar una definición de tarea permite, en teoría, crear una con otros roles. La restricción de `iam:PassRole` lo impide: ECS rechaza una definición cuyos roles el rol del pipeline no puede entregar.

## El proveedor llega desde fuera

Una cuenta solo admite un proveedor OIDC por URL (`token.actions.githubusercontent.com`). Como `dev` y `prod` de un producto comparten la cuenta, el proveedor no puede pertenecer a un entorno: lo crea `bootstrap`, y el módulo recibe su ARN.

## Los recursos llegan desde fuera

El módulo no conoce el repositorio ECR, el servicio ni el bucket: recibe sus ARN. Así sirve para cualquier stack que despliegue un contenedor en ECS o un sitio en S3 con CloudFront.
