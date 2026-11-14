-- Lua 스크립트 암호화
function get_module_name()
             return "on_login"
end

function on_login( name )

	-- 국가 코드 읽어오기
		-- get_local_info()의 반환값들
		--LOCAL_INFO_KOREA                      = 1
		--LOCAL_INFO_HONGKONG                   = 2
		--LOCAL_INFO_AMERICA                    = 4
		--LOCAL_INFO_EUROPE                     = 8
		--LOCAL_INFO_JAPAN                      = 16
		--LOCAL_INFO_TAIWAN                     = 32
		--LOCAL_INFO_CHINA                      = 64
		
	local race = get_value( "race" )
	local state_code = get_local_info() 

	-- 직업이 없는 캐릭은 새로만든 캐릭이므로 초기설정
	if get_value( "job" ) == 0 then
		on_first_login( name )
		
	-- 기존 캐릭터일 때, 국가 코드=64(중국)만 광고 화면 팝업
	else
		if state_code == 64 then
			open_popup("game.advertise_url",0,0)
		end
	end
		
	-- 귀환지역 없는 플레이어는 귀환지역 설정.
	local temp_rx = get_flag( "rx" )
	local temp_ry = get_flag( "ry" )

	if temp_rx == "" or temp_ry == "" then
	
		if race == 4 then
		
			-- 데바 귀환지역 설정
			set_flag( "rx", 7250 + math.random(0,100))
			set_flag( "ry", 6959 + math.random(0,100))
	
		elseif race == 5 then
		
			-- 아수라 귀환지역 설정
			set_flag( "rx", 116542 + math.random(0,100))
			set_flag( "ry", 58190 + math.random(0,100))

		else
			-- 가이아 귀환지역 설정
			set_flag( "rx", 152742 + math.random(0,100))
			set_flag( "ry", 77401 + math.random(0,100))

		end
	end
	
	-- 오토로 세팅된 캐릭터라면 저 멀리 날려 버리자~
	kick_auto_to_another_world()

	-- 수련자 섬에 있는 오토들은 본토로 날려 버리자
	local current_x = gv("x")
	local current_y = gv("y")
 
	if current_x >= 161280 and current_x <= 177408 then
		if current_y >= 48384 and current_y <= 64512 then
		
			local is_auto, quest_count
			quest_count, is_auto = anti_auto_quest_check()
	
			if is_auto then
			
		 		if race == 4 then
					RunTeleport_Auto_TO_City( 6625 , 6980 )
				elseif race == 5 then
					RunTeleport_Auto_TO_City( 116799 , 58205 )
				else
					RunTeleport_Auto_TO_City( 153506 , 77175 )
				end
				
			end -- if is_auto then
			
		end -- if current_y >= 48384 and current_y <= 64512 then
	end -- if current_x >= 161280 and current_x <= 177408 then
	
	
	--플래그 삭제
	
	--아무런 사용 없음
	del_flag( "cyan_ticket" )
	del_flag( "green_ticket" )
	
	--불카누스 입장시 새로 생성하므로 삭제
	del_flag( "Vul1" )
	del_flag( "Vul2" )
	del_flag( "Vul3" )
	
	
	--퀘스트 완료로 삭제
	--반환값 -1 : 아무것도 아님  /  0 : 수락가  /  1 : 수행중  /  2 : 종료가능   / 100 : 실패  /  255 : 이미종료
	local quest_progress3248 = get_quest_progress(3248) -- [집착]에르곤 크라토스
	local quest_progress3609 = get_quest_progress(3609) -- [큐브릭]악마 큐브 정화
	local quest_progress3350 = get_quest_progress(3350) -- [TP]탐험의 왕
	local quest_progress2008 = get_quest_progress(2008) -- [부활]광신도 암살자: 붉은농장
	local quest_progress2025 = get_quest_progress(2025) -- [부활]헥토르 소환
	
	if quest_progress3248 == 255 then
		del_flag( "count" )
		del_flag( "sx" )
		del_flag( "sy" )
		del_flag( "ex" )
		del_flag( "ey" )
	end
	
	if quest_progress3609 == 255 then
		del_flag( "alram_count_01" )
		del_flag( "alram_count_02" )
		del_flag( "alram_count_03" )
		del_flag( "alram_count_04" )
		del_flag( "alram_count_05" )
		del_flag( "alram_count_06" )
		
		del_flag( "juliet_finding" )
		del_flag( "romeo_finding" )
		
	end
	
	if quest_progress3350 == 255 then
		del_flag( "over_bluepoint_lakcity" )
		del_flag( "over_bluepoint_horizon" )
		del_flag( "over_bluepoint_katan" )
		del_flag( "over_bluepoint_rondoh" )
		
		del_flag( "over_redpoint_lakcity" )
		del_flag( "over_redpoint_horizon" )
		del_flag( "over_redpoint_katan" )
		del_flag( "over_redpoint_rondoh" )
		
		del_flag( "over_greenpoint_lakcity" )
		del_flag( "over_greenpoint_horizon" )
		del_flag( "over_greenpoint_katan" )
		del_flag( "over_greenpoint_rondoh" )
	end
	
	if quest_progress2008 == 255 then
		del_flag( "mainquest_warp" )
	end
	
	if quest_progress2025 == 255 then
		del_flag( "hectorspawn" )
	end

	update_title_condition( 9002001, gv( "max_reached_level" ) )
	
	on_login_event()
	
end