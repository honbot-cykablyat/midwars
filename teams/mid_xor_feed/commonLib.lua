local _G = getfenv(0)
local object = _G.object

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random
local min = _G.math.min

local BotEcho, VerboseLog, BotLog, Clamp = core.BotEcho, core.VerboseLog, core.BotLog, core.Clamp

object.commonLib = {}
local commonLib = object.commonLib

-- return -1 if enemy tower in range, 1 if ally tower, 0 if neither
function commonLib.RelativeTowerPosition(enemyTarget)
  local enemyTowers = core.localUnits['EnemyTowers']
  local allyTowers = core.localUnits['AllyTowers']

  local enemyDist = 99999
  local allyDist = 99999

  for i, tower in pairs(enemyTowers) do
    enemyDist = min(enemyDist, Vector3.Distance2D(enemyTarget:GetPosition(), tower:GetPosition()))
  end

  for i, tower in pairs(allyTowers) do
    allyDist = min(allyDist, Vector3.Distance2D(enemyTarget:GetPosition(), tower:GetPosition()))
  end

  if enemyDist == allyDist then
    return 0
  end

  if enemyDist < allyDist then
    return -1
  end

  return 1

end

function commonLib.IsDisabled(enemyTarget)
  return enemyTarget:IsStunned() or enemyTarget:IsImmobilized() or enemyTarget:IsPerplexed()
end

function commonLib.IsFreeLine(pos1, pos2)
  --BotEcho("freeline check")
  --core.DrawDebugLine(pos1, pos2, "yellow")
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local reserveWidth = 100*100

  local obstructed = false

  for _, ally in pairs(tAllies) do
    local posAlly = ally:GetPosition()
    local x0, y0, z0 = posAlly.x, posAlly.y, posAlly.z
    local U = (x0 - x1)*(x2 - x1) + (y0 - y1)*(y2 - y1)
    U = U / ((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))
    local xc = x1 + (U * (x2 - x1))
    local yc = y1 + (U * (y2 - y1))
    local d2 = (x0 - xc)*(x0 - xc) + (y0 - yc)*(y0 - yc)

    local color = "red"
    if d2 >= reserveWidth then color = "green" end
    local t = (xc - x1) / (x2 - x1)
    local between = t < 1 and t > 0
    if not between then color = "yellow" end

    if d2 < reserveWidth and between then
      --core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
      --core.DrawXPosition(posAlly, color, 25)
      obstructed = true
      break
    else
      --core.DrawXPosition(posCreep, color, 25)
      --core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
    end
  end

  if not obstructed then 
    for _, creep in pairs(tEnemies) do
      local posCreep = creep:GetPosition()
      local x0, y0, z0 = posCreep.x, posCreep.y, posCreep.z
      local U = (x0 - x1)*(x2 - x1) + (y0 - y1)*(y2 - y1)
      U = U / ((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))
      local xc = x1 + (U * (x2 - x1))
      local yc = y1 + (U * (y2 - y1))
      local d2 = (x0 - xc)*(x0 - xc) + (y0 - yc)*(y0 - yc)

      local color = "red"
      if d2 >= reserveWidth then color = "green" end
      local t = (xc - x1) / (x2 - x1)
      local between = t < 1 and t > 0
      if not between then color = "yellow" end

      if d2 < reserveWidth and between then
        --core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
        --core.DrawXPosition(posCreep, color, 25)
        obstructed = true
        break
      else 
        --core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
        --core.DrawXPosition(posCreep, color, 25)
      end
    end
  end

  if obstructed then return false end

  core.DrawDebugLine(pos1, pos2, "green")
  return true
end

function commonLib.IsFreeLineNoAllies(pos1, pos2)
  --BotEcho("freeline check")
  core.DrawDebugLine(pos1, pos2, "yellow")
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local reserveWidth = 100*100

  local obstructed = false

  for _, creep in pairs(tEnemies) do
    local posCreep = creep:GetPosition()
    local x0, y0, z0 = posCreep.x, posCreep.y, posCreep.z
    local U = (x0 - x1)*(x2 - x1) + (y0 - y1)*(y2 - y1)
    U = U / ((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))
    local xc = x1 + (U * (x2 - x1))
    local yc = y1 + (U * (y2 - y1))
    local d2 = (x0 - xc)*(x0 - xc) + (y0 - yc)*(y0 - yc)

    local color = "red"
    if d2 >= reserveWidth then color = "green" end
    local t = (xc - x1) / (x2 - x1)
    local between = t < 1 and t > 0
    if not between then color = "yellow" end

    if d2 < reserveWidth and between then
      --core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
      --core.DrawXPosition(posCreep, color, 25)
      obstructed = true
      break
    end
  end

  if obstructed then return false end

  --core.DrawDebugLine(pos1, pos2, "green")
  return true
end

function commonLib.CustomHarassUtility(target)
  local nUtil = 0
  local creepLane = core.GetFurthestCreepWavePos(core.tMyLane, core.bTraverseForward)
  local unitSelf = core.unitSelf
  local myPos = unitSelf:GetPosition()

  if unitSelf:GetHealthPercent() < 0.3 then
     nUtil = nUtil - 10
  end

  if unitSelf:GetHealth() > target:GetHealth() then
     nUtil = nUtil + 20
  end
  
  if target:IsChanneling() or target:IsDisarmed() or target:IsImmobilized() or target:IsPerplexed() or target:IsSilenced() or target:IsStunned() or unitSelf:IsStealth() then
    nUtil = nUtil + 50
  end

  local unitsNearby = core.AssessLocalUnits(object, myPos,100)
  
  if #unitsNearby.AllyHeroes == 0 then
  
    if core.GetClosestEnemyTower(myPos, 720) then
      nUtil = nUtil - 100
    end
    
    for id, creep in pairs(unitsNearby.EnemyCreeps) do
      local creepPos = creep:GetPosition()
      if(creep:GetAttackType() == "ranged" or Vector3.Distance2D(myPos, creepPos) < 20) then
        core.DrawXPosition(creepPos)
        nUtil = nUtil - 20
      end 
    end
  end

  return nUtil
end

--
-- courier behaviour
--

local CourierUseBehavior = {}
local function CourierUseUtility(botBrain)

  if #behaviorLib.curItemList == 0 then
    behaviorLib.DetermineBuyState(botBrain)
    --BotEcho("Populating itemlist")
  end

  if #behaviorLib.curItemList == 0 then
    --BotEcho("Itemlist empty")
    return 0
  end

  -- count empty slots
  local emptyInventorySlots = 0
  for slot = 1, 6, 1 do
    local curItem = inventory[slot]
    if not curItem then
      emptyInventorySlots = emptyInventorySlots + 1
    end
  end

  local emptyStashSlots = 0
  for slot = 7, 12, 1 do
    local curItem = inventory[slot]
    if not curItem then
      emptyStashSlots = emptyStashSlots + 1
    end
  end

  -- determine next buy item

  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
  local componentDefs = core.unitSelf:GetItemComponentsRemaining(nextItemDef)
  --[[
  if courierDebug then
    BotEcho("Component defs for "..nextItemDef:GetName()..":")
    core.printGetNameTable(componentDefs)
    BotEcho("Checking if room in stash and inventory...")
    BotEcho("  #components: "..#componentDefs.."  stash: "..emptyStashSlots.. "  inv: "..emptyInventorySlots)
  end
  --]]

  if emptyStashSlots == 0 then 
    --BotEcho("Stash full")
    return 0
  end

  object.courierBuyItem = nil

  local i = 1
  while i <= #componentDefs do
    local componentDef = componentDefs[i]
    if componentDef:GetCost() == 0 then
      subComponentDefs = core.unitSelf:GetItemComponentsRemaining(componentDef)
      local j = 1
      while j <= #subComponentDefs do
        local subComponentDef = subComponentDefs[i]
          if subComponentDef:GetCost() <= botBrain:GetGold() then
            object.courierBuyItem = subComponentDef
            BotEcho("Queueing component "..subComponentDef:GetName()..
                    " of "..componentDef:GetName().." of "..nextItemDef:GetName())
            BotEcho("Cost: "..subComponentDef:GetCost().." Gold: "..botBrain:GetGold())
            break
          end  
          j = j + 1
      end
    else 
      if componentDef:GetCost() <= botBrain:GetGold() then
        object.courierBuyItem = componentDef
        BotEcho("Queueing component "..componentDef:GetName().." of "..nextItemDef:GetName())
        BotEcho("Cost: "..componentDef:GetCost().." Gold: "..botBrain:GetGold())
        break
      end
    end

    if object.courierBuyItem then break end
    
    i = i + 1
  end

  if not object.courierBuyItem then
    return 0
  end

  if object.bDebugUtility == true then
    BotEcho(format("  CourierUtility: %g", 100))
  end

  return 100
end

local function CourierUseExecute(botBrain)

  if not object.courierBuyItem then return false end

  courier = object.skills.courier

  BotEcho("Buying "..object.courierBuyItem:GetName())

  core.unitSelf:PurchaseRemaining(object.courierBuyItem)
  object.courierBuyItem = nil  

  if not courier:CanActivate() then
    if courierDebug then
      BotEcho("Cannot use courier")
    end
    return 0
  end

  return core.OrderAbility(botBrain, courier)
end

--CourierUseBehavior["Utility"] = CourierUseUtility
--CourierUseBehavior["Execute"] = CourierUseExecute
--CourierUseBehavior["Name"] = "Use courier"
--tinsert(behaviorLib.tBehaviors, CourierUseBehavior)

local DenyTowerBehavior = {}
local function DenyTowerUtility(botBrain)
  local allyTowers = core.localUnits["AllyTowers"]
  for i, tower in pairs(allyTowers) do
    local healthPercent = tower:GetHealthPercent()
    if healthPercent < 0.1 then
      object.towerToDeny = tower
      return 25
    end
  end
  object.towerToDeny = nil
  return 0
end

local function DenyTowerExecute(botBrain)
  if object.towerToDeny then
    local range = core.unitSelf:GetAttackRange()
    local ownPos = core.unitSelf:GetPosition()
    local towerPos = object.towerToDeny:GetPosition()
    core.DrawXPosition(towerPos, "red", 100)
    return core.OrderAttackClamp(botBrain, core.unitSelf, object.towerToDeny)
  end
end

DenyTowerBehavior["Utility"] = DenyTowerUtility
DenyTowerBehavior["Execute"] = DenyTowerExecute
DenyTowerBehavior["Name"] = "Deny tower"
tinsert(behaviorLib.tBehaviors, DenyTowerBehavior)

local KillShrineBehavior = {}
local function KillShrineUtility(botBrain)
  if not core.enemyMainBaseStructure then 
    return 0 
  end
  if core.enemyMainBaseStructure:GetHealthPercent() ~= nil and 
    core.enemyMainBaseStructure:GetHealthPercent() < 1 then
    local ownPos = core.unitSelf:GetPosition()
    local shrinePos = core.enemyMainBaseStructure:GetPosition()
    local dist2 = Vector3.Distance2DSq(ownPos, shrinePos)
    if dist2 < 1000*1000 then
      return 40
    else
      return 0
    end
  end
  return 0
end

local function KillShrineExecute(botBrain)
  if core.enemyMainBaseStructure then
    --BotEcho("KILL SHRINE KILL SHRINE")
    local range = core.unitSelf:GetAttackRange()
    local ownPos = core.unitSelf:GetPosition()
    local shrinePos = core.enemyMainBaseStructure:GetPosition()
    core.DrawXPosition(shrinePos, "red", 100)
    local state = core.OrderAttackClamp(botBrain, core.unitSelf, object.towerToDeny)
    if state == false then
      BotEcho("ASDFASDFASDFASDF")
    end
    return state
  end
end

KillShrineBehavior["Utility"] = KillShrineUtility
KillShrineBehavior["Execute"] = KillShrineExecute
KillShrineBehavior["Name"] = "Kill shrine"
tinsert(behaviorLib.tBehaviors, KillShrineBehavior)

local PuzzleBoxBehavior = {}
local function PuzzleBoxUtility(botBrain)
  if not object.itemPuzzle or not object.itemPuzzle:CanActivate() then
    return 0
  end
  local allies = core.NumberElements(core.localUnits["AllyUnits"])
  if allies > 4 then
    return 50
  else
    return 0
  end
end

local function PuzzleBoxExecute(botBrain)
  if object.itemPuzzle and object.itemPuzzle:CanActivate() then
    BotEcho('Use Puzzlebox!!!')
    bActionTaken = core.OrderItemClamp(botBrain, unitSelf, object.itemPuzzle)
    return true
  end
  return false
end
PuzzleBoxBehavior["Utility"] = PuzzleBoxUtility
PuzzleBoxBehavior["Execute"] = PuzzleBoxExecute
PuzzleBoxBehavior["Name"] = "Puzzlebox"
tinsert(behaviorLib.tBehaviors, PuzzleBoxBehavior)