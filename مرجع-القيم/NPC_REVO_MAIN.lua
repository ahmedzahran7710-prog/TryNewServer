------------------بسم الله الرحمن الرحيم---------------------
----------------------Smart Team--------------------------
----------------------Revolution--------------------------
----------------------ثورة الشعوب ------------------------

function get_module_name()
    return "DarkxEvil_Revolution" --DarkxEvil_BlackEye
end

    function NPC_DarkxEvil_Revolution_contact()--NPC_DarkxEvil_BlackEye_contact
	dlg_title( "ثورة الشعوب")
	--dlg_text( "مرحباً بك في تاجر ثورة الشعوب  .. التاجر العام في خدمتك .. اختر ما تريد من الأقسام التالية :" )
	dlg_text( "التاجر الآن في الصيانة | Merchant is now in maintenance" )
	dlg_menu( "<#FFFFFF>اللغة العربية", "NPC_DarkxEvil_Revolution_contact_AR()")
	dlg_menu( "<#FFFFFF>English language", "NPC_DarkxEvil_Revolution_contact_EN()")
	dlg_menu( "<#FFFFFF>حصول على إذن القرية المخفية ", "GET_H_V_P()")
	dlg_menu( "<#FFFFFF>Get Hidden Village Pass ", "GET_H_V_P()")
	dlg_menu( "<#FFFFFF>إنهاء المحادثة", '' )
    dlg_show()
	end
	function GET_H_V_P()
			delete_item( get_item_handle( 910023 ), 1 )
			insert_item(910023, 1)
	
	end

	function NPC_DarkxEvil_Revolution_contact_AR()
	dlg_title( "ثورة الشعوب" )
	dlg_text( "مرحباً بك في تاجر ثورة الشعوب  .. التاجر العام في خدمتك .. اختر ما تريد من الأقسام التالية :" )
	dlg_menu( "<#CCFFCC>المستلزمات العامة", "DarkxEvilAccessories()" )
	dlg_menu( "<#CCFFCC>خوذ الإحتراف", "open_market( 'REVO_BY_RAKAN_0002' )" )
	dlg_menu( "<#CCFFCC>خوذ الدعم", "open_market( 'REVO_BY_RAKAN_0003' )" )
	dlg_menu( "<#CCFFCC>قسم الزينة", "DarkxEvil_Zain()" )
	dlg_menu( "<#CCFFCC>قسم الاحجار", "Dark_Stone()" )
	dlg_menu( "<#CCFFCC>القسم العام للمرافق", "DarkxEvll_Creature_Pet()" )
	dlg_menu( "إنهاء المحادثة", '' )
    dlg_show()
	end
	
	function Dark_Stone()
    dlg_title( "ثورة الشعوب" )
    dlg_text( "مرحباً بك في تاجر ثورة الشعوب  .. التاجر العام في خدمتك .. اختر ما تريد من الأقسام التالية :" )
    dlg_menu( "<#CCFFCC>الأحجار الاستثنائية و الفريدة", "open_market( 'hossam_s3' )" )
    dlg_menu( "<#FFFF66>عودة إلى القائمة الرئيسية", "NPC_DarkxEvil_Revolution_contact_AR()")
    dlg_menu( "<#FFFFFF>إنهاء المحادثة", '' )
    dlg_show()
    end
	
	function DarkxEvll_Creature_Pet()
    dlg_title( "ثورة الشعوب" )
    dlg_text( "مرحباً بك في تاجر ثورة الشعوب  .. التاجر العام في خدمتك .. اختر ما تريد من الأقسام التالية :" )
    dlg_menu( "<#CCFFCC>المرافقين الاليفين", "open_market( 'dark_pets_3liv' )" )
	dlg_menu( "<#CCFFCC>لفافات طلب مرافق", "open_market( 'dark_set_pets' )" )
    dlg_menu( "<#CCFFCC>ترياقات المرافق", "open_market( 'dark_tri3g_pets' )" )
    dlg_menu( "<#FFFF66>عودة إلى القائمة الرئيسية", "NPC_DarkxEvil_Revolution_contact_AR()" )
    dlg_menu( "<#FFFFFF>إنهاء المحادثة", '' )
    dlg_show()
    end
	
	function DarkxEvil_Zain()
	dlg_title( "ثورة الشعوب" )
	dlg_text( "مرحباً بك في تاجر ثورة الشعوب  .. التاجر العام في خدمتك .. اختر ما تريد من الأقسام التالية :" )
	dlg_menu( "<#CCFFCC>أجنحة و عبائات", "open_market( 'dark_3baitat_wings' )" )
	dlg_menu( "<#CCFFCC>زينة الشعر", "open_market( 'dark_hair_zain')" )
	dlg_menu( "<#CCFFCC>زينة الأقنعة", "open_market( 'dark_masks91_zain')" )
	dlg_menu( "<#CCFFCC>زينة البشرة ","open_market( 'dark_skin_zain' )" )
	dlg_menu( "<#CCFFCC>زينة الأسلحة", "open_market( 'dark_weapons_zina' )" )
	dlg_menu( "<#CCFFCC>الزينة الجديدة","open_market( 'dark_new_zain' )" )
	dlg_menu( "<#FFFF66>عودة إلى القائمة الرئيسية", "NPC_DarkxEvil_Revolution_contact_AR()" )
	dlg_menu( "<#FFFFFF>إنهاء المحادثة", '' )
	dlg_show()
	end
	
	function DarkxEvilAccessories()
	dlg_title( "ثورة الشعوب" )	
    dlg_text( "مرحباً بك في تاجر ثورة الشعوب  .. التاجر العام في خدمتك .. اختر ما تريد من الأقسام التالية :" )
	dlg_menu( "<#CCFFCC>المستلزمات","open_market( 'DarkxEvilMstalsmataltryb' )" )
	dlg_menu( "<#CCFFCC>الأجزاء و الرقاقات","open_market( 'REVO_BY_RAKAN_0001' )" )
	dlg_menu( "<#CCFFCC>مستلزمات تطوير الدورب والدمج","open_market( 'DarkxEvilTaDg' )" )
	dlg_menu( "<#CCFFCC>حقائب", "open_market( 'dark_bags' )" )
	dlg_menu( "<#FFFF66>عودة إلى القائمة الرئيسية", "NPC_DarkxEvil_Revolution_contact_AR()" )
	dlg_menu( "<#FFFFFF>إنهاء المحادثة", '')
    dlg_show()
    end
	
	function NPC_DarkxEvil_Revolution_contact_EN()
	dlg_title( "Revolution Server" )
	dlg_text( "Welcome To Revolution Server" )
	dlg_menu( "<#CCFFCC>Main Consumables", "DarkxEvilAccessories_EN()" )
	dlg_menu( "<#CCFFCC>Master Class Helmets", "open_market( 'REVO_BY_RAKAN_0002' )" )
	dlg_menu( "<#CCFFCC>R7 Helmets", "open_market( 'REVO_BY_RAKAN_0003' )" )
	dlg_menu( "<#CCFFCC>Decorative Section", "DarkxEvil_Zain_EN()" )
	dlg_menu( "<#CCFFCC>Stones Section", "Dark_Stone_EN()" )
	dlg_menu( "<#CCFFCC>Main Pets Section", "DarkxEvll_Creature_Pet_EN()" )
	dlg_menu( "Cancel", '' )
    dlg_show()
	end

	function Dark_Stone_EN()
    dlg_title( "Revolution Server" )
    dlg_text( "Welcome To Revolution Server" )
    dlg_menu( "<#CCFFCC>Tear Drops and Stones", "open_market( 'hossam_s3' )" )
    dlg_menu( "<#FFFF66>back", "NPC_DarkxEvil_Revolution_contact_EN()" )
    dlg_menu( "<#FFFFFF>Cancel", '' )
    dlg_show()
    end
	
	function DarkxEvll_Creature_Pet_EN()
    dlg_title( "Revolution Server" )
    dlg_text( "Welcome To Revolution Server" )
    dlg_menu( "<#CCFFCC>Loot Pets", "open_market( 'dark_pets_3liv' )" )
	dlg_menu( "<#CCFFCC>Pets Summoning Scrolls", "open_market( 'dark_set_pets' )" )
    dlg_menu( "<#CCFFCC>Pets Unit items", "open_market( 'dark_tri3g_pets' )" )
    dlg_menu( "<#FFFF66>back", "NPC_DarkxEvil_Revolution_contact_EN()" )
    dlg_menu( "<#FFFFFF>Cancel", '' )
    dlg_show()
    end
	
	function DarkxEvil_Zain_EN()
	dlg_title( "Revolution Server" )
	dlg_text( "Welcome To Revolution Server" )
	dlg_menu( "<#CCFFCC>Cloacks and Wings", "open_market( 'dark_3baitat_wings' )" )
	dlg_menu( "<#CCFFCC>Hair Deco.", "open_market( 'dark_hair_zain')" )
	dlg_menu( "<#CCFFCC>Mask Deco.", "open_market( 'dark_masks91_zain')" )
	dlg_menu( "<#CCFFCC>Skin Deco. ", "open_market( 'dark_skin_zain' )" )
	dlg_menu( "<#CCFFCC>weapons Deco.", "open_market( 'dark_weapons_zina' )" )
	dlg_menu( "<#CCFFCC>New Decorative", "open_market( 'dark_new_zain' )" )
	dlg_menu( "<#FFFF66>back", "NPC_DarkxEvil_Revolution_contact_EN()" )
	dlg_menu( "<#FFFFFF>Cancel", '' )
	dlg_show()
	end

	function DarkxEvilAccessories_EN()
	dlg_title( "Revolution Server" )	
    dlg_text( "Welcome To Revolution Server" )
	dlg_menu( "<#CCFFCC>Consumables", "open_market( 'DarkxEvilMstalsmataltryb' )" )
	dlg_menu( "<#CCFFCC>Altered Pieces", "open_market( 'REVO_BY_RAKAN_0001' )" )
	dlg_menu( "<#CCFFCC>Combine Consumables", "open_market( 'DarkxEvilTaDg' )" )
	dlg_menu( "<#CCFFCC>Bags", "open_market( 'dark_bags' )" )
	dlg_menu( "<#FFFF66>back", "NPC_DarkxEvil_Revolution_contact_EN()" )
	dlg_menu( "<#FFFFFF>Cancel", '' )
    dlg_show()
    end