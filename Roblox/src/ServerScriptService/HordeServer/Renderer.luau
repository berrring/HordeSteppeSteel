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

return R
