# ecr: decisiones de diseño

## Un repositorio por entorno

Cada entorno tiene su repositorio, como el resto de sus recursos. Promover una versión de `dev` a `prod` es subir la misma imagen al repositorio de `prod`. Un repositorio compartido ahorraría almacenamiento, pero ataría los entornos entre sí.

## Solo se conservan las últimas imágenes

Una regla de ciclo de vida elimina las imágenes más allá de las 10 más recientes, con o sin etiqueta. Sin ella, cada despliegue suma una imagen y el almacenamiento crece sin límite. Diez dejan margen para volver atrás varias versiones.

## Etiquetas mutables por defecto

En un entorno de prueba es cómodo reutilizar `latest`. En producción conviene `IMMUTABLE`: cada versión tiene su etiqueta y nadie puede sobrescribir una imagen ya desplegada.

## Análisis al subir

El análisis básico de ECR revisa cada imagen nueva contra vulnerabilidades conocidas del sistema operativo, sin costo. Los resultados se ven en la consola de ECR.

## Cifrado por defecto

Las imágenes se cifran con la llave administrada por ECR (AES-256), sin costo ni configuración.
