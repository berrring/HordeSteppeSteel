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
function A.checkpoint(s)
 local count=0
 for _,id in ipairs(s.unitOrder) do
  if s.result then break end
  local army=s.units[id]
  if army and army.faction=="rus" and army.mp>0 then
   local from=s.tiles[army.tile]
   local enemy
   for _,adj in ipairs(B.neighbors(s,from)) do
    local other=adj.unit and s.units[adj.unit]
    if other and other.faction=="mongol" and (not enemy or other.hp<enemy.hp) then enemy=other end
   end
   if enemy then
    if M.attack(s,"rus",id,enemy.id) then count+=1 end
   else
    local route={}
    local open={}
    for _,q in ipairs(s.order) do
     local p=s.tiles[q]
     if p.owner=="mongol" then route[q]=0;table.insert(open,p) end
    end
    local i=1
    while open[i] do
     local p=open[i];i+=1
     for _,n in ipairs(B.neighbors(s,p)) do
      if route[n.id]==nil then route[n.id]=route[p.id]+1;table.insert(open,n) end
     end
    end
    local best,value
    for _,n in ipairs(B.neighbors(s,from)) do
     if not n.unit then
      local points=(n.owner~="rus" and 5 or 0)-(route[n.id] or 99)*4
      if value==nil or points>value then best,value=n,points end
     end
    end
    if best and M.move(s,"rus",id,best.id) then count+=1 end
   end
  end
 end
 return count
end
return A
