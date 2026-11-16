property p
global g

on new me, tTag
  p = [:]
  p[#tag] = tTag
  p[#ScriptLimit] = 0
  p[#Cleared] = 0
  me.prepare()
  return me
end

on prepare me
  t = g.cars[p.tag]
  t.car[#WheelPartPos] = []
  repeat with i = 1 to 2
    t.car.WheelPartPos.add(member(t.car.name).group(t.car.name & "WheelPart" & i & "_Dummy").transform.position - member(t.car.name).model(t.car.name).transform.position)
  end repeat
  t.car[#ExhaustPartPos] = []
  repeat with i = 1 to 2
    t.car.ExhaustPartPos.add(member(t.car.name).group(t.car.name & "ExhaustPart" & i & "_Dummy").transform.position - member(t.car.name).model(t.car.name).transform.position)
  end repeat
  t.car[#WheelPart] = []
  repeat with i = 1 to 2
    pPart = CreateParticleSystem(t.general.member.name, [#type: #Wheel, #NameTag: string(p.tag)])
    pPart.transform.position = vector(0.0, 0.0, -150.0)
    pPart.parent = t.car.model
    pPart.transform.position = t.car.WheelPartPos[i]
    pPart.removeFromWorld()
    t.car.WheelPart.add(pPart)
  end repeat
  t.car[#ExhaustPart] = []
  repeat with i = 1 to 2
    pPart = CreateParticleSystem(t.general.member.name, [#type: #Exhaust, #NameTag: string(p.tag)])
    pPart.transform.position = vector(0.0, 0.0, -150.0)
    pPart.parent = t.car.model
    pPart.transform.position = t.car.ExhaustPartPos[i]
    t.car.ExhaustPart.add(pPart)
  end repeat
  t.car[#NitroPart] = []
  repeat with i = 1 to 2
    pPart = CreateParticleSystem(t.general.member.name, [#type: #Nitro, #NameTag: string(p.tag)])
    pPart.transform.position = vector(0.0, 0.0, -150.0)
    pPart.parent = t.car.model
    pPart.transform.position = t.car.ExhaustPartPos[i] - (t.car.model.transform.yAxis * 0.20000000000000001)
    pPart.removeFromWorld()
    t.car.NitroPart.add(pPart)
  end repeat
  t.general.States.add(#updateEffects)
end

on enterFrame me
end

on clear me
end
