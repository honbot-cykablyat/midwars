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
object.teamHeroStatuses = nil
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

function CreateRallyPoint()
  local enemyBasePos = core.enemyMainBaseStructure:GetPosition()
  local allyTower = core.GetClosestAllyTower(enemyBasePos)
  object.teamRallyPoint = allyTower:GetPosition()
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
  if healing > 2 and table.getn(enemyTeam) > table.getn(allyTeam) then
    object.teamStatus = "RALLY_TEAM"
    CreateRallyPoint()
  elseif rallying == 5 then
    object.teamStatus = ""
    object.teamRallyPoint = ""
  elseif object.teamStatus == "RALLY_TEAM" then
  else
    object.teamStatus = ""
  end
end

function object:UpdateHeroStatus(hero, status)
  object.teamHeroStatuses[hero:GetUniqueID()] = status
  object.UpdateTeamStatus()
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
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride
