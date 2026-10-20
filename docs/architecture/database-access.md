# Acceso a la base de datos

La base de datos está en subredes privadas y no acepta conexiones desde internet. Para consultarla desde un equipo (DBeaver, psql) se abre un túnel de Session Manager a través de la tarea del backend.

## Cómo funciona

```
DBeaver ──▶ 127.0.0.1:15432 ──▶ Session Manager ──▶ tarea de ECS ──▶ RDS:5432
```

- El túnel entra por la tarea del backend con ECS Exec, que debe estar activo (`backend_enable_execute_command = true`; el perfil `minimal` lo activa).
- El puerto local escucha solo en `127.0.0.1`: nadie de la red puede usarlo.
- No se abre ningún puerto en AWS. Abrir el túnel requiere credenciales de IAM, y conectarse a la base, además, su usuario y contraseña.

## Uso

```
.\scripts\db-tunnel.ps1 -Product <product> -Environment <environment>
```

- Busca la tarea en ejecución en cada llamada y abre el túnel. Queda abierto hasta cerrar la ventana o presionar `Ctrl+C`.
- `-LocalPort` cambia el puerto local (por defecto `15432`), por ejemplo para abrir dos túneles a la vez.
- Usa el perfil de AWS de `clientes/<product>/<environment>.tfvars`.

En el cliente de base de datos: host `127.0.0.1`, el puerto local, la base de `db_name`, SSL `require`, y el usuario y la contraseña del secreto de la base (`db_secret_arn`).

## Cuándo hay que reabrirlo

El túnel apunta a una tarea concreta. Cada despliegue del backend reemplaza la tarea, y el túnel abierto deja de servir: se cierra y se vuelve a correr el mismo comando. Session Manager también cierra la sesión tras 20 minutos sin tráfico (configurable en las preferencias de Session Manager, hasta 60).

Una IP fija no resuelve esto: el túnel identifica la tarea por su id, no por su IP, y Fargate no admite Elastic IP.

## Requisitos del equipo

- AWS CLI y el plugin de Session Manager (`session-manager-plugin`).
- La SCP de la organización debe permitir `ssmmessages:*`. Si la niega, el túnel falla con `TargetNotConnected`.
