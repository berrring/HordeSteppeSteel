local P=game:GetService("Players")
P.CharacterAutoLoads=false
local Shared=game.ReplicatedStorage:WaitForChild("HordeShared")
local C=require(Shared.Config)
local M=require(script.Parent.Match)
local AI=require(script.Parent.AI)
local Renderer=require(script.Parent.Renderer)
local remote=Shared.Remotes.Command
local renderer=Renderer.new()
local current,saved,host
local last={}
local function response(success,message)
 return {ok=success,message=message,state=current,hasSave=saved~=nil,income=current and M.income(current,"mongol")}
end
local function showMatch()
 renderer:reset(current)
 renderer:update(current)
end
local function process(player,r)
 if type(r)~="table" or type(r.action)~="string" then return response(false,"Invalid command.") end
 if r.action=="status" then return response(true) end
 if host and host~=player then return response(false,"This server already has a campaign commander.") end
 local now=os.clock()
 if now-(last[player] or -10)<.09 then return response(false,"One command at a time.") end
 last[player]=now
 local action=r.action
 if action=="start" then
  local n=r.size
  if type(n)~="number" or not C.Sizes[n] or r.faction~="mongol" then return response(false,"Choose a supported map and the Mongol Khanate.") end
  local seed=r.seed
  if type(seed)~="number" or seed~=seed or seed%1~=0 or seed<1 or seed>2000000000 then seed=Random.new():NextInteger(1,2000000000) end
  host=player
  current=M.new(n,seed)
  showMatch()
  return response(true,"March east and capture Novgorod. Cross the river at a ford.")
 elseif action=="continue" then
  if not saved then return response(false,"No checkpoint in this server session.") end
  host=player
  current=M.snapshot(saved);current.events={}
  showMatch()
  return response(true,"Checkpoint restored.")
 end
 if not current or host~=player then return response(false,"Start a campaign first.") end
 if action=="save" then
  if current.active~="mongol" or current.result then return response(false,"Save during an active Mongol turn.") end
  saved=M.snapshot(current);saved.events={}
  return response(true,"Checkpoint saved for this server session.")
 end
 if current.active~="mongol" or current.result then return response(false,"The campaign is no longer accepting orders.") end
 current.events={}
 local success,message
 if action=="move" and type(r.unit)=="string" and type(r.tile)=="string" then success,message=M.move(current,"mongol",r.unit,r.tile)
 elseif action=="attack" and type(r.unit)=="string" and type(r.target)=="string" then success,message=M.attack(current,"mongol",r.unit,r.target)
 elseif action=="recruit" and type(r.city)=="string" and type(r.kind)=="string" then success,message=M.recruit(current,"mongol",r.city,r.kind)
 elseif action=="build" and type(r.city)=="string" and type(r.kind)=="string" then success,message=M.build(current,"mongol",r.city,r.kind)
 elseif action=="end" then
  M.begin(current,"rus")
  local actions=AI.run(current)
  if not current.result then
   current.turn+=1
   local inc=M.begin(current,"mongol")
   message=string.format("Rus took %d actions. Income +%d gold, +%d food, +%d wood.",actions,inc.gold,inc.food,inc.wood)
  else message="The Rus army seized Sarai." end
  success=true
 else success=false;message="Unknown or malformed order." end
 if success then renderer:update(current) end
 return response(success,message)
end
remote.OnServerInvoke=function(player,r)
 local ok,value=pcall(process,player,r)
 if ok then return value end
 warn("[HORDE] Command failed: "..tostring(value))
 return response(false,"The order stopped due to a server error.")
end
P.PlayerRemoving:Connect(function(player)
 last[player]=nil
 if host==player then host=nil end
end)
print("[HORDE] Campaign server ready.")
