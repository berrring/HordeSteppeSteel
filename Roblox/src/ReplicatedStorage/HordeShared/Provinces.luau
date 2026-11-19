-- Province identities, positions and roads adapted from the archived Godot full campaign.
-- Only Mongol and Rus play in Checkpoint 1. Other provinces begin neutral.
local P={}
local provinces={
 {"sarai","Sarai",0,0,"Steppe","mongol",3,2,1,true},
 {"kipchak","Kipchak Steppe",-3,-3,"Steppe","mongol",1,2,0,false},
 {"novgorod","Novgorod",-4,-8,"Forest","rus",3,1,3,true},
 {"moscow","Moscow",-1,-6,"Forest","rus",2,1,2,false},
 {"kiev","Kiev",-3,-5,"Plains","rus",2,2,1,false},
 {"tabriz","Tabriz",-2,6,"Hills","neutral",2,1,1,false},
 {"samarkand","Samarkand",2,3,"Plains","neutral",3,2,1,false},
 {"bukhara","Bukhara",-1,4.5,"Steppe","neutral",2,2,1,false},
 {"karakorum","Karakorum",6,-3,"Hills","neutral",2,1,1,false},
 {"zhongdu","Zhongdu",8,-1,"Plains","neutral",3,2,1,false},
 {"shangdu","Shangdu",7,-5,"Forest","neutral",2,1,2,false},
 {"urgench","Urgench",3,1,"Plains","mongol",2,2,1,false},
}
local roads={
 {"sarai","kipchak"},{"sarai","urgench"},{"sarai","kiev"},{"sarai","samarkand"},
 {"kipchak","kiev"},{"kipchak","moscow"},{"kipchak","urgench"},{"kiev","moscow"},
 {"moscow","novgorod"},{"urgench","samarkand"},{"urgench","karakorum"},
 {"samarkand","bukhara"},{"samarkand","karakorum"},{"bukhara","tabriz"},
 {"tabriz","samarkand"},{"karakorum","zhongdu"},{"karakorum","shangdu"},{"zhongdu","shangdu"},
}
function P.new()
 local s={scenario="checkpoint1",size=#provinces,tiles={},order={},cities={},cityOrder={},roads={}}
 for _,spec in ipairs(provinces) do
  local id,name,x,z,terrain,owner,gold,food,wood,capital=table.unpack(spec)
  s.tiles[id]={id=id,name=name,x=x,z=z,terrain=terrain,owner=owner,adjacent={},yield={gold=gold,food=food,wood=wood}}
  table.insert(s.order,id)
  if capital or id=="kiev" or id=="moscow" or id=="samarkand" or id=="zhongdu" then
   s.tiles[id].city=id
   s.cities[id]={id=id,name=name,tile=id,owner=owner,capital=capital,buildings={}}
   table.insert(s.cityOrder,id)
  end
 end
 for _,road in ipairs(roads) do
  local a,b=table.unpack(road)
  table.insert(s.tiles[a].adjacent,b)
  table.insert(s.tiles[b].adjacent,a)
  table.insert(s.roads,{a,b})
 end
 return s
end
return P
