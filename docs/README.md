# Documentación

## Arquitectura

- [Vista general](architecture/overview.md): diagrama, recorrido de una petición y componentes.
- [Nombres](architecture/naming.md): cómo se arman los nombres y tags a partir del producto.
- [Entornos y perfiles](architecture/environments.md): perfiles `minimal` y `production`, y cómo se combinan los archivos de variables.
- [Costos del entorno dev](architecture/costs.md): cada servicio con su especificación y costo mensual.
- [State y backend](architecture/state-and-backend.md): dónde guarda Terraform el state y cómo se aísla cada cliente.

## Módulos

Cada módulo tiene tres documentos: `requirements.md` (qué debe hacer), `interface.md` (variables y salidas) y `design.md` (decisiones de diseño y su justificación).

- [bootstrap](modules/bootstrap/requirements.md): bucket del state remoto de una cuenta.
- [network](modules/network/requirements.md): VPC, subnets y rutas de un entorno.
- [static-site](modules/static-site/requirements.md): sitio estático en S3 con CloudFront, y enrutamiento de la API.
- [ecr](modules/ecr/requirements.md): repositorio de imágenes del backend.
- [ecs-service](modules/ecs-service/requirements.md): backend en contenedores con ECS Fargate.
- [api-gateway](modules/api-gateway/requirements.md): entrada al backend por HTTPS.
- [rds-postgres](modules/rds-postgres/requirements.md): base de datos PostgreSQL.
- [uploads-bucket](modules/uploads-bucket/requirements.md): bucket de archivos subidos por los usuarios.
- [acm-certificate](modules/acm-certificate/requirements.md): certificado HTTPS de un dominio propio.

## Stacks

- [web-app](stacks/web-app/requirements.md): entorno completo de una aplicación web.
- [dns-zone](stacks/dns-zone/requirements.md): zona de Route 53 del dominio propio, compartida por los entornos.
