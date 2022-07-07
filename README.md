# Sistema-administrador-de-Hoteles

La cadena de hoteles “Buenas noches” está construyendo un nuevo sistema para el control de sus hoteles,habitaciones, reservaciones y huéspedes.Nosotros nos encargamos del diseño de la base de datos.A  pesar  de  que  la  cadena  actualmente  contaba  con  8  hoteles,  es  necesario  que  el  sistema  permita  la creara de nuevos hoteles con o sin habitaciones, a cada hotel se le asigna un código de identificación, un nombre, su dirección y un teléfono de recepción. Cada hotel tiene distinto número de habitaciones, cada habitación tiene un número de huéspedes máximo, un nombre asignado, un precio distinto por noche, y es necesario poder llevar un control de qué habitaciones se encuentran desocupadas u ocupadas.Algunos hoteles cuentan con restaurantes, estos restaurantes actualmente son de las categorías Mexicana,Italiana, Japonesa, pero se planea incluir nuevas categorías en una próxima expansión.

Un cliente es aquel que se ha hospedado al menos una vez en la cadena del hotel, SÓLAMENTE DEBE EXISTIR UNA SOLA VEZ CADA CLIENTE EN EL LISTADO; es necesario conocer el nombre del cliente,sus apellidos, su teléfono y correo de contacto, un número de identificación, RFC, un número de cuentaobligatorio, y un número de cuenta opcional.

Una reservación es la asignación futura de un cliente a una habitación, es necesario tener un identificadorúnico de reservación, conocer la fecha de inicio, la fecha fin, fecha y hora de check in, fecha y hora decheck out, el total a pagar por la estadía, y el total de otros cargos.

Es necesario contar con un listado de empleados, cada hotel tiene un conjunto de empleados asignados, decada uno de ellos es necesario conocer su nombre, apellido materno, paterno, fecha de nacimiento, númerode identificación, RFC, puesto, un jefe asignado (opcional), fecha de ingreso, sueldo mensual, también esnecesario saber si están activos, de no ser así, también se registra su fecha de baja.

Cada restaurante cuenta con un menú, el cual consta de un listado de platillos y sus precios. Cada que unhuésped realice un consumo en un restaurante, el cargo se hace a su reservación, es necesario guardar unregistro de cada platillo que ordenó, el costo de cada platillo y la fecha de consumo.

Entonces todo estos fueron los requerimientos que se nos pidieron y fue lo que realizamos en nuestro proyecto. 
