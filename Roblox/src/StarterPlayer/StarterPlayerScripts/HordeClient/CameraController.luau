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
function Camera.configure(n,first)
 local a,b=B.position(0,0),B.position(n-1,n-1)
 minX=a.X-8;maxX=b.X+8;minZ=a.Z-8;maxZ=b.Z+8
 target=first or (a+b)/2
 focus=target
 zoom=first and 66 or 104
 smoothed=zoom
end
function Camera.focus(p) target=Vector3.new(p.X,C.FieldOrigin.Y,p.Z) end
function Camera.pause(v) paused=v;drag=false end
function Camera.start()
 local cam=workspace.CurrentCamera
 cam.CameraType=Enum.CameraType.Scriptable
 cam.FieldOfView=48
 UIS.InputBegan:Connect(function(input,gp)
  if gp or paused or UIS:GetFocusedTextBox() then return end
  if input.UserInputType==Enum.UserInputType.MouseButton2 then drag=true end
  if input.KeyCode==Enum.KeyCode.Q then yaw-=math.pi/6 end
  if input.KeyCode==Enum.KeyCode.E then yaw+=math.pi/6 end
 end)
 UIS.InputEnded:Connect(function(input)

return C
