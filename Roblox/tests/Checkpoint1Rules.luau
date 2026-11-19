-- Run in the Studio Server Command Bar during Play.
-- These checks use a private match and leave the live campaign untouched.
local server=game.ServerScriptService.HordeServer
local M=require(server.Match)
local A=require(server.AI)
local Policy=require(server.CommandPolicy)
local B=require(game.ReplicatedStorage.HordeShared.Board)
local s=M.newCheckpoint(1)
assert(#s.order==12 and #s.roads==18,"Unexpected map geometry")
local seen,queue={sarai=true},{s.tiles.sarai}
local cursor=1
while queue[cursor] do
 local p=queue[cursor]
 cursor+=1
 for _,n in ipairs(B.neighbors(s,p)) do
  assert(table.find(n.adjacent,p.id),"Road not reciprocal")
  if not seen[n.id] then seen[n.id]=true;table.insert(queue,n) end
 end
end
assert(#queue==12,"Province graph disconnected")
assert(s.units.U1.faction=="mongol" and s.units.U3.faction=="rus")
assert(not M.move(s,"mongol","U1","novgorod"))
assert(not M.move(s,"mongol","U4","novgorod"))
assert(M.move(s,"mongol","U2","kipchak"))
assert(not M.move(s,"mongol","U2","urgench"))
assert(M.attack(s,"mongol","U1","U3"))
assert(s.tiles.kiev.owner=="mongol" and s.units.U1.tile=="kiev" and not s.units.U3)
assert(s.units.U1.hp==13 and s.units.U1.mp==0,"Unexpected combat losses or order budget")
assert(not Policy.check({action="move",matchId=1,turn=1,unit="U2",tile="urgench",gold=999999}))
assert(not Policy.check({action="end",matchId=1,turn=0}))
assert(Policy.check({action="end",matchId=1,turn=1}))
M.begin(s,"rus")
assert(not M.move(s,"mongol","U1","sarai"),"Player acted during Rus phase")
assert(A.checkpoint(s)>0,"No action from the Rus opening")
s.turn+=1
local gold=s.resources.mongol.gold
local income=M.begin(s,"mongol")
assert(s.active=="mongol" and s.turn==2 and s.resources.mongol.gold==gold+income.gold)
assert(s.units.U2.mp==1)
local restarted=M.newCheckpoint(2)
assert(restarted.turn==1 and restarted.tiles.kiev.owner=="rus" and restarted.units.U3.hp==5)
print("[CP1 RULES] topology, orders, combat, payload validation, AI, income and fresh restart passed")
return true
