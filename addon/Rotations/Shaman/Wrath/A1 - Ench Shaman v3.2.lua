local A1 = ni.utils.require("A1")
local GetSpellInfo, GetWeaponEnchantInfo, UnitAffectingCombat, GetTotemInfo, DestroyTotem = GetSpellInfo, GetWeaponEnchantInfo, UnitAffectingCombat, GetTotemInfo, DestroyTotem
local ench_menu = {
    settingsfile = "A1 - Ench Shaman v3.2.json",
    { type = "separator" },
    { type = "title", text = "|cff266bffEnch Shaman PvE |cffcece0cA1 v3.2" },
    { type = "separator" },
    { type = "entry", text = "\124T"..A1.ench_icons.Purge..":22:22\124t |cff266bffРазвеивание магии", enabled = true, key = "gui_Purge" },
	{ type = "entry", text = "\124T"..A1.ench_icons.Cure_Toxins..":20:20\124t |cff266bffОздоровление", enabled = true, key = "gui_Cure_Toxins" },
	{ type = "entry", text = "\124T"..A1.ench_icons.Hex..":20:20\124t |cff266bffЖаба", enabled = true, key = "gui_Hex" },
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
ni.GUI.AddFrame("ShamEnch32", ench_menu)
end
local function menu_unload()
ni.GUI.DestroyFrame("ShamEnch32")
end
local Healing_Wave_Healing = (3250 + 1.6114*GetSpellBonusHealing())
local LastAction, LastTotemicRecall, LastTotemicCall = 0, 0, 0
local ench_rotation = {
    "Altkey",
    "Cache",
    "RaceBuff",
    "Pause",
    "Test",
    "Stopattack",
    "Hex (control)",
    "Hex (focus)",
    "Enchant Weapon",
    "Shield",
    "Shamanistic Rage",
    "Zandalar",
    "Trinket",
    "Cure Toxins (members)",
    "Cure Toxins (player)",
    "Wind Shear",
    "Purge",
    "Combat Pause",
    "Totemic Recall",
    "Call of the Elements",
    "Fire Totems",
    "Feral Spirit",
    "Targetenemy",
    "Autoattack",
    "Lightning Bolt",
    "Fire Nova",
    "Stormstrike",
    "Lava Lash",
    "Fire Shock",
    "Earth Shock",
}
local ench_functions = {
	["Altkey"] = function()
		if IsLeftAltKeyDown() or IsRightAltKeyDown() then
            print("ALT KEY IS SHIFTED")
        end
	end,
	["Cache"] = function()
		PlayerNearestEnemies()
	end,
	["Test"] = function()
		if ni.unit.exists("Тотем магмы VII") then
            ni.player.runtext("Стоит тотем магмы")
        end
	end,
    ["Pause"] = function ()
        local framerate = GetFramerate()
        if IsMounted()
        or UnitInVehicle("player")
        or ni.player.buff(GetSpellInfo(430))
        or ni.player.buff(GetSpellInfo(433))
        or ni.player.isconfused()
        or ni.player.isfleeing()
        or ni.player.isstunned()
        or UnitIsDeadOrGhost("player")
        or IsLeftShiftKeyDown()
        or framerate < 18 then
            return true
        end
		ni.vars.debug = select(2, GetSetting("gui_Debug"))
    end,
    ["RaceBuff"] = function ()
        if not ni.player.buff(310802) then
            if ni.spell.available(310802) then
                return ni.spell.cast(310802)
            end
        end
    end,
    ["Combat Pause"] = function ()
        if IsLeftShiftKeyDown()
		or (ni.player.debuff(305131) and ni.player.debuffremaining(305131) < 2)
        or (ni.player.debuff(69762) and ni.player.debuffremaining(69762) > 19)
        or (ni.player.debuff(69762) and ni.player.debuffremaining(69762) < 8)
        or (ni.unit.hp("target") == 100 and UnitInRaid("player"))
        or ni.player.iscasting()
        or ni.player.ischanneling()
        or ni.unit.debuff("target", A1.ench_skills.Hex) then
            return true
        end
    end,
	["Autoattack"] = function()
		if A1.PlayerCanAttack() then
            if not IsCurrentSpell(A1.ench_skills.AutomaticAttack) then
                ni.spell.cast(A1.ench_skills.AutomaticAttack)
                return true
            end
        end
    end,
    ["Stopattack"] = function()
        if ni.unit.exists("target")
        and (not ni.player.inmelee("target") or not ni.player.isfacing("target"))
        and UnitCanAttack("player", "target") then
            if IsCurrentSpell(A1.ench_skills.AutomaticAttack) then
                ni.player.runtext("/stopattack")
                return true
            end
        end
    end,
    ["Targetenemy"] = function()
		if UnitAffectingCombat("player")
		and (not ni.unit.exists("target") or (ni.unit.exists("target") and not UnitCanAttack("player", "target")) or UnitIsDeadOrGhost("target")) then
            if PlayerNearestEnemies() >= 1 then
                ni.player.runtext("/targetenemy")
                return true
            end
        end
	end,
	["Stormstrike"] = function()
        if ni.spell.available(A1.ench_skills.Stormstrike) then
            if A1.PlayerCanAttack() then
                ni.spell.cast(A1.ench_skills.Stormstrike)
                return true
            end
        end
	end,
	["Lava Lash"] = function()
            if ni.spell.available(A1.ench_skills.Lava_Lash) then
                if A1.PlayerCanAttack() then
                    ni.spell.cast(A1.ench_skills.Lava_Lash)
                    return true
                end
            end
	end,
	["Call of the Elements"] = function()
        local FireTotem = select(2, GetTotemInfo(1))
        local EarthTotem = select(2, GetTotemInfo(2))
        local WaterTotem = select(2, GetTotemInfo(3))
        local AirTotem = select(2, GetTotemInfo(4))
        if ni.spell.available(A1.ench_skills.Call_of_the_Elements)
        and A1.PlayerCanAttack()
        and not ni.player.ismoving()
        and ni.unit.ttd("target") > 25 then
            if (FireTotem == "" and EarthTotem == "" and WaterTotem == "" and AirTotem == "") then
                ni.spell.cast(A1.ench_skills.Call_of_the_Elements)
                return true
            end
        end
	end,
	["Totemic Recall"] = function()
		local _, Call_of_the_Elements_enabled = GetSetting("gui_Call_of_the_Elements")
        local FireTotem = select(2, GetTotemInfo(1))
        local EarthTotem = select(2, GetTotemInfo(2))
        local WaterTotem = select(2, GetTotemInfo(3))
        local AirTotem = select(2, GetTotemInfo(4))
        --if Call_of_the_Elements_enabled then
            if not UnitAffectingCombat("player")
            and (FireTotem ~= "" or EarthTotem ~= "" or WaterTotem ~= "" or AirTotem ~= "")
            and ni.spell.available(36936) then
                ni.spell.cast(A1.ench_skills.Totemic_Recall)
                return true
            end
        --end
    end,
	["Feral Spirit"] = function()
        if ni.unit.isboss("target")
        or IsLeftControlKeyDown() then
            if ni.spell.available(A1.ench_skills.Feral_Spirit)
            and ni.spell.valid("target", A1.ench_skills.Earth_Shock, true, true)
            and ni.unit.ttd("target") > 25  then
                ni.spell.cast(A1.ench_skills.Feral_Spirit)
                return true
            end
        end
	end,
	["Zandalar"] = function()
        if ni.spell.cd(A1.ench_skills.Zandalar) == 0 then
            if A1.PlayerCanAttack() then
                ni.spell.cast(A1.ench_skills.Shamanistic_Rage)
                ni.spell.cast(A1.ench_skills.Zandalar)
                return true
            end
        end
	end,
	["Trinket"] = function()
        if ni.player.slotcastable(13)
		and ni.player.slotcd(13) == 0 then
            if ni.player.buff(A1.ench_skills.Zandalar) then
                ni.player.useinventoryitem(13)
                return true
            end
        end
	end,
	["Shamanistic Rage"] = function()
        if ni.player.power(0) < 70
        and ni.unit.ttd("target") > 25 then
            if ni.spell.available(A1.ench_skills.Shamanistic_Rage) then
                if ni.player.inmelee("target")
                and UnitCanAttack("player", "target") then
                    ni.spell.cast(A1.ench_skills.Shamanistic_Rage)
                    ni.spell.cast(A1.ench_skills.Zandalar)
                    ni.player.useinventoryitem(13)
                    return true
                end
            end
        end
	end,
	["Enchant Weapon"] = function()
        local MainHandEnchant, _, _, OfHandEnchant = GetWeaponEnchantInfo()
        if MainHandEnchant == nil then
            if ni.spell.available(A1.ench_skills.ench1) then
                ni.spell.cast(A1.ench_skills.ench1)
                return true
            end
        end
        if OfHandEnchant == nil then
            if ni.spell.available(A1.ench_skills.ench2) then
                ni.spell.cast(A1.ench_skills.ench2)
                return true
            end
        end
	end,
	["Shield"] = function()
        if ni.player.buffremaining(A1.ench_skills.Lightning_Shield) < 180 then
            if ni.spell.available(A1.ench_skills.Lightning_Shield) then
                ni.spell.cast(A1.ench_skills.Lightning_Shield)
                return true
            end
        end
	end,
    ["Lightning Bolt"] = function()
        if not ni.player.issilenced() then
            if ni.player.buffstacks(A1.ench_skills.Maelstrom_Weapon) == 5 then
                if ni.player.hpraw() < Healing_Wave_Healing*0.7 then
                    if PlayerNearestEnemies() == 1 or ni.unit.isboss("target") then
                        if ni.spell.available(A1.ench_skills.Lightning_Bolt)
                        and ni.spell.valid("target", A1.ench_skills.Lightning_Bolt, true, true)
                        and ni.unit.debuff("target", A1.ench_skills.Stormstrike, "player") then
                            ni.spell.cast(A1.ench_skills.Lightning_Bolt)
                            return true
                        end
                    end
                    if PlayerNearestEnemies() > 1 then
                        if ni.spell.available(A1.ench_skills.Chain_Lightning)
                        and ni.spell.valid("target", A1.ench_skills.Chain_Lightning, true, true)
                        and ni.unit.debuff("target", A1.ench_skills.Stormstrike, "player") then
                            ni.spell.cast(A1.ench_skills.Chain_Lightning)
                            return true
                        end
                    end
                end
                if ni.player.hpraw() > Healing_Wave_Healing*0.7 then
                    if ni.spell.available(49273) then
                        ni.spell.cast(49273, "player")
                        return true
                    end
                end
            end
        end
    end,
    ["Earth Shock"] = function()
        if not ni.player.issilenced() then
            if ni.unit.isboss("target") then
                if ni.spell.available(A1.ench_skills.Earth_Shock)
                and ni.spell.valid("target", A1.ench_skills.Earth_Shock, true, true) then
                    ni.spell.cast(A1.ench_skills.Earth_Shock)
                    return true
                end
            end
        end
    end,
    ["Fire Shock"] = function()
        if not ni.player.issilenced() then
            if ni.unit.isboss("target") then
                if ni.unit.debuffremaining("target", A1.ench_skills.Fire_Shock, "player") <= 3 then
                    if ni.spell.available(A1.ench_skills.Fire_Shock)
                    and ni.spell.valid("target", A1.ench_skills.Fire_Shock, true, true) then
                        ni.spell.cast(A1.ench_skills.Fire_Shock)
                        return true
                    end
                end
            end
        end
    end,
    ["Fire Totems"] = function ()
        local FireTotem = select(2, GetTotemInfo(1))
        if UnitAffectingCombat("player")
        and not ni.player.ismoving()
        and ni.unit.ttd("target") > 8 then
            if FireTotem == "" then
                if ni.spell.available(58734)
                and A1.PlayerCanAttack() then
                    ni.spell.cast(58734)
                    return true
                end
            end
        end
    end,
    ["Fire Nova"] = function ()
        local FireTotem = select(2, GetTotemInfo(1))
        if not ni.player.issilenced() then
            if UnitAffectingCombat("player") then
                if FireTotem ~= "" then
                    --if ni.player.buff(16246) then
                        if ni.spell.available(A1.ench_skills.Fire_Nova)
                        and A1.PlayerCanAttack()
                        and (PlayerNearestEnemies() >= 2
                        or ni.unit.isboss("target")) then
                            ni.spell.cast(A1.ench_skills.Fire_Nova)
                            return true
                        end
                    --end
                end
            end
        end
    end,
    ["Purge"] = function ()
        local _, Purge_enabled = GetSetting("gui_Purge")
        if not ni.player.issilenced() then
            if Purge_enabled then
                if UnitAffectingCombat("player") then
                    if ni.spell.available(A1.ench_skills.Purge)
                    and ni.spell.valid("target", A1.ench_skills.Purge, false, true)
                    and ni.unit.bufftype("target", "Magic") then
                        ni.spell.cast(A1.ench_skills.Purge)
                        return true
                    end
                end
            end
        end
    end,
    ["Cure Toxins (members)"] = function()
        local _, enabled = GetSetting("gui_Cure_Toxins")
        if not ni.player.issilenced() then
            if enabled then
                if ni.spell.available(A1.ench_skills.Cure_Toxins) then
                    for _, member in ipairs(ni.members) do
                        if ni.unit.debufftype(member.unit, "Disease|Poison")
                        and ni.healing.candispel(member.unit)
                        and ni.spell.valid(member.unit, A1.ench_skills.Cure_Toxins, false, true, true) then
                            ni.spell.cast(A1.ench_skills.Cure_Toxins, member.unit)
                            return true
                        end
                    end
                end
            end
        end
    end,
    ["Cure Toxins (player)"] = function()
        local _, enabled = GetSetting("gui_Cure_Toxins")
        if not ni.player.issilenced() then
            --if enabled then
                if ni.spell.available(A1.ench_skills.Cure_Toxins) then
                    if ni.player.debufftype("Disease|Poison")
                    and ni.healing.candispel("player") then
                        ni.spell.cast(A1.ench_skills.Cure_Toxins, "player")
                        return true
                    end
                end
            --end
        end
    end,
	["Wind Shear"] = function()
		local _, wind_shear_enabled = GetSetting("gui_Purge")
		if wind_shear_enabled then
            if ni.spell.shouldinterrupt("target")
            or ni.unit.ischanneling("target") then
                if ni.spell.cd(A1.ench_skills.Wind_Shear) == 0
                and ni.player.power() >= 5
                and ni.spell.valid("target", A1.ench_skills.Wind_Shear, true, true, false) then
                    ni.spell.cast(A1.ench_skills.Wind_Shear)
                    return true
                end
            end
		end
	end,
	["Hex (control)"] = function ()
		local _, hex_enabled = GetSetting("gui_Hex")
        if not ni.player.issilenced() then
            if hex_enabled then
                if ni.spell.available(A1.ench_skills.Hex) then
                    for _, UnderControllMember in ipairs(ni.members) do
                        if ni.unit.isplayercontrolled(UnderControllMember.unit)
                        and ni.unit.isplayer(UnderControllMember.unit)
                        and ni.spell.valid(UnderControllMember.unit, A1.ench_skills.Hex, false, true, true) then
                            ni.spell.cast(A1.ench_skills.Hex, UnderControllMember.unit)
                            return true
                        end
                    end
                end
            end
        end
    end,
    ["Hex (focus)"] = function ()
        if not ni.player.issilenced() then
            if ni.unit.exists("focus") then
                if ni.spell.available(A1.ench_skills.Hex)
                and ni.spell.valid("focus", A1.ench_skills.Hex, false, true, true) then
                    if ni.unit.creaturetype("focus") == 1 or ni.unit.creaturetype("focus") == 7 then
                        ni.spell.cast(A1.ench_skills.Hex, "focus")
                        return true
                    end
                end
            end
        end
	end,
}
ni.bootstrap.profile("A1 - Ench Shaman v3.2", ench_rotation, ench_functions, menu_load, menu_unload)
