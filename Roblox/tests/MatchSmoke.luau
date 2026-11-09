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
   index+=1
  end
  for _,city in pairs(a.cities) do assert(seen[city.tile],city.name) end
  mapCount+=1
 end
end
good(mapCount==9,"Nine deterministic connected boards across 12, 14 and 16")
local s=M.new(12,1811)
local a=s.units.U1
good(a.kind=="archer" and a.mp==5 and s.units.U4.faction=="rus","Both armies and Mongol mobility")
good(not M.move(s,"rus","U4",s.cities.sarai.tile) and not M.move(s,"mongol","U4",s.cities.sarai.tile),"Wrong faction and out-of-turn movement rejected")
good(not M.move(s,"mongol","U1","999:999") and not M.move(s,"mongol","U1",s.units.U2.tile),"Invalid and occupied destinations rejected")
local range=B.moveRange(s,a)
local target=next(range)
local cost=range[target]
local start=a.tile
good(M.move(s,"mongol",a.id,target) and a.mp==5-cost and not s.tiles[start].unit and s.tiles[target].unit==a.id,"Legal movement spends terrain cost and updates occupancy")
local water
for _,id in ipairs(s.order) do if s.tiles[id].terrain=="Water" then water=id;break end end
good(water and not M.move(s,"mongol",a.id,water),"Water impassable")

return {checks=checks,console="server VM"}
