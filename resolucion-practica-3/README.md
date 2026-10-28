# Entrega práctica 3 — Bases de datos NoSQL

* **Nombre: Francisco Benítez**
* **student\_id:francisco\_benitez**
* **Escala:small**



Responde cada pregunta en una a tres oraciones. Cuando se pide un dato, copia el valor que te dio el notebook.



## CAP y PACELC



1.En modo CP, la réplica C quedó aislada y respondió error (“no disponible”) porque no tenía quórum: sacrifica la disponibilidad (A). En modo AP, C respondió 100 aunque en A y B ya se había escrito 80, es decir, devolvió un dato desactualizado: sacrifica la consistencia (C).



**2.** En modo AP, después de la reparación las tres réplicas quedaron con saldo 50. Se perdió la escritura saldo=80 hecha en A, aunque había sido confirmada como OK, porque last-write-wins conservó la versión más nueva (la de C).



3.Con W=1 la p99 es 9,6 ms y con W=3 es 55,6 ms. Con W=3 hay que esperar la confirmación de todas las réplicas, incluida C, que está en otra región. A cambio de esa latencia se gana consistencia: todas las réplicas tienen el dato antes de responder OK. Es el trade-off de PACELC sin partición: latencia vs. consistencia.



**4.En modo CP solo pudo seguir escribiendo el lado ABC, porque tiene mayoría: el quórum con 5 réplicas es 5 // 2 + 1 = 3, y ABC tiene 3 nodos. El lado DE (2 nodos) no alcanza el quórum, por eso la escritura vía D dio error “sin quórum” y la lectura vía E dio “no disponible”.**



## Clave-valor



5.El GET en memoria tardó 0,0002 ms y el GET con Spark sobre Delta 819 ms: el de memoria fue \~3,6 millones de veces más rápido. Redis guarda los datos en memoria porque su caso de uso es encontrar un valor por clave en milisegundos: en RAM la tabla hash va directo a la clave, sin leer archivos ni ejecutar una consulta. La contra es que la RAM es más cara y limitada que el disco.



**6.** Para encontrar los 992 clientes de AR hubo que recorrer los 5.000 valores porque, en el modelo clave-valor, la base solo conoce la clave (customer:<id>). El país está dentro del JSON, pero la base no sabe que existe ese campo, así que tiene que abrir cada valor para filtrarlo.



Ventaja: la búsqueda por clave (customer:42) es directa y muy rápida, y las claves se reparten fácilmente entre nodos.

Desventaja: no se puede consultar por el contenido del valor (no hay WHERE country = 'AR'); para hacerlo hay que recorrer todo o mantener a mano estructuras extra, como un set country:AR.



**7**.Al pasar de 4 a 5 nodos, con hash mod N se movió el 79,6% de las claves y con hashing consistente el 21,2%. Conviene el hashing consistente porque, al agregar un nodo, solo se mueven las claves del tramo del anillo que ocupa, mientras que con mod N cambia el nodo de casi todas, porque la cuenta depende de la cantidad total de nodos. Mover menos claves significa transferir menos datos por la red y ser mas eficiente.



## Documental

**8.** La consulta relacional devolvió 11 filas (3 tablas, 2 joins): una por transacción, repitiendo los datos del cliente en cada una. La documental devolvió 1 documento (0 joins). Dentro del documento quedaron embebidos el perfil del cliente (profile), sus estadísticas (stats) y la lista de sus transacciones (transactions); dentro de cada transacción, además, se embebió una copia del producto (categoría y precio), conservando el product\_id como referencia al catálogo.



**9.** Spark armó un esquema con la unión de todos los campos de los documentos y completó con null los que faltaban en cada uno. El modelo documental tiene esquema flexible porque los documentos de una misma colección no necesitan tener los mismos campos ni un esquema definido de antemano: la estructura se interpreta al leer (schema-on-read), a diferencia del modelo relacional, donde se define antes de escribir.



**10.**El documento más grande pesa 5,2 KB (≈225 bytes por transacción); a ese ritmo, un cliente llegaría al límite de 16 MB de MongoDB con ≈74.599 transacciones. Si un documento crece sin límite, cada lectura y cada actualización se vuelven más lentas porque hay que mover el documento entero, y al llegar a 16 MB la base rechaza nuevas escrituras



**11.**El modelo documental resuelve bien las consultas centradas en una entidad, como traer un cliente con todo su historial o evaluar sus transacciones (compras grandes, dispositivos, fraude), porque todo está en un solo documento y no hacen falta joins. Le cuestan más las consultas analíticas que cruzan documentos, como el monto total por categoría: hay que usar explode para desarmar los arrays y volver a una fila por transacción antes de poder agrupar.



## Grafos

12.El grafo tiene 5.000 nodos Customer (738 marcados), 2.361 nodos Device y 5.400 aristas USES.



13.El patrón de 2 saltos necesitó 3 joins y el de 4 saltos, 5 joins: cada salto agrega un join contra la tabla de aristas. Neo4j recorre relaciones más eficientemente porque usa index-free adjacency: cada nodo guarda punteros directos a sus vecinos, así que un salto es seguir un puntero, sin buscar en una tabla. En una base relacional cada salto es un join sobre toda la tabla de aristas, y el costo crece con el tamaño de la tabla y con la cantidad de saltos.



14.La propagación de etiquetas convergió en 14 iteraciones (en la 14 ya no cambió ningún nodo). El componente conexo más grande es el c:122, con 23 nodos.



15.Con hash(id) mod 4, el 74,4% de las aristas quedó entre máquinas distintas. Distribuir un grafo es difícil porque las consultas recorren relaciones: si dos nodos conectados quedan en máquinas diferentes, cada salto entre ellos requiere una comunicación por red, y en recorridos de varios saltos eso se multiplica. 



## Vectorial

**16.**El vector de cada cliente es una lista de 10 números que resume su comportamiento; en qué categorías gasta, con qué medio paga, cuánto gasta en promedio y qué parte de sus compras son grandes. La similitud coseno compara dos de esas listas y dice qué tan parecido es el comportamiento de dos clientes.



**17.**Entre los clientes más parecidos a un cliente marcado, el 31,6% también está marcado, contra una tasa base de 14,8% (más del doble). Buscar clientes parecidos sirve para detectar casos sospechosos: si alguien se comporta como clientes con fraude, conviene revisarlo.



**18.**Con nprobe=4 se obtiene un recall de 0,872 (encuentra el 87% de los vecinos correctos) revisando solo el 6% de los vectores. Con la búsqueda aproximada se gana velocidad, porque compara contra una pequeña parte de los datos, y se pierde precisión, porque a veces no encuentra a algunos de los clientes más parecidos.



## Columnar

**19.**Los mismos datos ocupan 50,0 MB en CSV, 121,1 MB en JSON y 5,3 MB en Parquet. Para la consulta sobre amount, Spark leyó solo la columna amount (ReadSchema: struct<amount:decimal(12,2)>). Con los datos ordenados se pueden saltear 7 de los 8 archivos; sin ordenar, ninguno.



**20.**Guardar por columnas es bueno para analítica porque las consultas suelen usar pocas columnas sobre muchas filas: se lee solo lo necesario, los datos ocupan menos y se pueden saltear archivos enteros. No conviene para modificar una fila por vez porque los datos de esa fila están repartidos en varias columnas y archivos comprimidos, así que cambiar un solo registro obliga a reescribir bloques enteros.

