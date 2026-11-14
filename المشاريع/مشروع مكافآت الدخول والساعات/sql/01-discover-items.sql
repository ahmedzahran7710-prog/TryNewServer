/* ============================================================
   مشروع مكافآت الدخول والساعات
   01-discover-items.sql   —   قراءة فقط / READ ONLY
   الغرض: إيجاد أكواد الأيتمات التي سنستخدمها في المكافآت
          + التأكد من صلاحيتها للربط (bind) بلا كسر شيء
   التشغيل: SSMS على قاعدة  Telecaster
   ============================================================ */

USE [Telecaster];
GO

/* ------------------------------------------------------------
   1) بحث عام بالكلمات المفتاحية
      عدّل الكلمة بين %% لو أردت
   ------------------------------------------------------------ */
SELECT TOP 200
      ir.id                AS item_id
    , sr.value             AS item_name
    , ir.type              AS item_type
    , ir.item_use_flag     AS use_flag
    , ir.price             AS price
    , ir.use_min_level     AS min_lv
    , ir.use_max_level     AS max_lv
    , ir.weight            AS weight
FROM dbo.ItemResource ir
LEFT JOIN dbo.StringResource sr
       ON sr.code = ir.name_id
WHERE sr.value LIKE N'%repair%'
   OR sr.value LIKE N'%Repair%'
   OR sr.value LIKE N'%إصلاح%'
   OR sr.value LIKE N'%potion%'
   OR sr.value LIKE N'%Potion%'
   OR sr.value LIKE N'%scroll%'
   OR sr.value LIKE N'%Scroll%'
   OR sr.value LIKE N'%EXP%'
   OR sr.value LIKE N'%experience%'
ORDER BY ir.type, ir.id;
GO

/* ------------------------------------------------------------
   2) وصف أنواع الأيتمات الموجودة (تعرف منها نوع الـconsumable)
   ------------------------------------------------------------ */
SELECT ir.type, COUNT(*) AS cnt
FROM dbo.ItemResource ir
GROUP BY ir.type
ORDER BY cnt DESC;
GO

/* ------------------------------------------------------------
   3) الأيتمات الرخيصة القابلة للاستخدام (مرشّحو المكافآت)
      price <= 50000 و لها use flag من نوع "استخدام"
   ------------------------------------------------------------ */
SELECT TOP 300
      ir.id, sr.value AS item_name, ir.type, ir.item_use_flag,
      ir.price, ir.use_min_level
FROM dbo.ItemResource ir
LEFT JOIN dbo.StringResource sr ON sr.code = ir.name_id
WHERE ir.item_use_flag & 8 = 8          -- bit 8 = USE
  AND ir.price <= 50000
ORDER BY ir.price ASC, ir.id;
GO

/* ------------------------------------------------------------
   4) فحص بتات أي أيتم بالتفصيل
      ضع الأكواد بدل 1,2,3
   ------------------------------------------------------------ */
SELECT
      ir.id, sr.value AS item_name, ir.item_use_flag AS flag,
      CASE WHEN ir.item_use_flag & 1   = 1   THEN 'CANT_DONATE '  ELSE '' END +
      CASE WHEN ir.item_use_flag & 2   = 2   THEN 'CANT_STORAGE ' ELSE '' END +
      CASE WHEN ir.item_use_flag & 4   = 4   THEN 'CANT_ENHANCE ' ELSE '' END +
      CASE WHEN ir.item_use_flag & 8   = 8   THEN 'USE '          ELSE '' END +
      CASE WHEN ir.item_use_flag & 128 = 128 THEN 'TARGET_USE '   ELSE '' END +
      CASE WHEN ir.item_use_flag & 256 = 256 THEN 'WARP '         ELSE '' END +
      CASE WHEN ir.item_use_flag & 512 = 512 THEN 'CANT_TRADE '   ELSE '' END
      AS decoded_flags
FROM dbo.ItemResource ir
LEFT JOIN dbo.StringResource sr ON sr.code = ir.name_id
WHERE ir.id IN (1, 2, 3);   -- <<< ضع أكوادك هنا
GO

/* ------------------------------------------------------------
   5) هل الأيتم اختصارًا مرتبط بمهمة؟ (لا نستخدمه كمكافأة)
      أيتم له script_text غير فارغ أو أعلى من سعر معقول
   ------------------------------------------------------------ */
SELECT ir.id, sr.value AS item_name, ir.script_text, ir.price
FROM dbo.ItemResource ir
LEFT JOIN dbo.StringResource sr ON sr.code = ir.name_id
WHERE ir.script_text IS NOT NULL AND ir.script_text <> ''
ORDER BY ir.id;
GO

/* ------------------------------------------------------------
   6) أرخص 3 مرشحين لكل نوع استخدام (تختار منهم)
   ------------------------------------------------------------ */
;WITH ranked AS (
  SELECT ir.id, sr.value AS item_name, ir.type, ir.price, ir.item_use_flag,
         ROW_NUMBER() OVER (PARTITION BY ir.type ORDER BY ir.price ASC, ir.id) AS rn
  FROM dbo.ItemResource ir
  LEFT JOIN dbo.StringResource sr ON sr.code = ir.name_id
  WHERE ir.item_use_flag & 8 = 8 AND ir.price > 0
)
SELECT * FROM ranked WHERE rn <= 3 ORDER BY type, rn;
GO

/* ------------------------------------------------------------
   7) تأكيد أن resolve الاسم يعمل (بحث باسم عربي/إنجليزي معيّن)
   ------------------------------------------------------------ */
SELECT TOP 50 ir.id, sr.value AS item_name, ir.type, ir.item_use_flag, ir.price
FROM dbo.ItemResource ir
JOIN dbo.StringResource sr ON sr.code = ir.name_id
WHERE sr.value LIKE N'%نسبة%' OR sr.value LIKE N'%خبرة%' OR ir.id BETWEEN 9000 AND 9200
ORDER BY ir.id;
GO

/* ============================================================
   بعد الحصول على الأكواد:
   1) ضعها في lua/rz_rewards.lua  ->  M.items
   2) شغّل 02-bind-check.sql  للتأكد أن الربط مقبول
   ============================================================ */
