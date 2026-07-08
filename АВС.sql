-- 1. Считаем чистую выручку и количество по каждому товару (отбрасываем возвраты)
WITH ProductSales AS (
    SELECT 
        "StockCode",
        "Description",
        SUM("Quantity" * "UnitPrice") AS TotalRevenue,
        SUM("Quantity") AS TotalQuantity
    FROM online_retail
    WHERE "Quantity" > 0 
      AND "UnitPrice" > 0 
      AND "InvoiceNo" NOT LIKE 'C%' -- Убираем возвраты (Credit notes)
    GROUP BY "StockCode", "Description"
),

-- 2. Считаем процент выручки от общего объема для каждого товара
RevenueShare AS (
    SELECT 
        "StockCode",
        "Description",
        TotalRevenue,
        TotalQuantity,
        (TotalRevenue / SUM(TotalRevenue) OVER()) * 100 AS RevenuePercent
    FROM ProductSales
),

-- 3. Считаем нарастающий итог (Cumulative Percent) для правила Парето
CumulativeShare AS (
    SELECT 
        "StockCode",
        "Description",
        TotalRevenue,
        TotalQuantity,
        RevenuePercent,
        SUM(RevenuePercent) OVER (
            ORDER BY TotalRevenue DESC 
            ROWS UNBOUNDED PRECEDING
        ) AS CumulativePercent
    FROM RevenueShare
)

-- 4. Присваиваем ABC-категории
SELECT 
    "StockCode",
    "Description",
    ROUND(TotalRevenue, 2) AS TotalRevenue,
    TotalQuantity,
    ROUND(RevenuePercent, 2) AS RevenuePercent,
    ROUND(CumulativePercent, 2) AS CumulativePercent,
    CASE 
        WHEN CumulativePercent <= 80 THEN 'A (Локомотив)'
        WHEN CumulativePercent <= 95 THEN 'B (Середняк)'
        ELSE 'C (Аутсайдер)'
    END AS ABC_Category
FROM CumulativeShare
ORDER BY TotalRevenue DESC;