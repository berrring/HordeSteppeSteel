local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Shared=game.ReplicatedStorage:WaitForChild("HordeShared")
local C=require(Shared.Config)
local B=require(Shared.Board)
local S=require(script.Parent.UISkin)
local Camera=require(script.Parent.CameraController)
local remote=Shared.Remotes:WaitForChild("Command")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="HordeUI";gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")
local state,mode,save,inc=nil,"menu",false,nil
local selected,tileId,cityId
local legal,paths={},{}
local viewport,hover
local busy=false
local size=14
local setupFaction="mongol"
local message="The eastern frontier awaits."
local openMenu,openGame,redraw,request,openPause,openResult
local activeLayers={}
local visuals=Instance.new("Folder");visuals.Name="HordeSelectionLocal";visuals.Parent=workspace
local function clear()
 for _,p in ipairs(activeLayers) do p:Destroy() end
 activeLayers={}
end
local function keep(p) table.insert(activeLayers,p);return p end
local function header(p,n,text,sz,pos)
 return S.label(p,n,text,sz,pos,{font=Enum.Font.GothamBold,size=18,color=S.Gold})
end
local function afford(cost)
 for key,val in pairs(cost) do if state.resources.mongol[key]<val then return false end end
 return true
end
local banner
local function note(t)
 message=t or message
 if banner and banner.Parent then banner.Text=message end
end
local function tilePart(id)
 local world=workspace:FindFirstChild("HordeWorld")
 return world and world:FindFirstChild("Tiles") and world.Tiles:FindFirstChild(id)
end
local function hexOverlay(id,col,alpha,offset)
 local t=tilePart(id)
 if not t then return end
 local p=Instance.new("Part")
 p.Name="Preview "..id;p.Anchored=true
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Shape=Enum.PartType.Cylinder
 p.Size=Vector3.new(.039,t.Size.X*.79,t.Size.X*.79)
 p.CFrame=(t.CFrame+Vector3.new(0,t.Size.Y/2+offset,0))*CFrame.Angles(0,0,math.pi/2)
 p.Color=col;p.Material=Enum.Material.Neon;p.Transparency=alpha
 p.CanQuery=false;p.CanTouch=false;p.CanCollide=false;p.CastShadow=false
 p.Parent=visuals
end
local function renderHighlights(pathEnd)
 visuals:ClearAllChildren()
 if not state or mode~="game" then return end
 if tileId then hexOverlay(tileId,S.Gold,.48,.041) end
 for id in pairs(legal) do hexOverlay(id,Color3.fromHex("77C9AB"),.76,.033) end
 if selected then
  local u=state.units[selected]
  if u and not u.attacked then
   for id,other in pairs(state.units) do
    if other.faction~=u.faction and B.distance(state.tiles[u.tile],state.tiles[other.tile])<=C.Units[u.kind].range then
     hexOverlay(other.tile,Color3.fromHex("DC6755"),.48,.046)
    end
   end
  end
 end
 if pathEnd and legal[pathEnd] then
  local from=pathEnd
  while from and legal[from] do hexOverlay(from,Color3.fromHex("A8EFBD"),.68,.061);from=paths[from] end
 end
end
local function worldTile()
 local w=workspace:FindFirstChild("HordeWorld")
 local f=w and w:FindFirstChild("Tiles")
 if not f then return end
 local cursor=UIS:GetMouseLocation()
 local ray=workspace.CurrentCamera:ViewportPointToRay(cursor.X,cursor.Y)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={f}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*2500,params)
 if hit then return hit.Instance:GetAttribute("TileId") end
end
local function focus(id)
 if not state or not id then return end
 local t=state.tiles[id]
 if t then Camera.focus(B.position(t.q,t.r)) end
end
local function flash(events)
 for _,e in ipairs(events or {}) do
  if e.kind=="attack" or e.kind=="capture" then
   local t=tilePart(e.tile)
   if t then
    local gui=Instance.new("BillboardGui");gui.Name="HordeCombatFloat";gui.AlwaysOnTop=true
    gui.Size=UDim2.fromOffset(120,28);gui.StudsOffsetWorldSpace=Vector3.new(0,3.7,0);gui.Adornee=t;gui.Parent=player.PlayerGui
    local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1
    l.Text=e.kind=="capture" and "CAPTURED" or "-"..e.damage..(e.defeated and "  ROUTED" or "")
    l.Font=Enum.Font.GothamBold;l.TextScaled=true;l.TextStrokeTransparency=.25;l.TextColor3=e.kind=="capture" and S.Gold or Color3.fromHex("FF936F");l.Parent=gui
    Tween:Create(gui,TweenInfo.new(1.15),{StudsOffsetWorldSpace=gui.StudsOffsetWorldSpace+Vector3.new(0,2.1,0)}):Play()
    task.delay(1.25,function() gui:Destroy() end)
   end
  end
 end
end
request=function(action,data)
 if busy then return end
 busy=true
 data=data or {};data.action=action
 if action=="end" then note("Rus is taking its turn…") end
 local ok,r=pcall(function() return remote:InvokeServer(data) end)
 busy=false
 if not ok or not r then note("Server unavailable. Try again.");return false end
 state=r.state;save=r.hasSave;inc=r.income
 if r.message then note(r.message) end
 if state and state.result and action~="status" then openResult();return r.ok end
 if r.ok and (action=="start" or action=="continue") then
  selected=nil;cityId="sarai";tileId=state.cities.sarai.tile
  Camera.configure(state.size,B.position(state.tiles[tileId].q,state.tiles[tileId].r))
  openGame()
 elseif mode=="game" and state then
  if selected and not state.units[selected] then selected=nil end
  if selected and r.ok and action=="move" then tileId=state.units[selected].tile end
  redraw()
  if r.ok and (action=="move" or action=="end" or action=="attack") then flash(state.events) end
 elseif mode=="pause" and action=="save" and r.ok then
  openPause()
 end
 return r.ok
end
local function background(name)
 local bg=keep(S.frame(gui,name,UDim2.fromScale(1,1),UDim2.new(),S.Ink))
 local blend=Instance.new("UIGradient")
 blend.Color=ColorSequence.new(Color3.fromHex("172431"),Color3.fromHex("3C514C"));blend.Rotation=32;blend.Parent=bg
 return bg
end
local function card(parent,name,w,h)
 local c=S.frame(parent,name,UDim2.new(.93,0,.91,0),UDim2.fromScale(.5,.5),S.Panel)
 c.AnchorPoint=Vector2.new(.5,.5)
 local max=Instance.new("UISizeConstraint");max.MaxSize=Vector2.new(w,h);max.MinSize=Vector2.new(310,240);max.Parent=c
 S.round(c,14);S.stroke(c,S.Gold,.62)
 return c
end
openMenu=function(setup)
 mode=setup and "setup" or "menu";Camera.pause(true);visuals:ClearAllChildren();clear()
 local bg=background("FrontEnd")
 local panel=card(bg,"Campaign Setup",setup and 720 or 565,setup and 536 or 395)
 local pad=22
 local hero=header(panel,"Brand","HORDE  /  STEPPE & STEEL",UDim2.new(1,-2*pad,0,35),UDim2.fromOffset(pad,18))
 hero.TextSize=setup and 25 or 28
 S.label(panel,"Subtitle",setup and "CHOOSE YOUR CIVILIZATION" or "THE EASTERN FRONTIER",UDim2.new(1,-2*pad,0,28),UDim2.fromOffset(pad,55),{size=13,color=S.Muted})
 if not setup then
  S.label(panel,"Introduction","Ride from Sarai, claim the river crossings, and take Novgorod in an original turn-based campaign.",UDim2.new(1,-2*pad,0,57),UDim2.fromOffset(pad,86),{size=16,color=S.Text,wrap=true})
  S.button(panel,"NewGame","New campaign",UDim2.new(1,-2*pad,0,45),UDim2.fromOffset(pad,159),function() openMenu(true) end,true,true)
  S.button(panel,"Continue","Continue checkpoint",UDim2.new(1,-2*pad,0,42),UDim2.fromOffset(pad,214),function() request("continue") end,save)
  S.label(panel,"CheckpointNote","Checkpoints remain available in the current server session.",UDim2.new(1,-2*pad,0,38),UDim2.fromOffset(pad,260),{size=13,color=S.Muted,wrap=true})
  banner=S.label(panel,"Message",message,UDim2.new(1,-2*pad,0,44),UDim2.fromOffset(pad,310),{size=13,color=S.Gold,wrap=true})
  return
 end
 for i,id in ipairs(C.FactionOrder) do
  local fact=C.Factions[id]
  local x=(i-1)%2;local y=math.floor((i-1)/2)
  local pick=S.frame(panel,"Faction "..id,UDim2.new(.5,-29,0,74),UDim2.new(x*.5,x==0 and pad or 7,0,88+y*79),id==setupFaction and S.Tile or Color3.fromHex("273746"))
  S.round(pick,7)
  if id==setupFaction then S.stroke(pick,S.Gold,.25) end
  local stripe=S.frame(pick,"Faction accent",UDim2.fromOffset(4,49),UDim2.fromOffset(2,12),fact.color);S.round(stripe,2)
  S.label(pick,"Civilization",fact.name,UDim2.new(1,-24,0,23),UDim2.fromOffset(12,3),{font=Enum.Font.GothamBold,size=14,color=id==setupFaction and S.Gold or S.Text})
  S.label(pick,"Status",fact.status,UDim2.new(1,-24,0,16),UDim2.fromOffset(12,24),{size=11,color=S.Muted})
  S.label(pick,"Description",fact.description,UDim2.new(1,-26,0,30),UDim2.fromOffset(12,40),{size=11,color=S.Text,wrap=true})
  if id=="mongol" then
   local choose=Instance.new("TextButton");choose.Name="SelectMongol";choose.BackgroundTransparency=1;choose.Text="";choose.Size=UDim2.fromScale(1,1);choose.Parent=pick
   choose.Activated:Connect(function() setupFaction=id;note("Mongol Khanate selected.") end)
  end
 end
 S.label(panel,"MapSize","MAP SIZE",UDim2.fromOffset(106,27),UDim2.fromOffset(pad,340),{size=13,color=S.Muted})
 for i,n in ipairs({12,14,16}) do
  S.button(panel,"Map"..n,n.." × "..n,UDim2.new(.22,-13,0,34),UDim2.new((i-1)*.224, pad,0,372),function() size=n;openMenu(true) end,true,size==n)
 end
 local seed=Instance.new("TextBox");seed.Name="Seed";seed.PlaceholderText="Random seed";seed.Text="";seed.ClearTextOnFocus=false
 seed.Font=Enum.Font.Gotham;seed.TextSize=13;seed.TextColor3=S.Text;seed.PlaceholderColor3=S.Muted;seed.BackgroundColor3=S.Ink
 seed.Size=UDim2.new(.32,-24,0,34);seed.Position=UDim2.new(.675,0,0,372);seed.Parent=panel;S.round(seed,6)
 S.button(panel,"Back","Back",UDim2.new(.30,-pad,0,42),UDim2.fromOffset(pad,432),function() openMenu(false) end)
 S.button(panel,"Start","Start campaign",UDim2.new(.67,-pad,0,42),UDim2.new(.31,0,0,432),function()
  request("start",{size=size,faction=setupFaction,seed=tonumber(seed.Text)})
 end,true,true)
 banner=S.label(panel,"Message",message,UDim2.new(1,-2*pad,0,35),UDim2.fromOffset(pad,482),{size=13,color=S.Gold,wrap=true})
end
local top,context,side,feed,commandStrip
local function unitPanel(scroller,t,u)
 local d=C.Units[u.kind]
 header(scroller,"Title",d.name,UDim2.new(1,-7,0,29))
 S.label(scroller,"Faction",C.Factions[u.faction].name,UDim2.new(1,-7,0,21),nil,{size=13,color=S.Muted})
 local text=string.format("Health  %d / %d\nMove  %d    •    Range  %d\nAttack  %d    •    Defense  %d\n%s",u.hp,u.maxHp,u.mp,d.range,d.attack,d.defense,u.attacked and "Attack spent" or "Attack ready")
 S.label(scroller,"UnitStats",text,UDim2.new(1,-7,0,88),nil,{size=15,wrap=true})
 S.label(scroller,"Hint",u.faction=="mongol" and "Teal tiles are reachable. Red tiles contain targets in range." or "Enemy army. Select a Mongol unit to issue orders.",UDim2.new(1,-7,0,58),nil,{size=13,color=S.Muted,wrap=true})
 if t.city then S.button(scroller,"CityDetails","Inspect "..state.cities[t.city].name,UDim2.new(1,-6,0,34),nil,function() cityId=t.city;redraw() end) end
end
local function cityPanel(scroller,c,t)
 header(scroller,"CityName",c.name,UDim2.new(1,-7,0,30))
 S.label(scroller,"Owner",c.owner=="neutral" and "Neutral settlement" or C.Factions[c.owner].name,UDim2.new(1,-7,0,21),nil,{size=13,color=S.Muted})
 local def=(c.capital and 2 or 1)+(c.owner=="rus" and 1 or 0)+(c.buildings.fortress and 2 or 0)
 local gold=c.owner=="neutral" and 0 or c.capital and 6 or 4
 local food=c.owner=="neutral" and 0 or 4+(c.buildings.farm and 4 or 0)
 local wood=c.owner=="neutral" and 0 or 3+(c.buildings.lumber and 4 or 0)
 local garrison=t.unit and C.Units[state.units[t.unit].kind].name or "Open"
 local detail=string.format("City yield: %d gold / %d food / %d wood\nDefense +%d  ·  Garrison: %s",gold,food,wood,def,garrison)
 S.label(scroller,"CityStats",detail,UDim2.new(1,-7,0,54),nil,{size=13,color=S.Text,wrap=true})
 if c.owner=="mongol" then
  local count=0;for _,u in pairs(state.units) do if u.faction=="mongol" then count+=1 end end
  local free=not t.unit
  for _,a in ipairs(B.neighbors(state,t)) do if not a.unit and a.owner=="mongol" and C.Terrain[a.terrain].move<99 then free=true end end
  header(scroller,"RecruitTitle",c.recruited==state.turn and "RECRUITED THIS TURN" or "RECRUIT",UDim2.new(1,-7,0,25)).TextSize=13
  for _,k in ipairs(C.UnitOrder) do
   local d=C.Units[k]
   S.button(scroller,"Recruit_"..k,d.name.."  ·  "..S.cost(d.cost),UDim2.new(1,-5,0,34),nil,function() request("recruit",{city=c.id,kind=k}) end,
   afford(d.cost) and c.recruited~=state.turn and free and count<C.MaxUnits and state.active=="mongol")
  end
  header(scroller,"BuildTitle","CONSTRUCT",UDim2.new(1,-7,0,25)).TextSize=13
  for _,k in ipairs(C.BuildingOrder) do
   local d=C.Buildings[k]
   S.button(scroller,"Build_"..k,d.name.."  ·  "..(c.buildings[k] and "Completed" or S.cost(d.cost)),UDim2.new(1,-5,0,34),nil,function() request("build",{city=c.id,kind=k}) end,
   afford(d.cost) and not c.buildings[k] and c.built~=state.turn and state.active=="mongol")
  end
 else
  S.label(scroller,"Conquest","Clear the garrison and move onto the tile to capture it.",UDim2.new(1,-7,0,55),nil,{size=13,color=S.Muted,wrap=true})
 end
end
redraw=function()
 if mode~="game" or not state then return end
 top:ClearAllChildren()
 local terr=0
 for _,t in pairs(state.tiles) do if t.owner=="mongol" then terr+=1 end end
 local res=state.resources.mongol
 header(top,"Faction","MONGOL KHANATE",UDim2.new(.35,-5,0,24),UDim2.fromOffset(13,4)).TextSize=14
 S.label(top,"Territory","Turn "..state.turn.."   •   "..terr.." holdings",UDim2.new(.36,-5,0,20),UDim2.fromOffset(13,27),{size=12,color=S.Muted})

