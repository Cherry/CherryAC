if !SERVER then return end
AddCSLuaFile("autorun/client/pingy_cl.lua")
require("mysqloo")

allowedPeople = {
	-- steamids - yes I'm a hyprocrite
}

 
local CONNECTED_TO_MYSQL = false

local DATABASE_HOST = "x"
local DATABASE_PORT = 3306
local DATABASE_NAME = "x"
local DATABASE_USERNAME = "x"
local DATABASE_PASSWORD = "x"

local ADB = {}
ADB.privcache = {}

ADB.MySQLDB = nil

function ADB.Query(query, callback)
	if CONNECTED_TO_MYSQL then 
		if ADB.MySQLDB and ADB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED then
			ADB.ConnectToMySQL(DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_NAME, DATABASE_PORT)
		end
		local query = ADB.MySQLDB:query(query)
		local data
		query.onData = function(Q, D)
			data = data or {}
			table.insert(data, D)
		end
		
		query.onError = function(Q, E) ADB.Log("MySQL Error: ".. E) Error("MySQL Error: ".. E) callback() end
		query.onSuccess = function()
			if callback then callback(data) end 
		end
		query:start()
		return
	end
end

function ADB.QueryValue(query, callback)
	if CONNECTED_TO_MYSQL then 
		if ADB.MySQLDB and ADB.MySQLDB:status() == mysqloo.DATABASE_NOT_CONNECTED then
 			ADB.ConnectToMySQL(DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_NAME, DATABASE_PORT)
 		end
		local query = ADB.MySQLDB:query(query)
		local data
		query.onData = function(Q, D)
			data = D
		end
		query.onSuccess = function()
			for k,v in pairs(data or {}) do
				callback(v)
				return
			end
			callback()
		end
		query.onError = function(Q, E) ADB.Log("MySQL Error: ".. E) Error("MySQL Error: ".. E) callback() end
		query:start()
		return
	end
end

function ADB.ConnectToMySQL(host, username, password, database_name, database_port)
	if not mysqloo then ADB.Log("MySQL Error: MySQL modules aren't installed properly!") Error("MySQL modules aren't installed properly!") end
	local databaseObject = mysqloo.connect(host, username, password, database_name, database_port)
	
	databaseObject.onConnectionFailed = function(msg)
		ADB.Log("MySQL Error: Connection failed! "..tostring(msg))
		Error("Connection failed! " ..tostring(msg))		
	end
	
	databaseObject.onConnected = function()
		CONNECTED_TO_MYSQL = true
	end
	databaseObject:connect() 
	ADB.MySQLDB = databaseObject
end

function ADB.Log(text, force)
	if not text and not force then return end
	if not ADB.File then -- The log file of this session, if it's not there then make it!
		if not file.IsDir("ACSQL_logs") then
			file.CreateDir("ACSQL_logs")
		end
		ADB.File = "ACSQL_logs/"..os.date("%m_%d_%Y")..".txt"
	end
	file.Append(ADB.File, os.date().. "\t"..(text or "").."\n")
end

hook.Add("InitPostEntity", "ACMYSQLCONNECT", function()
	ADB.ConnectToMySQL(DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_NAME, DATABASE_PORT) 
end)

-- Random string generation
local function StringRandom(int)
	math.randomseed(os.time())
	local s = ""
	for i = 1, int do
		s = s..string.char(math.random(65, 90))
	end
	return s
end

-- Generating 4 random strings for use in the general command, umsg, safe command and the handshake command
local command = StringRandom(math.random(10,20))
local message = StringRandom(math.random(10,20))
local stringx = StringRandom(math.random(10,20))
local handshake = StringRandom(math.random(10,20))
ServerLog(string.format("%s + %s + %s + %s", command, message, stringx, handshake).."\n")
-- Log these (really for my benefit when I reload the script and want to do testing)

local bannable = {
	["faphack"] = "FapHack",
	["integra"] = "Integra Hack",
	--["pixelrender"] = "Attempting pp_pixelrender",
}
-- Easy player function to record as cheater
function _R.Player:RecordCheater(args)
	if self:IsValid() and !table.HasValue(allowedPeople, self:SteamID()) and !self.Hacker then			
		self.acArgs = (type(args) == "table" and table.concat(args, " ")) or tostring(args)
		local rank = (_R.Player.GetLevel and LevelToString(self:GetLevel())) or "N/A"
		local name = (_R.Player.SteamName and self:SteamName().." ["..self:Nick().."]") or self:Name()
		if !self.numDetect then
			self.numDetect = 0				
			ADB.Query(string.format("INSERT INTO detections VALUES(%s, %q, %q, 1, NOW(), %s, %q, %q)", sql.SQLStr(name), self:SteamID(), self:IPAddress(), sql.SQLStr(GetHostName()), self.acArgs, rank))		
		else
			ADB.Query(string.format("UPDATE detections SET name = %s, ip = %q, detections = detections + 1, lasttime = NOW(), server = %q, reason = %q, rank = %q WHERE steamid = %q", sql.SQLStr(name), self:IPAddress(), GetHostName(), self.acArgs, rank, self:SteamID()))
		end
		self.numDetect = self.numDetect + 1
		self.Hacker = true
		for k,v in pairs(bannable) do
			if string.find(string.lower(self.acArgs), string.lower(k)) then
				sourcebans.BanPlayerBySteamID(self:SteamID(), 0, v, Entity(0), name)				
			end
		end
	end
end

-- For dicks.
function _R.Player:goBoom()
	if self:IsValid() and !table.HasValue(allowedPeople, self:SteamID()) then
		umsg.Start("makeMeCrash", self)
		umsg.End()
		timer.Simple(2, function() -- Let's make sure they haven't blocked that umsg
			if self:IsValid() then
				self:SendLua([[ table.Emtpy(_R) ]])
				self:Remove() -- Just incase, we'll fuck them up and remove their player ent
			end
		end)		
	end
end

-- Asks for handshake. Sends the random strings for the command, etc, and then sends the random generated umsg string to start the AC going
function _R.Player:requestResponse()
	self:ConCommand(handshake)
	self:ConCommand(command.." "..stringx)
	umsg.Start("ACCC", self)
		umsg.String(command)
		umsg.String(message)
		umsg.String(stringx)
	umsg.End()				
	umsg.Start(message, self)
	umsg.End()
end

-- The actual AC command
concommand.Add(command, function(ply, command, args)
	if ply:IsValid() and !table.HasValue(allowedPeople, ply:SteamID()) and !ply.Hacker then	
		if tostring(args[1]) == tostring(stringx) then -- Is the arguments they entered the same as the safe command string?
			if !ply.Safe then 				
				ply.Safe = true -- Mark them as "safe", as the command isn't blocked.
				ServerLog(ply:Name().." is safe.\n") 
			end
			return 
		else
			ply:RecordCheater(args) -- Else we'll record them as a cheater, with the command arguments.
		end
	end
end)

-- Handshake command - ensures player is actually connected and didn't time out.
concommand.Add(handshake, function(ply, command, args)
	if ply:IsValid() and !ply.isActive then
		ply.isActive = true -- Mark them as active, so we know now that if they don't respond with the safe command string, something is up.
		ServerLog(ply:Name().." is active.\n")
	end
end)

-- Not sure we need to do this, but why not. Once it's done one cycle and they're detected, they'll be ignored on both client and server anyway.
timer.Create("AntiCheat", 120, 0, function()
	for k,v in pairs(player.GetAll()) do
		if ValidEntity(v) then
			umsg.Start(message, v)
			umsg.End()
		end
	end
end)

concommand.Add("_speedy", function(ply, command, args)
	if ply:IsValid() then		
		if ply.speedy then
			if ply:IsLevelFourAdmin() then ply:ChatPrint("Checking time") end
			local x = CurTime() - ply.speedy
			if ply:IsLevelFourAdmin() then ply:ChatPrint("Difference = "..x) end
			if x <= 9 then
				if ply:IsLevelFourAdmin() then ply:ChatPrint("Bad time offset - "..x) end
				ply:RecordCheater("Possible speedhack - difference of " .. x)
			end
		end
		ply.speedy = CurTime()
		if ply:IsLevelFourAdmin() then ply:ChatPrint("Current time set - "..ply.speedy) end
	end
end)

-- Reason used for the no command response
local timeReason = "Invalid, late, or no command response. Possible blocked concommand"

timer.Simple(1, function() -- I hate DarkRP.
	hook.Add("PlayerInitialSpawn", "ACInitialise", function(ply)
		-- Let's see if they've been detected before, and append how many times to their player ent.
		ADB.QueryValue("SELECT detections from detections where steamid = "..sql.SQLStr(ply:SteamID()), function(result)		
			if !ply:IsValid() then return end
			if result then
				ply.numDetect = tonumber(result) 
			end			
		end)
		ply.Safe = false
		-- Request first response
		ply:requestResponse()
		-- Let's request another after 1 second
		timer.Simple(1, function()
			if ply:IsValid() then
				ply:requestResponse()
			end
		end)
		-- Let's just be totally sure they got the first two.
		timer.Simple(5, function()
			if ply:IsValid() then
				ply:requestResponse()
			end
		end)
		timer.Simple(180, function()
			if !ply:IsValid() then return end
			ply:requestResponse()
			-- They've had more than enough chances now, so we'll mark them as a possible cheater			
			timer.Simple(2, function() 
				if !ply:IsValid() then return end
				if !ply.Safe then
					if ply.isActive then 
						ply:RecordCheater(timeReason) 
					else
						ply:goBoom()
					end
				end
			end)
		end)
	end)
end)
