/* ============================================================
   RZ Gift Bag  --  03 DELIVERY  v1.1  (WRITES - backup first!)
   Run against: Telecaster1

   DECISIONS APPLIED
     * one bag per CHARACTER CLASS  (bag id chosen from a map table)
     * delivery for NEW CHARACTERS ONLY (trigger on Character insert)

   ORDER
     A. run 01-discover.sql -> learn the class column + smp_insert_item params
     B. fill RZ_GiftBagMap with the class value -> bag code
     C. fix the EXEC block once so it matches your smp_insert_item
     D. test with section 3 on ONE character (logged out)
     E. enable the trigger (section 5)
   ============================================================ */

USE Telecaster1;
GO

/* ------------------------------------------------------------
   1) log table - one row per character, blocks double delivery
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.RZ_GiftLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RZ_GiftLog
    (
        sid       INT           NOT NULL PRIMARY KEY,
        char_name NVARCHAR(64)  NOT NULL,
        class_val INT           NULL,
        gift_code INT           NOT NULL,
        given_at  DATETIME      NOT NULL DEFAULT GETDATE(),
        note      NVARCHAR(200) NULL
    );
    PRINT 'RZ_GiftLog created';
END
ELSE PRINT 'RZ_GiftLog already exists';
GO

/* ------------------------------------------------------------
   2) class -> bag map  (fill from the class values you found)
      class_val = the value stored in Character.class (or job)
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.RZ_GiftBagMap', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RZ_GiftBagMap
    (
        class_val INT          NOT NULL PRIMARY KEY,
        bag_code  INT          NOT NULL,
        label     NVARCHAR(50) NULL
    );
    PRINT 'RZ_GiftBagMap created (empty - fill it!)';
END
ELSE PRINT 'RZ_GiftBagMap already exists';
GO

/* EXAMPLE - fix the numbers.
   RZ_GIFT.bags in the lua file must use the SAME bag codes. */
/*
DELETE FROM dbo.RZ_GiftBagMap;   -- careful: wipes the map
INSERT INTO dbo.RZ_GiftBagMap (class_val, bag_code, label) VALUES
 (1, 97000001, 'Fighter'),
 (2, 97000002, 'Hunter'),
 (3, 97000003, 'Magician'),
 (4, 97000004, 'Summoner');
*/

SELECT * FROM dbo.RZ_GiftBagMap;
GO

/* ------------------------------------------------------------
   3) procedure: deliver the right bag to ONE character
   ------------------------------------------------------------ */
IF OBJECT_ID('dbo.RZ_GiveGiftBag', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RZ_GiveGiftBag;
GO

CREATE PROCEDURE dbo.RZ_GiveGiftBag
    @char_name NVARCHAR(64),
    @force_bag INT = NULL          -- override the map (testing)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sid INT, @cls INT, @bag INT;

    /* change [class] to the real column name if yours differs */
    SELECT @sid = sid, @cls = [class]
    FROM dbo.[Character]
    WHERE name = @char_name AND delete_time IS NULL;

    IF @sid IS NULL
    BEGIN
        PRINT 'character not found: ' + @char_name;
        RETURN 1;
    END

    IF EXISTS (SELECT 1 FROM dbo.RZ_GiftLog WHERE sid = @sid)
    BEGIN
        PRINT 'gift already given to ' + @char_name;
        RETURN 2;
    END

    SET @bag = @force_bag;
    IF @bag IS NULL
        SELECT @bag = bag_code FROM dbo.RZ_GiftBagMap WHERE class_val = @cls;

    IF @bag IS NULL
    BEGIN
        PRINT 'no bag mapped for class ' + ISNULL(CAST(@cls AS NVARCHAR(10)),'NULL')
              + ' (character ' + @char_name + ')';
        RETURN 3;
    END

    /* ---- the server's own insert procedure --------------------
       Parameter names differ between builds - take them from
       01-discover.sql query 6 and fix this block once.
       ---------------------------------------------------------- */
    EXEC dbo.smp_insert_item
         @IN_SID       = @sid,
         @IN_OWNER_ID  = @sid,
         @IN_ACCOUNT_ID = 0,
         @IN_SUMMON_ID = 0,
         @IN_AUCTION_ID = 0,
         @IN_KEEPING_ID = 0,
         @IN_CODE      = @bag,
         @IN_IDX       = 0,
         @IN_FLAG      = 0,
         @IN_CNT       = 1,
         @IN_LEVEL     = 1,
         @IN_ENHANCE   = 0,
         @IN_ENDURANCE = 100,
         @IN_GCODE     = 1,
         @IN_REMAIN_TIME = 0,
         @IN_ELEMENTAL_EFFECT_TYPE = 0,
         @IN_ELEMENTAL_EFFECT_EXPIRE_TIME = NULL,
         @IN_ELEMENTAL_EFFECT_ATTACK_POINT = 0,
         @IN_ELEMENTAL_EFFECT_MAGIC_POINT = 0;

    INSERT INTO dbo.RZ_GiftLog (sid, char_name, class_val, gift_code, note)
    VALUES (@sid, @char_name, @cls, @bag, 'delivered');

    PRINT 'gift ' + CAST(@bag AS NVARCHAR(10)) + ' delivered to ' + @char_name;
    RETURN 0;
END
GO

/* ------------------------------------------------------------
   4) TEST on one character (must be LOGGED OUT)
   ------------------------------------------------------------ */
-- EXEC dbo.RZ_GiveGiftBag @char_name = N'OwnerZahran';                 -- uses the map
-- EXEC dbo.RZ_GiveGiftBag @char_name = N'OwnerZahran', @force_bag = 97000003;  -- force
GO

/* ------------------------------------------------------------
   5) TRIGGER - new characters only
   Enable ONLY after section 4 worked.
   ------------------------------------------------------------ */
/*
IF OBJECT_ID('dbo.trg_RZ_GiftOnCreate','TR') IS NOT NULL
    DROP TRIGGER dbo.trg_RZ_GiftOnCreate;
GO
CREATE TRIGGER dbo.trg_RZ_GiftOnCreate
ON dbo.[Character]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sid INT, @nm NVARCHAR(64);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT sid, name FROM inserted;
    OPEN cur;
    FETCH NEXT FROM cur INTO @sid, @nm;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.RZ_GiveGiftBag @char_name = @nm;
        FETCH NEXT FROM cur INTO @sid, @nm;
    END
    CLOSE cur;
    DEALLOCATE cur;
END
*/
GO

/* ------------------------------------------------------------
   6) BACKFILL - optional: everyone who never got a gift
      (you chose "new characters only", so this is OFF by default)
   ------------------------------------------------------------ */
/*
DECLARE @nm NVARCHAR(64);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT c.name FROM dbo.[Character] c
    WHERE c.delete_time IS NULL
      AND NOT EXISTS (SELECT 1 FROM dbo.RZ_GiftLog g WHERE g.sid = c.sid);
OPEN cur;
FETCH NEXT FROM cur INTO @nm;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.RZ_GiveGiftBag @char_name = @nm;
    FETCH NEXT FROM cur INTO @nm;
END
CLOSE cur; DEALLOCATE cur;
*/
GO

/* ------------------------------------------------------------
   7) state report
   ------------------------------------------------------------ */
SELECT
    (SELECT COUNT(*) FROM dbo.RZ_GiftLog)        AS gifts_given,
    (SELECT COUNT(*) FROM dbo.RZ_GiftBagMap)     AS classes_mapped,
    (SELECT COUNT(*) FROM dbo.RZ_GiftLog WHERE note='delivered') AS delivered;
GO

/* ------------------------------------------------------------
   8) full undo
   ------------------------------------------------------------ */
-- IF OBJECT_ID('dbo.trg_RZ_GiftOnCreate','TR') IS NOT NULL DROP TRIGGER dbo.trg_RZ_GiftOnCreate;
-- DROP PROCEDURE dbo.RZ_GiveGiftBag;
-- DROP TABLE dbo.RZ_GiftBagMap;
-- DROP TABLE dbo.RZ_GiftLog;
GO
