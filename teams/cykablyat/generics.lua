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

generics.positionStatus = nil

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
    botBrain:OrderPosition(core.unitSelf.object, "attack", healPos, "none", nil, true)
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
  return true
  -- local unitSelf = core.unitSelf
  -- local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  -- local allyTower = core.GetClosestAllyTower(enemyBasePos)
  -- local allyTowerPos = allyTower:GetPosition()
  -- if Vector3.Distance2D(unitSelf:GetPosition(), allyTowerPos) < 1000 then
  --   botBrain:OrderPosition(unitSelf.object, "attack", allyTowerPos, "none", nil, false)
  -- end
  -- local allyTeam = core.teamBotBrain:GetAllyTeam(unitSelf:GetPosition(), 1000);
  -- allyTeam = HoN.GetGroupCenter(allyTeam);
  -- if allyTeam then
  --   botBrain:OrderPosition(unitSelf.object, "attack", allyTeam, "none", nil, false)
  -- end
end

generics.GroupBehavior = {}
generics.GroupBehavior["Utility"] = groupUtility
generics.GroupBehavior["Execute"] = groupExecute
generics.GroupBehavior["Name"] = "Group"

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

-- returns 0 if no tower, 1 if ally tower, -1 if enemy tower
-- can't have both ally tower and enemy tower in range??
function generics.AnalyzeNearbyTowers(pos)
  -- BotEcho("yo")
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
    -- BotEcho("building " .. building:GetTypeName())
    if building:IsTower() then
      local dist = Vector3.Distance2D(pos, building:GetPosition())
      -- BotEcho("dist" .. dist)
      if dist < 1000 then
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
  local allyAvgHpPc = generics.CalculateTeamHealthPc(nearbyAllies)
  local enemyAvgHpPc = generics.CalculateTeamHealthPc(nearbyEnemies)
  local towerStatus = generics.AnalyzeNearbyTowers(heroPos)
  local status = nil
  -- core.BotEcho(allyCount .. " " .. enemyCount .. " " .. allyAvgHpPc .. " " .. enemyAvgHpPc)
  BotEcho("tower status " .. towerStatus)
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
  BotEcho("status: " .. status)
  generics.positionStatus = status
end

function RallyTeamBehaviorUtility(botBrain)
  if core.teamBotBrain:GetTeamStatus() == "RALLY_TEAM" then
    return 35
  end
  return 0
end

function RallyTeamBehaviorExecute(botBrain)
  local rallyPoint = core.teamBotBrain:GetRallyPoint()
  local dist = Vector3.Distance2D(core.unitSelf:GetPosition(), rallyPoint)
  if dist > 250 then
    if Vector3.Distance2DSq(core.unitSelf:GetPosition(), rallyPoint) > 1200 * 1200 then
      itemGhostMarchers = core.GetItem("Item_EnhancedMarchers")
      if itemGhostMarchers ~= nil and itemGhostMarchers:CanActivate() then
        botBrain:OrderItem(itemGhostMarchers.object or itemGhostMarchers, false)
      end
    end
    core.OrderMoveToPosAndHoldClamp(botBrain, core.unitSelf, rallyPoint, false)
  else
    core.teamBotBrain:UpdateHeroStatus(core.unitSelf, "RALLYING")
  end
end

behaviorLib.RallyTeamBehavior = {}
behaviorLib.RallyTeamBehavior["Utility"] = RallyTeamBehaviorUtility
behaviorLib.RallyTeamBehavior["Execute"] = RallyTeamBehaviorExecute
behaviorLib.RallyTeamBehavior["Name"] = "RallyTeam"

-- update team when you are going to well for healing

-- local function CustomHealAtWellExecute(botBrain)
--   core.teamBotBrain:UpdateTeamOfHeroStatus(core.unitSelf, "HEALING")
--   return false
-- end
--
-- behaviorLib.CustomHealAtWellBehavior["Execute"] = CustomHealAtWellExecute

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
