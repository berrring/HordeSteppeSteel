local C=require(game.ReplicatedStorage.HordeShared.Config)
local B={}
function B.key(q,r) return q..":"..r end
function B.position(q,r)
 return C.FieldOrigin+Vector3.new((q+(r%2)*.5)*math.sqrt(3)*C.HexRadius,0,r*1.5*C.HexRadius)
end
function B.center(t)
 if t.x~=nil then return C.FieldOrigin+Vector3.new((t.x+4)*5.25,0,(t.z+8)*5.9) end
 return B.position(t.q,t.r)
end
local function axial(q,r) return q-math.floor(r/2),r end
function B.distance(a,b)
 if a.adjacent then
  if a.id==b.id then return 0 end
  return table.find(a.adjacent,b.id) and 1 or math.huge
 end
 local aq,ar=axial(a.q,a.r)
 local bq,br=axial(b.q,b.r)
 local q,r=aq-bq,ar-br
 return math.max(math.abs(q),math.abs(r),math.abs(q+r))
end
function B.neighbors(s,t)
 if t.adjacent then
  local out={}
  for _,id in ipairs(t.adjacent) do table.insert(out,s.tiles[id]) end
  return out
 end
 local q,r=axial(t.q,t.r)
 local list={}
 for _,d in ipairs({{1,0},{1,-1},{0,-1},{-1,0},{-1,1},{0,1}}) do
  local ar=r+d[2]
  local b=s.tiles[B.key(q+d[1]+math.floor(ar/2),ar)]
  if b then table.insert(list,b) end
 end
 return list
end
function B.moveRange(s,unit)
 if s.scenario=="checkpoint1" then
  local best,prev={},{}
  if unit.mp>0 then
   for _,t in ipairs(B.neighbors(s,s.tiles[unit.tile])) do if not t.unit then best[t.id]=1;prev[t.id]=unit.tile end end
  end
  return best,prev
 end
 local best={[unit.tile]=0}
 local previous={}
 local open={{id=unit.tile,cost=0}}
 while #open>0 do
  local p=table.remove(open,1)
  if p.cost==best[p.id] then
   for _,t in ipairs(B.neighbors(s,s.tiles[p.id])) do
    local cost=C.Terrain[t.terrain].move+p.cost
    if cost<=unit.mp and not t.unit and (not best[t.id] or cost<best[t.id]) then
     best[t.id]=cost;previous[t.id]=p.id
     table.insert(open,{id=t.id,cost=cost})
    end
   end
  end
 end
 best[unit.tile]=nil
 return best,previous
end
function B.generate(n,seed)
 assert(C.Sizes[n],"Unsupported map size")
 local rng=Random.new(seed)
 local s={size=n,seed=seed,tiles={},order={},cities={},cityOrder={}}
 local mid=math.floor(n/2)
 local function terrain(q,r)
  local x=rng:NextNumber()
  local river=mid+math.floor(math.sin(r*.57)*1.55)
  if q==river then
   if r==mid or r==2 or r==n-3 then return "Ford" end
   return "Water"
  end
  if r==mid or r==2 or r==n-3 then
   return x<.52 and "Plains" or "Steppe"
  end
  if x<.075 and (r<mid-2 or r>mid+2) then return "Mountains" end
  if x<.25+(q>mid and .15 or 0) then return "Forest" end
  if x<.48 then return "Hills" end
  if x<.64 then return "Plains" end
  return "Steppe"
 end
 for r=0,n-1 do
  for q=0,n-1 do
   local id=B.key(q,r)
   local t={id=id,q=q,r=r,terrain=terrain(q,r),owner="neutral"}
   s.tiles[id]=t;table.insert(s.order,id)
  end
 end
 local function city(q,r,id,name,owner,capital)
  local t=s.tiles[B.key(q,r)]
  t.terrain=owner=="rus" and "Plains" or "Steppe";t.city=id
  s.cities[id]={id=id,name=name,tile=t.id,owner=owner,capital=capital,buildings={}}
  table.insert(s.cityOrder,id)
 end
 city(1,mid,"sarai","Sarai","mongol",true)
 city(n-2,mid,"novgorod","Novgorod","rus",true)
 city(mid+1,mid,"sarkel","Sarkel","neutral",false)
 city(mid-2,n-3,"crossroads","Silk Road Ford","neutral",false)
 return s
end
return B
