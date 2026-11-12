local C=require(game.ReplicatedStorage.HordeShared.Config)
local B=require(game.ReplicatedStorage.HordeShared.Board)
local assets=game.ServerStorage:WaitForChild("HordeAssets")
local Tween=game:GetService("TweenService")
local R={}
R.__index=R
local function folder(p,n)
 local f=Instance.new("Folder");f.Name=n;f.Parent=p;return f
end
local function part(p,n,size,cf,col,kind)
 local b=Instance.new("Part");b.Name=n;b.Size=size;b.CFrame=cf;b.Color=col;b.Material=kind or Enum.Material.SmoothPlastic
 b.TopSurface=Enum.SurfaceType.Smooth;b.BottomSurface=Enum.SurfaceType.Smooth
 b.Anchored=true;b.CanCollide=false;b.CanTouch=false;b.CanQuery=false;b.Parent=p;return b
end
local function clone(p,n,cf,scale)
 local m=p:Clone();m.Name=n;m:ScaleTo(scale);m:PivotTo(cf);return m
end
local function label(p,text,color)
 local a=Instance.new("BillboardGui")
 a.Name="Label";a.AlwaysOnTop=true;a.MaxDistance=125;a.Size=UDim2.fromOffset(128,21);a.StudsOffsetWorldSpace=Vector3.new(0,2.38,0)
 local t=Instance.new("TextLabel");t.BackgroundColor3=C.Palette.ink;t.BackgroundTransparency=.11;t.TextColor3=color
 t.Font=Enum.Font.GothamMedium;t.TextSize=12;t.Size=UDim2.fromScale(1,1);t.Text=text;t.Parent=a
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,5);c.Parent=t
 a.Parent=p
 return a
end
local function rusUnit(kind)
 local m=Instance.new("Model");m.WorldPivot=CFrame.identity
 local tint=C.Factions.rus.color
 local steel=C.Palette.steel:Lerp(C.Palette.snow,.24)
 local function piece(n,x,y,z,v,col,cf)
  return part(m,n,v,cf or CFrame.new(x,y,z),col)
 end
 piece("Rus tunic",0,.98,0,Vector3.new(.72,.78,.47),tint)
 piece("Mail mantle",0,1.31,.02,Vector3.new(.84,.27,.55),steel)
 piece("Face",0,1.56,.028,Vector3.new(.43,.40,.37),Color3.fromHex("B78B6B"))
 local helm=Instance.new("WedgePart")
 helm.Name="Pointed iron helmet";helm.Size=Vector3.new(.49,.35,.44);helm.CFrame=CFrame.new(0,1.86,0)
 helm.Color=steel;helm.Anchored=true;helm.CanCollide=false;helm.CanQuery=false;helm.CanTouch=false;helm.Parent=m
 for _,i in ipairs({-1,1}) do
  piece("Boot",i*.22,.33,.04*i,Vector3.new(.25,.62,.32),C.Palette.wood)
  piece("Sleeve",i*.43,1.06,.18,Vector3.new(.23,.42,.22),steel)
 end
 piece("Crimson wooden shield",-.43,.99,.36,Vector3.new(.58,.79,.12),tint,CFrame.new(-.43,.99,.36)*CFrame.Angles(0,0,.12))
 piece("Shield boss",-.43,1.02,.431,Vector3.new(.12,.12,.055),C.Palette.snow)
 if kind=="spear" then
  piece("Spear",.49,1.35,.27,Vector3.new(.07,2.54,.07),C.Palette.wood,CFrame.new(.49,1.35,.27)*CFrame.Angles(.15,0,-.16))
  piece("Spear leaf",.69,2.60,.44,Vector3.new(.135,.24,.09),C.Palette.snow)
 else
  piece("Axe handle",.49,1.31,.36,Vector3.new(.075,.90,.07),C.Palette.wood,CFrame.new(.49,1.31,.36)*CFrame.Angles(.10,0,-.45))
  piece("Axe head",.65,1.70,.36,Vector3.new(.315,.22,.092),C.Palette.snow)
 end
 return m
end
local function rusCity(capital)
 local m=Instance.new("Model");m.WorldPivot=CFrame.identity
 local tint=C.Factions.rus.color
 local x=capital and 1.12 or .88
 part(m,"Timber hall",Vector3.new(3.10,1.92,2.2)*x,CFrame.new(0,.96*x,0),C.Palette.wood)
 for _,s in ipairs({-1,1}) do
  part(m,"Gabled roof",Vector3.new(3.42,.21,1.61)*x,CFrame.new(0,2.18*x,s*.64*x)*CFrame.Angles(s*.48,0,0),tint)
  part(m,"Timber pier",Vector3.new(.16,1.82,.18)*x,CFrame.new(s*1.29*x,.95*x,1.07*x),Color3.fromHex("886A54"))
 end
 part(m,"Door",Vector3.new(.79,1.28,.16)*x,CFrame.new(0,.64*x,1.11*x),C.Palette.steel)
 if capital then
  part(m,"Watch turret",Vector3.new(.72,1.05,.72),CFrame.new(.8,2.44,0),C.Palette.wood)
  part(m,"Turret roof",Vector3.new(.91,.20,.91),CFrame.new(.8,2.98,0),tint)
 end
 return m
end
local axes={{1,0},{.5,math.sqrt(3)/2},{-.5,math.sqrt(3)/2},{-1,0},{-.5,-math.sqrt(3)/2},{.5,-math.sqrt(3)/2}}
function R.new()
 return setmetatable({tiles={},units={},cities={},bands={},stamp={},motion={}},R)
end
function R:reset(s)
 if self.world then self.world:Destroy() end
 self.tiles={};self.units={};self.cities={};self.bands={};self.stamp={};self.motion={}
 local root=Instance.new("Model");root.Name="HordeWorld"
 root.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 root:SetAttribute("MapSize",s.size);root:SetAttribute("Seed",s.seed)
 self.world=root
 self.tileRoot=folder(root,"Tiles")
 self.borderRoot=folder(root,"Borders")
 self.unitRoot=folder(root,"Armies")
 self.cityRoot=folder(root,"Settlements")
 local props=folder(root,"Terrain Props")
 local N=s.size
 local extent=(N-1)*math.sqrt(3)*C.HexRadius
 local depth=(N-1)*1.5*C.HexRadius
 part(root,"Carved steppe map base",Vector3.new(extent+15,.75,depth+12),CFrame.new(C.FieldOrigin+Vector3.new(extent/2+2,-.46,depth/2)),C.Palette.steel,Enum.Material.Slate)
 for _,id in ipairs(s.order) do
  local t=s.tiles[id]
  local a=C.Terrain[t.terrain];local p=B.position(t.q,t.r)
  local slabSize=Vector3.new(C.HexRadius*math.sqrt(3)*.978,a.height+.14,C.HexRadius*.978)
  local pose=CFrame.new(p+Vector3.new(0,(a.height-.14)/2,0))
  local material=(t.terrain=="Water" or t.terrain=="Ford") and Enum.Material.SmoothPlastic or Enum.Material.Plastic
  local tile=part(self.tileRoot,id,slabSize,pose,a.color,material)
  for i=1,2 do
   local wing=part(tile,"Hex wing "..i,slabSize,pose*CFrame.Angles(0,i*math.pi/3,0)+Vector3.new(0,i*.003,0),a.color,material)
   wing:SetAttribute("TileId",id);wing.CanQuery=true
  end
  tile.CanCollide=false;tile.CanQuery=true;tile.CanTouch=false
  tile:SetAttribute("TileId",id);tile:SetAttribute("Q",t.q);tile:SetAttribute("R",t.r);tile:SetAttribute("Terrain",t.terrain)
  tile:SetAttribute("Traversable",a.move<99);tile:SetAttribute("MoveCost",a.move)
  tile:SetAttribute("Resource",a.resource)
  tile.Parent=self.tileRoot;self.tiles[id]=tile
  local idx=(t.q*113+t.r*73+s.seed)%7
  local name,scale
  if not t.city then
   if t.terrain=="Forest" and idx<5 then name=idx%2==0 and "Steppe_Tree_Pine" or "Steppe_Tree_Broadleaf";scale=.34
   elseif t.terrain=="Mountains" then name="Steppe_Rock";scale=.64
   elseif t.terrain=="Hills" and idx<3 then name="Steppe_Rock";scale=.31 end
  end
  if name then
   local pos=p+Vector3.new(idx%3-1,a.height,-.9)
   clone(assets.Environment[name],id.." Decor",CFrame.new(pos)*CFrame.Angles(0,idx*.57,0),scale).Parent=props
  end
 end
 root.Parent=workspace
end
function R:surface(t)
 return B.position(t.q,t.r)+Vector3.new(0,C.Terrain[t.terrain].height,0)
end
function R:unitPose(s,u,tileId)
 local t=s.tiles[tileId]
 local offset=t.city and Vector3.new(1.26,0,1.52) or Vector3.zero
 return CFrame.new(self:surface(t)+offset)*CFrame.Angles(0,u.faction=="mongol" and math.pi/2 or -math.pi/2,0)
end
function R:animate(m,u,s,route,strike)
 local key=u.id
 local version=(self.motion[key] or 0)+1
 self.motion[key]=version
 local motion=self.motion
 task.spawn(function()
  local function tweenTo(target,duration)
   if motion[key]~=version or not m.Parent then return false end
   local cf=Instance.new("CFrameValue");cf.Value=m:GetPivot()
   local conn=cf.Changed:Connect(function(value)
    if m.Parent and motion[key]==version then m:PivotTo(value) end
   end)
   local tween=Tween:Create(cf,TweenInfo.new(duration,Enum.EasingStyle.Sine),{Value=target})
   tween:Play();tween.Completed:Wait()
   conn:Disconnect();cf:Destroy()
   return motion[key]==version and m.Parent~=nil
  end
  for _,dest in ipairs(route or {}) do
   if not tweenTo(self:unitPose(s,u,dest),.11) then return end
  end
  if strike and strike.from==u.tile and s.tiles[strike.tile] then
   local home=self:unitPose(s,u,u.tile)
   local target=self:surface(s.tiles[strike.tile])
   local offset=target-home.Position;offset=Vector3.new(offset.X,0,offset.Z)
   if offset.Magnitude>.01 and tweenTo(home+offset.Unit*(u.kind=="archer" and .21 or .66),.12) then
    tweenTo(home,.14)
   end
  end
 end)
end
function R:ownerOverlay(s,t)
 local owner=t.owner
 local p=self:surface(t);local draw={};local pattern=owner
 if owner~="neutral" then
  local adjacent=B.neighbors(s,t)
  for i,axis in ipairs(axes) do
   local axisV=Vector3.new(axis[1],0,axis[2])
   local adjacentOwner="edge"
   for _,n in ipairs(adjacent) do
    local offset=B.position(n.q,n.r)-B.position(t.q,t.r)
    if offset.Unit:Dot(axisV)>.998 then adjacentOwner=n.owner;break end
   end
   if adjacentOwner~=owner then draw[i]=axisV;pattern..=tostring(i) end
  end
 end
 if pattern==self.stamp[t.id] then return end
 self.stamp[t.id]=pattern
 if self.bands[t.id] then self.bands[t.id]:Destroy();self.bands[t.id]=nil end
 if owner=="neutral" then return end
 local tint=C.Factions[owner].color
 local f=folder(self.borderRoot,t.id);self.bands[t.id]=f
 for _,v in pairs(draw) do
  local mid=p+v*C.HexRadius*.822+Vector3.new(0,.039,0)
  local segment=part(f,"Border",Vector3.new(C.HexRadius*.94,.055,.125),CFrame.lookAt(mid,mid+v),tint)
  segment.CastShadow=false
 end
end
function R:update(s)
 local routes,strikes={},{}
 for _,event in ipairs(s.events) do
  if event.kind=="move" then
   local route=routes[event.unit] or {}
   for _,id in ipairs(event.route) do table.insert(route,id) end
   routes[event.unit]=route
  elseif event.kind=="attack" then strikes[event.unit]=event end
 end
 for _,id in ipairs(s.order) do
  local t=s.tiles[id];local part=self.tiles[id]
  part:SetAttribute("Owner",t.owner);part:SetAttribute("City",t.city);part:SetAttribute("Unit",t.unit)
  self:ownerOverlay(s,t)
 end
 for id,m in pairs(self.units) do
  if not s.units[id] then m:Destroy();self.units[id]=nil;self.motion[id]=nil end
 end
 for _,id in ipairs(s.unitOrder) do
  local u=s.units[id]
  if u then
   local m=self.units[id]
   if not m then
    local cf=self:unitPose(s,u,u.tile)
    if u.faction=="mongol" then m=clone(assets.Units[C.Units[u.kind].asset],id,cf,C.AssetScale) else m=rusUnit(u.kind);m:PivotTo(cf) end
    m.Name=id;m.Parent=self.unitRoot;self.units[id]=m
    local anchor=m:FindFirstChildWhichIsA("BasePart",true)
    local gui=label(anchor,C.Units[u.kind].name,C.Palette.snow)
    gui.Name="Health";gui.StudsOffsetWorldSpace=Vector3.new(0,u.faction=="mongol" and 2.45 or 1.23,0);gui.Size=UDim2.fromOffset(69,17)
    local hp=gui:FindFirstChildWhichIsA("TextLabel")
    hp.Name="HP";hp.TextSize=10
    local bar=Instance.new("Frame");bar.Name="Bar";bar.BorderSizePixel=0;bar.BackgroundColor3=C.Factions[u.faction].color
    bar.Size=UDim2.fromScale(1,.16);bar.Position=UDim2.fromScale(0,.84);bar.Parent=hp
   elseif routes[id] or strikes[id] then self:animate(m,u,s,routes[id],strikes[id]) end
   m:SetAttribute("TileId",u.tile);m:SetAttribute("Faction",u.faction)
   m:SetAttribute("HP",u.hp);m:SetAttribute("MaxHP",u.maxHp);m:SetAttribute("Kind",u.kind)
   local hp=m:FindFirstChild("Health",true).HP;hp.Text=u.hp.." / "..u.maxHp
   hp.Bar.Size=UDim2.fromScale(u.hp/u.maxHp,.16)
  end
 end
 for _,id in ipairs(s.cityOrder) do
  local c=s.cities[id];local t=s.tiles[c.tile]
  local mark=c.owner..tostring(c.buildings.fortress)..tostring(c.buildings.farm)..tostring(c.buildings.lumber)
  if not self.cities[id] or self.cities[id].mark~=mark then
   if self.cities[id] then self.cities[id].model:Destroy() end
   local base=CFrame.new(self:surface(t)+Vector3.new(-.71,0,-.71))
   local city
   if c.owner=="rus" and not c.buildings.fortress then city=rusCity(c.capital);city:PivotTo(base)
   else
    local name=c.buildings.fortress and "Mongol_Fortress" or c.capital and "Mongol_CapitalYurt" or "Mongol_Yurt"
    city=clone(assets.Buildings[name],id,base,c.buildings.fortress and .44 or .64)
    if c.owner=="rus" then
     for _,p in ipairs(city:GetDescendants()) do
      if p:IsA("BasePart") and (p.Name:find("roof") or p.Name:find("Banner")) then p.Color=C.Factions.rus.color:Lerp(C.Palette.steel,.3) end
     end
    end
   end
   city.Name=id;city.Parent=self.cityRoot
   local flagParent=part(city,"City marker",Vector3.new(.2,.2,.2),base+Vector3.new(0,2.92,0),C.Palette.steel)
   flagParent.Transparency=1
   label(flagParent,c.name,c.owner=="neutral" and C.Palette.snow or C.Factions[c.owner].color).StudsOffsetWorldSpace=Vector3.new(0,.10,0)
   if c.buildings.farm then
    for i=1,3 do part(city,"Crop row",Vector3.new(.26,.13,1.35),base*CFrame.new(-1.50+i*.30,.065,2.6),C.Palette.steppe,Enum.Material.Ground) end
   end
   if c.buildings.lumber then
    for i=1,3 do part(city,"Cut timber",Vector3.new(.18,.18,1.30),base*CFrame.new(2.5+i*.21,.1,-1.1),C.Palette.wood,Enum.Material.Wood) end
   end
   self.cities[id]={model=city,mark=mark}
  end
 end
end
return R
