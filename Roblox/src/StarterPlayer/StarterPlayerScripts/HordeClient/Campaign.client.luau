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
 local purse=string.format("Gold  %d     Food  %d     Wood  %d",res.gold,res.food,res.wood)
 if inc then purse=string.format("Gold %d (+%d)    Food %d (+%d)    Wood %d (+%d)",res.gold,inc.gold,res.food,inc.food,res.wood,inc.wood) end
 S.label(top,"Resources",purse,UDim2.new(.54,0,1,0),UDim2.new(.30,0,0,0),{size=14,color=S.Text,wrap=true})
 S.button(top,"Menu","Menu",UDim2.fromOffset(63,34),UDim2.new(1,-72,0,10),openPause)
 commandStrip:ClearAllChildren()
 S.button(commandStrip,"EndTurn","End turn",UDim2.new(1,-10,0,40),UDim2.fromOffset(5,4),function() request("end") end,true,true)
 S.button(commandStrip,"Focus","Focus  [F]",UDim2.new(1,-10,0,29),UDim2.fromOffset(5,49),function() focus(tileId) end,tileId~=nil)
 context:ClearAllChildren();S.list(context,6)
 local t=tileId and state.tiles[tileId]
 local u=selected and state.units[selected]
 if cityId and state.cities[cityId] then
  local c=state.cities[cityId];cityPanel(context,c,state.tiles[c.tile])
 elseif u and t then unitPanel(context,t,u)
 elseif t then
  header(context,"Tile",t.terrain,UDim2.new(1,-7,0,30))
  local inf=C.Terrain[t.terrain]
  local detail=(t.owner=="neutral" and "Neutral territory" or C.Factions[t.owner].name).."\n"..(inf.move<99 and ("Movement cost: "..inf.move) or "Impassable")
  if inf.resource then detail..="\nResource: "..inf.resource end
  S.label(context,"TileInfo",detail,UDim2.new(1,-7,0,72),nil,{size=14,wrap=true})
 else
  header(context,"Orders","FIELD ORDERS",UDim2.new(1,-7,0,28))
  S.label(context,"StartHint","Click an army or settlement. Take Novgorod to win. Watch the river for fords.",UDim2.new(1,-7,0,89),nil,{size=14,wrap=true})
 end
 legal,paths={},{}
 if u and u.faction=="mongol" and not cityId then legal,paths=B.moveRange(state,u) end
 renderHighlights(hover)
end
openGame=function()
 mode="game";Camera.pause(false);clear()
 top=keep(S.frame(gui,"HordeHUD",UDim2.new(1,-24,0,56),UDim2.fromOffset(12,9),S.Ink));S.round(top,9)
 side=keep(S.frame(gui,"CampaignContext",UDim2.new(.29,0,1,-146),UDim2.new(1,-12,0,76),S.Ink))
 side.AnchorPoint=Vector2.new(1,0);S.round(side,9)
 local limits=Instance.new("UISizeConstraint");limits.MaxSize=Vector2.new(300,1600);limits.MinSize=Vector2.new(208,230);limits.Parent=side
 context=Instance.new("ScrollingFrame");context.Name="Details";context.Size=UDim2.new(1,-20,1,-107)
 context.Position=UDim2.fromOffset(12,10);context.BackgroundTransparency=1;context.BorderSizePixel=0;context.ScrollBarThickness=4
 context.CanvasSize=UDim2.new();context.AutomaticCanvasSize=Enum.AutomaticSize.Y;context.Parent=side
 commandStrip=S.frame(side,"CommandStrip",UDim2.new(1,-12,0,83),UDim2.new(0,6,1,-88),S.Ink)
 feed=keep(S.frame(gui,"CampaignFeed",UDim2.new(.68,-18,0,54),UDim2.new(0,12,1,-61),S.Ink));S.round(feed,8)
 banner=S.label(feed,"Message",message,UDim2.new(1,-20,0,29),UDim2.fromOffset(10,2),{size=13,color=S.Gold,wrap=true})
 S.label(feed,"Controls","WASD / right-drag pan   ·   Wheel zoom   ·   Q / E rotate   ·   F focus",UDim2.new(1,-20,0,19),UDim2.fromOffset(10,32),{size=11,color=S.Muted,wrap=true})
 redraw()
 task.delay(.35,function() if mode=="game" then renderHighlights() end end)
end
openPause=function()
 mode="pause";Camera.pause(true);visuals:ClearAllChildren();clear()
 local bg=background("Pause")
 local p=card(bg,"Paused",430,365)
 header(p,"Title","CAMPAIGN PAUSED",UDim2.new(1,-40,0,45),UDim2.fromOffset(20,14))
 banner=S.label(p,"Message",message,UDim2.new(1,-40,0,48),UDim2.fromOffset(20,54),{size=14,color=S.Muted,wrap=true})
 for i,a in ipairs({
  {"Resume","Resume campaign",openGame,true},
  {"Save","Save session checkpoint",function() request("save") end,true},
  {"Restore","Restore session checkpoint",function() request("continue") end,save},
  {"MainMenu","Main menu",function() openMenu(false) end,true},
 }) do S.button(p,a[1],a[2],UDim2.new(1,-40,0,43),UDim2.fromOffset(20,109+(i-1)*55),a[3],a[4],i==1) end
end
openResult=function()
 mode="result";Camera.pause(true);visuals:ClearAllChildren();clear()
 local bg=background("Result")
 local p=card(bg,"Campaign Result",480,350)
 local win=state.result=="mongol"
 header(p,"Outcome",win and "VICTORY  /  NOVGOROD FALLS" or "DEFEAT  /  SARAI HAS FALLEN",UDim2.new(1,-40,0,61),UDim2.fromOffset(20,14))
 S.label(p,"Stats",string.format("Turns completed: %d\nEnemy armies routed: %d\nSettlements captured: %d\nUnits recruited: %d",state.turn,state.stats.kills.mongol,state.stats.captures.mongol,state.stats.recruits.mongol),UDim2.new(1,-40,0,111),UDim2.fromOffset(20,80),{size=16,wrap=true})
 S.button(p,"Restart","Restart same map",UDim2.new(1,-40,0,44),UDim2.fromOffset(20,206),function() request("start",{size=state.size,faction="mongol",seed=state.seed}) end,true,true)
 S.button(p,"NewGame","Return to main menu",UDim2.new(1,-40,0,44),UDim2.fromOffset(20,263),function() openMenu(false) end)
end
local function mapSelect(id)
 local t=state.tiles[id]
 if not t then return end
 local u=selected and state.units[selected]
 if u and u.faction=="mongol" and not cityId and id~=u.tile then
  local target=t.unit and state.units[t.unit]
  if target and target.faction~="mongol" and B.distance(t,state.tiles[u.tile])<=C.Units[u.kind].range then
   request("attack",{unit=u.id,target=target.id});return
  elseif legal[id] then request("move",{unit=u.id,tile=id});return end
 end
 if id==tileId and t.city and not cityId then
  cityId=t.city;selected=nil
 elseif id==tileId and cityId and t.unit then cityId=nil;selected=t.unit
 else
  tileId=id;selected=t.unit;cityId=not t.unit and t.city or nil
 end
 redraw()
end
UIS.InputBegan:Connect(function(inp,processed)
 if UIS:GetFocusedTextBox() then return end
 if (inp.KeyCode==Enum.KeyCode.Escape or inp.KeyCode==Enum.KeyCode.P) and not busy then
  if mode=="game" then openPause() elseif mode=="pause" then openGame() end
  return
 end
 if processed or mode~="game" or busy or not state then return end
 if inp.KeyCode==Enum.KeyCode.F then focus(tileId);return end
 if inp.UserInputType==Enum.UserInputType.MouseButton1 then
  local id=worldTile()
  if id then mapSelect(id) end
 end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 if mode~="game" then return end
 elapsed+=dt
 if elapsed<.09 then return end
 elapsed=0
 local id=worldTile()
 if id~=hover then hover=id;renderHighlights(hover) end
end)
Camera.start()
request("status")
openMenu(false)
