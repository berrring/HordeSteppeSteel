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

