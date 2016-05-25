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

object.bReportBehavior = true
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

BotEcho('loading devourer_main...')

object.heroName = 'Hero_Devourer'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}

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

  local skillarray = {skills.hook, skills.fart, skills.hook, skills.skin, skills.hook, skills.ulti, skills.hook, skills.fart, skills.fart, skills.fart, skills.ulti, skills.skin, skills.skin, skills.skin, skills.stats, skills.ulti, skills.stats}

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

behaviorLib.StartingItems = {"Item_ManaBattery", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = {"Item_Marchers", "Item_EnhancedMarchers", "Item_PowerSupply"}
behaviorLib.MidItems = {"Item_PortalKey", "Item_MagicArmor2"}
behaviorLib.LateItems = {"Item_BehemothsHeart"}

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
local function HasEnemiesInRange(unit, range)
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

function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  local tEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  for _, enemy in pairs(tEnemies) do
    local state = enemy:HasState("State_Devourer_Ability1")
    if state then
      BotEcho("DevoHook Detected!!!")
    end
  end

  if HasEnemiesInRange(core.unitSelf, 250) then
    if not core.unitSelf:HasState("State_Devourer_Ability2_Self") then
      object:OrderAbility(skills.fart)
    end
  else
    if core.unitSelf:HasState("State_Devourer_Ability2_Self") then
      object:OrderAbility(skills.fart)
    end
  end
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

-- Custom healAtWell behaviorLib

local healAtWellOldUtility = behaviorLib.HealAtWellBehavior["Utility"]

local function HealAtWellUtilityOverride(botBrain)
  if core.unitSelf:GetHealthPercent() and core.unitSelf:GetHealthPercent() < 0.15 then
    return 999
  end
  return healAtWellOldUtility(botBrain)
end

behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverride

-- end healAtWell

-- Custom harass behaviour

local harassOldUtility = behaviorLib.HarassHeroBehavior["Utility"]
local harassOldExecute = behaviorLib.HarassHeroBehavior["Execute"]

local function harassUtilityOverride(botBrain)
  if core.teamBotBrain.GetState and core.teamBotBrain:GetState() == "LANE_AGGRESSIVELY" then
    return 100
  end
  return harassOldUtility(botBrain)
end

local function harassExecuteOverride(botBrain)
  -- moves the hero to enemy teams position
  -- local enemyTeamPos = core.teamBotBrain:GetEnemyTeamPosition()
  -- if enemyTeamPos and core.teamBotBrain:GetState() == "LANE_AGGRESSIVELY" then
  --   BotEcho("ordering devourer attack!")
  --   -- BotEcho("enemy team pos : " .. enemyTeamPos.y)
  --   -- core.OrderPosition()
  --   -- core.OrderPosition(botBrain, core.unitSelf, "move", enemyTeamPos)
  --   -- botBrain:OrderPosition(core.unitSelf, "move", enemyTeamPos)
  --   -- core.OrderPosition(botBrain, core.unitSelf, "move", core.unitSelf:GetPosition(), "none", nil, true)
  --   botBrain:OrderPosition(core.unitSelf.object, "move", enemyTeamPos)
  -- end

  -- local targetHero = core.teamBotBrain:GetTeamTarget()
  -- if targetHero == nil then
  --   targetHero = core.teamBotBrain:CalculateClosestEnemyToAllyHero(core.unitSelf)
  -- end
  -- if targetHero == nil or not targetHero:IsValid() then
  --   return false --can not execute, move on to the next behavior
  -- end

  local unitSelf = core.unitSelf
  local targetHero = core.teamBotBrain:FindBestEnemyTargetInRange(unitSelf:GetPosition(), 800)
  if targetHero == nil then
    return false
  end
  behaviorLib.heroTarget = targetHero

  if unitSelf:IsChanneling() then
    return
  end

  local bActionTaken = false

  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, targetHero) then
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), targetHero:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, targetHero);

    local itemGhostMarchers = core.itemGhostMarchers

    local ulti = skills.ulti
    local ultiRange = ulti and (ulti:GetRange() + core.GetExtraRange(unitSelf) + core.GetExtraRange(targetHero)) or 0

    local bUseUlti = true

    if ulti and ulti:CanActivate() and bUseUlti and dist < ultiRange then
      bActionTaken = core.OrderAbilityEntity(botBrain, ulti, targetHero)
    elseif (ulti and ulti:CanActivate() and bUseUlti and dist > ultiRange) then
      --move in when we want to ult
      local desiredPos = targetHero:GetPosition()

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
    return harassOldExecute(botBrain)
  end
end

behaviorLib.HarassHeroBehavior["Utility"] = harassUtilityOverride
behaviorLib.HarassHeroBehavior["Execute"] = harassExecuteOverride

-- End of custom harass

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
        nUtility = 25 --25
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

local hookTarget = nil
local function hookUtility(botBrain)
  local unitSelf = core.unitSelf;
  if not skills.hook:CanActivate() then
    return 0
  end

  for _, unit in pairs(core.localUnits["EnemyHeroes"]) do
    if unit and unit:GetPosition() then
      local location = generics.predict_location(unitSelf, unit, 1600)
      local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), location);
      if nDistSq < skills.hook:GetRange() * skills.hook:GetRange() then
        if generics.IsFreeLine(unitSelf:GetPosition(), location, false) then
          hookTarget = unit;
          return 100;
        end
      end
    end
  end
  return 0;
end

local function hookExecute(botBrain)
  local unitSelf = core.unitSelf

  if skills.hook:CanActivate() then
    local location = generics.predict_location(unitSelf, hookTarget, 1600);
    if generics.IsFreeLine(unitSelf:GetPosition(), location, false) then
      core.OrderAbilityPosition(botBrain, skills.hook, location);
    end
  end
end

local HookBehavior = {}
HookBehavior["Utility"] = hookUtility
HookBehavior["Execute"] = hookExecute
HookBehavior["Name"] = "Hook"
tinsert(behaviorLib.tBehaviors, HookBehavior)

local function findHookPlaceUtility(botBrain)
  local unitSelf = core.unitSelf;
  if not skills.hook:CanActivate() then
    return 0
  end
  if not core.teamBotBrain.enemyTeam or not core.teamBotBrain.allyTeam then
    return 0
  end

  local inRange = false
  for _, unit in pairs(core.localUnits["EnemyHeroes"]) do
    local location = generics.predict_location(unitSelf, unit, 1600)
    local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), location);
    local range = skills.hook:GetRange();
    if nDistSq < range * range then
      if generics.IsFreeLine(unitSelf:GetPosition(), location, false) then
        return 0;
      end
    elseif nDistSq < range * 1.5 * range * 1.5 then
      inRange = true
    end
  end
  if not inRange then
    return 0
  end
  return 60;
end

local function findHookPlaceExecute(botBrain)
  local unitSelf = core.unitSelf;
  local oX = unitSelf:GetPosition().x;
  local oY = unitSelf:GetPosition().y;
  local cX = core.teamBotBrain.enemyTeam[1].x;
  local cY = core.teamBotBrain.enemyTeam[1].y;
  local tX = core.teamBotBrain.allyTeam[1].x
  local tY = core.teamBotBrain.allyTeam[1].y
  local d
  if cY == tY then
    if oY < tY then
      d = 100
    else
      d = -100
    end
  elseif oY - tY > ((cX - tX) / (cY - tY)) * (oX - tX) then
    d = 100
  else
    d = -100
  end
  local deltaX = oX - cX;
  local deltaY = oY - cY;
  local radius = math.sqrt(deltaX * deltaX + deltaY * deltaY);
  local orthoX = -deltaY * d / radius;
  local orthoY = deltaX * d / radius;
  local newDeltaX = deltaX + orthoX;
  local newDeltaY = deltaY + orthoY;
  local newLength = math.sqrt(newDeltaX * newDeltaX + newDeltaY * newDeltaY);
  local aX = cX + newDeltaX * radius / newLength;
  local aY = cY + newDeltaY * radius / newLength;
  botBrain:OrderPosition(core.unitSelf.object, "move", Vector3.Create(aX, aY), "none", nil, true)
end

local FindHookPlaceBehavior = {}
FindHookPlaceBehavior["Utility"] = findHookPlaceUtility
FindHookPlaceBehavior["Execute"] = findHookPlaceExecute
FindHookPlaceBehavior["Name"] = "FindHook"
tinsert(behaviorLib.tBehaviors, FindHookPlaceBehavior)

BotEcho('finished loading devourer_main')
