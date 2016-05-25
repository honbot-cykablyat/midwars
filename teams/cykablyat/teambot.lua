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

local function GetNearbyTeams(hero)
  local nearbyAllies = {}
  local nearbyEnemies = {}
  local allyTeamHealthPc = 0
  local enemyTeamHealthPc = 0
  for _, ally in pairs(object.tAllyHeroes) do
    local allyPos = ally:GetPosition()
    if allyPos and allyPos.x and ally:IsAlive() then
      local dist = Vector3.Distance2D(allyPos, hero:GetPosition())
      if dist < 1000 then
        tinsert(nearbyAllies, ally)
        allyTeamHealthPc = allyTeamHealthPc + ally:GetHealthPercent()
      end
    end
  end
  for _, enemy in pairs(object.tEnemyHeroes) do
    local enemyPos = enemy:GetPosition()
    if enemyPos and enemyPos.x and enemy:IsAlive() then
      local dist = Vector3.Distance2D(enemyPos, hero:GetPosition())
      if dist < 1000 then
        tinsert(nearbyEnemies, enemy)
        enemyTeamHealthPc = enemyTeamHealthPc + enemy:GetHealthPercent()
      end
    end
  end
  -- core.BotEcho(allyTeamHealthPc / table.getn(nearbyAllies))
  local allyTeamAvgHpPc = nil
  local enemyTeamAvgHpPc = nil
  if table.getn(nearbyAllies) == 0 then
    allyTeamAvgHpPc = 0
  else
    allyTeamAvgHpPc = allyTeamHealthPc / table.getn(nearbyAllies)
  end
  if table.getn(nearbyEnemies) == 0 then
    enemyTeamAvgHpPc = 0
  else
    enemyTeamAvgHpPc = enemyTeamHealthPc / table.getn(nearbyEnemies)
  end
  return {
    table.getn(nearbyAllies),
    table.getn(nearbyEnemies),
    allyTeamAvgHpPc,
    enemyTeamAvgHpPc
  }
end

function object:AnalyzeAllyHeroPosition(hero)
  local nearbyTeams = GetNearbyTeams(hero)
  -- core.BotEcho(nearbyTeams[1] .. " " .. nearbyTeams[2] .. " " .. nearbyTeams[3] .. " " .. nearbyTeams[4])
  if nearbyTeams[2] > nearbyTeams[1] and nearbyTeams[4] > nearbyTeams[3] then
    return "RETREAT"
  elseif nearbyTeams[2] == 0 or nearbyTeams[2] > nearbyTeams[1] or (nearbyTeams[2] == nearbyTeams[1] and nearbyTeams[4] >= nearbyTeams[3]) then
    return "GROUP"
  elseif (nearbyTeams[2] == nearbyTeams[1] and nearbyTeams[3] > nearbyTeams[4]) or (nearbyTeams[1] > nearbyTeams[2] and nearbyTeams[4] > nearbyTeams[3]) then
    return "HARASS"
  elseif nearbyTeams[1] > nearbyTeams[2] and nearbyTeams[3] > nearbyTeams[4] then
    return "ATTACK"
  else
    return "GROUP"
  end
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
      -- core.BotEcho("is valid")
      teamHealthPc = teamHealthPc + hero:GetHealthPercent()
      tinsert(validHeroes, hero)
    end
  end
  -- local validTeam = FindGroupCenter(validHeroes)
  local validTeam = {}
  local teamPosition = HoN.GetGroupCenter(validHeroes)
  for _, hero in pairs(validHeroes) do
    -- core.BotEcho("pos: " .. tostring(hero:GetPosition()))
    -- core.BotEcho("x " .. hero:GetPosition().x .. " y " .. hero:GetPosition().y)
    local distanceToCenter = Vector3.Distance2D(teamPosition, hero:GetPosition())
    -- core.BotEcho("which distance was " .. distanceToCenter)
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
  -- if not object.allyTeam[1] or not object.enemyTeam[1] then
  --   state = "LANE_PASSIVELY"
  --   return
  -- end
  --
  -- -- core.BotEcho("Enemies: " .. object.enemyTeam[2] .. " Allies: " .. object.allyTeam[2])
  --
  -- local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  -- local allyTower = core.GetClosestAllyTower(enemyBasePos)
  -- local allyTowerPos = allyTower:GetPosition()
  -- local enemyTower = core.GetClosestEnemyTower(allyTowerPos)
  -- local enemyTowerPos = enemyTower:GetPosition()
  --
  -- local distToAllyTower = Vector3.Distance2D(object.allyTeam[1], allyTowerPos)
  -- local distToEnemyTower = Vector3.Distance2D(object.allyTeam[1], enemyTowerPos)

  -- if object.enemyTeam[2] < object.allyTeam[2] then
  --   state = "LANE_AGGRESSIVELY"
  -- elseif object.enemyTeam[2] > object.allyTeam[2] then
  --   state = "TEAM_RETREAT"
  -- else
  --   state = "LANE_PASSIVELY"
  -- end

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
    if hero:GetPosition() and hero:GetPosition().x and hero:IsAlive() then
      tinsert(team, hero)
    end
  end
  return team
end

function object:GetEnemyTeam()
  local team = {}
  for _, hero in pairs(object.tEnemyHeroes) do
    if hero:GetPosition() and hero:GetPosition().x and hero:IsAlive() then
      tinsert(team, hero)
    end
  end
  return team
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
  -- BotEcho("hi")
  -- core.BotEcho(tostring(core.localUnits["Enemies"]))
  -- core.BotEcho(tostring(object.tEnemyHeroes))
  -- core.printTable(core.localUnits["EnemyCreeps"])
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
  -- EvaluateTeamMapPosition()
  -- core.BotEcho(state)
  -- if allyTeam[1] then
  --   teamTarget = FindBestEnemyTargetInRange(allyTeam[1], 500)
  -- end
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride
