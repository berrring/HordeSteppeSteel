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

