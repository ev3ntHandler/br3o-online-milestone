property p
global g

on new me, tParams
  p = [:]
  p[#controller] = tParams[#controller]
  p[#tag] = tParams[#tag]
  p[#car] = tParams[#car]
  p[#ScriptLimit] = 0
  p[#interface] = member("Interface")
  p[#Speedo] = p.interface.model("Speedometer")
  p[#Pointer] = p.interface.model("SpeedometerPointer")
  p[#SpeedoOrigT] = p.Speedo.transform.duplicate()
  p[#PointerOrigT] = p.Pointer.transform.duplicate()
  p[#me] = me
  return me
end

on enterFrame me
  pSpeedMS = g.cars[p.tag][#specifics][#speedMS]
  pSpeedKH = integer(abs(pSpeedMS) * 3600 / 1000)
  if pSpeedKH >= 0 then
    tOrigRotationZ = p.PointerOrigT.rotation.z
    tRotation = 130.0 * (pSpeedKH / 200.0)
    p.Pointer.transform.rotation.z = tOrigRotationZ - tRotation
  end if
end
