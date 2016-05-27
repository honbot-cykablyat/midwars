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

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
local commonLib = object.commonLib

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading puppetmaster_main...')

object.heroName = 'Hero_PuppetMaster'

behaviorLib.StartingItems = {"2 Item_MinorTotem", "Item_ManaBattery", "Item_PowerSupply"}
behaviorLib.LaneItems = {"Item_Marchers", "Item_Steamboots"}
behaviorLib.MidItems = {"Item_HelmOfTheVictim", "Item_WhisperingHelm", "Item_Glowstone", "Item_Lifetube", "Item_Regen"}
behaviorLib.LateItems = {"Item_Protect", "Item_AxeOfTheMalphai", "Item_LifeSteal4", "Item_Sicarius", "Item_Confluence", "Item_ManaBurn2", "Item_Beastheart", "Item_AxeOfTheMalphai", "Item_BehemothsHeart"}

local FindItemsOld = core.FindItems
local function FindItemsFn(botBrain)
  FindItemsOld(botBrain)
  if object.itemPuzzle then
    return
  end
  local unitSelf = core.unitSelf
  local inventory = unitSelf:GetInventory(false)
  if inventory ~= nil then
    for slot = 1, 6, 1 do
      local curItem = inventory[slot]
      if curItem and not curItem:IsRecipe() then
        if not object.itemPuzzle and curItem:GetName() == "Item_Summon" then
          object.itemPuzzle = core.WrapInTable(curItem)
        end
      end
    end
  end
end
core.FindItems = FindItemsFn

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
    skills.attributeBoost = unitSelf:GetAbility(4)
    skills.courier = unitSelf:GetAbility(12)

    if skills.hold and skills.show and skills.whip and skills.ulti and skills.attributeBoost then
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
  elseif skills.whip:CanLevelUp() then
    skills.whip:LevelUp()
  elseif skills.hold:CanLevelUp() then
    skills.hold:LevelUp()
  elseif skills.show:CanLevelUp() then
    skills.show:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end
end

local function HarassHeroUtilityOverride(botBrain)
  local nUtility = 0

  local mana = core.unitSelf:GetMana()
  local holdUtility = 10
  local ultiUtility = 40
  local showUtility = 10

  if skills.ulti:CanActivate()  then
    nUtility = nUtility + ultiUtility
    mana = mana - skills.ulti:GetManaCost()
    if skills.hold:CanActivate() and skills.hold:GetManaCost() < mana then
      mana = mana - skills.hold:GetManaCost()
      nUtility = nUtility + holdUtility
      if skills.show:CanActivate() and skills.show:GetManaCost() < mana then
        nUtility = nUtility + showUtility
      end
    else
      if skills.show:CanActivate() and skills.show:GetManaCost() < mana then
        nUtility = nUtility + showUtility
      else
        -- cannot ult and disable
        nUtility = nUtility - ultiUtility
      end
    end
  else 
    if skills.hold:CanActivate() then
      mana = mana - skills.hold:GetManaCost()
      nUtility = nUtility + holdUtility
      if skills.show:CanActivate() and skills.show:GetManaCost() < mana then
        nUtility = nUtility + showUtility
      end
    else 
      if skills.show:CanActivate() then
        nUtility = nUtility + showUtility
      end
    end
  end

  -- a puppet is placed
  if behaviorLib.heroTargetOverride then
    --BotEcho("Exists puppet! extra utility for harass!")
    nUtility = nUtility + 40
  end

  local unitTarget = behaviorLib.heroTarget



  if unitTarget then

    if commonLib.IsDisabled(unitTarget) then
      --BotEcho("Enemy disabled! extra utility for harass!")
      nUtility = nUtility + 30
    end

    local s = commonLib.RelativeTowerPosition(unitTarget)
    if s == 1 then 
      nUtility = nUtility * 1.4
    end
    if s == -1 then 
      nUtility = nUtility / 1.4
    end

    if unitTarget:GetMana() > core.unitSelf:GetMana() then 
      nUtility = nUtility / 1.2
    else 
      nUtility = nUtility * 1.2
    end
  end

  return nUtility
end

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget

  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf

  local bActionTaken = false

  --
  -- Use abilities
  --
  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, unitTarget) then
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)

    local hold = skills.hold
    local ulti = skills.ulti
    local show = skills.show
    
    local facing = core.HeadingDifference(unitSelf, unitTarget:GetPosition())

    local targetDisabled = commonLib.IsDisabled(unitTarget)

    if not bActionTaken and ulti and targetDisabled and ulti:CanActivate() and 
      Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < ulti:GetRange() then
      bActionTaken = core.OrderAbilityEntity(botBrain, ulti, unitTarget)
    end

    if not bActionTaken and hold and not targetDisabled and hold:CanActivate() and 
      Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < hold:GetRange() then
      bActionTaken = core.OrderAbilityEntity(botBrain, hold, unitTarget)
    end

    if not bActionTaken and show and not targetDisabled and show:CanActivate() and 
      Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < show:GetRange() then
      bActionTaken = core.OrderAbilityEntity(botBrain, show, unitTarget)
    end
  end

  if not bActionTaken then

    local desiredPos = unitTarget:GetPosition()

    if not bActionTaken and itemGhostMarchers and itemGhostMarchers:CanActivate() then
      bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemGhostMarchers)
    end

    if not bActionTaken and behaviorLib.lastHarassUtil < behaviorLib.diveThreshold then
      desiredPos = core.AdjustMovementForTowerLogic(desiredPos)
    end

    --bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, desiredPos, false)
    
    if not bActionTaken then 
      return object.harassExecuteOld(botBrain)
    end
  end
  return true
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
behaviorLib.CustomHarassUtility = HarassHeroUtilityOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  if not core.localUnits then return end

  local enemies = core.localUnits['EnemyUnits']

  local overrideTarget = false

  for i, unit in pairs(enemies) do

    if unit:GetTypeName() == "Pet_PuppetMaster_Ability4" and unit:GetTeam() ~= core.unitSelf:GetTeam() then
      core.teamBotBrain.heroTargetOverride = unit
      overrideTarget = true
    end
  end 

  if not overrideTarget then 
    core.teamBotBrain.heroTargetOverride = nil
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

function printObjects(objects)
  for i, obj in pairs(objects) do
    BotEcho(obj:GetDisplayName().." "..obj:GetTypeName())
  end
end

function Starts(string, start) 
  return string.sub(string, 1, string.len(start)) == start
end

function object:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

BotEcho('finished loading puppetmaster_main')
