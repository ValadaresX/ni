local A1 = ni.utils.require("A1")
local DruidMenu = {
    settingsfile = "Druid Leveling pve.json",
    { type = "title", text = "|cffe08400Druid |cff83e000leveling pve |cffe08400A1 v1.0" },
    { type = "separator" },
    { type = "entry", text = "\124T"..A1.DruidIcons.Growl..":22:22\124t |cffe08400Агро", enabled = true, key = "k_taunts" },
    { type = "separator" },
    { type = "entry", text = "|cff00a4e0Лог", enabled = false, key = "gui_debug" },
}
local function GetSetting(name)
  for k, v in ipairs(DruidMenu) do
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
local function OnLoad()
ni.GUI.AddFrame("A1-Druid_Lev", DruidMenu)
end
local function OnUnLoad()
ni.GUI.DestroyFrame("A1-Druid_Lev")
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
local agressiveenemies = {}
local highrangeenemies = {}
local BadBuff = {9438}
local DruidRotation = {
    "Altkey",
    "Pause",
    --"Forms",
    "Combat Pause",
    "Feral_autoattack",
    "Bear_Maul",
    "Bear_Mangle",
    "Bear_Growl",
    "Bear_FaerieFire_Feral",
    "Bear_DemoralizingRoar",
    "Bear_Swipe",
    "Cat_Rip",
    "Cat_Rake",
    --"Moonkin_Moonfire",
    --"Moonkin_Wrath",
}
local DruidFunctions = {
	["Altkey"] = function()
		if IsLeftAltKeyDown() or IsRightAltKeyDown() then
            print("ALT KEY IS SHIFTED")
        end
	end,
	["Forms"] = function()
        if UnitAffectingCombat("player") then
            if ni.player.inmelee("target")
            and not ni.player.buff(A1.DruidSkills.BearForm)
            and ni.spell.available(A1.DruidSkills.BearForm) then
                ni.spell.cast(A1.DruidSkills.BearForm)
            end
            if not ni.player.inmelee("target")
            and ni.player.aura(A1.DruidSkills.BearForm) then
                CancelUnitBuff("player", "Облик медведя")
            end
        end
        if not UnitAffectingCombat("player") then
            if not ni.player.inmelee("target")
            and ni.player.aura(A1.DruidSkills.BearForm) then
                CancelUnitBuff("player", "Облик медведя")
            end
        end
	end,
    ["Pause"] = function ()
        if IsMounted()
        or UnitInVehicle("player")
        or ni.player.buff(GetSpellInfo(430))
        or ni.player.buff(GetSpellInfo(433))
        or ni.player.isconfused()
        or ni.player.isstunned()
        or UnitIsDeadOrGhost("player") then
			return true
        end
		ni.vars.debug = select(2, GetSetting("gui_debug"))
    end,
	["Feral_autoattack"] = function()
        if ni.player.buff(A1.DruidSkills.BearForm) then
            agressiveenemies = ni.player.enemiesinrange(3)
            if A1.PlayerCanAttack() then
                if not IsCurrentSpell(A1.PWtalents.AutomaticAttack) then
                    ni.spell.cast(A1.PWtalents.AutomaticAttack)
                    return true
                end
            end
        end
        if ni.unit.exists("target")
        and (not ni.player.inmelee("target") or not ni.player.isfacing("target"))
        and UnitCanAttack("player", "target") then
            if IsCurrentSpell(A1.PWtalents.AutomaticAttack) then
                ni.player.runtext("/stopattack")
                return true
            end
        end
		if UnitAffectingCombat("player")
		and (not ni.unit.exists("target") or (ni.unit.exists("target") and not UnitCanAttack("player", "target")) or UnitIsDeadOrGhost("target")) then
            if #agressiveenemies >= 1 then
                ni.player.runtext("/targetenemy")
                return true
            end
        end
		--if UnitAffectingCombat("player")
        --and not UnitInRaid("player") then
        --    local icon=GetRaidTargetIndex("target")
		--if icon == nil
        --and not ni.unit.isboss("target") then
        --        return SetRaidTarget("target", 3)
        --    end
        --end
	end,
    ["Combat Pause"] = function ()
        for _, v in ipairs(BadBuff) do
            if IsLeftShiftKeyDown()
            or ni.player.iscasting()
            or ni.player.ischanneling()
            or ni.unit.buff("target", v) then
                return true
            end
        end
    end,
    ["Moonkin_Wrath"] = function()
		if not ni.player.buff(A1.DruidSkills.BearForm) then
            if ni.spell.available(A1.DruidSkills.Wrath) then
                if not ni.player.ismoving()
                and ni.spell.valid("target", A1.DruidSkills.Wrath, true, true) then
                    ni.spell.cast(A1.DruidSkills.Wrath)
                    return true
                end
            end
        end
    end,
    ["Moonkin_Moonfire"] = function()
		if not ni.player.buff(A1.DruidSkills.BearForm) then
            if UnitAffectingCombat("player") then
                if ni.spell.available(A1.DruidSkills.Moonfire) then
                    if ni.spell.valid("target", A1.DruidSkills.Moonfire, true, true)
                    and ni.unit.debuffremaining("target", A1.DruidSkills.Moonfire, "player") < 0.5 then
                        ni.spell.cast(A1.DruidSkills.Moonfire)
                        return true
                    end
                end
            end
        end
    end,
	["Cat_Rip"] = function ()
		if ni.player.buff(A1.DruidSkills.CatForm) then
            if A1.PlayerCanAttack()
            and ni.spell.available(A1.DruidSkills.Rip)
            and GetComboPoints("player") == 5 then
                ni.spell.cast(A1.DruidSkills.Rip)
                return true
            end
        end
	end,
	["Cat_Rake"] = function ()
		if ni.player.buff(A1.DruidSkills.CatForm) then
            if A1.PlayerCanAttack()
            and ni.spell.available(A1.DruidSkills.Rake)
            and GetComboPoints("player") > 5 then
                ni.spell.cast(A1.DruidSkills.Rip)
                return true
            end
        end
	end,
	["Bear_Maul"] = function ()
		if ni.player.buff(A1.DruidSkills.BearForm) then
            if not IsCurrentSpell(A1.DruidSkills.Maul) then
                if A1.PlayerCanAttack()
                and ni.player.power() > 15 then
                    --if #agressiveenemies == 1 then
                        ni.spell.cast(A1.DruidSkills.Maul)
                        return true
                    --end
                end
            end
        end
	end,
	["Bear_Swipe"] = function ()
        agressiveenemies = ni.player.enemiesinrange(7)
		if ni.player.buff(A1.DruidSkills.BearForm) then
            if ni.spell.available(A1.DruidSkills.Swipe_Bear)
            and ni.player.power() >= 20 then
                if #agressiveenemies >= 2 then
                    ni.spell.cast(A1.DruidSkills.Swipe_Bear)
                    return true
                end
            end
        end
	end,
	["Bear_DemoralizingRoar"] = function ()
        agressiveenemies = ni.player.enemiesinrange(5)
		if ni.player.buff(A1.DruidSkills.BearForm) then
            if (ni.unit.isboss("target") or #agressiveenemies >= 6) then
                if ni.spell.available(A1.DruidSkills.DemoralizingRoar)
                and A1.PlayerCanAttack() then
                    if not ni.unit.debuff("target", A1.DruidSkills.DemoralizingRoar) or ni.unit.debuffremaining("target", A1.DruidSkills.DemoralizingRoar) <= 5 then
                        ni.spell.cast(A1.DruidSkills.DemoralizingRoar)
                        return true
                    end
                end
            end
        end
	end,
	["Bear_Mangle"] = function ()
		if ni.player.buff(A1.DruidSkills.BearForm) then
            if ni.spell.available(A1.DruidSkills.Mangle_Bear)
            and A1.PlayerCanAttack() then
                if ((ni.unit.debuffremaining("target", A1.DruidSkills.Mangle_Bear) <= 5
                or ni.player.power() > 30) and ni.unit.isboss("target"))
                or ni.player.buff(A1.DruidSkills.Berserk)
                or ni.player.power() > 70 then
                    ni.spell.cast(A1.DruidSkills.Mangle_Bear)
                    return true
                end
            end
        end
	end,
	["Bear_Growl"] = function()
        local _, taunts_enabled = GetSetting("k_taunts")
        if ni.spell.cd(A1.DruidSkills.Growl) == 0
        and ni.spell.cd(A1.DruidSkills.FaerieFire_Feral) ~= 0
        and UnitAffectingCombat("player")
        and ni.player.buff(A1.DruidSkills.BearForm) then
            highrangeenemies = ni.player.enemiesinrange(29)
            for i = 1, #ni.members do
                local Ally = ni.members[i].unit
                for TauntEnemy in ipairs(highrangeenemies) do
                    local lowthreatunit = highrangeenemies[TauntEnemy].guid
                    if taunts_enabled then
                        if not Tank(Ally)
                        and UnitAffectingCombat(lowthreatunit)
                        and ni.unit.threat(Ally, lowthreatunit) == 3
                        and (not (ni.unit.buff(lowthreatunit, 12021) or ni.unit.debuff(lowthreatunit, A1.DruidSkills.Growl) or ni.unit.debuff(lowthreatunit, A1.PWtalents.Provoke)))
                        and BlackListedMonster(lowthreatunit)
                        and BlackListedMonsterWithDebuff(lowthreatunit) then
                            if ni.spell.valid(lowthreatunit, A1.DruidSkills.Growl, false, true, false) then
                                ni.spell.cast(A1.DruidSkills.Growl, lowthreatunit)
                                return true
                            end
                        end
                    end
                end
            end
        end
	end,
	["Bear_FaerieFire_Feral"] = function()
        local _, taunts_enabled = GetSetting("k_taunts")
        if ni.spell.available(A1.DruidSkills.FaerieFire_Feral)
        and UnitAffectingCombat("player")
        and ni.player.buff(A1.DruidSkills.BearForm) then
            highrangeenemies = ni.player.enemiesinrange(29)
            for i = 1, #ni.members do
                local Ally = ni.members[i].unit
                for TauntEnemy in ipairs(highrangeenemies) do
                    local lowthreatunit = highrangeenemies[TauntEnemy].guid
                    if taunts_enabled then
                        if not Tank(Ally)
                        and UnitAffectingCombat(lowthreatunit)
                        and ni.unit.threat(Ally, lowthreatunit) == 3
                        and (not (ni.unit.buff(lowthreatunit, 12021) or ni.unit.debuff(lowthreatunit, A1.DruidSkills.Growl) or ni.unit.debuff(lowthreatunit, A1.PWtalents.Provoke)))
                        and BlackListedMonster(lowthreatunit)
                        and BlackListedMonsterWithDebuff(lowthreatunit) then
                            if ni.spell.valid(lowthreatunit, A1.DruidSkills.FaerieFire_Feral, false, true, false) then
                                ni.spell.cast(A1.DruidSkills.FaerieFire_Feral, lowthreatunit)
                                return true
                            end
                        end
                    end
                end
            end
        end
	end,
	["Tree_Regrowth"] = function()
		if not ni.player.buff(A1.DruidSkills.BearForm) then
            if ni.spell.available(A1.DruidSkills.Regrowth)
            and not ni.player.ismoving() then
                for i = 1, #ni.members do
                    local Ally = ni.members[i].unit
                    local AllyHP = ni.members[i].hp
                    if AllyHP < 60 then
                        if not ni.unit.buff(Ally, A1.DruidSkills.Regrowth)
                        and ni.spell.valid(Ally, A1.DruidSkills.Regrowth, false, true, true) then
                            ni.spell.cast(A1.DruidSkills.Regrowth, Ally)
                            return true
                        end
                    end
                end
            end
        end
	end,
	["Tree_Rejuvenation"] = function()
		if not ni.player.buff(A1.DruidSkills.BearForm) then
            if ni.spell.available(A1.DruidSkills.Rejuvenation) then
                for i = 1, #ni.members do
                    local Ally = ni.members[i].unit
                    local AllyHP = ni.members[i].hp
                    if AllyHP < 90 and UnitAffectingCombat(Ally) then
                        if not ni.unit.buff(Ally, A1.DruidSkills.Rejuvenation)
                        and ni.spell.valid(Ally, A1.DruidSkills.Rejuvenation, false, true, true) then
                            ni.spell.cast(A1.DruidSkills.Rejuvenation, Ally)
                            return true
                        end
                    end
                end
            end
        end
	end,
}
ni.bootstrap.profile("Druid lev pve A1 1.0", DruidRotation, DruidFunctions, OnLoad, OnUnLoad)