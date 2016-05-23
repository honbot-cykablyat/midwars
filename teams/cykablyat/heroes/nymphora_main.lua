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

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

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

  if skills.ulti:CanLevelUp() then
    skills.ulti:LevelUp()
  elseif skills.heal:CanLevelUp() then
    skills.heal:LevelUp()
  elseif skills.mana:CanLevelUp() then
    skills.mana:LevelUp()
  elseif skills.stun:CanLevelUp() then
    skills.stun:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end
end

function sign(x)
  return (x<0 and -1) or 1
end

function behaviorLib.CustomHarassUtility(unit)
  return 0
  local unitSelf = core.unitSelf;
  local level = unitSelf:GetLevel() - unit:GetLevel();
  level = sign(level) * level * level;
  local mana = unitSelf:GetMana() / skills.stun:GetManaCost() * 3;
  local health = unitSelf:GetHealthPercent() * 7 + (1 - unit:GetHealthPercent()) * 6;
  local cds = 0;
  for _, skill in pairs(skills) do
    if skill:CanActivate() then
      cds = cds + 2;
    end
  end
  local harass = level + mana + health + cds;
  if core.GetClosestAllyTower(unitSelf:GetPosition(), 900) and core.GetClosestAllyTower(unit:GetPosition(), 1000) then
    harass = harass + 20;
  end
  local enemies_close = 0;
  for _, unit in pairs(core.localUnits["EnemyHeroes"]) do
    local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unit:GetPosition());
    if nDistSq < 200 * 200 then
      enemies_close = enemies_close + 1;
    end
  end
  if enemies_close == 1 then
    harass = harass + 20;
  end
  if enemies_close > 1 then
    return 0;
  end
  return harass;
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
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride


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
    if not unit:IsInvulnerable() and not unit:IsHero() and unit:GetOwnerPlayerID() == nil then
      local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unit:GetPosition())
      local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unit, true) 
      local nTempHP = unit:GetHealth()
      if nDistSq < nAttackRangeSq * 3 * 3 and nTempHP < nMinionHP then
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
        nUtility = 100 --25
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

BotEcho('finished loading nymphora_main')
