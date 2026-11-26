local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local C=require(game.ReplicatedStorage.HordeShared.Config)
local B=require(game.ReplicatedStorage.HordeShared.Board)
local Camera={}
local target=C.FieldOrigin
local focus=target
local zoom=88
local smoothed=zoom
local yaw=math.rad(29)
local smoothYaw=yaw
local minX,maxX,minZ,maxZ=target.X-10,target.X+110,target.Z-10,target.Z+105
local paused=true
local drag=false
local touches={}
local function pan(dx,dy)
 local right=Vector3.new(math.cos(smoothYaw),0,-math.sin(smoothYaw))
 local back=Vector3.new(math.sin(smoothYaw),0,math.cos(smoothYaw))
 target-=right*dx*(zoom/670)
 target+=back*dy*(zoom/670)
end
function Camera.configure(state)
 local a,b=B.center(state.tiles[state.order[1]]),B.center(state.tiles[state.order[1]])
 for _,id in ipairs(state.order) do
  local p=B.center(state.tiles[id])
  a=Vector3.new(math.min(a.X,p.X),p.Y,math.min(a.Z,p.Z))
  b=Vector3.new(math.max(b.X,p.X),p.Y,math.max(b.Z,p.Z))
 end
 minX=a.X-8;maxX=b.X+8;minZ=a.Z-8;maxZ=b.Z+8
 target=(a+b)/2
 yaw=math.rad(18);smoothYaw=yaw
 focus=target
 local view=workspace.CurrentCamera.ViewportSize
 local aspect=math.max(.6,view.X/math.max(1,view.Y))
 local span=b-a
 zoom=math.clamp(math.max((span.Z*.73+span.X*.17+15)/.58,(span.X+span.Z*.23+12)/(.71*aspect)),96,190)
 smoothed=zoom
end
function Camera.focus(p) target=Vector3.new(p.X,C.FieldOrigin.Y,p.Z) end
function Camera.pause(v) paused=v;drag=false;table.clear(touches) end
function Camera.start()
 local cam=workspace.CurrentCamera
 cam.CameraType=Enum.CameraType.Scriptable
 cam.FieldOfView=49
 UIS.InputBegan:Connect(function(input,gp)
  if gp or paused or UIS:GetFocusedTextBox() then return end
  if input.UserInputType==Enum.UserInputType.MouseButton2 then drag=true end
  if input.KeyCode==Enum.KeyCode.Q then yaw-=math.pi/6 end
  if input.KeyCode==Enum.KeyCode.E then yaw+=math.pi/6 end
 end)
 UIS.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton2 then drag=false end
 end)
 UIS.InputChanged:Connect(function(input,gp)
  if paused then return end
  if input.UserInputType==Enum.UserInputType.MouseWheel and not gp then zoom=math.clamp(zoom-input.Position.Z*8,32,195) end
  if drag and input.UserInputType==Enum.UserInputType.MouseMovement then
   pan(input.Delta.X,input.Delta.Y)
  end
 end)
 UIS.TouchStarted:Connect(function(input,processed)
  if not processed and not paused then touches[input]=input.Position end
 end)
 UIS.TouchMoved:Connect(function(input)
  local last=touches[input]
  if not last or paused then return end
  local now=input.Position
  local companion
  for item,p in pairs(touches) do if item~=input then companion=p;break end end
  touches[input]=now
  if companion then
   zoom=math.clamp(zoom+((last-companion).Magnitude-(now-companion).Magnitude)*.16,32,195)
  else
   local delta=now-last
   pan(delta.X,delta.Y)
  end
 end)
 UIS.TouchEnded:Connect(function(input) touches[input]=nil end)
 Run:BindToRenderStep("HordeStrategyCamera",Enum.RenderPriority.Camera.Value+1,function(dt)
  local right=Vector3.new(math.cos(smoothYaw),0,-math.sin(smoothYaw))
  local forward=Vector3.new(-math.sin(smoothYaw),0,-math.cos(smoothYaw))
  if not paused and not UIS:GetFocusedTextBox() then
   local x=(UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0)-(UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
   local z=(UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0)-(UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
   target+=(right*x+forward*z)*(22+smoothed*.21)*dt
  end
  target=Vector3.new(math.clamp(target.X,minX,maxX),C.FieldOrigin.Y,math.clamp(target.Z,minZ,maxZ))
  local alpha=1-math.exp(-dt*10)
  focus=focus:Lerp(target,alpha);smoothed+=(zoom-smoothed)*alpha;smoothYaw+=(yaw-smoothYaw)*alpha
  local eye=Vector3.new(math.sin(smoothYaw)*.68,.735,math.cos(smoothYaw)*.68)*smoothed
  cam.CFrame=CFrame.lookAt(focus+eye,focus);cam.Focus=CFrame.new(focus)
 end)
end
return Camera
