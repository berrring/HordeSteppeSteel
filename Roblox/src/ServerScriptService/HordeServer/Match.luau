local C=require(game.ReplicatedStorage.HordeShared.Config)
local B=require(game.ReplicatedStorage.HordeShared.Board)
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
local function resetBudget(u)
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
 if ready then resetBudget(u) end
 s.units[id]=u;table.insert(s.unitOrder,id);t.unit=id
 return u
end
function M.new(n,seed)
 local s=B.generate(n,seed)
 s.turn=1;s.active="mongol";s.serial=0;s.units={};s.unitOrder={};s.events={}
 s.resources={mongol=copy(C.Start),rus=copy(C.Start)}
 s.stats={kills={mongol=0,rus=0},captures={mongol=0,rus=0},recruits={mongol=0,rus=0}}
 local mid=math.floor(n/2)

return M
