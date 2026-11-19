local Policy={}
local clockFields={action=true,matchId=true,turn=true}
local allowed={
 status={action=true},
 start={action=true,faction=true},
 continue={action=true},
 save=clockFields,
 ["end"]=clockFields,
 move={action=true,matchId=true,turn=true,unit=true,tile=true},
 attack={action=true,matchId=true,turn=true,unit=true,target=true},
}
local function id(v)
 return type(v)=="string" and #v<=24 and v:match("^[%w_]+$")~=nil
end
local function ticket(v)
 return type(v)=="number" and v>=1 and v<=10^9 and v%1==0
end
function Policy.check(payload)
 if type(payload)~="table" or type(payload.action)~="string" then return false,"Invalid command." end
 local a=payload.action
 local fields=allowed[a]
 if not fields then return false,"This order is not available in Checkpoint 1." end
 for key in pairs(payload) do
  if not fields[key] then return false,"Unexpected command field. No change was made." end
 end
 if a=="start" then
  return payload.faction=="mongol","Checkpoint 1 is played as the Mongol Khanate."
 end
 if a~="status" and a~="continue" and (not ticket(payload.matchId) or not ticket(payload.turn)) then
  return false,"The order has no valid campaign or turn."
 end
 if a=="move" and (not id(payload.unit) or not id(payload.tile)) then return false,"Choose a valid army and province." end
 if a=="attack" and (not id(payload.unit) or not id(payload.target)) then return false,"Choose a valid army and target." end
 return true
end
return Policy
