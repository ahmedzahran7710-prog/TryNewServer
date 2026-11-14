/* ============================================================
   02-bind-check.sql  —  قراءة فقط (READ ONLY)
   الهدف: التأكد أن أيتمات المكافآت لن تُتداول
   (قبل التسليم: السكربت يطلب بتات الربط، وهذا فحص تحقّق)
   ============================================================ */

USE [Telecaster];
GO

/* ضع أكواد المكافآت النهائية هنا */
DECLARE @codes TABLE (id INT PRIMARY KEY);
INSERT INTO @codes (id) VALUES (0);   -- <<< عدّلها

/* 1) هل كل الأكواد موجودة؟ */
SELECT c.id AS requested_code,
       CASE WHEN ir.id IS NULL THEN 'MISSING' ELSE 'OK' END AS exists_check,
       sr.value AS item_name,
       ir.item_use_flag AS current_flag
FROM @codes c
LEFT JOIN dbo.ItemResource ir ON ir.id = c.id
LEFT JOIN dbo.StringResource sr ON sr.code = ir.name_id;
GO

/* 2) هل الأيتم قابل للتداول حاليًا؟ (512 = CANT_TRADE) */
SELECT ir.id, sr.value AS item_name, ir.item_use_flag,
       CASE WHEN ir.item_use_flag & 512 = 512 THEN 'BOUND_OK' ELSE 'TRADABLE_NOW' END AS trade_state,
       CASE WHEN ir.item_use_flag & 8 = 8 THEN 'USABLE' ELSE 'NOT_USABLE' END AS use_state
FROM dbo.ItemResource ir
LEFT JOIN dbo.StringResource sr ON sr.code = ir.name_id
WHERE ir.id IN (SELECT id FROM @codes WHERE id > 0);
GO

/* 3) لو أراد المستخدم نسخًا مربوطة دائمًا (بديل احتياطي):
      يُنشئ نسخة بالاسم نفسه + (Bound) وبنفس الأيقونة والموديل مع
      item_use_flag = الأصلي | 1 | 2 | 512
   لا تشغّل هذا إلا بعد نسخة احتياطية، وهو مُعطّل بالتعليقات
   ------------------------------------------------------------
   INSERT INTO dbo.ItemResource (id, name_id, tooltip_id, type, [group], class,
        wear_type, set_id, set_part_flag, grade, rank, level, enhance, socket,
        status_flag, limit_deva, limit_asura, limit_gaia, job_depth,
        limit_fighter, limit_hunter, limit_magician, limit_summoner,
        use_min_level, use_max_level, target_min_level, target_max_level,
        range, weight, price, huntaholic_point, arena_point, ethereal,
        item_use_flag, script_text)
   SELECT id + 700000, name_id, tooltip_id, type, [group], class,
        wear_type, set_id, set_part_flag, grade, rank, level, enhance, socket,
        status_flag, limit_deva, limit_asura, limit_gaia, job_depth,
        limit_fighter, limit_hunter, limit_magician, limit_summoner,
        use_min_level, use_max_level, target_min_level, target_max_level,
        range, weight, price, huntaholic_point, arena_point, ethereal,
        item_use_flag | 1 | 2 | 512, script_text
   FROM dbo.ItemResource WHERE id IN (SELECT id FROM @codes WHERE id > 0);
   -- ثم انسخ الاسم في StringResource بنفس الـ name_id أو name_id جديد
   ------------------------------------------------------------ */
