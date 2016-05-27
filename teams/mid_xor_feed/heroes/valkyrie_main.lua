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

runfile "bots/teams/mid_xor_feed/core.lua"
runfile "bots/teams/mid_xor_feed/behaviorLib.lua"
runfile "bots/teams/mid_xor_feed/botbraincore.lua"
runfile "bots/teams/mid_xor_feed/eventsLib.lua"
runfile "bots/teams/mid_xor_feed/metadata.lua"

runfile "bots/teams/mid_xor_feed/commonLib.lua"

local core, eventsLib, behaviorLib, metadata, skills, generics = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills, object.commonLib

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading valkyrie_main...')

object.heroName = 'Hero_Valkyrie'


behaviorLib.StartingItems = {"Item_MysticPotpourri", "2 Item_MinorTotem", "Item_ManaBattery", "Item_PowerSupply"}
behaviorLib.LaneItems = {"Item_BrainOfMaliken", "Item_Replenish", "Item_PretendersCrown", "Item_CrushingClaws", "Item_Strength5", "Item_Astrolabe"}
behaviorLib.MidItems = {"Item_Marchers", "Item_Punchdagger", "Item_EnhancedMarchers", "Item_Warhammer", "Item_Pierce 2"}
behaviorLib.LateItems = {"Item_Immunity", "Item_Confluence", "Item_Strength6", "Item_Freeze", "Item_BehemothsHeart"}


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
    skills.courier = unitSelf:GetAbility(12)

    if skills.call and skills.javelin and skills.leap and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  if skills.javelin:CanLevelUp() and unitSelf:GetLevel() == 1 then
    skills.javelin:LevelUp()
  elseif skills.leap:CanLevelUp() and unitSelf:GetLevel() == 2 then
    skills.leap:LevelUp()
  elseif skills.ulti:CanLevelUp() then
    skills.ulti:LevelUp()
  elseif skills.call:CanLevelUp() then
    skills.call:LevelUp()
  elseif skills.javelin:CanLevelUp() then
    skills.javelin:LevelUp()
  elseif skills.leap:CanLevelUp() then
    skills.leap:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end
end

local nukeTarget = nil

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  if not core.unitSelf:IsAlive() then 
    return
  end

  local unitSelf = self.core.unitSelf
  local teamBotBrain = core.teamBotBrain
  local tEnemyHeroes = core.CopyTable(core.localUnits["EnemyHeroes"])

  local lowestHealthPercent = 1
  for _, enemyHero in pairs(tEnemyHeroes) do
    if enemyHero:GetHealthPercent() < lowestHealthPercent then
      lowestHealthPercent = enemyHero:GetHealthPercent()
      nukeTarget = enemyHero
    end
  end

  if nukeTarget and nukeTarget:GetHealthPercent() > 0.6 then
    nukeTarget = nil
  end

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

  local addBonus = 0
  if EventData.Type == "Attack" then
    local unitTarget = EventData.TargetUnit
    if EventData.InflictorName == "Projectile_Valkyrie_Ability2" and unitTarget:IsHero() then
      addBonus = addBonus + 50
    end
  end

  if addBonus > 0 then
    core.nHarassBonus = core.nHarassBonus + addBonus
  end
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

function behaviorLib.CustomRetreatExecute(botBrain)
  local leap = skills.leap
  local unitSelf = core.unitSelf
  local unitsNearby = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 500)

  if unitSelf:GetHealthPercent() < 0.4 and core.NumberElements(unitsNearby.EnemyHeroes) > 0 then
    local ulti = skills.ulti
    if ulti and ulti:CanActivate() then
      return core.OrderAbility(botBrain, ulti)
    end
    local angle = core.HeadingDifference(unitSelf, core.allyMainBaseStructure:GetPosition())
    if leap and leap:CanActivate() and angle < 0.5 then
      return core.OrderAbility(botBrain, leap)
    end
  end
  return false
end

local function CustomHarassUtilityFnOverride(target)
  local nUtility = 0

  local call = skills.call
  if call and call:CanActivate() then
    nUtility = nUtility + 10
  end

  return generics.CustomHarassUtility(target) + nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf


  local bActionTaken = false

  local call = skills.call
  if call and call:CanActivate() and Vector3.Distance2D(unitTarget:GetPosition(), unitSelf:GetPosition()) < 200 then
    bActionTaken = core.OrderAbility(botBrain, call)
  end

  if call and call:CanActivate() and Vector3.Distance2D(unitTarget:GetPosition(), unitSelf:GetPosition()) < 600 and unitTarget:GetHealthPercent() < 0.6 then
    bActionTaken = core.OrderAbility(botBrain, call)
  end

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
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget and generics.IsFreeLineNoAllies(myPos, enemyPos) then
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

local itemAstro = nil
local itemManaring = nil
local FindItemsOld = core.FindItems
local function FindItemsFn(botBrain)
  FindItemsOld(botBrain)
  if itemAstro then
    return
  end
  local unitSelf = core.unitSelf
  local inventory = unitSelf:GetInventory(false)
  if inventory ~= nil then
    for slot = 1, 6, 1 do
      local curItem = inventory[slot]
      if curItem and not curItem:IsRecipe() then
        if not itemAstro and curItem:GetName() == "Item_Astrolabe" then
          itemAstro = core.WrapInTable(curItem)
        end
      end
    end
  end
  if itemManaring then
    return
  end
  local unitSelf = core.unitSelf
  local inventory = unitSelf:GetInventory(false)
  if inventory ~= nil then
    for slot = 1, 6, 1 do
      local curItem = inventory[slot]
      if curItem and not curItem:IsRecipe() then
        if not itemManaring and curItem:GetName() == "Item_Replenish" then
          itemManaring = core.WrapInTable(curItem)
        end
      end
    end
  end
end
core.FindItems = FindItemsFn


local CallPushBehavior = {}
local function CallPushUtility(botBrain)
  local nUtility = 0;
  local unitSelf = core.unitSelf
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local enemyCreepsInRange = 0
  local siegeOnLane = false
  local totalHealthLost = 0
  
  local call = skills.call
  if call and call:CanActivate() then
    for _, ally in pairs(tAllies) do
      local typeAlly = ally:GetTypeName()

      if typeAlly == "Creep_LegionSiege" or typeAlly == "Creep_HellbourneSiege" then
        siegeOnLane = true
      else
        totalHealthLost = totalHealthLost + ally:GetMaxHealth() - ally:GetHealth()
      end

    end

    if totalHealthLost > 330 and siegeOnLane == true and itemAstro and itemAstro:CanActivate() then
      BotEcho('Use meka!!!')
      bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemAstro)
    end


    for _, creep in pairs(tEnemies) do
      local typeCreep = creep:GetTypeName()

      if typeCreep == "Creep_LegionSiege" or typeCreep == "Creep_HellbourneSiege" then
        siegeOnLane = true
      end

      if typeCreep ~= "Creep_LegionSiege" and typeCreep ~= "Creep_HellbourneSiege" then
        if Vector3.Distance2D(creep:GetPosition(), unitSelf:GetPosition()) < 600 then
          enemyCreepsInRange = enemyCreepsInRange + 1
        end 
      end
    end
  end

  if itemManaring and enemyCreepsInRange > 2 and siegeOnLane == true then
    nUtility = nUtility + 40
  end

  if itemManaring and enemyCreepsInRange > 3 then
    nUtility = nUtility + 30
  end

  return nUtility
end
local function CallPushExecute(botBrain)
  local call = skills.call
  if call and call:CanActivate() then
    BotEcho('Push call!')
    return core.OrderAbility(botBrain, call)
  end
  return false
end
CallPushBehavior["Utility"] = CallPushUtility
CallPushBehavior["Execute"] = CallPushExecute
CallPushBehavior["Name"] = "Call push"
tinsert(behaviorLib.tBehaviors, CallPushBehavior)

local AstrolabeBehavior = {}
local function AstrolabeUtility(botBrain)
  local nUtility = 0;
  local unitSelf = core.unitSelf
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local siegeOnLane = false
  local totalHealthLost = 0
  local saveUnit = false
  
  for _, ally in pairs(tAllies) do
    local typeAlly = ally:GetTypeName()

    if typeAlly == "Creep_LegionSiege" or typeAlly == "Creep_HellbourneSiege" then
      siegeOnLane = true
    else
      totalHealthLost = totalHealthLost + ally:GetMaxHealth() - ally:GetHealth()
      if ally:GetHealthPercent() < 0.1 then
        saveUnit = true
      end
    end

    if totalHealthLost > 333 and siegeOnLane == true then
      nUtility = nUtility + 45
    elseif totalHealthLost > 500 then
      nUtility = nUtility + 55
    elseif saveUnit then
      nUtility = nUtility + 65
    end

  end
  return nUtility
end
local function AstrolabeExecute(botBrain)
  if itemAstro and itemAstro:CanActivate() then
    return core.OrderItemClamp(botBrain, unitSelf, itemAstro)
  end
  return false
end
AstrolabeBehavior["Utility"] = AstrolabeUtility
AstrolabeBehavior["Execute"] = AstrolabeExecute
AstrolabeBehavior["Name"] = "Astrolabe"
tinsert(behaviorLib.tBehaviors, AstrolabeBehavior)

local ManaringBehavior = {}
local function ManaringUtility(botBrain)
  local nUtility = 0;
  local unitSelf = core.unitSelf
  
  if (unitSelf:GetMaxMana() - unitSelf:GetMana()) > 135 then
    nUtility = nUtility + 45
  end
  return nUtility
end
local function ManaringExecute(botBrain)
  if itemManaring and itemManaring:CanActivate() then
    return core.OrderItemClamp(botBrain, unitSelf, itemManaring)
  end
  return false
end
ManaringBehavior["Utility"] = ManaringUtility
ManaringBehavior["Execute"] = ManaringExecute
ManaringBehavior["Name"] = "Manaring"
tinsert(behaviorLib.tBehaviors, ManaringBehavior)

local LeapBehavior = {}
local function LeapUtility(botBrain)
  local nUtility = 0;
  local unitSelf = core.unitSelf
  
  local angle = core.HeadingDifference(unitSelf, core.allyMainBaseStructure:GetPosition())
  local leap = skills.leap
  if unitSelf:GetHealthPercent() < 0.2 and angle < 0.5 then
    nUtility = nUtility + 95
  end
  
  return nUtility
end
local function LeapExecute(botBrain)
  if leap and leap:CanActivate() then
    return core.OrderAbility(botBrain, leap)
  end
  return false
end
LeapBehavior["Utility"] = LeapUtility
LeapBehavior["Execute"] = LeapExecute
LeapBehavior["Name"] = "Leap escape"
tinsert(behaviorLib.tBehaviors, LeapBehavior)

local NukeBehavior = {}
local function NukeUtility(botBrain)
  local nUtility = 0;
  local unitSelf = core.unitSelf

  if nukeTarget and Vector3.Distance2D(nukeTarget:GetPosition(), unitSelf:GetPosition()) < 600 then
    nUtility = nUtility + 60
  end
  
  return nUtility
end
local function NukeExecute(botBrain)
  --BotEcho("Want to call on nuketarget!")
  if call and call:CanActivate() then
    --BotEcho("Calling on nuketarget!")
    return core.OrderAbility(botBrain, call)
  end
  return false
end
NukeBehavior["Utility"] = NukeUtility
NukeBehavior["Execute"] = NukeExecute
NukeBehavior["Name"] = "Nuke Behavior"
tinsert(behaviorLib.tBehaviors, NukeBehavior)

BotEcho('finished loading valkyrie_main')
