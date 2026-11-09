local S=game.ServerScriptService.HordeServer
local M=require(S.Match)
local C=require(game.ReplicatedStorage.HordeShared.Config)
local B=require(game.ReplicatedStorage.HordeShared.Board)
local AI=require(S.AI)
local checks={}
local function good(x,why) assert(x,why);table.insert(checks,why) end
local mapCount=0
for _,n in ipairs({12,14,16}) do
 for _,seed in ipairs({11,34,1811}) do
  local a,b=M.new(n,seed),M.new(n,seed)
  assert(#a.order==n*n)
  assert(#a.unitOrder==6)
  for _,id in ipairs(a.order) do
   local t=a.tiles[id]
   assert(t.id==id and t.terrain==b.tiles[id].terrain and C.Terrain[t.terrain])
   for _,adj in ipairs(B.neighbors(a,t)) do assert(B.distance(adj,t)==1) end
  end
  local queue={a.tiles[a.cities.sarai.tile]}
  local seen={[queue[1].id]=true}
  local index=1
  while queue[index] do
   for _,k in ipairs(B.neighbors(a,queue[index])) do
    if not seen[k.id] and C.Terrain[k.terrain].move<99 then seen[k.id]=true;table.insert(queue,k) end
   end

return {checks=checks,mapCount=mapCount,console="server VM"}
