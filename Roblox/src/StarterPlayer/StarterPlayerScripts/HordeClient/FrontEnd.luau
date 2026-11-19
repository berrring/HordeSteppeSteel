
local C=require(game.ReplicatedStorage.HordeShared.Config)
local S=require(script.Parent.UISkin)
local FrontScene=require(script.Parent.FrontScene)
local F={}
local P=S.C
local function B(p,n,l,w,h,x,y,cb,o)
 return S.button(p,n,l,UDim2.new(w,0,0,h),UDim2.new(x,0,0,y),cb,o)
end
local function heading(p,n,copy,y,h,size)
 return S.text(p,n,copy,UDim2.new(1,0,0,h),UDim2.fromOffset(0,y),{size=size,font=S.Display,color=P.white})
end
local function paragraph(p,n,copy,y,height,size,col)
 return S.text(p,n,copy,UDim2.new(1,0,0,height),UDim2.fromOffset(0,y),{size=size,wrap=true,color=col or P.muted})
end
local function screenDim(back,mode)
 back:ClearAllChildren()
 local f=S.block(back,"Backdrop",UDim2.fromScale(1,1),nil,P.ink)
 if mode=="pause" or mode=="result" then
  f.BackgroundTransparency=.26
 else
  f.BackgroundColor3=Color3.new(1,1,1)
  local a=Instance.new("UIGradient")
  a.Color=ColorSequence.new(Color3.fromHex("0D171F"),Color3.fromHex("34443C"));a.Rotation=17;a.Parent=f
 end
 return f
end
local function addScene(back,sz)
 local v,fit=FrontScene.new(back);fit(sz.X)
 local full=S.block(back,"SceneShade",UDim2.fromScale(1,1),nil,P.ink)
 local grad=Instance.new("UIGradient")
 grad.Color=ColorSequence.new(Color3.new(1,1,1))
 grad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.06),NumberSequenceKeypoint.new(.365,.08),NumberSequenceKeypoint.new(.60,.91),NumberSequenceKeypoint.new(1,.96)})
 grad.Rotation=sz.X<620 and -67 or 0;grad.Parent=full
end
local function modal(root,name,w,h,ctx,backRoute)
 local box=S.card(root,name,UDim2.new(1,-28,1,-24),UDim2.fromScale(.5,.5),P.panel)
 box.AnchorPoint=Vector2.new(.5,.5)
 local constrain=Instance.new("UISizeConstraint");constrain.MaxSize=Vector2.new(w,h);constrain.Parent=box
 local body=Instance.new("ScrollingFrame");body.Name="Content";body.BackgroundTransparency=1;body.BorderSizePixel=0
 body.Position=UDim2.fromOffset(18,11);body.Size=UDim2.new(1,-36,1,-22)
 body.ScrollingDirection=Enum.ScrollingDirection.Y;body.AutomaticCanvasSize=Enum.AutomaticSize.Y;body.CanvasSize=UDim2.new()
 body.ScrollBarThickness=3;body.ScrollBarImageColor3=P.brass;body.Parent=box
 if backRoute then
  local button=S.button(box,"Close","×",UDim2.fromOffset(34,32),UDim2.new(1,-44,0,11),backRoute,{size=23})
  button.ZIndex=3
 end
 return body
end
local function note(p,ctx,y)
 return paragraph(p,"Status",ctx.message or "",y,33,12,ctx.bad and P.red or P.brass)
end
function F.render(root,back,mode,ctx)
 local sz=root.AbsoluteSize
 local narrow=sz.X<620
 local low=sz.Y<463
 local background=screenDim(back,mode)
 if mode=="menu" or mode=="setup" then addScene(background,sz) end
 if mode=="menu" then
  local width=math.clamp((sz.X>0 and sz.X or 750)*.47,275,535)
  if narrow then width=math.clamp(sz.X-44,238,370) end
  local left=narrow and 22 or math.clamp(sz.X*.063,28,90)
  local h=low and 346 or 420
  local design=S.block(root,"MainMenu",UDim2.fromOffset(width,h),UDim2.new(0,left,.5,low and 0 or 4),P.ink)
  design.BackgroundTransparency=1;design.AnchorPoint=Vector2.new(0,.5)
  local serif=sz.X<740 and 42 or 54
  S.text(design,"Setting","THE EASTERN FRONTIER",UDim2.new(1,0,0,19),nil,{size=12,font=S.Bold,color=P.brass})
  local rule=S.block(design,"HeadingRule",UDim2.fromOffset(48,2),UDim2.fromOffset(0,26),P.brass);rule.BackgroundTransparency=.20
  local title=S.text(design,"GameTitle","HORDE",UDim2.new(1,0,0,62),UDim2.fromOffset(0,31),{size=serif+14,font=S.Display})
  if low then title.TextSize=serif end
  local subY=low and 82 or 91
  S.text(design,"Subtitle","STEPPE & STEEL",UDim2.new(1,0,0,37),UDim2.fromOffset(1,subY),{size=low and 26 or 32,font=S.Display,color=P.pale})
  paragraph(design,"Introduction","Command the Mongol armies across twelve provinces. Take Novgorod to win.",subY+41,low and 37 or 48,low and 13 or 15)
  local y=low and 165 or 196
  B(design,"NewGame","New Campaign",1,44,0,y,function() ctx.navigate("setup") end,{primary=true,size=15})
  local canResume=ctx.active or ctx.saved
  B(design,"Continue",ctx.active and "Resume campaign" or ctx.saved and "Continue checkpoint" or "Continue  ·  No checkpoint",1,39,0,y+53,function()
   if ctx.active then ctx.navigate("game") else ctx.request("continue") end
  end,{enabled=canResume,size=13})
  B(design,"Settings","Settings",.48,35,0,y+103,function() ctx.navigate("settings","menu") end,{size=13})
  B(design,"About","About",.48,35,.52,y+103,function() ctx.navigate("about","menu") end,{size=13})
  if ctx.message and ctx.message~="" then return note(design,ctx,y+145) end
  return
 elseif mode=="setup" then
  local f=modal(root,"CampaignSetup",617,377,ctx,function() ctx.navigate("menu") end)
  heading(f,"Title","Mongol campaign",4,51,narrow and 31 or 38)
  paragraph(f,"Intro","CHECKPOINT 1  /  12 PROVINCES",57,25,12,P.brass)
  local cards={
   {"Mongol", "Mongol Khanate", "Player", C.Factions.mongol.color},
   {"Rus", "Rus' Principalities", "AI opponent", C.Factions.rus.color},
  }
  for i,q in ipairs(cards) do
   local a=S.card(f,q[1],UDim2.new(.48,0,0,58),UDim2.new((i-1)*.52,0,0,97),P.raised)
   local dot=S.block(a,"FactionMark",UDim2.fromOffset(3,31),UDim2.fromOffset(8,12),q[4]);S.corner(dot,2)
   S.text(a,"Title",q[2],UDim2.new(1,-20,0,23),UDim2.fromOffset(15,7),{size=narrow and 11 or 14,font=S.Bold,truncate=true})
   S.text(a,"Role",q[3],UDim2.new(1,-20,0,20),UDim2.fromOffset(15,30),{size=11,color=P.muted})
  end
  paragraph(f,"Brief","Select an army, then follow a road to move or attack. Each army can act once per turn.",176,57,14)
  B(f,"Back","Back",.27,42,0,254,function() ctx.navigate("menu") end)
  B(f,"Start","Start Campaign",.69,42,.30,254,ctx.start,{primary=true})
  return note(f,ctx,306)
 elseif mode=="settings" then
  local f=modal(root,"Settings",489,333,ctx,function() ctx.navigate(ctx.returnTo or "menu") end)
  heading(f,"Title","Settings",3,41,34)
  paragraph(f,"Scope","These preferences last for this play session.",48,30,13)
  B(f,"ReducedMotion","Reduce interface motion  ·  "..(ctx.prefs.reduce and "On" or "Off"),1,39,0,91,function() ctx.toggle("reduce") end,{selected=ctx.prefs.reduce})
  B(f,"PlatformChat","Roblox chat  ·  "..(ctx.prefs.chat and "On" or "Off"),1,39,0,140,function() ctx.toggle("chat") end,{selected=ctx.prefs.chat})
  B(f,"ControlsHint","Show control hints  ·  "..(ctx.prefs.hints and "On" or "Off"),1,39,0,189,function() ctx.toggle("hints") end,{selected=ctx.prefs.hints})
  B(f,"Back","Done",1,36,0,251,function() ctx.navigate(ctx.returnTo or "menu") end,{primary=true})
 elseif mode=="about" then
  local f=modal(root,"About",476,302,ctx,function() ctx.navigate("menu") end)
  heading(f,"Title","Horde / Steppe & Steel",4,43,32)
  paragraph(f,"Credit","A medieval Eurasian strategy game by Team Arsenal.",55,46,15,P.white)
  paragraph(f,"Details","Lead the Mongol Khanate through the Eastern Frontier. The Rus' Principalities oppose you in this campaign.",110,67,14)
  B(f,"Back","Back to menu",1,39,0,196,function() ctx.navigate("menu") end,{primary=true})
 elseif mode=="pause" then
  local f=modal(root,"PauseMenu",486,416,ctx,function() ctx.navigate("game") end)
  heading(f,"Title","Orders paused",4,45,35)
  paragraph(f,"Details","Turn "..ctx.state.turn.."  ·  Mongol Khanate",49,27,13)
  local commands={
   {"Resume","Resume Campaign",function() ctx.navigate("game") end,true},
   {"Save","Save session checkpoint",function() ctx.request("save") end,true},
   {"Restore",ctx.saved and "Restore checkpoint" or "Restore  ·  No checkpoint",function() ctx.request("continue") end,ctx.saved},
   {"Settings","Settings",function() ctx.navigate("settings","pause") end,true},
   {"MainMenu","Main menu",function() ctx.navigate("menu") end,true},
  }
  for i,q in ipairs(commands) do B(f,q[1],q[2],1,37,0,87+(i-1)*45,q[3],{primary=i==1,enabled=q[4],size=13}) end
  return note(f,ctx,318)
 elseif mode=="result" then
  local f=modal(root,"CampaignResult",491,336,ctx)
  local s=ctx.state;local win=s.result=="mongol"
  heading(f,"Outcome",s.endReason or (win and "Victory" or "Defeat"),1,53,37)
  paragraph(f,"Verdict",win and "VICTORY" or "DEFEAT",55,24,13,win and P.brass or P.red)
  paragraph(f,"Stats",string.format("Turns played: %d\nEnemy armies routed: %d\nSettlements captured: %d\nUnits recruited: %d",s.turn,s.stats.kills.mongol,s.stats.captures.mongol,s.stats.recruits.mongol),86,94,14,P.white)
  B(f,"Restart","Restart campaign",1,40,0,192,ctx.start,{primary=true})
  B(f,"MainMenu","Main menu",1,36,0,242,function() ctx.navigate("menu") end)
 end
end
return F
