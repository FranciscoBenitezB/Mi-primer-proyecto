# Entrega práctica 5 — MLOps con MLflow

* **Nombre:** Francisco Benitez
* **student\_id:** francisco\_benitez
* **Escala:** small



## Mis runs

| run | modelo | features | class\_weight | umbral | hiperparametros | train\_pr\_auc | pr\_auc | accuracy | precision | recall | f1 |

|---|---|---|---|---|---|---|---|---|---|---|---|

| mejor\_balanced | gradient\_boosting | completas | balanced | 0.5 | learning\_rate=0.1, max\_depth=3 | 0.602 | 0.586 | 0.809 | 0.329 | 0.808 | 0.468 |

| mejor\_u0.3 | gradient\_boosting | completas | ninguno | 0.3 | learning\_rate=0.1, max\_depth=3 | 0.608 | 0.585 | 0.908 | 0.554 | 0.564 | 0.559 |

| gb\_completas | gradient\_boosting | completas | ninguno | 0.5 | learning\_rate=0.1, max\_depth=3 | 0.608 | 0.585 | 0.918 | 0.717 | 0.353 | 0.473 |

| max\_depth=8 | random\_forest | completas | ninguno | 0.5 | n\_estimators=100, max\_depth=8 | 0.643 | 0.568 | 0.914 | 0.799 | 0.226 | 0.352 |

| rf\_completas | random\_forest | completas | ninguno | 0.5 | n\_estimators=100, max\_depth=8 | 0.643 | 0.568 | 0.914 | 0.799 | 0.226 | 0.352 |

| log\_completas | logistic\_regression | completas | ninguno | 0.5 | C=1.0 | 0.531 | 0.545 | 0.917 | 0.758 | 0.288 | 0.417 |

| max\_depth=5 | random\_forest | completas | ninguno | 0.5 | n\_estimators=100, max\_depth=5 | 0.561 | 0.541 | 0.903 | 0.906 | 0.078 | 0.144 |

| max\_depth=sin\_limite | random\_forest | completas | ninguno | 0.5 | n\_estimators=100, max\_depth=sin\_limite | 1.0 | 0.537 | 0.916 | 0.689 | 0.341 | 0.456 |

| max\_depth=3 | random\_forest | completas | ninguno | 0.5 | n\_estimators=100, max\_depth=3 | 0.535 | 0.525 | 0.896 | 0.0 | 0.0 | 0.0 |

| (automático) | random\_forest | completas | ninguno | 0.5 | n\_estimators=100, max\_depth=3 | 0.535 | 0.525 | 0.896 | 0.0 | 0.0 | 0.0 |

| (automático) | random\_forest | completas | ninguno | 0.3 | n\_estimators=100, max\_depth=3 | 0.535 | 0.525 | 0.911 | 0.766 | 0.212 | 0.332 |

| 01\_repro\_b | random\_forest | cliente | ninguno | 0.5 | n\_estimators=100, max\_depth=8 | 0.594 | 0.51 | 0.909 | 0.722 | 0.207 | 0.321 |

| 01\_repro\_a | random\_forest | cliente | ninguno | 0.5 | n\_estimators=100, max\_depth=8 | 0.594 | 0.51 | 0.909 | 0.722 | 0.207 | 0.321 |

| log\_cliente | logistic\_regression | cliente | ninguno | 0.5 | C=1.0 | 0.447 | 0.448 | 0.902 | 0.614 | 0.157 | 0.25 |

| Run\_1 | logistic\_regression | basicas | ninguno | 0.5 | C=1.0 | 0.341 | 0.339 | 0.896 | 0.493 | 0.045 | 0.082 |


**Run registrado: mejor\_balanced (gradient boosting, completas, class\_weight = balanced).**

## Datos y tracking


**1.** El split train tiene 35.654 filas (11,05 % de contracargos), test tiene 7.129 (10,38 %) y nuevas tiene 7.165 (11,05 %). Se separa por fecha porque así se entrena con el pasado (1 al 5 de marzo) y se evalúa con lo que viene después (6 de marzo), igual que cuando el modelo esté en uso real. Si se separara al azar, el modelo vería información del futuro durante el entrenamiento y el resultado en test sería más optimista de lo que en verdad va a rendir.



**2.** Un “modelo” que siempre dice que no hay contracargo obtiene una accuracy del 89,6 %, sin detectar ni un solo contracargo. Como las clases están desbalanceadas (casi el 90 % de las compras no tiene contracargo), la accuracy engaña: se puede tener un valor alto sin que el modelo sirva. Por eso se usa el PR-AUC, que mide qué tan bien el modelo ordena las transacciones de más a menos riesgosas, sin depender de un umbral.



**3.** En 01\_manual\_logistica se registraron como parámetros el tipo de modelo (logistic\_regression), el conjunto de variables (basicas), C = 1.0, class\_weight = ninguno, el umbral (0,5), la tabla (ml\_features) y su versión (0). Como métricas, las de test (PR-AUC 0,339, ROC-AUC 0,794, accuracy 0,896, precision 0,493, recall 0,045, F1 0,082 y 67 alertas) y el train\_pr\_auc (0,341); como artefacto, la matriz de confusión, y el modelo con su firma quedó en Logged models. Un run es un entrenamiento concreto con sus parámetros, métricas y artefactos, mientras que un experimento es el contenedor que agrupa varios runs del mismo problema para poder compararlos.



**4.** Autolog registró 46 parámetros (todos los del Pipeline de scikit-learn), contra los 7 que elegimos a mano. Sus métricas son sólo de entrenamiento: training\_accuracy\_score, training\_f1\_score, training\_log\_loss, training\_precision\_score, training\_recall\_score, training\_roc\_auc y training\_score. No registra lo propio del problema que sí registramos a mano: las métricas sobre test (porque no sabe cuál es nuestro conjunto de test), el PR-AUC, el umbral y la versión de los datos.



**5.** Sí, 01\_repro\_a y 01\_repro\_b dieron exactamente las mismas métricas (PR-AUC de test 0,5099 en ambos). Se mantuvieron porque se fijaron las cuatro fuentes de variación: los mismos datos (la versión Delta de ml\_features, registrada en data\_version), el mismo código, la misma semilla (random\_state=42) y el mismo entorno (el requirements.txt que MLflow guarda junto al modelo)



**6.** Al llamar al modelo sin la columna amount, MLflow lanzó un error (“Failed to enforce schema”) y frenó la predicción antes de calcular nada, porque amount está marcada como columna obligatoria en la firma. La firma (signature) declara qué columnas y tipos de datos espera recibir el modelo como entrada y qué devuelve como salida; funciona como un contrato que impide usar el modelo con datos que no lo cumplen.



## Tus experimentos



**7.** Mi mejor run fue mejor\_balanced: gradient\_boosting con variables completas, max\_depth = 3, learning\_rate = 0.1 y class\_weight = balanced, con un PR-AUC de test de 0,586 (prácticamente igual a gb\_completas, sin balancear, con 0,585). Respecto de usar sólo rule\_alert (solo\_regla, PR-AUC 0,170), mejoró 0,416 puntos, es decir, unas 3,4 veces más.



**8.** Con regresión logística, el PR-AUC pasó de 0,339 con basicas a 0,448 con cliente (+0,109) y a 0,545 con completas (+0,097), una mejora total de 0,206. En mi mejor run, las variables más importantes (según la caída del PR-AUC al desordenar cada columna) fueron amount (\~0,33), payment\_channel (\~0,18) y hour (\~0,10), seguidas por category, account\_age\_days y device\_customers; is\_night, country, price y day\_of\_week casi no aportaron.



**9.** Con completas, el mejor fue el gradient boosting (PR-AUC 0,585), seguido del bosque (0,568) y la logística (0,545). La logística le da un peso fijo a cada variable y los suma, así que trata “de noche” y “por transferencia” por separado. Un árbol, en cambio, va haciendo preguntas encadenadas (por ejemplo, “¿es de noche?” y después “¿es transferencia?”), por lo que puede detectar que la combinación de ambas es más riesgosa.



**10.** Con class\_weight = balanced, la precision bajó de 0,717 a 0,329, el recall subió de 0,353 a 0,808 y las alertas pasaron de 364 a 1.818. El PR-AUC casi no cambió (0,585 → 0,586): balancear hace que el modelo dé probabilidades más altas a todas las transacciones, así que más superan el umbral, pero el orden de riesgo entre ellas se mantiene.



**11.** Al bajar el umbral de 0,5 a 0,3 (gradient boosting con completas), las alertas pasaron de 364 a 753, el recall subió de 0,353 a 0,564 y la precision bajó de 0,717 a 0,554; el F1 subió de 0,473 a 0,559 y el PR-AUC quedó igual (0,585). El PR-AUC no depende del umbral porque evalúa todos los umbrales posibles y mide qué tan bien el modelo ordena las transacciones por riesgo; el F1 sí depende porque se calcula con la precision y el recall de un umbral concreto.



**12.** Barrí max\_depth en un random\_forest con completas. El mejor PR-AUC de test fue con max\_depth = 8 (0,568). Con sin\_limite, el train\_pr\_auc llegó a 1,0 mientras el de test cayó a 0,537: el modelo memorizó los datos de entrenamiento en lugar de aprender patrones generalizables. Ese fenómeno se llama sobreajuste (overfitting).



## Comparar y elegir



**13.** No coincidieron: el mejor por PR-AUC fue mejor\_balanced (0,586, accuracy 0,809) y el mejor por accuracy fue gb\_completas (accuracy 0,918, PR-AUC 0,585). Con clases desbalanceadas, la accuracy premia a los modelos que alertan poco (no alertar nunca ya da 0,896), mientras que el PR-AUC mide qué tan bien se ordena el riesgo, sin depender del umbral.



**14.** Los runs más alejados de la diagonal son los dos max\_depth=sin\_limite: con basicas (train 0,998 vs. test 0,205) y con completas (train 1,0 vs. test 0,537). Estar lejos de la diagonal indica sobreajuste: sin límite de profundidad, los árboles memorizan los datos de entrenamiento y no generalizan a datos nuevos.



**15.** Consultar con mlflow.search\_runs devuelve los runs como una tabla dentro del código, que se puede filtrar, ordenar y usar automáticamente (por ejemplo, para elegir y registrar el mejor modelo sin intervención manual), algo que no escala mirando la interfaz cuando hay cientos de runs. El filtro para traer sólo los bosques con PR-AUC de test mayor a 0,55 sería:

tags.student\_id = 'francisco\_benitez' AND params.model\_type = 'random\_forest' AND metrics.test\_pr\_auc > 0.55



**16.** En fraude suele costar más un contracargo no detectado, porque la plataforma pierde el dinero de la compra (y paga costos del contracargo), mientras que una alerta falsa sólo cuesta tiempo de revisión y algo de fricción con el cliente. Si el equipo de riesgo puede revisar una cantidad fija de alertas por día, usaría el umbral para que la cantidad de alertas coincida con esa capacidad: como el modelo ordena las transacciones por riesgo, se alertan las N más riesgosas y el umbral queda en la probabilidad de la N-ésima.



## Registro, uso y monitoreo



**17.** Sí, se registró como workspace.bigdata\_francisco\_benitez.fraud\_model, versión 1, con el alias champion. La ventaja de usar el alias es que siempre apunta al modelo vigente: si mañana hay uno mejor, se le pasa el alias y quien lo usa no tiene que cambiar nada.



**18.** Se puntuaron 7.165 transacciones nuevas y 1.825 generaron alerta (25,5 %). Cada decisión se puede revisar con las columnas score, alerta, threshold, model\_name, model\_version, run\_id y scored\_at. El umbral se guarda aparte porque es una decisión del negocio (cuántas alertas se pueden revisar) y se puede cambiar sin volver a entrenar el modelo.



**19.** Sí, fue muy parecido: 0,579 en las nuevas contra 0,586 en test. Con la campaña simulada, las alertas subieron del 25,5 % al 42,9 %. El drift es cuando los datos nuevos dejan de parecerse a los que el modelo usó para aprender. Se puede detectar antes de tener las etiquetas porque los cambios en las compras (montos, medios de pago) y en los puntajes del modelo se ven enseguida, mientras que los contracargos reales se confirman recién días después



## Cierre



**20.** Pasé por todas las etapas: preparé y separé los datos, entrené varios modelos, MLflow guardó cada prueba, registré el mejor con nombre y versión, lo usé para puntuar transacciones nuevas y controlé cómo le fue con los resultados reales. Para usarlo de verdad faltaría que el proceso corra solo todos los días, que avise automáticamente si el modelo empieza a fallar o cambian los datos, y que se reentrene cada cierto tiempo con datos nuevos.

