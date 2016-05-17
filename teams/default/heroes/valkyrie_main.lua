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
runfile "bots/teams/default/hook_arrow.lua"


local core, eventsLib, behaviorLib, metadata, skills, hook_arrow = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills, object.hook_arrow

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

--------------------------------
-- Skills
--------------------------------
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

  if skills.ulti:CanLevelUp() then
    skills.ulti:LevelUp()
  elseif skills.javelin:CanLevelUp() then
    skills.javelin:LevelUp()
  elseif skills.leap:CanLevelUp() then
    skills.leap:LevelUp()
  elseif skills.call:CanLevelUp() then
    skills.call:LevelUp()
  else
    skills.attributeBoost:LevelUp()
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
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

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

function behaviorLib.CustomRetreatExecute(botBrain)
	local leap = skills.leap
	local unitSelf = core.unitSelf
	local angle = core.HeadingDifference(unitSelf, core.allyMainBaseStructure:GetPosition())
	

	if leap and leap:CanActivate() and angle < 0.5 then
		return core.OrderAbility(botBrain, leap)
	end
	return false
end

local function CustomHarassUtilityFnOverride(target)
  local nUtil = 0
  local creepLane = core.GetFurthestCreepWavePos(core.tMyLane, core.bTraverseForward)
  local myPos = core.unitSelf:GetPosition()

  --jos potu käytössä niin ei agroilla
  if core.unitSelf:HasState(core.idefHealthPotion.stateName) then

    return -10000
  end

  --jos tornin rangella ni ei mennä
  if core.GetClosestEnemyTower(myPos, 720) then

    return -10000
  end

 --  if target and target:GetHealth() < 250 and core.unitSelf:GetHealth() > 400 then
 --   return 100
 -- end

  if core.unitSelf:GetHealth() < 200 then
     return -10000
  end

  local unitsNearby = core.AssessLocalUnits(object, myPos,100)
  --jos ei omia creeppejä 500 rangella, niin ei aggroa
  for id, creep in pairs(unitsNearby.EnemyCreeps) do
      if(creep:GetAttackType() == "ranged" or Vector3.Distance2D(myPos, creep:GetPosition()) < 20) then
      core.DrawXPosition(creep:GetPosition())
        return -10000
      end 
  end

  return 50
  --if core.NumberElements(unitsNearby.AllyCreeps) == 0 then
  --   return 0
  --  end

  --if unitTarget and unitTarget:GetHealth() < 250 and core.unitSelf:GetHealth() > 400 then
  --  return 100
  --end



  --return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget

  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf


  local bActionTaken = false

  --since we are using an old pointer, ensure we can still see the target for entity targeting

  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local PositionSelfLogicOld = behaviorLib.PositionSelfLogic
local function PositionSelfLogicOverride(botBrain)
  local vecDesiredPos, unitTarget = PositionSelfLogicOld(botBrain)	
  vecDesiredPos = core.AdjustMovementForTowerLogic(vecDesiredPos)
  return vecDesiredPos, unitTarget
end
behaviorLib.PositionSelfLogic = PositionSelfLogicOverride

local function DetermineArrowTarget(arrow)
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = arrow:GetRange()
  local maxDistanceSq = maxDistance * maxDistance
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 999999999
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    core.DrawXPosition(enemyPos, "yellow", 50)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget and hook_arrow.IsFreeLine(myPos, enemyPos) then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local arrowTarget = nil
local function ArrowUtility(botBrain)
  local javelin = skills.javelin
  if javelin and javelin:CanActivate() then
    local unitTarget = DetermineArrowTarget(javelin)
    if unitTarget then
      arrowTarget = unitTarget:GetPosition()
      core.DrawXPosition(arrowTarget, "green", 50)
      return 60
    end
  end
  arrowTarget = nil
  return 0
end
local function ArrowExecute(botBrain)
  local javelin = skills.javelin
  if javelin and javelin:CanActivate() and arrowTarget then
    return core.OrderAbilityPosition(botBrain, javelin, arrowTarget)
  end
  return false
end
local ArrowBehavior = {}
ArrowBehavior["Utility"] = ArrowUtility
ArrowBehavior["Execute"] = ArrowExecute
ArrowBehavior["Name"] = "Arrowing"
tinsert(behaviorLib.tBehaviors, ArrowBehavior)

BotEcho('finished loading valkyrie_main')