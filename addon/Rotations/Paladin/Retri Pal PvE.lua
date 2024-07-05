local UnitAffectingCombat,
IsLeftAltKeyDown,
IsRightAltKeyDown,
IsLeftShiftKeyDown,
UnitInVehicle,
IsMounted,
GetSpellInfo,
UnitIsDeadOrGhost,
IsCurrentSpell,
UnitCanAttack,
UnitInRaid,
GetRaidTargetIndex,
SetRaidTarget,
GetTime,
IsUsableSpell,
UnitLevel,
UnitCastingInfo,
GetItemCount,
GetNetStats,
UnitClass,
CancelUnitBuff,
GetSpellBonusHealing,
UnitIsUnit =
UnitAffectingCombat,
IsLeftAltKeyDown,
IsRightAltKeyDown,
IsLeftShiftKeyDown,
UnitInVehicle,
IsMounted,
GetSpellInfo,
UnitIsDeadOrGhost,
IsCurrentSpell,
UnitCanAttack,
UnitInRaid,
GetRaidTargetIndex,
SetRaidTarget,
GetTime,
IsUsableSpell,
UnitLevel,
UnitCastingInfo,
GetItemCount,
GetNetStats,
UnitClass,
CancelUnitBuff,
GetSpellBonusHealing,
UnitIsUnit;

local A1 = ni.utils.require("A1");
local RPmenu = {
    settingsfile = "A1-RetriPal-1.0.json",
    { type = "title", text = "Retribution Paladin v1.0" },
    { type = "separator" },
    { type = "entry", text = "\124T"..A1.pal_icons.Seal_of_Command..":22:22\124t АОЕ режим", enabled = true, key = "cfg_aoe" },
    { type = "entry", text = "\124T"..A1.pal_icons.Repentance..":22:22\124t Покаяние", enabled = false, key = "cfg_Repentance" },
    { type = "entry", text = "\124T"..A1.pal_icons.Flash_of_Light..":22:22\124t Вспышка света", enabled = false, key = "cfg_Flash_of_Light" },
    { type = "entry", text = "\124T"..A1.pal_icons.Cleanse..":22:22\124t Очищение", enabled = false, key = "cfg_Cleanse" },
    { type = "dropdown", menu = {
        { selected = false, value = A1.pal_skills.Greater_Blessing_of_Kings, text = "Каска" },
        { selected = true, value = A1.pal_skills.Greater_Blessing_of_Might, text = "Кулак" },
        { selected = false, value = A1.pal_skills.Greater_Blessing_of_Wisdom, text = "Крест" },
        { selected = false, value = 0, text = "Выкл" },
        }, key = "cfg_Greater_Blessing" },
    { type = "separator" },
    { type = "entry", text = "Лог", enabled = false, key = "cfg_debug" },
};
local function GetSetting(name)
  for k, v in ipairs(RPmenu) do
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
end;
local function OnLoad()
ni.GUI.AddFrame("A1-Retripal-1", RPmenu)
end;
local function OnUnLoad()
ni.GUI.DestroyFrame("A1-Retripal-1")
end;
local dontdispel = {38791, 30128, 28169, 38806, 70964, 31803, 60814, 68786, 34916, 34917, 34919, 48159, 48160, 30404, 30405, 31117, 34438, 35183, 43522, 47841, 47843, 65812, 68154, 68155, 68156, 44461, 55359, 55360, 55361, 55362, 61429, 30108, 34914, 74562, 74792, 70867, 70338, 70405 };
local freedomdebuff = {69649, 45524, 1715, 3408, 59638, 20164, 25809, 31589, 51585, 50040, 50041, 31124, 122, 44614, 339, 45334, 58179, 61391, 19306, 19185, 35101, 5116, 2974, 61394, 54644, 50245, 50271, 54706, 4167, 33395, 55080, 6136, 120, 116, 31589, 20170, 31125, 3409, 26679, 64695, 63685, 8056, 8034, 18118, 18223, 63311, 23694, 1715, 12323, 39965, 55536, 13099, 32859, 32065, 22800, 3604, 33967, 12023, 47698, 38316, 15063, 49717 };
for _, v in pairs(dontdispel) do
    ni.healing.debufftoblacklist(v)
end;
local FlashofLightHealing = (832 + GetSpellBonusHealing());
local HolyLightHealing = (5166 + 1.66*GetSpellBonusHealing());
local RProtation = {
    "Righteous Fury Check",
    "Pause",
    "Sacred Shield",
    "Lay on Hands",
    "Great blessing",
    "Cleanse: high priority",
    "Seals",
    "Divine Plea",
    "Repentance",
    "Hammer of Justice",
    "Combat Pause",
    "Hand of Freedom",
    "Hand of Salvation",
    "Avenging Wrath",
    "Targeting and attack",
    "Exorcism",
    "Hammer of Wrath",
    "Judgement",
    "Consecration",
    "Divine Storm",
    "Crusader Strike",
    "Cleanse: low priority",
    "Healing no combat",
};
local RPfunctions = {
    ["Pause"] = function ()
        if IsMounted()
        or UnitInVehicle("player")
        or ni.player.buff(GetSpellInfo(430))
        or ni.player.buff(GetSpellInfo(433))
        or ni.player.isconfused()
        or ni.player.isstunned()
        or UnitIsDeadOrGhost("player") then
			return true;
        end
		ni.vars.debug = select(2, GetSetting("cfg_debug"));
    end,
    ["Combat Pause"] = function ()
        if IsLeftShiftKeyDown()
        or ni.player.iscasting()
        or ni.player.ischanneling() then
			return true;
        end
    end,
	["Targeting and attack"] = function()
        if UnitAffectingCombat("player") then
            if A1.PlayerCanAttack() then
                if not IsCurrentSpell(A1.PWtalents.AutomaticAttack) then
                    return ni.spell.cast(A1.PWtalents.AutomaticAttack);
                end
            end
        end
        if ni.unit.exists("target")
        and (not ni.player.inmelee("target") or not ni.player.isfacing("target"))
        and UnitCanAttack("player", "target") then
            if IsCurrentSpell(A1.PWtalents.AutomaticAttack) then
                return ni.player.runtext("/stopattack");
            end
        end
		if UnitAffectingCombat("player")
		and (not ni.unit.exists("target") or (ni.unit.exists("target") and not UnitCanAttack("player", "target")) or UnitIsDeadOrGhost("target")) then
            if PlayerNearestEnemies() >= 1 then
                return ni.player.runtext("/targetenemy");
            end
        end
	end,
	["Righteous Fury Check"] = function()
        if ni.player.aura(A1.pal_skills.Righteous_Fury) then
            return CancelUnitBuff("player", A1.pal_skills.Righteous_Fury);
        end
	end,
	["Seals"] = function()
        if ni.spell.valid("target", A1.pal_skills.Judgement_of_Wisdom, false, true, false) then
            if not ni.player.aura(A1.pal_skills.Seal_of_Command) then
                if not ni.unit.isboss("target") then
                    if ni.spell.available(A1.pal_skills.Seal_of_Command) then
                        return ni.spell.cast(A1.pal_skills.Seal_of_Command);
                    end
                end
            end
            if not ni.player.aura(A1.pal_skills.Seal_of_Corruption) then
                if ni.unit.isboss("target")
                or ni.unit.isplayer("target") then
                    if ni.spell.available(A1.pal_skills.Seal_of_Corruption) then
                        return ni.spell.cast(A1.pal_skills.Seal_of_Corruption);
                    end
                end
            end
        end
	end,
    ["Hand of Salvation"] = function()
        if UnitInRaid("player") then
            for _, member in ipairs(ni.members) do
                local ally = member.unit;
                if ni.unit.threat(ally) >= 1
                and not Tank(ally)
                and ni.spell.available(A1.pal_skills.Hand_of_Salvation)
                and ni.spell.valid(ally, A1.pal_skills.Hand_of_Salvation, false, true, true) then
                    return ni.spell.cast(A1.pal_skills.Hand_of_Salvation, ally);
                end
            end
        end
    end,
    ["Hand of Freedom"] = function()
        if ni.spell.available(A1.pal_skills.Hand_of_Freedom) then
            for _, slowing in ipairs(freedomdebuff) do
                for _, member in ipairs(ni.members) do
                    local ally = member.unit;
                    if ni.unit.debuff(ally, slowing)
                    and ni.spell.valid(ally, A1.pal_skills.Hand_of_Freedom, false, true, true) then
                        return ni.spell.cast(A1.pal_skills.Hand_of_Freedom, ally);
                    end
                end
            end
        end
    end,
	["Divine Storm"] = function()
		local _, aoe_mode = GetSetting("cfg_aoe");
        if UnitAffectingCombat("player") then
            if aoe_mode then
                if not ni.player.isdisarmed() then
                    if ni.spell.available(A1.pal_skills.Divine_Storm)
                    and A1.PlayerCanAttack() then
                        return ni.spell.cast(A1.pal_skills.Divine_Storm);
                    end
                end
            end
        end
	end,
	["Crusader Strike"] = function()
        if UnitAffectingCombat("player") then
            if not ni.player.isdisarmed() then
                if ni.spell.available(A1.pal_skills.Crusader_Strike)
                and A1.PlayerCanAttack() then
                    return ni.spell.cast(A1.pal_skills.Crusader_Strike);
                end
            end
        end
	end,
	["Divine Plea"] = function()
        if UnitAffectingCombat("player") then
            if ni.unit.ttd("target") > 10
            or ni.player.power() < 65 then
                if ni.spell.available(A1.pal_skills.Divine_Plea) then
                    return ni.spell.cast(A1.pal_skills.Divine_Plea);
                end
            end
        end
	end,
	["Avenging Wrath"] = function()
        if UnitAffectingCombat("player") then
            if ni.unit.isboss("target") then
                if not ni.player.debuff(A1.pal_debuff.Forbearance) then
                    if ni.spell.available(A1.pal_skills.Avenging_Wrath)
                    and A1.PlayerCanAttack() then
                        return ni.spell.cast(A1.pal_skills.Avenging_Wrath);
                    end
                end
            end
        end
	end,
    ["Sacred Shield"] = function()
        if ni.spell.available(A1.pal_skills.Sacred_Shield) then
            if UnitAffectingCombat("player") then
                if not ni.unit.buff("player", A1.pal_skills.Sacred_Shield) then
				    return ni.spell.cast(A1.pal_skills.Sacred_Shield, "player")
                end
			end
        end
    end,
	["Exorcism"] = function()
		local _, Flash_of_Light_on = GetSetting("cfg_Flash_of_Light");
        if UnitAffectingCombat("player") then
            if ni.player.aura(A1.pal_skills.The_Art_of_War) then
                if Flash_of_Light_on then
                for _, member in ipairs(ni.members) do
                    local ally = member.unit;
                    if ni.unit.hpraw(ally) > FlashofLightHealing*2
                    and ni.spell.valid(ally, A1.pal_skills.Flash_of_Light, false, true, true)
                    and ni.spell.available(A1.pal_skills.Flash_of_Light)
                    and not ni.unit.debuff(ally, A1.raid_debuff.Enfeeble) then
                        return ni.spell.cast(A1.pal_skills.Flash_of_Light, ally);
                    end
                end
            elseif ni.spell.valid("target", A1.pal_skills.Exorcism, true, true, false)
            and ni.spell.available(A1.pal_skills.Exorcism) then
                return ni.spell.cast(A1.pal_skills.Exorcism);
            end
            end
        end
	end,
	["Lay on Hands"] = function()
        if UnitAffectingCombat("player") then
            for _, member in ipairs(ni.members) do
                local ally = member.unit;
                if ni.unit.hp(ally) < 12
                and ni.spell.valid(ally, A1.pal_skills.Lay_on_Hands, false, true, true)
                and ni.spell.available(A1.pal_skills.Lay_on_Hands)
                and ni.unit.debuff(ally, A1.raid_debuff.Enfeeble)
                and not UnitIsUnit("player", ally) then
                    return ni.spell.cast(A1.pal_skills.Lay_on_Hands, ally);
                end
            end
        end
	end,
	["Consecration"] = function()
		local _, aoe_mode = GetSetting("cfg_aoe");
        if UnitAffectingCombat("player") then
            if aoe_mode then
                if ni.spell.available(A1.pal_skills.Consecration)
                and A1.PlayerCanAttack() then
                    return ni.spell.cast(A1.pal_skills.Consecration);
                end
            end
        end
	end,
	["Cleanse: high priority"] = function()
        if ni.spell.available(A1.pal_skills.Cleanse) then
            local _, cleanse_mode = GetSetting("cfg_Cleanse");
            if cleanse_mode then
                for _, member in ipairs(ni.members) do
                    local ally = member.unit;
                    if ni.unit.debufftype(ally, "Magic|Disease|Poison")
                    and ni.healing.candispel(ally)
                    and ni.spell.valid(ally, A1.pal_skills.Cleanse, false, true, true) then
                        return ni.spell.cast(A1.pal_skills.Cleanse, ally);
                    end
                end
            end
        end
	end,
	["Cleanse: low priority"] = function()
        if ni.spell.available(A1.pal_skills.Cleanse) then
            for _, member in ipairs(ni.members) do
                local ally = member.unit;
                if ni.unit.debufftype(ally, "Magic|Disease|Poison")
                and ni.healing.candispel(ally)
                and ni.spell.valid(ally, A1.pal_skills.Cleanse, false, true, true) then
                    return ni.spell.cast(A1.pal_skills.Cleanse, ally);
                end
            end
        end
	end,
	["Judgement"] = function()
        if UnitAffectingCombat("player") then
            if ni.spell.available(A1.pal_skills.Judgement_of_Wisdom)
            and ni.spell.valid("target", A1.pal_skills.Judgement_of_Wisdom, false, true, false) then
                return ni.spell.cast(A1.pal_skills.Judgement_of_Wisdom);
            end
        end
	end,
    ["Hammer of Justice"] = function()
        if ni.spell.available(A1.pal_skills.Hammer_of_Justice) then
            if (ni.unit.iscasting("target") or ni.unit.ischanneling("target"))
            and ni.spell.valid("target", A1.pal_skills.Hammer_of_Justice, false, true, false) then
                return ni.spell.cast(A1.pal_skills.Hammer_of_Justice);
            end
        end
    end,
	["Repentance"] = function()
		local _, repentance_on = GetSetting("cfg_Repentance");
        if repentance_on and ni.unit.exists("focus") then
            if UnitAffectingCombat("player") then
                if ni.unit.creaturetype("focus") == 2
                or ni.unit.creaturetype("focus") == 3
                or ni.unit.creaturetype("focus") == 5
                or ni.unit.creaturetype("focus") == 6
                or ni.unit.creaturetype("focus") == 7 then
                    if ni.spell.available(A1.pal_skills.Repentance)
                    and ni.spell.valid("target", A1.pal_skills.Repentance, false, true, false) then
                        return ni.spell.cast(A1.pal_skills.Repentance);
                    end
                end
            end
        end
	end,
	["Holy Wrath"] = function()
        if UnitAffectingCombat("player") then
            if ni.spell.available(A1.pal_skills.Holy_Wrath) then
                if (ni.unit.creaturetype("target") == 6
                or ni.unit.creaturetype("target") == 3) then
                    if not ni.unit.isboss("target")
                    and ni.unit.iscasting("target") then
                        return ni.spell.cast(A1.pal_skills.Holy_Wrath);
                    end
                end
            end
        end
	end,
	["Hammer of Wrath"] = function()
        if UnitAffectingCombat("player") then
            if IsUsableSpell(A1.pal_skills.Hammer_of_Wrath)
            and ni.spell.available(A1.pal_skills.Hammer_of_Wrath)
            and ni.spell.valid("target", A1.pal_skills.Hammer_of_Wrath, true, true, false) then
                return ni.spell.cast(A1.pal_skills.Hammer_of_Wrath);
            end
        end
	end,
    ["Great blessing"] = function()
		local CurrentBlessing = GetSetting("cfg_Greater_Blessing")
        if CurrentBlessing == 0 then
            return false
        end
            if ni.spell.available(CurrentBlessing) then
            for _, member in ipairs(ni.members) do
                local ally = member.unit;
                if ni.unit.buffremaining(ally, CurrentBlessing) < 360
                and ni.spell.valid(ally, CurrentBlessing, false, true, true) then
                    return ni.spell.cast(CurrentBlessing, ally);
                end
            end
        end
    end,
	["Healing no combat"] = function()
        if not UnitAffectingCombat("player")
        and not ni.player.ismoving() then
            for _, member in ipairs(ni.members) do
                local ally = member.unit;
                if ni.unit.hpraw(ally) > HolyLightHealing
                and ni.spell.valid(ally, A1.pal_skills.Holy_Light, false, true, true)
                and ni.spell.available(A1.pal_skills.Holy_Light) then
                    return ni.spell.cast(A1.pal_skills.Holy_Light, ally);
                end
                if ni.unit.hpraw(ally) > FlashofLightHealing
                and ni.spell.valid(ally, A1.pal_skills.Flash_of_Light, false, true, true)
                and ni.spell.available(A1.pal_skills.Flash_of_Light) then
                    return ni.spell.cast(A1.pal_skills.Flash_of_Light, ally);
                end
            end
        end
	end,
}
ni.bootstrap.profile("Retri Pal PvE", RProtation, RPfunctions, OnLoad, OnUnLoad)