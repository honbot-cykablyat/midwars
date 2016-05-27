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

function groupUtility(botBrain)
  local allyTeam = core.teamBotBrain.GetAllyTeam()
  if allyTeam and allyTeam[1] then
    if generics.AnalyzeAllyHeroPosition(core.unitSelf) == "GROUP" then
      local allyTeam = core.teamBotBrain:GetAllyTeam(core.unitSelf:GetPosition(), 2000);
      allyTeam = HoN.GetGroupCenter(allyTeam);
      if allyTeam then
        if Vector3.Distance2D(core.unitSelf:GetPosition(), allyTeam) < 1000 then
          return 0
        end
      end
      return 25
    end
  end
  return 0
end

function groupExecute(botBrain)
  local unitSelf = core.unitSelf
  local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  local allyTower = core.GetClosestAllyTower(enemyBasePos)
  local allyTowerPos = allyTower:GetPosition()
  if Vector3.Distance2D(unitSelf:GetPosition(), allyTowerPos) < 1000 then
    botBrain:OrderPosition(unitSelf.object, "move", allyTowerPos, "none", nil, false)
  end
  local allyTeam = core.teamBotBrain:GetAllyTeam(unitSelf:GetPosition(), 1000);
  allyTeam = HoN.GetGroupCenter(allyTeam);
  if allyTeam then
    botBrain:OrderPosition(unitSelf.object, "move", allyTeam, "none", nil, false)
  end
end

generics.GroupBehavior = {}
generics.GroupBehavior["Utility"] = groupUtility
generics.GroupBehavior["Execute"] = groupExecute
generics.GroupBehavior["Name"] = "Group"

local function findProjectile(botBrain)
  local unitSelf = core.unitSelf
  local pos = unitSelf:GetPosition()
  local units = HoN.GetUnitsInRadius(pos, 750, core.UNIT_MASK_ALIVE + core.UNIT_MASK_GADGET)
  for _, unit in pairs(units) do
    if unit:GetTypeName() == "Gadget_Valkyrie_Ability2_Reveal" and unit:GetTeam() ~= core.myTeam then
      local arrowPos = unit:GetPosition()
      local heading = unit:GetHeading()
      local radius = unitSelf:GetBoundsRadius();
      if intersects({arrowPos, heading * 750}, {Vector3.Create(pos.x - radius, pos.y - radius, 0), Vector3.Create(pos.x + radius, pos.y + radius, 0)}) then
        return {arrowPos, heading}
      end
    end
  end
  for _, hero in pairs(core.teamBotBrain.tEnemyHeroes) do
    if hero:GetTypeName() == "Hero_Devourer" then
      local beha = hero:GetBehavior()
      if beha and beha:GetType() == "Ability" and not beha:GetTarget() then
        local goalPos = beha:GetGoalPosition()
        if goalPos then
          local pos = hero:GetPosition()
          return {pos, Vector3.Create(pos.x - goalPos.x, pos.y - goalPos.y, 0)}
        end
      end
    end
    if hero:GetTypeName() == "Hero_Fairy" then
      local beha = hero:GetBehavior()
      if beha and beha:GetType() == "Ability" and not beha:GetTarget() then
        local goalPos = beha:GetGoalPosition()
        if goalPos then
          local pos = hero:GetPosition()
          return {pos, Vector3.Create(pos.x - goalPos.x, pos.y - goalPos.y, 0)}
        end
      end
    end
  end
end

function intersects(ray, box)
   local tmin, tmax = -99999, 99999
    if not ray[2].x == 0 then
        local tx1 = (box[1].x - ray[1].x) / ray[2].x;
        local tx2 = (box[2].x - ray[1].x) / ray[2].x;
        tmin = math.max(tmin, math.min(tx1, tx2));
        tmax = math.min(tmax, math.max(tx1, tx2));
    end
    if not ray[2].y == 0.0 then
        local ty1 = (box[1].y - ray[1].y) / ray[2].y;
        local ty2 = (box[2].y - ray[1].y) / ray[2].y;
        tmin = math.max(tmin, math.min(ty1, ty2));
        tmax = math.min(tmax, math.max(ty1, ty2));
    end
    return tmax >= tmin;
end

function dodgeUtility(botBrain)
  local position = findProjectile(botBrain)
  if position then
    return 200
  end
  return 0
end

function dodgeExecute(botBrain)
  local unitSelf = core.unitSelf
  local pos = unitSelf:GetPosition()
  local position = findProjectile(botBrain)
  if position then
    local x, y
    local between = Vector3.Create(position[1].x - pos.x, position[1].y - pos.y, 0)
    local perpen = Vector3.Create(position[2].y, -position[2].x, 0);
    if Vector3.Dot(perpen, between) > 0 then
      x = pos.x - 50 * position[2].y
      y = pos.y + 50 * position[2].x
    else
      x = pos.x + 50 * position[2].y
      y = pos.y - 50 * position[2].x
    end
    local dir = Vector3.Create(x, y, 0)
    botBrain:OrderPosition(core.unitSelf.object, "move", dir, "none", nil, true)
  end
end

generics.DodgeBehavior = {}
generics.DodgeBehavior["Utility"] = dodgeUtility
generics.DodgeBehavior["Execute"] = dodgeExecute
generics.DodgeBehavior["Name"] = "Dodge"


function generics.predict_location(unit, enemy, projectileSpeed)
  local enemyHeading = enemy:GetHeading()
  local selfPos = unit:GetPosition()
  local enemyPos = enemy:GetPosition()
  if enemy:GetBehavior() then
    if not enemy:GetBehavior():GetType() == "Move" then
      return enemyPos    
    end
  end
  local enemySpeed = enemy:GetMoveSpeed()
  if not enemyHeading then
    return enemyPos
  end
  local enemyMovement = enemySpeed * enemyHeading;

  local startPos = enemyPos;
  local t = Vector3.Distance2D(selfPos, startPos) / projectileSpeed;
  return startPos + t * enemyMovement
  --while true do
  --  local newPos = startPos + t * enemyMovement;
  --  local newT = Vector3.Distance2D(selfPos, newPos) / projectileSpeed;
  --  if math.abs(newT - t) < 0.001 then
  --    return newPos
  --  end
  --  t = newT
  --end
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

function CalculateTeamHealthPc(team)
  if table.getn(team) == 0 then
    return 0
  end
  local teamHpPc = 0
  for _, hero in pairs(team) do
    teamHpPc = teamHpPc + hero:GetHealthPercent()
  end
  return teamHpPc / table.getn(team)
end

-- returns 0 if no tower, 1 if ally tower, -1 if enemy tower
-- can't have both ally tower and enemy tower in range??
function AnalyzeNearbyTowers(pos)
  local status = 0
  for _, building in pairs(core.localUnits["AllyBuildings"]) do
    if building:IsTower() then
      local dist = Vector3.Distance2D(pos, building:GetPosition())
      if dist < 600 then
        status = 1
      end
    end
  end
  for _, building in pairs(core.localUnits["EnemyBuildings"]) do
    if building:IsTower() then
      local dist = Vector3.Distance2D(pos, building:GetPosition())
      if dist < 800 then
        status = -1
      end
    end
  end
  return status
end

function generics.AnalyzeAllyHeroPosition(hero)
  local heroPos = hero:GetPosition()
  local nearbyAllies = core.teamBotBrain:GetAllyTeam(heroPos, 1000)
  local nearbyEnemies = core.teamBotBrain:GetEnemyTeam(heroPos, 1000)
  local allyCount = table.getn(nearbyAllies)
  local enemyCount = table.getn(nearbyEnemies)
  local allyAvgHpPc = CalculateTeamHealthPc(nearbyAllies)
  local enemyAvgHpPc = CalculateTeamHealthPc(nearbyEnemies)
  local towerStatus = AnalyzeNearbyTowers(heroPos)
  -- core.BotEcho(allyCount .. " " .. enemyCount .. " " .. allyAvgHpPc .. " " .. enemyAvgHpPc)
  if enemyCount > allyCount and enemyAvgHpPc > allyAvgHpPc then
    return "GROUP" --"RETREAT"
  elseif enemyCount == 0 or enemyCount > allyCount or (enemyCount == allyCount and enemyAvgHpPc >= allyAvgHpPc) then
    return "GROUP"
  elseif (enemyCount == allyCount and allyAvgHpPc > enemyAvgHpPc) or (allyCount > enemyCount and enemyAvgHpPc > allyAvgHpPc) then
    return "HARASS"
  elseif allyCount > enemyCount and allyAvgHpPc > enemyAvgHpPc then
    return "ATTACK"
  else
    return "GROUP"
  end
end
