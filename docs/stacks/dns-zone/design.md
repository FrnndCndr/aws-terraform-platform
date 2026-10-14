# dns-zone: decisiones de diseño

## Un stack aparte

La zona pertenece al cliente, no a un entorno: `dev` usa `dev.<dominio>` y `prod` usa el dominio principal. Si la zona viviera en el stack de `dev`, destruir `dev` la borraría y dejaría a `prod` sin dominio. Por eso tiene su propio stack y su propio state, que se aplican una vez.

## Delegación desde el registrador

La zona responde las consultas del dominio solo cuando el registrador la señala como autoritativa: eso es cargar sus servidores de nombres en NIC Chile. Es el único paso que no hace Terraform, porque NIC Chile no ofrece integración.

Los servidores de nombres los asigna AWS al crear la zona. Si la zona se destruye y se vuelve a crear, cambian, y hay que repetir la delegación. Por eso la zona tiene `prevent_destroy`.

## Los registros los crean los entornos

Este stack solo crea la zona. Cada entorno crea sus propios registros (el subdominio del sitio y la validación del certificado) en su stack, junto con los recursos a los que apuntan. Destruir un entorno borra sus registros y deja intactos los del otro.

## Sin tag de entorno

La zona lleva los tags `client`, `project` y `managed_by`, sin `environment`, porque es compartida.
