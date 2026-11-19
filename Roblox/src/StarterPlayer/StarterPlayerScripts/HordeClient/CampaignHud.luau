
local C=require(game.ReplicatedStorage.HordeShared.Config)
local B=require(game.ReplicatedStorage.HordeShared.Board)
local S=require(script.Parent.UISkin)
local H={}
local P=S.C
local function line(p,n,y)
 local l=S.block(p,n,UDim2.new(1,0,0,1),UDim2.fromOffset(0,y),P.line)
 l.BackgroundTransparency=.48
end
local function copy(p,n,value,h,y,sz,col)
 return S.text(p,n,value,UDim2.new(1,0,0,h),UDim2.fromOffset(0,y),{size=sz or 13,color=col or P.muted,wrap=true})
end
local function action(p,n,caption,h,y,cb,opts)
 return S.button(p,n,caption,UDim2.new(1,-1,0,h),UDim2.fromOffset(0,y),cb,opts)
end
local function provinceDetails(p,ctx,t)
 local city=t.city and ctx.state.cities[t.city]
 local q=t.yield
 copy(p,"Terrain",t.terrain.."  ·  "..#t.adjacent.." connected roads",23,0,13,P.white)
 copy(p,"YieldTitle","YIELD PER TURN",21,29,11,P.brass)
 copy(p,"Yield",string.format("%d gold  ·  %d food  ·  %d wood",q.gold,q.food,q.wood),25,50,13,P.white)
 line(p,"ProvinceRule",83)
 local army=t.unit and ctx.state.units[t.unit]
 copy(p,"Garrison","Army  ·  "..(army and C.Units[army.kind].name or "Open"),23,90,13)
 if city and city.capital then copy(p,"Capital","Capital stronghold",23,115,12,P.brass) end
 if army then action(p,"SelectArmy","Inspect army",32,146,function() ctx.inspectUnit(army.id) end,{primary=army.faction=="mongol",size=12})
 else copy(p,"CaptureHint","March here from a connected province to take control.",42,128,12) end
end
local function unitDetails(p,ctx,u,t)
 local def=C.Units[u.kind]
 local hp=S.block(p,"HealthTrack",UDim2.new(1,0,0,6),UDim2.fromOffset(0,27),P.raised);S.corner(hp,3)
 local fill=S.block(hp,"Remaining",UDim2.fromScale(u.hp/u.maxHp,1),nil,u.faction=="mongol" and P.green or P.red);S.corner(fill,3)
 copy(p,"Health","Strength  "..u.hp.." / "..u.maxHp,23,0,13,P.white)
 copy(p,"Combat","Attack  "..def.attack.."   ·   Defense  "..def.defense,23,41,13)
 copy(p,"Province",t.name,23,65,13,P.white)
 copy(p,"Budget",u.faction=="mongol" and (u.mp>0 and "One order available" or "Order used this turn") or "Enemy army",23,92,12,u.mp>0 and P.green or P.muted)
 if ctx.prefs.hints then copy(p,"UnitHint",u.faction=="mongol" and "Teal: march. Red: attack." or "Select your army before attacking.",28,116,12) end
 action(p,"ProvinceDetails","Inspect province",29,147,function() ctx.inspectProvince(t.id) end,{size=12})
end
function H.render(root,ctx)
 local s=ctx.state
 local sz=root.AbsoluteSize
 local narrow=sz.X<635
 local tiny=sz.X<435
 local m=narrow and 9 or 14
 local topH=narrow and 78 or 51
 local top=S.card(root,"HordeHUD",UDim2.new(1,-2*m,0,topH),UDim2.fromOffset(m,7),P.ink);top.Active=true
 local status="Turn "..s.turn.."  ·  "..(ctx.busyTurn and "Rus turn" or "Your turn")
 local owned=0
 for _,t in pairs(s.tiles) do if t.owner=="mongol" then owned+=1 end end
 S.text(top,"Faction","Mongol Khanate",UDim2.fromOffset(tiny and 143 or 168,24),UDim2.fromOffset(11,4),
  {size=tiny and 15 or 17,font=S.Display,color=P.pale})
 S.text(top,"Territory",status,UDim2.fromOffset(154,17),UDim2.fromOffset(11,26),{size=11,color=ctx.busyTurn and P.brass or P.muted})
 if not tiny then
  local holdingsX=narrow and .56 or .22
  if not narrow and sz.X<780 then holdingsX=.25 end
  S.text(top,"Holdings",owned.." holdings",UDim2.new(.16,0,0,19),UDim2.new(holdingsX,0,0,narrow and 16 or 16),{size=11,color=P.dim,truncate=true})
 end
 local menuW=tiny and 58 or 72
 S.button(top,"Menu","Menu",UDim2.fromOffset(menuW,31),UDim2.new(1,-(menuW+9),0,8),function() ctx.navigate("pause") end,{enabled=not ctx.busy,size=13})
 local resLeft=narrow and 10 or math.clamp(sz.X*.36,202,329)
 local resRight=narrow and 10 or menuW+24
 local across=S.block(top,"Resources",UDim2.new(1,-(resLeft+resRight),0,narrow and 29 or 37),UDim2.fromOffset(resLeft,narrow and 45 or 7),P.ink)
 across.BackgroundTransparency=1
 for i,k in ipairs(C.ResourceOrder) do
  local value=s.resources.mongol[k]
  local label=string.upper(string.sub(k,1,1))..string.sub(k,2)
  local holder=S.block(across,label,UDim2.new(1/3,-4,1,0),UDim2.fromScale((i-1)/3,0),P.panel);S.corner(holder,5)
  local income=ctx.income and ctx.income[k]
  local caption=string.format("%s  %d%s",label,value,(income and not tiny) and ("  +"..income) or "")
  S.text(holder,"Value",caption,UDim2.new(1,-5,1,0),UDim2.fromOffset(5,0),{size=tiny and 10 or 12,font=S.Medium,color=k=="gold" and P.pale or P.white,truncate=true})
 end
 local panelW=math.clamp(math.floor(sz.X*.34),208,278)
 if tiny then panelW=math.clamp(math.floor(sz.X*.53),150,200) end
 local dockH=narrow and 45 or 48
 local dock=S.card(root,"OrderDock",UDim2.fromOffset(panelW,dockH),UDim2.new(1,-m,1,-m),P.ink)
 dock.AnchorPoint=Vector2.new(1,1);dock.Active=true
 local focusW=tiny and 52 or 65
 S.button(dock,"Focus",tiny and "Focus" or "Focus [F]",UDim2.new(0,focusW,1,-10),UDim2.fromOffset(5,5),ctx.focus,
  {enabled=ctx.tile~=nil and not ctx.busy,size=11})
 S.button(dock,"EndTurn",ctx.busyTurn and "Rus turn…" or "End Turn",UDim2.new(1,-(focusW+16),1,-10),UDim2.fromOffset(focusW+11,5),ctx.endTurn,
  {primary=true,enabled=not ctx.busy,size=14})
 if not ctx.inspector then
  local reveal=S.button(root,"OpenInspector","Open inspector",UDim2.fromOffset(tiny and 121 or 137,34),UDim2.new(1,-m,0,topH+17),ctx.reopen,{size=12})
  reveal.AnchorPoint=Vector2.new(1,0)
 end
 local info
 if ctx.inspector then
  local t=ctx.tile and s.tiles[ctx.tile]
  local u=ctx.unit and s.units[ctx.unit]
  local city=t and t.city and s.cities[t.city]
  local y=topH+17
  local h=math.max(112,math.min(t and 250 or 170,sz.Y-y-dockH-2*m-11))
  local f=S.card(root,"CampaignInspector",UDim2.fromOffset(panelW,h),UDim2.new(1,-m,0,y),P.panel)
  f.AnchorPoint=Vector2.new(1,0);f.Active=true
  local owner=u and u.faction or t and t.owner
  local label=u and C.Units[u.kind].name or t and t.name or "Eastern Frontier"
  local kind=u and "ARMY" or city and city.capital and "CAPITAL" or t and "PROVINCE" or "MISSION"
  local caption=kind..(owner and ("  /  "..(owner=="neutral" and "Neutral" or C.Factions[owner].name)) or "")
  local mark=S.block(f,"FactionStripe",UDim2.fromOffset(2,30),UDim2.fromOffset(8,10),owner and C.Factions[owner] and C.Factions[owner].color or P.brass)
  mark.BackgroundTransparency=.16
  S.text(f,"Title",label,UDim2.new(1,-52,0,28),UDim2.fromOffset(14,5),{size=tiny and 19 or 22,font=S.Display,color=P.white,truncate=true})
  S.text(f,"Type",caption,UDim2.new(1,-52,0,18),UDim2.fromOffset(14,34),{size=tiny and 9 or 10,color=P.brass,truncate=true})
  S.button(f,"Close","×",UDim2.fromOffset(28,28),UDim2.new(1,-36,0,9),ctx.close,{size=19})
  local sectionY=62
  local sc=Instance.new("ScrollingFrame");sc.Name="Details";sc.Size=UDim2.new(1,-24,1,-(sectionY+8));sc.Position=UDim2.fromOffset(11,sectionY)
  sc.BackgroundTransparency=1;sc.BorderSizePixel=0;sc.CanvasSize=UDim2.new()
  sc.AutomaticCanvasSize=Enum.AutomaticSize.Y;sc.ScrollingDirection=Enum.ScrollingDirection.Y
  sc.ScrollBarThickness=3;sc.ScrollBarImageColor3=P.brass;sc.Parent=f
  if u then sc.CanvasSize=UDim2.fromOffset(0,180);unitDetails(sc,ctx,u,t)
  elseif t then sc.CanvasSize=UDim2.fromOffset(0,184);provinceDetails(sc,ctx,t)
  else copy(sc,"Objective","Select an army or province. Follow roads north to Novgorod.",70,0,13) end
 end
 local feedW=math.min(472,math.floor(sz.X)-panelW-3*m-7)
 if tiny then feedW=math.max(94,feedW) else feedW=math.max(145,feedW) end
 local showHints=ctx.prefs.hints and not tiny
 local feedH=showHints and 69 or tiny and 66 or 53
 local feed=S.card(root,"CampaignFeed",UDim2.fromOffset(feedW,feedH),UDim2.new(0,m,1,-m),P.ink)
 feed.AnchorPoint=Vector2.new(0,1);feed.Active=true
 local edge=S.block(feed,"FeedAccent",UDim2.fromOffset(2,feedH-18),UDim2.fromOffset(7,9),P.brass);edge.BackgroundTransparency=.22
 S.text(feed,"Objective","OBJECTIVE  /  TAKE NOVGOROD",UDim2.new(1,-19,0,14),UDim2.fromOffset(14,4),{size=tiny and 8 or 10,font=S.Bold,color=P.brass,truncate=true})
 info=S.text(feed,"Message",ctx.message or "",UDim2.new(1,-19,0,tiny and 41 or 33),UDim2.fromOffset(14,17),{size=tiny and 10 or 12,color=ctx.bad and P.red or P.white,wrap=true})
 if showHints then S.text(feed,"Controls","WASD / drag to pan   ·   Scroll to zoom   ·   Q / E rotate",UDim2.new(1,-19,0,13),UDim2.fromOffset(14,51),{size=10,color=P.dim,truncate=true}) end
 return info
end
return H
