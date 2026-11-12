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

return S
