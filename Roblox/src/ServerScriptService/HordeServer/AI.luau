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
 local count=0
 local own=s.cities.novgorod
 local cap=s.tiles[own.tile]
 local threat
 for _,u in pairs(s.units) do
  if u.faction=="mongol" and B.distance(s.tiles[u.tile],cap)<=3 then
   if not threat or s.tiles[u.tile].id<threat.id then threat=s.tiles[u.tile] end
  end
 end
 for _,id in ipairs(s.unitOrder) do
  local u=s.units[id]
  if u and u.faction=="rus" and not s.result then
   local victim=enemies(s,u)
   if victim and not u.attacked then if M.attack(s,"rus",id,victim.id) then count+=1 end end
   local goal=threat
   if not goal then
    for _,k in ipairs({"sarkel","crossroads","sarai"}) do
     local city=s.cities[k]
     if city.owner~="rus" then goal=s.tiles[city.tile];break end
    end
   end
   if goal then
    local route=distances(s,goal)
    local opts=B.moveRange(s,u)
    local best,bestValue
    for _,t in ipairs(s.order) do
     if opts[t] then
      local tile=s.tiles[t]
      local distance=route[t] or 100
      local value=-distance*10-opts[t]*.2+(tile.owner=="rus" and 0 or 2)
      if not bestValue or value>bestValue then best,bestValue=t,value end
     end
    end
    local current=route[u.tile] or 100
    if best and (route[best] or 100)<current and M.move(s,"rus",id,best) then count+=1 end
   end
   victim=enemies(s,u)
   if victim and not u.attacked and not s.result then if M.attack(s,"rus",id,victim.id) then count+=1 end end
  end
 end
 if not s.result then
  for _,id in ipairs(s.cityOrder) do
   if s.cities[id].owner=="rus" then
    if M.recruit(s,"rus",id,s.turn%2==0 and "spear" or "infantry") then count+=1 end
    if threat and M.build(s,"rus",id,"fortress") then count+=1
    elseif M.build(s,"rus",id,s.turn%2==0 and "farm" or "lumber") then count+=1 end
   end
  end
 end
 return count
end
return A
