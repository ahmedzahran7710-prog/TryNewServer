# مشروع ضبط القيم والوحوش والدروب — المرجع الكامل

**التاريخ:** 2026-11-10 · **السيرفر:** Rappelz Epic 9.1 (Revolution Team) · **الحالة:** مرحلة مراجعة قبل التنفيذ

> هذا الملف مرجع فني لكل ما يخص **أرقام اللعبة**: الضرر · الوحوش · الأيتمات · الدروب · الريسبون · التلفيل · الترويض · النسب.
> كل معلومة هنا مصدرها مشاركات مجتمع رابلز و/أو الكود والهياكل المسرّبة — **والحكم النهائي دائمًا من سيرفرك نفسه** (انظر §١١).

---

## ١) من أين يقرأ السيرفر البيانات؟ — أهم فكرة في الملف

| المكوّن | المصدر | إيه اللي فيه |
|---|---|---|
| **GameServer** | **قاعدة `Arcadia`** (SQL) | كل الأرقام الثابتة: `MonsterResource` · `ItemResource` · `DropGroupResource` · `MonsterDropTableResource` · `SummonResource` · `SkillResource` · `StringResource` |
| **GameServer** | **`GameServer.opt`** | النسب العامة: `exp_rate` · `item_drop_rate` · `max_level` · `taming_success_rate_2` … |
| **GameServer** | **`Resource/Script/*.ela`** | `monster_respawn.lua` (الكثافة والفواصل) + سكربتات المابات |
| **الخريطة** | **`*.nfs`** | **أماكن الوحوش** (الإحداثيات) — ليست في SQL |
| **العميل** | **`data.00x` → RDB** | نسخة للعرض فقط: `db_item.rdb` · `db_monster.rdb` · `db_creature.rdb` |

### القاعدة الذهبية

> **تعديل قيمة على السيرفر ≠ تعديلها عند اللاعب.**
> لو غيّرت اسم أيتم أو وصفه في SQL، **لازم** تعيد بناء الـRDB في الكلاينت (`db_item.rdb`) وإلا العميل يعرض القديم.
> أما **الأرقام** (هجوم/دفاع/دروب/خبرة) فالسيرفر هو الحكم — الكلاينت لا يحسبها.

---

## ٢) خريطة الجداول التي ستتعامل معها

| الجدول | المقابل في الكلاينت | المحتوى |
|---|---|---|
| `MonsterResource` | `db_monster.rdb` | كل وحش: HP · هجوم · دفاع · خبرة · ترويض · جدول الدروب |
| `ItemResource` | `db_item.rdb` | كل أيتم: النوع · المستوى · القيم · التحسين |
| `DropGroupResource` | `db_dropgroup.rdb` | **مجموعة** دروب متسلسلة (احتمالاتها مجموعها 1) |
| `MonsterDropTableResource` | — (سيرفر فقط) | **جدول دروب** الوحش (id + sub_id) |
| `SummonResource` | `db_creature.rdb` | المخلوقات القابلة للترويض (الألياف) |
| `StringResource` | `db_string.rdb` | الأسماء والأوصاف |
| `SkillResource` | `db_skill.rdb` | المهارات وقيمها |
| `InstanceDungeonMonsterRespawnResource` | — | ريسبون وحوش الإنستانس (إحداثيات مستطيل) |

> ⚠️ الأسماء أعلاه هي المتعارف عليها في مجتمع 6.2–9.4. **تحقق من وجودها عندك أولًا** (§١١، الاستعلام 1).

---

## ٣) حقول الوحش — `MonsterResource`

الهيكل الكامل لـ`db_monster.rdb` مسرّب من السيرفر (نفس أسماء الأعمدة تقريبًا في SQL):

| الحقل | المعنى | ملاحظة |
|---|---|---|
| `id` | معرّف الوحش | |
| `monster_group` | المجموعة | تُستخدم لتعديل كل نسخ الوحش مرة واحدة |
| `monster_type` | النوع | عادي/بوس/نخبة… |
| `level` | المستوى | يؤثر على الخبرة والضرر |
| `race` · `grp` | السلالة/الفصيلة | |
| `hp` · `mp` | الصحة والمانا | |
| `attack_point` | **الهجوم الفيزيائي** | |
| `magic_point` | **الهجوم السحري** | |
| `defence` | **الدفاع الفيزيائي** | |
| `magic_defence` | **الدفاع السحري** | |
| `accuracy` · `avoid` | الدقة/المراوغة | أساس معادلة الإصابة |
| `magic_accuracy` · `magic_avoid` | نسخة سحرية | |
| `attack_speed` · `magic_speed` | السرعة | |
| `attack_range` · `visible_range` · `chase_range` | المدى/الرؤية/المطاردة | |
| `attack_flags` | سلوك الهجوم | أول ضربة/رد فعل… |
| `exp` · `jp` | **الخبرة ونقاط المهارة** | × `game.exp_rate` |
| `exp_2` · `jp_2` | قيم بديلة (نسخة ثانية) | تُستخدم في حالات خاصة |
| `gold_drop_percentage` · `gold_min` · `gold_max` | **الفلوس** | |
| `chaos_drop_percentage` · `chaos_min` · `chaos_max` | **الشاووس (نقاط)** | |
| `drop_table_link_id` | **رقم جدول الدروب** | ← المفتاح لكل الدروبات |
| `taming_id` | رقم المخلوق في `SummonResource` | 0 = غير قابل للترويض |
| `taming_percentage` | **نسبة الترويض** | 1.0 = 100% · 0.01 = ١٪ |
| `taming_exp_mod` | مضاعف خبرة الترويض | |
| `monster_skill_link_id` | مهارات الوحش | |
| `stat_id` | مقاومة/حالة | |
| `walk_speed` · `run_speed` | الحركة | |
| `model` | الموديل | يبدأ بـ`ain_` … |
| `transform_level` | مستوى التحوّل | |

**أهم 6 حقول لأي مراجعة توازن:** `hp` · `attack_point` · `defence` · `exp` · `drop_table_link_id` · `taming_percentage`.

---

## ٤) الضرر — المعادلات

### 4.1 القيم الأساسية للمهاجم (من الكود المصدري)

```
AttackPoint       = strength * 2.8 * fCM + level
BowAttackPoint    = (agility*1.2 + dexterity*2.2) * fCM + level
MagicPoint        = intelligence * 2 * fCM + level
Defence           = vital * 1.6 * fCM + level
MagicDefence      = mental * 2 * fCM + level
Accuracy          = dexterity * 0.5 * fCM + level
Avoid             = agility * 0.5 * fCM + level
MaxHP             = (vital * fCM * 33) + (level * 20)
MaxMP             = (intelligence * fCM * 30) + (level * 20)
AttackSpeed       = agility * 0.1 + 100
CritChance        = luck * 0.2 + 3
```
> `fCM` = مضاعف فئة الشخصية (1 للاعبين). هذه المعادلات **داخل الكود** — لا تُعدّل من SQL.

### 4.2 معادلة الضرر الفعلي (الأشهر في المجتمع)

```
أقل ضرر  = (Attack) − (Defence / 2)
أعلى ضرر = 1.1 × أقل ضرر
المتوسط  = 1.05 × (Attack − Defence/2)
```
- `Attack` = `P.Atk` للضربة العادية، أو **رقم المهارة** في وصفها.
- `Defence` = `P.Def` للفيزيائي و`M.Def` للسحري.

### 4.3 الضرر في PvP

```
الضرر ≈ (المعادلة السابقة) ÷ 6
```
وفي السيرفر يُضبط كذلك بـ:
| الخيار | المعنى |
|---|---|
| `game.pvp_damage_rate_for_player` | مضاعف ضرر اللاعب على اللاعب (مثال 0.08) |
| `game.pvp_damage_rate_for_summon` | مضاعف ضرر المخلوق في PvP (مثال 0.12) |

### 4.4 الضرر عبر الزمن (DOT)
- **لا** يُخفّض بالدفاع، **و**يمكن أن يصيب إصابة حرجة.
- يُخفّض في PvP بنفس معامل الـ1/6.

### 4.5 عشوائية الضرر
`game.ignore_random_damage` — لو = 1 يتجاهل العشوائية (ضرر ثابت). مفيد للاختبار، **خطر على التوازن**.

### 4.6 الضرر من الوحوش إليك
يتحكم فيه:
- `hp/attack_point/defence` في `MonsterResource`
- `game.monster_regen` (قوة شفاء الوحوش)

> **حقيقة يجب قولها:** المعادلة الدقيقة **غير منشورة رسميًا**؛ ما فوق هو الأقرب من الكود وويكي المجتمع. **لا تعِد كتابتها من الصفر** — اضبط القيم فقط.

---

## ٥) الوحوش والريسبون

### 5.1 أين تُوضع الوحوش؟
| المستوى | المكان |
|---|---|
| **الخريطة** | `*.nfs` داخل `map` — الإحداثيات الفعلية |
| **الكثافة والفواصل** | `monster_respawn.lua` (سكربت) |
| **الإنستانس** | جدول `InstanceDungeonMonsterRespawnResource` (مستطيل: left/top/right/bottom + channel) |

**شكل سكربت الريسبون:**
```lua
monster_ID       = {10185002,0,0,0,0,0}
density          = {0.1,0.1,0.1,0.1,0.1,0.1}
interval         = {3000,1000,1200,1500,2000,3000}
Raidmob_density  = {0.37,...}
Raidmob_interval = {10000,10000,12000,15000,20000,30000}
```
- `density` = عدد الوحوش في المنطقة
- `interval` = **زمن إعادة الظهور بالميلي ثانية**

### 5.2 شفاء الوحوش
| الخيار | المعنى |
|---|---|
| `game.monster_regen` | سرعة شفاء الوحوش العادية |
| `game.monster_regen_boss` | سرعة شفاء البوسات |

> ⚠️ لو رفعت `monster_regen` كثيرًا يصبح البوس غير قابل للقتل عمليًا.

---

## ٦) الدروب — النظام الكامل (أهم قسم)

### 6.1 السلسلة

```
MonsterResource.drop_table_link_id
        ↓
MonsterDropTableResource  (id + sub_id)   ← حتى 10 خانات في كل صف
        ↓
   ┌────────────┴─────────────┐
رقم موجب = ItemResource      رقم سالب = DropGroupResource
   (أيتم مباشر)                    ↓ (احتمالات مجموعها = 1)
                              ItemResource أو مجموعات أخرى…
```

### 6.2 القواعد الصارمة

| القاعدة | التفصيل |
|---|---|
| كل صف في `MonsterDropTableResource` = **10 خانات** | `drop_item_id_00 … _09` |
| **الموجب** = أيتم · **السالب** = مجموعة | مثال: `-851100` ترجعك لمجموعة |
| مجموع احتمالات **المجموعة** = **1.000000** | أقل أو أكثر ⇒ دروب مكسور |
| في **جدول الوحش** يحق لكل خانة حتى **1.0** | لا يشترط المجموع = 1 |
| احتمال 0 = لا يُقرأ الأصلًا | احذف الصف بدل تركه صفرًا |
| `drop_min_count` / `max_count` | عدد القطع |
| `drop_min_level` / `max_level` | مستوى الأيتم عند السقوط |

### 6.3 مثال عملي (إضافة دروب لوحش)

```sql
-- 1) أنشئ جدول دروب جديد (id 99600) وفيه أيتم 99700 بنسبة 100%
INSERT INTO Arcadia.dbo.MonsterDropTableResource
(id, sub_id, drop_item_id_00, drop_percentage_00, drop_min_count_00, drop_max_count_00,
 drop_min_level_00, drop_max_level_00)
VALUES (99600, 0, 99700, 1.0000000, 1, 1, 1, 1);

-- 2) اربطه بالوحش
UPDATE Arcadia.dbo.MonsterResource
SET drop_table_link_id = 99600
WHERE id IN (10185002);
```

### 6.4 الفلوس والشاووس
| الحقل | المعنى |
|---|---|
| `gold_drop_percentage` · `gold_min` · `gold_max` | فلوس الوحش |
| `chaos_drop_percentage` · `chaos_min` · `chaos_max` | شاووس |
| `game.gold_drop_base` · `game.gold_drop_percent` | مضاعفات عامة |
| `game.item_drop_rate` · `game.gold_drop_rate` · `game.chaos_drop_rate` | نسب عامة في `.opt` |

---

## ٧) الأيتمات — `ItemResource`

| الحقل | المعنى |
|---|---|
| `id` · `name_id` | المعرّف + اسم في `StringResource` |
| `type` · `group` · `class` · `grade` · `rank` | التصنيف |
| `level` · `use_min_level` · `target_min_level` | المستويات |
| `enhance` | هل يقبل التحسين |
| `socket` | عدد خانات الأحجار |
| `wear_type` · `wear_limit_bits` | من يلبسه (سلالة/فئة) |
| `endurance` · `ethereal_durability` | المتانة |
| `base_type_0..3` | **نوع القيمة** (15 = دفاع فيزيائي · 20 = وزن…) |
| `base_var1_0..3` | **القيمة الابتدائية** |
| `base_var2_0..3` | **الزيادة لكل مستوى** |
| `opt_type_0..3` | 26 = خانة حزام · 96 = زيادة عادية · 98 = نسبة مئوية |
| `opt_var1_x` / `opt_var2_x` | قيم الخيارات |
| `effect_id` | التأثير البصري |
| `skill_id` · `state_id` | مهارة/حالة عند الاستخدام |

> **مهم:** أيتم جديد = RDB جديد في الكلاينت. تعديل الأرقام فقط = السيرفر يكفي.

---

## ٨) التلفيل والخبرة

### 8.1 كيف تُحسب خبرة اللاعب
```
الخبرة المكتسبة = exp الوحش × game.exp_rate × معامل الفريق × (عقوبات المستوى)
```
| الخيار | المعنى |
|---|---|
| `game.exp_rate` | **النسبة العامة** (1 = رسمي · 10 = ×10) |
| `game.party_exp_rate_0 … _6` | نسب الفريق حسب عدد الأعضاء |
| `game.party_exp_penalty_level` | فارق المستوى الذي يبدأ عنده خصم الفريق |
| `game.max_level` | أقصى مستوى (مثال 190/200) |
| `game.killed_exp_percentage` | خبرة القتل في PvP |
| `game.summon_exp_penalty_level` · `game.farm_normal_summon_exp` | خبرة المخلوقات |

### 8.2 جدول الخبرة (مرجع رسمي مختصر)

| المستوى | خبرة المستوى | الإجمالي |
|---|---|---|
| 2 | 6 | 6 |
| 5 | 72 | 125 |
| 10 | 1,332 | 3,362 |
| 20 | 21,000 | 98,344 |
| 30 | 102,564 | 726,092 |
| 50 | — | ~1.6 مليون |
| 100 | — | عشرات الملايين |
| **200** | **~2.5×10¹⁵** | **~8×10¹⁵** |

> **خبرة المخلوقات = 80% من خبرة اللاعب** للوصول لنفس المستوى.

### 8.3 أين الجدول في سيرفرك؟
جدول مستويات/خبرة داخل `Arcadia` (اسمه المرجّح `LevelResource` أو `ExpResource`). **تحقق بالاستعلام 4 في §١١.**

---

## ٩) الترويض والألياف (المخلوقات)

### 9.1 حقول الترويض
| الحقل | المعنى |
|---|---|
| `taming_id` | رقم المخلوق في `SummonResource` — **0 = غير قابل للترويض** |
| `taming_percentage` | **الاحتمال**: `1.0` = 100% · `0.25` = 25% · `0.01` = 1% |
| `taming_exp_mod` | مضاعف خبرة المخلوق |

### 9.2 نِسب الترويض في البيانات الأصلية (مرجع)

| الفئة | النسبة |
|---|---|
| تنين أبيض · طاغية الموت | `0.01` |
| الجني · سيربيروس | `0.015` |
| ملاك · تافاري · إيموس | `0.02` |
| وحيد القرن · سلامندر · صقر | `0.07` |
| أورك · جنية · حورية · ذئب | `0.25` |

### 9.3 تعديل النسبة

```sql
-- كل الترويض × 5
UPDATE Arcadia.dbo.MonsterResource
SET taming_percentage = taming_percentage * 5
WHERE taming_percentage > 0;

-- سقف 100%
UPDATE Arcadia.dbo.MonsterResource
SET taming_percentage = 1.0
WHERE taming_percentage > 1.0;
```

**وفي `.opt`:**
| الخيار | المعنى |
|---|---|
| `game.taming_success_rate_2` | **مضاعف نجاح الترويض** (الأسهل) |
| `game.card_drop_rate` | نسبة سقوط **كروت المخلوقات** |
| `game.summon_exp_penalty_level` | عقوبة خبرة المخلوق حسب فارق المستوى |
| `game.farm_normal_summon_exp` · `game.farm_growth_summon_exp` | خبرة المخلوق في المزرعة |

> ⚠️ **فخ شائع:** لو `taming_id` لا يطابق رقمًا موجودًا في `SummonResource` ⇒ **الترويض يفشل دائمًا** حتى لو النسبة 100%. تحقق بالاستعلام 3.

---

## ١٠) النسب — جدول `GameServer.opt` الكامل

| الخيار | النوع | المعنى |
|---|---|---|
| `game.exp_rate` | F | مضاعف الخبرة |
| `game.item_drop_rate` | F | مضاعف الأيتم |
| `game.gold_drop_rate` | F | مضاعف الفلوس |
| `game.chaos_drop_rate` | F | مضاعف الشاووس |
| `game.party_exp_rate_0..6` | F | نسب الفريق |
| `game.max_level` | N | أقصى مستوى |
| `game.taming_success_rate_2` | F | نجاح الترويض |
| `game.card_drop_rate` | F | كروت الوحوش |
| `game.monster_regen` / `_boss` | F | شفاء الوحوش |
| `game.enhance_chance` · `_min` · `_max` | F | فرص التحسين |
| `game.enhance_fail_type` · `enhance_destroy_level` | I | فشل/تدمير التحسين |
| `game.pvp_damage_rate_for_player` | F | ضرر PvP (لاعب) |
| `game.pvp_damage_rate_for_summon` | F | ضرر PvP (مخلوق) |
| `game.ignore_random_damage` | N | إلغاء عشوائية الضرر |
| `game.no_skill_cooltime` | N | إلغاء التبريد |
| `game.no_collision_check` | N | إلغاء التصادم |
| `game.item_hold_time` | N | مدة بقاء الأيتم على الأرض |
| `game.speed_unit` | N | وحدة الحركة |
| `game.local_flag` | N | لغة/منطقة |

> **بعد أي تعديل:** احفظ `.opt` → اسحبه على `RappelzCompress_v2.exe` → رستارت السيرفر. **بدون `.eop` لا يُقرأ شيء.**
> **الأنواع:** `S` نص · `N` عدد صحيح · `F` عشري · `T` منطقي (0/1).

---

## ١١) مراجعة سيرفرك — استعلامات جاهزة

> شغّلها في SSMS على قاعدة `Arcadia`. كلها **قراءة فقط**.

```sql
-- 1) هل الجداول موجودة؟ (أول استعلام يجب تشغيله)
SELECT TABLE_NAME, (SELECT SUM(p.rows) FROM sys.partitions p
       WHERE p.object_id = t.object_id AND p.index_id IN (0,1)) AS rows
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE='BASE TABLE'
  AND (TABLE_NAME LIKE '%Monster%' OR TABLE_NAME LIKE '%Item%'
    OR TABLE_NAME LIKE '%Drop%' OR TABLE_NAME LIKE '%Summon%'
    OR TABLE_NAME LIKE '%Level%' OR TABLE_NAME LIKE '%Skill%')
ORDER BY TABLE_NAME;
```

```sql
-- 2) توزيع مستويات الوحوش وأرقامها
SELECT level, COUNT(*) AS mobs, AVG(hp) AS avg_hp, AVG(attack_point) AS avg_atk,
       AVG(defence) AS avg_def, AVG(exp) AS avg_exp
FROM dbo.MonsterResource
GROUP BY level ORDER BY level;
```

```sql
-- 3) الترويض: هل taming_id يطابق SummonResource؟
SELECT m.taming_id, COUNT(*) AS mobs,
       MIN(m.taming_percentage) AS min_p, MAX(m.taming_percentage) AS max_p,
       CASE WHEN s.id IS NULL THEN 'BROKEN - no summon' ELSE 'OK' END AS state
FROM dbo.MonsterResource m
LEFT JOIN dbo.SummonResource s ON s.id = m.taming_id
WHERE m.taming_id > 0
GROUP BY m.taming_id, s.id
ORDER BY state, m.taming_id;
```

```sql
-- 4) جدول الخبرة (تحقق من الاسم أولًا)
SELECT TOP 20 * FROM dbo.LevelResource ORDER BY level;
```

```sql
-- 5) وحوش بلا جدول دروب (دروب مكسورة)
SELECT COUNT(*) AS no_drop
FROM dbo.MonsterResource
WHERE drop_table_link_id = 0 OR drop_table_link_id IS NULL;
```

```sql
-- 6) مجموعات دروب مجموعها ≠ 1 (خطأ فادح)
SELECT id,
  (ISNULL(drop_percentage_00,0)+ISNULL(drop_percentage_01,0)+ISNULL(drop_percentage_02,0)+
   ISNULL(drop_percentage_03,0)+ISNULL(drop_percentage_04,0)+ISNULL(drop_percentage_05,0)+
   ISNULL(drop_percentage_06,0)+ISNULL(drop_percentage_07,0)+ISNULL(drop_percentage_08,0)+
   ISNULL(drop_percentage_09,0)) AS total
FROM dbo.DropGroupResource
HAVING ABS((ISNULL(drop_percentage_00,0)+ISNULL(drop_percentage_01,0)+ISNULL(drop_percentage_02,0)+
   ISNULL(drop_percentage_03,0)+ISNULL(drop_percentage_04,0)+ISNULL(drop_percentage_05,0)+
   ISNULL(drop_percentage_06,0)+ISNULL(drop_percentage_07,0)+ISNULL(drop_percentage_08,0)+
   ISNULL(drop_percentage_09,0)) - 1.0) > 0.01;
```

```sql
-- 7) أيتم معيّن: أين يسقط؟
DECLARE @item int = 503001;
SELECT id FROM dbo.DropGroupResource
WHERE drop_item_id_00=@item OR drop_item_id_01=@item OR drop_item_id_02=@item
   OR drop_item_id_03=@item OR drop_item_id_04=@item OR drop_item_id_05=@item
   OR drop_item_id_06=@item OR drop_item_id_07=@item OR drop_item_id_08=@item
   OR drop_item_id_09=@item;
```

**وأيضًا اقرأ من الملفات مباشرة:**
```
Game_bin\GameServer.opt      ← كل النسب (قبل الضغط)
Game_bin\Resource\Script\    ← سكربتات الريسبون
Client\...\data.00x          ← RDB العميل (للعرض فقط)
```

---

## ١٢) مصدر السورس والكلاينت — الروابط

| المصدر | إيه فيه |
|---|---|
| https://www.elitepvpers.com/forum/rappelz-private-server/2364564-release-db_monster-rdb-structure-id-byteorder.html | **هيكل `db_monster.rdb` كامل** (كل الحقول) |
| https://www.elitepvpers.com/forum/rappelz-private-server/2156088-tut-how-customize-drop-table-s.html | شرح نظام الدروب خطوة بخطوة |
| https://www.elitepvpers.com/forum/rappelz-private-server/4225800-how-add-thing-monster.html | مثال إضافة دروب لوحش |
| https://www.elitepvpers.com/forum/rappelz-private-server/5264345-epic-6-2-server-database-client-mismatch-search-rdb-import-tool.html | علاقات جداول الدروب (شرح دقيق) |
| https://www.elitepvpers.com/forum/rappelz-private-server/4645163-info-taming-calculation.html | حساب الترويض |
| https://www.elitepvpers.com/forum/rappelz-private-server/1652448-tutoriel-changement-de-taux-de-tame-fr-us-tutorial-changing-rates-tame-en-us.html | نِسب الترويض الرسمية حسب الفئة |
| https://www.elitepvpers.com/forum/rappelz-private-server/4320593-pvp-server-taming-rates.html | **خيارات النسب في `GameServer.opt`** |
| https://www.elitepvpers.com/forum/rappelz-private-server/4763943-game-base-stats-equations-such.html | **معادلات القيم الأساسية من السورس** |
| https://rappelz.fandom.com/wiki/Damage | معادلة الضرر وPvP وDOT |
| https://rappelz.fandom.com/wiki/Level | **جدول الخبرة الكامل** حتى 200 |
| https://www.elitepvpers.com/forum/rappelz-private-server/2769975-release-rappelz-rdb-tool-tabs.html | **RappelzRDBTool** — تحويل RDB ↔ SQL |
| https://www.elitepvpers.com/forum/rappelz-private-server/2706568-guide-dumping-clients-importing-rdb-data-sql-updating-rdbs-incl-strings.html | دليل استخراج الكلاينت وبناء RDB |
| https://github.com/glandu2/rzu | `rzu` — أدوات glandu2 (RDB/DLL) |

---

## ١٣) خطة المشروع — بالترتيب

| # | الخطوة | الناتج |
|---|---|---|
| 0 | **نسخة احتياطية** (`backup-rz.cmd`) | أمان |
| 1 | تشغيل استعلامات §١١ (1–6) | **صورة كاملة** لوضعك الحالي |
| 2 | قراءة `GameServer.opt` الحالي | معرفة نسبك الفعلية |
| 3 | مقارنة النتائج بالمرجع (§٤–§٩) | قائمة انحرافات |
| 4 | قرار: النسب المطلوبة (خبرة/دروب/ترويض) | أرقام نهائية |
| 5 | التعديل في **بيئة اختبار** أولًا | تأكيد |
| 6 | تطبيق + إعادة ضغط + رستارت | تنفيذ |
| 7 | اختبار في اللعبة (قتل وحش/دروب/ترويض) | تحقق |

---

## ١٤) تحذيرات

1. **لا تعدّل `Arcadia` وأنا غير متأكد من أسماء الأعمدة** — شغّل الاستعلام 1 أولًا.
2. **مجموع نسب `DropGroupResource` = 1** — أي خطأ = دروب صامت (لا يسقط شيء ولا رسالة خطأ).
3. **`taming_id` غير المطابق** = فشل ترويض أبدي.
4. **أيتم جديد** يحتاج RDB في الكلاينت — الأرقام لا.
5. **`max_level` أعلى من دعم الكلاينت** = أعطال عرض.
6. **`ignore_random_damage = 1`** يقصّ العشوائية — للاختبار فقط.
7. **بعد كل تعديل `.opt`: إعادة ضغط إلزامية**.
8. **لا تختبر على شخصية حقيقية** — استخدم حساب اختبار.

---

## ١٥) خلاصة في ٥ أسطر

1. الأرقام في **`Arcadia`**، النسب في **`GameServer.opt`**، الأماكن في **`nfs` + لوا الريسبون**.
2. الضرر = `Attack − Defence/2` فيزيائيًا، ÷6 في PvP.
3. الدروب سلسلة: وحش → جدول → مجموعة (مجموعها 1) → أيتم.
4. الترويض = `taming_id` صحيح + `taming_percentage` + `game.taming_success_rate_2`.
5. **قبل أي تعديل:** شغّل استعلامات §١١ وخذ نسخة احتياطية.
