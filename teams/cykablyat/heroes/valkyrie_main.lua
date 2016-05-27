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

BotEcho('loading valkyrie_main...')

object.heroName = 'Hero_Valkyrie'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 4, LongSolo = 2, ShortSupport = 0, LongSupport = 0, ShortCarry = 4, LongCarry = 3}

behaviorLib.StartingItems =
  {"Item_DuckBoots", "Item_HealthPotion", "Item_MinorTotem", "Item_PretendersCrown", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems =
  {"Item_Energizer", "Item_Sicarius", "Item_Steamboots"}
behaviorLib.MidItems =
  {"Item_Dawnbringer", "Item_ManaBurn1", "Item_ManaBurn2", "Item_Pierce"}
behaviorLib.LateItems =
  {"Item_Wingbow", "Item_Immunity", "Item_Protect", "Item_Sasuke"}
--------------------------------
-- Skills
--------------------------------
behaviorLib.tBehaviors = {}
tinsert(behaviorLib.tBehaviors, behaviorLib.PickRuneBehavior)
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
tinsert(behaviorLib.tBehaviors, generics.TakeHealBehavior)
tinsert(behaviorLib.tBehaviors, generics.GroupBehavior)
tinsert(behaviorLib.tBehaviors, generics.DodgeBehavior)
tinsert(behaviorLib.tBehaviors, behaviorLib.HitBuildingBehavior)

local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.call = unitSelf:GetAbility(0)
    skills.javelin = unitSelf:GetAbility(1)
    skills.leap = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.call and skills.javelin and skills.leap and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local skillarray = {skills.javelin, skills.leap, skills.javelin, skills.call, skills.call, skills.call, skills.call, skills.ulti, skills.javelin, skills.javelin, skills.ulti, skills.leap, skills.leap, skills.leap, skills.attributeBoost, skills.ulti}

  if skillarray[unitSelf:GetLevel()] then
    local lvSkill = skillarray[unitSelf:GetLevel()]
    if lvSkill:CanLevelUp() then
      lvSkill:LevelUp()
    end
  else
    if skills.attributeBoost:CanLevelUp() then
      skills.attributeBoost:LevelUp()
    end
  end
end

function sign(x)
  return (x<0 and -1) or 1
end

function behaviorLib.CustomHarassUtility(unit)
  local unitSelf = core.unitSelf;
  local health = unitSelf:GetHealthPercent();
  return -(1 - health) * 10
end

-- Custom healAtWell behaviorLib

local healAtWellOldUtility = behaviorLib.HealAtWellBehavior["Utility"]

local function HealAtWellUtilityOverride(botBrain)
  if core.unitSelf:GetHealthPercent() and core.unitSelf:GetHealthPercent() < 0.50 then
    local util = 1
    local heroMul = 10
    local pos = core.unitSelf:GetPosition()
    local enemyHeroes = core.teamBotBrain.GetEnemyTeam(2200, range)
    if enemyHeroes then
      for _, _ in pairs(enemyHeroes) do
          util = util * heroMul
      end
    end
    local allyHeroes = core.teamBotBrain.GetAllyTeam(2200, range)
    if allyHeroes then
      for _, _ in pairs(allyHeroes) do
          util = util / (heroMul * core.unitSelf:GetHealthPercent())
      end
    end
    return util
  end
  return healAtWellOldUtility(botBrain)
end

behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverride

-- end healAtWell

-- Custom HitBuildingUtility

local oldHitBuildingUtility = behaviorLib.HitBuildingBehavior["Utility"]

local function NewHitBuildingUtility(botBrain)
  local addToUtil = 0
  local scaleOldUtil = 2
  return scaleOldUtil*(oldHitBuildingUtility(botBrain)) + addToUtil
end

behaviorLib.HitBuildingBehavior["Utility"] = NewHitBuildingUtility
-- end HitBuilding

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
  elseif state == "GROUP" then
    return 0
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

  local call = skills.call
  if call and call:CanActivate() and targetHero:GetPosition() and Vector3.Distance2D(targetHero:GetPosition(), unitSelf:GetPosition()) < 650 then
    bActionTaken = core.OrderAbility(botBrain, call)
  end

  if not bActionTaken then
    return harassOldExecute(botBrain)
  end
end

behaviorLib.HarassHeroBehavior["Utility"] = harassUtilityOverride
behaviorLib.HarassHeroBehavior["Execute"] = harassExecuteOverride

local stunTarget = nil
local function throwSpearUtility(botBrain)
  local unitSelf = core.unitSelf;
  if not skills.javelin:CanActivate() then
    return 0
  end
  local target = nil
  local health = 1
  for _, enemy in pairs(core.localUnits["EnemyHeroes"]) do
    if enemy:GetHealthPercent() < health then
      local pos = generics.predict_location(unitSelf, enemy, 857.14)
      local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), pos);
      if nDistSq < 1000 * 1000 then
        if generics.IsFreeLine(unitSelf:GetPosition(), pos, true) then
          target = enemy
          health = enemy:GetHealthPercent()
        end
      end
    end
  end
  if target then
    stunTarget = target
    return 40
  end
  return 0
end

local function throwSpearExecute(botBrain)
  local unitSelf = core.unitSelf;
  if stunTarget and skills.javelin:CanActivate() then
    local pos = generics.predict_location(unitSelf, stunTarget, 857.14)
    core.OrderAbilityPosition(botBrain, skills.javelin, pos);
  end
end

local JavelinBehavior = {}
JavelinBehavior["Utility"] = throwSpearUtility
JavelinBehavior["Execute"] = throwSpearExecute
JavelinBehavior["Name"] = "Javelin"
tinsert(behaviorLib.tBehaviors, JavelinBehavior)

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

-- custom destroy building behavior

local function DestroyBuildingUtility(botBrain)
  for _, enemyBuilding in pairs(core.localUnits["EnemyBuildings"]) do
    -- BotEcho(enemyBuilding:GetTypeName())
    if enemyBuilding:IsBase() then
      BotEcho("base!")
      behaviorLib.heroTarget = enemyBuilding
      return math.ceil(0.5 - enemyBuilding:GetHealthPercent()) * (1 - enemyBuilding:GetHealthPercent()) * 200
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

local function GetAttackDamageMinOnCreep(unitCreepTarget)
  local unitSelf = core.unitSelf
  local nDamageMin = unitSelf:GetAttackDamageMax(); --core.GetFinalAttackDamageAverage(unitSelf)

  if core.itemHatchet then
    nDamageMin = nDamageMin * core.itemHatchet.creepDamageMul
  end

  return nDamageMin
end

local function LastHitUtility(botBrain)
  local unitSelf = core.unitSelf
  if not unitSelf:IsAttackReady() then
    return 0;
  end
  local tEnemies = core.localUnits["Enemies"]
  local unitWeakestMinion = nil
  local nMinionHP = 99999999
  local nUtility = 0
  for _, unit in pairs(tEnemies) do
    if not unit:IsInvulnerable() and not unit:IsHero() and unit:GetOwnerPlayerID() == nil and unit:IsAlive() then
      local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unit:GetPosition())
      local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unit, true)
      local nTempHP = unit:GetHealth()
      if nDistSq < nAttackRangeSq * 3 * 3 and nTeampHP and nTempHP < nMinionHP then
        unitWeakestMinion = unit
        nMinionHP = nTempHP
      end
    end
  end

  if unitWeakestMinion ~= nil then
    core.unitMinionTarget = unitWeakestMinion
    --minion lh > creep lh
    local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitWeakestMinion:GetPosition())
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitWeakestMinion, true) * 3 * 3
    if nDistSq < nAttackRangeSq then
      if nMinionHP <= GetAttackDamageMinOnCreep(unitWeakestMinion) then --core.GetFinalAttackDamageAverage(unitSelf) * (1 - unitWeakestMinion:GetPhysicalResistance()) then
        -- LastHit Minion
        nUtility = 60 --25
      else
        -- Harass Minion
        -- PositionSelf 20 and AttackCreeps 21
        -- positonSelf < minionHarass < creep lh || deny
        --nUtility = 80 --20.5
      end
    end
  end
  return nUtility
end

local nLastMoveToCreepID = nil
local function LastHitExecute(botBrain)
  local bActionTaken = false
  local unitSelf = core.unitSelf
  local sCurrentBehavior = core.GetCurrentBehaviorName(botBrain)

  local unitCreepTarget = nil
  if sCurrentBehavior == "AttackEnemyMinions" then
    unitCreepTarget = core.unitMinionTarget
  else
    unitCreepTarget = core.unitCreepTarget
  end

  if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then
    --Get info about the target we are about to attack
    local vecSelfPos = unitSelf:GetPosition()
    local vecTargetPos = unitCreepTarget:GetPosition()
    local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitCreepTarget, true)

    -- Use Loggers Hatchet
    local itemHatchet = core.itemHatchet
    --nested if for clarity and to reduce optimization which is negligible.
    if itemHatchet and itemHatchet:CanActivate() then --valid hatchet
      if unitCreepTarget:GetTeam() ~= unitSelf:GetTeam() and core.IsLaneCreep(unitCreepTarget) then --valid creep
        if core.GetAttackSequenceProgress(unitSelf) ~= "windup" and nDistSq < (600 * 600) then --valid positioning
          if GetAttackDamageMinOnCreep(unitCreepTarget) > core.unitCreepTarget:GetHealth() then --valid HP
            bActionTaken = botBrain:OrderItemEntity(itemHatchet.object or itemHatchet, unitCreepTarget.object or unitCreepTarget, false)
          end
        end
      end
    end
    if bActionTaken then
      return true;
    end
    --Only attack if, by the time our attack reaches the target
    -- the damage done by other sources brings the target's health
    -- below our minimum damage, and we are in range and can attack right now-
    if nDistSq <= nAttackRangeSq and unitSelf:IsAttackReady() then
      if unitSelf:GetAttackType() == "melee" then
        local nDamageMin = GetAttackDamageMinOnCreep(unitCreepTarget)

        if unitCreepTarget:GetHealth() <= nDamageMin then
          if core.GetAttackSequenceProgress(unitSelf) ~= "windup" then
            bActionTaken = core.OrderAttack(botBrain, unitSelf, unitCreepTarget)
          else
            bActionTaken = true
          end
        else
          bActionTaken = core.OrderHoldClamp(botBrain, unitSelf, false)
        end
      else
        bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)
      end
    else
      if unitSelf:GetAttackType() == "melee" then
        if core.GetLastBehaviorName(botBrain) ~= behaviorLib.AttackCreepsBehavior.Name and unitCreepTarget:GetUniqueID() ~= behaviorLib.nLastMoveToCreepID then
          behaviorLib.nLastMoveToCreepID = unitCreepTarget:GetUniqueID()
          --If melee, move closer.
          local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
          bActionTaken = core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecDesiredPos, false)
        end
      else
        --If ranged, get within 70% of attack range if not already
        -- This will decrease travel time for the projectile
        if (nDistSq > nAttackRangeSq * 0.5) then
          local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
          bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
        --If within a good range, just hold tight
        else
          bActionTaken = core.OrderHoldClamp(botBrain, unitSelf, false)
        end
      end
    end
  end
  return bActionTaken
end

local LastHitBehaviour = {}
LastHitBehaviour["Utility"] = LastHitUtility
LastHitBehaviour["Execute"] = LastHitExecute
LastHitBehaviour["Name"] = "LastHit"
tinsert(behaviorLib.tBehaviors, LastHitBehaviour)

local function escapeUtility(botBrain)
  local unitSelf = core.unitSelf
  if eventsLib.recentDamageHalfSec > 0.025 * core.unitSelf:GetMaxHealth() then
    if skills.leap:CanActivate() then
      local angle = core.HeadingDifference(unitSelf, core.GetClosestAllyTower(unitSelf:GetPosition()):GetPosition())
      if angle < 0.25 then
        return 100
      end
    end
    if skills.ulti:CanActivate() then
      return 100
    end
  end
  return 0
end

local function escapeExecute(botBrain)
  local unitSelf = core.unitSelf
  if skills.leap:CanActivate() then
    local angle = core.HeadingDifference(unitSelf, core.GetClosestAllyTower(unitSelf:GetPosition()):GetPosition())
    if angle < 0.25 then
      return core.OrderAbility(botBrain, skills.leap)
    end
  end
  if skills.ulti:CanActivate() then
    return core.OrderAbility(botBrain, skills.ulti)
  end
end

local EscapeBehaviour = {}
EscapeBehaviour["Utility"] = escapeUtility
EscapeBehaviour["Execute"] = escapeExecute
EscapeBehaviour["Name"] = "Escape"
tinsert(behaviorLib.tBehaviors, EscapeBehaviour)
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

BotEcho('finished loading valkyrie_main')
