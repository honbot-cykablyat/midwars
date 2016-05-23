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

local availableStates = {"DEFEND_OWN_TOWER", "LANE_PASSIVELY", "LANE_AGGRESSIVELY", "AVOID_ENEMY_TOWER", "ATTACK_ENEMY_TOWER"}
local state
local function EvaluateTeamMapPosition()

  local furthestCreepPos = object:GetFrontOfCreepWavePosition("middle")
  core.DrawXPosition(furthestCreepPos, "red", 10000)
  -- core.BotEcho(furthestCreepPos.x .." ".. furthestCreepPos.y)
  local allyHeroesNearCreep = {}
  for _, allyHero in pairs(object.tAllyHeroes) do
    if allyHero:IsAlive() then
      local distanceToCreep = Vector3.Distance2D(furthestCreepPos, allyHero:GetPosition())
      if distanceToCreep < 1000 then
        tinsert(allyHeroesNearCreep, allyHero)
      end
    end
  end

  local myTeamPos = HoN.GetGroupCenter(allyHeroesNearCreep)
  -- local enemyTeamPos = HoN.GetGroupCenter(allyHeroesNearCreep)

  core.DrawXPosition(myTeamPos)
  core.DrawXPosition(enemyTeamPos)
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
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

local attack_priority = {"Hero_Fairy", "Hero_PuppetMaster", "Hero_Valkyrie", "Hero_MonkeyKing", "Hero_Devourer"};

local unitTeamTarget = nil

function object:GetTeamTarget()
  if unitTeamTarget and unitTeamTarget:IsValid() then
    if self:CanSeeUnit(unitTeamTarget) then
      return self:GetMemoryUnit(unitTeamTarget)
    else
      unitTeamTarget = nil
    end
  end
  return nil
end

function object:SetTeamTarget(target)
  unitTeamTarget = target
end

function object:GroupAndPushLogic()

end
