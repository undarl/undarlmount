--Slash handler
SLASH_UMT1 = "/umt"

--Initialize the mount table and Saved Lists
local MountTable = {}
UMTflying = {}
UMTground = {}
UMTdragride = {}
FlightAchieves = {} -- flight unlock achievements true/false {draenor,legion)

--INITIALIZATION--
local function UMT_Init()

	--Only run if MountTable has not been built
	if MountTable[1] then return end

	--print("UMT_Init running...") --Debug text

	--Create the mount table, storing mount names and faction limitations
	for _,mountid in ipairs(C_MountJournal.GetMountIDs()) do
		mname,_,_,_,_,_,_,_,fac = C_MountJournal.GetMountInfoByID(mountid)
		tinsert(MountTable, {mname,fac,mountid})
	end

	--Find and save flight achievement status
	_,_,_,hasdraenor = GetAchievementInfo(10018)
	_,_,_,haslegion = GetAchievementInfo(11446)
	FlightAchieves = {hasdraenor, haslegion}

end

--CHECK FOR TRICKSY NO-FLY ZONES
local function UMT_FlyLockCheck()

	local flylock = false

	--Flying achievement checks
	--if C_Map.GetBestMapForUnit("player") == 7 and not FlightAchieves[1] then
	--	flylock = true -- Draenor
	--elseif GetCurrentMapContinent() == 8 and not FlightAchieves[2] then
	--	flylock = true -- Broken Isles
	--elseif GetCurrentMapContinent() == -1 then
	--	flylock = true -- Weird places
	--end

	return flylock
end

--SELECT AND SUMMON THE MOUNT
local function UMT_Mount()

	--print("Mount Table Item 1: " .. MountTable[1][1]) --Debug text

	--Quick dismount if mounted
	if IsMounted() then
		Dismount()
		return
	end

	--Initialize the Mount Table if needed
	UMT_Init()

	--Initialize some variables
	local cind, mountname, mountid
	local cfac = UnitFactionGroup("player")
	local vjmaps = {201,203,204,205}
	local dragridecontinents = {"Dragon Isles"}

	--print(cfac) --Debug text

	--Choose a mount
	if tContains(vjmaps, C_Map.GetBestMapForUnit("player")) and IsSwimming() then
		--Are we in Vashj'ir and in water? If so, mount the seahorse.
		mountname = "Vashj'ir Seahorse"
	--If we're in a dragonriding area, do that
	elseif tContains(dragridecontinents, tostring(getContinent(false))) then
		if UMTdragride[1] then
			mountname = UMTdragride[random(#(UMTdragride))]
			--print(mountname) --Debug text
		else
			print("No dragonriding mounts have been added.")
    end
	--If we're in a flyable and not achievement-locked area and are high enough level to fly, then let's do that
	elseif IsFlyableArea() and not UMT_FlyLockCheck() and UnitLevel("player") >= 30 then
    if UMTflying[1] then
		  mountname = UMTflying[random(#(UMTflying))]
    else
      print("No flying mounts have been added.")
    end
	else
    if UMTground[1] then
		  mountname = UMTground[random(#(UMTground))]
    else
      print("No ground mounts have been added.")
    end
	end

	--print(mountname) --Debug text

	--Use the chosen mount's name to look up its ID in the mount table
	for _,entry in ipairs(MountTable) do
		if entry[1] == mountname then

			--print(index .. " " .. tostring(entry[2])) --Debug text

			-- Check for faction limitations
			if entry[2] == nil then
				mountid = entry[3]
				break
			elseif entry[2] == 0 and cfac == "Horde" then
				mountid = entry[3]
				break
			elseif entry[2] == 1 and cfac == "Alliance" then
				mountid = entry[3]
				break
			end
		end
	end

	--print(tostring(mountid)) --Debug text

	--Summon the mount
	C_MountJournal.SummonByID(mountid)
end

function getContinent(feedback)
    local mapID = C_Map.GetBestMapForUnit("player")
    if(mapID) then
			local info = C_Map.GetMapInfo(mapID)
            if(info) then
                while(info['mapType'] and info['mapType'] > 2) do
                    info = C_Map.GetMapInfo(info['parentMapID'])
                end
                if(info['mapType'] == 2) then
                		if feedback == true then
                	  	print(info['name'] .. " (" .. tostring(info['mapID'] .. ")"))
                	  else
                	  	return info['name']
                	  end
                end
            end
        end
    end

--Slash commands
function SlashCmdList.UMT(msg, editbox)

	local command, rest = msg:match("^(%S*)%s*(.-)$")
	-- Any leading non-whitespace is captured into command;
	-- the rest (minus leading whitespace) is captured into rest.

	if command == "mount" then
		--Run the mount command
		UMT_Mount()

	elseif command == "testmap" then
		getContinent(true)

	elseif command == "worgen" then
		--If we're in a no-fly area, do nothing
		if not IsFlyableArea() or UMT_FlyLockCheck() then
			--print("Worgen ground mode -- do nothing.") --Debug text
		--Otherwise run the mount logic as usual
		else
			--print("Worgen fly mode -- running.") -- Debug text
			UMT_Mount()
		end

	elseif command == "list" then
		local flystring = ""
		--Build pretty list of flying mounts
		if UMTflying[1] then
			for iter = 1, #(UMTflying) do
				flystring = flystring .. UMTflying[iter]
				if iter == #(UMTflying) then
					flystring = flystring .. "."
				else
					flystring = flystring .. ", "
				end
			end
		else
			flystring = "You have no flying mounts listed."
		end

		local groundstring = ""
		--Build pretty list of ground mounts
		if UMTground[1] then
			for iter = 1, #(UMTground) do
				groundstring = groundstring .. UMTground[iter]
				if iter == #(UMTground) then
					groundstring = groundstring .. "."
				else
					groundstring = groundstring .. ", "
				end
			end
		else
			groundstring = "You have no ground mounts listed."
		end

		local dragstring = ""
		--Build pretty list of dragonriding mounts
		if UMTdragride[1] then
			for iter = 1, #(UMTdragride) do
				dragstring = dragstring .. UMTdragride[iter]
				if iter == #(UMTdragride) then
					dragstring = dragstring .. "."
				else
					dragstring = dragstring .. ", "
				end
			end
		else
			dragstring = "You have no dragonriding mounts listed."
		end
		--Display lists
		print("|cffffff78Flying Mounts:|r " .. flystring)
		print("|cffffff78Ground Mounts:|r " .. groundstring)
		print("|cffffff78Dragonriding Mounts:|r " .. dragstring)

	elseif command == "addfly" and rest ~= "" then
		local found
		--Initialize the Mount Table if needed
		UMT_Init()
		--Check for valid mount, add if so
		for _,entry in ipairs(MountTable) do
			if entry[1] == rest then
				found = true
				break
			end
		end
		if found then
			tinsert(UMTflying, rest)
			sort(UMTflying)
			print("Mount \"" .. rest .. "\" added to random flying mount list.")
		else
			print("\"" .. rest .. "\" was not found in the mount journal.")
		end

	elseif command == "delfly" and rest ~= "" then
		local mind
		--Look for mount in the player's random mount table
		for index, entry in ipairs(UMTflying) do
			if entry == rest then
				mind = index
				break
			end
		end
		--Remove the mount if present
		if mind then
			tremove(UMTflying, mind)
			print("Mount \"" .. rest .. "\" removed from random flying mount list.")
		else
			print("\"" .. rest .. "\" was not found in the random flying mount list.")
		end

	elseif command == "addground" and rest ~= "" then
		local found
		--Initialize the Mount Table if needed
		UMT_Init()
		--Check for valid mount, add if so
		for _,entry in ipairs(MountTable) do
			if entry[1] == rest then
				found = true
				break
			end
		end
		if found then
			tinsert(UMTground, rest)
			sort(UMTground)
			print("Mount \"" .. rest .. "\" added to random ground mount list.")
		else
			print("\"" .. rest .. "\" was not found in the mount journal.")
		end

	elseif command == "delground" and rest ~= "" then
		local mind
		--Look for mount in the player's random mount table
		for index, entry in ipairs(UMTground) do
			if entry == rest then
				mind = index
				break
			end
		end
		--Remove the mount if present
		if mind then
			tremove(UMTground, mind)
			print("Mount \"" .. rest .. "\" removed from random ground mount list.")
		else
			print("\"" .. rest .. "\" was not found in the random mount list.")
		end

	elseif command == "adddrag" and rest ~= "" then
		local found
		--Initialize the Mount Table if needed
		UMT_Init()
		--Check for valid mount, add if so
		for _,entry in ipairs(MountTable) do
			if entry[1] == rest then
				found = true
				break
			end
		end
		if found then
			tinsert(UMTdragride, rest)
			sort(UMTdragride)
			print("Mount \"" .. rest .. "\" added to random dragonriding mount list.")
		else
			print("\"" .. rest .. "\" was not found in the mount journal.")
		end

	elseif command == "deldrag" and rest ~= "" then
		local mind
		--Look for mount in the player's random mount table
		for index, entry in ipairs(UMTdragride) do
			if entry == rest then
				mind = index
				break
			end
		end
		--Remove the mount if present
		if mind then
			tremove(UMTdragride, mind)
			print("Mount \"" .. rest .. "\" removed from random dragonriding mount list.")
		else
			print("\"" .. rest .. "\" was not found in the random mount list.")
		end

	elseif command == "init" then
		--Re-initialize the mount table
		MountTable = {}
		UMT_Init()
		print("|cffffff78Mount Table re-initialized.|r")

	elseif command == "addboth" and rest ~= "" then
		local found
		--Initialize the Mount Table if needed
		UMT_Init()
		--Check for valid mount, add if so
		for _,entry in ipairs(MountTable) do
			if entry[1] == rest then
				found = true
				break
			end
		end
		if found then
			tinsert(UMTflying, rest)
			sort(UMTflying)
			tinsert(UMTground, rest)
			sort(UMTground)
			print("Mount \"" .. rest .. "\" added to both random mount lists.")
		else
			print("\"" .. rest .. "\" was not found in the mount journal.")
		end

elseif command == "delboth" and rest ~= "" then
		local mind
		--Look for mount in the player's random mount tables
		for index, entry in ipairs(UMTflying) do
			if entry == rest then
				f_ind = index
				break
			end
		end
		for index, entry in ipairs(UMTground) do
			if entry == rest then
				g_ind = index
				break
			end
		end
		--Remove the mount if present
		if f_ind then
			tremove(UMTflying, f_ind)
			print("Mount \"" .. rest .. "\" removed from random flying mount list.")
		else
			print("\"" .. rest .. "\" was not found in the random flying mount list.")
		end
		if g_ind then
			tremove(UMTflying, g_ind)
			print("Mount \"" .. rest .. "\" removed from random ground mount list.")
		else
			print("\"" .. rest .. "\" was not found in the random ground mount list.")
		end

	elseif command == "clearground" then
		--Zero out the ground mount list
		UMTground = {}
		print("|cffffff78All ground mounts deleted.|r")

	elseif command == "clearfly" then
		--Zero out the flying mount list
		UMTflying = {}
		print("|cffffff78All flying mounts deleted.|r")

	else
		-- If not handled above, display syntax
		print("Syntax: |cffffff78/umt mount|r -- mount a random mount")
		print("             |cffffff78/umt worgen|r -- like mount, but ignores ground mounts")
		print("             |cffffff78/umt list|r -- display your random mount lists")
		print("             |cffffff78/umt addfly <mount name>|r -- add a flying mount to the list")
		print("             |cffffff78/umt delfly <mount name>|r -- remove a flying mount from the list")
		print("             |cffffff78/umt addground <mount name>|r -- add a ground mount to the list")
		print("             |cffffff78/umt delground <mount name>|r -- remove a ground mount from the list")
		print("             |cffffff78/umt addboth <mount name>|r -- add a mount to both lists")
		print("             |cffffff78/umt delboth <mount name>|r -- add a mount to both lists")
		print("             |cffffff78/umt adddrag <mount name>|r -- add a dragonriding mount to the list")
		print("             |cffffff78/umt deldrag <mount name>|r -- remove a dragonriding mount from the list")
		print("             |cffffff78/umt init|r -- re-initialize the mount journal table")
		print("|cffffff78Mount names must be spelled and capitalized exactly.|r")
	end
end

