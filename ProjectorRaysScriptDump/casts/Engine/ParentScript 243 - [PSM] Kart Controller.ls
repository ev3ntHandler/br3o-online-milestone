property p
global g

on new me, tTag
  p = [:]
  p[#tag] = tTag
  p[#ScriptLimit] = 0
  me.prepare()
  return me
end

on prepare me
  SetKartProps(p.tag)
  if g.KartHelpers = 1 then
    BuildKartHelpers(p.tag)
  end if
end

on enterFrame me
  if g.GameInput = 0 then
    if g.cars[p.tag].general.States.getPos(#UpdateKartMixer) <> 0 then
      UpdateKartMixer(p.tag)
    end if
    exit
  end if
  if (g.GameInput = 1) and (g.cars[p.tag].general.state = #Pending) then
    g.cars[p.tag].general.state = #Racing
  end if
  tList = g.cars[p.tag].general.States.duplicate()
  repeat with i in tList
    case i of
      #default:
        UpdateWayPoints(p.tag)
        UpdateLaps(p.tag)
        UpdateMaterials(p.tag)
      #InputKeys:
        InputKeys(p.tag)
      #UpdateAnimations:
        UpdateAnimations(p.tag)
      #updateEffects:
        updateEffects(p.tag)
      #Racing:
        Racing(p.tag)
      #UpdateHelpers:
        UpdateHelpers(p.tag)
      #ItemUse:
        ItemUse(p.tag)
      #Think:
        Think(p.tag)
      #Unstuck:
        Unstuck(p.tag)
      #Hit:
        Hit(p.tag)
      #UpdateKartMixer:
        UpdateKartMixer(p.tag)
    end case
  end repeat
end
