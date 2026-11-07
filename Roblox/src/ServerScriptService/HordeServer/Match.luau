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

return M
