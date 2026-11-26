local C = require(game.ReplicatedStorage.HordeShared.Config)

local Art = {}
local V = Vector3.new
local P = C.Palette
local library = game.ServerStorage:WaitForChild("HordeAssets")
local cache = {}

local function piece(parent, name, size, pose, color, material, shape)
 local p = Instance.new("Part")
 p.Name, p.Size, p.CFrame, p.Color = name, size, pose, color
 p.Material = material or Enum.Material.SmoothPlastic
 p.Shape = shape or Enum.PartType.Block
 p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
 p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
 p.Parent = parent
 return p
end

local function rod(parent, name, a, b, width, color, material)
 local d = b - a
 return piece(parent, name, V(d.Magnitude, width, width),
  CFrame.lookAt((a+b)/2, b) * CFrame.Angles(0, math.pi/2, 0), color, material, Enum.PartType.Cylinder)
end

local function disc(parent, name, point, diameter, height, color, material)
 return piece(parent, name, V(height, diameter, diameter),
  CFrame.new(point) * CFrame.Angles(0, 0, math.pi/2), color, material, Enum.PartType.Cylinder)
end

local function portable(asset)
 if cache[asset] then return cache[asset] end
 local model = asset:Clone()
 local pivot = model:GetPivot()
 model.PrimaryPart = nil
 model.WorldPivot = pivot
 for _, object in ipairs(model:GetDescendants()) do
  if object:IsA("MeshPart") and object.MeshContent.SourceType == Enum.ContentSourceType.Opaque then
   local n = object.Name:lower()
   local size, cf, color, material = object.Size, object.CFrame, object.Color, object.Material
   local parent = object.Parent
   if n:find("tier") then
    local side = math.max(size.X, size.Z)
    for step = 1, 3 do
     disc(parent, object.Name, cf.Position + V(0, (step-2)*size.Y/3, 0),
      side*(1.12-step*.20), size.Y/3+.02, color, material)
    end
   elseif n:find("felt roof") or n:find("courtyard command ger") then
    for step = 1, 4 do
     disc(parent, object.Name, cf.Position + V(0, (step-2.5)*size.Y/4, 0),
      size.X*(1.09-step*.13), size.Y/4+.025, color, material)
    end
   elseif n:find("palisade") then
    for _, side in ipairs({-1,1}) do
     piece(parent, "Timber palisade", V(size.X,size.Y,.24), cf*CFrame.new(0,0,side*(size.Z/2-.12)), color, Enum.Material.Wood)
     piece(parent, "Timber palisade", V(.24,size.Y,size.Z), cf*CFrame.new(side*(size.X/2-.12),0,0), color, Enum.Material.Wood)
    end
   elseif n:find("post roof") or n:find("gate roof") then
    for step = 1,3 do
     piece(parent, object.Name, V(size.X*(1.15-step*.19),size.Y/3+.02,size.Z*(1.15-step*.19)),
      cf*CFrame.new(0,(step-2)*size.Y/3,0), color, material)
    end
   elseif n:find("felt wall") or n:find("tension strap") or n:find("binding") or n:find("footing")
     or n:find("smoke vent") or n:find("roof crown") or n:find("socket") and n:find("stone") then
    disc(parent, object.Name, cf.Position, size.X, size.Y, color, material)
   elseif n:find("shield") then
    piece(parent, object.Name, V(math.min(size.X,size.Z),size.Y,math.max(size.X,size.Z)),
     cf, color, material, Enum.PartType.Ball)
   elseif n:find("stone") and not n:find("turf") then
    piece(parent, object.Name, size*.86, cf*CFrame.Angles(.18,.4,.21), color, material, Enum.PartType.Ball)
   elseif n:find("fur brim") or n:find("felt cone") or n:find("felt crown") then
    disc(parent, object.Name, cf.Position, math.max(size.X,size.Z)*.90, size.Y, color, material)
   elseif n:find("barrel") or n:find("cheek") or n:find("neck") or n:find("face") or n:find("muzzle") or n:find("canopy") then
    piece(parent, object.Name, size, cf, color, material, Enum.PartType.Ball)
   elseif n:find("leg") and not n:find("grounded stance") or n:find("spear shaft") or n:find("pike shaft") or n:find("lance shaft") then
    local length = math.max(size.Y,size.Z)
    local offset = size.Y >= size.Z and cf.UpVector or cf.LookVector
    rod(parent, object.Name, cf.Position-offset*length*.47,cf.Position+offset*length*.47,
     math.clamp(size.X,.07,.35),color,material)
   elseif n:find("composite bow") then
    local points = {V(-.33,.56,0),V(.05,.41,0),V(.25,0,0),V(.02,-.40,0),V(-.32,-.56,0)}
    for i=1,#points-1 do
     rod(parent,"Recurve limb",cf*points[i],cf*points[i+1],.09,color,material)
    end
    rod(parent,"Bow string",cf*points[1],cf*points[#points],.022,P.snow)
   elseif not (n:find("bowstring") or n:find("eyes") or n:find("moustache") or n:find("reins")
     or n:find("hooves") or n:find("grounded flat sole") or n:find("grouped grass")) then
    piece(parent, object.Name, size, cf, color, material)
   end
   object:Destroy()
  elseif object:IsA("BasePart") then
   object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
  elseif object:IsA("LayerCollector") or object:IsA("LuaSourceContainer") then
   object:Destroy()
  end
 end
 model:SetAttribute("SourceAsset", asset.Name)
 cache[asset] = model
 return model
end

function Art.place(group, name, pose, scale)
 local asset = library[group][name]
 local model = portable(asset):Clone()
 model:ScaleTo(scale)
 model:PivotTo(pose)
 return model
end

function Art.rusSettlement(capital)
 local m = Instance.new("Model")
 m.WorldPivot = CFrame.identity
 local timber = Color3.fromHex("755440")
 local roof = P.steel:Lerp(C.Factions.rus.color,.34)
 local function house(x,z,w,d,h)
  piece(m,"Stone foundation",V(w+.13,.24,d+.13),CFrame.new(x,.12,z),Color3.fromHex("898579"),Enum.Material.Slate)
  piece(m,"Log walls",V(w,h,d),CFrame.new(x,h/2+.15,z),timber,Enum.Material.Wood)
  for _, sign in ipairs({-1,1}) do
   piece(m,"Shingle roof",V(w+.27,.14,d*.59),CFrame.new(x,h+.39,z+sign*d*.24)*CFrame.Angles(sign*.50,0,0),roof,Enum.Material.Wood)
  end
  for level=1,3 do
   rod(m,"Log end course",V(x-w*.54,level*h/4+.18,z+d*.51),V(x+w*.54,level*h/4+.18,z+d*.51),.13,P.wood,Enum.Material.Wood)
  end
  piece(m,"Recessed door",V(.46,h*.63,.08),CFrame.new(x,h*.31+.20,z+d*.56),P.ink)
 end
 house(0,0,2.05,1.58,1.35)
 if capital then
  house(-1.22,-.72,.95,.91,1.65)
  house(1.08,-.67,.72,.76,1)
  rod(m,"Standard",V(1.28,0,.57),V(1.28,2.34,.57),.075,P.wood)
  piece(m,"Crimson pennant",V(.40,.43,.045),CFrame.new(1.44,1.99,.57),C.Factions.rus.color,Enum.Material.Fabric)
 end
 m:SetAttribute("SourceAsset","Rus timber hall")
 return m
end

return Art
