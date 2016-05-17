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

BotEcho('loading devourer_main...')

object.heroName = 'Hero_Devourer'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.hook = unitSelf:GetAbility(0)
    skills.fart = unitSelf:GetAbility(1)
    skills.skin = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)

    if skills.hook and skills.fart and skills.skin and skills.ulti and skills.stats then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local skillarray = {skills.fart, skills.hook, skills.hook, skills.skin, skills.hook, skills.ulti, skills.hook, skills.fart, skills.fart, skills.fart, skills.ulti, skills.skin, skills.skin, skills.skin, skills.stats, skills.ulti, skills.stats}

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

  if HasEnemiesInRange(core.unitSelf, 250) then
    if not core.unitSelf:HasState("State_Devourer_Ability2_Self") then
      BotEcho("OFF")
      object:OrderAbility(skills.fart)
    end
  else
    if core.unitSelf:HasState("State_Devourer_Ability2_Self") then
      BotEcho("ON")
      object:OrderAbility(skills.fart)
    end
  end
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

function HasEnemiesInRange(unit, range)
  local enemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local rangeSq = range * range
  local myPos = unit:GetPosition()
  for _, enemy in pairs(enemies) do
    if Vector3.Distance2DSq(enemy:GetPosition(), myPos) < rangeSq then
      return true
    end
  end
  return false
end

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)
  local myPos = core.unitSelf:GetPosition()

  local unitsNearby = core.AssessLocalUnits(object, myPos, skills.fart:GetRange())
  if next(unitsNearby) == nil then
    if skills.fart:IsActive() then
      core.unitSelf:GetBehaviour():OrderAbility(skills.fart)
    end
  else
    if not skills.fart:IsActive() then
      core.unitSelf:GetBehaviour():OrderAbility(skills.fart)
    end
  end

end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

local function CustomHarassUtilityOverride(hero)
  local nUtility = 0

  if skills.hook:CanActivate() then
    nUtility = nUtility + 10
  end

  if skills.ulti:CanActivate() then
    nUtility = nUtility + 40
  end

  return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf

  if unitSelf:IsChanneling() then
    return
  end

  local bActionTaken = false

  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, unitTarget) then
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget);

    local itemGhostMarchers = core.itemGhostMarchers

    local ulti = skills.ulti
    local ultiRange = ulti and (ulti:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(unitTarget)) or 0

    local bUseUlti = true

    if ulti and ulti:CanActivate() and bUseUlti and dist < ultiRange then
      bActionTaken = core.OrderAbilityEntity(botBrain, ulti, unitTarget)
    elseif (ulti and ulti:CanActivate() and bUseUlti and dist > ultiRange) then
      --move in when we want to ult
      local desiredPos = unitTarget:GetPosition()

      if itemPK and itemPK:CanActivate() then
        bActionTaken = core.OrderItemPosition(botBrain, unitSelf, itemPK, desiredPos)
      end

      if not bActionTaken and itemGhostMarchers and itemGhostMarchers:CanActivate() then
        bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemGhostMarchers)
      end

      if not bActionTaken and behaviorLib.lastHarassUtil < behaviorLib.diveThreshold then
        desiredPos = core.AdjustMovementForTowerLogic(desiredPos)
      end
      core.OrderMoveToPosClamp(botBrain, unitSelf, desiredPos, false)
      bActionTaken = true
    end
  end

  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

BotEcho('finished loading devourer_main')
