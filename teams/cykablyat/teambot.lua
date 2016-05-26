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

function GetNearbyTeams(hero)
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


object.attack_priority = {"Hero_Fairy", "Hero_PuppetMaster", "Hero_Valkyrie", "Hero_MonkeyKing", "Hero_Devourer"};

object.healPosition = nil

object.teamTarget = nil

function object:GetAllyTeam(position, range)
  local team = {}
  for _, hero in pairs(object.tAllyHeroes) do
    if hero:GetPosition() and hero:GetPosition().x and hero:IsAlive() then
      if not position or Vector3.Distance2DSq(hero:GetPosition(), position) < range * range then
        tinsert(team, hero)
      end
    end
  end
  return team
end

function object:GetEnemyTeam(position, range)
  local team = {}
  for _, hero in pairs(object.tEnemyHeroes) do
    if hero:GetPosition() and hero:GetPosition().x and hero:IsAlive() then
      if not position or Vector3.Distance2DSq(hero:GetPosition(), position) < range * range then
        tinsert(team, hero)
      end
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
