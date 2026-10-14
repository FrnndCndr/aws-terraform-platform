# aws-terraform-platform

## Descripción

Plataforma de Terraform para AWS donde se gestiona la infraestructura de varios clientes a partir de una misma base de código.

La arquitectura de referencia incluye:

- **Red:** VPC con subnets públicas y privadas.
- **Base de datos:** PostgreSQL en RDS.
- **Servicios:** contenedores con ECS/Fargate.
- **Sitios estáticos:** S3 con CloudFront.

La lógica vive en módulos reutilizables, uno por responsabilidad. Cada cliente y entorno se describe con un archivo de variables (`.tfvars`) y tiene su propio state, de modo que un cambio en un cliente nunca afecta a otro.

### Valor

- **Rapidez:** levantar un entorno nuevo es copiar un archivo de configuración y editarlo.
- **Repetibilidad:** el mismo código produce la misma infraestructura en cada cliente.
- **Aislamiento:** un state por cliente y entorno.
- **Trazabilidad:** la infraestructura queda versionada y revisable.

## Estructura

Estructura objetivo del repositorio. Se construye por fases, por lo que algunas carpetas aún no existen.

```
aws-terraform-platform/
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       └── validate.yml
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── modules/
│   ├── network/
│   ├── static-site/
│   ├── ecr/
│   ├── ecs-service/
│   ├── api-gateway/
│   ├── rds-postgres/
│   ├── uploads-bucket/
│   └── acm-certificate/
├── stacks/
│   ├── dns-zone/
│   └── web-app/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── backend.tf
├── clientes/
│   ├── ejemplo/
│   │   ├── dev.tfvars
│   │   └── prod.tfvars
│   └── .gitkeep
└── docs/
    └── modules/
```

- **`bootstrap/`:** crea el bucket de state remoto de cada cuenta. Se aplica una vez.
- **`modules/`:** módulos reutilizables, uno por responsabilidad.
- **`stacks/web-app/`:** compone los módulos en una arquitectura completa.
- **`stacks/dns-zone/`:** zona DNS del dominio propio, compartida por los entornos de un cliente.
- **`clientes/`:** un archivo de variables por cliente y entorno. Solo `ejemplo/` se versiona.
- **`docs/modules/`:** documentación de cada módulo.
