local C=require(game.ReplicatedStorage.HordeShared.Config)
local B={}
function B.key(q,r) return q..":"..r end
function B.position(q,r)
 return C.FieldOrigin+Vector3.new((q+(r%2)*.5)*math.sqrt(3)*C.HexRadius,0,r*1.5*C.HexRadius)
end
local function axial(q,r) return q-math.floor(r/2),r end
function B.distance(a,b)
 local aq,ar=axial(a.q,a.r)
 local bq,br=axial(b.q,b.r)
 local q,r=aq-bq,ar-br
 return math.max(math.abs(q),math.abs(r),math.abs(q+r))
end
function B.neighbors(s,t)
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

return B
