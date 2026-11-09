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
local w,g=s.resources.mongol.wood,s.resources.mongol.gold
good(M.build(s,"mongol","sarai","farm") and s.resources.mongol.wood==w-7 and s.resources.mongol.gold==g-3,"Construction deducts exact costs")
good(not M.build(s,"mongol","sarai","farm") and not M.build(s,"mongol","sarai","fortress"),"Duplicate and same-turn construction rejected")
local food=s.resources.mongol.food
g=s.resources.mongol.gold
good(M.recruit(s,"mongol","sarai","spear") and s.resources.mongol.food==food-5 and s.resources.mongol.gold==g-7,"Recruitment deducts exact costs")
good(s.units.U7.mp==0 and not M.recruit(s,"mongol","sarai","infantry"),"New unit waits and duplicate recruitment rejected")
local incoming=M.income(s,"mongol")
food=s.resources.mongol.food
s.turn+=1;M.begin(s,"mongol")
good(s.resources.mongol.food==food+incoming.food and incoming.food>=8 and s.units.U7.mp==3,"Income and new-turn reset")
local store=M.snapshot(s)
store.resources.mongol.gold=0
good(s.resources.mongol.gold>0,"Snapshot isolates resource state")
local function relocate(s,id,tile)
 local u=s.units[id]
 s.tiles[u.tile].unit=nil;s.tiles[tile].unit=id;u.tile=tile
end
local c=M.new(12,1811)
local enemy=c.units.U4
good(not M.attack(c,"mongol","U1",enemy.id),"Out-of-range combat rejected")
local near=B.key(9,6)
relocate(c,"U1",near)
local dmg=M.damage(c,c.units.U1,enemy)
good(M.attack(c,"mongol","U1",enemy.id) and enemy.hp==enemy.maxHp-dmg,"Ranged attack uses deterministic damage")

return {checks=checks,console="server VM"}
