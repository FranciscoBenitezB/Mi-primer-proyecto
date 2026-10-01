# Práctica 1 — Ingesta y capa Bronze

**Nombre:** Francisco Benitez
**student_id:** francisco_benitez

### Tres observaciones sobre CSV/JSON, Parquet y Delta

1. **CSV vs. Parquet — tipos de datos.** El CSV no preserva tipos: todas las columnas de `customers` y `transactions` llegaron como `string`, incluido `amount`, que es numérico. Parquet, en cambio, trajo `products` con los tipos correctos (`product_id` como `long`, `price` como `decimal(12,2)`) porque los guarda dentro del archivo mismo.

2. **JSON — anidamiento y tipos simples.** A diferencia del CSV, que aplana todo a texto, JSON preserva tipos simples (`customer_id`, `event_id` y `product_id` como `long`) y además soporta estructuras anidadas: `context` llega como `struct`, agrupando `platform` y `session_id` dentro de una sola columna, algo que un CSV no puede representar sin aplanarlo en columnas separadas.

3. **Delta — lo que agrega por encima de Parquet.** Delta no reemplaza a Parquet, lo envuelve: los datos de `bronze_transactions` se guardan como archivos Parquet, pero `DESCRIBE HISTORY` muestra algo que un directorio Parquet suelto no tiene, un registro de transacciones con la operación (`CREATE OR REPLACE TABLE AS SELECT`), quién la hizo y cuándo. Eso es lo que permite versionar la tabla y auditar sus cambios.

### Las cinco V en este caso

- **Volumen:** se ve en el tamaño de las tablas Bronze: 5.000 clientes, 500 productos, 50.011 transacciones y 200.000 eventos.
- **Velocidad:** se ve en que los eventos son el dato que más rápido se acumula (200.000 registros contra 50.011 transacciones y 5.000 clientes), simulando un flujo de alta frecuencia.
- **Variedad:** se ve en los tres formatos de origen que conviven en la ingesta: CSV plano (clientes, transacciones), Parquet columnar (productos) y JSON semiestructurado con anidamiento (eventos).
- **Veracidad:** se ve en el diagnóstico de calidad: sobre 50.011 transacciones, 11 tienen `transaction_id` duplicado y 52 tienen un `amount` que no se puede convertir a número.
- **Valor:** se ve en que estos datos, una vez limpios en Silver y agregados en Gold, podrían usarse para detectar fraude (`is_fraud`), entender comportamiento de clientes o medir ventas por canal de pago.
