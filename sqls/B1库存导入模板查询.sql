SELECT 
-- select top 100 
CASE WHEN T0.[BatchNum] IS NULL THEN T0.[ItemCode] ELSE '' END [ItemCode],
CASE WHEN T0.[BatchNum] IS NULL THEN T1.ItemName ELSE '' END [ItemName],
CASE WHEN T0.[BatchNum] IS NOT NULL THEN  '' ELSE
 CASE WHEN T1.ManBtchNum = 'Y' THEN 'YES' ELSE '' END 
END [ManBtchNum],
CASE WHEN T0.[BatchNum] IS NULL THEN CAST(T0.[OnHand] as nvarchar) ELSE '' END [OnHand],
CASE WHEN T0.[BatchNum] IS NULL THEN T1.InvntryUom ELSE '' END [InvntryUom],
CASE WHEN T0.[BatchNum] IS NULL THEN T0.[WhsCode] ELSE '' END [WhsCode],
CASE WHEN T0.[BatchNum] IS NULL THEN '0' ELSE '' END  [Price],
CASE WHEN T0.[BatchNum] IS NULL THEN 'CNY' ELSE '' END  [Currency],
CASE WHEN T0.[BatchNum] IS NULL THEN '' ELSE T0.[BatchNum] END  [BatchNum],
CASE WHEN T0.[BatchNum] IS NULL THEN '' ELSE CAST(T0.[Quantity] as nvarchar) END  [Quantity]
FROM (
SELECT T0.[ItemCode], T0.[WhsCode], T0.[OnHand],NULL [BatchNum],NULL [Quantity] 
FROM OITW T0
WHERE T0.[OnHand] > 0
UNION ALL
SELECT T0.[ItemCode], T0.[WhsCode], NULL [OnHand], T0.[BatchNum],SUM(T0.[Quantity]) [Quantity]
FROM OIBT T0
WHERE T0.[Quantity] > 0
GROUP BY T0.[ItemCode], T0.[WhsCode], T0.[BatchNum]
) T0 INNER JOIN OITM T1 ON T0.ItemCode = T1.ItemCode
ORDER BY T0.ItemCode, T0.WhsCode, T0.BatchNum