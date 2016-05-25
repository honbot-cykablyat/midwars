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
  local healPos = core.teamBotBrain.healPosition
  if healPos then
  	botBrain:OrderPosition(core.unitSelf.object, "move", healPos, "none", nil, true)
	end
end

generics.TakeHealBehavior = {}
generics.TakeHealBehavior["Utility"] = takeHealUtility
generics.TakeHealBehavior["Execute"] = takeHealExecute
generics.TakeHealBehavior["Name"] = "TakeHeal"

function generics.predict_location(unit, enemy, projectileSpeed)
  local enemyHeading = enemy:GetHeading()
  local selfPos = unit:GetPosition()
  local enemyPos = enemy:GetPosition()
  local enemySpeed = enemy:GetMoveSpeed()
	if not enemyHeading then
		return enemyPos
	end
  local enemyMovement = enemySpeed * enemyHeading;

  local startPos = enemyPos;
  local t = Vector3.Distance2D(selfPos, startPos) / projectileSpeed;
  while true do
    local newPos = startPos + t * enemyMovement;
    local newT = Vector3.Distance2D(selfPos, newPos) / projectileSpeed;
    if math.abs(newT - t) < 0.001 then
      return newPos
    end
    t = newT
  end
end


function generics.IsFreeLine(pos1, pos2, ignoreAllies)
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local spaceBetween = 100 * 100 -- 50 * 50
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

function generics.CalculateEnemyTargetValue(enemy, position, range)
  local value = 0
  if enemy:GetPosition() == nil then
    return -1000
  end
  local dist = Vector3.Distance2D(enemy:GetPosition(), position)
  if not enemy:IsAlive() then
    return -1000
  elseif not enemy:IsValid() then
    return -1000
  elseif dist > range then
    return -1000
  end

  value = math.floor(100 - dist / 100)

  local health = enemy:GetHealth()
  value = value - math.floor(health / 50)

  if enemy:IsStunned() then
    value = value + 50
  end

  return value
end

-- Checks for nearest and lowest hp enemy hero
function generics.FindBestEnemyTargetInRange(range)
  local bestTarget = nil
  local bestTargetValue = nil
  -- BotEcho("hi")
  -- core.BotEcho(tostring(core.localUnits["Enemies"]))
  -- core.BotEcho(tostring(object.tEnemyHeroes))
  -- core.printTable(core.localUnits["EnemyUnits"])
  -- for _, enemyBuilding in pairs(core.localUnits["EnemyBuildings"]) do
  --   BotEcho(enemyBuilding:GetTypeName())
  --   if enemyBuilding:IsBase() then
  --     bestTarget = enemyBuilding
  --     bestTargetValue = math.ceiling(0.5 - enemyBuilding:GetHealthPercent()) * (1 - enemyBuilding:GetHealthPercent()) * 200
  --     -- BotEcho("base!")
  --   end
  -- end
  for _, enemyUnit in pairs(core.localUnits["EnemyCreeps"]) do
    if enemyUnit:GetTypeName() == "Pet_PuppetMaster_Ability4" then
      -- BotEcho("was puppet!")
      bestTarget = enemyUnit
      bestTargetValue = 110
    end
  end
  for _, enemyHero in pairs(core.teamBotBrain:GetEnemyTeam()) do
    local value = generics.CalculateEnemyTargetValue(enemyHero, core.unitSelf:GetPosition(), range)
    if bestTarget == nil or bestTargetValue < value then
      bestTarget = enemyHero
      bestTargetValue = value
    end
  end
  return bestTarget
end
