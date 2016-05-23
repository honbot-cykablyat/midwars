local _G = getfenv(0)
local object = _G.object

runfile 'bots/teambot/teambotbrain.lua'

object.myName = 'Cyka Blyat'

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