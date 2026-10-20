# github-oidc: requisito

## Propósito

Crear los roles de IAM que GitHub Actions asume para desplegar el backend y el frontend de un entorno, con credenciales temporales y sin llaves guardadas en GitHub.

## Qué debe cumplir

1. Crea, por entorno, hasta dos roles: uno para desplegar el backend y otro para desplegar el frontend. Cada uno es opcional.
2. Cada rol solo lo puede asumir un workflow del repositorio indicado que corre en el environment de GitHub indicado.
3. El rol del backend solo puede subir imágenes al repositorio ECR del entorno, registrar definiciones de tarea, actualizar el servicio ECS del entorno y entregar a ECS los dos roles de ese servicio.
4. El rol del frontend solo puede escribir en el bucket del sitio del entorno e invalidar su distribución de CloudFront.
5. Usa el proveedor OIDC de GitHub que ya existe en la cuenta: no lo crea.
6. Entrega como salida el ARN de cada rol.

## Qué no hace

- No crea el proveedor OIDC: lo crea `bootstrap`, una vez por cuenta.
- No crea los workflows ni configura GitHub.
- No da permisos sobre la base de datos, los secretos ni Terraform.

## Costo

Sin costo. IAM y el intercambio de credenciales con OIDC no cobran.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, un workflow del repositorio y environment indicados asume el rol y despliega.
- Un workflow de otra rama, de otro environment o de otro repositorio no logra asumir el rol.
