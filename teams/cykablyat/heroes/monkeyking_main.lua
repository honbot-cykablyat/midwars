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

object.bReportBehavior = falses
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

BotEcho('loading monkeyking_main...')

object.heroName = 'Hero_MonkeyKing'

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

behaviorLib.StartingItems =
  {"Item_LoggersHatchet", "Item_ManaPotion", "Item_MinorTotem", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems =
  {"Item_Bottle", "Item_EnhancedMarchers", "Item_PowerSupply", "Item_Protect"}
behaviorLib.MidItems =
  {"Item_Dawnbringer", "Item_Evasion", "Item_Pierce", "Item_Sasuke", "Item_Weapon3"}
behaviorLib.LateItems =
  {"Item_DaemonicBreastplate", "Item_Immunity"}

local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.dash = unitSelf:GetAbility(0)
    skills.pole = unitSelf:GetAbility(1)
    skills.rock = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)

    if skills.dash and skills.pole and skills.rock and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local skillarray = {skills.dash, skills.pole, skills.pole, skills.rock, skills.pole, skills.rock, skills.pole, skills.ulti, skills.rock, skills.rock, skills.ulti, skills.dash, skills.dash, skills.dash, skills.ulti, skills.stats, skills.ulti}

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

function sign(x)
  return (x<0 and -1) or 1
end

function behaviorLib.CustomHarassUtility(unit)
  local unitSelf = core.unitSelf;
  local level = unitSelf:GetLevel() - unit:GetLevel();
  level = sign(level) * level * level;
  local mana = unitSelf:GetMana() / skills.dash:GetManaCost() * 3;
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
    if nDistSq < skills.dash:GetRange() * skills.dash:GetRange() then
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

local function HarassHeroExecute(botBrain)
  local bDebugEchos = false
  --[[
  if object.myName == "Bot1" then
    bDebugEchos = true
  end
  --]]

  local unitSelf = core.unitSelf
  local targetHero = behaviorLib.heroTarget
  local vecTargetPos = (targetHero and targetHero:GetPosition()) or nil

  if bDebugEchos then BotEcho("Harassing "..((targetHero~=nil and targetHero:GetTypeName()) or "nil")) end
  if targetHero and vecTargetPos then
    local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPos)
    local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, targetHero, true)

    local itemGhostMarchers = core.itemGhostMarchers

    --BotEcho('canSee: '..tostring(core.CanSeeUnit(botBrain, targetHero)))
    --BotEcho(format("nDistSq: %d  nAttackRangeSq: %d   attackReady: %s  canSee: %s", nDistSq, nAttackRangeSq, tostring(unitSelf:IsAttackReady()), tostring(core.CanSeeUnit(botBrain, targetHero))))

    --only attack when in nRange, so not to aggro towers/creeps until necessary, and move forward when attack is on cd
    if nDistSq < skills.dash:GetRange() * skills.dash:GetRange() * 2 * 2 and unitSelf:IsAttackReady() and core.CanSeeUnit(botBrain, targetHero) then
      local bInTowerRange = core.NumberElements(core.GetTowersThreateningUnit(unitSelf)) > 0
      local bShouldDive = behaviorLib.lastHarassUtil >= behaviorLib.diveThreshold

      if bDebugEchos then BotEcho(format("inTowerRange: %s  bShouldDive: %s", tostring(bInTowerRange), tostring(bShouldDive))) end

      if not bInTowerRange or bShouldDive then
        if bDebugEchos then BotEcho("ATTAKIN NOOBS! divin: "..tostring(bShouldDive)) end
        if not skills.dash:CanActivate() and nDistSq < nAttackRangeSq then
          if skills.rock:CanActivate() then
            core.OrderAbility(botBrain, skills.rock);
            return;
          end
          if skills.pole:CanActivate() then
            core.OrderAbilityEntity(botBrain, skills.pole, targetHero);
            return;
          end
          core.OrderAttackClamp(botBrain, unitSelf, targetHero)
        elseif skills.dash:CanActivate() then
          core.OrderAbility(botBrain, skills.dash);
        end
      end
    else
      if bDebugEchos then BotEcho("MOVIN OUT") end
      local vecDesiredPos = vecTargetPos
      local bUseTargetPosition = true

      --leave some space if we are ranged
      if unitSelf:GetAttackRange() > 200 then
        vecDesiredPos = vecTargetPos + Vector3.Normalize(unitSelf:GetPosition() - vecTargetPos) * behaviorLib.rangedHarassBuffer
        bUseTargetPosition = false
      end

      if itemGhostMarchers and itemGhostMarchers:CanActivate() then
        local bSuccess = core.OrderItemClamp(botBrain, unitSelf, itemGhostMarchers)
        if bSuccess then
          return
        end
      end

      local bChanged = false
      local bWellDiving = false
      vecDesiredPos, bChanged, bWellDiving = core.AdjustMovementForTowerLogic(vecDesiredPos)

      if bDebugEchos then BotEcho("Move - bChanged: "..tostring(bChanged).."  bWellDiving: "..tostring(bWellDiving)) end

      if not bWellDiving then
        if behaviorLib.lastHarassUtil < behaviorLib.diveThreshold then
          if bDebugEchos then BotEcho("DON'T DIVE!") end

          if core.NumberElements(core.GetTowersThreateningPosition(vecDesiredPos, nil, core.myTeam)) > 0 then
            return false
          end

          if bUseTargetPosition and not bChanged then
            core.OrderMoveToUnitClamp(botBrain, unitSelf, targetHero, false)
          else
            core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecDesiredPos, false)
          end
        else
          if bDebugEchos then BotEcho("DIVIN Tower! util: "..behaviorLib.lastHarassUtil.." > "..behaviorLib.diveThreshold) end
          core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)
        end
      else
        return false
      end

      --core.DrawXPosition(vecDesiredPos, 'blue')
    end
  else
    return false
  end
end

behaviorLib.HarassHeroBehavior = {}
behaviorLib.HarassHeroBehavior["Utility"] = behaviorLib.HarassHeroUtility
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecute
behaviorLib.HarassHeroBehavior["Name"] = "HarassHero"
tinsert(behaviorLib.tBehaviors, behaviorLib.HarassHeroBehavior)

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
  local target = nil
  local index = 666
  for _,enemy in pairs(core.localUnits["EnemyHeroes"]) do
    if enemy:IsStunned() then
      for i,hero in pairs(attack_priority) do
        if enemy.hero_name == hero and i < index then
          target = enemy
          index = i
        end
      end
    end
  end
  core.teamBotBrain:SetTeamTarget(target)
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride



local harassOldUtility = behaviorLib.HarassHeroBehavior["Utility"]
local harassOldExecute = behaviorLib.HarassHeroBehavior["Execute"]

local function harassUtilityOverride(botBrain)
  BotEcho("checking harass ")
  if core.teamBotBrain.GetState and core.teamBotBrain:GetState() == "LANE_AGGRESSIVELY" then
    return 100
  end
  return harassOldUtility(botBrain)
end

local function harassExecuteOverride(botBrain)
  -- local targetHero = behaviorLib.heroTarget
  local targetHero = core.teamBotBrain:GetTeamTarget()
  if targetHero == nil or not targetHero:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf

  local bActionTaken = false

  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, targetHero) then
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), targetHero:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, targetHero)

    local dash = skills.dash
    local facing = core.HeadingDifference(unitSelf, targetHero:GetPosition())

    if dash and dash:CanActivate() and Vector3.Distance2D(unitSelf:GetPosition(), targetHero:GetPosition()) < dash:GetRange() and facing < 0.3 then
      bActionTaken = core.OrderAbility(botBrain, dash)
    end

    local stun = skills.rock
    if not bActionTaken and not targetHero:IsStunned() and not targetHero:IsMagicImmune() and stun and stun:CanActivate() and Vector3.Distance2D(unitSelf:GetPosition(), targetHero:GetPosition()) < 200 and facing < 0.3 then
      bActionTaken = core.OrderAbility(botBrain, stun)
    end

  end

  if not bActionTaken then
    return harassOldExecute(botBrain)
  end
end

behaviorLib.HarassHeroBehavior["Utility"] = harassUtilityOverride
behaviorLib.HarassHeroBehavior["Execute"] = harassExecuteOverride


local dash_dmg = {15, 20, 25, 30};
local pole_dmg = {100, 150, 200, 250};
local rock_dmg = {60, 90, 120, 150};
local effective_skills = {0, 2, 1};
local combo = {0, 2, 1, 0, 1}; -- dash, rock, pole, dash, pole
local function comboViable()
  local unitSelf = core.unitSelf
  local mana = 0;
  local mana = 0.5 * skills.pole:GetManaCost();
  for _, v in pairs(effective_skills) do
    local skill = unitSelf:GetAbility(v)
    if not skill:CanActivate() then
      return false;
    end
    mana = mana + skill:GetManaCost();
  end
  return mana < core.unitSelf:GetMana();
end

local comboState = 1;
local function KillUtility(botBrain)
  local unitSelf = core.unitSelf;
  if comboState > 1 then
    return 999;
  end
  if not comboViable() then
    return 0;
  end
  local physical_dmg = 2 * (dash_dmg[skills.dash:GetLevel()] + core.GetFinalAttackDamageAverage(unitSelf)) + 1.5 * pole_dmg[skills.pole:GetLevel()];
  local magic_dmg = rock_dmg[skills.rock:GetLevel()];
  for _, unit in pairs(core.localUnits["EnemyHeroes"]) do
    local nDistSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unit:GetPosition());
    if nDistSq < skills.dash:GetRange() * skills.dash:GetRange() then
      local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, targetHero, true)
      local dmg = (1 - unit:GetPhysicalResistance()) * physical_dmg + (1 - unit:GetMagicResistance()) * magic_dmg;
      if dmg >= unit:GetHealth() then
        behaviorLib.herotarget = unit;
        return 999;
      end
    end
  end
  return 0;
end

local function orderAbility(botBrain, s)
  local unitSelf = core.unitSelf
  local skill = unitSelf:GetAbility(s);
  if s == 1 then
    core.OrderAbilityEntity(botBrain, skill, behaviorLib.herotarget);
  else
    core.OrderAbility(botBrain, skill);
  end
end

local function KillExecute(botBrain)
  local unitSelf = core.unitSelf
  if comboState >= 5 then
    comboState = 1;
    return true;
  end

  local skill = unitSelf:GetAbility(combo[comboState])
  if skill and skill:CanActivate() then
    orderAbility(botBrain, combo[comboState]);
    comboState = comboState + 1;
  end
  return false;
end

local KillBehavior = {}
KillBehavior["Utility"] = KillUtility
KillBehavior["Execute"] = KillExecute
KillBehavior["Name"] = "Kill"
tinsert(behaviorLib.tBehaviors, KillBehavior)

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

BotEcho('finished loading monkeyking_main')
