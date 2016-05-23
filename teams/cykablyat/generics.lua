-- Stolen from default generics

local _G = getfenv(0)
local object = _G.object

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog

object.generics = {}
local generics = object.generics

BotEcho("loading default generics ..")

function takeHealUtility(botBrain)
  local healPos = core.teamBotBrain.healPosition
  if healPos and core.unitSelf:GetHealthPercent() < 0.50 then
    return 100
  end
  return 0
end

function takeHealExecute(botBrain)
  core.OrderPosition(botBrain, core.unitSelf, "move", healPos, "none", nil, true)
end

TakeHealBehavior = {}
TakeHealBehavior["Utility"] = takeHealUtility
TakeHealBehavior["Execute"] = takeHealExecute
TakeHealBehavior["Name"] = "HarassHero"

function targetUtility(botBrain)
  local target = nil
  local index = 666
  for _,enemy in pairs(core.localUnits["EnemyHeroes"]) do 
    if enemy:IsStunned() then
      for i,hero in pairs(core.teamBotBrain.attack_priority) do
        if enemy.hero_name == hero and i < index then
          target = enemy
          index = i
        end
      end
    end
  end
  core.teamBotBrain:SetTeamTarget(target)
  return 0
end

function targetExecute(botBrain)
end

TargetBehavior = {}
TargetBehavior["Utility"] = targetUtility
TargetBehavior["Execute"] = targetExecute
TargetBehavior["Name"] = "Target"

function generics.IsFreeLine(pos1, pos2, ignoreAllies)
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local spaceBetween = 50 * 50
  if not ignoreAllies then
    for _, ally in pairs(tAllies) do
      local posAlly = ally:GetPosition()
      local x3, y3 = posAlly.x, posAlly.y
      local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
      local calc2 = calc * calc
      local actual = calc2 / distanceLine
      if actual < spaceBetween then
        return false
      end
    end
  end
  for _, creep in pairs(tEnemies) do
    local posCreep = creep:GetPosition()
    local x3, y3 = posCreep.x, posCreep.y
    local calc = x1*y2 - x2*y1 + x2*y3 - x3*y2 + x3*y1 - x1*y3
    local calc2 = calc * calc
    local actual = calc2 / distanceLine
    if actual < spaceBetween then
      return false
    end
  end
  return true
end
