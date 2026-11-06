local C={}
C.Palette={steel=Color3.fromHex("2B3A4A"),gold=Color3.fromHex("DAA520"),snow=Color3.fromHex("E8ECEF"),wood=Color3.fromHex("5C4033"),steppe=Color3.fromHex("6B8E23"),ink=Color3.fromHex("18232F")}
C.FactionOrder={"mongol","rus","cuman","byzantine","seljuk","khwarazm"}
C.Factions={
 mongol={name="Mongol Khanate",color=Color3.fromHex("DAA520"),description="Mounted armies gain +1 movement. Steppe holdings yield extra food.",status="Playable",capital="Sarai"},
 rus={name="Rus' Principalities",color=Color3.fromHex("A52A2A"),description="Settlements gain +1 defense. Forest holdings yield extra timber.",status="AI opponent",capital="Novgorod"},
 cuman={name="Cumans / Kipchaks",color=Color3.fromHex("20B2AA"),description="Mobile light cavalry of the Wild Field.",status="Planned"},
 byzantine={name="Byzantine Empire",color=Color3.fromHex("800080"),description="Armored cataphracts and frontier defenses.",status="Planned"},
 seljuk={name="Seljuk Sultanate",color=Color3.fromHex("2B5B84"),description="Siegecraft and combined arms.",status="Planned"},
 khwarazm={name="Khwarazmshah Dynasty",color=Color3.fromHex("2E8B57"),description="Silk Road trade and royal lancers.",status="Planned"},
}
C.ResourceOrder={"gold","food","wood"}
C.Start={gold=34,food=27,wood=22}
C.UnitOrder={"archer","light","heavy","spear","infantry"}
C.Units={
 archer={name="Horse Archer",asset="Mongol_HorseArcher",hp=15,attack=7,defense=1,move=4,range=2,mounted=true,cost={gold=10,food=7}},
 light={name="Light Cavalry",asset="Mongol_LightCavalry",hp=17,attack=8,defense=2,move=4,range=1,mounted=true,cost={gold=9,food=7}},
 heavy={name="Heavy Cavalry",asset="Mongol_HeavyCavalry",hp=23,attack=10,defense=4,move=3,range=1,mounted=true,cost={gold=15,food=10,wood=3}},

return C
