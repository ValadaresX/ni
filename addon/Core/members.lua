local setmetatable, type, select, sort, wipe, ipairs, tremove, tos = setmetatable, type, select, sort, wipe, ipairs, tremove, tostring
local UnitGroupRolesAssigned, UnitIsGhost, UnitHealthMax, UnitName, UnitGUID, UnitIsUnit = UnitGroupRolesAssigned, UnitIsGhost, UnitHealthMax, UnitName, UnitGUID, UnitIsUnit
local IsInRaid, GetNumRaidMembers, GetNumPartyMembers, GetNumGroupMembers, UnitClass, UnitCanAssist = IsInRaid, GetNumRaidMembers, GetNumPartyMembers, GetNumGroupMembers, UnitClass, UnitCanAssist
local UnitAffectingCombat, UnitHealth, UnitHealthMax, CheckInteractDistance, UnitAffectingCombat = UnitAffectingCombat, UnitHealth, UnitHealthMax, CheckInteractDistance, UnitAffectingCombat
local CreateFrame, CanInspect, GetTalentInfo, GetSpellInfo, IsSpellInRange, GetRaidRosterInfo = CreateFrame, CanInspect, GetTalentInfo, GetSpellInfo, IsSpellInRange, GetRaidRosterInfo
local GetNumTalentTabs, GetActiveTalentGroup, GetTalentTabInfo, GetNumTalents = GetNumTalentTabs, GetActiveTalentGroup, GetTalentTabInfo, GetNumTalents
--[[WARNING: Don't put NotifyInspect as local]]
local isFunction = ni.utils.isfunction;
local members = {};
local memberssetup = { cache = { _cache = {} } };
local roster = memberssetup.cache
local aux_roster = {};
local _cache = roster._cache
local tankTalents, BuildTalents, inspectFrame, DoInspect
local INSPECT_TIMEOUT = 3; -- If, during this time, we do not obtain the "INSPECT_TALENT_READY" trigger, we skip the unit and increase its INSPECT_DELAY.
local INSPECT_DELAY	= 10;  -- NotifyInspect delay per unit.
local wotlk = ni.vars.build == 30300;
local cata = ni.vars.build == 40300;
local inspect = { unit = "", tainted = false };
local playerInCombat
local pGuid
setmetatable(members, {
    __call = function(_, ...)
        local groupType, nRaidMembers, nPartyMembers, subgroup
        if wotlk or cata then
            nRaidMembers = GetNumRaidMembers()
            nPartyMembers = GetNumPartyMembers()
            groupType = nRaidMembers > 0 and "raid" or "party"
		else
            nRaidMembers = GetNumGroupMembers()
            nPartyMembers = nRaidMembers - 1
            groupType = IsInRaid() and "raid" or "party"
        end
        local groupsize = groupType == "raid" and nRaidMembers or nPartyMembers
        pGuid = UnitGUID("player");
        for i = 1, groupsize do
            local unit = groupType .. i
            local guid = UnitGUID(unit)
			if guid then
				subgroup = groupType == "raid" and select(3, GetRaidRosterInfo(i)) or 1;
				if guid ~= pGuid then
					local o = memberssetup:create(unit, guid, subgroup)
					if o then
						members[#members + 1] = o;
					end
				else
					members[#members + 1] = memberssetup:create("player", pGuid, subgroup)
				end
			end
		end
		if groupsize < 1 or groupType == "party" then
			members[#members + 1] = memberssetup:create("player", pGuid, 1)
		end
	end,
	__index = { name = "members", author = "MoRBiDuS", version = "1.2.0" };
});

local dontCache = {	["updatemember"] = true, ["updatemembers"] = true, ["reset"] = true, ["addcustom"] = true, ["removecustom"] = true };
local function addCache(t)
	for n, v in pairs(t) do
		if isFunction(v) and not dontCache[n] then
			t[n] = memberssetup.Do(t[n], _cache)
		end
	end
end;
function memberssetup.Do(f, c)
    return function(...)
		local a, res = tos(f);
		for n = 2, select('#', ...) do
			a = a.."Â»"..tos(select(n,...))
		end
		res = c[a]
        if not res then
            res = { f(...) }
			c[a] = res
        end
		return unpack(res);
    end
end;
setmetatable(memberssetup, { __call = function(_, ...) return Do(...) end });

if wotlk then
	tankTalents = {
		BladeBarrier			= GetSpellInfo(49182),
		Toughness				= GetSpellInfo(49042),
		Anticipation			= GetSpellInfo(55129),
		SurvivalOfTheFittest	= GetSpellInfo(33853),
		ProtectorOfThePack		= GetSpellInfo(57873)
	};

	BuildTalents = function(unit)
		if not unit then return end
		local notMe = unit ~= "player"
		local NumTalentTabs = GetNumTalentTabs(notMe)
		if NumTalentTabs > 0 then
			local group = GetActiveTalentGroup(notMe)
			local guid = UnitGUID(unit)
			roster[guid].talents = {}
			local talents = roster[guid].talents
			local maxPointsSpent = 0
			for tab = 1, NumTalentTabs do
				local SpecName = GetTalentTabInfo(tab, notMe)
				talents[SpecName] = {}
				local pointsSpent = 0
				for numTalents = 1, GetNumTalents(tab, notMe) do
					local name, _, tier, column, currentRank, maxRank = GetTalentInfo(tab, numTalents, notMe, nil, group)
					pointsSpent = pointsSpent + currentRank
					talents[SpecName][name] = {
						tier		= tier,
						column		= column,
						currentRank	= currentRank,
						maxRank		= maxRank
					};
				end
				roster[guid]["t"..tab] = pointsSpent
				if pointsSpent > maxPointsSpent then
					maxPointsSpent = pointsSpent;
					roster[guid].specName = SpecName;
				end
			end
		end
	end;

    hooksecurefunc("NotifyInspect", function(unit)
        if UnitExists(unit) and  not UnitIsUnit("mouseover", unit) then
            inspect.unit = unit
            inspect.tainted = true
            ni.C_Timer.After(INSPECT_TIMEOUT, function()
                if inspect.tainted then
                    inspect.tainted = false
                    local guid = UnitGUID(inspect.unit)
                    local Obj = roster[guid] or aux_roster[guid]
                    if Obj then
                        Obj.lastInspTime = 5 * Obj.inspAttempts + GetTime()
                        if Obj.inspAttempts < 3 then
                            Obj.inspAttempts = Obj.inspAttempts + 1
                        end
                    end
                end
            end)
        end
    end);
	inspectFrame = CreateFrame("frame")
	DoInspect = function(unit)
		if CanInspect(unit) then
			NotifyInspect(unit);
			inspectFrame:RegisterEvent("INSPECT_TALENT_READY");
		end
	end;
	inspectFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	inspectFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
	
    inspectFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "INSPECT_TALENT_READY" then
            self:UnregisterEvent("INSPECT_TALENT_READY")
            if inspect.tainted then
                BuildTalents(inspect.unit)
                local guid = UnitGUID(inspect.unit)
                roster[guid].lastInspTime = GetTime()
                roster[guid].inspAttempts = 0
                inspect.tainted = false
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            playerInCombat = false;
        elseif event == "PLAYER_REGEN_DISABLED" then
            playerInCombat = true;
        end
    end);
end;
function memberssetup:create(unit, guid, subgroup)
	if roster[guid] then return end
	local o = {}
	setmetatable(o, memberssetup)
	
	function o:istank()
		return o.role == "TANK"
		or (o.class == "WARRIOR" and o:aura(71))
		or (o.class == "DRUID" and o:auras("9634||5487"))
		or (o.class == "PALADIN" and o:aura(25780) and ni.power.currentraw(o.unit, 0) < 14000)
		or (o.class == "DEATHKNIGHT" and o:aura(48263))
		or (o:aura(57339) or (o:aura(57340) and ni.power.currentraw(o.unit, 0) < 14000)) or false;	
	end;
	if wotlk then
		function o:ishealer()
			return o.role == "HEALER";
		end;
		function o:isdps()
			return o.role == "MELEE" or o.role == "CASTER";
		end;
		function o:iscaster()
			return o.role == "CASTER";
		end;
		function o:ismelee()
			return o.role == "MELEE";
		end;
	end;
	function o:location()
		local x, y, z, r = ni.functions.objectinfo(o.guid);
		if x then
			return x, y, z, r;
		end
		return 0, 0, 0, 0;
	end;
	function o:combat()
		return ni.unit.incombat(o.unit);
	end
	function o:aura(aura)
		return ni.unit.aura(o.unit, aura);
	end;	
	function o:auras(auras)
		return ni.unit.auras(o.unit, auras);
	end;
	function o:buff(buff, filter)
		return ni.unit.buff(o.unit, buff, filter) ~= nil;
	end;
	function o:debuff(debuff, filter)
		return ni.unit.debuff(o.unit, debuff, filter) ~= nil;
	end;	
	function o:buffs(str, filter)
		return ni.unit.buffs(o.unit, str, filter) or false;
	end;
	function o:debuffs(str, filter)
		return ni.unit.debuffs(o.unit, str, filter) or false;
	end;
	function o:bufftype(str)
		return ni.unit.bufftype(o.unit, str) or false;
	end;	
	function o:debufftype(str)
		return ni.unit.debufftype(o.unit, str) or false;
	end;
	function o:buffstacks(buff, filter)
		return ni.unit.buffstacks(o.unit, buff, filter) or 0;
	end;
	function o:debuffstacks(debuff, filter)
		return ni.unit.debuffstacks(o.unit, debuff, filter) or 0;
	end;
	function o:buffremaining(buff, filter)
		return ni.unit.buffremaining(o.unit, buff, filter);
	end;
	function o:debuffremaining(debuff, filter)
		return ni.unit.debuffremaining(o.unit, debuff, filter);
	end;
	function o:dispel()
		return ni.healing.candispel(o.unit) or false;
	end;
	function o:hpraw()
		return UnitHealth(o.unit);
	end;		
	function o:hpmax()
		return UnitHealthMax(o.unit);
	end;
	--------------------------------------
	function o:hp()
		local hp = o:hpraw()/o:hpmax() * 100;
		if hp == 100 or hp <= 0 or o:isdead() then
			return 100;
		end
		--------------------------------------
		for i = 1, #ni.tables.cantheal do
		local cantheal = ni.tables.cantheal[i];
			if o:debuff(cantheal) then return 100 end
		end;
		for i = 1, #ni.tables.notneedheal do
		local notneedheal = ni.tables.notneedheal[i];
			if o:buff(notneedheal) then return 100 end
		end;		
		hp = o:istank() and (hp - 5) or hp;
		hp = o:dispel() and (hp - 2) or hp;
		return hp;
	end;
    function o:range()
		local reqDist = roster[pGuid] and roster[pGuid].class == "PALADIN" and roster[pGuid].role == "HEALER" and 60 or 40        
		local dist = ni.player.distance(o.unit) or 999;
        return dist < reqDist or false;
    end;
	function o:distance(tar)
		local t = true and tar or pla;
		return ni.unit.distance(o.unit, t);		
	end;
	function o:los()
		return ni.player.los(o.unit) == true;
	end;
	function o:facing()
		return ni.player.facing(o.unit) == true;
	end;
	function o:unfriendly()
		return ni.player.isenemy(o.unit);
	end;
	function o:isdead()
		return ni.unit.unitisdead(o.unit);
	end;	
	function o:valid(spell, facing, los)
		local spellid = tonumber(spell)
		spellid = spellid or ni.spell.id(spell)
		return (spellid > 0
		and IsSpellInRange(GetSpellInfo(spellid), o.unit) == 1
		and not o:unfriendly() and not o:isdead()
		and (not facing or o:facing())
		and (not los or o:los()))
		or false;
	end;
	function o:threat()
		return ni.unit.threat(o.unit) or false;
	end;	
	function o:getRole()
		if not wotlk then
			return UnitGroupRolesAssigned(o.unit) or "NONE";
		else
			if not roster[o.guid] then
				return "NONE"
			elseif not roster[o.guid].talents
			  or not CheckInteractDistance(o.unit, 1) then
				return roster[o.guid].lastRole or "NONE"
			end
		end
		
		local class, role, t = o.class, "none", tankTalents
		if class == "ROGUE" or class == "HUNTER" then
			role = "MELEE"
		elseif class == "MAGE" or class == "WARLOCK" then
			role = "CASTER"
		elseif class == "DEATHKNIGHT" then
			local score = o:talent(t.BladeBarrier) > 0 and 1 or 0
			score = score + (o:talent(t.Toughness) > 0 and 1 or 0)
			score = score + (o:talent(t.Anticipation) > 0 and 1 or 0)
			role = score >= 2 and "TANK" or "MELEE"	-- if has 2 of the 3 tanking talents then is a tank
		else
			local t1, t2, t3 = roster[o.guid].t1, roster[o.guid].t2, roster[o.guid].t3
			if class == "PRIEST" then
				role = (t1 + t2) > t3 and "HEALER" or "CASTER"
			elseif class == "WARRIOR" then
				role = (t1 + t2) > t3 and "MELEE" or "TANK" 
			else
				local weight = (t1 > t2 and t1 > t3 and 1) or (t2 > t1 and t2 > t3 and 2) or (t3 > t1 and t3 > t2 and 3) or 0
				if class == "PALADIN" then
					role = weight == 1 and "HEALER" or weight == 2 and "TANK" or weight == 3 and "MELEE"
				elseif class == "DRUID" then
					if weight == 2 then
						role = o:talent(t.SurvivalOfTheFittest) > 0 and o:talent(t.ProtectorOfThePack) > 0 and "TANK" or "MELEE"
					else
						role = weight == 1 and "CASTER" or "HEALER"
					end
				elseif class == "SHAMAN" then
					role = weight == 1 and "CASTER" or weight == 2 and "MELEE" or weight == 3 and "HEALER"
				end
			end
		end
		
		local tank, healer, damager = UnitGroupRolesAssigned(roster[o.guid].unit)
		local GroupRole = tank and "TANK" or healer and "HEALER" or damager and "DAMAGER" or "NONE"
		if GroupRole ~= "NONE" then
			if GroupRole == "DAMAGER" then
				if not (role == "CASTER" or role == "MELEE") then
					role = GroupRole
				end
			elseif GroupRole ~= role then
				role = GroupRole
			end
		end		
		
		roster[o.guid].role = role
		return role
	end;
	if wotlk then
		function o:talent(talent) -- Returns the rank of the unit's talent
			if roster[o.guid] and roster[o.guid].talents then
				local talents = roster[o.guid].talents
				for tab,tbl in pairs(talents) do
					if type(tbl) == "table" then
						for k,v in pairs(tbl) do
							if k == talent then
								return v.currentRank;
							end
						end
					end
				end
			end
			return 0
		end;
	end

	function o:updatemember()
		o.name = o.name or UnitName(o.unit);
		o.class = o.class or select(2, UnitClass(o.unit));
		o.spec	= wotlk and roster[o.guid] and roster[o.guid].specName or (aux_roster[o.guid] and aux_roster[o.guid].spec) or "None"
		
		if wotlk then
			local role = o:getRole()
			o.role = role ~= "NONE" and role or (aux_roster[o.guid] and aux_roster[o.guid].role)
		end

		roster[o.guid].name		= o.name
		roster[o.guid].class	= o.class
		roster[o.guid].guid		= o.guid
		roster[o.guid].subgroup	= o.subgroup
		roster[o.guid].spec		= o.spec
		roster[o.guid].role		= o.role

		playerInCombat = playerInCombat == nil and UnitAffectingCombat("player") or playerInCombat
		if wotlk then
			if not playerInCombat or o.unit == "player" or (roster[o.guid].lastInspTime == 0 and CheckInteractDistance(o.unit, 1) ~= nil) then
				local now = GetTime()
				roster[o.guid].spec = roster[o.guid].specName or "None"
				if now-roster[o.guid].lastInspTime > INSPECT_DELAY then
					if roster[o.guid].role then
						roster[o.guid].lastRole = roster[o.guid].role
					end
					if o.unit == "player" then
						BuildTalents("player")
						roster[o.guid].lastInspTime = now
					else
						DoInspect(o.unit)
					end		
				end
			end
		end
		
	end;
	
	-- Attributes
	o.unit			= unit
	o.guid			= guid
	o.subgroup		= subgroup
	o.name			= UnitName(unit)
	o.class			= select(2, UnitClass(unit))
	o.target		= unit .. "target"
	o.spec			= "None"
	o.role			= "NONE"

	roster[o.guid] = {}
	roster[o.guid].name			= o.name
	roster[o.guid].class		= o.class
	roster[o.guid].guid			= o.guid
	roster[o.guid].subgroup		= o.subgroup
	roster[o.guid].role			= "NONE"
	roster[o.guid].lastRole		= "NONE"
	roster[o.guid].lastInspTime	= 0
	roster[o.guid].inspAttempts	= 0
	addCache(o)
	return o;
end;

local inrange, inrangebelow, inrangewithbuff, inrangewithdebufftype, inrangewithbufftype, inrangewithoutbuff, inrangewithbuffbelow, inrangewithoutbuffbelow, inrangewithdebuff, inrangewithdebuffbelow, inrangewithoutdebuff, inrangewithoutdebuffbelow, tsubgroup, subgroupbelow, subgroupbelow2 = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {};
memberssetup.set = function()
	function members.updatemembers()
		wipe(_cache)
		for _, o in ipairs(members) do
			o:updatemember();
		end
	end;
	function members.reset()
		ni.C_Timer.After(0, function()
			wipe(members);
			aux_roster = ni.utils.deepcopytable(roster);
			wipe(roster);
			memberssetup.set();
		end)
	end;
	function members.sort()
		if #members > 1 then
			sort(members, function(a,b) return a:range() and not b:range() or a:range() == b:range() and a:hp() < b:hp() end)
		end
		return members;
	end;
	function members.below(percent)
		local total = 0;
		for _,o in ipairs(members) do
			if o:hp() < percent then
				total = total + 1;
			end
		end
		return total;
	end;
	function members.average(unit, distance)
		local average = 0;
		local tbl = members.inrange(unit or "player", distance or 40)
		for _,o in ipairs(tbl) do
			average = average + o:hp()
		end
		return average / #tbl;
	end;
	function members.averageof(count, unit, distance)
		if not count or count <= 0 then return 0 end
		unit = unit or "player"
		distance = distance or 40		
		local n, average = 0, 0
		for i, o in ipairs(members.inrange(unit, distance)) do
			average = average + o:hp()
			if i >= count then n = i break end	
		end
		return n > 0 and average/n or 0;
	end;
	function members.inrange(unit, distance)
		wipe(inrange)
		if type(unit) ~= "string" then return inrange end
		for _,o in ipairs(members) do
			if not UnitIsUnit(o.unit, unit) then
				local unitdistance = ni.unit.distance(o.unit, unit) or 999;
				if unitdistance <= distance then
					inrange[#inrange + 1] = o;
				end
			end
		end
		return inrange;
	end;
	function members.inrangebelow(unit, distance, hp)
		wipe(inrangebelow)
		for _,o in ipairs(members.inrange(unit, distance)) do
			local aux = o:hp()
			if aux <= hp then
				local idx = #inrangebelow + 1
				inrangebelow[idx] = o;
				inrangebelow[idx].aux = aux;
			end
		end
		if #inrangebelow > 1 then
			sort(inrangebelow, function(a,b) return a.aux < b.aux end)
		end
		return inrangebelow;
	end;
	function members.inrangewithbuff(unit, distance, buff, filter)
		wipe(inrangewithbuff)
		for _,o in ipairs(members.inrange(unit, distance)) do
			if o:buff(buff, filter) then
				inrangewithbuff[#inrangewithbuff + 1] = o;
			end
		end
		return inrangewithbuff;
	end;
	function members.inrangewithdebufftype(unit, distance, str)
        wipe(inrangewithdebufftype)
        for _,o in ipairs(members.inrange(unit, distance)) do
            if o:debufftype(str) then
                inrangewithdebufftype[#inrangewithdebufftype + 1] = o;
            end
        end
        return inrangewithdebufftype;
    end;
	function members.inrangewithbufftype(unit, distance, str)
        wipe(inrangewithbufftype)
        for _,o in ipairs(members.inrange(unit, distance)) do
            if o:bufftype(str) then
                inrangewithbufftype[#inrangewithbufftype + 1] = o;
            end
        end
        return inrangewithbufftype;
    end;
	function members.inrangewithoutbuff(unit, distance, buff, filter)
		wipe(inrangewithoutbuff)
		for _,o in ipairs(members.inrange(unit, distance)) do
			if not o:buff(buff, filter) then
				inrangewithoutbuff[#inrangewithoutbuff + 1] = o;
			end
		end
		return inrangewithoutbuff;
	end;
	function members.inrangewithbuffbelow(unit, distance, buff, hp, filter)
		wipe(inrangewithbuffbelow)
		for _,o in ipairs(members.inrangebelow(unit, distance, hp)) do
			if o:buff(buff, filter) then
				inrangewithbuffbelow[#inrangewithbuffbelow + 1] = o;
			end
		end
		return inrangewithbuffbelow;
	end;
	function members.inrangewithoutbuffbelow(unit, distance, buff, hp, filter)
		wipe(inrangewithoutbuffbelow)
		for _,o in ipairs(members.inrangebelow(unit, distance, hp)) do
			if not o:buff(buff, filter) then
				inrangewithoutbuffbelow[#inrangewithoutbuffbelow + 1] = o;
			end
		end
		return inrangewithoutbuffbelow;
	end;
	function members.inrangewithdebuff(unit, distance, debuff, filter)
		wipe(inrangewithdebuff)
		for _,o in ipairs(members.inrange(unit, distance)) do
			if o:debuff(debuff, filter) then
				inrangewithdebuff[#inrangewithdebuff + 1] = o;
			end
		end
		return inrangewithdebuff;
	end;
	function members.inrangewithdebuffbelow(unit, distance, debuff, hp, filter)
		wipe(inrangewithdebuffbelow)
		for _,o in ipairs(members.inrangebelow(unit, distance, hp)) do
			if o:debuff(debuff, filter) then
				inrangewithdebuffbelow[#inrangewithdebuffbelow + 1] = o;
			end
		end
		return inrangewithdebuffbelow;
	end;
	function members.inrangewithoutdebuff(unit, distance, debuff, filter)
		wipe(inrangewithoutdebuff)
		for _,o in ipairs(members.inrange(unit, distance)) do
			if not o:debuff(debuff, filter) then
				inrangewithoutdebuff[#inrangewithoutdebuff + 1] = o;
			end
		end
		return inrangewithoutdebuff;
	end;
	function members.inrangewithoutdebuffbelow(unit, distance, debuff, hp, filter)
		wipe(inrangewithoutdebuffbelow)
		for _,o in ipairs(members.inrangebelow(unit, distance, hp)) do
			if not o:debuff(debuff, filter) then
				inrangewithoutdebuffbelow[#inrangewithoutdebuffbelow + 1] = o;
			end
		end
		return inrangewithoutdebuffbelow;
	end;
	function members.tsubgroup()
		wipe(tsubgroup)
		for _,o in ipairs(members) do
			if not tContains(tsubgroup, o.subgroup) then
				tinsert(tsubgroup, o.subgroup)
			end
		end
		return tsubgroup;
	end	
    function members.subgroupbelow(percent, radius, owngroup)
        local total, aux = 0
		wipe(subgroupbelow)
		wipe(subgroupbelow2)
        if owngroup then
            aux = members.inrange("player", 0)[1];
            owngroup = aux and aux.subgroup;
        end
        for _, group in ipairs(owngroup and {owngroup} or members.tsubgroup()) do
            for _, o in ipairs(members) do
                if o.subgroup == group and o:range()
                  and o:hp() < percent and o:los() then
                    total = 1;
                    for _,o2 in ipairs(members) do
                        if o.guid ~= o2.guid and o2.subgroup == group
                        and o2:hp() < percent and ni.unit.distance(o.unit, o2.unit) <= radius
                        and ni.unit.los(o.unit, o2.unit) then
                            total = total + 1;
                        end
                    end
                end
                o.near = total;
                subgroupbelow[#subgroupbelow + 1] = o;
            end
            sort(subgroupbelow, function(a,b) return (a.near > b.near) or (a.near == b.near and a:hp() < b:hp()) end);
            if subgroupbelow[1] then
                subgroupbelow2[#subgroupbelow2 + 1] = subgroupbelow[1];
            end
        end
        sort(subgroupbelow2, function(a,b) return (a.near > b.near) or (a.near == b.near and a:hp() < b:hp()) end);
        if subgroupbelow2[1] then
            return subgroupbelow2[1].near, subgroupbelow2[1];
        else
            return 0;
        end
    end;	
	function members.addcustom(unit, guid)
		if type(unit) == "string" then
			local getGUID = ni.objectmanager.objectGUID(unit);
			local groupMember = memberssetup:create(unit, guid or UnitGUID(unit));
			if groupMember then
				members[#members + 1] = groupMember;
				members:updatemembers();
			end
		end
	end;
	function members.removecustom(identifier, isName)
		if type(identifier) == "string" then
			for i, o in ipairs(members) do
				if (isName and o.name == identifier and UnitIsUnit(identifier, o.unit)) 
				or (not isName and o.unit == identifier) then
					roster[o.guid] = nil;
					tremove(members, i);
					members:updatemembers();
					break;
				end
			end
		end
	end;
	members()
end;

memberssetup.set()
addCache(members)

return members;