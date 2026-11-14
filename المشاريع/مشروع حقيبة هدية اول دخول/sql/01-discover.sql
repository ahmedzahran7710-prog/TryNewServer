/* ============================================================
   RZ Gift Bag  --  01 DISCOVER  (READ ONLY)
   Run against: Arcadia
   Purpose: find the item IDs you need and confirm the mechanism
   ============================================================ */

USE Arcadia;
GO

/* ---- 1) does ItemResource have the columns we need? ---- */
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ItemResource'
  AND COLUMN_NAME IN ('id','name_id','item_use_flag','status_flag','script_text',
                      'type','group','class','wear_type','level','use_min_level','set_id')
ORDER BY COLUMN_NAME;
GO

/* ---- 2) find items by NAME ---- change the word after LIKE */
SELECT TOP 50
       i.id, s.value AS name, i.type, i.[group], i.class, i.level,
       i.item_use_flag, i.script_text
FROM dbo.ItemResource i
LEFT JOIN dbo.StringResource s ON s.code = i.name_id
WHERE s.value LIKE N'%Anais%'
ORDER BY i.id;
GO

/* ---- 2b) the four searches you actually need ---- */
-- anais   : '%Anais%'
-- exp     : '%EXP%' or '%Experience%'
-- energy  : '%Energy%'
-- stabil  : '%Stabil%' or '%Vigor%' or '%Activity%'
-- 150 set : '%150%'
GO

/* ---- 3) level-150 equipment, grouped so you can see the whole set ---- */
SELECT i.set_id, i.[class], i.wear_type, COUNT(*) AS parts
FROM dbo.ItemResource i
WHERE i.level = 150 AND i.type = 1          -- type 1 = equipment in most builds
GROUP BY i.set_id, i.[class], i.wear_type
ORDER BY i.set_id, i.[class];
GO

/* ---- 4) list a set in full (change set_id) ---- */
DECLARE @set int = 0;    -- << change me
SELECT i.id, s.value AS name, i.wear_type, i.[class], i.level, i.rank, i.set_part_flag
FROM dbo.ItemResource i
LEFT JOIN dbo.StringResource s ON s.code = i.name_id
WHERE i.set_id = @set
ORDER BY i.wear_type;
GO

/* ---- 5) how are the items you want currently flagged? ----
   item_use_flag bits we care about:
       1  CANT_DONATE
       2  CANT_STORAGE
       4  CANT_ENHANCE
       8  USE
      16  CARD
      32  SOCKET
      64  JOIN
     128  TARGET_USE
     256  WARP
     512  CANT_TRADE
   "character bound" = CANT_TRADE + CANT_SELL + CANT_STORAGE + CANT_DONATE
*/
DECLARE @code int = 0;   -- << put one item id here
SELECT id, item_use_flag, status_flag, script_text
FROM dbo.ItemResource WHERE id = @code;
GO

/* ---- 6) the server's own item-insert procedure (signature we must match) ---- */
SELECT p.name AS proc,
       pa.name AS param,
       TYPE_NAME(pa.user_type_id) AS type,
       pa.is_output
FROM sys.procedures p
JOIN sys.parameters pa ON pa.object_id = p.object_id
WHERE p.name LIKE '%insert_item%'
ORDER BY p.name, pa.parameter_id;
GO

/* ---- 7) does the Item table look the way we expect? ---- */
SELECT TOP 5 * FROM Telecaster1.dbo.Item;
GO

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM Telecaster1.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Item'
ORDER BY ORDINAL_POSITION;
GO


/* ---- 9) character class / job columns (needed by the delivery trigger) ---- */
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM Telecaster1.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Character'
ORDER BY ORDINAL_POSITION;
GO

/* ---- 9b) which class values actually exist in your world ---- */
SELECT [class] AS class_val, COUNT(*) AS chars
FROM Telecaster1.dbo.[Character]
WHERE delete_time IS NULL
GROUP BY [class] ORDER BY [class];
GO

/* ---- 10) level-150 equipment split by class limits ---- */
SELECT
    SUM(CASE WHEN limit_fighter  = 1 THEN 1 ELSE 0 END) AS fighter_items,
    SUM(CASE WHEN limit_hunter   = 1 THEN 1 ELSE 0 END) AS hunter_items,
    SUM(CASE WHEN limit_magician = 1 THEN 1 ELSE 0 END) AS magician_items,
    SUM(CASE WHEN limit_summoner = 1 THEN 1 ELSE 0 END) AS summoner_items,
    SUM(CASE WHEN limit_fighter=0 AND limit_hunter=0
              AND limit_magician=0 AND limit_summoner=0 THEN 1 ELSE 0 END) AS all_classes
FROM dbo.ItemResource
WHERE level = 150;
GO

/* ---- 10b) level-150 list per class (pick your set ids from here) ---- */
SELECT i.[class], i.limit_fighter, i.limit_hunter, i.limit_magician, i.limit_summoner,
       i.wear_type, i.set_id, i.id, s.value AS name
FROM dbo.ItemResource i
LEFT JOIN dbo.StringResource s ON s.code = i.name_id
WHERE i.level = 150
ORDER BY i.[class], i.wear_type, i.id;
GO

/* ---- 11) name search that also shows the class flags ---- */
DECLARE @w NVARCHAR(40) = N'%Anais%';   -- << change me
SELECT i.id, s.value AS name, i.level, i.[class],
       i.limit_fighter, i.limit_hunter, i.limit_magician, i.limit_summoner,
       i.item_use_flag
FROM dbo.ItemResource i
LEFT JOIN dbo.StringResource s ON s.code = i.name_id
WHERE s.value LIKE @w
ORDER BY i.id;
GO

/* ---- 8) what a normal starter character already owns (reference row) ---- */
-- SELECT TOP 30 * FROM Telecaster1.dbo.Item
-- WHERE owner_id = (SELECT sid FROM Telecaster1.dbo.Character WHERE name = 'OwnerZahran');
GO
