local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic = true
object.bRunBehaviors = true
object.bUpdates = true
object.bUseShop = true

object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"
runfile "bots/teams/cykablyat/generics.lua"

local generics, core, eventsLib, behaviorLib, metadata, skills = object.generics, object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading nymphora_main...')

object.heroName = 'Hero_Fairy'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 0, ShortSolo = 0, LongSolo = 0, ShortSupport = 5, LongSupport = 5, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
behaviorLib.tBehaviors = {}
tinsert(behaviorLib.tBehaviors, behaviorLib.PushBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.HealAtWellBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.AttackCreepsBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.DontBreakChannelBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.PositionSelfBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.RetreatFromThreatBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.PreGameBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.ShopBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.StashBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.HarassHeroBehavior)
tinsert(behaviorLib.tBehaviors, generics.GroupBehavior)
tinsert(behaviorLib.tBehaviors, generics.DodgeBehavior)
tinsert(behaviorLib.tBehaviors, generics.RallyTeamBehavior)
tinsert(behaviorLib.tBehaviors, generics.HitBuildingBehavior)

behaviorLib.StartingItems =
  {"Item_CrushingClaws", "Item_GuardianRing", "Item_ManaBattery", "Item_MinorTotem"}
behaviorLib.LaneItems =
  {"Item_EnhancedMarchers", "Item_ManaRegen3", "Item_Marchers", "Item_MysticVestments"}
behaviorLib.MidItems =
  {"Item_PortalKey", "Item_Silence", "Item_ManaBurn1", "Item_Morph"}
behaviorLib.LateItems =
  {"Item_Astrolabe", "Item_BarrierIdol", "Item_FrostfieldPlate"}

local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.heal = unitSelf:GetAbility(0)
    skills.mana = unitSelf:GetAbility(1)
    skills.stun = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.heal and skills.mana and skills.stun and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

   local skillarray = {skills.heal, skills.stun, skills.heal, skills.stun, skills.heal, skills.stun, skills.heal, skills.stun, skills.ulti, skills.mana, skills.ulti, skills.mana, skills.mana, skills.mana, skills.attributeBoost, skills.ulti}

  local lvSkill = skillarray[unitSelf:GetLevel()];
  if lvSkill then
    if lvSkill:CanLevelUp() then
      lvSkill:LevelUp()
    end
  else
    if skills.attributeBoost:CanLevelUp() then
      skills.attributeBoost:LevelUp()
    end
  end
end

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  -- custom code here
  generics.AnalyzeAllyHeroPosition(core.unitSelf)
  core.teamBotBrain:UpdateHeroBehavior(core.unitSelf, object.sCurrentBehaviorName)
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

-- Custom healAtWell behaviorLib

local healAtWellOldUtility = behaviorLib.HealAtWellBehavior["Utility"]

local function HealAtWellUtilityOverride(botBrain)
  if core.unitSelf:GetHealthPercent() and core.unitSelf:GetHealthPercent() < 0.15 then
    return 100
  end
  return healAtWellOldUtility(botBrain)
end

behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverride

-- end healAtWell

local harassOldUtility = behaviorLib.HarassHeroBehavior["Utility"]
local harassOldExecute = behaviorLib.HarassHeroBehavior["Execute"]

local function harassUtilityOverride(botBrain)
  local old = harassOldUtility(botBrain)
  local hpPc = core.unitSelf:GetHealthPercent()
  local state = generics.positionStatus
  BotEcho("state is " .. state .. " old " .. old)
  if state == "ATTACK" and hpPc > 0.15 then
    return 99
    -- return old + 80
  elseif state == "HARASS" and hpPc > 0.15 then
    return old + 20
    -- return old + 40
  else
    return old
  end
end

local function harassExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  -- local targetHero = core.teamBotBrain:FindBestEnemyTargetInRange(unitSelf:GetPosition(), 1000)
  local targetHero = generics.FindBestEnemyTargetInRange(800)
  if targetHero == nil then
    return false
  end
  behaviorLib.heroTarget = targetHero

  --core.DrawXPosition(targetHero:GetPosition(), "red", 400)

  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), targetHero:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, targetHero) then
    local stun = skills.stun
    if stun:CanActivate() and core.unitSelf:GetMana() > 50 then
      local nRange = stun:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityPosition(botBrain, stun, targetHero:GetPosition())
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, targetHero)
      end
    end
  end

  if not bActionTaken then
    return harassOldExecute(botBrain)
  end
end

behaviorLib.HarassHeroBehavior["Utility"] = harassUtilityOverride
behaviorLib.HarassHeroBehavior["Execute"] = harassExecuteOverride

-- custom destroy building behavior

local function DestroyBuildingUtility(botBrain)
  for _, enemyBuilding in pairs(core.localUnits["EnemyBuildings"]) do
    -- BotEcho(enemyBuilding:GetTypeName())
    if enemyBuilding:IsBase() then
      behaviorLib.heroTarget = enemyBuilding
      local value = math.ceil(0.75 - enemyBuilding:GetHealthPercent()) * (1 - enemyBuilding:GetHealthPercent()) * 250
      return value
    end
  end
  return 0
end

local function DestroyBuildingExecute(botBrain)
  core.OrderAttack(botBrain, core.unitSelf, behaviorLib.heroTarget)
  return true
end

local DestroyBuildingBehavior = {}
DestroyBuildingBehavior["Utility"] = DestroyBuildingUtility
DestroyBuildingBehavior["Execute"] = DestroyBuildingExecute
DestroyBuildingBehavior["Name"] = "DestroyBuilding"
tinsert(behaviorLib.tBehaviors, DestroyBuildingBehavior)

local stunTarget = nil
local function StunUtility(botBrain)
  if not skills.stun:CanActivate() then
    return 0
  end
  local target = generics.FindBestEnemyTargetInRange(600)
  if target and target:IsHero() then
    stunTarget = target
    return 100
  end
  local health = 1
  for _, enemy in pairs(core.localUnits["EnemyHeroes"]) do
    local pos = generics.predict_location(core.unitSelf, enemy, 1000);
    local nDistSq = Vector3.Distance2DSq(core.unitSelf:GetPosition(), pos);
    local range = skills.stun:GetRange()
    if nDistSq < range * range then
      if enemy:GetHealthPercent() < health then
        target = enemy
        health = enemy:GetHealthPercent()
      end
    end
  end
  if not target then
    return 0
  end
  stunTarget = target
  return 80
end

local function StunExecute(botBrain)
  if stunTarget and skills.stun:CanActivate() then
    local pos = generics.predict_location(core.unitSelf, stunTarget, 700)
    if pos then
      core.OrderAbilityPosition(botBrain, skills.stun, pos);
    end
  end
end

local stunBehaviour = {}
stunBehaviour["Utility"] = StunUtility
stunBehaviour["Execute"] = StunExecute
stunBehaviour["Name"] = "Stun"
tinsert(behaviorLib.tBehaviors, stunBehaviour)

local healTarget = nil
local function HealUtility(botBrain)
  if not skills.heal:CanActivate() then
    return 0
  end
  local target = nil
  local health = 1
  for _, ally in pairs(core.localUnits["AllyHeroes"]) do
    if ally:GetHealthPercent() < health then
      target = ally
      health = ally:GetHealthPercent()
    end
  end
  if health < 0.50 then
    healTarget = target
    return 100
  end
  return 0
end

local function HealExecute(botBrain)
  if skills.heal:CanActivate() then
    local pos = generics.predict_location(core.unitSelf, healTarget, 1000)
    core.teamBotBrain.healPosition = pos;
    if pos then
      core.OrderAbilityPosition(botBrain, skills.heal, pos);
    end
  end
end

local healBehaviour = {}
healBehaviour["Utility"] = HealUtility
healBehaviour["Execute"] = HealExecute
healBehaviour["Name"] = "Heal"
tinsert(behaviorLib.tBehaviors, healBehaviour)

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)
  if EventData["SourceUnit"] and core.unitSelf:GetUniqueID() == EventData["SourceUnit"]:GetUniqueID() then
    if EventData["Type"] == "Ability" then
      core.teamBotBrain.healPosition = nil;
    end
  end
  -- custom code here
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

BotEcho('finished loading nymphora_main')
