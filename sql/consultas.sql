-- Ejecutar después de importar el Excel con el notebook.
-- Dialecto: SQLite. La vista se recrea; la tabla original se conserva.

-- Consulta 1
SELECT
    COUNT(*) AS Registros,
    COUNT(DISTINCT InvoiceNo) AS Facturas_distintas,
    COUNT(*) - COUNT(Description) AS Sin_descripcion,
    COUNT(*) - COUNT(CustomerID) AS Sin_cliente,
    MIN(InvoiceDate) AS Primera_fecha,
    MAX(InvoiceDate) AS Ultima_fecha
FROM transacciones;

-- Consulta 2
DROP VIEW IF EXISTS movimientos_productos;

CREATE VIEW IF NOT EXISTS movimientos_productos AS
SELECT
    UPPER(TRIM(InvoiceNo)) AS Factura,
    UPPER(TRIM(StockCode)) AS Producto,
    Description AS Descripcion,
    Quantity AS Cantidad,
    InvoiceDate AS Fecha,
    UnitPrice AS Precio_unitario,
    CustomerID AS Cliente,
    Country AS Pais,
    Quantity * UnitPrice AS Importe,
    CASE
        WHEN UPPER(TRIM(InvoiceNo)) LIKE 'C%' THEN 'Cancelación'
        WHEN Quantity < 0 THEN 'Otro movimiento negativo'
        ELSE 'Venta positiva'
    END AS Tipo_movimiento
FROM transacciones
WHERE UnitPrice > 0
    AND Quantity <> 0
    AND UPPER(TRIM(StockCode)) NOT IN (
        'AMAZONFEE', 'B', 'BANK CHARGES', 'C2', 'CRUK',
        'D', 'DOT', 'M', 'POST', 'S'
    )
    AND SUBSTR(UPPER(TRIM(StockCode)), 1, 5) <> 'GIFT_';

-- Consulta 3
SELECT
    (SELECT COUNT(*) FROM transacciones) AS Registros_originales,
    COUNT(*) AS Movimientos_seleccionados,
    (SELECT COUNT(*) FROM transacciones) - COUNT(*) AS Registros_excluidos,
    COUNT(*) - COUNT(Cliente) AS Registros_sin_cliente,
    ROUND(SUM(Importe), 2) AS Importe_neto_GBP
FROM movimientos_productos;

-- Consulta 4
SELECT
    Tipo_movimiento,
    COUNT(*) AS Registros,
    SUM(Cantidad) AS Unidades,
    ROUND(SUM(Importe), 2) AS Importe_GBP
FROM movimientos_productos
GROUP BY Tipo_movimiento
ORDER BY Importe_GBP DESC;

-- Consulta 5
WITH resumen_mensual AS (
    SELECT
        STRFTIME('%Y-%m', Fecha) AS Mes,
        COUNT(DISTINCT CASE
            WHEN Tipo_movimiento = 'Venta positiva' THEN Factura
        END) AS Facturas_venta,
        SUM(CASE
            WHEN Tipo_movimiento = 'Venta positiva' THEN Importe
            ELSE 0
        END) AS Ventas_positivas,
        SUM(CASE
            WHEN Tipo_movimiento = 'Cancelación' THEN Importe
            ELSE 0
        END) AS Cancelaciones,
        SUM(Importe) AS Importe_neto
    FROM movimientos_productos
    GROUP BY STRFTIME('%Y-%m', Fecha)
),
comparacion_mensual AS (
    SELECT
        *,
        LAG(Importe_neto) OVER (ORDER BY Mes) AS Neto_mes_anterior
    FROM resumen_mensual
)
SELECT
    Mes,
    Facturas_venta,
    ROUND(Ventas_positivas, 2) AS Ventas_positivas_GBP,
    ROUND(Cancelaciones, 2) AS Cancelaciones_GBP,
    ROUND(Importe_neto, 2) AS Importe_neto_GBP,
    CASE
        WHEN Mes = '2011-12' THEN NULL
        ELSE ROUND(
            100.0 * (Importe_neto - Neto_mes_anterior)
            / NULLIF(Neto_mes_anterior, 0),
            2
        )
    END AS Variacion_neta_pct,
    CASE
        WHEN Mes = '2011-12' THEN 'Parcial: hasta el día 9'
        ELSE 'Mes completo dentro del período'
    END AS Cobertura
FROM comparacion_mensual
ORDER BY Mes;

-- Consulta 6
WITH productos_por_pais AS (
    SELECT
        Pais,
        Producto,
        SUM(Cantidad) AS Unidades_netas,
        SUM(Importe) AS Importe_neto_producto
    FROM movimientos_productos
    GROUP BY Pais, Producto
),
totales_por_pais AS (
    SELECT
        Pais,
        SUM(Importe) AS Importe_neto_pais
    FROM movimientos_productos
    GROUP BY Pais
),
ranking AS (
    SELECT
        Pais,
        Producto,
        Unidades_netas,
        Importe_neto_producto,
        DENSE_RANK() OVER (
            PARTITION BY Pais
            ORDER BY ROUND(Importe_neto_producto, 2) DESC
        ) AS Posicion
    FROM productos_por_pais
    WHERE Importe_neto_producto > 0
)
SELECT
    r.Pais,
    r.Posicion,
    r.Producto,
    r.Unidades_netas,
    ROUND(r.Importe_neto_producto, 2) AS Importe_neto_GBP,
    ROUND(
        100.0 * r.Importe_neto_producto / t.Importe_neto_pais,
        2
    ) AS Participacion_pais_pct
FROM ranking AS r
JOIN totales_por_pais AS t
    ON r.Pais = t.Pais
WHERE r.Posicion <= 3
    AND t.Importe_neto_pais > 0
ORDER BY r.Pais, r.Posicion, r.Producto;

-- Consulta 7
SELECT
    Cliente,
    COUNT(DISTINCT CASE
        WHEN Tipo_movimiento = 'Venta positiva' THEN Factura
    END) AS Facturas_venta,
    COUNT(DISTINCT CASE
        WHEN Tipo_movimiento = 'Venta positiva'
        THEN STRFTIME('%Y-%m', Fecha)
    END) AS Meses_con_compras,
    ROUND(SUM(CASE
        WHEN Tipo_movimiento = 'Venta positiva' THEN Importe
        ELSE 0
    END), 2) AS Ventas_positivas_GBP,
    ROUND(SUM(CASE
        WHEN Tipo_movimiento = 'Cancelación' THEN Importe
        ELSE 0
    END), 2) AS Cancelaciones_GBP,
    ROUND(SUM(Importe), 2) AS Importe_neto_GBP
FROM movimientos_productos
WHERE Cliente IS NOT NULL
GROUP BY Cliente
HAVING COUNT(DISTINCT CASE
    WHEN Tipo_movimiento = 'Venta positiva' THEN Factura
END) > 0
ORDER BY Facturas_venta DESC, Importe_neto_GBP DESC, Cliente
LIMIT 10;

-- Consulta 8
WITH actividad_clientes AS (
    SELECT
        Cliente,
        COUNT(DISTINCT STRFTIME('%Y-%m', Fecha)) AS Meses_con_compras
    FROM movimientos_productos
    WHERE Cliente IS NOT NULL
        AND Tipo_movimiento = 'Venta positiva'
    GROUP BY Cliente
),
grupos AS (
    SELECT
        CASE
            WHEN Meses_con_compras = 1 THEN 'Un solo mes'
            ELSE 'Dos o más meses'
        END AS Frecuencia,
        COUNT(*) AS Clientes
    FROM actividad_clientes
    GROUP BY CASE
        WHEN Meses_con_compras = 1 THEN 'Un solo mes'
        ELSE 'Dos o más meses'
    END
)
SELECT
    Frecuencia,
    Clientes,
    ROUND(
        100.0 * Clientes / SUM(Clientes) OVER (),
        2
    ) AS Participacion_pct
FROM grupos
ORDER BY Clientes DESC;
