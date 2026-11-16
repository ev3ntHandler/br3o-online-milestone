global gSystem, gLoader, gData, gSound, gGame

on ShowHideRoots me, t
  tSymbol = symbol(t.target.name)
  if voidp(gGame.cars[tSymbol]) = 1 then
    exit
  end if
  tRootList = gGame.cars[tSymbol].car.RootList
  tPreviousRootList = gGame.cars[tSymbol].car.previousRootList
  repeat with i in tPreviousRootList
    tgroup = t.member.group("TrackRoot" & i & "_Group")
    if tgroup <> VOID then
      tgroup.parent = VOID
    end if
  end repeat
  repeat with i in tRootList
    tgroup = t.member.group("TrackRoot" & i & "_Group")
    if tgroup <> VOID then
      tgroup.parent = gGame.member.group("World")
    end if
  end repeat
end

on BackwardsView me, t
  if voidp(gGame.cars[symbol(t.target.name)]) = 0 then
    if (gGame.cars[symbol(t.target.name)].input.backwardCam = 1) and (gGame.SlowMo = 0) then
      if t.OldOffSet = vector() then
        t.OldOffSet = t.offset
      end if
      if t.OldRotation = vector() then
        t.OldRotation = t.rotation
      end if
      tCar = gGame.cars[symbol(t.target.name)].general.data.car
      if (tCar = "Tank") or (tCar = "BlackTruck") or (tCar = "Apache") then
        t.offset = t.OldOffSet + vector(0, 16.0, 0.0)
        t.rotation = t.OldRotation - vector(2.0, 0.0, 180.0)
      else
        t.offset = t.OldOffSet + vector(0, 11.0, 0.0)
        t.rotation = t.OldRotation - vector(2.0, 0.0, 180.0)
      end if
    else
      if t.OldOffSet <> vector() then
        t.offset = t.OldOffSet
        t.rotation = t.OldRotation
        t.OldOffSet = vector()
        t.OldRotation = vector()
      end if
    end if
  end if
end

on DebugCameras me, t
  if voidp(gGame[#cars]) = 0 then
    tValue = value(_key.key)
    if (tValue.ilk <> #integer) or (tValue = 0) then
      return 0
    else
      if tValue <= gGame.cars.count then
        gGame.camera[1].target = gGame.cars[tValue].car.model
      end if
    end if
  end if
end

on SetFog me, tTarget, tDataList
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
  tCameraName = "DefaultView"
  if tDataList[#camera].ilk = #string then
    tCameraName = tDataList.camera
  end if
  tCamera = gGame.member.camera(tCameraName)
  if tCamera = VOID then
    return 0
  end if
  tCamera.fog.enabled = gGame.fog
  if gGame.fog = 0 then
    return 0
  end if
  if voidp(gGame[#FogRange]) = 1 then
    tRange = [0, 100]
  else
    tRange = gGame.FogRange
  end if
  if voidp(gGame[#fogColor]) = 1 then
    tColor = [0, 0, 0, 0]
  else
    tColor = gGame.fogColor
  end if
  tColor = rgb(tColor[1], tColor[2], tColor[3])
  if (gGame.name = "Burnin' Rubber 3") and (tRange[1] < 125) then
    tRange[1] = 125
  end if
  tCamera.fog.near = tRange[1]
  tCamera.fog.far = tRange[2]
  tCamera.fog.color = tColor
  tType = #linear
  if tDataList[#type].ilk = #symbol then
    tType = tDataList.type
  end if
  case tType of
    #linear:
      tCamera.fog.decayMode = tType
    #exponential:
      tCamera.fog.decayMode = tType
    #exponential2:
      tCamera.fog.decayMode = tType
    otherwise:
      tCamera.fog.decayMode = #linear
  end case
  return 1
end

on SetSkybox me, tTarget, tDataList
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return VOID
  end if
  tmember = member("Skyboxes")
  if tmember = VOID then
    return VOID
  end if
  tSkybox = tDataList[#skybox]
  if tSkybox = EMPTY then
    tSkybox = "Jungle"
  end if
  tDummy = member("Skyboxes").model("Skybox" & tSkybox & "_Dummy")
  if tDummy = VOID then
    alert("COULDNT FIND SKYBOX! SKYBOX WAS: " & tDataList.skybox)
    tDummy = member("Skyboxes").model("SkyboxCitySunny_Dummy")
  end if
  if member("Skyboxes").group("Skybox_Group") = VOID then
    member("Skyboxes").newGroup("Skybox_Group")
  end if
  tDummy.parent = member("Skyboxes").group("Skybox_Group")
  tCount = tmember.shader.count
  repeat with i = 1 to tCount
    tShader = tmember.shader[i]
    if tShader.name contains "Opaque" then
      tShader.transparent = 0
    end if
  end repeat
end

on AddCameraToSprite me, tTarget, tDataList
  if value(tTarget).ilk <> #integer then
    return 0
  end if
  tSprite = sprite(value(tTarget))
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tmember = VOID
  if tDataList[#member].ilk = #string then
    tmember = member(tDataList.member)
  end if
  if tmember = VOID then
    return 0
  end if
  tCameraName = VOID
  if tDataList[#camera].ilk = #string then
    tCameraName = tDataList.camera
  end if
  if tCameraName = VOID then
    return 0
  end if
  tCamera = tmember.camera(tCameraName)
  if tCamera = VOID then
    return 0
  end if
  tIndex = tSprite.cameraCount() + 1
  if tDataList[#index].ilk = #integer then
    tIndex = tDataList.index
  end if
  tSprite.addCamera(tCamera, tIndex)
end

on RemoveCameraFromSprite me, tTarget, tDataList
  if value(tTarget).ilk <> #integer then
    return 0
  end if
  tSprite = sprite(value(tTarget))
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tIndex = 0
  if tDataList[#index].ilk = #integer then
    tIndex = tDataList.index
  end if
  if tIndex = 0 then
    tCameraName = VOID
    if tDataList[#camera].ilk = #string then
      tCameraName = tDataList.camera
    end if
    if tCameraName = VOID then
      return 0
    end if
    tCount = tSprite.cameraCount()
    tIndex = 0
    repeat with i = 1 to tCount
      if tSprite.camera(i).name = tCameraName then
        tIndex = i
      end if
    end repeat
    if tIndex > 0 then
      tSprite.deleteCamera(tIndex)
    end if
  else
    if tIndex > 0 then
      tSprite.deleteCamera(tIndex)
    end if
  end if
end
