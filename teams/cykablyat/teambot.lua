local _G = getfenv(0)
local object = _G.object

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

runfile 'bots/teambot/teambotbrain.lua'

object.myName = 'Cyka Blyat'

local core = object.core

-- Custom code

function object:CalculateClosestEnemyToAllyHero(ally)
  local closestEnemy = nil
  local closestPos = nil
  local closestDist = nil
  local allyPos = ally:GetPosition()
  for _, enemyHero in pairs(object.tEnemyHeroes) do
    if not enemyHero:GetPosition() and object:GetMemoryUnit(enemyHero) then
      enemyHero = object:GetMemoryUnit(enemyHero)
    end
    if enemyHero:GetPosition() and enemyHero:IsAlive() then
      local enemyPos = enemyHero:GetPosition()
      if not closestEnemy then
        closestEnemy = enemyHero
        closestPos = enemyPos
      end
      local distDifference = Vector3.Distance2D(closestPos, allyPos) - Vector3.Distance2D(enemyPos, allyPos)
      if distDifference < 0 and closestEnemy:GetHealth() > enemyHero:GetHealth() then
        closestEnemy = enemyHero
        closestPos = enemyPos
      end
      if distDifference < 200 and closestEnemy:GetHealth() > enemyHero:GetHealth() + 200 then
        closestEnemy = enemyHero
        closestPos = enemyPos
      end
    end
  end
  return closestEnemy
end

local function CalculateTeamPositionAndSize(heroes)
  local validHeroes = {}
  local teamHealthPc = 0
  -- local furthestCreepPos = object:GetFrontOfCreepWavePosition("middle")
  -- If no creeps
  -- if not furthestCreepPos then
  --   return { Vector3.create(0, 0), 5 }
  -- end
  -- core.DrawXPosition(furthestCreepPos, "red", 10000)
  -- core.BotEcho(furthestCreepPos.x .." ".. furthestCreepPos.y)
  -- local heroesNearCreep = {}
  for _, hero in pairs(heroes) do
    -- core.BotEcho("hero name " .. hero:GetTypeName() .. " of " .. hero:GetTeam())
    -- If hero is not visible fetch it from memory
    -- local heroFromMemory = object:GetMemoryUnit(hero)
    -- if heroFromMemory:GetPosition() then
      -- core.BotEcho("from memory " .. tostring(heroFromMemory:GetPosition()))
    -- end
    -- if not hero:GetPosition() and object:GetMemoryUnit(hero) then
    --   hero = object:GetMemoryUnit(hero)
    -- end
    -- core.BotEcho("heron positio : " .. tostring(hero:GetPosition()))
    -- if hero:GetPosition() then
    --   core.BotEcho("POSITION " .. tostring(hero:GetPosition()))
    -- end
    -- core.printTable(hero)

    if hero:GetPosition() and hero:IsAlive() then
      teamHealthPc = teamHealthPc + hero:GetHealthPercent()
      tinsert(validHeroes, hero)
    end
  end
  local validTeam = {}
  local teamPosition = HoN.GetGroupCenter(validHeroes)
  for _, hero in pairs(validHeroes) do
    -- core.BotEcho("pos: " .. tostring(hero:GetPosition()))
    -- core.BotEcho("x " .. hero:GetPosition().x .. " y " .. hero:GetPosition().y)
    local distanceToCenter = Vector3.Distance2D(teamPosition, hero:GetPosition())
    if distanceToCenter < 700 then
      tinsert(validTeam, hero)
    end
  end
  return {
    HoN.GetGroupCenter(validTeam),
    table.getn(validTeam),
    math.floor(teamHealthPc / table.getn(validTeam))
  }
end

local state = "LANE_PASSIVELY"
object.allyTeam = nil
object.enemyTeam = nil
local function EvaluateTeamMapPosition()

  object.allyTeam = CalculateTeamPositionAndSize(object.tAllyHeroes)
  object.enemyTeam = CalculateTeamPositionAndSize(object.tEnemyHeroes)
  -- core.BotEcho("ally team:")
  -- allyTeam = CalculateTeamPositionAndSize(object.tAllyHeroes)
  -- core.BotEcho("size: " .. allyTeam[2])
  -- core.BotEcho("enemy team:")
  -- enemyTeam = CalculateTeamPositionAndSize(object.tEnemyHeroes)
  -- core.BotEcho("size: " .. enemyTeam[2])

  -- if one of teams position is nil
  if not object.allyTeam[1] or not object.enemyTeam[1] then
    state = "LANE_PASSIVELY"
    return
  end

  core.BotEcho("Enemies: " .. object.enemyTeam[2] .. " Allies: " .. object.allyTeam[2])

  local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  local allyTower = core.GetClosestAllyTower(enemyBasePos)
  local allyTowerPos = allyTower:GetPosition()
  local enemyTower = core.GetClosestEnemyTower(allyTowerPos)
  local enemyTowerPos = enemyTower:GetPosition()

  local distToAllyTower = Vector3.Distance2D(object.allyTeam[1], allyTowerPos)
  local distToEnemyTower = Vector3.Distance2D(object.allyTeam[1], enemyTowerPos)

  if object.enemyTeam[2] < object.allyTeam[2] then
    state = "LANE_AGGRESSIVELY"
  elseif object.enemyTeam[2] > object.allyTeam[2] then
    state = "TEAM_RETREAT"
  else
    state = "LANE_PASSIVELY"
  end

  -- if distToAllyTower < 1000 then
  --   state = "DEFEND_ALLY_TOWER"
  -- elseif distToAllyTower <= distToEnemyTower then
  --   state = "LANE_PASSIVELY"
  -- elseif distToAllyTower > distToEnemyTower then
  --   state = "LANE_PASSIVELY"
  -- elseif distToEnemyTower < 750 then
  --   state = "AVOID_ENEMY_TOWER"
  -- else
  --   state = "LANE_PASSIVELY"
  -- end

  core.DrawXPosition(object.allyTeam[1], "green", 400)
  core.DrawXPosition(object.enemyTeam[1], "red", 400)
end

function object:GetState()
  return state
end


object.attack_priority = {"Hero_Fairy", "Hero_PuppetMaster", "Hero_Valkyrie", "Hero_MonkeyKing", "Hero_Devourer"};

object.healPosition = nil

object.teamTarget = nil

function object:GetAllyTeam()
  local team = {}
  for _, hero in pairs(object.tAllyHeroes) do
    if hero:GetPosition() and hero:IsAlive() then
      tinsert(team, hero)
    end
  end
  return team
end

function object:GetEnemyTeam()
  local team = {}
  for _, hero in pairs(object.tEnemyHeroes) do
    -- If hero is not visible fetch it from memory
    core.BotEcho("heron positio : " .. tostring(hero:GetPosition()))
    if not hero:GetPosition() and object:GetMemoryUnit(hero) then
      hero = object:GetMemoryUnit(hero)
    end
    if hero:GetPosition() and hero:IsAlive() then
      tinsert(team, hero)
    end
  end
  return team
end

function object:GetEnemyTeamPosition()
  -- core.BotEcho(enemyTeam[1].x)
  -- return nil
  if enemyTeam[1] then
    return enemyTeam[1]
  end
  return nil
end

function object:GetTeamTarget()
  if object.teamTarget then
    --core.BotEcho(object.teamTarget:GetTypeName())
    return self:GetMemoryUnit(object.teamTarget)
  end
  return nil
end

function object:SetTeamTarget(target)
  object.teamTarget = target
end

function object:GroupAndPushLogic()

end

local function CalculateEnemyTargetValue(enemy, position, range)
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
function object:FindBestEnemyTargetInRange(position, range)
  local bestTarget = nil
  local bestTargetValue = nil
  -- if teamTarget then
  --   bestTarget = object:GetMemoryUnit(teamTarget)
  --   if not bestTarget or not bestTarget:GetPosition() or Vector3.Distance2D(position, bestTarget:GetPosition()) > range then
  --     bestTarget = nil
  --   end
  -- end
  for _, enemyHero in pairs(object.tEnemyHeroes) do
    local value = CalculateEnemyTargetValue(enemyHero, position, range)
    if bestTarget == nil or bestTargetValue < value then
      bestTarget = enemyHero
      bestTargetValue = value
    end
  end
  return bestTarget
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
  EvaluateTeamMapPosition()
  core.BotEcho(state)
  -- if allyTeam[1] then
  --   teamTarget = FindBestEnemyTargetInRange(allyTeam[1], 500)
  -- end
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride
