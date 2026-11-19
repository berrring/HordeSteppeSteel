
local Tween=game:GetService("TweenService")
local S={}
S.C={
 ink=Color3.fromHex("101A22"),panel=Color3.fromHex("192733"),raised=Color3.fromHex("223444"),
 line=Color3.fromHex("42535A"),muted=Color3.fromHex("B0BFBE"),dim=Color3.fromHex("869B9D"),
 white=Color3.fromHex("E8ECEF"),gold=Color3.fromHex("DAA520"),brass=Color3.fromHex("D7B763"),
 pale=Color3.fromHex("F0D991"),red=Color3.fromHex("F0A08E"),green=Color3.fromHex("9DD8BD"),
 wood=Color3.fromHex("5C4033"),olive=Color3.fromHex("6B8E23"),steel=Color3.fromHex("2B3A4A"),
}
S.Display=Enum.Font.Garamond
S.Bold=Enum.Font.GothamBold
S.Regular=Enum.Font.Gotham
S.Medium=Enum.Font.GothamMedium
S.reduce=false
function S.corner(p,r)
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 7);c.Parent=p;return c
end
function S.stroke(p,c,t)
 local b=Instance.new("UIStroke");b.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 b.Color=c or S.C.line;b.Transparency=t or .34;b.Thickness=1;b.Parent=p;return b
end
function S.block(p,n,box,pos,color)
 local a=Instance.new("Frame");a.Name=n;a.Size=box;a.Position=pos or UDim2.new()
 a.BackgroundColor3=color or S.C.panel;a.BorderSizePixel=0;a.Parent=p;return a
end
function S.card(p,n,box,pos,color)
 local a=S.block(p,n,box,pos,color);S.corner(a,9);S.stroke(a);return a
end
function S.text(p,n,copy,box,pos,style)
 style=style or {}
 local l=Instance.new("TextLabel")
 l.Name=n;l.Text=copy;l.Size=box;l.Position=pos or UDim2.new()
 l.BackgroundTransparency=1;l.TextColor3=style.color or S.C.white
 l.Font=style.font or S.Regular;l.TextSize=style.size or 14
 l.TextXAlignment=style.align or Enum.TextXAlignment.Left
 l.TextYAlignment=style.valign or Enum.TextYAlignment.Center
 l.TextWrapped=style.wrap or false
 if style.truncate then l.TextTruncate=Enum.TextTruncate.AtEnd end
 l.Parent=p;return l
end
function S.list(p,gap)
 local l=Instance.new("UIListLayout");l.Padding=UDim.new(0,gap or 6);l.SortOrder=Enum.SortOrder.LayoutOrder;l.Parent=p
 return l
end
function S.row(p,n,copy,height,style)
 return S.text(p,n,copy,UDim2.new(1,0,0,height),nil,style)
end
function S.button(p,n,copy,box,pos,act,opt)
 opt=opt or {}
 local enabled=opt.enabled~=false
 local colors=S.C
 local base=opt.primary and colors.brass or opt.selected and Color3.fromHex("354D50") or colors.raised
 local hover=opt.primary and colors.pale or opt.selected and Color3.fromHex("445F60") or Color3.fromHex("304B59")
 local press=opt.primary and Color3.fromHex("BF9A4D") or Color3.fromHex("1D303C")
 local b=Instance.new("TextButton");b.Name=n;b.Text=copy;b.Size=box;b.Position=pos or UDim2.new()
 b.Font=S.Medium;b.TextSize=opt.size or 14;b.TextWrapped=opt.wrap or false
 b.TextTruncate=opt.truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
 b.BackgroundColor3=enabled and base or Color3.fromHex("1B2933")
 b.TextColor3=enabled and (opt.primary and colors.ink or opt.selected and colors.pale or colors.white) or colors.dim
 b.BorderSizePixel=0;b.AutoButtonColor=false;b.Active=enabled;b.Selectable=enabled
 b.Interactable=enabled;b.Parent=p;S.corner(b,6)
 local border=S.stroke(b,opt.primary and colors.pale or opt.selected and colors.brass or colors.line,opt.primary and .53 or opt.selected and .31 or enabled and .57 or .82)
 if enabled then
  local pointed,down=false,false
  local tween
  local function paint()
   if tween then tween:Cancel() end
   local color=down and press or pointed and hover or base
   border.Transparency=pointed and .23 or opt.selected and .31 or .55
   if S.reduce then b.BackgroundColor3=color
   else tween=Tween:Create(b,TweenInfo.new(.13,Enum.EasingStyle.Quad),{BackgroundColor3=color});tween:Play() end
  end
  b.MouseEnter:Connect(function() pointed=true;paint() end)
  b.MouseLeave:Connect(function() pointed=false;down=false;paint() end)
  b.SelectionGained:Connect(function() pointed=true;paint() end)
  b.SelectionLost:Connect(function() pointed=false;down=false;paint() end)
  b.MouseButton1Down:Connect(function() down=true;paint() end)
  b.MouseButton1Up:Connect(function() down=false;paint() end)
  b.Activated:Connect(act)
 end
 return b
end
function S.cost(c)
 local out={}
 for _,k in ipairs({"gold","food","wood"}) do if c[k] then table.insert(out,c[k].." "..k) end end
 return table.concat(out,"  ·  ")
end
return S
