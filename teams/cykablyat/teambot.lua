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

local function CalculateTeamPositionAndSize(heroes)
  local furthestCreepPos = object:GetFrontOfCreepWavePosition("middle")
  -- If no creeps
  -- if not furthestCreepPos then
  --   return { Vector3.create(0, 0), 5 }
  -- end
  -- core.DrawXPosition(furthestCreepPos, "red", 10000)
  -- core.BotEcho(furthestCreepPos.x .." ".. furthestCreepPos.y)
  local heroesNearCreep = {}
  for _, hero in pairs(heroes) do
    if hero:GetPosition() and hero:IsAlive() then
      local distanceToCreep = Vector3.Distance2D(furthestCreepPos, hero:GetPosition())
      if distanceToCreep < 1000 then
        tinsert(heroesNearCreep, hero)
      end
    end
  end
  return { HoN.GetGroupCenter(heroesNearCreep), table.getn(heroesNearCreep) }
end

local availableStates = {"DEFEND_OWN_TOWER", "LANE_PASSIVELY", "LANE_AGGRESSIVELY", "AVOID_ENEMY_TOWER", "ATTACK_ENEMY_TOWER"}
local state = "LANE_PASSIVELY"
local allyTeam = nil
local enemyTeam = nil
local function EvaluateTeamMapPosition()

  allyTeam = CalculateTeamPositionAndSize(object.tAllyHeroes)
  enemyTeam = CalculateTeamPositionAndSize(object.tEnemyHeroes)

  -- if one of teams position is nil
  if not allyTeam[1] or not enemyTeam[1] then
    state = "LANE_PASSIVELY"
    return
  end

  core.BotEcho(allyTeam[2] .. " " .. enemyTeam[2])

  local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  local allyTower = core.GetClosestAllyTower(enemyBasePos)
  local allyTowerPos = allyTower:GetPosition()
  local enemyTower = core.GetClosestEnemyTower(allyTowerPos)
  local enemyTowerPos = enemyTower:GetPosition()

  local distToAllyTower = Vector3.Distance2D(allyTeam[1], allyTowerPos)
  local distToEnemyTower = Vector3.Distance2D(allyTeam[1], enemyTowerPos)

  if enemyTeam[2] < allyTeam[2] then
    state = "LANE_AGGRESSIVELY"
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

  core.DrawXPosition(allyTeam[1], "green", 400)
  core.DrawXPosition(enemyTeam[1], "red", 400)
end

function object:GetState()
  return state
end


local attack_priority = {"Hero_Fairy", "Hero_PuppetMaster", "Hero_Valkyrie", "Hero_MonkeyKing", "Hero_Devourer"};

local healPosition = nil

local teamTarget = nil

function object:GetTeamTarget()
  if teamTarget then
    core.BotEcho(teamTarget:GetTypeName())
  end
  return teamTarget
end

function object:SetTeamTarget(target)
  teamTarget = target
end

function object:GroupAndPushLogic()

end

-- Checks for nearest and lowest hp enemy hero
local function FindBestEnemyTarget(position)
  local bestTarget = nil
  if teamTarget then
    bestTarget = object:GetMemoryUnit(teamTarget)
  end
  for _, enemyHero in pairs(object.tEnemyHeroes) do
    if enemyHero:GetPosition() and enemyHero:IsAlive() then
      local distanceToPos = Vector3.Distance2D(position, enemyHero:GetPosition())
      local enemyHealth = enemyHero:GetHealth()
      if not bestTarget then
        bestTarget = enemyHero
      end

      local bestTargetDist = Vector3.Distance2D(position, bestTarget:GetPosition())
      -- Checks if best target has more health than currently looped hero
      -- Or if best target has less than 300 more HP and current hero is 200 closer
      if (not bestTarget:IsStunned() and enemyHero:IsStunned()) or bestTarget:GetHealth() > enemyHealth or (enemyHealth - bestTarget:GetHealth() < 300 and bestTargetDist - 200 > distanceToPos) then
        bestTarget = enemyHero
      end
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
  if allyTeam[1] then
    teamTarget = FindBestEnemyTarget(allyTeam[1])
  end
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride
