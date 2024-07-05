local A1 = ni.utils.require("A1")
local GetSpellInfo, GetWeaponEnchantInfo, UnitAffectingCombat, GetTotemInfo, DestroyTotem = GetSpellInfo, GetWeaponEnchantInfo, UnitAffectingCombat, GetTotemInfo, DestroyTotem
local ench_menu = {
    settingsfile = "A1 - ShamRestor2.0.json",
    { type = "separator" },
    { type = "title", text = "|cff266bffRestoration Shaman PvE |cffcece0cA1 v2.0" },
    { type = "separator" },
	{ type = "entry", text = "\124T"..A1.restorsham_icons.Wind_Shear..":20:20\124t |cff266bffПронизывающий ветер", enabled = false, key = "gui_Wind_Shear" },
	{ type = "entry", text = "\124T"..A1.restorsham_icons.Cleanse_Spirit..":20:20\124t |cff266bffДиспел", enabled = false, key = "gui_Decurse" },
	{ type = "entry", text = "\124T"..A1.restorsham_icons.Hex..":20:20\124t |cff266bffЖаба", enabled = false, key = "gui_Hex" },
    { type = "separator" },
    { type = "entry", text = "|cffcece0cЛог", enabled = false, key = "gui_Debug" },
}
local function GetSetting(name)
  for k, v in ipairs(ench_menu) do
    if v.type == "entry"
    and v.key ~= nil
    and v.key == name then
      return v.value, v.enabled
    end
			if v.type == "dropdown"
			and v.key ~= nil
			and v.key == name then
				for k2, v2 in pairs(v.menu) do
					if v2.selected then
						return v2.value
					end
				end
			end
        if v.type == "input"
         and v.key ~= nil
         and v.key == name then
            return v.value
        end
    end
end
local function menu_load()
ni.GUI.AddFrame("ShamRestor20", ench_menu)
end
local function menu_unload()
ni.GUI.DestroyFrame("ShamRestor20")
end
local highrangeenemies = {}
local function GUID_Enemys()
	table.wipe(highrangeenemies)
	highrangeenemies = ni.player.enemiesinrange(30)
	for k, v in ipairs(highrangeenemies) do
		if ni.player.threat(v.guid)==-1 then
			table.remove(highrangeenemies, k)
		end
	end
	return #highrangeenemies
end
local CriticalCast = {"Сожжение", "Ледяное дыхание", "Огненное дыхание", "Священный огонь", "Дыхание Пустоты", "Пожирающее пламя", "Ледяные шипы", "Статический сбой"}
local dontdispel = {36020}
local OverHealing = {30423, 66118}
local CriticalDebuff = {67050, 70541, 38801, 43093}
local Healing_Wave_Healing = (4062.5 + 1.6114*GetSpellBonusHealing())*1.3756
local Lesser_Healing_Wave_Healing = (1720 + 0.8057*GetSpellBonusHealing())*1.2815
local Riptide_Healing = (1670 + 1.342*GetSpellBonusHealing())*0.6178
local Chain_Heal_Healing = (1356 + 2.6319*GetSpellBonusHealing())*0.7855
local LastES, LastTotemicRecall, LastTotemicCall, LastAnounce = 0, 0, 0, 0
local raid_debuffs = {
    Enfeeble = GetSpellInfo(30843),
    Pursued_by_Anub = GetSpellInfo(67574),
    Necrotic_Plague = GetSpellInfo(70337)
}
for _, v in pairs(dontdispel) do
    ni.healing.debufftoblacklist(v)
end
function Tank(t)
    local _, _, class = UnitClass(t)
	if (class == 11
	and ni.unit.aura(t, 9634))
    or (class == 1
	and ni.unit.aura(t, 71))
    or (class == 2
	and ni.unit.aura(t, 25780))
    or (class == 6
	and ni.unit.aura(t, 48263)) then
		return true
	end
	return false
end
local ench_rotation = {
    "Altkey",
    "RaceBuff",
    "Healthstone",
    "Pause",
    "Enchant Weapon",
    "Water Shield",
    --"Mana Tide Totem",
    "Earth Shield",
    "Combat Pause",
    "Nature Swiftness",
    "Tidal Force",
    "Riptide",
    "Healing Wave (Targettarget)",
    "Healing Wave (Critical)",
    "Healing Wave (Target)",
    "Chain Heal",
    "Cleanse Spirit",
    "Healing Wave",
    "Leser Healing Wave",
    "Purge",
    "Wind Shear",
    "Hex (control)",
    "Chain Heal nc",
}
local ench_functions = {
	["Altkey"] = function()
		if IsLeftAltKeyDown() or IsRightAltKeyDown() then
            return print("ALT KEY IS SHIFTED")
        end
	end,
    ["Healthstone"] = function()
        local hstones = { 36892, 36893, 36894 }
        for i = 1, #hstones do
            if UnitAffectingCombat("player")
            and ni.player.hp() < 33
            and ni.player.hasitem(hstones[i])
            and ni.player.itemcd(hstones[i]) == 0 then
                return ni.player.useitem(hstones[i])
            end
        end
    end,
    ["Healing Wave (Target)"] = function()
        if (ni.unit.hp("target") < 100 or (UnitAffectingCombat("player") and ni.unit.buff("target", 47893)))
        and ni.spell.available(A1.restorsham_skills.Healing_Wave)
        and ni.spell.valid("target", A1.restorsham_skills.Healing_Wave, false, true, true)
        and not ni.unit.ismoving("player") then
            return ni.spell.cast(A1.restorsham_skills.Healing_Wave, "target")
        end
    end,
    ["Healing Wave (Critical)"] = function ()
        if ni.spell.available(A1.restorsham_skills.Healing_Wave)
        and not ni.player.ismoving() then
            for _, z in ipairs(OverHealing) do
                for _, x in ipairs(CriticalDebuff) do
                    for _, member in ipairs(ni.members) do
                        if ni.unit.debuff(member.unit, raid_debuffs.Enfeeble) then
                            return false
                        end
                        if (((ni.unit.debuff(member.unit, z) and member.hp <= 90)
                        or ni.unit.debuff(member.unit, x))
                        and ni.spell.valid(member.unit, A1.restorsham_skills.Healing_Wave, false, true, true)) then
                            return ni.spell.cast(A1.restorsham_skills.Healing_Wave, member.unit)
                        end
                    end
                end
            end
        end
    end,
    ["Healing Wave (Targettarget)"] = function()
        local cast = UnitCastingInfo("target")
        if ni.unit.exists("target")
        and ni.unit.exists("targettarget") then
            for _, x in ipairs(CriticalCast) do
                if ni.unit.castingpercent("target") > 65
                and cast == x then
                    if ni.spell.available(A1.restorsham_skills.Healing_Wave)
                    and ni.spell.valid("targettarget", A1.restorsham_skills.Healing_Wave, false, true, true)
                    and not ni.unit.ismoving("player") then
                        return ni.spell.cast(A1.restorsham_skills.Healing_Wave, "targettarget")
                    end
                end
            end
        end
    end,
    ["Pause"] = function ()
        if IsMounted()
        or UnitInVehicle("player")
        or ni.player.buff(GetSpellInfo(430))
        or ni.player.buff(GetSpellInfo(433))
        or ni.player.isconfused()
        or ni.player.isfleeing()
        or ni.player.isstunned()
        or ni.player.iscasting()
        or ni.player.ischanneling()
        or UnitIsDeadOrGhost("player")
        or IsLeftShiftKeyDown() then
            return true
        end
        GUID_Enemys()
		ni.vars.debug = select(2, GetSetting("gui_Debug"))
    end,
    ["Combat Pause"] = function ()
        if IsLeftShiftKeyDown()
        or ni.player.debuffstacks(69766) > 4
		or (ni.player.debuff(305131) and ni.player.debuffremaining(305131) < 2)
        or (ni.player.debuff(69762) and ni.player.debuffremaining(69762) > 3) then
            return true
        end
    end,
    ["Water Shield"] = function ()
        if not ni.player.buff(A1.restorsham_skills.Water_Shield) then
            if ni.spell.available(A1.restorsham_skills.Water_Shield) then
                return ni.spell.cast(A1.restorsham_skills.Water_Shield)
            end
        end
    end,
    ["RaceBuff"] = function ()
        if not ni.player.buff(310807) then
            if ni.spell.available(310807) then
                return ni.spell.cast(310807)
            end
        end
    end,
    ["Healing Wave"] = function ()
        if ni.spell.available(A1.restorsham_skills.Healing_Wave)
        and not ni.player.ismoving()
        and UnitAffectingCombat("player") then
            for _, member in ipairs(ni.members) do
                if not ni.unit.debuff(member.unit, raid_debuffs.Enfeeble) then
                    if ni.unit.hpraw(member.unit) >= Healing_Wave_Healing
                    and ni.spell.valid(member.unit, A1.restorsham_skills.Healing_Wave, false, true, true) then
                        return ni.spell.cast(A1.restorsham_skills.Healing_Wave, member.unit)
                    end
                end
            end
        end
    end,
    ["Leser Healing Wave"] = function ()
        if ni.spell.available(A1.restorsham_skills.Lesser_Healing_Wave)
        and not ni.player.ismoving()
        and UnitAffectingCombat("player") then
            for _, member in ipairs(ni.members) do
                if not ni.unit.debuff(member.unit, raid_debuffs.Enfeeble)
                and not Tank(member.unit)
                and not ni.unit.buff(member.unit, A1.restorsham_skills.Riptide) then
                    if ni.unit.hpraw(member.unit) >= Lesser_Healing_Wave_Healing
                    and ni.spell.valid(member.unit, A1.restorsham_skills.Lesser_Healing_Wave, false, true, true) then
                        return ni.spell.cast(A1.restorsham_skills.Lesser_Healing_Wave, member.unit)
                    end
                end
            end
        end
    end,
    ["Riptide"] = function ()
        if ni.spell.available(A1.restorsham_skills.Riptide)
        and UnitAffectingCombat("player") then
            for _, member in ipairs(ni.members) do
                if not ni.unit.debuff(member.unit, raid_debuffs.Enfeeble)
                and not ni.unit.buff(member.unit, A1.restorsham_skills.Riptide)  then
                    if ni.unit.hpraw(member.unit) >= Riptide_Healing
                    and ni.spell.valid(member.unit, A1.restorsham_skills.Riptide, false, true, true) then
                        return ni.spell.cast(A1.restorsham_skills.Riptide, member.unit)
                    end
                end
            end
        end
    end,
    ["Chain Heal"] = function()
        if ni.spell.available(A1.restorsham_skills.Chain_Heal)
        and ni.player.buff(A1.restorsham_skills.Tidal_Force)
        and UnitAffectingCombat("player") then
            for _, member in ipairs(ni.members) do
                if not ni.unit.debuff(member.unit, raid_debuffs.Enfeeble) then
                    if #ni.members.inrangebelowraw(member.unit, 12, Chain_Heal_Healing*1.6) >= 3
                    and ni.spell.valid(member.unit, A1.restorsham_skills.Chain_Heal, false, true, true) then
                        return ni.spell.cast(A1.restorsham_skills.Chain_Heal, member.unit)
                    end
                end
            end
        end
        if ni.spell.available(A1.restorsham_skills.Chain_Heal)
        and not ni.unit.ismoving("player")
        and UnitAffectingCombat("player") then
            for _, member in ipairs(ni.members) do
                if not ni.unit.debuff(member.unit, raid_debuffs.Enfeeble) then
                    if #ni.members.inrangebelowraw(member.unit, 12, Chain_Heal_Healing*0.7) >= 3
                    and ni.spell.valid(member.unit, A1.restorsham_skills.Chain_Heal, false, true, true) then
                        return ni.spell.cast(A1.restorsham_skills.Chain_Heal, member.unit)
                    end
                end
            end
        end
    end,
    ["Chain Heal nc"] = function()
        if not UnitAffectingCombat("player") then
            if ni.spell.available(A1.restorsham_skills.Chain_Heal)
            and not ni.unit.ismoving("player") then
                for _, member in ipairs(ni.members) do
                    if not ni.unit.debuff(member.unit, raid_debuffs.Enfeeble) then
                        if #ni.members.inrangebelow("player", 25, 85) >= 3
                        and ni.spell.valid(member.unit, A1.restorsham_skills.Chain_Heal, false, true, true) then
                            return ni.spell.cast(A1.restorsham_skills.Chain_Heal, member.unit)
                        end
                    end
                end
            end
        end
    end,
    ["Tidal Force"] = function()
        if ni.spell.cd(A1.restorsham_skills.Tidal_Force) == 0 then
            for _, member in ipairs(ni.members) do
                if ni.unit.hpraw(member.unit) >= Chain_Heal_Healing*2
                and #ni.members.inrangebelow(member.unit, 12, 70) >= 3 then
                    return ni.spell.cast(A1.restorsham_skills.Tidal_Force)
                end
            end
        end
    end,
    ["Cleanse Spirit"] = function()
		local _, decurse_enabled = GetSetting("gui_Decurse")
		if decurse_enabled then
            if ni.spell.available(A1.restorsham_skills.Cleanse_Spirit) then
                for _, member in ipairs(ni.members) do
                    if ni.unit.hp(member.unit) > 75
                    and ni.unit.debufftype(member.unit, "Curse|Disease|Poison")
                    and ni.healing.candispel(member.unit)
                    and ni.spell.valid(member.unit, A1.restorsham_skills.Cleanse_Spirit, false, true, true) then
                        return ni.spell.delaycast(A1.restorsham_skills.Cleanse_Spirit, member.unit, 1.2)
                    end
                end
            end
        end
	end,
	["Enchant Weapon"] = function()
        local MainHandEnchant = GetWeaponEnchantInfo()
        if MainHandEnchant == nil then
            if ni.spell.available(A1.restorsham_skills.Earthliving_Weapon) then
                return ni.spell.cast(A1.restorsham_skills.Earthliving_Weapon)
            end
        end
	end,
    ["Purge"] = function ()
        if not ni.player.issilenced() then
            if ni.spell.available(A1.restorsham_skills.Purge)
            and UnitAffectingCombat("player") then
                for BuffedEnemy in ipairs(highrangeenemies) do
                    local GUNIT = highrangeenemies[BuffedEnemy].guid
                    if ni.spell.valid(GUNIT, A1.restorsham_skills.Purge, false, true)
                    and ni.unit.bufftype(GUNIT, "Magic") then
                        return ni.spell.cast(A1.restorsham_skills.Purge, GUNIT)
                    end
                end
            end
        end
    end,
	["Wind Shear"] = function()
		local _, wind_shear_enabled = GetSetting("gui_Wind_Shear")
		if wind_shear_enabled then
            if ni.spell.shouldinterrupt("target")
            or ni.unit.ischanneling("target") then
                if ni.spell.cd(A1.restorsham_skills.Wind_Shear) == 0
                and ni.player.power() >= 5
                and ni.spell.valid("target", A1.restorsham_skills.Wind_Shear, false, true, false) then
                    return ni.spell.cast(A1.restorsham_skills.Wind_Shear)
                end
            end
		end
	end,
    ["Mana Tide Totem"] = function()
        if ni.player.power() < 55
        and UnitAffectingCombat("player") then
            if ni.spell.available(A1.restorsham_skills.Mana_Tide_Totem) then
                return ni.spell.cast(A1.restorsham_skills.Mana_Tide_Totem)
            end
        end
    end,
    ["Earth Shield"] = function()
        for _, tank in ipairs(ni.members) do
            if ni.unit.threat(tank.unit, "target") == 3
            and Tank(tank.unit) then
                if not ni.unit.buff(tank.unit, A1.restorsham_skills.Earth_Shield)
                and ni.spell.valid(tank.unit, A1.restorsham_skills.Earth_Shield, false, true, true)
                and ni.spell.available(A1.restorsham_skills.Earth_Shield) then
                    LastES = GetTime()
                    return ni.spell.cast(A1.restorsham_skills.Earth_Shield, tank.unit)
                end
            end
        end
    end,
	["Call of the Elements"] = function()
        local FireTotem = select(2, GetTotemInfo(1))
        local EarthTotem = select(2, GetTotemInfo(2))
        local WaterTotem = select(2, GetTotemInfo(3))
        local AirTotem = select(2, GetTotemInfo(4))
        if ni.spell.available(A1.restorsham_skills.Call_of_the_Elements)
        and (UnitAffectingCombat("player")
        or ni.unit.exists("focus") and UnitAffectingCombat("focus")) then
            if (FireTotem == "" and EarthTotem == "" and WaterTotem == "" and AirTotem == "")
            and GetTime() - LastTotemicCall > 7 then
                LastTotemicCall = GetTime()
                return ni.spell.cast(A1.restorsham_skills.Call_of_the_Elements)
            end
        end
	end,
    ["Nature Swiftness"] = function()
        if ni.spell.cd(A1.restorsham_skills.Nature_Swiftness) == 0 then
            for _, member in ipairs(ni.members) do
                if not ni.unit.debuff(member.unit, raid_debuffs.Enfeeble) then
                    if UnitAffectingCombat("player")
                    and ni.unit.hpraw(member.unit) >= Healing_Wave_Healing*1.8
                    and ni.spell.valid(member.unit, A1.restorsham_skills.Healing_Wave, false, true, true) then
                        ni.spell.cast(A1.restorsham_skills.Nature_Swiftness)
                        return ni.spell.cast(A1.restorsham_skills.Healing_Wave, member.unit)
                    end
                end
            end
        end
    end,
	["Hex (control)"] = function ()
		local _, hex_enabled = GetSetting("gui_Hex")
        if not ni.player.issilenced() then
            if hex_enabled then
                if ni.spell.available(A1.restorsham_skills.Hex) then
                    for _, UnderControllMember in ipairs(ni.members) do
                        if ni.unit.isplayercontrolled(UnderControllMember.unit)
                        and ni.unit.isplayer(UnderControllMember.unit)
                        and ni.spell.valid(UnderControllMember.unit, A1.restorsham_skills.Hex, false, true, true) then
                            return ni.spell.cast(A1.restorsham_skills.Hex, UnderControllMember.unit)
                        end
                    end
                end
            end
        end
    end,
	["Totemic Recall"] = function()
        local FireTotem = select(2, GetTotemInfo(1))
        local EarthTotem = select(2, GetTotemInfo(2))
        local WaterTotem = select(2, GetTotemInfo(3))
        local AirTotem = select(2, GetTotemInfo(4))
        if not UnitAffectingCombat("player")
        and (FireTotem ~= "" or EarthTotem ~= "" or WaterTotem ~= "" or AirTotem ~= "")
        and not ni.spell.gcd() then
            return ni.spell.cast(A1.restorsham_skills.Totemic_Recall)
        end
    end,
}
ni.bootstrap.profile("A1 - Restoration Shaman v2.0", ench_rotation, ench_functions, menu_load, menu_unload)
