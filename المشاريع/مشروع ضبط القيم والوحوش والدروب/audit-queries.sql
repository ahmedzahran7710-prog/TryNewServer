/* ============================================================
   RZ Balance Audit - read-only queries
   Run in SSMS against database: Arcadia
   Each block is independent. Select the block and press F5.
   ============================================================ */

USE Arcadia;
GO

/* ---- 1) which resource tables exist and how big are they ---- */
SELECT
    t.TABLE_NAME,
    (SELECT SUM(p.rows) FROM sys.partitions p
     WHERE p.object_id = t.TABLE_SCHEMA + '.' + t.TABLE_NAME AND p.index_id IN (0,1)) AS approx_rows
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND (t.TABLE_NAME LIKE '%Monster%' OR t.TABLE_NAME LIKE '%Item%'
    OR t.TABLE_NAME LIKE '%Drop%'   OR t.TABLE_NAME LIKE '%Summon%'
    OR t.TABLE_NAME LIKE '%Level%'  OR t.TABLE_NAME LIKE '%Skill%'
    OR t.TABLE_NAME LIKE '%Creature%')
ORDER BY t.TABLE_NAME;
GO

/* ---- 1b) simpler row counts (works on any SQL version) ---- */
SELECT 'MonsterResource' AS tbl, COUNT(*) AS rows FROM dbo.MonsterResource
UNION ALL SELECT 'ItemResource', COUNT(*) FROM dbo.ItemResource
UNION ALL SELECT 'DropGroupResource', COUNT(*) FROM dbo.DropGroupResource
UNION ALL SELECT 'MonsterDropTableResource', COUNT(*) FROM dbo.MonsterDropTableResource
UNION ALL SELECT 'SummonResource', COUNT(*) FROM dbo.SummonResource
UNION ALL SELECT 'StringResource', COUNT(*) FROM dbo.StringResource;
GO

/* ---- 2) monster balance by level ---- */
SELECT level,
       COUNT(*)                AS mobs,
       AVG(CAST(hp AS BIGINT)) AS avg_hp,
       AVG(attack_point)       AS avg_atk,
       AVG(defence)            AS avg_def,
       AVG(exp)                AS avg_exp,
       AVG(jp)                 AS avg_jp
FROM dbo.MonsterResource
GROUP BY level
ORDER BY level;
GO

/* ---- 2b) bosses / high level sample ---- */
SELECT TOP 30 id, name_id, level, hp, attack_point, defence, exp, drop_table_link_id
FROM dbo.MonsterResource
ORDER BY hp DESC;
GO

/* ---- 3) taming integrity ---- */
SELECT m.taming_id,
       COUNT(*)                AS mobs,
       MIN(m.taming_percentage) AS min_pct,
       MAX(m.taming_percentage) AS max_pct,
       CASE WHEN s.id IS NULL THEN 'BROKEN - no summon' ELSE 'OK' END AS state
FROM dbo.MonsterResource m
LEFT JOIN dbo.SummonResource s ON s.id = m.taming_id
WHERE m.taming_id > 0
GROUP BY m.taming_id, s.id
ORDER BY state, m.taming_id;
GO

/* ---- 3b) taming percentage distribution ---- */
SELECT taming_percentage, COUNT(*) AS mobs
FROM dbo.MonsterResource
WHERE taming_percentage > 0
GROUP BY taming_percentage
ORDER BY taming_percentage;
GO

/* ---- 4) level / exp table (name may differ - check 1 first) ---- */
-- SELECT TOP 25 * FROM dbo.LevelResource ORDER BY level;
GO

/* ---- 5) monsters with no drop table ---- */
SELECT COUNT(*) AS mobs_without_drop
FROM dbo.MonsterResource
WHERE drop_table_link_id = 0 OR drop_table_link_id IS NULL;
GO

/* ---- 6) drop groups whose percentages do not sum to 1 ---- */
SELECT id,
       ISNULL(drop_percentage_00,0)+ISNULL(drop_percentage_01,0)+
       ISNULL(drop_percentage_02,0)+ISNULL(drop_percentage_03,0)+
       ISNULL(drop_percentage_04,0)+ISNULL(drop_percentage_05,0)+
       ISNULL(drop_percentage_06,0)+ISNULL(drop_percentage_07,0)+
       ISNULL(drop_percentage_08,0)+ISNULL(drop_percentage_09,0) AS total
FROM dbo.DropGroupResource
WHERE ABS(
       ISNULL(drop_percentage_00,0)+ISNULL(drop_percentage_01,0)+
       ISNULL(drop_percentage_02,0)+ISNULL(drop_percentage_03,0)+
       ISNULL(drop_percentage_04,0)+ISNULL(drop_percentage_05,0)+
       ISNULL(drop_percentage_06,0)+ISNULL(drop_percentage_07,0)+
       ISNULL(drop_percentage_08,0)+ISNULL(drop_percentage_09,0) - 1.0) > 0.01;
GO

/* ---- 6b) sanity: are drop tables linked to real monsters ---- */
SELECT COUNT(*) AS orphan_drop_tables
FROM dbo.MonsterDropTableResource d
WHERE NOT EXISTS (SELECT 1 FROM dbo.MonsterResource m WHERE m.drop_table_link_id = d.id);
GO

/* ---- 7) where does an item drop from ---- */
DECLARE @item int = 503001;   -- << change me
SELECT 'DropGroup' AS src, id FROM dbo.DropGroupResource
WHERE drop_item_id_00=@item OR drop_item_id_01=@item OR drop_item_id_02=@item
   OR drop_item_id_03=@item OR drop_item_id_04=@item OR drop_item_id_05=@item
   OR drop_item_id_06=@item OR drop_item_id_07=@item OR drop_item_id_08=@item
   OR drop_item_id_09=@item
UNION ALL
SELECT 'DropTable', id FROM dbo.MonsterDropTableResource
WHERE drop_item_id_00=@item OR drop_item_id_01=@item OR drop_item_id_02=@item
   OR drop_item_id_03=@item OR drop_item_id_04=@item OR drop_item_id_05=@item
   OR drop_item_id_06=@item OR drop_item_id_07=@item OR drop_item_id_08=@item
   OR drop_item_id_09=@item;
GO

/* ---- 8) which monsters use a given drop table ---- */
-- SELECT id, name_id, level FROM dbo.MonsterResource WHERE drop_table_link_id = 99600;
GO

/* ---- 9) player levels currently on the server (sanity vs max_level) ---- */
USE Telecaster1;
GO
SELECT TOP 10 lv, COUNT(*) AS chars
FROM dbo.Character
WHERE delete_time IS NULL
GROUP BY lv ORDER BY lv DESC;
GO
