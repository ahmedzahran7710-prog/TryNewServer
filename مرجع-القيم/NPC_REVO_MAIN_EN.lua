------------------بسم الله الرحمن الرحيم---------------------
----------------------Smart Team--------------------------
----------------------Black Eye---------------------------
----------------------Revolution Server---------------------------
function get_module_name()
    return "DarkxEvil_BlackEye_EM"
end
  

	function NPC_DarkxEvil_BlackEye_contact_EN()
	dlg_title( "Revolution Server")
	dlg_text( "welcome to Revolution Server" )
	--dlg_menu( "قسم الأسحلة والدورع", "DarkWeaponsandShields()")
	dlg_menu( "<#CCFFCC>Main Consumables", "DarkxEvilAccessories_EN()")
	dlg_menu( "<#CCFFCC>Master Class Helmets", "open_market( 'REVO_BY_RAKAN_0002' )")
	dlg_menu( "<#CCFFCC>Decorative Section", "DarkxEvil_Zain_EN()" )
	dlg_menu( "<#CCFFCC>Stones Section", "Dark_ston_EN()" )
	dlg_menu( "<#CCFFCC>Main Pets Section", "DarkxEvll_pet_5_EN()" )
	

	dlg_menu( "End Chat", "")
    dlg_show()
	end
	
	function Amaady_Converter()
	dlg_title( "Revolution Server" )	
    dlg_text( "!!...مرحبا بك في تاجر سيرفر العين السوداء اختار من تريد")
	dlg_menu( "قسم تبديل نقاط العمل", "Amaady_JP_Converter()" )
	dlg_menu( "عودة الي السابق", "NPC_DarkxEvil_BlackEye_contact_EN()")
	dlg_menu( "End Chat", "")
	dlg_show()
	end
	function Dark_ston_EN()
    dlg_title( "Revolution Server")
    dlg_text( "welcome to Revolution Server" )
   -- dlg_menu( "احجار اسطورية", "open_market( 'hossam_s1' )" )
	--dlg_menu( "احجار غير اسطورية", "open_market( 'hossam_s2' )" )
    dlg_menu( "<#CCFFCC>Tear Drops and Stones", "open_market( 'hossam_s3' )" )
    dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( "<#FFFFFF>End Chat", '' )
    dlg_show()
    end
	function DarkxEvll_pet_5_EN()
    dlg_title( "Revolution Server")
    dlg_text( "welcome to Revolution Server" )
    --dlg_menu( "بطاقات مرافقين فازغة ", "open_market( 'dark_empty_pets_cards' )" )--تم ازلة هذا القسم لزيادة التدريب والمتاجرات:)
    
   -- dlg_menu( "جواهر المرافقين", "open_market( 'dark_johr_xd' )" )
   
    dlg_menu( "<#CCFFCC>Loot Pets", "open_market( 'dark_pets_3liv' )" )
	dlg_menu( "<#CCFFCC>Pets Summoning Scrolls", "open_market( 'dark_set_pets' )" )
    dlg_menu( "<#CCFFCC>Pets Unit items", "open_market( 'dark_tri3g_pets' )" )
	
    dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( "<#FFFFFF>End Chat", '' )
    dlg_show()
    end
	function DarkxEvil_Zain_EN()
	dlg_title( "Revolution Server")
	dlg_text( "welcome to Revolution Server" )
	dlg_menu( "<#CCFFCC>Cloacks and Wings", "open_market( 'dark_3baitat_wings' )" )
	dlg_menu( "<#CCFFCC>Hair Deco.", "open_market( 'dark_hair_zain')" )
	dlg_menu( "<#CCFFCC>Skin Deco. ","open_market( 'dark_skin_zain' )" )
	dlg_menu( "<#CCFFCC>weapons Deco.", "open_market( 'dark_weapons_zina' )" )
	dlg_menu( "<#CCFFCC>New Decorative","open_market( 'dark_new_zain' )" )
	--dlg_menu( "زينة كاملة","open_market( 'dark_file_zain' )" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
	dlg_menu( "<#FFFFFF>End Chat", '' )
	dlg_show()
end
	function DarkxEvilSkilCard()
	dlg_title( "Revolution Server" )	
    dlg_text( "مرحبا بك في قسم بطاقات مهارة السيرفر تفضل اختر ما تريد")
    dlg_menu( "شعب أرماد", "DarkxEvilarmad()" )
	dlg_menu( "شعب أجوريا", "DarkxEvilagorua()" )
	dlg_menu( "شعب أمانيس", "DarkxEvilamanys()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
	dlg_menu( "End Chat", "")
    dlg_show()
	end
	function DarkxEvilarmad()
	dlg_title( "Revolution Server" )	
    dlg_text( "مرحبا بك في قسم شعب ارماد تفضل ")
    dlg_menu( "متدرب أرماد", "open_market('A_1')" )
	dlg_menu( "مناور", "open_market('A_2')" )
	dlg_menu( "ساحر", "open_market('A_3')" )
	dlg_menu( "كابوس", "open_market('A_4')" )
	dlg_menu( "سفاح", "open_market('A_5')" )
	dlg_menu( "سيد الظلام", "open_market('A_6')" )
	dlg_menu( "ساحر ظلامي", "open_market('A_7')" )
	dlg_menu( "محطم", "open_market('A_8')" )
	dlg_menu( "سيد براري", "open_market('A_9')" )
	dlg_menu( "شبح", "open_market('A_10')" )
	dlg_menu( "محارب الغسق", "open_market('A_11')" )
	dlg_menu( "امير الظلال", "open_market('A_12')" )
	dlg_menu( "متربص", "open_market('A_13')" )
	dlg_menu( "سيد الادغال", "open_market('A_14')" )
	dlg_menu( "عودة الي القائمة السابقة", "DarkxEvilSkilCard()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
	dlg_menu( "End Chat", "")
    dlg_show()
	end
	function DarkxEvilagorua()
	dlg_title( "Revolution Server" )	
    dlg_text( "مرحبا بك في قسم شعب اجوريا تفضل")
    dlg_menu( "متدرب أجوريا", "open_market('B_1')" )
	dlg_menu( "مقاتل", "open_market('B_2')" )
	dlg_menu( "جلمود", "open_market('B_3')" )
	dlg_menu( "وحشي", "open_market('B_4')" )
	dlg_menu( "فولازي", "open_market('B_5')" )
	dlg_menu( "قناص", "open_market('B_6')" )
	dlg_menu( "مغوار", "open_market('B_7')" )
	dlg_menu( "الصنديد", "open_market('B_8')" )
	dlg_menu( "سيد الوحوش", "open_market('B_9')" )
	dlg_menu( "مدجج", "open_market('B_10')" )
	dlg_menu( "امير نبال", "open_market('B_11')" )
	dlg_menu( "امبراطور", "open_market('B_12')" )
	dlg_menu( "باسل", "open_market('B_13')" )
	dlg_menu( "سيد الكواسر", "open_market('B_14')" )
    dlg_menu( "عودة الي القائمة السابقة", "DarkxEvilSkilCard()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
	dlg_menu( "End Chat", "")
    dlg_show()
	end
	function DarkxEvilamanys()
	dlg_title( "Revolution Server" )
    dlg_text( "مرحبا بك في قسم امانيس تفضل")
    dlg_menu( "متدرب امانيس", "open_market('C_1')" )
	dlg_menu( "مدافع", "open_market('C_2')" )
	dlg_menu( "مسعف", "open_market('C_3')" )
	dlg_menu( "مروض", "open_market('C_4')" )
	dlg_menu( "فارس", "open_market('C_5')" )
	dlg_menu( "متراس", "open_market('C_6')" )
	dlg_menu( "حكيم", "open_market('C_7')" )
	dlg_menu( "طبيب", "open_market('C_8')" )
	dlg_menu( "مخلب", "open_market('C_9')" )
	dlg_menu( "نبيل", "open_market('C_10')" )
	dlg_menu( "مدرع", "open_market('C_11')" )
	dlg_menu( "سيد الحكماء", "open_market('C_12')" )
	dlg_menu( "مستشار", "open_market('C_13')" )
	dlg_menu( "جارح", "open_market('C_14')" )
	dlg_menu( "عودة الي القائمة السابقة", "DarkxEvilSkilCard()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
	dlg_menu( "End Chat", "")
    dlg_show()
	end
	function DarkxEvilAccessories_EN()
	dlg_title( "Revolution Server" )	
    dlg_text( "welcome to Revolution Server")
	dlg_menu( "<#CCFFCC>Consumables","open_market( 'DarkxEvilMstalsmataltryb' )")
	dlg_menu( "<#CCFFCC>Altered Pieces","open_market( 'REVO_BY_RAKAN_0001' )")
	dlg_menu( "<#CCFFCC>Combine Consumables ","open_market( 'DarkxEvilTaDg' )")
	dlg_menu( "<#CCFFCC>Bags", "open_market( 'dark_bags' )" )
	
	--dlg_menu( "مستلزمات تغير التخصص والشعب","open_market( 'darkxeviljod' )")
	--dlg_menu( "مستلزمات النمط","open_market( 'DarkxEvilMstalsmatnamt' )")

	--dlg_menu( "طاقم الاسهم","open_market('DarkxEvil_New_1995')")
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
	dlg_menu( "<#FFFFFF>End Chat", '')
    dlg_show()
    end
    function DarkWeaponsandShields()
    dlg_title( "Revolution Server")
    dlg_text( "مرحبا بك في قسم تجهيزات Revolution Server اي  تفضل اختار الي تبي" )
    dlg_menu( "أسحلة ودورع بصلابة7.4","darkxevilxweaponsa()" )
    dlg_menu( "أسحلة ودورع بدون صلابة 7.4","darkxevilxweaponsa74()" )
    dlg_menu( "اسحلة ودورع الاحتراف", "DarkWeaponsandShields7_4()" )
    dlg_menu( "الاسلحة الزرقاء", "open_market( 'darkxevil_blue_DroB' )" )
    dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( "<#FFFFFF>End Chat", '')
    dlg_show()
    end
    function DarkWeaponsandShields7_4()
    dlg_title( "Revolution Server")
    dlg_text( "مرحبا بك في قسم تجهيزات Revolution Server اي  تفضل اختار الي تبي" )
    dlg_menu( "دروب أحتراف","open_market('darkxevil_7_4_warrior')")
    dlg_menu( "اسحلة احتراف","open_market('darkxevil_7_4_weapon_1hand')")
    dlg_menu( "خوذات احتراف ","open_market('darkxevil_7_4_cs_equip')")
    dlg_menu( "احذيه احتراف","open_market('darkxevil_7_4_boots')")
    dlg_menu( "قفازات احتراف","open_market('darkxevil_7_4_gloves')")
    dlg_menu( "مجموعه الاحتراف","open_market('darkxevil_7_4_all_things')")
    dlg_menu( "خوأتم واقراط و قلادة الاحتراف","open_market( 'darkxevil_7_4_7oatim')")
	dlg_menu( "عودة الي القائمة السابقة", "DarkWeaponsandShields()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( "End Chat", "")
    dlg_show()
    end
    function darkxevilxweaponsa74()
    dlg_title( "Revolution Server")
    dlg_text( "مرحبا بك في قسم تجهيزات Revolution Server اي  تفضل اختار الي تبي" )
    dlg_menu( "الاسحلة", "darkxevil_Weapons_saa()")
    dlg_menu( "الدورع", "open_market( 'darkxevil_Armors_saa' )")
    dlg_menu( "احذية", "open_market( 'darkxevi_shop_armor_shoes1' )" )
    dlg_menu( "قفازات", "open_market( 'darkxevi_shop_armor_gloves1' )" )
    dlg_menu( "أحزمة", "open_market( 'darkxevi_shop_armor_belts1' )" )
    dlg_menu( "خوذ", "open_market( 'darkxevi_shop_armor_khowad1' )"  )
    dlg_menu( "تروس", "open_market( 'darkxevi_shop_armor_shield1' )" )
    dlg_menu( "خواتم", "open_market( 'darkxevi_shop_armor_show1')" )
    dlg_menu( "اقراط", "open_market( 'darkxevi_shop_armor_asha1')" )
    dlg_menu( "قلادة", "open_market( 'darkxevi_shop_armor_ssss1')" )
	dlg_menu( "عودة الي القائمة السابقة", "DarkWeaponsandShields()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( "<#FFFFFF>End Chat", '')
    dlg_show()
    end
    function darkxevil_Weapons_saa()
    dlg_title( "Revolution Server")
    dlg_text( "مرحبا بك في قسم تجهيزات Revolution Server اي  تفضل اختار الي تبي" )
    dlg_menu( "رمح ", "open_market( 'darkxevil_spear' )" )
    dlg_menu( "فاس بقبضة واحدة", "open_market( 'darkxevil_axe1' )" )
    dlg_menu( "فأس بقبضتين", "open_market( 'darkxevil_axe2' )" )
    dlg_menu( "صولجان بقبضة واحدة", "open_market( 'darkxevil_mace1' )" )
    dlg_menu( "صولجان بقبضتين", "open_market( 'darkxevil_mace2' )" )
    dlg_menu( "قوس ", "open_market( 'darkxevil_longbow ' )" )
    dlg_menu( "نشاب", "open_market( 'darkxevil_crossbow' )" )
    dlg_menu( "عصا بقبضة واحدة", "open_market( 'darkxevil_staff1' )" )
    dlg_menu( "عصا بقبضتين", "open_market( 'darkxevil_staff2' )" )
    dlg_menu( "سيف بقبضة واحدة ", "open_market( 'darkxevil_sword1' )" )
    dlg_menu( "سيف بقبضتين", "open_market( 'darkxevil_sword2' )" )
    dlg_menu( "خنجر", "open_market( 'darkxevil_dirk' )" )	
	dlg_menu( "عودة الي القائمة السابقة", "DarkWeaponsandShields()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( " <#FFFFFF>End Chat", '' )	
    dlg_show()		
    end	
    function darkxevilxweaponsa()
    dlg_title( "Revolution Server")
    dlg_text( "مرحبا بك في قسم تجهيزات Revolution Server اي  تفضل اختار الي تبي" )
    dlg_menu( "الاسحلة", "darkxevil_Weapons_s()")
    dlg_menu( "الدورع", "darkxevil_Armors_s()")
    dlg_menu( "احذية", "open_market( 'darkxevi_shop_armor_shoes' )" )
    dlg_menu( "قفازات", "open_market( 'darkxevi_shop_armor_gloves' )" )
    dlg_menu( "أحزمة", "open_market( 'darkxevi_shop_armor_belts' )" )
    dlg_menu( "خوذ", "open_market( 'darkxevi_shop_armor_khowad' )"  )
    dlg_menu( "تروس", "open_market( 'darkxevi_shop_armor_shield' )" )
    dlg_menu( "خواتم", "open_market( 'darkxevi_shop_armor_show')" )
    dlg_menu( "اقراط", "open_market( 'darkxevi_shop_armor_asha')" )
    dlg_menu( "قلادة", "open_market( 'darkxevi_shop_armor_ssss')" )
    dlg_menu( "عودة الي القائمة السابقة", "DarkWeaponsandShields()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( "<#FFFFFF>End Chat", '')
    dlg_show()
    end
    function darkxevil_Weapons_s()
    dlg_title( "Revolution Server")
    dlg_text( "مرحبا بك في قسم تجهيزات Revolution Server اي  تفضل اختار الي تبي" )
    dlg_menu( "رمح ", "open_market( 'darkxevil_spear_s' )" )
    dlg_menu( "فاس بقبضة واحدة", "open_market( 'darkxevil_axe1_s' )" )
    dlg_menu( "فأس بقبضتين", "open_market( 'darkxevil_axe2_s' )" )
    dlg_menu( "صولجان بقبضة واحدة", "open_market( 'darkxevil_mace1_s' )" )
    dlg_menu( "صولجان بقبضتين", "open_market( 'darkxevil_mace2_s' )" )
    dlg_menu( "قوس ", "open_market( 'darkxevil_longbow_s' )" )
    dlg_menu( "نشاب", "open_market( 'darkxevil_crossbow_s' )" )
    dlg_menu( "عصا بقبضة واحدة", "open_market( 'darkxevil_staff1_s' )" )
    dlg_menu( "عصا بقبضتين", "open_market( 'darkxevil_staff2_s' )" )
    dlg_menu( "سيف بقبضة واحدة ", "open_market( 'darkxevil_sowrd1_s' )" )
    dlg_menu( "سيف بقبضتين", "open_market( 'darkxevil_sowrd2_s' )" )
    dlg_menu( "خنجر", "open_market( 'darkxevil_dirk_s' )" )	
    dlg_menu( "عودة الي القائمة السابقة", "darkxevilxweaponsa()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( " <#FFFFFF>End Chat", '' )	
    dlg_show()		
    end
    function darkxevil_Armors_s()
    dlg_title( "Revolution Server")
    dlg_text( "مرحبا بك في قسم تجهيزات Revolution Server اي  تفضل اختار الي تبي" )
    dlg_menu( "درع النمط الحربي", "open_market( 'darkxevil_armors1_s1' )" )	
    dlg_menu( "درع نمط الصياد", "open_market( 'darkxevil_armors2_s1' )" )	
    dlg_menu( "درع نمط البراري", "open_market( 'darkxevil_armors3_s1' )" )
    dlg_menu( "درع النمط السحري", "open_market( 'darkxevil_armors4_s1' )" )
	dlg_menu( "عودة الي القائمة السابقة", "DarkWeaponsandShields()" )
	dlg_menu( "<#FFFF66>back", 'NPC_DarkxEvil_BlackEye_contact_EN()')
    dlg_menu( " <#FFFFFF>End Chat", '' )	
    dlg_show()	
    end
	function Teleporter_Smart() -- Smart Team Teleporter :3
dlg_title( "المرسال الخاص" )
dlg_text( "أهلا و سهلا بك .. مرسال Revolution Server تحت خدمتك" )
dlg_menu( "المدن الرئيسية", 'City_Main()' )
dlg_menu( "المناطق فرعية", 'City_Sub()' )
dlg_menu( "الدهاليز", 'Dungeon_Teleport1()' )
dlg_menu( "<#FFFFFF>End Chat", '' )
dlg_show()
end
function City_Main()
dlg_title( "المرسال الخاص" )
dlg_text( "المدن الرئيسية" )
dlg_menu( "جندار", 'Teleport_Now( 152465, 76951, 100000 )' )
dlg_menu( "ماندا", 'Teleport_Now(152465, 76951, 100000)' )
dlg_menu( "أوروك", 'Teleport_Now(117974, 59119, 100000)' )
dlg_menu( "أبيدوس", 'Teleport_Now(138274, 105965, 100000)' )
dlg_menu( "كاديس", 'Teleport_Now(154666, 150287, 100000)' )
dlg_menu( "إيتانا", 'Teleport_Now(162624, 131811, 100000)' )
dlg_menu( "رجوع", 'Teleporter_Smart()' )
dlg_menu( "<#FFFFFF>End Chat", '' )
dlg_show()
end
function City_Sub()
dlg_title( "المرسال الخاص" )
dlg_text( "المناطق الفرعية" )
dlg_menu( "الجزيرة المخفية", "Teleport_Now(83876, 115913, 150000)" )
dlg_menu( "الشلال", 'Teleport_Now(146361, 135624, 150000)' )
dlg_menu( "أنوار", 'Teleport_Now(135876, 156035, 150000)' )
dlg_menu( "جزيرة يارس", 'Teleport_Now(142086, 132207, 150000)' )
dlg_menu( "صحراء موتيا", 'Teleport_Now(116000, 89800, 150000)' )
dlg_menu( "غابات العلقم", 'Teleport_Now(162200, 119000, 150000)' )
dlg_menu( "وكر التنين", 'Teleport_Now(106200, 135400, 150000)' )
dlg_menu( "المزرعة الحمراء", 'Teleport_Now(123400, 104000, 150000)' )
dlg_menu( "رجوع", 'Teleporter_Smart()' )
dlg_menu( "<#FFFFFF>End Chat", '' )
dlg_show()
end
function Dungeon_Teleport1()
dlg_title( "المرسال الخاص" )
dlg_text( "الدهاليز" )
dlg_menu( "باب القمر 1", "Teleport_In_Out( 222779, 72351, 132965, 87069 , 'مرسال باب القمر الأول', 'Dungeon_Teleport1()' )" )
dlg_menu( "باب القمر 2", "Teleport_In_Out( 222778, 120723, 130246, 79583 , 'مرسال باب القمر الثاني', 'Dungeon_Teleport1()')" )
dlg_menu( "المنجم المفقود 1", "Teleport_In_Out( 219257, 15681, 155874, 103758 , 'مرسال المنجم المفقود الأول', 'Dungeon_Teleport1()')" )
dlg_menu( "المنجم المفقود 2", "Teleport_In_Out( 219257, 112449, 152309, 102886 , 'مرسال المنجم المفقود الثاني', 'Dungeon_Teleport1()')" )
dlg_menu( "وادي الماس 1", "Teleport_In_Out( 218806, 56778, 103218, 100377 , 'مرسال وادي الماس الأول', 'Dungeon_Teleport1()')" )
dlg_menu( "وادي الماس 2", "Teleport_In_Out( 218806, 89034, 99758, 103245 , 'مرسال وادي الماس الثاني', 'Dungeon_Teleport1()')" )
dlg_menu( "مركز تبرعات قرقيس 1", "Teleport_In_Out( 211302, 129971, 132686, 128034 , 'مرسال مركز تبرعات قرقيس الأول', 'Dungeon_Teleport1()')" )
dlg_menu( "مركز تبرعات قرقيس 2", "Teleport_In_Out( 211299, 146193, 137446, 128108 , 'مرسال مركز تبرعات قرقيس الثاني', 'Dungeon_Teleport1()')" )
dlg_menu( "باقي الدهاليز", 'Dungeon_Teleport2()' )
dlg_menu( "رجوع", "Teleporter_Smart()" )
dlg_menu( "<#FFFFFF>End Chat", '' )
dlg_show()
end
function Dungeon_Teleport2()
dlg_title( "المرسال الخاص" )
dlg_text( "باقي الدهاليز" )
dlg_menu( "أسطورة القدماء", "Teleport_In_Out( 206071, 116948, 146074, 135595 , 'مرسال أسطورة القدماء', 'Dungeon_Teleport2()')" )
dlg_menu( "الأسطورة العريقة", "Teleport_In_Out( 201400, 167649, 91925, 117126 , 'مرسال الأسطورة العريقة', 'Dungeon_Teleport2()')" )
dlg_menu( "أسطورة الأنوار", "Teleport_In_Out( 201400, 151566, 85790, 118118 , 'مرسال أسطورة الأنوار', 'Dungeon_Teleport2()')" )
dlg_menu( "الأسطورة الضائعة", "Teleport_In_Out( 201406, 135330, 92011, 124429 , 'مرسال الأسطورة الضائعة', 'Dungeon_Teleport2()')" )
dlg_menu( "كيوبيكالا", "Teleport_Now(98924, 129289, 250000)" )
dlg_menu( "دهليز العنقاء", "RunTeleport( 0 , 170314 , 153429 )" )
dlg_menu( "الصفحة السابقة", 'Dungeon_Teleport1()' )
dlg_menu( "<#FFFFFF>End Chat", '' )
dlg_show()
end
function Teleport_Now( x, y, price )
local gold = gv("gold")
if gold >= price then
dlg_special('confirm_window', 'RunTeleport( '..price..",".. x..",".. y..' )', "عند الضغط على موافق سوف يتم خصم "..price.." عملة ذهب" )
else
message("عفوا لا تملك ما يكفي من المال لتنفيذ هذه العملية !!")
end
end
function Teleport_In_Out( Xin, Yin, Xout, Yout , Name, Func )
dlg_title( "المرسال الخاص" )
dlg_text( Name )
dlg_menu( "بالداخل", 'Teleport_Now('.. Xin..','.. Yin..','.. 250000 ..')' )
dlg_menu( "بالخارج", 'Teleport_Now( '..Xout..','.. Yout..','.. 250000 ..')' )
dlg_menu( "رجوع", Func )
dlg_menu( "<#FFFFFF>End Chat", '' )
dlg_show()
end
function Amaady_JP_Converter() --jp_chager()
		dlg_title( "تاجر الـ JP Amaady" )
		
		dlg_text( "مرحبا بك ..<br>أنا تاجر نقاط العمل في خدمتك ..<br>اختر ما تريد من الأقسام التالية :" )
		
		dlg_menu( "JP مقابل الذهب", "rup_sub()" )
		dlg_menu( "JP مقابل نقاط تحدي", "holic_sub()" )
		dlg_menu( "JP مقابل نقاط احتراف", "tp_sub()" )
		--dlg_menu( "JP مقابل JP للمرافق", "CreatureBuyJPMenu()" )
		dlg_menu( "عودة الي السابق", "NPC_DarkxEvil_BlackEye_contact_EN()")
		dlg_menu( "<#FFFFFF>End Chat", " " )
		
		dlg_show()
end

--************************************************************************************--
--****************************قسم التبديل من جي بي إلى ذهب****************************--
--************************************************************************************--
 -- UNTERMEN?: JP -> Rupee --

function rup_sub()
		dlg_title( "تاجر الـ JP Amaady" )
		dlg_text( "أود إخبارك بأنني أبدل كل نقطة عمل بعملتين من الذهب" )
		dlg_menu( "1.000.000 JP", "rup_exchange(1)" )
		dlg_menu( "2.500.000 JP", "rup_exchange(2)" )
		dlg_menu( "5.000.000 JP", "rup_exchange(3)" )
		dlg_menu( "10.000.000 JP", "rup_exchange(4)" )
		dlg_menu( "25.000.000 JP", "rup_exchange(5)" )
		dlg_menu( "50.000.000 JP", "rup_exchange(6)" )
		dlg_menu( "100.000.000 JP", "rup_exchange(7)" )
		dlg_menu( "500 M JP", "rup_exchange(8)" )
		dlg_menu( "1000 M JP", "rup_exchange(9)" )
		dlg_menu( "2500 M JP", "rup_exchange(10)" )
		dlg_menu( "5000 M JP", "rup_exchange(11)" )
		dlg_menu( "تبديل كل الـ JP بالذهب", "JP_all_Rub()" )
		dlg_menu( "عودة", "Amaady_JP_Converter()" )
		dlg_menu( "<#FFFFFF>End Chat", " " )
		
		dlg_show()
end

-- FUNKTION: JP -> Rupee --

function JP_N_find_1()
dlg_title( "تاجر الـ JP Amaady" )
dlg_text( "عذرا انت لا تملك ما يكفي من JP" )
dlg_menu( "عودة", "rup_sub()" )
dlg_menu( "<#FFFFFF>End Chat", " " )
dlg_show()
 end
 
function rup_exchange( rup_id )
		local jp = get_value( "jp" )
		local gold = get_value( "gold" )
		text1 = "تمت عملية الاستبدال بنجاح !!"

		if rup_id == 1 then
		
				if jp >= 1000000 then
						
						set_value( "jp", jp - 1000000 )
						set_value( "gold", gold + 2000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end
		
		if rup_id == 2 then
		
				if jp >= 2500000 then
						
						set_value( "jp", jp - 2500000 )
						set_value( "gold", gold + 5000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()	
				end
				
		return
		end

		if rup_id == 3 then
		
				if jp >= 5000000 then
						
						set_value( "jp", jp - 5000000 )
						set_value( "gold", gold + 10000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end

		if rup_id == 4 then
		
				if jp >= 10000000 then
						
						set_value( "jp", jp - 10000000 )
						set_value( "gold", gold + 20000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end

		if rup_id == 5 then
		
				if jp >= 25000000 then
						
						set_value( "jp", jp - 25000000 )
						set_value( "gold", gold + 50000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end

		if rup_id == 6 then
		
				if jp >= 50000000 then
						
						set_value( "jp", jp - 50000000 )
						set_value( "gold", gold + 100000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end

		if rup_id == 7 then
		
				if jp >= 100000000 then
						
						set_value( "jp", jp - 100000000 )
						set_value( "gold", gold + 200000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end

		if rup_id == 8 then
		
				if jp >= 500000000 then
						
						set_value( "jp", jp - 500000000 )
						set_value( "gold", gold + 1000000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end		

		if rup_id == 9 then
		
				if jp >= 1000000000 then
						
						set_value( "jp", jp - 1000000000 )
						set_value( "gold", gold + 2000000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end

		if rup_id == 10 then
		
				if jp >= 2500000000 then
						
						set_value( "jp", jp - 2500000000 )
						set_value( "gold", gold + 5000000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end

		if rup_id == 11 then
		
				if jp >= 5000000000 then
						
						set_value( "jp", jp - 5000000000 )
						set_value( "gold", gold + 10000000000 )
						message( text1 )
						rup_sub()
						
				else
				JP_N_find_1()
				end
				
		return
		end	
end

 -- Change all jp to Rubee by: Amaady >>
function JP_all_Rub()
			local jp = get_value( "jp" )
			local gold = get_value( "gold" )
			local add_gold = jp*2
		if jp >= 1 then
			set_value( "gold", gold + add_gold )
			set_value( "jp" , 0 )
		else
			dlg_title( "تاجر JP" )
			dlg_text( "عذرا انت لا تملك ما يكفي من JP" )
			dlg_menu( "@90010003", "rup_sub()" )
			dlg_menu( "<#FFFFFF>End Chat", " " )
			dlg_show()
		end
end

--************************************************************************************--
--*************************قسم التبديل من جي بي إلى ذهب انتهى*************************--
--************************************************************************************--
--************************************************************************************--
--**************************قسم التبديل من جي بي إلى نقاط دب**************************--
--************************************************************************************--
 -- UNTERMEN?: JP -> Holic --

function holic_sub()

		dlg_title( "تاجر JP" )
		
		dlg_text( "أود إخبارك بأنني أبدل كل ألف نقطة عمل بنقطة واحدة من نقاط دهليز الدب" )
		
		dlg_menu( "1.000.000 JP", "holic_exchange(1)" )
		dlg_menu( "2.500.000 JP", "holic_exchange(2)" )
		dlg_menu( "5.000.000 JP", "holic_exchange(3)" )
		dlg_menu( "10.000.000 JP", "holic_exchange(4)" )
		dlg_menu( "25.000.000 JP", "holic_exchange(5)" )
		dlg_menu( "50.000.000 JP", "holic_exchange(6)" )
		dlg_menu( "100.000.000 JP", "holic_exchange(7)" )
		dlg_menu( "500 M JP", "holic_exchange(8)" )
		dlg_menu( "1000 M JP", "holic_exchange(9)" )
		dlg_menu( "2500 M JP", "holic_exchange(10)" )
		dlg_menu( "5000 M JP", "holic_exchange(11)" )
		dlg_menu( "تبديل كل الـ JP بنقاط دب", "JP_all_holic()" )
		dlg_menu( "عودة", "Amaady_JP_Converter()" )
		dlg_menu( "<#FFFFFF>End Chat", " " )
		
		dlg_show()
		
end

 -- FUNKTION: JP -> Holic --
 
function JP_N_find_2()
dlg_title( "تاجر الـ JP Amaady" )
dlg_text( "عذرا انت لا تملك ما يكفي من JP" )
dlg_menu( "عودة", "holic_sub()" )
dlg_menu( "انهاء المحادثة", " " )
dlg_show()
 end
 
function holic_exchange( holic_id )

		local jp = get_value( "jp" )
		local holic = get_value( "huntaholic_point" )
		text2 = "تمت عملية الاستبدال بنجاح !!"

		
		if holic_id == 1 then
		
				if jp >= 1000000 then
						
						set_value( "jp", jp - 1000000 )
						set_huntaholic_point( holic + 1000 )
						message( "لقد كسبت 1000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()	
				end
				
		return
		end

		if holic_id == 2 then
		
				if jp >= 2500000 then
						
						set_value( "jp", jp - 2500000 )
						set_huntaholic_point( holic + 2500 )
						message( "لقد كسبت 2500 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()		
				end
				
		return
		end

		if holic_id == 3 then
		
				if jp >= 5000000 then
						
						set_value( "jp", jp - 5000000 )
						set_huntaholic_point( holic + 5000 )
						message( "لقد كسبت 5000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()		
				end
				
		return
		end

		if holic_id == 4 then
		
				if jp >= 10000000 then
						
						set_value( "jp", jp - 10000000 )
						set_huntaholic_point( holic + 10000 )
						message( "لقد كسبت 10000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else	
				JP_N_find_2()	
				end
				
		return
		end

		if holic_id == 5 then
		
				if jp >= 25000000 then
						
						set_value( "jp", jp - 25000000 )
						set_huntaholic_point( holic + 25000 )
						message( "لقد كسبت 25000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()		
				end
				
		return
		end

		if holic_id == 6 then
		
				if jp >= 50000000 then
						
						set_value( "jp", jp - 50000000 )
						set_huntaholic_point( holic + 50000 )
						message( "لقد كسبت 50000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()		
				end
				
		return
		end

		if holic_id == 7 then
		
				if jp >= 100000000 then
						
						set_value( "jp", jp - 100000000 )
						set_huntaholic_point( holic + 100000 )
						message( "لقد كسبت 100000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()
				end
				
		return
		end

		if holic_id == 8 then
		
				if jp >= 500000000 then
						
						set_value( "jp", jp - 500000000 )
						set_huntaholic_point( holic + 500000 )
						message( "لقد كسبت 500000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()		
				end
				
		return
		end		

		if holic_id == 9 then
		
				if jp >= 1000000000 then
						
						set_value( "jp", jp - 1000000000 )
						set_huntaholic_point( holic + 1000000 )
						message( "لقد كسبت 1000000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()	
				end
				
		return
		end
		
		if holic_id == 10 then
		
				if jp >= 2500000000 then
						
						set_value( "jp", jp - 2500000000 )
						set_huntaholic_point( holic + 2500000 )
						message( "لقد كسبت 2500000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else	
				JP_N_find_2()		
				end
				
		return
		end

		if holic_id == 11 then
		
				if jp >= 5000000000 then
						
						set_value( "jp", jp - 5000000000 )
						set_huntaholic_point( holic + 5000000 )
						message( "لقد كسبت 5000000 نقطة دهاليز !!" )
						message( text2 )
						holic_sub()
						
				else
				JP_N_find_2()	
				end
				
		return
		end
end

 -- Change all jp to holic by: Amaady >>

function JP_all_holic()
	local jp = get_value( "jp" )
	local holic = get_value( "huntaholic_point" )
	local n = 1000
	local add_holic_e = jp - math.floor(jp/n)*n
	local add_holic_f = jp - add_holic_e
	local add_holic = add_holic_f / n
	if jp >= n then
	set_huntaholic_point( holic + add_holic )
	set_value( "jp" , add_holic_e )
	else
		dlg_title( "تاجر JP" )
		dlg_text( "عذرا انت لا تملك ما يكفي من JP" )
		dlg_menu( "@90010003", "holic_sub()" )
		dlg_menu( "<#FFFFFF>End Chat", " " )
		dlg_show()
	end
end

--************************************************************************************--
--***********************قسم التبديل من جي بي إلى نقاط دب انتهى***********************--
--************************************************************************************--
--************************************************************************************--
--************************قسم التبديل من جي بي إلى نقاط احتراف************************--
--************************************************************************************--

 -- UNTERMEN?: JP -> TP --

function tp_sub()

		dlg_title( "تاجر JP" )
		
		dlg_text( "أود اخبارك بان 1000 مليون JP = 1 نقطة احتراف" )
		
		dlg_menu( "اعطني نقاط احتراف", "tp_exchange()" )
		dlg_menu( "عودة", "Amaady_JP_Converter()" )
		dlg_menu( "<#FFFFFF>End Chat", " " )
		
		dlg_show()

end

-- FUNKTION: JP -> TP --

function tp_exchange()

		local tp = get_value( "tp" )
		local jp = get_value( "jp" )
		local job = get_value( "job_2" )
		text3 = "تمت عملية الاستبدال بنجاح!"
		
		if jp >= 1000000000 then

				if job > 0 then
				
						set_value( "jp", jp - 1000000000 )
						set_value( "tp", tp + 1 )
						message( text3 )
						tp_sub()
				
				else
				
						dlg_title( "تاجر JP" )
						
						dlg_text( "اعتذر منك يا #@character_name@# انت لست مؤهلا لذلك عد للتدريب" )
						
						dlg_menu( "@90010003", "Amaady_JP_Converter()" )
						dlg_menu( "انهاء المحادثة", " " )
						
						dlg_show()
						
				return
				end
				
		else
		
				dlg_title( "تاجر JP" )
				
				dlg_text( "عذرا انت لا تملك ما يكفي من JP" )
				
				dlg_menu( "@90010003", "Amaady_JP_Converter()" )
				dlg_menu( "انهاء المحادثة", " " )
				
				dlg_show()
		
		return		
		end
		
end

--************************************************************************************--
--*********************قسم التبديل من جي بي إلى نقاط احتراف انتهى*********************--
--************************************************************************************--
--************************************************************************************--
--***********************قسم التبديل من جي بي إلى جي بي المرافق***********************--
--************************************************************************************--

  -- ~FUNKTION: Charakter-JP gegen Kreaturen-JP

function CreatureBuyJPMenu()

		dlg_title( "تاجر JP" )
		dlg_text( "20 مليون JP مقابل 1 JP للمرافق ، ما هو المرافق الذي سيحصل على الـ JP" )

		for i = 0, 5 do


				handle = 0
				handle = get_creature_handle( i )

				if handle ~= 0 and handle ~= nil then

						lv = get_creature_value( handle, "level" )
						petJp = get_creature_value( handle, "jp" )

						text = sconv("@90010009", "#@creature_name@#",tostring(get_creature_value( handle, "name" )) ,"#@creature_level@#",tostring(lv))

						command = 'Creature_Buy_JP( ' .. handle .. ' )'

						dlg_menu( text, command )

				end

		end

		dlg_menu( "عودة", "Amaady_JP_Converter()" )
		dlg_menu( "انهاء المحادثة", " " )
		dlg_show()

end

function Creature_Buy_JP( handle )


		playerJPs = get_value( "jp" )
		petJp = get_creature_value( handle, "jp" )
		
		if playerJPs >= 20000000 then

				set_creature_value( handle, "jp", petJp + 1 )
				sv( "jp", playerJPs - 20000000)
				message( "لقد حصل مرافقك على نقطة JP" )
				CreatureBuyJPMenu()

		else

				dlg_title( "تاجر JP" )
				
				dlg_text( "عذرًا أنت لا تملك ما يكفي من JP")
				
				dlg_menu( "عودة", "Amaady_JP_Converter()" )
				dlg_menu( "انهاء المحادثة", " " )
				
				dlg_show()

		end

end