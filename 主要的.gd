extends Node

var mod路径 = "X:\\游戏\\红警\\重聚\\RF-Client-master\\Bin\\Mod&AI\\Mod\\RA2"
var 复制的文件列表 = ["ai.ini" , "art.ini" , "rules.ini" , "credits.txt"]

var rulesmd
var rulesmd_yr
var 一次处理多少个 = 1
var 进度条 = []
var 结束 = false
var 是否自动退出 = false

func _ready () -> void :
	var image = Image.create(640, 480, false, Image.FORMAT_RGBA8)
	image.fill (Color (0,0,0,0) )
	for x in image.get_size().x :
		for y in image.get_size().y :
			if x < 2 || x > image.get_size().x - 3 || y < 2 || y > image.get_size().y - 3 :
				image.set_pixel(x , y , Color (0,0,0,1) )
			elif x < 4 || x > image.get_size().x - 5 || y < 4 || y > image.get_size().y - 5 : 
				image.set_pixel(x , y , Color (1,0,0,1) )
	var texture = ImageTexture.create_from_image(image)
	get_node("TextureRect").texture = texture

	var 退出按钮 = get_node("退出按钮")
	退出按钮.gui_input.connect(按钮点击)
	退出按钮.mouse_entered.connect(func(): 退出按钮.texture = load("res://按钮-点击.png") )
	退出按钮.mouse_exited.connect(func(): 退出按钮.texture = load("res://按钮.png") )

	for i in 7 :
		进度条.append (Vector2i (0 , 0) )
	call_deferred ("开始修改")

func _process(delta: float) -> void:
	var 进度完成 = true
	for i in 进度条 :
		if i == Vector2i (0 , 0) || (i.x / i.y) != 1.0 : 进度完成 = false
	if 进度完成 && !结束 :
		get_node("处理完成").text = "处理完成：yes"
		保存文件 ()
		结束 = true
	if !进度完成 : get_node("处理完成").text = "处理完成：no"

	显示文本进度条 (get_node("[General]") 			, "[General]处理进度：" 		, 进度条[0])
	显示文本进度条 (get_node("[Sides]") 			, "[Sides]处理进度：" 		, 进度条[1])
	显示文本进度条 (get_node("[InfantryTypes]") 	, "[InfantryTypes]处理进度："	, 进度条[2])
	显示文本进度条 (get_node("步兵") 				, "步兵处理进度：" 			, 进度条[3])
	显示文本进度条 (get_node("[BuildingTypes]") 	, "[BuildingTypes]处理进度："	, 进度条[4])
	显示文本进度条 (get_node("建筑") 				, "建筑处理进度：" 			, 进度条[5])
	显示文本进度条 (get_node("[AI]") 				, "[AI]处理进度：" 			, 进度条[6])

func 开始修改 () :
	await get_tree().process_frame
	await get_tree().process_frame

	var 配置文件 = ReadINI ("配置文件.ini" , true)

	for temp_string1 in 配置文件 :
		var temp_string1_键 = temp_string1.substr (0 , temp_string1.find ("=") )
		var temp_string1_值 = temp_string1.substr (temp_string1.find ("=") + 1)
		if temp_string1_键 == "mod路径" :
			mod路径 = temp_string1_值
		if temp_string1_键 == "复制的文件列表" :
			复制的文件列表 = temp_string1_值.split ( "," , false )
		if temp_string1_键 == "一次处理量" :
			一次处理多少个 = int (temp_string1_值)
		if temp_string1_键 == "是否自动退出" :
			temp_string1_值 = 文本变为小写字母 (temp_string1_值)
			if temp_string1_值 == "yes" || temp_string1_值 == "true" :
				是否自动退出 = true
			elif temp_string1_值 == "no" || temp_string1_值 == "false" :
				是否自动退出 = false

	while mod路径.substr (mod路径.length () - 1) == "\\" || mod路径.substr (mod路径.length () - 1) == "/" :
		mod路径 = mod路径.substr (0 , mod路径.length () - 1)

#复制文件
	for 文件名 in 复制的文件列表 :
		var 新文件名 = 文件名.substr (0 , 文件名.find (".") ) + "md" + 文件名.substr (文件名.find (".") )
		if FileAccess.file_exists (mod路径 + "\\" + 文件名) && !FileAccess.file_exists (mod路径 + "\\" + 新文件名):
			DirAccess.copy_absolute (mod路径 + "\\" + 文件名 , mod路径 + "\\" + 新文件名)

#改rules
	rulesmd = ReadINI (mod路径 + "\\rules.ini")
	rulesmd_yr = ReadINI ("res://rulesmd-yr.ini")

	处理__General_小节 ()
	var sides = 处理__Sides_小节 ()
	var 盟军所属 = sides[0]
	var 苏联所属 = sides[1]
	处理__InfantryTypes_小节__步兵_小节 (盟军所属 , 苏联所属)
	处理__BuildingTypes_小节__建筑_小节 ()
	处理__AI_小节 ()

func 保存文件 () :
	rulesmd = INI_Merge_Sections (rulesmd)
	rulesmd = rulesmd.filter (func (element) : return element != "")
	DirAccess.open(mod路径).remove("rulesmd.ini")
	var file = FileAccess.open(mod路径 + "\\rulesmd.ini", FileAccess.WRITE)
	for 当前行 in rulesmd :
		file.store_string(当前行 + "\n")
	file.close()
	print("保存文件")

	if 是否自动退出 : get_tree().quit()

#读取ini
func ReadINI (Path_ini , 是根目录 = false) :											#输入ini类型名称和ini文件位置
	if 是根目录 : Path_ini = OS.get_executable_path ().get_base_dir () + "\\" + Path_ini
	var file_ini = FileAccess.open (Path_ini , FileAccess.READ )	#读取文件
	var 临时_ini_主要的 = file_ini.get_as_text ()
	file_ini.close ()
	临时_ini_主要的 = 临时_ini_主要的.replace ("\t" , "")
	临时_ini_主要的 = 临时_ini_主要的.replace ("\r" , "")
	临时_ini_主要的 = 临时_ini_主要的.split ( "\n" , false )

	for i in 临时_ini_主要的.size () :											#删注释和空格
		var temp_str_1 = 临时_ini_主要的[i]
		if temp_str_1.find (";") != -1 :
			temp_str_1 = temp_str_1.substr (0 , temp_str_1.find (";"))

		temp_str_1 = temp_str_1.replace (" " , "")

		临时_ini_主要的[i] = temp_str_1
	for i in 临时_ini_主要的.size () :											#去掉空行
		if i > 临时_ini_主要的.size () - 1 :
			break
		if 临时_ini_主要的[i] == "" || 临时_ini_主要的[i] == "\n" || 临时_ini_主要的[i] == "\r" || 临时_ini_主要的[i] == "\r\n" || 临时_ini_主要的[i] == "\n\r" :
			临时_ini_主要的.remove_at (i)
	临时_ini_主要的 = INI_Merge_Sections (临时_ini_主要的)
	return 临时_ini_主要的

#合并ini
func INI_Merge_Sections (临时_ini_主要的) :
	var ini_小节列表 = []
	var 临时_ini_主要的_1 = 临时_ini_主要的
	临时_ini_主要的 = []
	for i in 临时_ini_主要的_1.size () :											#找到所有小节
		if 临时_ini_主要的_1[i].find("=") == -1 && 临时_ini_主要的_1[i].find("[") == 0 && 临时_ini_主要的_1[i].find("]") == 临时_ini_主要的_1[i].length() - 1 :
			if 临时_ini_主要的_1[i] != "[]" :
				ini_小节列表.append (i)

	for i in ini_小节列表.size () :
		var temp_a = ini_小节列表[i]
		if 临时_ini_主要的.find (临时_ini_主要的_1[temp_a]) == -1 :					#添加节头
			临时_ini_主要的.append (临时_ini_主要的_1[temp_a])
		var temp_b = 1
		var temp_INI_main_find = 临时_ini_主要的.find (临时_ini_主要的_1[temp_a])
		var temp_INI_main_find_1
		while true :
			if temp_INI_main_find + temp_b >= 临时_ini_主要的.size () :
				temp_INI_main_find_1 = temp_INI_main_find
				break
			elif 临时_ini_主要的[temp_INI_main_find + temp_b].find("[") != -1 :
				temp_INI_main_find_1 = temp_INI_main_find + temp_b - 1
				break
			temp_b = temp_b + 1

		temp_b = 1
		var temp_list_1 = []
		while temp_b + temp_a < 临时_ini_主要的_1.size () :
			if 临时_ini_主要的_1[temp_b + temp_a].find("[") != -1:
				break
			temp_list_1.append(临时_ini_主要的_1[temp_b + temp_a])
			temp_b = temp_b + 1
		for a in temp_list_1.size () :
			临时_ini_主要的.insert (temp_INI_main_find_1 + 1 + a , temp_list_1 [a] )

	return 临时_ini_主要的

func 显示文本进度条 (物体 , 文本 , 进度条) :
	物体.text = 文本 + str(进度条.x) + "/" + str(进度条.y)

func 文本变为小写字母 (文本) :
	文本 = 文本.replace ("A" , "a").replace ("B" , "b").replace ("C" , "c").replace ("D" , "d")
	文本 = 文本.replace ("E" , "e").replace ("F" , "f").replace ("G" , "g")
	文本 = 文本.replace ("H" , "h").replace ("I" , "i").replace ("J" , "j").replace ("K" , "k")
	文本 = 文本.replace ("L" , "l").replace ("M" , "m").replace ("N" , "n")
	文本 = 文本.replace ("O" , "o").replace ("P" , "p").replace ("Q" , "q")
	文本 = 文本.replace ("R" , "r").replace ("S" , "s").replace ("T" , "t")
	文本 = 文本.replace ("U" , "u").replace ("V" , "v").replace ("W" , "w")
	文本 = 文本.replace ("X" , "x").replace ("Y" , "y").replace ("Z" , "z")
	return 文本

func 删除小节 (小节名称) :
	rulesmd = INI_Merge_Sections (rulesmd)
	var 小节位置 = rulesmd.find ("[" + 小节名称 + "]")
	if 小节位置 == -1 : return rulesmd
	rulesmd.remove_at (小节位置)
	while 小节位置 < rulesmd.size () :
		var temp_string1 = rulesmd[小节位置]
		if temp_string1.find ("=") == - 1 && temp_string1.find ("[") != -1 :
			break
		rulesmd.remove_at (小节位置)

func 获取小节 (ini文件 , 小节名称) :
	ini文件 = INI_Merge_Sections (ini文件)
	var 小节位置 = ini文件.find ("[" + 小节名称 + "]")
	var i = 1
	var 新的小节 = []
	while 小节位置 + i < ini文件.size () :
		var temp_string1 = ini文件[小节位置 + i]
		if temp_string1.find ("=") == - 1 && temp_string1.find ("[") != -1 :
			break
		新的小节.append (temp_string1)
		i += 1
	return 新的小节

func 处理__General_小节 () :
	进度条[0] = Vector2i (0 , 2)

	删除小节 ("General")

	进度条[0] = Vector2i (1 , 2)

	var 新的小节 = 获取小节 (rulesmd_yr , "General")

	var temp_ini = []
	temp_ini.append ("[CombatDamage]")
	temp_ini.append ("OverloadCount=3,6,10,50")
	temp_ini.append ("OverloadDamage=0,50,100,500")
	temp_ini.append ("OverloadFrames=30,60,60,60")
	temp_ini.append ("ControlledAnimationType=MINDANIM")
	temp_ini.append ("PermaControlledAnimationType=MINDANIMR")
	temp_ini.append ("MindControlAttackLineFrames=20")
	rulesmd += temp_ini

	temp_ini = ["[General]"]
	temp_ini += 新的小节
	rulesmd += temp_ini

	进度条[0] = Vector2i (2 , 2)

func 处理__Sides_小节 () :
	进度条[1] = Vector2i (0 , 1)

	var 新的小节 = 获取小节 (rulesmd , "Sides")
	var sides = []

	var 临时int1 = 0
	for temp_string1 in 新的小节 :
		var temp_string1_键 = temp_string1.substr (0 , temp_string1.find ("=") )
		var temp_string1_值 = temp_string1.substr (temp_string1.find ("=") + 1)
		if temp_string1_键 != "" : 
			temp_string1_值 = 文本变为小写字母 (temp_string1_值).replace (" " , "").split ( "," , false )
			sides.append(temp_string1_值)

	进度条[1] = Vector2i (1 , 1)
	return sides

func 处理__InfantryTypes_小节__步兵_小节 (盟军所属 , 苏军所属) :
	进度条[2] = Vector2i (0 , 2)
	var 步兵注册表 = 获取小节 (rulesmd , "InfantryTypes")
	进度条[2] = Vector2i (1 , 2)

	for 序数 in 步兵注册表.size () :
		步兵注册表[序数] = 步兵注册表[序数].substr (步兵注册表[序数].find ("=") + 1)
		步兵注册表[序数] = 步兵注册表[序数].replace ("\t" , "").replace ("\r" , "")
		步兵注册表[序数] = 步兵注册表[序数].replace ("\n" , "").replace (" " , "")
	步兵注册表 = 步兵注册表.filter (func (element) : return element != "")

	进度条[2] = Vector2i (2 , 2)

	进度条[3] = Vector2i (0 , 步兵注册表.size () )
	for 步兵 in 步兵注册表 :
		var 当前步兵ini = 获取小节(rulesmd , 步兵)
		var 当前步兵可驻扎 = false
		var 当前步兵可所属 = "盟军"

		for temp_string1 in 当前步兵ini :
			var temp_string1_键 = temp_string1.substr (0 , temp_string1.find ("=") )
			var temp_string1_值 = temp_string1.substr (temp_string1.find ("=") + 1)
			temp_string1_值 = 文本变为小写字母 (temp_string1_值)
			if temp_string1_键 == "Occupier" :
				if temp_string1_值 == "yes" || temp_string1_值 == "true" :
					当前步兵可驻扎 = true
				elif temp_string1_值 == "no" || temp_string1_值 == "false" :
					当前步兵可驻扎 = false
			if temp_string1_键 == "Owner" :
				for temp_string1_值_一部分 in temp_string1_值.replace (" " , "").split ( "," , false ) :
					if 苏军所属.find (temp_string1_值_一部分) != -1 :
						当前步兵可所属 = "苏军"

		if 当前步兵可驻扎 :
			if 当前步兵可所属 == "盟军" :
				var temp_ini = []
				temp_ini.append("[" + 步兵 + "]")
				temp_ini.append("OccupyPip=PersonBlue")
				temp_ini.append("OccupyWeapon=AlliedOccupyW")
				temp_ini.append("EliteOccupyWeapon=AlliedOccupyW")
				rulesmd += temp_ini
			else :
				var temp_ini = []
				temp_ini.append("[" + 步兵 + "]")
				temp_ini.append("OccupyPip=PersonRed")
				temp_ini.append("OccupyWeapon=SovietOccupyW")
				temp_ini.append("EliteOccupyWeapon=SovietOccupyW")
				rulesmd += temp_ini

		if 进度条[3].x % 一次处理多少个 == 0 :
			await get_tree().process_frame
		进度条[3] = Vector2i (进度条[3].x + 1 , 步兵注册表.size () )

func 处理__BuildingTypes_小节__建筑_小节 () :
	进度条[4] = Vector2i (0 , 2)
	var 建筑注册表 = 获取小节 (rulesmd , "BuildingTypes")
	进度条[4] = Vector2i (1 , 2)

	for 序数 in 建筑注册表.size () :
		建筑注册表[序数] = 建筑注册表[序数].substr (建筑注册表[序数].find ("=") + 1)
		建筑注册表[序数] = 建筑注册表[序数].replace ("\t" , "").replace ("\r" , "")
		建筑注册表[序数] = 建筑注册表[序数].replace ("\n" , "").replace (" " , "")
	建筑注册表 = 建筑注册表.filter (func (element) : return element != "")
	进度条[4] = Vector2i (2 , 2)

	进度条[5] = Vector2i (0 , 建筑注册表.size () )
	for 建筑 in 建筑注册表 :
		var 当前建筑ini = 获取小节(rulesmd , 建筑)
		var 当前建筑可驻扎步兵 = false
		var 当前建筑是克隆缸 = false

		for temp_string1 in 当前建筑ini :
			var temp_string1_键 = temp_string1.substr (0 , temp_string1.find ("=") )
			var temp_string1_值 = temp_string1.substr (temp_string1.find ("=") + 1)
			temp_string1_值 = 文本变为小写字母 (temp_string1_值)
			if temp_string1_键 == "CanBeOccupied" :
				if temp_string1_值 == "yes" || temp_string1_值 == "true" :
					当前建筑可驻扎步兵 = true
				elif temp_string1_值 == "no" || temp_string1_值 == "false" :
					当前建筑可驻扎步兵 = false
			if temp_string1_键 == "Cloning" :
				if temp_string1_值 == "yes" || temp_string1_值 == "true" :
					当前建筑是克隆缸 = true
				elif temp_string1_值 == "no" || temp_string1_值 == "false" :
					当前建筑是克隆缸 = false

		if 当前建筑可驻扎步兵 :
			var temp_ini = []
			temp_ini.append ("[" + 建筑 + "]")
			temp_ini.append ("Primary=")
			temp_ini.append ("Secondary=")
			temp_ini.append ("CanOccupyFire=yes")
			rulesmd += temp_ini
		if 当前建筑是克隆缸 :
			var temp_ini = []
			temp_ini.append ("[" + 建筑 + "]")
			temp_ini.append ("Grinding=yes")
			temp_ini.append ("UnitAbsorb=no")
			temp_ini.append ("InfantryAbsorb=yes")
			rulesmd += temp_ini

		if 进度条[5].x % 一次处理多少个 == 0 :
			await get_tree().process_frame
		进度条[5] = Vector2i (进度条[5].x + 1 , 建筑注册表.size () )

func 处理__AI_小节 () :
	进度条[6] = Vector2i (0 , 4)
	var AI_小节 = 获取小节 (rulesmd , "AI")
	进度条[6] = Vector2i (1 , 4)
	for 序数 in AI_小节.size () :
		AI_小节[序数] = AI_小节[序数].replace ("\t" , "").replace ("\r" , "")
		AI_小节[序数] = AI_小节[序数].replace ("\n" , "").replace (" " , "")
	AI_小节 = AI_小节.filter (func (element) : return element != "")
	进度条[6] = Vector2i (2 , 4)

	var AlliedBaseDefenses = ""
	var SovietBaseDefenses = ""
	for temp_string1 in AI_小节 :
		var temp_string1_键 = temp_string1.substr (0 , temp_string1.find ("=") )
		var temp_string1_值 = temp_string1.substr (temp_string1.find ("=") + 1)
		if temp_string1_键 == "BuildDummy" || temp_string1_键 == "BuildDefense" || temp_string1_键 == "BuildPDefense" || temp_string1_键 == "BuildAA" :
			var temp_ini = temp_string1_值.split ( "," , false )
			for i in temp_ini.size () :
				if i == 0 :
					AlliedBaseDefenses += temp_ini[0]
					AlliedBaseDefenses += ","
				else :
					SovietBaseDefenses += temp_ini[i]
					SovietBaseDefenses += ","
	进度条[6] = Vector2i (3 , 4)

	var temp_ini = []
	temp_ini.append ("[AI]")
	temp_ini.append ("AlliedBaseDefenses=" + AlliedBaseDefenses)
	temp_ini.append ("SovietBaseDefenses=" + SovietBaseDefenses)
	temp_ini.append ("AIForcePredictionFudge=5,25,80")

	rulesmd += temp_ini
	进度条[6] = Vector2i (4 , 4)

func 按钮点击(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_tree().quit()
