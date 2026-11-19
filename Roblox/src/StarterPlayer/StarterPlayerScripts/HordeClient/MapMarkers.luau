
local Run=game:GetService("RunService")
local Core=game:GetService("GuiService")
local S=require(script.Parent.UISkin)
local M={}
local names={archer="HA",light="LC",heavy="HC",spear="SP",infantry="IN"}
function M.new(playerGui)
 local root=Instance.new("ScreenGui");root.Name="HordeMapMarkers";root.ScreenInsets=Enum.ScreenInsets.None
 root.ResetOnSpawn=false;root.DisplayOrder=3;root.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;root.Parent=playerGui
 local entries={}
 local api={}
 function api.clear()
  table.clear(entries)
  root:ClearAllChildren()
 end
 local function marker(n,text,tile,delta,w,h,tint,active,pick,z)
  local q=S.button(root,n,text,UDim2.fromOffset(w,h),nil,pick,{size=z==2 and 10 or 11,primary=active,truncate=true})
  q.Visible=false;q.ZIndex=z;q.AnchorPoint=Vector2.new(.5,.5);q.BackgroundTransparency=active and 0 or .11
  local border=q:FindFirstChildWhichIsA("UIStroke")
  border.Color=tint;border.Thickness=1.2;border.Transparency=.25
  table.insert(entries,{tile=tile,offset=delta,button=q})
 end
 function api.draw(state,selected,onPick,compact)
  api.clear()
  local world=workspace:FindFirstChild("HordeWorld")
  local tiles=world and world:FindFirstChild("Tiles")
  if not tiles then return end
  for _,id in ipairs(state.order) do
   local province=state.tiles[id]
   local tile=tiles:FindFirstChild(id)
   if tile and tile:IsA("BasePart") then
    local tint=province.owner=="mongol" and S.C.brass or province.owner=="rus" and S.C.red or S.C.dim
    local name=province.name
    marker("Province_"..id,name,tile,Vector3.new(-.28,2.56,-.89),math.clamp(#name*5+13,37,94),19,tint,false,
     function() onPick(id,true) end,2)
   end
  end
  for _,id in ipairs(state.unitOrder) do
   local u=state.units[id]
   local tile=u and tiles:FindFirstChild(u.tile)
   if tile and tile:IsA("BasePart") then
    local t=state.tiles[u.tile]
    marker("Army_"..id,string.format("%s  %d",names[u.kind],u.hp),tile,t.city and Vector3.new(1.26,.91,1.52) or Vector3.new(0,1.05,0),
     compact and 39 or 45,18,u.faction=="mongol" and S.C.brass or S.C.red,selected==id,function() onPick(u.tile,false) end,3)
   end
  end
 end
 Run:BindToRenderStep("HordeTacticalMarkers",Enum.RenderPriority.Camera.Value+2,function()
  if #entries==0 then return end
  local camera=workspace.CurrentCamera
  if not camera then return end
  local t,b=Core:GetGuiInset()
  local vp=camera.ViewportSize
  for _,entry in ipairs(entries) do
   local p,inside=camera:WorldToViewportPoint(entry.tile.Position+entry.offset)
   local visible=entry.tile.Parent~=nil and inside and p.Y>=t.Y+4 and p.Y<vp.Y-b.Y-4
   entry.button.Visible=visible
   if visible then entry.button.Position=UDim2.fromOffset(p.X,p.Y) end
  end
 end)
 return api
end
return M
