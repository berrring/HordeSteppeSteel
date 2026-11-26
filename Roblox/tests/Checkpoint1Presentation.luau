-- Run in the Studio Server Command Bar during Play, after starting a campaign.
local world = workspace:WaitForChild("HordeWorld", 5)
assert(world, "Start a campaign before running presentation checks")
assert(#world.Tiles:GetChildren() == 12 and #world["Province Roads"]:GetChildren() == 18)
local originals = game.ServerStorage.HordeAssets
local Art = require(game.ServerScriptService.HordeServer.CampaignArt)
local verified = 0
for _, category in ipairs({"Units", "Buildings", "Environment"}) do
 for _, original in ipairs(originals[category]:GetChildren()) do
  local portable = Art.place(category, original.Name, CFrame.identity, 1)
  assert(portable:GetAttribute("SourceAsset") == original.Name)
  assert(portable:FindFirstChildWhichIsA("BasePart", true), original.Name)
  for _, child in ipairs(portable:GetDescendants()) do
   if child:IsA("BasePart") then
    assert(child.Anchored and not child.CanCollide and not child.CanTouch, child.Name)
   end
   assert(not child:IsA("MeshPart") or child.MeshContent.SourceType ~= Enum.ContentSourceType.Opaque, child.Name)
  end
  portable:Destroy()
  verified += 1
 end
end
assert(verified == 13)
assert(world.Armies.U1:GetAttribute("SourceAsset") == "Mongol_HorseArcher")
assert(world.Settlements.novgorod:GetAttribute("SourceAsset") == "Rus timber hall")
assert(world["Regional landscape"]["Frontier palisade"]:GetAttribute("SourceAsset") == "Mongol_Fortress")
assert(#world["River Crossings"]:GetChildren() > 0)
for _, army in ipairs(world.Armies:GetChildren()) do
 local bounds = army:FindFirstChild("Selection bounds")
 assert(bounds and bounds.CanQuery and not bounds.CanCollide)
 assert(bounds:GetAttribute("TileId") == army:GetAttribute("TileId"))
end
print("[CP1 ART] 13 portable assets, 12 provinces, 18 roads, bridge, Rus hall, fortress and army hitboxes passed")
return verified
