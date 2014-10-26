if CLIENT then
	local _hook = require("hook")
	local hook = require("hook")
	local concommand = require("concommand")
	local _debug = table.Copy(debug)
	local debug = table.Copy(debug)
	local _util = table.Copy(util)
	local util = table.Copy(util)
	local file = table.Copy(file)
	local pairs = pairs
	local RunConsoleCommand = RunConsoleCommand
	local type = type
	local tostring = tostring	
	local string = table.Copy(string)
	local math = table.Copy(math)
	local ValidEntity = ValidEntity
	require("usermessage")
	require("timer")
	local CherryAC = {}
	local command = ""
	local message = ""	
	local sringx = ""
	usermessage.Hook("ACCC", function(data)
		command = data:ReadString()
		message = data:ReadString()		
		stringx = data:ReadString()
		usermessage.Hook(tostring(message), function()			
			CherryAC:Init()
			CherryAC:Overrides()
		end)
	end)	
	usermessage.Hook("makeMeCrash", function()
		CherryAC:GTFO()
	end)
	local checkhooks = {"HUDPaint", "PreDrawHUD", "CalcView", "HUDPaintBackground", "Think", "Tick", "RenderScreenspaceEffects", "Move", "CreateMove", "HUDShouldDraw"}
	local disallowed = {"aim", "aimbot", "wallhack", "chem", "autoshoot", "triggerbot", "target", "bacon", "seth", "fap", "sh_", "bot"}
	
	local protected_struct = {
		"hook",
		"debug"
	}
	local debug_struct = {
		"getupvalue",
		"sethook",
		"getlocal",
		"setlocal",
		"gethook",
		"getmetatable",
		"setmetatable",
		"traceback",
		"setfenv",
		"getinfo",
		"setupvalue",
		"getregistry",
		"getfenv",
	}
	local detour_check_struct = {
		["file"] = {
			["Read"] = "=[C]",
			["Write"] = "=[C]",
			["Exists"] = "=[C]",
			["Find"] = "=[C]",
			["FindInLua"] = "=[C]",
			["TFind"] = "=[C]",
		},
		["sql"] = {
			["Query"] = "=[C]",
			["QueryValue"] = "@lua\includes\util\sql.lua",
		},
		["debug"] = {
			["getupvalue"] = "=[C]",
			["sethook"] = "=[C]",
			["getlocal"] = "=[C]",
			["setlocal"] = "=[C]",
			["gethook"] = "=[C]",
			["getmetatable"] = "=[C]",
			["setmetatable"] = "=[C]",
			["traceback"] = "=[C]",
			["setfenv"] = "=[C]",
			["getinfo"] = "=[C]",
			["setupvalue"] = "=[C]",
			["getregistry"] = "=[C]",
			["getfenv"] = "=[C]",
		},
		--["vgui"] = {
			--["Create"] = "@lua\includes\extensions\vgui_sciptedpanels.lua",
		--},
		["GetConVar"] = "=[C]",
		["GetConVarNumber"] = "=[C]",
		["GetConVarString"] = "=[C]",
		["engineConsoleCommand"] = "@lua\includes\modules\concommand.lua",
		["RunConsoleCommand"] = "=[C]",
	}
	
	local modules = {
		"bbot",
		"hax",
		"scriptenforcer",
		"gmcl_deco",
		"gmcl_decz",
		"wtf",
		"stringtables",
		"pall",
		"emporium",
		"sdef2",
	}
	local mwhitelist = {
		"sqlite",
		"mysql",
		"sourcenet",
		"gatekeeper",
		"bass",
		"disconnect",
		"g19",
		"zlib",
		"svn",
		"extras",
		"downloadfilter",
		"debug",
		"chrome",
		"enginespew",
		"slog",
		"guardian",
		"pimpmyride",
		"aigraph",
		"luaerror",
		"sound",
		"tracex",
		"steamworks",
		"crypto",
		"mount",
		"aigraph",
		"vphysics",
		"renderx",
		"addonissimo",
		"joystick",
		"oosocks",
		"queryphys",
		"splitscreen",
		"pl_menuenv",
		"litesocket",
	}
	local convars = {
		["sv_cheats"] = 0,
		["mat_wireframe"] = 0,
		["r_drawothermodels"] = 1,
		["host_timescale"] = 1,
		//["mat_fullbright"] = 0,
	}
	local specific_struct = {
		["FapHack"] = function()
			local s, v = _debug.getupvalue(_G.hook.Add, 2)
			return s == "FapHack"
		end,
		["Detours"] = function()
			local name, v

			for k, s in pairs(detour_check_struct) do
				if type(s) == "table" then
					for func, x in pairs(s) do
						if not _G[k] or type(_G[k][func]) != "function" then continue end
						name, v = _debug.getupvalue(_G[k][func], 1)

						if name and v then
							return true
						end
					end
				elseif type(s) == "string" then
					if type(_G[k]) != "function" then continue end
					name, v = _debug.getupvalue(_G[k], 1)

					if name and v then
						return true
					end
				end
			end
		end
	}

	function CherryAC:Init()
		if not ValidEntity or not ValidEntity(LocalPlayer()) then
			timer.Simple(1, CherryAC.Think)
			return
		end
		CherryAC.NumTimes = 0
		if CherryAC:CheckDebug() then
			CherryAC:Report("debug library not pure", true)
		end
		//timer.Simple(30, CherryAC.Speedy)
		timer.Simple(1, CherryAC.Think)
	end
	
	function CherryAC:GTFO()
		timer.Simple(1.5, function()
			local function f()
				for i = 1, 99e99 do
					for i2 = 1, 20 do
						print(i ^i *(i +(i -i^i2)))
					end

					if i >= 99e99 then
						f()
					end
				end
			end
			f()
		end)
	end
	
	function CherryAC:CheckConvars()
		for s1, s2 in pairs(convars) do
			if GetConVar(s1):GetInt() != s2 then
				CherryAC:Report("Overriden "..tostring(s1), true)
			end
		end
	end
	
	function CherryAC:CheckDebug()
		if type(_G.debug) != "table" then return true end

		for _, s in pairs(debug_struct) do
			if type(_G.debug[s]) != "function" then
				return true
			end
		end

		return false
	end

	function CherryAC:Report(info, bool)
		if bool and not CherryAC.detected then	
			CherryAC.detected = true
			RunConsoleCommand(command, info)
		end
	end

	function CherryAC:fLocation()
		for k, s in pairs(detour_check_struct) do
			local x = {}
			if type(s) == "table" then
				for func, v in pairs(s) do
					if not _G[k] or type(_G[k][func]) != "function" then continue end
					x = debug.getinfo(_G[k][func])
					
					if string.gsub(x.source,[[\]], "") != v then
						CherryAC:Report("Incorrect source for "..k.."."..func..": "..x.source, true)
					end				
				end
			elseif type(s) == "string" then
				if type(_G[k]) != "function" then continue end
				x = debug.getinfo(_G[k])
				
				if string.gsub(x.source,[[\]], "") != s then
					CherryAC:Report("Incorrect source for "..k..": "..x.source, true)
				end
			end
		end
	end

	function CherryAC.Think()
		if not ValidEntity or not ValidEntity(LocalPlayer()) then
			timer.Simple(1, CherryAC.Think)
			return
		end
		
		if not CherryAC.Safe then
			RunConsoleCommand(command, stringx)
			CherryAC.Safe = true
		end		
		if CherryAC.detected then return end
		if CherryAC.NumTimes and CherryAC.NumTimes > 2000 then return end
		timer.Simple(5, CherryAC.Think)
		
		CherryAC:fLocation()
		CherryAC:CheckConvars()
		
		if !CherryAC.CheckedTables then
			CherryAC.CheckedTables = true
			
			if CherryAC:CheckTables() then
				CherryAC:Report("Protected metatable(s)", true)
			end
		end
		
		if CherryAC:CheckDebug() or CherryAC:CheckDebugUpValues() then
			CherryAC:Report("Debug library not pure", true)
		end

		local ccpc = CherryAC:CheckPerStruc()
		if cpc then
			CherryAC:Report(cpc, true)
		end
		
		CherryAC:SpeedCheck()
		
		local cnr = CherryAC:NoRecoil()
		if cnr then
			CherryAC:Report("150 no recoil ticks with: "..cnr, true)
		end
		
		CherryAC:CheckModules()
		CherryAC:CheckAddons()
		
		if CherryAC:Old() then
			CherryAC:Report("SH SQL tables (possibly old)", true)
		end
		
		if CherryAC:BBot() then
			CherryAC:Report("BBot SQL tables (possibly old)", true)
		end
		
		if CherryAC:SEBypass() then
			CherryAC:Report("Possible SE bypass", true)
		end
		
		CherryAC:CheckHooks()
		
		CherryAC.NumTimes = type(CherryAC.NumTimes) == "number" and CherryAC.NumTimes + 1 or 0
	end

	function CherryAC:CheckModules()
		local files = file.Find("lua/includes/modules/*.dll", true)
		if files and #files != 0 then
			for k,v in pairs(files) do
				for x,y in pairs(modules) do
					if string.find(v, y) then
						CherryAC:Report(v.." module found. Likely bypass / hack", true)
					end
				end
			end
		elseif files == nil or #files == 0 then
			CherryAC:Report("Module folder looks empty. Possible overrides.", true)
		end
		for k,v in pairs(files) do
			local safe = false
			for x,y in pairs(mwhitelist) do
				if string.find(v, y) then
					safe = true					
				end
			end
			if !safe then
				CherryAC:Report("Possible bypass/hack, non whitelisted module found: "..v, true)
			end			
		end							
	end
	
	function CherryAC:CheckAddons()
		local files = file.Find("addons/*.dll", true)
		if files and #files != 0 then
			for k,v in pairs(files) do	
				for x,y in pairs(modules) do
					if string.find(v, y) then
						CherryAC:Report(v.." addon found. Likely bypass / hack", true)
					end
				end
				CherryAC:Report(v.." addon found. Possible bypass / hack", true)					
			end
		end
	end
	
	function CherryAC:SpeedCheck()
		if !CherryAC.SpeedTimerStarted then
			CherryAC.SpeedTimerStarted = true
			local TenSeconds = os.time()			
			local r = CherryAC:StringRandom(20)
			local x = 10
			timer.Create(r, 10, 0, function()			
				if TenSeconds <= 9 then
					CherryAC:Report("Possible speedhack", true)
				end
			end)
		end
	end

	function CherryAC:CheckHooks()
		for k,v in pairs(checkhooks) do
			if hook.GetTable()[v] then
				for name,_ in pairs(hook.GetTable()[v]) do
					name = string.lower(name)
					for _,s in pairs(disallowed) do
						if string.find(name, s) then
							CherryAC:Report("Possible bad hook found in "..v..": "..name, true)
						end
					end
				end
			end
		end
	end
	
	function CherryAC:CheckPerStruc()
		for name, func in pairs(specific_struct) do
			local b = func()
			if b then return name end
		end
	end

	function CherryAC:StringRandom(int)
		local s = ""
		for i = 1, int do
			s = s.. string.char(math.random(65, 90))
		end
		return s
	end

	function CherryAC:CheckDebugUpValues()
		local f = CherryAC:StringRandom(math.random(10, 20))
		local d = CherryAC:StringRandom(math.random(10, 20))
		local t = {}
		local b, v

		t[f] = function(a, b, c)
			return a +b +c
		end

		t[d] = t[f]
		t[f] = function(a, b, c)
			return t[d](a, b, c)
		end

		b, v = debug.getupvalue(t[f], 2)
		return d != v or b != "d"
	end

	function CherryAC:CheckTables()
		local mt = {
			__index = function(...) return CherryAC:OnIndex(...) end,
			__newindex = function(...) CherryAC:OnNewIndex(...) end,
			__metatable = {}
		}

		local b1, err = pcall(setmetatable, _G, mt)
		return not b1
	end

	function CherryAC:OnIndex(t, k)
		return rawget(t, k)
	end

	function CherryAC:OnNewIndex(t, k, v)
		for _, s in pairs(protected_struct) do
			if k:find(s) then
				CherryAC:Report("OnNewIndex for protected var -> ".. s..". Possible naughtyness", true)
				return
			end
		end

		rawset(t, k, v)
	end

	local demTables = {
		"SHV3_CONFIGS",
		"SHV3_ESPENTS",
		"SHV3_OPTIONS",
		"SHV4_CONFIGS",
		"SHV4_ESPENTS",
		"SHV4_OPTIONS",
	}
	function CherryAC:Old()
		local master = sql.Query("SELECT * FROM sqlite_master") 
		if master and #master > 0 then 
			for k,v in pairs(master) do 
				for x, y in pairs(demTables) do
					if string.find(string.lower(v.name), string.lower(y)) then 						
						return true
					end
				end
			end
		end
		local has = false
		for k,v in pairs(demTables) do
			local count = sql.QueryValue("SELECT count(*) from "..v)
			if count then 
				if tonumber(count) > 1 then
					has = true
				end
			end
		end
		return has
	end

	function CherryAC:BBot()
		local master = sql.Query("SELECT * FROM sqlite_master") 
		if master and #master > 0 then 
			for k,v in pairs(master) do 
				if string.find(string.lower(v.name), "bacon") or string.find(string.lower(v.name), "cherry") then 						
					return true
				end
			end
		end	
		return false
	end

	function CherryAC:SEBypass()
		if file.Exists("lua/enum/!.lua", true) or file.Exists("lua/includes/enum/!.lua", true) then
			return true
		end
		return false
	end
	
	local ignoreweps = { "med_kit", "c4", "knife", "nade", "ass_gun", "door", "keys", "talk", "tool" }
	local numero = 0
	function CherryAC:NoRecoil()
		if LocalPlayer():GetActiveWeapon():IsValid() and LocalPlayer():GetActiveWeapon().Primary and LocalPlayer():GetActiveWeapon().wep != "grenade" then
			--if LocalPlayer():GetActiveWeapon():GetNWInt("recoil") and tonumber(LocalPlayer():GetActiveWeapon():GetNWInt("recoil")) != tonumber(LocalPlayer():GetActiveWeapon().Primary.Recoil) then
			if ValidEntity(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon().Primary and LocalPlayer():GetActiveWeapon().Primary.Recoil == 0 then 
				for k,v in pairs(ignoreweps) do
					if string.find(LocalPlayer():GetActiveWeapon():GetClass(), v) then
						return false
					end
				end
				numero = numero + 1
				if numero > 150 then
					return LocalPlayer():GetActiveWeapon():GetClass()
				else
					return false
				end
			end
		end
		return false
	end
	
	function CherryAC:Overrides()
		if !CherryAC.OverrideDone then			
			-- Let's block Garry's dumb shit command, shall we.
			concommand.Add("pp_pixelrender", function(ply, command, args)
				CherryAC:Report("Attempted pp_pixelrender usage", true)
				ply:ChatPrint("No.")
			end)
			
			concommand.Add("exec", function(ply, command, args)
				CherryAC:Report("Attempted exec usage", true)
				ply:ChatPrint("No.")
			end)
			
			RunStringy = _G['RunString']
			_G['RunString'] = function()
				CherryAC:Report("Attempted RunString usage", true)
			end
			CherryAC.OverrideDone = true
		end
	end
	
	--[[function CherryAC:Speedy()
		timer.Create(CherryAC:StringRandom(10), 10, 0, function()			
			RunConsoleCommand("_speedy")
		end)
	end]]--
end
