local C=require(game.ReplicatedStorage.HordeShared.Config)
local S={}
S.Text=C.Palette.snow
S.Gold=C.Palette.gold
S.Muted=Color3.fromHex("A6B5C0")
S.Ink=C.Palette.ink
S.Panel=Color3.fromHex("223344")
S.Tile=Color3.fromHex("2D4253")
function S.round(p,n)
 local r=Instance.new("UICorner");r.CornerRadius=UDim.new(0,n or 8);r.Parent=p
end
function S.stroke(p,color,transparency)
 local a=Instance.new("UIStroke");a.Color=color or S.Gold;a.Transparency=transparency or .60;a.Thickness=1;a.Parent=p
end
function S.frame(p,n,size,pos,bg)
 local f=Instance.new("Frame");f.Name=n;f.Size=size;f.Position=pos or UDim2.new()
 f.BackgroundColor3=bg or S.Panel;f.BorderSizePixel=0;f.Parent=p
 return f
end
function S.label(p,n,text,size,pos,style)
 local l=Instance.new("TextLabel");l.Name=n;l.Text=text;l.Size=size;l.Position=pos or UDim2.new()
 l.BackgroundTransparency=1;l.TextXAlignment=Enum.TextXAlignment.Left
 l.Font=style and style.font or Enum.Font.Gotham
 l.TextColor3=style and style.color or S.Text
 l.TextSize=style and style.size or 15
 l.TextWrapped=style and style.wrap or false
 l.Parent=p;return l
end
function S.button(p,n,text,size,pos,callback,enabled,accent)
 local active=enabled~=false
 local t=Instance.new("TextButton");t.Name=n;t.Text=text;t.Size=size;t.Position=pos or UDim2.new()
 t.Font=Enum.Font.GothamMedium;t.TextSize=14;t.TextColor3=active and (accent and S.Ink or S.Text) or Color3.fromHex("7F909D")
 t.TextWrapped=true;t.AutoButtonColor=active;t.Active=active
 t.BackgroundColor3=active and (accent and S.Gold or S.Tile) or Color3.fromHex("283746")
 t.BorderSizePixel=0;t.Parent=p;S.round(t,6)
 if active then t.Activated:Connect(callback) end
 return t
end
function S.list(p,pad)
 local a=Instance.new("UIListLayout");a.Padding=UDim.new(0,pad or 5);a.SortOrder=Enum.SortOrder.LayoutOrder;a.Parent=p;return a
end
function S.cost(cost)
 local s={}
 for _,key in ipairs(C.ResourceOrder) do if cost[key] then table.insert(s,cost[key].." "..key) end end
 return table.concat(s,"  ·  ")
end
return S
