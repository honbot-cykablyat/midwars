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
    skills.attributeBoost = unitSelf:GetAbility(4)

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
  elseif skills.hold:CanLevelUp() then
    skills.hold:LevelUp()
  elseif skills.show:CanLevelUp() then
    skills.show:LevelUp()
  elseif skills.whip:CanLevelUp() then
    skills.whip:LevelUp()
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

-- ComboWombo -behaviour

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
      BotEcho(skill:GetName())
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
  core.DrawXPosition(unitPos, "red", 1200)
  if comboIndex > 1 then
    return 999;
  end
  if not ableToCombo() then
    BotEcho("no combo")
    return 0;
  end
  -- Loop through enemy heros in 400 radius
  BotEcho("COMBO TIME")
  for _, unit in pairs(core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 600).EnemyHeroes) do
--    BotEcho("yo looping")
    local dmg = calculateDamage(unitSelf, unit);
    -- BotEcho("Calculated damage: " + dmg);
    BotEcho(dmg)
    BotEcho(unit:GetHealth())
    --if dmg >= unit:GetHealth() or true then
      behaviorLib.herotarget = unit;
      target = unit
      BotEcho("LET'S DO THIS!");
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
  BotEcho("executing")
  BotEcho(comboIndex)
  -- Check if execution of combo has been completed
  if comboIndex > 5 then 
    BotEcho("ending combo")
    comboIndex = 1;
    wait = 0;
    lastCast = 0;
    lastAttacked = 0;
    return true;
  end
  local unitSelf = core.unitSelf

  
  --BotEcho(skill)
  if attacksLeft > 0 then
    BotEcho("still attacks left!")
    behaviorLib.herotarget = unit;
    if (lastAttacked - HoN:GetMatchTime() <= atks_per_sec) then
      attacksLeft = attacksLeft - 1;
      lastAttacked = HoN:GetMatchTime();
      -- If no attacks left move on to next combo state
      if attacksLeft == 0 then
        BotEcho("no attacks left")
        comboIndex = comboIndex + 1;
      end
    end
  elseif comboIndex == 3 or comboIndex == 5 then
    -- attack
   BotEcho("attack!")
    if comboIndex == 3 then
      attacksLeft = math.floor(hold_time[skills.hold:GetLevel()] / atks_per_sec) - 1;
    else
      attacksLeft = math.floor(show_time[skills.show:GetLevel()] / atks_per_sec) + 2;
    end
    behaviorLib.herotarget = unit;
    lastAttacked = HoN:GetMatchTime();
  else
    -- cast a spell
    BotEcho("cast a spell!")
   -- BotEcho(skill:CanActivate())
    local skill = unitSelf:GetAbility(combo[comboIndex]);
	if skill and skill:CanActivate() and (HoN:GetMatchTime() - lastCast) > wait then
      BotEcho(skill:GetTypeName());
      wait = skill:GetAdjustedCastTime();
      lastCast = HoN:GetMatchTime();
--      botBrain:OrderAbilityEntity(skill, target);
   --   botBrain.OrderPosition(botBrain, target, target:GetPosition())
      core.OrderAbilityEntity(botBrain, skill, target);
      BotEcho(type (target[1]))
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
tinsert(behaviorLib.tBehaviors, ComboBehavior)

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
