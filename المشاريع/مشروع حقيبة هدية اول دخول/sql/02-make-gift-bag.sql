/* ============================================================
   RZ Gift Bag  --  02 MAKE THE BAG  (WRITES - backup first!)
   Run against: Arcadia

   BEFORE RUNNING
     1. backup-rz.cmd
     2. fill every  <<...>>  below
     3. characters must be OFFLINE
     4. recompress nothing here - these are SQL only,
        but the client needs an RDB update to show the new tooltip/flag
   ============================================================ */

USE Arcadia;
GO

/* ------------------------------------------------------------
   STEP 1 - choose the bag item
   Use an existing "box"/"bag" item id. Check with:
     SELECT i.id, s.value, i.type, i.item_use_flag, i.script_text
     FROM dbo.ItemResource i
     LEFT JOIN dbo.StringResource s ON s.code = i.name_id
     WHERE s.value LIKE '%Box%' OR s.value LIKE '%Bag%' OR s.value LIKE '%Package%'
   ------------------------------------------------------------ */
DECLARE @bag_id int = 0;          -- << put the bag item id here

/* ------------------------------------------------------------
   STEP 2 - turn it into a usable gift bag
     item_use_flag = 8 (USE) + 512 (CANT_TRADE) + 2 (CANT_STORAGE)
                     + 1 (CANT_DONATE) = 523
     add 4  (CANT_ENHANCE) -> 527
   script_text must equal the function name inside rz_gift_box.lua
   ------------------------------------------------------------ */
UPDATE dbo.ItemResource
SET item_use_flag = 527,
    script_text   = 'rz_gift_open'
WHERE id = @bag_id;
GO

/* verify */
-- SELECT id, item_use_flag, script_text FROM dbo.ItemResource WHERE id = @bag_id;

/* ------------------------------------------------------------
   STEP 3 - bind the gift contents to the character
   Same flag value on every item you are giving away.
   527 = USE + CANT_TRADE + CANT_STORAGE + CANT_DONATE + CANT_ENHANCE
   (equipment should NOT have USE, so use 519 = 512+4+2+1)

   Fill the list with the ids you found in 01-discover.sql
   ------------------------------------------------------------ */
DECLARE @bind_equip  int = 519;   -- trade/storage/donate/enhance blocked
DECLARE @bind_usable int = 527;   -- same + usable

-- EXAMPLE (replace the list):
/*
UPDATE dbo.ItemResource SET item_use_flag = @bind_equip
WHERE id IN (
  0  -- 150 set armor pieces
  ,0 -- weapons
);
*/

/* ------------------------------------------------------------
   STEP 4 - optional: make the bag itself non-droppable / non-tradeable
   The bag gets 527 above. If your build also uses status_flag for
   no-drop, set it here after checking the current value.
   ------------------------------------------------------------ */
-- UPDATE dbo.ItemResource SET status_flag = status_flag | 0 WHERE id = @bag_id;

/* ------------------------------------------------------------
   STEP 5 - sanity report: what did we change?
   ------------------------------------------------------------ */
SELECT i.id, s.value AS name, i.item_use_flag, i.script_text
FROM dbo.ItemResource i
LEFT JOIN dbo.StringResource s ON s.code = i.name_id
WHERE i.script_text = 'rz_gift_open' OR i.id = @bag_id;
GO

/* ============================================================
   NOTES
   - item_use_flag is read by the SERVER. The CLIENT shows the
     "cannot trade" text from its own db_item.rdb, so players may
     still see an old tooltip until you rebuild the client RDB.
   - Do not set FLAG_USE (8) on equipment - it would try to "use" it.
   ============================================================ */
