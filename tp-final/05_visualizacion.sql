-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 05 — Visualización y verificación del resultado final
-- MAGIC Consultas sobre las tablas Gold para verificar e interpretar el resultado. No forma parte del Job.
-- MAGIC Para graficar: en la salida de cada celda, **+ → Visualization** (tipo sugerido en cada título).

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1. Ventaja de local según el régimen de público
-- MAGIC Gráfico sugerido: barras agrupadas, X = `liga`, Y = `pct_local` y `prob_local_mercado`, agrupado por `regimen_publico`.

-- COMMAND ----------

SELECT liga, regimen_publico, visitantes_permitidos, partidos,
       round(pct_local * 100, 1)           AS pct_local,
       round(prob_local_mercado * 100, 1)  AS prob_local_mercado,
       diferencia_goles_promedio
FROM workspace.tp_futbol.gold_resumen_regimen_publico
ORDER BY liga, regimen_publico, visitantes_permitidos;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2. Error del mercado sobre el local en partidos sin público, por trimestre
-- MAGIC Positivo = las cuotas le daban al local más chances de las que tuvo. Gráfico sugerido: barras, X = `trimestre`, Y = `error_mercado_pp`.

-- COMMAND ----------

SELECT trimestre,
       sum(partidos) AS partidos,
       round(sum(error_mercado_local_pp * partidos) / sum(partidos), 2) AS error_mercado_pp
FROM workspace.tp_futbol.gold_mercado_trimestral
WHERE regimen_publico = 'sin_publico'
GROUP BY trimestre
HAVING sum(partidos) >= 30
ORDER BY trimestre;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3. Margen de cada casa de apuestas por liga (%)
-- MAGIC Gráfico sugerido: barras agrupadas, X = `liga`, Y = las tres columnas de margen.

-- COMMAND ----------

SELECT liga,
       round(avg(margen_pinnacle) * 100, 2)          AS margen_pinnacle_pct,
       round(avg(margen_promedio_mercado) * 100, 2)  AS margen_promedio_mercado_pct,
       round(avg(margen_b365) * 100, 2)              AS margen_b365_pct,
       count(margen_b365)                            AS partidos_con_b365
FROM workspace.tp_futbol.gold_partidos
GROUP BY liga
ORDER BY liga;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 4. Evolución del margen de Pinnacle por año (%)
-- MAGIC Gráfico sugerido: líneas, X = `anio`, Y = `margen_pinnacle_pct`, una serie por `liga`.

-- COMMAND ----------

SELECT liga, anio,
       count(margen_pinnacle)                  AS partidos,
       round(avg(margen_pinnacle) * 100, 2)    AS margen_pinnacle_pct
FROM workspace.tp_futbol.gold_partidos
WHERE margen_pinnacle IS NOT NULL
GROUP BY liga, anio
ORDER BY liga, anio;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 5. Calibración de las cuotas y sesgo favorito-batacazo
-- MAGIC Cada partido aporta tres apuestas (local, empate, visitante) con la cuota principal.
-- MAGIC `resultado_por_peso_pct` = ganancia o pérdida promedio por cada $1 apostado. Gráfico sugerido: barras, X = `tramo`, Y = `resultado_por_peso_pct`.

-- COMMAND ----------

WITH apuestas AS (
  SELECT cuota_local AS cuota, CASE WHEN resultado = 'H' THEN 1 ELSE 0 END AS gana
  FROM workspace.tp_futbol.gold_partidos WHERE cuota_local IS NOT NULL
  UNION ALL
  SELECT cuota_empate, CASE WHEN resultado = 'D' THEN 1 ELSE 0 END
  FROM workspace.tp_futbol.gold_partidos WHERE cuota_empate IS NOT NULL
  UNION ALL
  SELECT cuota_visitante, CASE WHEN resultado = 'A' THEN 1 ELSE 0 END
  FROM workspace.tp_futbol.gold_partidos WHERE cuota_visitante IS NOT NULL
)
SELECT
  CASE WHEN 1/cuota <= 0.15 THEN '1) 0-15%'
       WHEN 1/cuota <= 0.25 THEN '2) 15-25%'
       WHEN 1/cuota <= 0.35 THEN '3) 25-35%'
       WHEN 1/cuota <= 0.45 THEN '4) 35-45%'
       WHEN 1/cuota <= 0.55 THEN '5) 45-55%'
       WHEN 1/cuota <= 0.65 THEN '6) 55-65%'
       WHEN 1/cuota <= 0.75 THEN '7) 65-75%'
       ELSE '8) 75-100%' END              AS tramo,
  count(*)                                 AS apuestas,
  round(avg(1/cuota) * 100, 1)             AS prob_implicita_pct,
  round(avg(gana) * 100, 1)                AS frecuencia_real_pct,
  round((avg(gana * cuota) - 1) * 100, 1)  AS resultado_por_peso_pct
FROM apuestas
GROUP BY 1
ORDER BY 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 6. ¿Alguna estrategia simple le gana a la casa?
-- MAGIC Resultado por cada $1 apostado (%), con la cuota principal y con Bet365.

-- COMMAND ----------

WITH p AS (
  SELECT *,
         least(cuota_local, cuota_empate, cuota_visitante) AS cuota_favorito,
         CASE least(cuota_local, cuota_empate, cuota_visitante)
              WHEN cuota_local THEN 'H' WHEN cuota_empate THEN 'D' ELSE 'A' END AS pick_favorito,
         greatest(cuota_local, cuota_visitante) AS cuota_batacazo,
         CASE WHEN cuota_local >= cuota_visitante THEN 'H' ELSE 'A' END AS pick_batacazo
  FROM workspace.tp_futbol.gold_partidos
  WHERE cuota_local IS NOT NULL
)
SELECT 'siempre_local' AS estrategia,
       round((avg(CASE WHEN resultado = 'H' THEN cuota_local ELSE 0 END) - 1) * 100, 2) AS cuota_principal_pct,
       round((avg(CASE WHEN resultado = 'H' THEN b365c_local ELSE 0 END) FILTER (WHERE b365c_local IS NOT NULL) - 1) * 100, 2) AS bet365_pct
FROM p
UNION ALL
SELECT 'siempre_empate',
       round((avg(CASE WHEN resultado = 'D' THEN cuota_empate ELSE 0 END) - 1) * 100, 2),
       round((avg(CASE WHEN resultado = 'D' THEN b365c_empate ELSE 0 END) FILTER (WHERE b365c_empate IS NOT NULL) - 1) * 100, 2)
FROM p
UNION ALL
SELECT 'siempre_visitante',
       round((avg(CASE WHEN resultado = 'A' THEN cuota_visitante ELSE 0 END) - 1) * 100, 2),
       round((avg(CASE WHEN resultado = 'A' THEN b365c_visitante ELSE 0 END) FILTER (WHERE b365c_visitante IS NOT NULL) - 1) * 100, 2)
FROM p
UNION ALL
SELECT 'siempre_favorito',
       round((avg(CASE WHEN resultado = pick_favorito THEN cuota_favorito ELSE 0 END) - 1) * 100, 2), NULL
FROM p
UNION ALL
SELECT 'siempre_batacazo',
       round((avg(CASE WHEN resultado = pick_batacazo THEN cuota_batacazo ELSE 0 END) - 1) * 100, 2), NULL
FROM p;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 7. ¿Influye la distancia que viaja el visitante?
-- MAGIC Gráfico sugerido: barras, X = `tramo_distancia`, Y = `pct_local`, una serie por `region`.

-- COMMAND ----------

SELECT CASE WHEN liga = 'ARG' THEN 'Argentina' ELSE 'Europa' END AS region,
       CASE WHEN distancia_km < 50   THEN '1) < 50 km'
            WHEN distancia_km < 200  THEN '2) 50-200 km'
            WHEN distancia_km < 500  THEN '3) 200-500 km'
            WHEN distancia_km < 1000 THEN '4) 500-1000 km'
            ELSE '5) > 1000 km' END                          AS tramo_distancia,
       count(*)                                              AS partidos,
       round(avg(CASE WHEN resultado = 'H' THEN 1 ELSE 0 END) * 100, 1) AS pct_local,
       round(avg(diferencia_goles), 3)                       AS diferencia_goles_promedio
FROM workspace.tp_futbol.gold_partidos
WHERE regimen_publico = 'pleno'
GROUP BY 1, 2
ORDER BY 1, 2;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 8. Auditoría del pipeline (idempotencia)

-- COMMAND ----------

SELECT * FROM workspace.tp_futbol.validacion_auditoria ORDER BY ejecutado_en;
