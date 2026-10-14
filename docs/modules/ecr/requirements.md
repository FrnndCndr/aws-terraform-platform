# ecr: requisito

## Propósito

Crear el repositorio privado de imágenes de contenedor de un servicio del backend.

## Qué debe cumplir

1. Crea un repositorio ECR con nombre `<name_prefix>-<service_name>`.
2. Analiza cada imagen al subirla en busca de vulnerabilidades conocidas.
3. Conserva solo las últimas imágenes (10 por defecto) y elimina las anteriores.
4. Entrega como salida la URL del repositorio, que es el destino de `docker push`.

## Costo

0,10 USD por GB almacenado al mes. Con 10 imágenes de unos cientos de MB, menos de 1 USD al mes. El análisis básico al subir no tiene costo.

## Verificación

- `terraform fmt -check -recursive`, `terraform validate` y `tflint` sin errores.
- Tras aplicar, `docker push` a la URL del repositorio funciona.
