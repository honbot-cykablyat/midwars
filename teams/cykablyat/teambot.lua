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

object.attack_priority = {"Hero_Fairy", "Hero_PuppetMaster", "Hero_Valkyrie", "Hero_MonkeyKing", "Hero_Devourer"};

object.healPosition = nil

object.teamStatus = {}
object.teamHeroStatuses = {}
object.teamRallyPoint = nil
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

function object:GetTeamStatus()
  return object.teamStatus
end

function object:GetRallyPoint()
  return object.teamRallyPoint
end

function CreateRallyPoint()
  -- core.BotEcho("creating rally point!")
  local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  local allyBasePos = core.allyMainBaseStructure:GetPosition()
  local allyTowerPos = core.GetClosestAllyTower(enemyBasePos):GetPosition()
  local rallyPoint = allyTowerPos + (Vector3.Normalize(allyBasePos - allyTowerPos) * 200)
  core.DrawXPosition(rallyPoint, "orange", 1000)
  object.teamRallyPoint = rallyPoint
  -- object.teamRallyPoint = allyTowerPos
  -- core.DrawXPosition(object.teamRallyPoint, "green", 800)
end

function object:UpdateTeamStatus()
  local allyTeam = object:GetAllyTeam()
  local enemyTeam = object:GetEnemyTeam()
  local healing = 0
  local rallying = 0
  for _, status in pairs(object.teamHeroStatuses) do
    if status == "HEALING" then
      healing = healing + 1
    elseif status == "RALLYING" then
      rallying = rallying + 1
    end
  end
  core.BotEcho("team status: healing " .. healing .. " rallying " .. rallying)
  core.BotEcho("ally count " .. table.getn(allyTeam) .. " enemy count " .. table.getn(enemyTeam))
  if healing > 1 or table.getn(allyTeam) < 4 then
    object.teamStatus = "RALLY_TEAM"
    CreateRallyPoint()
  elseif rallying == 5 then
    object.teamStatus = ""
    object.teamHeroStatuses = {}
    object.teamRallyPoint = ""
  elseif object.teamStatus == "RALLY_TEAM" then
  else
    object.teamStatus = ""
  end
  core.BotEcho("which means " .. object.teamStatus)
end

function object:GetHeroBehavior(hero)
  return object.teamHeroStatuses[hero:GetUniqueID()]
end

function object:UpdateHeroBehavior(hero, behavior)
  if behavior == "HealAtWell" then
    object.teamHeroStatuses[hero:GetUniqueID()] = "HEALING"
  elseif behavior == "Shop" then
    object.teamHeroStatuses[hero:GetUniqueID()] = "HEALING"
  elseif behavior == "Rallying" then
    object.teamHeroStatuses[hero:GetUniqueID()] = "RALLYING"
  end
end

-- function object:GetTeamTarget()
--   if object.teamTarget then
--     --core.BotEcho(object.teamTarget:GetTypeName())
--     return self:GetMemoryUnit(object.teamTarget)
--   end
--   return nil
-- end
--
-- function object:SetTeamTarget(target)
--   object.teamTarget = target
-- end

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)
  -- custom code here
  -- object.UpdateTeamStatus()
  -- core.BotEcho("team status : " .. object.teamStatus)
  CreateRallyPoint()
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride
