# network: decisiones de diseño

## Subnets públicas y privadas

Una subnet es pública cuando su tabla de rutas envía el tráfico de internet a un Internet Gateway; es privada cuando no tiene esa ruta. La diferencia es solo la ruta.

En las públicas van los recursos que reciben tráfico de internet o necesitan salir a él: el balanceador y, en la configuración mínima, las tareas del backend. En las privadas va la base de datos, que no necesita internet y así no es alcanzable desde fuera.

## Dos zonas de disponibilidad como mínimo

Un balanceador de aplicación exige subnets en al menos dos zonas, y RDS exige lo mismo para su grupo de subnets aunque la base use una sola. Dos es el mínimo que permite desplegar el resto de la arquitectura. Tres agrega tolerancia a fallos sin costo en la red.

## Qué zonas se usan

Se toman las primeras zonas estándar de la región, sin Local Zones ni zonas que requieran activación. `excluded_zone_ids` deja fuera zonas por su id. Los ids identifican la misma zona física en todas las cuentas, a diferencia de los nombres (`us-east-1a`), que AWS reparte distinto en cada cuenta.

El stack excluye por defecto `use1-az3`, una zona antigua de `us-east-1` donde varios servicios y tipos de instancia no están disponibles.

## El NAT Gateway es opcional y está desactivado por defecto

Un NAT Gateway permite que recursos en subnets privadas salgan a internet sin ser alcanzables desde fuera. Cuesta cerca de 33 USD al mes por existir, más el tráfico.

En la configuración mínima no se crea: las tareas del backend van en subnets públicas con IP pública, y su security group solo acepta tráfico de la entrada al backend. En producción se activa y las tareas pasan a subnets privadas, sin IP pública.

## Un NAT Gateway o uno por zona

Con uno solo, todas las subnets privadas salen por la misma zona: si esa zona falla, pierden la salida a internet. Uno por zona elimina ese punto único de fallo y multiplica el costo. `single_nat_gateway` deja elegir según el entorno.

## Una tabla de rutas privada por zona

Cada subnet privada tiene su propia tabla de rutas, aunque no haya NAT. Así, activar un NAT por zona solo agrega una ruta a cada tabla, sin recrear tablas ni asociaciones.

## Subnets `/20` calculadas desde el rango de la VPC

Los rangos de las subnets se derivan de `vpc_cidr` en lugar de recibirse uno por uno: hay menos variables y no es posible declarar rangos que se solapen. Las públicas ocupan la primera mitad del rango de la VPC y las privadas la segunda, lo que deja espacio para más zonas sin renumerar.

## Sin IP pública automática

Las subnets públicas no asignan IP pública a lo que se lance en ellas. Cada recurso que la necesita la pide de forma explícita, de modo que ninguno queda expuesto por omisión.

## Cada entorno tiene su VPC

Los entornos de un cliente no comparten red. Usan rangos distintos (`10.20.0.0/16`, `10.21.0.0/16`) para poder conectarlos entre sí más adelante sin conflicto de direcciones.

## Sin security groups en este módulo

Cada módulo crea el security group de su propio recurso y declara de quién acepta tráfico. La red no conoce qué servicios se despliegan en ella.
