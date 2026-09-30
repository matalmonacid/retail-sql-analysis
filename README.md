# Análisis de ventas con SQL

Proyecto de análisis de transacciones de una tienda online británica con **SQLite y Python**. Las consultas estudian la evolución mensual del importe neto, los productos principales de cada país y la frecuencia de compra de los clientes.

**Autor:** Matías Almonacid Mellado

- [Notebook con código, resultados e interpretaciones](retail_sql_analysis.ipynb)
- [Consultas SQL](sql/consultas.sql)

## Preguntas y resultados

| Pregunta | Resultado |
| --- | --- |
| ¿Qué mes completo tiene el mayor importe neto? | Noviembre de 2011: £1.432.734,99 |
| ¿Qué productos destacan dentro de cada país? | Ranking de las primeras tres posiciones en 38 países; 134 filas al conservar empates |
| ¿Qué cliente registra más facturas de venta? | Cliente 12748: 206 facturas |
| ¿Qué proporción compra en distintos meses? | 2.695 de 4.334 clientes identificados: 62,18 % |

Los 536.465 movimientos seleccionados suman £9.792.708,88 de importe neto registrado. Las ventas positivas suman £10.271.433,06 y las cancelaciones, −£478.724,18.

## Técnicas utilizadas

- Selección y normalización con `WHERE`, `TRIM` y `UPPER`.
- Agregación con `GROUP BY`, `HAVING`, `SUM` y `COUNT(DISTINCT ...)`.
- Clasificación y agregación condicional mediante `CASE`.
- Vistas y CTE para organizar las consultas.
- `JOIN` para combinar el resumen por producto con el total de su país.
- `LAG` para comparar meses y `DENSE_RANK` para conservar empates en los rankings.
- Funciones de ventana para calcular participaciones sin colapsar los grupos.

Python carga el Excel en SQLite y presenta o exporta los resultados. Los cálculos del análisis se realizan con SQL. La base contiene una tabla de transacciones y una vista; las consultas combinan resúmenes derivados de esa tabla.

## Datos y criterios

Fuente: Chen, D. (2015). *Online Retail*. UCI Machine Learning Repository. [DOI: 10.24432/C5BW33](https://doi.org/10.24432/C5BW33).

El archivo contiene 541.909 registros del 1 de diciembre de 2010 al 9 de diciembre de 2011. Los importes se expresan en libras esterlinas (GBP).

Se conservan precios positivos y cantidades distintas de cero. Se excluyen códigos identificados como envíos, comisiones, descuentos, ajustes, operaciones manuales, muestras y vales. Las cantidades negativas seleccionadas se mantienen para calcular el importe neto. Las filas repetidas se conservan porque no existe un identificador de línea que permita confirmar errores.

Los registros sin cliente identificado se incluyen en los análisis generales y se excluyen de las consultas por cliente.

Datos disponibles en [UCI](https://archive.ics.uci.edu/dataset/352/online+retail), bajo [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). El Excel y la base generada no se incluyen en el repositorio.

## Cómo ejecutar

1. Descarga este repositorio y extrae su contenido.
2. Descarga y descomprime el conjunto de datos desde UCI. Coloca `Online Retail.xlsx` junto al notebook.
3. Instala las dependencias desde una terminal en la carpeta del proyecto:

   ```bash
   python -m pip install -r requirements.txt
   ```

4. Inicia Jupyter:

   ```bash
   python -m jupyterlab
   ```

5. Abre `retail_sql_analysis.ipynb` y ejecuta todas las celdas en orden desde un kernel reiniciado.

El notebook crea `online_retail.db`, reemplaza la tabla `transacciones` y recrea la vista `movimientos_productos`. La última celda exporta cuatro tablas a `resultados/`.

El módulo `sqlite3` viene con Python. Para ejecutar las consultas se necesita una versión de SQLite compatible con funciones de ventana. El notebook imprime la versión utilizada.

Después de importar el Excel, también puedes abrir la base con un cliente SQLite y ejecutar `sql/consultas.sql`. Este archivo no importa el Excel: consulta la tabla creada por el notebook y recrea la vista de análisis.

## Archivos

| Archivo o carpeta | Contenido |
| --- | --- |
| `retail_sql_analysis.ipynb` | Notebook ejecutado con explicaciones y resultados |
| `sql/consultas.sql` | Consultas del análisis en formato SQL |
| `resultados/resumen_mensual.csv` | Importes, facturas y variación mensual |
| `resultados/ranking_productos_por_pais.csv` | Primeras tres posiciones por país, incluidos empates |
| `resultados/clientes_frecuentes.csv` | Diez clientes con más facturas de venta |
| `resultados/recurrencia_clientes.csv` | Clientes con compras en uno o varios meses |
| `requirements.txt` | Dependencias de Python |

## Límites de interpretación

- El importe neto seleccionado no representa ganancias ni todos los conceptos facturados.
- Las cancelaciones se contabilizan en su fecha de registro; no se vinculan a la venta original.
- Diciembre de 2011 termina el día 9. Su variación mensual se deja sin calcular.
- La recurrencia entre meses no es una tasa de retención: los clientes tienen diferentes tiempos de seguimiento.
- El ranking por frecuencia no equivale a un ranking por importe acumulado o rentabilidad.
- SQLite almacena los precios como `REAL`. Los resultados monetarios se presentan redondeados a dos decimales; el proyecto no es un sistema contable de precisión decimal exacta.

## Verificación

Verificado con Python 3.12.14 y SQLite 3.53.1. Las celdas se ejecutaron en orden en un proceso Python limpio, sin utilizar un kernel de Jupyter. Se comprobaron el total de registros, la conciliación del importe mensual, el ranking con empates, el cliente con más facturas y los conteos de recurrencia. Las consultas del archivo SQL también se ejecutaron contra la base generada.
