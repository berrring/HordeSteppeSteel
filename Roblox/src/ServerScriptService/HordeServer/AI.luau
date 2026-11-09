local C=require(game.ReplicatedStorage.HordeShared.Config)
local B=require(game.ReplicatedStorage.HordeShared.Board)
local M=require(script.Parent.Match)
local A={}
local function enemies(s,u)
 local best,val
 for _,id in ipairs(s.unitOrder) do
  local v=s.units[id]
  if v and v.faction~="rus" and B.distance(s.tiles[u.tile],s.tiles[v.tile])<=C.Units[u.kind].range then
   local score=v.hp-M.damage(s,u,v)
   if not val or score<val then best,val=v,score end
  end
 end
 return best
end
local function distances(s,goal)
 local open={goal}
 local seen={[goal.id]=0}
 local i=1
 while i<=#open do
  local t=open[i];i+=1
  for _,n in ipairs(B.neighbors(s,t)) do
   if C.Terrain[n.terrain].move<99 and not seen[n.id] then
    seen[n.id]=seen[t.id]+1;table.insert(open,n)
   end
  end
 end
 return seen
end
function A.run(s)

return AI
