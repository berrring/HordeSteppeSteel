local Players=game:GetService("Players")
Players.CharacterAutoLoads=false
local Shared=game.ReplicatedStorage:WaitForChild("HordeShared")
local Match=require(script.Parent.Match)
local AI=require(script.Parent.AI)
local Policy=require(script.Parent.CommandPolicy)
local Renderer=require(script.Parent.Renderer)
local remote=Shared.Remotes.Command
local renderer=Renderer.new()
local current,saved,host
local generation=0
local busy=false
local function response(ok,message)
 return {
  ok=ok,message=message,state=current and Match.snapshot(current),hasSave=saved~=nil,
  income=current and Match.income(current,"mongol"),
 }
end
local function installMatch(gameState)
 generation+=1
 gameState.matchId=generation
 renderer:reset(gameState)
 renderer:update(gameState)
 current=gameState
end
local function process(player,order)
 local action=order.action
 if action=="start" then
  installMatch(Match.newCheckpoint(generation+1))
  host=player
  print(string.format("[CP1] match=%d turn=1 provinces=%d armies=%d",current.matchId,#current.order,#current.unitOrder))
  return response(true,"Select the light cavalry at Urgench. A road leads to Kipchak Steppe.")
 elseif action=="continue" then
  if not saved then return response(false,"No checkpoint in this server session.") end
  local restored=Match.snapshot(saved);restored.events={}
  installMatch(restored)
  host=player
  return response(true,"Checkpoint restored.")
 end
 if not current or host~=player then return response(false,"Start a campaign first.") end
 if order.matchId~=current.matchId or order.turn~=current.turn then
  return response(false,"That order belongs to an earlier campaign or turn.")
 end
 if current.active~="mongol" or current.result then return response(false,"Wait for the Mongol turn.") end
 if action=="save" then
  saved=Match.snapshot(current);saved.events={}
  return response(true,"Checkpoint saved for this server session.")
 end
 current.events={}
 local success,message
 if action=="move" then
  success,message=Match.move(current,"mongol",order.unit,order.tile)
 elseif action=="attack" then
  success,message=Match.attack(current,"mongol",order.unit,order.target)
 elseif action=="end" then
  local ended=current.turn
  Match.begin(current,"rus")
  task.wait(.55)
  current.rusTurns+=1
  local count=AI.checkpoint(current)
  local lastBattle
  for _,event in ipairs(current.events) do if event.kind=="attack" then lastBattle=event.text end end
  if not current.result then
   current.turn+=1
   Match.begin(current,"mongol")
   message=string.format("Rus: %d %s. Your turn.",count,count==1 and "order" or "orders")
   if lastBattle then message="Rus: "..lastBattle end
  else
   message=lastBattle or current.endReason
  end
  print(string.format("[CP1] match=%d closed=%d rusOrders=%d rusTurns=%d next=%d phase=%s",
   current.matchId,ended,count,current.rusTurns,current.turn,current.active))
  success=true
 end
 if success then
  renderer:update(current)
  if action=="move" or action=="attack" then
   print(string.format("[CP1] match=%d turn=%d %s: %s",current.matchId,current.turn,action,message))
  end
 end
 return response(success,message)
end
remote.OnServerInvoke=function(player,order)
 local valid,reason=Policy.check(order)
 if not valid then return response(false,reason) end
 if order.action=="status" then return response(true) end
 if host and host~=player then return response(false,"This server already has a campaign commander.") end
 if busy then return response(false,"An order or enemy turn is already being resolved.") end
 busy=true
 local ok,result=xpcall(function() return process(player,order) end,debug.traceback)
 busy=false
 if ok then return result end
 warn("[CP1] Command failed: "..tostring(result))
 return response(false,"The order stopped due to a server error.")
end
Players.PlayerRemoving:Connect(function(player) if host==player then host=nil end end)
print("[CP1] Campaign server ready.")
