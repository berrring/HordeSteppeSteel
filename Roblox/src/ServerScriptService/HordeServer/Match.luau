local C=require(game.ReplicatedStorage.HordeShared.Config)
local B=require(game.ReplicatedStorage.HordeShared.Board)
local Provinces=require(game.ReplicatedStorage.HordeShared.Provinces)
local M={}
local function copy(x)
 if type(x)~="table" then return x end
 local out={}
 for k,v in pairs(x) do out[k]=copy(v) end
 return out
end
function M.snapshot(s) return copy(s) end
function M.cityDefense(city)
 if not city then return 0 end
 return (city.capital and 2 or 1)+(city.owner=="rus" and 1 or 0)+(city.buildings.fortress and C.Buildings.fortress.defense or 0)
end
function M.income(s,f)
 local out={gold=0,food=0,wood=0}
 if s.scenario=="checkpoint1" then
  for _,id in ipairs(s.order) do
   local p=s.tiles[id]
   if p.owner==f then for k,v in pairs(p.yield) do out[k]+=v end end
  end
  return out
 end
 local raw={gold=0,food=0,wood=0}
 for _,id in ipairs(s.cityOrder) do
  local city=s.cities[id]
  if city.owner==f then
   out.gold+=city.capital and 6 or 4
   out.food+=4
   out.wood+=3
   for _,b in ipairs(C.BuildingOrder) do
    if city.buildings[b] and C.Buildings[b].income then
     for k,v in pairs(C.Buildings[b].income) do out[k]+=v end
    end
   end
  end
 end
 for _,id in ipairs(s.order) do
  local t=s.tiles[id]
  if t.owner==f then
   local res=C.Terrain[t.terrain].resource
   if res then raw[res]+=1 end
   if f=="mongol" and t.terrain=="Steppe" then raw.food+=1 end
   if f=="rus" and t.terrain=="Forest" then raw.wood+=2 end
  end
 end
 for k,v in pairs(raw) do out[k]+=math.floor(v/3) end
 return out
end
local function claim(s,t,owner)
 if s.scenario=="checkpoint1" then
  if t.owner==owner then return end
  t.owner=owner
  if t.city then s.cities[t.city].owner=owner end
  s.stats.captures[owner]+=1
  table.insert(s.events,{kind="capture",tile=t.id,text=t.name.." captured by "..C.Factions[owner].name.."."})
  if owner=="mongol" and t.id=="novgorod" then s.result="mongol";s.endReason="Novgorod secured" end
  return
 end
 t.owner=owner
 if not t.city then return end
 local c=s.cities[t.city]
 local prior=c.owner
 c.owner=owner
 for _,n in ipairs(B.neighbors(s,t)) do
  if not n.city and not n.unit and C.Terrain[n.terrain].move<99 then n.owner=owner end
 end
 if prior~=owner then
  c.recruited=nil
  c.built=nil
  s.stats.captures[owner]+=1
  if c.capital then s.result=owner end
  table.insert(s.events,{kind="capture",tile=t.id,text=c.name.." captured by "..C.Factions[owner].name.."."})
 end
end
local function resetBudget(s,u)
 if s.scenario=="checkpoint1" then u.mp=1;u.attacked=false;return end
 local def=C.Units[u.kind]
 u.mp=def.move+(u.faction=="mongol" and def.mounted and 1 or 0)
 u.attacked=false
end
local function spawn(s,f,kind,t,ready)
 assert(not t.unit and C.Terrain[t.terrain].move<99)
 s.serial+=1
 local def=C.Units[kind]
 local id="U"..s.serial
 local u={id=id,faction=f,kind=kind,tile=t.id,hp=def.hp,maxHp=def.hp,mp=0,attacked=true}
 if ready then resetBudget(s,u) end
 s.units[id]=u;table.insert(s.unitOrder,id);t.unit=id
 return u
end
function M.new(n,seed)
 local s=B.generate(n,seed)
 s.turn=1;s.active="mongol";s.serial=0;s.units={};s.unitOrder={};s.events={}
 s.resources={mongol=copy(C.Start),rus=copy(C.Start)}
 s.stats={kills={mongol=0,rus=0},captures={mongol=0,rus=0},recruits={mongol=0,rus=0}}
 local mid=math.floor(n/2)
 for _,p in ipairs({{"mongol","sarai",1,{"archer","light","infantry"}},{"rus","novgorod",n-2,{"infantry","spear","infantry"}}}) do
  local f,city,q,kinds=table.unpack(p)
  local c=s.cities[city]
  claim(s,s.tiles[c.tile],f)
  local positions={{q,mid},{q,mid-1},{q,mid+1}}
  for i,point in ipairs(positions) do
   local tile=s.tiles[B.key(point[1],point[2])]
   if C.Terrain[tile.terrain].move>2 then tile.terrain="Plains" end
   tile.owner=f
   spawn(s,f,kinds[i],tile,f=="mongol")
  end
 end
 return s
end
function M.newCheckpoint(matchId)
 local s=Provinces.new()
 s.matchId=matchId;s.turn=1;s.active="mongol";s.serial=0;s.units={};s.unitOrder={};s.events={};s.rusTurns=0
 s.resources={mongol=copy(C.Start),rus=copy(C.Start)}
 s.stats={kills={mongol=0,rus=0},captures={mongol=0,rus=0},recruits={mongol=0,rus=0}}
 spawn(s,"mongol","archer",s.tiles.sarai,true)
 spawn(s,"mongol","light",s.tiles.urgench,true)
 local kiev=spawn(s,"rus","infantry",s.tiles.kiev,false)
 kiev.hp=5
 spawn(s,"rus","spear",s.tiles.moscow,false)
 spawn(s,"rus","infantry",s.tiles.novgorod,false)
 return s
end
local function action(s,f)
 return not s.result and s.active==f
end
local function access(s,f,id)
 if not action(s,f) then return nil,"Wait for your turn." end
 local u=s.units[id]
 if not u or u.faction~=f then return nil,"Select one of your units." end
 return u
end
function M.move(s,f,id,dest)
 local u,msg=access(s,f,id)
 if not u then return false,msg end
 local t=s.tiles[dest]
 if not t then return false,"That tile is outside the map." end
 local costs,prev=B.moveRange(s,u)
 if not costs[dest] then
  if s.scenario=="checkpoint1" then
   if u.mp==0 then return false,"This army has already acted this turn." end
   if B.distance(s.tiles[u.tile],t)~=1 then return false,"No road connects these provinces." end
   if t.unit then return false,"The province is occupied. Select an enemy army to attack." end
  end
  return false,"Destination is blocked or out of movement range."
 end
 local route={dest}
 local k=dest
 while prev[k] and prev[k]~=u.tile do k=prev[k];table.insert(route,1,k) end
 local from=u.tile
 s.tiles[from].unit=nil;t.unit=id;u.tile=dest
 u.mp-=costs[dest]
 table.insert(s.events,{kind="move",unit=id,from=from,route=route})
 claim(s,t,f)
 return true,s.scenario=="checkpoint1" and (C.Units[u.kind].name.." marched to "..t.name..".") or ("Moved "..C.Units[u.kind].name..".")
end
function M.damage(s,u,target)
 local def=C.Units[u.kind]
 local td=C.Units[target.kind]
 local t=s.tiles[target.tile]
 local mitigation=td.defense+C.Terrain[t.terrain].def+M.cityDefense(t.city and s.cities[t.city])
 local power=def.attack+(u.kind=="spear" and td.mounted and 4 or 0)
 return math.max(2,power-math.floor(mitigation*.57))
end
local function provinceCombat(s,u,enemy)
 if u.mp<1 or u.attacked then return false,"This army has already acted this turn." end
 local source,dest=s.tiles[u.tile],s.tiles[enemy.tile]
 if B.distance(source,dest)~=1 then return false,"No road connects these armies." end
 if dest.owner~=enemy.faction then return false,"The defending army does not control this province." end
 local damage=math.min(enemy.hp,M.damage(s,u,enemy))
 local routed=enemy.hp<=damage
 local retaliation=math.min(u.hp,math.max(1,math.floor(M.damage(s,enemy,u)*(routed and .35 or .65))))
 enemy.hp-=damage;u.hp-=retaliation;u.mp=0;u.attacked=true
 local attackerRouted=u.hp==0
 local mongolLoss=u.faction=="mongol" and retaliation or damage
 local rusLoss=u.faction=="rus" and retaliation or damage
 local report=string.format("%s: Mongol −%d, Rus −%d. %s",dest.name,mongolLoss,rusLoss,
  routed and (attackerRouted and "Both armies routed." or "Defenders routed. Province captured.") or (attackerRouted and "Attacker routed." or "Defenders hold."))
 local attack={kind="attack",unit=u.id,target=enemy.id,from=source.id,tile=dest.id,damage=damage,retaliation=retaliation,defeated=routed,attackerRouted=attackerRouted,text=report}
 table.insert(s.events,attack)
 if attackerRouted then
  s.units[u.id]=nil;source.unit=nil;s.stats.kills[enemy.faction]+=1
 end
 if routed then
  s.units[enemy.id]=nil;dest.unit=nil;s.stats.kills[u.faction]+=1
  if not attackerRouted then
   source.unit=nil;dest.unit=u.id;u.tile=dest.id
   table.insert(s.events,{kind="move",unit=u.id,from=source.id,route={dest.id}})
   claim(s,dest,u.faction)
  end
 end
 local mongol,rus=false,false
 for _,a in pairs(s.units) do
  if a.faction=="mongol" then mongol=true else rus=true end
 end
 if not mongol then s.result="rus";s.endReason="Mongol armies routed"
 elseif not rus and not s.result then s.result="mongol";s.endReason="Rus armies routed" end
 return true,report
end
function M.attack(s,f,id,targetId)
 local u,msg=access(s,f,id)
 if not u then return false,msg end
 local t=s.units[targetId]
 if not t or t.faction==f then return false,"Choose an enemy unit." end
 if s.scenario=="checkpoint1" then return provinceCombat(s,u,t) end
 if u.attacked then return false,"This unit has already attacked." end
 if B.distance(s.tiles[u.tile],s.tiles[t.tile])>C.Units[u.kind].range then return false,"Enemy is beyond attack range." end
 local damage=M.damage(s,u,t)
 u.attacked=true
 u.mp=math.max(0,u.mp-1)
 t.hp=math.max(0,t.hp-damage)
 local detail=t.hp==0 and " defeated." or " took "..damage.." damage."
 table.insert(s.events,{kind="attack",unit=id,target=targetId,from=u.tile,tile=t.tile,damage=damage,defeated=t.hp==0,text=C.Units[t.kind].name..detail})
 if t.hp==0 then
  s.tiles[t.tile].unit=nil
  s.units[targetId]=nil
  s.stats.kills[f]+=1
 end
 return true,C.Units[t.kind].name..detail
end
function M.afford(s,f,cost)
 for k,v in pairs(cost) do if s.resources[f][k]<v then return false end end
 return true
end
local function pay(s,f,cost)
 for k,v in pairs(cost) do s.resources[f][k]-=v end
end
function M.recruitTile(s,city)
 local t=s.tiles[city.tile]
 if not t.unit then return t end
 for _,v in ipairs(B.neighbors(s,t)) do
  if not v.unit and v.owner==city.owner and C.Terrain[v.terrain].move<99 then return v end
 end
 return nil
end
function M.recruit(s,f,cityId,kind)
 if not action(s,f) then return false,"Wait for your turn." end
 local city,def=s.cities[cityId],C.Units[kind]
 if not city or city.owner~=f or not def then return false,"Select a friendly city and unit." end
 if f=="rus" and def.mounted then return false,"Rus recruits infantry and spearmen in this slice." end
 if city.recruited==s.turn then return false,"This city has already recruited this turn." end
 local count=0
 for _,u in pairs(s.units) do if u.faction==f then count+=1 end end
 if count>=C.MaxUnits then return false,"Army limit reached." end
 local t=M.recruitTile(s,city)
 if not t then return false,"Clear the city or an adjacent friendly tile." end
 if not M.afford(s,f,def.cost) then return false,"Not enough resources." end
 pay(s,f,def.cost)
 local u=spawn(s,f,kind,t,false)
 city.recruited=s.turn
 s.stats.recruits[f]+=1
 table.insert(s.events,{kind="recruit",unit=u.id,tile=t.id,text=C.Units[kind].name.." rallied at "..city.name.."."})
 return true,"Recruited "..def.name..". Ready next turn."
end
function M.build(s,f,cityId,kind)
 if not action(s,f) then return false,"Wait for your turn." end
 local city,def=s.cities[cityId],C.Buildings[kind]
 if not city or city.owner~=f or not def then return false,"Select a friendly city and structure." end
 if city.buildings[kind] then return false,"This structure is already built." end
 if city.built==s.turn then return false,"This city has already built this turn." end
 if not M.afford(s,f,def.cost) then return false,"Not enough resources." end
 pay(s,f,def.cost);city.buildings[kind]=true;city.built=s.turn
 return true,def.name.." constructed at "..city.name.."."
end
function M.begin(s,f)
 s.active=f
 local income=M.income(s,f)
 for k,v in pairs(income) do s.resources[f][k]+=v end
 for _,id in ipairs(s.unitOrder) do
  local u=s.units[id]
  if u and u.faction==f then resetBudget(s,u) end
 end
 return income
end
return M
