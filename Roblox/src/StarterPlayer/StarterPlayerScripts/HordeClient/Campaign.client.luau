
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Core=game:GetService("StarterGui")
local Shared=game.ReplicatedStorage:WaitForChild("HordeShared")
local C=require(Shared.Config)
local B=require(Shared.Board)
local S=require(script.Parent.UISkin)
local Camera=require(script.Parent.CameraController)
local Front=require(script.Parent.FrontEnd)
local Hud=require(script.Parent.CampaignHud)
local Markers=require(script.Parent.MapMarkers)
local remote=Shared.Remotes:WaitForChild("Command")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local P=S.C
local markers=Markers.new(pg)
local function screen(name,order,inset)
 local g=Instance.new("ScreenGui");g.Name=name;g.ResetOnSpawn=false
 g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;g.DisplayOrder=order;g.ScreenInsets=inset
 g.Parent=pg
 return g
end
local back=screen("HordeAtmosphere",4,Enum.ScreenInsets.None)
back.ClipToDeviceSafeArea=false
local gui=screen("HordeUI",5,Enum.ScreenInsets.CoreUISafeInsets)
local root=S.block(gui,"SafeArea",UDim2.fromScale(1,1),nil,P.ink);root.BackgroundTransparency=1
local state,save,income
local mode,returnTo="menu","menu"
local prefs={hints=true,chat=false,reduce=false}
local selected,tileId,provinceId
local inspector=true
local legal,paths={},{}
local hover,banner
local busy,busyTurn,bad=false,false,false
local message=""
local request,render,navigate,mapSelect
local visuals=Instance.new("Folder");visuals.Name="HordeSelectionLocal";visuals.Parent=workspace
local function note(t,isBad)
 message=t or message;bad=isBad==true
 if banner and banner.Parent then
  banner.Text=message;banner.TextColor3=bad and P.red or mode=="game" and P.white or P.brass
 end
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
 if tileId then hexOverlay(tileId,P.brass,.48,.041) end
 for id in pairs(legal) do hexOverlay(id,Color3.fromHex("77C9AB"),.76,.033) end
 if selected then
  local u=state.units[selected]
  if u and u.faction=="mongol" and u.mp>0 and not u.attacked then
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
local function worldTile(point)
 local w=workspace:FindFirstChild("HordeWorld")
 local f=w and w:FindFirstChild("Tiles")
 if not f then return end
 local cursor=point or UIS:GetMouseLocation()
 local ray=workspace.CurrentCamera:ViewportPointToRay(cursor.X,cursor.Y)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={f}
 local hit=workspace:Raycast(ray.Origin,ray.Direction*2500,params)
 if hit then return hit.Instance:GetAttribute("TileId") end
end
local function focus(id)
 if not state or not id then return end
 local t=state.tiles[id]
 if t then Camera.focus(B.center(t)) end
end
local function flash(events)
 for _,e in ipairs(events or {}) do
  if e.kind=="attack" or e.kind=="capture" then
   local t=tilePart(e.tile)
   if t then
    local gui=Instance.new("BillboardGui");gui.Name="HordeCombatFloat";gui.AlwaysOnTop=true
    gui.Size=UDim2.fromOffset(120,28);gui.StudsOffsetWorldSpace=Vector3.new(0,e.kind=="capture" and 4.8 or 3.7,0);gui.Adornee=t;gui.Parent=player.PlayerGui
    local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1
    l.Text=e.kind=="capture" and "CAPTURED" or "-"..e.damage..(e.defeated and "  ROUTED" or "")
    l.Font=Enum.Font.GothamBold;l.TextScaled=true;l.TextStrokeTransparency=.25;l.TextColor3=e.kind=="capture" and P.brass or Color3.fromHex("FF936F");l.Parent=gui
    Tween:Create(gui,TweenInfo.new(1.15),{StudsOffsetWorldSpace=gui.StudsOffsetWorldSpace+Vector3.new(0,2.1,0)}):Play()
    task.delay(1.25,function() gui:Destroy() end)
   end
  end
 end
end

local function applyPrefs()
 S.reduce=prefs.reduce
 pcall(function() Core:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,prefs.chat) end)
end
local function selectUnit(id)
 local u=state.units[id];if not u then return end
 selected=id;provinceId=nil;tileId=u.tile;inspector=true;render()
end
local function selectProvince(id)
 if not state.tiles[id] then return end
 selected=nil;provinceId=id;tileId=id;inspector=true;render()
end
local function markerPick(id,isProvince)
 if busy or mode~="game" or not state or not state.tiles[id] then return end
 if isProvince and (not selected or id==tileId) then selectProvince(id) else mapSelect(id) end
end
local function relocateFirst()
 selected=nil;provinceId="sarai";tileId="sarai"
 inspector=root.AbsoluteSize.X>=635
 local frontier=B.center(state.tiles.kiev)
 local south=B.center(state.tiles.urgench)
 Camera.configure(state,frontier:Lerp(south,.37)+Vector3.new(9,0,0))
end
request=function(action,payload)
 if busy then return false end
 busy=true;busyTurn=action=="end"
 if busyTurn then note("Rus is taking its turn…",false);render() end
 payload=payload or {};payload.action=action
 if state and action~="start" and action~="continue" and action~="status" then
  payload.matchId=state.matchId;payload.turn=state.turn
 end
 local ok,r=pcall(function() return remote:InvokeServer(payload) end)
 busy=false;busyTurn=false
 if not ok or not r then note("Could not reach the campaign server. Try again.",true);render();return false end
 state=r.state;save=r.hasSave;income=r.income
 if r.message then note(r.message,not r.ok) end
 if state and state.result and action~="status" then navigate("result");return r.ok end
 if r.ok and (action=="start" or action=="continue") then
  relocateFirst()
  navigate("game")
  task.delay(.4,function() if mode=="game" then renderHighlights();markers.draw(state,selected,markerPick,root.AbsoluteSize.X<435) end end)
 elseif mode=="game" and state then
  if selected and not state.units[selected] then selected=nil;provinceId=tileId end
  if selected and state.units[selected] then tileId=state.units[selected].tile end
  render()
  if r.ok and (action=="move" or action=="end" or action=="attack") then flash(state.events) end
 elseif action~="status" then render() end
 return r.ok
end
navigate=function(nextMode,goBack)
 if nextMode=="game" and (not state or state.result) then return end
 if nextMode=="pause" and (not state or state.result) then return end
 if goBack then returnTo=goBack end
 mode=nextMode
 Camera.pause(mode~="game")
 render()
end
render=function()
 if root.AbsoluteSize.X<40 then return end
 root:ClearAllChildren();banner=nil
 back.Enabled=mode~="game"
 if mode=="game" and state then
  local u=selected and state.units[selected]
  legal,paths={},{}
  if u and u.faction=="mongol" and not provinceId then legal,paths=B.moveRange(state,u) end
  banner=Hud.render(root,{
   state=state,income=income,busy=busy,busyTurn=busyTurn,tile=tileId,unit=selected,province=provinceId,inspector=inspector,prefs=prefs,message=message,bad=bad,
   request=request,navigate=navigate,focus=function() focus(tileId) end,endTurn=function() request("end") end,
   close=function() inspector=false;render() end,reopen=function() inspector=true;render() end,
   inspectUnit=selectUnit,inspectProvince=selectProvince,
  })
  renderHighlights(hover)
  markers.draw(state,selected,markerPick,root.AbsoluteSize.X<435)
 else
  markers.clear();visuals:ClearAllChildren()
  banner=Front.render(root,back,mode,{
   state=state,saved=save,active=state~=nil and not state.result,navigate=navigate,request=request,
   message=message,bad=bad,prefs=prefs,returnTo=returnTo,
   start=function() request("start",{faction="mongol"}) end,
   toggle=function(k) prefs[k]=not prefs[k];applyPrefs();render() end,
  })
 end
end
mapSelect=function(id)
 local t=state.tiles[id]
 if not t then return end
 local u=selected and state.units[selected]
 if u and u.faction=="mongol" and id~=u.tile then
  local enemy=t.unit and state.units[t.unit]
  if enemy and enemy.faction~="mongol" then request("attack",{unit=u.id,target=enemy.id});return
  elseif not t.unit then request("move",{unit=u.id,tile=id});return end
 end
 if t.unit then selectUnit(t.unit) else selectProvince(id) end
end
UIS.InputBegan:Connect(function(inp,processed)
 if UIS:GetFocusedTextBox() or busy then return end
 if inp.KeyCode==Enum.KeyCode.P or inp.KeyCode==Enum.KeyCode.Escape then
  if mode=="game" and (inp.KeyCode==Enum.KeyCode.P or not processed) then navigate("pause")
  elseif mode=="pause" and (inp.KeyCode==Enum.KeyCode.P or not processed) then navigate("game") end
  return
 end
 if processed or mode~="game" or not state then return end
 if inp.KeyCode==Enum.KeyCode.F then focus(tileId)
 elseif inp.UserInputType==Enum.UserInputType.MouseButton1 then
  local id=worldTile();if id then mapSelect(id) end
 end
end)
UIS.TouchTap:Connect(function(positions,processed)
 if processed or mode~="game" or busy or not state or #positions~=1 then return end
 local id=worldTile(positions[1]);if id then mapSelect(id) end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 if mode~="game" or not UIS.MouseEnabled then return end
 elapsed+=dt
 if elapsed<.10 then return end
 elapsed=0
 local id=worldTile()
 if id~=hover then hover=id;renderHighlights(hover) end
end)
local revision=0
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
 revision+=1
 local token=revision
 task.delay(.12,function() if token==revision then render() end end)
end)
applyPrefs()
Camera.start()
request("status")
navigate("menu")
