global gSystem, gData, gGame

on createlight me, tTarget, tDataList
end

on SetLight me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tName = VOID
  if tDataList[#name].ilk = #string then
    tName = tDataList.name
  end if
  if tName = VOID then
    return 0
  end if
  tLight = tmember.light(tName)
  if tLight = VOID then
    return 0
  end if
  tType = tLight.type
  if tDataList[#type].ilk = #symbol then
    tList = [#ambient, #point, #spot, #directional]
    if tList.getPos(tDataList.type) <> 0 then
      tLight.type = tDataList.type
    end if
  end if
  if tLight.type = #ambient then
    if tDataList[#color].ilk = #color then
      tLight.color = tDataList.color
    end if
  end if
  if tLight.type = #directional then
    if tDataList[#color].ilk = #color then
      tLight.color = tDataList.color
    end if
    if tDataList[#specular].ilk = #integer then
      tLight.specular = tDataList.specular
    end if
  end if
  if tLight.type = #point then
    if tDataList[#color].ilk = #color then
      tLight.color = tDataList.color
    end if
    if tDataList[#specular].ilk = #integer then
      tLight.specular = tDataList.specular
    end if
    if tDataList[#attenuation].ilk = #vector then
      tLight.attenuation = tDataList.attenuation
    end if
  end if
  if tLight.type = #spot then
    if tDataList[#color].ilk = #color then
      tLight.color = tDataList.color
    end if
    if tDataList[#specular].ilk = #integer then
      tLight.specular = tDataList.specular
    end if
    if tDataList[#attenuation].ilk = #vector then
      tLight.attenuation = tDataList.attenuation
    end if
    if (tDataList[#spotAngle].ilk = #integer) or (tDataList[#spotAngle].ilk = #float) then
      tLight.spotAngle = tDataList.spotAngle
    end if
    if tDataList[#spotDecay].ilk = #integer then
      tLight.spotDecay = tDataList.spotDecay
    end if
  end if
  return 1
end

on deleteLight me, tTarget, tDataList
end
