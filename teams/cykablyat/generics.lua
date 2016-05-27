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

generics.positionStatus = "NULL:D"

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
  local value = 0
  -- if generics.positionStatus == "GROUP" then
  --   value = 25
  -- elseif core.teamBotBrain:GetTeamStatus() == "REGROUP" then
  --   value = 40
  -- end
  -- BotEcho("asdf " .. value)
  return value
end

function groupExecute(botBrain)
  local unitSelf = core.unitSelf
  local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  local allyTower = core.GetClosestAllyTower(enemyBasePos)
  local allyTowerPos = allyTower:GetPosition()
  if Vector3.Distance2D(unitSelf, allyTowerPos) < 1000 then
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
      if intersects({arrowPos, heading * 750}, {Vector3.Create(pos.x - 3, pos.y - 3, 0), Vector3.Create(pos.x + 3, pos.y + 3, 0)}) then
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

function generics.CalculateTeamHealthPc(team)
  if table.getn(team) == 0 then
    return 0
  end
  local teamHpPc = 0
  for _, hero in pairs(team) do
    teamHpPc = teamHpPc + hero:GetHealthPercent()
  end
  return teamHpPc / table.getn(team)
end

-- returns a number between 1 and -1 depending if closer to ally or enemy tower
function generics.AnalyzeNearbyTowers(pos)
  local allyTowerDist = Vector3.Distance2D(pos, core.GetClosestAllyTower(pos):GetPosition())
  local enemyTowerDist = Vector3.Distance2D(pos, core.GetClosestEnemyTower(pos):GetPosition())
  -- local allyValue = math.ceil(700 - allyTowerDist) * 1 / allyTowerDist
  -- local enemyValue = math.ceil(1000 - enemyTowerDist) * 1.3 / enemyTowerDist
  if allyTowerDist < 650 then
    return 1
  elseif enemyTowerDist < 1000 then
    return -1
  else
    return 0
  end
end

function generics.AnalyzeAllyHeroPosition(hero)
  local heroPos = hero:GetPosition()
  local nearbyAllies = core.teamBotBrain:GetAllyTeam(heroPos, 1000)
  local nearbyEnemies = core.teamBotBrain:GetEnemyTeam(heroPos, 1000)
  local allyCount = table.getn(nearbyAllies)
  local enemyCount = table.getn(nearbyEnemies)
  local allyAvgHpPc = generics.CalculateTeamHealthPc(nearbyAllies)
  local enemyAvgHpPc = generics.CalculateTeamHealthPc(nearbyEnemies)
  local towerStatus = generics.AnalyzeNearbyTowers(heroPos)
  local status = nil
  -- core.BotEcho(allyCount .. " " .. enemyCount .. " " .. allyAvgHpPc .. " " .. enemyAvgHpPc)
  -- BotEcho("tower status " .. towerStatus)
  if enemyCount > allyCount and (enemyAvgHpPc > allyAvgHpPc + 0.3 or towerStatus == -1) then
    status =  "RETREAT"
  elseif enemyCount == 0 or enemyCount > allyCount or (enemyCount == allyCount and enemyAvgHpPc >= allyAvgHpPc) then
    status = "GROUP"
  elseif (enemyCount == allyCount and allyAvgHpPc > enemyAvgHpPc) or (allyCount > enemyCount and enemyAvgHpPc > allyAvgHpPc) then
    status = "HARASS"
  elseif allyCount > enemyCount and allyAvgHpPc > enemyAvgHpPc then
    status = "ATTACK"
  else
    status = "GROUP"
  end
  -- BotEcho("status: " .. status)
  generics.positionStatus = status
end

function RallyTeamBehaviorUtility(botBrain)
  -- if core.teamBotBrain:GetTeamStatus() == "RALLY_TEAM" and core.teamBotBrain:GetHeroBehavior(core.unitSelf) ~= "HEALING" then
  --   BotEcho("rallying!!!")
  --   return 0
  --   -- return 60
  -- end
  return 0
end

function RallyTeamBehaviorExecute(botBrain)
  BotEcho("executing rally behavior")
  local rallyPoint = core.teamBotBrain:GetRallyPoint()
  local dist = Vector3.Distance2D(core.unitSelf:GetPosition(), rallyPoint)
  if dist > 700 then
    if Vector3.Distance2DSq(core.unitSelf:GetPosition(), rallyPoint) > 1200 * 1200 then
      itemGhostMarchers = core.GetItem("Item_EnhancedMarchers")
      if itemGhostMarchers ~= nil and itemGhostMarchers:CanActivate() then
        botBrain:OrderItem(itemGhostMarchers.object or itemGhostMarchers, false)
      end
    end
    core.OrderMoveToPosAndHoldClamp(botBrain, core.unitSelf, rallyPoint, false)
  else
    BotEcho("at rally point")
    core.teamBotBrain:UpdateHeroBehavior(core.unitSelf, "Rallying")
  end
end

generics.RallyTeamBehavior = {}
generics.RallyTeamBehavior["Utility"] = RallyTeamBehaviorUtility
generics.RallyTeamBehavior["Execute"] = RallyTeamBehaviorExecute
generics.RallyTeamBehavior["Name"] = "RallyTeam"

-- fall back to ally tower if too far away

function RegroupBehaviorUtility(botBrain)
  -- local pos = core.unitSelf:GetPosition()
  -- local enemyBaseDist = Vector3.Distance2D(pos, core.enemyMainBaseStructure:GetPosition())
  -- local allyBaseDist = Vector3.Distance2D(pos, core.allyMainBaseStructure:GetPosition())
  -- local allyTowerDist = Vector3.Distance2D(pos, core.GetClosestAllyTower(pos):GetPosition())
  -- local allies = core.teamBotBrain:GetAllyTeam(pos, 1000)
  -- local alliesHpPc = generics.CalculateTeamHealthPc(allies)
  -- local value = 3 / table.getn(allies) / alliesHpPc * (allyTowerDist / 70)
  -- BotEcho("regroup value " .. value)
  -- if table.getn(allies) < 3 and allyTowerDist > 600 and enemyBaseDist < allyBaseDist then
  --   return value
  -- end
  return 0
end

function RegroupBehaviorExecute(botBrain)
  BotEcho("REGROUPING!!")
  local rallyPoint = core.teamBotBrain:GetRallyPoint()
  local dist = Vector3.Distance2D(core.unitSelf:GetPosition(), rallyPoint)
  if dist > 500 then
    if Vector3.Distance2D(core.unitSelf:GetPosition(), rallyPoint) > 1200 then
      itemGhostMarchers = core.GetItem("Item_EnhancedMarchers")
      if itemGhostMarchers ~= nil and itemGhostMarchers:CanActivate() then
        botBrain:OrderItem(itemGhostMarchers.object or itemGhostMarchers, false)
      end
    end
    core.OrderMoveToUnitClamp(botBrain, core.unitSelf, rallyPoint)
    -- local vecPos = object.behaviorLib.PositionSelfBackUp()
    -- core.DrawXPosition(vecPos, "yellow", 1000)
		-- return vecPos and core.OrderMoveToPosClamp(botBrain, core.unitSelf, vecPos, false)
  else
    BotEcho("AT REGROUP POINT")
  end
end

generics.RegroupBehavior = {}
generics.RegroupBehavior["Utility"] = RegroupBehaviorUtility
generics.RegroupBehavior["Execute"] = RegroupBehaviorExecute
generics.RegroupBehavior["Name"] = "Regroup"

-- fix that stupid ring

local function PositionSelfExecuteFix(botBrain)
	local nCurrentTimeMS = HoN.GetGameTime()
	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition()

	if core.unitSelf:IsChanneling() then
		return
	end

	local vecDesiredPos = vecMyPosition
	local unitTarget = nil
	vecDesiredPos, unitTarget = behaviorLib.PositionSelfLogic(botBrain)

	if vecDesiredPos then
		behaviorLib.MoveExecute(botBrain, vecDesiredPos)
	else
		BotEcho("PositionSelfExecute - nil desired position")
		return false
	end

end
behaviorLib.PositionSelfBehavior["Execute"] = PositionSelfExecuteFix

local function PushExecuteFix(botBrain)
	if core.unitSelf:IsChanneling() then
		return
	end

	local unitSelf = core.unitSelf
	local bActionTaken = false

	--Attack creeps if we're in range
	if bActionTaken == false then
		local unitTarget = core.unitEnemyCreepTarget
		if unitTarget then
			local nRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
			if unitSelf:GetAttackType() == "melee" then
				--override melee so they don't stand *just* out of range
				nRange = 250
			end

			if unitSelf:IsAttackReady() and core.IsUnitInRange(unitSelf, unitTarget, nRange) then
				bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitTarget)
			end

		end
	end

	if bActionTaken == false then
		local vecDesiredPos = behaviorLib.PositionSelfLogic(botBrain)
		if vecDesiredPos then
			bActionTaken = behaviorLib.MoveExecute(botBrain, vecDesiredPos)

		end
	end

	if bActionTaken == false then
		return false
	end
end
behaviorLib.PushBehavior["Execute"] = PushExecuteFix
