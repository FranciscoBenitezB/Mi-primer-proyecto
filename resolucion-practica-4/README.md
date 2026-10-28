# Entrega práctica 4 — Streaming

- **Nombre:** Francisco Benitez
- **student_id:** francisco_benitez
- **Escala:** small

Respondé cada pregunta en una a tres oraciones. Cuando se pide un dato, copiá el valor que te dio el notebook.

## Log y offsets

**1.** En la cola quedan solo los mensajes 4 y 5, dado que se borraron el 1, 2 y 3 al ser leídos. En el log, en cambio, todavía quedan los 5 mensajes, dado que no se borran.

**2.** El consumidor `antifraude` leyó 180 mensajes y `reportes` leyó 0. El atraso de `reportes` no afecta a `antifraude` porque cada consumidor mantiene su propio offset/checkpoint de forma independiente.

**3.** Un offset es el punto hasta donde un consumidor ya leyó el log. Se guarda en el checkpoint de cada consumidor, e indica desde dónde tiene que retomar la lectura.

**4.** El replay leyó los 280 mensajes. Kappa propone unificar todo en un solo pipeline de streaming, reprocesando también el histórico mediante replay sobre el mismo log. Lambda, en cambio, usa dos caminos paralelos (una capa batch y una de streaming) que después se combinan.

## Ingesta y enriquecimiento

**5.** Bronze procesa la totalidad de filas nuevas en cada llegada (si la llegada trae 60 filas, procesa 60). Al reejecutar sin archivos nuevos, procesa 0 filas, porque Auto Loader ya sabe qué archivos leyó y evita reprocesarlos.

**6.** Los motivos de rechazo fueron `INVALID_AMOUNT` y `UNKNOWN_CUSTOMER`, en la llegada `stream_002`. Bronze guarda el texto original porque lo que hoy se considera "error" puede cambiar (reglas de calidad distintas), y si se descartara de entrada se perdería la capacidad de reprocesar esos datos en el futuro.

**7.** El join agregó las columnas `country` (de `silver_customers`) y `category` (de `silver_products`). Es un join stream-tabla, porque el stream de eventos (`event_ts`) se enriquece contra tablas Delta estáticas.

## Tiempo y ventanas

**8.** La diferencia es el momento en que ocurrió el evento (event time) versus el momento en que el sistema lo procesa (processing time). Ejemplo con `late_ok`: ocurrió a las 12:03 (event time) pero llegó al sistema recién en la llegada 2, con processing time posterior.

**9.** El watermark valía 11:54, 11:58, 12:16, 12:17 y 12:35 al terminar cada llegada. Se calcula como el máximo event time visto hasta ese momento, menos 10 minutos de tolerancia.

**10.** Las primeras ventanas tumbling en modo append aparecen en la llegada 3, porque recién ahí el watermark (12:16, calculado a partir del evento de las 12:26) supera por primera vez el final de las primeras ventanas. Antes (11:54 y 11:58 en las llegadas 1 y 2) el watermark no alcanzaba ese límite.

**11.** Mientras la ventana sigue abierta, un evento que llega tarde igual se contabiliza en su ventana de event_time correspondiente (eso es `late_ok`). Un evento pasa a ser `late_bad` (no contabilizado) cuando llega después de que su ventana correspondiente ya se cerró.

**12.** Tumbling: ventanas fijas, sin huecos ni solapamiento entre sí — sirve por ejemplo para ver ventas en bloques de tiempo. Hopping: ventanas que se solapan, un evento puede caer en varias — útil para ver tendencias en tiempo real sin esperar a que cierre un bloque entero. Session: no tiene tamaño fijo, agrupa según la actividad detectada — permite ver momentos de mayor actividad de un usuario sin los tiempos muertos.

**13.** En modo update se emitió con el primer dato (llegada 1, 12:01) y se volvió a emitir cuando llegó `late_ok` en la llegada 2. En modo append se emitió una sola vez, cuando la ventana se cerró. Update muestra datos en tiempo real pero con resultados parciales que se repiten; append tarda más pero da un resultado único y definitivo.

**14.** Con un watermark de 1 minuto se gana velocidad: las ventanas se cierran casi de inmediato, dando resultados con menos latencia. Pero se pierde completitud, porque aumenta la cantidad de eventos que terminan en `late_bad` (datos tardíos pero legítimos que antes, con 10 minutos de margen, se habrían aceptado).

## Garantías y fallas

**15.** Quedaron 200 filas sin duplicar y 20 duplicadas al no deduplicar por `event_id`. Esto ocurre porque el productor trabaja bajo at-least-once: ante la duda de si un envío llegó o no, reintenta, y el mismo evento puede terminar repetido en dos llegadas.

**16.** Al reiniciar con el mismo checkpoint, el sistema sabe qué ya procesó y evita duplicados. Al perder el checkpoint, no tiene memoria de nada, así que reprocesa todo desde cero y genera duplicados. La garantía observada es exactly-once en el primer caso y at-least-once en el segundo.

**17.** `MERGE` es una escritura idempotente: antes de insertar, busca si la clave (`event_id`) ya existe en el destino, y si es así actualiza o no hace nada en vez de duplicar. Por eso, aunque se pierda el checkpoint y el streaming reprocese eventos ya escritos, el resultado final no cambia. Que una escritura sea idempotente significa que aplicarla una vez o varias veces produce siempre el mismo resultado.

## CDC

**18.** El log generó 13 eventos de cambio: 6 `insert`, 3 `update_preimage`, 3 `update_postimage` y 1 `delete`. Un `UPDATE` genera dos eventos porque el CDC registra por separado el estado anterior de la fila (preimage) y el estado nuevo (postimage), en vez de un solo evento de cambio. Por eso `update_preimage` y `update_postimage` coinciden en 3: son las mismas 3 filas actualizadas, antes y después.

**19.** Sí, la tabla reconstruida aplicando los eventos del log en orden coincide con la tabla original. A diferencia del snapshot actual, que solo muestra el estado final de cada fila, el log conserva el historial completo de cambios (cada insert, update y delete con sus valores anteriores y nuevos). Esto permite reconstruir el estado de la tabla en cualquier momento del tiempo, no solo el más reciente.

