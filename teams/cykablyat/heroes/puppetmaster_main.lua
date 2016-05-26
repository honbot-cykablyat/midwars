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

BotEcho('loading puppetmaster_main...')

object.heroName = 'Hero_PuppetMaster'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 4, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 4, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.hold = unitSelf:GetAbility(0)
    skills.show = unitSelf:GetAbility(1)
    skills.whip = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)

    if skills.hold and skills.show and skills.whip and skills.ulti and skills.stats then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local skillarray = {skills.whip, skills.hold, skills.show, skills.whip, skills.hold, skills.ulti, skills.whip, skills.show, skills.whip, skills.hold, skills.ulti, skills.hold, skills.show, skills.show, skills.stats, skills.ulti, skills.stats}

  if unitSelf:GetLevel() < 17 then
    local lvSkill = skillarray[unitSelf:GetLevel()]
    if lvSkill:CanLevelUp() then
      lvSkill:LevelUp()
    end
  else
    if skills.stats:CanLevelUp() then
      skills.stats:LevelUp()
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
  -- BotEcho("lasdfasdf")
  -- BotEcho(core.tMyLane)
  -- core.printTable(core.tMyLane)
  local state = generics.AnalyzeAllyHeroPosition(core.unitSelf)
  -- BotEcho("puppet state: " .. state)
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

tinsert(behaviorLib.tBehaviors, generics.TakeHealBehavior)
tinsert(behaviorLib.tBehaviors, generics.GroupBehavior)
tinsert(behaviorLib.tBehaviors, generics.DodgeBehavior)

-- Custom healAtWell behaviorLib

local healAtWellOldUtility = behaviorLib.HealAtWellBehavior["Utility"]

local function HealAtWellUtilityOverride(botBrain)
  if core.unitSelf:GetHealthPercent() and core.unitSelf:GetHealthPercent() < 0.15 then
    return 999
  end
  return healAtWellOldUtility(botBrain)
end

behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverride

-- custom destroy building behavior

local function DestroyBuildingUtility(botBrain)
  for _, enemyBuilding in pairs(core.localUnits["EnemyBuildings"]) do
    -- BotEcho(enemyBuilding:GetTypeName())
    if enemyBuilding:IsBase() then
      behaviorLib.heroTarget = enemyBuilding
      local value = math.ceil(0.5 - enemyBuilding:GetHealthPercent()) * (1 - enemyBuilding:GetHealthPercent()) * 200
      -- BotEcho("base!" .. value)
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

-- custom retreat behavior

-- local function TeamRetreatUtility(botBrain)
--   if core.teamBotBrain:GetState and core.teamBotBrain:GetState() == "TEAM_RETREAT" then
--     return 100
--   end
-- end
--
-- local function TeamRetreatExecute(botBrain)
--   if stunTarget and skills.stun:CanActivate() then
--     local pos = generics.predict_location(core.unitSelf, stunTarget, 1000)
--     core.OrderAbilityPosition(botBrain, skills.stun, pos);
--   end
-- end

-- Custom harass behaviour

local harassOldUtility = behaviorLib.HarassHeroBehavior["Utility"]
local harassOldExecute = behaviorLib.HarassHeroBehavior["Execute"]

local function harassUtilityOverride(botBrain)
  local old = harassOldUtility(botBrain)
  local hpPc = core.unitSelf:GetHealthPercent()
  local state = generics.AnalyzeAllyHeroPosition(core.unitSelf)
  BotEcho("state is " .. state .. " old " .. old)
  if state == "ATTACK" and hpPc > 0.15 then
    return old + 80
  elseif state == "HARASS" and hpPc > 0.15 then
    return old + 40
  else
    return old
  end
end

local function harassExecuteOverride(botBrain)
  local unitSelf = core.unitSelf
  -- local targetHero = core.teamBotBrain:FindBestEnemyTargetInRange(unitSelf:GetPosition(), 1000)
  local targetHero = generics.FindBestEnemyTargetInRange(1000)
  if targetHero == nil then
    return false
  end
  behaviorLib.heroTarget = targetHero

  --core.DrawXPosition(targetHero:GetPosition(), "red", 400)

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, targetHero) then

    local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), targetHero:GetPosition())

    local ulti = skills.ulti
    local nRange = ulti:GetRange()
    if not targetHero:IsMagicImmune() and ulti:CanActivate() and nTargetDistanceSq < (nRange * nRange) then
      bActionTaken = core.OrderAbilityEntity(botBrain, ulti, targetHero)
    end

    local hold = skills.hold
    nRange = hold:GetRange()
    if not bActionTaken and not targetHero:IsStunned() and not targetHero:IsMagicImmune() and hold:CanActivate() and not targetHero:HasState("State_PuppetMaster_Ability2") and nTargetDistanceSq < (nRange * nRange) then
      bActionTaken = core.OrderAbilityEntity(botBrain, hold, targetHero)
    end

    local show = skills.show
    nRange = show:GetRange()
    local unitsNearby = core.AssessLocalUnits(botBrain, targetHero, 400)

    local nEnemies = core.NumberElements(unitsNearby.Enemies)

    if not bActionTaken and not targetHero:IsStunned() and not targetHero:IsMagicImmune() and not targetHero:HasState("State_PuppetMaster_Ability1") and show:CanActivate() and nTargetDistanceSq < (nRange * nRange) and nEnemies > 0 then
      bActionTaken = core.OrderAbilityEntity(botBrain, show, targetHero)
    end
  end

  if not bActionTaken then
    return harassOldExecute(botBrain)
  end
end

behaviorLib.HarassHeroBehavior["Utility"] = harassUtilityOverride
behaviorLib.HarassHeroBehavior["Execute"] = harassExecuteOverride

-- custom kill enemy hero behavior

-- function KillEnemyHeroUtility(botBrain)
--   if core.teamBotBrain.GetState and core.teamBotBrain:GetState() == "LANE_AGGRESSIVELY" then
--     local targetHero = core.teamBotBrain:GetTeamTarget()
--     if targetHero == nil or not targetHero:IsValid() then
--       return false --can not execute, move on to the next behavior
--     end
--     return 100
--   end
-- end
--
-- function KillEnemyHeroExecute(botBrain)
--   local healPos = core.teamBotBrain.healPosition
--   if healPos then
--   	botBrain:OrderPosition(core.unitSelf.object, "move", healPos, "none", nil, true)
-- 	end
-- end

-- ComboWombo behaviour

local atks_per_sec = 0.71; -- default value
local hold_time = {2.5, 3.25, 4, 4.75};
local show_time = {2.5, 3, 3.5, 4};
local castableSpells = {0, 1, 3};
local ulti_dmg_multiplier = {1.4, 1.6, 1.8};
-- Lasts until target gets more than 1500 units away from spawned Puppet, or until Puppet is killed.
local combo = {3, 1, 5, 0, 5}; -- ulti, show, *attack, hold, *attack,

-- For checking if PuppetMaster has enough mana for Combo and no spells are in cooldown
local function ableToCombo()
  local unitSelf = core.unitSelf
  local manaCost = 0;
  for _, v in pairs(castableSpells) do
    local skill = unitSelf:GetAbility(v)
    if not skill:CanActivate() then
      return false;
    end
    manaCost = manaCost + skill:GetManaCost();
  end
  return manaCost <= core.unitSelf:GetMana();
end

-- Helper function for calculating the possible damage
local function calculateDamage(self, enemyHero)
  local avg_dmg = core.GetFinalAttackDamageAverage(self);
  local avg_hits_hold = math.floor(hold_time[skills.hold:GetLevel()] / atks_per_sec);
  local avg_hits_show = math.floor(show_time[skills.show:GetLevel()] / atks_per_sec);
  local ulti_multiplier = ulti_dmg_multiplier[skills.ulti:GetLevel()];
  local dmg = ulti_multiplier*(enemyHero:GetPhysicalResistance() * avg_dmg * (avg_hits_hold + avg_hits_show));
  return dmg;
end;

-- Utility function for Combo that is checked on every tick
local comboIndex = 1;
local target = nil
local function ComboUtility(botBrain)
  local unitSelf = core.unitSelf
  local unitPos = unitSelf:GetPosition();
  -- core.DrawDebugLine(unitPos, Vector3.Create(unitPos.x,  unitPos.y+400))
  -- core.DrawXPosition(unitPos, "red", 1200)
  if comboIndex > 1 then
    return 999;
  end
  if not ableToCombo() then
    return 0;
  end
  -- Loop through enemy heros in 400 radius
  for _, unit in pairs(core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 600).EnemyHeroes) do
    local dmg = calculateDamage(unitSelf, unit);
    --if dmg >= unit:GetHealth() or true then
      behaviorLib.herotarget = unit;
      target = unit
      return 999;
    -- end
  end
  return 0;
end

-- Execution function for the Combo
local lastCast = 0;
local lastAttacked = 0;
local wait = 0;
local attacksLeft = 0;
local function ComboExecute(botBrain)
  -- Check if execution of combo has been completed
  if comboIndex > 5 then
    comboIndex = 1;
    wait = 0;
    lastCast = 0;
    lastAttacked = 0;
    return true;
  end
  local unitSelf = core.unitSelf

  if attacksLeft > 0 then
    if (HoN:GetMatchTime() - lastAttacked > 600) then
      -- unneeded?
      behaviorLib.herotarget = target;
      core.OrderAttack(botBrain, unitSelf, target)
      attacksLeft = attacksLeft - 1;
      lastAttacked = HoN:GetMatchTime();
      -- If no attacks left move on to next combo state
      if attacksLeft == 0 then
        comboIndex = comboIndex + 1;
      end
    end
  elseif (HoN:GetMatchTime() - lastCast) > wait and (comboIndex == 3 or comboIndex == 5) then
   lastCast = 0;
   wait = 0;
    -- attack
    if comboIndex == 3 then
      attacksLeft = math.floor(hold_time[skills.hold:GetLevel()] / atks_per_sec) - 1;
    else
      attacksLeft = math.floor(show_time[skills.show:GetLevel()] / atks_per_sec) + 2;
    end
    -- is this needed?
    behaviorLib.herotarget = target;
    core.OrderAttack(botBrain, unitSelf, target)
    lastAttacked = HoN:GetMatchTime();
  else
    -- cast a spell
    local skill = unitSelf:GetAbility(combo[comboIndex]);
  if skill and skill:CanActivate() and (HoN:GetMatchTime() - lastCast) > wait then
      wait = skill:GetAdjustedCastTime();
      lastCast = HoN:GetMatchTime();
      core.OrderAbilityEntity(botBrain, skill, target);
      comboIndex = comboIndex + 1;
  end
  end
  return false;
end

-- Declaration of this custom Combo-behaviour which is checked on every tick if the PuppetMaster is able to do it => spells ready and enemy hero in range
local ComboBehavior = {}
ComboBehavior["Utility"] = ComboUtility
ComboBehavior["Execute"] = ComboExecute
ComboBehavior["Name"] = "Combo"
-- disable this behaviour
-- tinsert(behaviorLib.tBehaviors, ComboBehavior)

-- Custom HitBuildingUtility

local oldHitBuildingUtility = behaviorLib.HitBuildingBehavior["Utility"]

local function NewHitBuildingUtility(botBrain)
  local addToUtil = 0
  local scaleOldUtil = 2
  return scaleOldUtil*(oldHitBuildingUtility(botBrain)) + addToUtil
end

behaviorLib.HitBuildingBehavior["Utility"] = NewHitBuildingUtility
-- end HitBuilding

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

BotEcho('finished loading puppetmaster_main')
