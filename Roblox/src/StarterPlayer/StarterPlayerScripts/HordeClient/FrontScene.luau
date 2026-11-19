
local F={}
local function V(x,y,z) return Vector3.new(x,y,z) end
local function C(s) return Color3.fromHex(s) end
local function part(p,n,size,cf,tint,kind)
 local a=Instance.new(kind=="Wedge" and "WedgePart" or "Part")
 a.Name=n;a.Size=size;a.CFrame=cf;a.Color=tint
 if kind=="Ball" then a.Shape=Enum.PartType.Ball elseif kind=="Cylinder" then a.Shape=Enum.PartType.Cylinder end
 a.Material=Enum.Material.SmoothPlastic;a.TopSurface=Enum.SurfaceType.Smooth;a.BottomSurface=Enum.SurfaceType.Smooth
 a.Anchored=true;a.CanCollide=false;a.CanTouch=false;a.CanQuery=false;a.Parent=p;return a
end
local function oval(p,n,at,sz,col,turn)
 return part(p,n,sz,CFrame.new(at)*(turn or CFrame.identity),col,"Ball")
end
local function link(p,n,a,b,w,wz,col)
 local d=b-a
 local ref=math.abs(d.Unit:Dot(Vector3.xAxis))>.88 and Vector3.zAxis or Vector3.xAxis
 local right=(ref-d.Unit*ref:Dot(d.Unit)).Unit
 return part(p,n,V(w,d.Magnitude,wz),CFrame.fromMatrix((a+b)/2,right,d.Unit),col)
end
local function disk(p,n,at,r,height,col)
 return part(p,n,V(height,r*2,r*2),CFrame.new(at)*CFrame.Angles(0,0,math.pi/2),col,"Cylinder")
end
local function model(world,name,at,rotation,scale,build)
 local m=Instance.new("Model");m.Name=name;m.WorldPivot=CFrame.identity
 build(m)
 m:ScaleTo(scale);m:PivotTo(CFrame.new(at)*CFrame.Angles(0,math.rad(rotation),0));m.Parent=world
end
local function archer(h)
 local fur=C("906041");local shade=C("754C37");local dark=C("2D2A28");local hoof=C("293239")
 local leather=C("51392D");local wool=C("617243");local gold=C("C8A04C");local skin=C("C48F6C")
 oval(h,"Pony barrel",V(0,1.54,0),V(1.20,.96,2.75),fur)
 oval(h,"Chest",V(0,1.62,.83),V(1.13,1.11,1.35),fur)
 oval(h,"Croup",V(0,1.58,-.90),V(1.07,1.10,1.30),shade)
 oval(h,"Neck",V(0,2.05,.99),V(.79,1.50,.81),fur,CFrame.Angles(.43,0,0))
 oval(h,"Head",V(0,2.59,1.53),V(.65,.69,.96),fur,CFrame.Angles(.26,0,0))
 oval(h,"Muzzle",V(0,2.41,1.97),V(.48,.41,.73),shade,CFrame.Angles(.32,0,0))
 oval(h,"Mane",V(.012,2.26,.61),V(.27,1.19,.48),dark,CFrame.Angles(.40,0,0))
 oval(h,"Forelock",V(.01,2.87,1.58),V(.30,.25,.45),dark)
 for _,sg in ipairs({-1,1}) do
  link(h,"Ear",V(sg*.155,2.83,1.41),V(sg*.207,3.13,1.47),.143,.126,shade)
  oval(h,"Eye",V(sg*.294,2.65,1.61),V(.072,.081,.083),dark)
  local upFore=V(sg*.36,1.56,.78)
  local front=sg==1 and 1.10 or .63
  local knee=V(sg*.37,.72,front)
  local fet=V(sg*.37,sg==1 and .19 or .10,front-.08)
  link(h,"Upper foreleg",upFore,knee,.27,.31,fur)
  link(h,"Lower foreleg",knee,fet,.17,.20,fur)
  part(h,"Forehoof",V(.24,.18,.32),CFrame.new(fet+V(0,.015,.03)),hoof)
  local upBack=V(sg*.37,1.46,-.84)
  local hock=V(sg*.414,.63,sg==1 and -1.12 or -1.24)
  local down=V(sg*.414,.10,sg==1 and -.83 or -1.27)
  oval(h,"Haunch",upBack+V(0,-.18,0),V(.51,.83,.69),shade)
  link(h,"Hind leg",upBack,hock,.31,.35,shade)
  link(h,"Hind cannon",hock,down,.18,.2,fur)
  part(h,"Hind hoof",V(.25,.20,.32),CFrame.new(down+V(0,.02,.045)),hoof)
  link(h,"Rein",V(sg*.227,2.43,1.92),V(sg*.37,1.98,.26),.042,.041,leather)
  part(h,"Olive saddle blanket",V(.099,.52,1.25),CFrame.new(sg*.47,1.63,-.14)*CFrame.Angles(0,0,sg*.14),wool)
  part(h,"Bronze blanket hem",V(.102,.054,1.20),CFrame.new(sg*.506,1.41,-.14),gold)
  link(h,"Riding boot",V(sg*.40,2.13,-.08),V(sg*.58,1.46,.04),.24,.30,leather)
 end
 link(h,"Tail root",V(0,1.87,-1.40),V(.13,1.52,-1.70),.23,.25,dark)
 link(h,"Swept tail",V(.13,1.56,-1.64),V(.21,.82,-1.95),.16,.22,dark)
 part(h,"Saddle",V(.94,.24,.74),CFrame.new(0,2.01,-.15),leather)
 oval(h,"Rider torso",V(.015,2.56,-.16),V(.82,.82,.61),wool,CFrame.Angles(-.06,0,-.13))
 for i=0,2 do part(h,"Lamellar band",V(.62-i*.026,.105,.12),CFrame.new(.024,2.63-i*.14,.115)*CFrame.Angles(0,0,-.08),leather) end
 oval(h,"Face",V(.08,3.15,-.07),V(.51,.55,.49),skin)
 disk(h,"Fur cap brim",V(.08,3.31,-.10),.33,.137,leather)
 oval(h,"Felt riding cap",V(.08,3.41,-.11),V(.56,.40,.55),wool)
 oval(h,"Bronze button",V(.08,3.61,-.11),V(.108,.10,.10),gold)
 local hold=V(.89,2.71,.51);local draw=V(.08,2.94,.17)
 link(h,"Bow sleeve",V(.30,2.76,-.04),hold,.19,.205,leather)
 link(h,"Draw sleeve",V(-.31,2.76,-.02),draw,.20,.211,leather)
 oval(h,"Bow hand",hold,V(.166,.163,.169),skin)
 oval(h,"Draw hand",draw,V(.153,.159,.165),skin)
 local points={V(1.16,2.07,.70),V(.97,2.17,.58),V(1.04,2.41,.55),hold,V(1.03,3.08,.53),V(.985,3.32,.53),V(1.22,3.55,.67)}
 for i=1,#points-1 do link(h,"Recurved bow",points[i],points[i+1],.08,.085,(i==1 or i==#points-1) and gold or shade) end
 link(h,"Low bowstring",points[1],draw,.025,.025,C("F0DAB2"))
 link(h,"High bowstring",draw,points[#points],.025,.025,C("F0DAB2"))
 link(h,"Quiver",V(.36,2.11,-.54),V(.48,2.98,-.52),.26,.26,leather)
 for i=1,3 do
  local x=.35+i*.055
  link(h,"Fletched shafts",V(x,2.82,-.50),V(x+.04,3.13+i*.065,-.56),.035,.035,gold)
 end
end
local function ger(world,at,scale)
 model(world,"Felt ger",at,7,scale,function(h)
  local cream=C("DBD6BC");local wood=C("704C38")
  disk(h,"Footing",V(0,.105,0),2.32,.21,C("6A634E"))
  disk(h,"Circular felt wall",V(0,.94,0),2.14,1.66,cream)
  disk(h,"Lower tension belt",V(0,.53,0),2.155,.072,wood)
  disk(h,"Gold eave tie",V(0,1.69,0),2.18,.091,C("A8864C"))
  oval(h,"Tensioned ger roof",V(0,1.71,0),V(4.36,1.72,4.36),C("E8DFC3"))
  disk(h,"Smoke ring",V(0,2.57,0),.34,.13,wood)
  part(h,"Carved wooden door",V(.93,1.22,.17),CFrame.new(0,.71,2.145),wood)
  part(h,"Door lintel",V(1.10,.115,.22),CFrame.new(0,1.36,2.171),C("966A43"))
  link(h,"Banner pole",V(2.3,0,1.1),V(2.3,3.0,1.1),.08,.08,wood)
  part(h,"Hanging standard",V(.73,.65,.045),CFrame.new(2.57,2.57,1.12),C("334B53"))
  part(h,"Bronze emblem",V(.16,.16,.038),CFrame.new(2.57,2.59,1.16)*CFrame.Angles(0,0,.785),C("D0AA58"))
 end)
end
function F.new(parent)
 local v=Instance.new("ViewportFrame")
 v.Name="SteppeDiorama";v.BackgroundTransparency=1;v.BorderSizePixel=0
 v.Ambient=C("A6AEAA");v.LightColor=C("FFE8B5");v.LightDirection=V(-.45,-.83,-.54)
 v.Parent=parent
 local world=Instance.new("WorldModel");world.Name="SteppeForeground";world.Parent=v
 local cam=Instance.new("Camera");cam.FieldOfView=36;cam.Parent=v;v.CurrentCamera=cam
 local turf=C("738058")
 part(world,"Wide steppe ground",V(96,.33,72),CFrame.new(0,-.21,-16),turf)
 part(world,"Road to Sarai",V(3.9,.026,36),CFrame.new(3,-.035,-1)*CFrame.Angles(0,-.55,0),C("A19569"))
 for i,q in ipairs({{-18,-23,14,3,11},{-9,-25,17,4.9,12},{1,-26,17,5.8,14},{12,-27,18,5,13},{21,-22,16,3.4,12}}) do
  local x,z,w,h,d=table.unpack(q)
  part(world,"Distant ridge",V(w,h,d),CFrame.new(x,h*.44-.15,z)*CFrame.Angles(0,math.rad(135+i*22),0),
   ({C("667058"),C("525F54"),C("65735A")})[(i-1)%3+1],"Wedge")
 end
 for i,q in ipairs({{-6,-3,.7},{7,-3,.55},{10,-8,.7},{-9,-11,.65},{9,2.9,.55},{-4,4,.32},{12,5,.58}}) do
  local x,z,s=table.unpack(q)
  part(world,"Weathered stone",V(s*1.7,s*.85,s*1.22),CFrame.new(x,s*.25,z)*CFrame.Angles(0,i*.68,0),C("646B64"),"Wedge")
 end
 for i,q in ipairs({{-6,2},{7,5},{9,-3},{-1,-8},{10,1},{-3,7},{6,-10}}) do
  local x,z=table.unpack(q)
  for j=1,3 do
   local p=V(x+j*.15,.03,z)
   link(world,"Dry steppe stems",p,p+V(j*.10,.22+(i+j)%3*.11,.1),.051,.052,C("A59960"))
  end
 end
 ger(world,V(-1,0,-5.7),1.02)
 model(world,"Horse archer vignette",V(3.0,0,4.6),-37,1.95,archer)
 local function fit(width)
  local tight=width<620
  v.Position=tight and UDim2.fromScale(.11,0) or UDim2.fromScale(.36,0)
  v.Size=tight and UDim2.fromScale(.89,.74) or UDim2.fromScale(.64,1)
  local target=V(1.4,2.55,1.35)
  cam.CFrame=CFrame.lookAt(target+V(tight and 12 or 17,tight and 10.5 or 12,tight and 18 or 23),target)
 end
 return v,fit
end
return F
