global gSystem, gData, gGame, gSound, g

on BuildCar me, tmember, tController, tCarName
  if tCarName = VOID then
    tCarName = "Default"
  end if
  if voidp(gData.data.cars[symbol(tCarName)]) = 1 then
    tCarName = "Default"
  end if
  tNr = gGame.cars.count + 1
  tData = gData.data.cars[symbol(tCarName)].duplicate()
  if tCarName = "Player" then
    tData[#name] = convertToUpperCase(0, gGame.PlayerName)
  else
    if (gGame.AIsBuild + 1) > gData.data.Names[symbol(tCarName)].count then
      tNameNr = 1
    else
      tNameNr = gGame.AIsBuild + 1
    end if
    tData[#name] = convertToUpperCase(0, gData.data.Names[symbol(tCarName)][tNameNr])
  end if
  if voidp(tData[#personality]) = 1 then
    if voidp(gData.data.personality[symbol(tCarName)]) = 1 then
      tData[#personality] = gData.data.personality.default.duplicate()
    else
      tData[#personality] = gData.data.personality[symbol(tCarName)].duplicate()
    end if
  else
    if voidp(gData.data.personality[symbol(tData.personality)]) = 1 then
      tData[#personality] = gData.data.personality.default.duplicate()
    else
      tData[#personality] = gData.data.personality[symbol(tData.personality)].duplicate()
    end if
  end if
  if voidp(tData[#bodyKit]) = 1 then
    if voidp(gData.data.bodyKit[symbol(tCarName)]) = 1 then
      tData[#bodyKit] = gData.data.bodyKit.default
    else
      tData[#bodyKit] = gData.data.bodyKit[symbol(tCarName)]
    end if
  else
    if voidp(gData.data.bodyKit[symbol(tData.bodyKit)]) = 1 then
      tData[#bodyKit] = gData.data.bodyKit.default
    else
      tData[#bodyKit] = gData.data.bodyKit[symbol(tData.bodyKit)]
    end if
  end if
  if voidp(tData[#upgrades]) = 1 then
    if voidp(gData.data.upgrades[symbol(tCarName)]) = 1 then
      tData[#upgrades] = gData.data.upgrades.default
    else
      tData[#upgrades] = gData.data.upgrades[symbol(tCarName)]
    end if
  else
    if voidp(gData.data.upgrades[symbol(tData.upgrades)]) = 1 then
      tData[#upgrades] = gData.data.upgrades.default
    else
      tData[#upgrades] = gData.data.upgrades[symbol(tData.upgrades)]
    end if
  end if
  if voidp(tData[#Weapons]) = 1 then
    if voidp(gData.data.Weapons[symbol(tCarName)]) = 1 then
      tData[#Weapons] = gData.data.Weapons.default
    else
      tData[#Weapons] = gData.data.Weapons[symbol(tCarName)]
    end if
  else
    if voidp(gData.data.Weapons[symbol(tData.Weapons)]) = 1 then
      tData[#Weapons] = gData.data.Weapons.default
    else
      tData[#Weapons] = gData.data.Weapons[symbol(tData.Weapons)]
    end if
  end if
  if voidp(tData[#settings]) = 1 then
    if voidp(gData.data.carsettings[symbol(tCarName)]) = 1 then
      tData[#settings] = gData.data.carsettings.default.duplicate()
    else
      tData[#settings] = gData.data.carsettings[symbol(tCarName)].duplicate()
    end if
  else
    if voidp(gData.data.carsettings[symbol(tData.settings)]) = 1 then
      tData[#settings] = gData.data.carsettings.default.duplicate()
    else
      tData[#settings] = gData.data.carsettings[symbol(tData.settings)].duplicate()
    end if
  end if
  tCarName = tData.car
  tChassisName = string(tController) & tNr & tCarName
  tReturnList = [#CarName: tCarName, #model: VOID, #Proxy: VOID, #shadowmodel: VOID, #modelList: [], #data: [:], #effectList: [:]]
  tData.personality.Health = tData.personality.Health + (tData.upgrades.Armor[1] * gGame.HealthUpgrade)
  tSpeedMS = gGame.EngineUpgrade[1] * 1000 / 3600
  tData.settings.maxSpeed = tData.settings.maxSpeed + (tData.upgrades.engine[1] * tSpeedMS)
  tData.settings.accGain = tData.settings.accGain + (tData.upgrades.engine[1] * gGame.EngineUpgrade[2])
  tData.settings.decGain = tData.settings.decGain + (tData.upgrades.engine[1] * gGame.EngineUpgrade[3])
  tCarMember = member(tData.car)
  if tCarMember = VOID then
    return tReturnList
  end if
  gGame[#setupCar] = tCarName
  gGame[#setupSkin] = tData.bodyKit.skin
  if tCarName = "Apache" then
    event("SetupApache")
  else
    event("SetupCars")
  end if
  gGame.deleteProp(#setupCar)
  gGame.deleteProp(#setupSkin)
  tWheelList = [tCarName & "Wheel_LB", tCarName & "Wheel_RB", tCarName & "Wheel_RF", tCarName & "Wheel_LF"]
  if (tData.bodyKit.Rims > 0) and (gGame.Bosses.getPos(symbol(tCarName)) = 0) then
    createTexture(tCarName, [#fileName: "Wheels_Texture"])
    ASSIGNTEXTURE(tCarName, [#material: tCarName & "Wheels_Material", #texture1: "Wheels_Texture"])
    tResource = tCarMember.modelResource(tCarName & "Rims" & tData.bodyKit.Rims)
    if tResource <> VOID then
      repeat with i in tWheelList
        tCarMember.model(i).resource = tResource
        tCarMember.model(i).shader = tCarMember.model(tWheelList[1]).shader
      end repeat
    end if
  end if
  tModelList = [tCarName, tCarName & "Proxy", tCarName & "Glass", tCarName & "Wheel_LB", tCarName & "Wheel_RB", tCarName & "Wheel_RF", tCarName & "Wheel_LF"]
  tCount = tData.bodyKit.count
  repeat with i = 1 to tCount
    tProp = tData.bodyKit.getPropAt(i)
    if (tProp = #skin) or (tProp = #Rims) then
      next repeat
      next repeat
    end if
    if tData.bodyKit[i] > 0 then
      tModelList.add(tCarName & string(tProp) & tData.bodyKit[i])
    end if
  end repeat
  if tCarName = "Apache" then
    tModelList.add("ApacheTopRotor")
    tModelList.add("ApacheBackRotor")
  end if
  tModelList = CloneModel(0, tmember.name, [#sourceMember: tCarName, #model: tModelList, #NameTag: string(tController) & tNr, #shaderTag: string(tController) & tNr, #textureTag: string(tController) & tNr, #lod: 0])
  tmodel = tModelList[1]
  tProxy = tModelList[2]
  repeat with i in tModelList
    if (i = tmodel) or (i = tProxy) then
      next repeat
      next repeat
    end if
    if gGame.Bosses.getPos(symbol(tCarName)) = 0 then
      if (i.name contains tCarName & "Wheel_RF") or (i.name contains tCarName & "Wheel_RB") then
        i.transform.scale.x = -i.transform.scale.x
      end if
    end if
    if i.name contains "Wheel" then
      next repeat
    end if
    if i.name contains "Rotor" then
      if i.name contains "TopRotor" then
        i.transform = member("Apache").model("Apache").getWorldTransform().inverse() * member("Apache").model("ApacheTopRotor").transform
      end if
      if i.name contains "BackRotor" then
        i.transform = member("Apache").model("Apache").getWorldTransform().inverse() * member("Apache").model("ApacheBackRotor").transform
      end if
      i.parent = tmodel
      next repeat
    end if
    i.transform.position = vector(0, 0, 0)
    i.parent = tmodel
  end repeat
  if tCarName <> "Apache" then
    tShaderList = [tmember.shader(string(tController) & tNr & tCarName & "_Material"), tmember.shader(string(tController) & tNr & tCarName & "Glass_Material"), tmember.shader(string(tController) & tNr & tCarName & "Wheels_Material")]
    repeat with i in tShaderList
      if i.name contains "Wheel" then
        i.shininess = 0.0
      else
        i.shininess = 45.0
      end if
      i.specular = rgb(255, 255, 255)
    end repeat
  end if
  tShadowResource = tmember.modelResource("SimpleShadow")
  if tShadowResource = VOID then
    CLONEMODELS(tmember, [#cloneMember: member("SimpleShadow")])
    tmember.deleteModel("SimpleShadow")
    tmember.deleteShader("SimpleShadow_Material")
  end if
  tShadowResource = tmember.modelResource("SimpleShadow")
  tShadowModel = tmember.newModel(tChassisName & "Shadow", tShadowResource)
  tShadowModel.transform.scale = vector(1, 1, 1) * gGame.ShadowScale[symbol(tCarName)]
  tShadowModel.transform.scale.x = tShadowModel.transform.scale.x
  tShadowModel.transform.position = vector(0, 0, 0.01)
  tShadowShader = CreateShader(0, tmember.name, [#shader: tChassisName & "Shadow_Material", #texture: tCarName & "Shadow_Texture", #blend: 75.0])
  tShadowModel.shaderList = tShadowShader
  tModelList.add(tShadowModel)
  tEffectlist = [#primary: [], #secondary: [], #smoke: [], #Nitro: []]
  tgroup = tmember.newGroup(tChassisName & "Smoke")
  tgroup.transform.position = tCarMember.model(tCarName).transform.position
  tgroup.parent = tmodel
  tgroup.transform.position = tCarMember.group(tCarName & "Smoke_Dummy").transform.position - tCarMember.model(tCarName).transform.position
  tEffectlist.smoke.add(tgroup)
  repeat with i = 1 to 4
    tDummy = tCarName & "Nitro" & i & "_Dummy"
    if tCarMember.group(tDummy) = VOID then
      exit repeat
    end if
    tgroup = tmember.newGroup(tChassisName & "Nitro" & i & "_Dummy")
    tgroup.parent = tmodel
    tdiff = tCarMember.group(tDummy).transform.position - tCarMember.model(tCarName).transform.position
    tgroup.transform.position = tdiff
    tEffectlist.Nitro.add(tgroup)
  end repeat
  if tmember.modelResource("Nitro") = VOID then
    event(#SetupNitro)
    CloneModel(0, tmember.name, [#sourceMember: "Nitro", #lod: 0, #delete: 1])
  end if
  tNitroModels = []
  repeat with i = 1 to tEffectlist.Nitro.count
    tName = tChassisName & "Nitro" & i
    tNitro = tmember.newModel(tName, tmember.modelResource("Nitro"))
    tNitro.shader = tmember.shader("Nitro_Material")
    tNitro.parent = VOID
    tNitroModels.add(tNitro)
  end repeat
  member(tCarName).resetWorld()
  tReturnList = [#CarName: tCarName, #model: tmodel, #Proxy: tProxy, #shadowmodel: tShadowModel, #modelList: tModelList, #nitroModels: tNitroModels, #data: tData, #effectList: tEffectlist]
  return tReturnList
end

on GetStartPositionRotation me, tData
  tOrigData = tData.duplicate()
  tData = tData.duplicate()
  tData.deleteProp(#car)
  tResult = [vector(), [vector(0, 1, 0), 180.0]]
  if tData.position.ilk = #vector then
    tResult[1] = tData.position + vector(0, 0, 0.69999999999999996)
  end if
  if tData.position = #waypoint then
    tData.position = [integer(gGame.WayPointList[1].count / 2), 1]
  end if
  if tData.position.ilk = #integer then
    tData.position = [tData.position, 1]
  end if
  if tData.position.ilk = #list then
    if tData.position[2] = 0 then
      tData.position[2] = 1
    end if
    if tData.position[1] = 0 then
      tData.position[1] = integer(gGame.WayPointList[tData.position[2]].count / 2)
    end if
    if tData.position[1] = 0 then
      tData.position[1] = 1
    end if
  end if
  if tData.position.ilk = #list then
    tOffsetPos = 1
    repeat with i in gGame.cars
      tOtherData = [#position: i.general.buildData.position, #orientation: i.general.buildData.orientation]
      if tOtherData.position = tOrigData.position then
        tOffsetPos = tOffsetPos + 1
      end if
    end repeat
    if gGame.WayPointList[tData.position[2]].count > 0 then
      tTransform = gGame.WayPointList[tData.position[2]][tData.position[1]].duplicate()
    else
      tTransform = transform()
    end if
    tVector = tTransform.position
    tOdd = tOffsetPos mod 2
    if tOdd = 1 then
      tVector = tVector - (tTransform.xAxis * 2.0)
    else
      tVector = tVector + (tTransform.xAxis * 2.0)
    end if
    if tOffsetPos > 2 then
      tMult = integer(tOffsetPos / 2.0) - 1
      tVector = tVector + (-tTransform.yAxis * (7.0 * tMult))
    end if
    tRayDetails = gGame.Physics.rayCastClosest(tVector + vector(0, 0, 50), vector(0, 0, -1.00099999999999989))
    if tRayDetails.count > 0 then
      tVector.z = tRayDetails[2].z
    end if
    tVector.z = tVector.z + 0.69999999999999996
    tResult[1] = tVector
  end if
  tAxisAngle = [vector(0, 1, 0), 0]
  if tData.orientation = #waypoint then
    tData.orientation = [integer(gGame.WayPointList[1].count / 2), 1]
  end if
  if tData.orientation.ilk = #integer then
    tData.orientation = [tData.orientation, 1]
  end if
  if tData.orientation.ilk = #list then
    if tData.orientation.count = 4 then
      q = tData.orientation
      tAngle = 2 * atan(sqrt(1.0 - (q[4] * q[4])), q[4]) * 180 / PI
      t = sqrt(1 - (q[4] * q[4]))
      if t = 0 then
        tVector = vector(0, 1, 0)
      else
        x = q[1] / sqrt(1 - (q[4] * q[4]))
        y = q[2] / sqrt(1 - (q[4] * q[4]))
        z = q[3] / sqrt(1 - (q[4] * q[4]))
        tVector = vector(x, z, y)
      end if
      tAxisAngle = [tVector, tAngle]
    else
      if tData.orientation[2] = 0 then
        tData.orientation[2] = 1
      end if
      if tData.orientation[1] = 0 then
        tData.orientation[1] = integer(gGame.WayPointList[tData.orientation[2]].count / 2)
      end if
      if gGame.WayPointList[tData.position[2]].count > 0 then
        tTransform = gGame.WayPointList[tData.position[2]][tData.position[1]].duplicate()
      else
        tTransform = transform()
      end if
      tAxisAngle = tTransform.axisAngle
    end if
  end if
  tResult[2] = tAxisAngle
  return tResult
end

on ResetStates me, t
  if t = VOID then
    t = gGame.cars[gGame.currentCar]
  end if
  tList = t.general.States.duplicate()
  SetItemDelimiter("_")
  repeat with i in tList
    tString = string(i)
    if i = #update_tank then
      tHandler = #reset_tank
    else
      if i = #update_war then
        tHandler = #reset_war
      else
        tHandler = symbol("reset_" & tString.item[2])
      end if
    end if
    sendSprite(0, tHandler, t)
  end repeat
  ResetItemDelimiter()
end

on StopAllCars me, t
  repeat with i in gGame.cars
    if (i.race.state = #Finished) or (i.race.state = #Dead) then
      next repeat
      next repeat
    end if
    gGame.currentCar = i.general.tag
    gGame.currentController = i.general.controller
    event(#FinishCar)
    gGame.currentCar = #none
    gGame.currentController = #none
  end repeat
end

on setup_WayPoints me, t
  nothing()
end

on update_WayPoints me, t
  if voidp(gGame[#WayPointList]) = 1 then
    exit
  end if
  if gGame.WayPointList.count = 0 then
    exit
  end if
  if t.car.currentRootNr <> t.car.previousRootNR then
    tWayPointList = gGame.WayPointList[t.car.currentRootNr].duplicate()
    if t.car.currentRootNr < gGame.WayPointList.count then
      tList = gGame.WayPointList[t.car.currentRootNr + 1].duplicate()
      repeat with i in tList
        tWayPointList.add(i)
      end repeat
    end if
    t.car.previousRootNR = t.car.currentRootNr
    t.race.WayPointList = tWayPointList
  end if
  tPreviousD = 250.0
  tCarPos = t.car.model.worldPosition
  repeat with i in t.race.WayPointList
    TD = i.position.distanceTo(tCarPos)
    if TD < tPreviousD then
      t.race.waypoint = t.race.WayPointList.getPos(i)
      t.race.WaypointDistance = TD
      t.race.WaypointT = i
      tPreviousD = TD
    end if
  end repeat
  tTarget = t.race.waypoint + 1
  if tTarget > t.race.WayPointList.count then
    tTarget = t.race.WayPointList.count
  end if
  tTransform = t.race.WayPointList[tTarget].duplicate()
  tVector = LineLineIntersect(t.car.transform.duplicate(), tTransform, tTransform.yAxis, #x)
  tVector.z = t.car.transform.position.z
  t.race.perpVector = tVector
  t.race.perpDistance = (t.car.transform.position - tVector).length
  tSymbol = symbol("TrackRoot" & t.car.currentRootNr & "_Group")
  if voidp(gGame.checkpointList[tSymbol]) = 0 then
    tList = gGame.checkpointList[tSymbol]
  else
    tList = []
  end if
  repeat with i in tList
    tTransform1 = i.duplicate()
    tTransform2 = t.car.previousT.duplicate()
    tAxis = tTransform2.position - t.car.model.transform.position
    tAxis.normalize()
    pInt = LineLineIntersect(tTransform1, tTransform2, #x, tAxis)
    pPoint1 = point(t.car.previousT.position.x, t.car.previousT.position.y)
    pPoint2 = point(t.car.model.transform.position.x, t.car.model.transform.position.y)
    pXList = [pInt.x, pPoint1.locH, pPoint2.locH]
    pYList = [pInt.y, pPoint1.locV, pPoint2.locV]
    pXList.sort()
    pYList.sort()
    gGame.currentCar = t.general.tag
    gGame.currentController = t.general.controller
    if (pXList[2] = pInt.x) and (pYList[2] = pInt.y) then
      event(#Checkpoint)
    end if
    if t.race.CheckPoints = gGame.checkpointList.count then
      event(#FinishCar)
      tState = 1
    end if
    gGame.currentCar = #none
    gGame.currentController = #none
  end repeat
  tZDistance = abs(t.race.WayPointList[t.race.waypoint].position.z - tCarPos.z)
  if tCarPos.z < t.race.WayPointList[t.race.waypoint].position.z then
    tZDistance = -tZDistance
  end if
  t.race.waypointZ = tZDistance
  if t.general.controller = #player then
    tTransform2 = t.car.model.getWorldTransform().duplicate()
    pos1 = t.race.perpVector - tTransform2.position
    pos1.normalize()
    pos2 = tTransform2.yAxis
    pFrontBack = pos1.dot(pos2)
    if pFrontBack < -0.14999999999999999 then
      t.race.wrongWayCounter = t.race.wrongWayCounter + 1
    else
      t.race.wrongWayCounter = 0
    end if
    if t.race.wrongWayCounter >= 10 then
      SETVISIBLE(0, gGame.InterfaceName, [#model: "WrongWayStatus", #parent: "Hud", #state: 1])
    else
      if member(gGame.InterfaceName).model("WrongWayStatus").isInWorld() then
        SETVISIBLE(0, gGame.InterfaceName, [#model: "WrongWayStatus", #state: 0])
      end if
    end if
  end if
  return tState
end

on reset_waypoints me, t
  t.general.States.deleteOne(#update_WayPoints)
end

on setup_items me, t
end

on update_items me, t
  tCurrentTile = t.car.currentRootNr
  tItemList = gGame.member.group("TrackRoot" & tCurrentTile & "_Group").userData.Pickups
  tList = []
  the itemDelimiter = "_"
  repeat with i in tItemList
    i.pointAt(gGame.camera[1].transform.position, vector(0, 0, 1))
    tDistance = i.worldPosition.distanceTo(t.car.transform.position)
    if tDistance < 3.0 then
      gGame.currentCar = t.general.tag
      if i.name contains "Detonator" then
        Detonate(0, i, t.general.tag)
      end if
      event(symbol(i.name.item[2] & "Pickup"))
      tList.add(i)
    end if
  end repeat
  repeat with i in tList
    tName = i.name
    tItemList.deleteOne(i)
    gGame.member.deleteModel(tName)
  end repeat
  the itemDelimiter = TAB
  if tCurrentTile < gGame.RootList.count then
    tNextTile = tCurrentTile + 1
    tItemList = gGame.member.group("TrackRoot" & tNextTile & "_Group").userData.Pickups
    repeat with i in tItemList
      i.pointAt(gGame.camera[1].transform.position, vector(0, 0, 1))
    end repeat
  end if
end

on reset_items me, t
  t.general.States.deleteOne(#update_items)
end

on setup_keyInput me, t
  if gGame[#joystick] = VOID then
    gGame[#joystick] = xtra("joystick").new()
  end if
  t.input[#joystick] = gGame.joystick.numberOfJoy() > 0
  t.input[#ForceToggleJoystick] = 0
  tKeySets = [gGame.PlayerKeys1, gGame.PlayerKeys2]
  tKeys = 1
  repeat with i in gGame.cars
    if i.general.controller = #player then
      tKeySet = tKeySet + 1
    end if
  end repeat
  t.input[#keySet] = tKeySet
  t.input[#Keys] = tKeySets[tKeySet]
  tCount = t.input.Keys.count
  repeat with i = 1 to tCount
    tProp = t.input.Keys.getPropAt(i)
    t.input[tProp] = 0
  end repeat
  t.input[#leftPerc] = 1.0
  t.input[#rightPerc] = 1.0
  t.input[#deadZone] = 6000
end

on update_keyInput me, t
  if gGame.input = 0 then
    exit
  end if
  t.input[#joystick] = gGame.joystick.numberOfJoy() > 0
  if t.input.ForceToggleJoystick = 1 then
    t.input.joystick = 0
  end if
  if t.input.joystick = 1 then
    gGame.joystick.useJoy(1)
  end if
  t.input.forward = _key.keyPressed(t.input.Keys.forward)
  if t.input.forward = 0 then
    t.input.forward = _key.keyPressed("w")
  end if
  if (t.input.joystick = 1) and (t.input.forward = 0) then
    if gGame.joystick.zPos() <= (32768 - 4096) then
      t.input.forward = 1
    else
      t.input.forward = 0
    end if
  end if
  t.input.backward = _key.keyPressed(t.input.Keys.backward)
  if t.input.backward = 0 then
    t.input.backward = _key.keyPressed("s")
  end if
  if (t.input.joystick = 1) and (t.input.backward = 0) then
    if gGame.joystick.zPos() >= (32768 + 4096) then
      t.input.backward = 1
    else
      t.input.backward = 0
    end if
  end if
  t.input.left = _key.keyPressed(t.input.Keys.left)
  if t.input.left = 0 then
    t.input.left = _key.keyPressed("a")
  end if
  if t.input.left = 1 then
    t.input.leftPerc = 1.0
  else
    if (t.input.joystick = 1) and (t.input.left = 0) then
      if gGame.joystick.xPos() <= (32768 - t.input[#deadZone]) then
        t.input.left = 1
      else
        t.input.left = 0
      end if
      if t.input.left = 1 then
        t.input.leftPerc = (32768.0 - t.input.deadZone - gGame.joystick.xPos()) / (32768.0 - 6000)
      else
        t.input.leftPerc = 0.0
      end if
    end if
  end if
  t.input.right = _key.keyPressed(t.input.Keys.right)
  if t.input.right = 0 then
    t.input.right = _key.keyPressed("d")
  end if
  if t.input.right = 1 then
    t.input.rightPerc = 1.0
  else
    if (t.input.joystick = 1) and (t.input.right = 0) then
      if gGame.joystick.xPos() >= (32768 + t.input[#deadZone]) then
        t.input.right = 1
      else
        t.input.right = 0
      end if
      if t.input.right = 1 then
        t.input.rightPerc = (gGame.joystick.xPos() - t.input.deadZone - 32768.0) / (32768.0 - 6000)
      else
        t.input.rightPerc = 0.0
      end if
    end if
  end if
  if t.input.Keys.brake = "Shift" then
    t.input.brake = _key.shiftDown
  else
    t.input.brake = _key.keyPressed(t.input.Keys.brake)
  end if
  if (t.input.joystick = 1) and (t.input.brake = 0) then
    t.input.brake = gGame.joystick.button(2)
  end if
  if (t.input.joystick = 1) and (t.input.brake = 0) then
    t.input.brake = gGame.joystick.button(6)
  end if
  t.input.action1 = _key.keyPressed(t.input.Keys.action1)
  if t.input.action1 = 0 then
    t.input.action1 = _key.keyPressed(128)
  end if
  if (t.input.joystick = 1) and (t.input.action1 = 0) then
    t.input.action1 = gGame.joystick.button(1)
  end if
  t.input.action2 = _key.keyPressed(t.input.Keys.action2)
  if t.input.action2 = 0 then
    t.input.action2 = _key.keyPressed(129)
  end if
  if (t.input.joystick = 1) and (t.input.action2 = 0) then
    t.input.action2 = gGame.joystick.button(3)
  end if
  t.input.backwardCam = _key.keyPressed(t.input.Keys.backwardCam)
  if (t.input.joystick = 1) and (t.input.backwardCam = 0) then
    t.input.backwardCam = gGame.joystick.button(4)
  end if
end

on ForceToggleJoystick me
  if voidp(gGame) then
    return 
  end if
  if voidp(gGame[#cars]) then
    return 
  end if
  t = gGame.cars[1]
  if t.input.ForceToggleJoystick = 1 then
    t.input.ForceToggleJoystick = 0
  else
    if t.input.ForceToggleJoystick = 0 then
      t.input.ForceToggleJoystick = 1
    end if
  end if
end

on reset_keyInput me, t
  t.input.forward = 0
  t.input.backward = 0
  t.input.left = 0
  t.input.right = 0
  t.input.brake = 0
  t.input.action1 = 0
  t.input.action2 = 0
  t.input.backwardCam = 0
  t.general.States.deleteOne(#update_keyInput)
end

on setup_JoyInput me, t
  if gGame[#joystick] = VOID then
    gGame[#joystick] = xtra("joystick").new()
  end if
  tNumberOfJoy = gGame.joystick.numberOfJoy()
  if tNumberOfJoy > 0 then
    tNr = 1
    repeat with i in gGame.cars
      if voidp(i.input[#joystick]) = 0 then
        if i.input.joystick = 1 then
          tNr = tNr + 1
        end if
      end if
    end repeat
    t.input[#JoyNr] = tNr
    t.input[#leftPerc] = 0.0
    t.input[#rightPerc] = 0.0
    t.input[#joystick] = 1
  else
    gGame.joystick = VOID
    gGame.deleteProp(#joystick)
    t.input[#joystick] = 0
  end if
  t.input[#forward] = 0
  t.input[#backward] = 0
  t.input[#left] = 0
  t.input[#right] = 0
  t.input[#brake] = 0
  t.input[#action1] = 0
  t.input[#action2] = 0
  t.input[#backwardCam] = 0
end

on update_joyInput me, t
  if gGame.input = 0 then
    exit
  end if
  gGame.joystick.useJoy(t.input.JoyNr)
  t.input.forward = gGame.joystick.button(2)
  t.input.backward = gGame.joystick.button(4)
  if gGame.joystick.xPos() <= (32768 - 4096) then
    tLeft = 1
  else
    tLeft = 0
  end if
  t.input.left = tLeft
  t.input.leftPerc = (32768.0 - gGame.joystick.xPos()) / 32768.0
  if gGame.joystick.xPos() >= (32768 + 4096) then
    tRight = 1
  else
    tRight = 0
  end if
  t.input.right = tRight
  t.input.rightPerc = (gGame.joystick.xPos() - 32768.0) / 32768.0
  t.input.brake = gGame.joystick.button(6)
  t.input.action1 = gGame.joystick.button(1)
  t.input.action2 = gGame.joystick.button(3)
  t.input.backwardCam = gGame.joystick.button(5)
end

on reset_joyInput me, t
  t.general.States.deleteOne(#update_joyInput)
end

on setup_Racing me, t
  t.input[#joystick] = 0
  tCount = gGame.PlayerKeys1.count
  repeat with i = 1 to tCount
    tProp = gGame.PlayerKeys1.getPropAt(i)
    t.input[tProp] = 0
  end repeat
end

on update_Racing me, t
  t.race.Leader.worldPosition = t.car.Proxy.worldPosition
  tTarget = t.race.waypoint + 5
  if tTarget > t.race.WayPointList.count then
    tTarget = t.race.WayPointList.count
  end if
  tTotalAmount = 0
  tStartDiff = 0.0
  tChassisAxis = abs(t.car.model.transform.axisAngle[2])
  repeat with i = 1 to 15
    tNr = t.race.waypoint + i
    if tNr > t.race.WayPointList.count then
      tNr = t.race.WayPointList.count
    end if
    tPointAtPos = t.race.WayPointList[tNr].position
    tPointAtPos.z = t.race.Leader.transform.position.z
    if tPointAtPos = t.race.Leader.transform.position then
      tDifference = 0.0
    else
      t.race.Leader.pointAt(tPointAtPos, vector(0.0, 0.0, 1.0))
      tLeaderHelperAxis = abs(t.race.Leader.transform.axisAngle[2])
      tDifference = abs(tLeaderHelperAxis - tChassisAxis)
    end if
    tTotalAmount = tTotalAmount + tDifference
    if i = tTarget then
      tStartDiff = tDifference
    end if
  end repeat
  tGenDiff = tTotalAmount / 15
  tBrakingDifference = abs(tStartDiff - tGenDiff)
  if tBrakingDifference > 15.0 then
    t.input.brake = 1
  else
    t.input.brake = 0
  end if
  if (tBrakingDifference > 20.0) and (t.car.Speed >= 25.0) then
    t.input.forward = 0
  else
    t.input.forward = 1
  end if
  tPointAtPos = t.race.WayPointList[tTarget].position
  tPointAtPos.z = t.race.Leader.transform.position.z
  if tPointAtPos = t.race.Leader.transform.position then
    tDifference = 0.0
  else
    t.race.Leader.pointAt(tPointAtPos, vector(0.0, 0.0, 1.0))
    tLeaderHelperAxis = abs(t.race.Leader.transform.axisAngle[2])
    tDifference = abs(tLeaderHelperAxis - tChassisAxis)
  end if
  tLeftRight = LeftOrRight(t.race.WayPointList[tTarget], t.car.Proxy.transform)
  t.input.right = 0
  t.input.left = 0
  if tDifference > 3.5 then
    if tLeftRight[2] < 0.0 then
      t.input.left = 1
    else
      t.input.right = 1
    end if
  end if
  if gGame.RaceState <> #Pending then
    t.race.stuckCounter = t.race.stuckCounter + 1
    if (t.race.stuckCounter * gGame.tempo) >= gGame.AIStuckTime then
      tDistance = t.race.stuckPosition.distanceTo(t.car.model.worldPosition)
      if tDistance <= 1.0 then
        t.general.script.reset(t, 1, 0)
      else
        t.race.stuckPosition = t.car.model.worldPosition
      end if
      t.race.stuckCounter = 0
    end if
  end if
end

on reset_racing me, t
  t.input.forward = 0
  t.input.backward = 0
  t.input.left = random(0, 1)
  t.input.right = random(0, 1)
  t.input.brake = 0
  t.input.action1 = 0
  t.input.action2 = 0
  t.input.backwardCam = 0
  t.general.States.deleteOne(#update_Racing)
end

on setup_Damage me, t
  t.car[#Health] = t.general.data.personality.Health
  t.car[#HealthStates] = [t.car.Health * 0.29999999999999999, t.car.Health * 0.59999999999999998]
  t.car[#damageState] = 0
  t.car[#impacts] = []
  t.car[#previousMomentum] = vector()
end

on update_Damage me, t
  tDetails = gGame.collisionReports[symbol(t.car.Proxy.name)]
  t.car.collisionDetails = tDetails.duplicate()
  if tDetails.count > 0 then
    tVelocity = (t.car.PhysicsCar.linearMomentum - t.car.previousMomentum).length
    a = tVelocity / t.car.mass
    tForce = t.car.mass * a * 0.00003
    t.car.Health = t.car.Health - tForce
    gGame.collisionReports[symbol(t.car.Proxy.name)] = []
    if t.general.controller = #player then
      if tForce >= 0.10000000000000001 then
        PlaySound("Bump_SFX", [#priority: #low, #rateShift: random(-6, 8), #surround: 1, #member3DName: gGame.member.name, #sender: t.car.model.name, #targetName: t.car.model.name, #referenceName: "Player1_Camera", #distance: [0, 20], #static: 1])
      end if
      if tForce >= 0.75 then
        PlaySound("Clunk", [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #random: [1, 3], #sender: t.car.model.name, #targetName: t.car.model.name, #referenceName: "Player1_Camera", #distance: [0, 20], #static: 1])
      end if
    end if
  end if
  t.car.previousMomentum = t.car.PhysicsCar.linearMomentum
  tList = t.car.impacts.duplicate()
  tEnemy = VOID
  repeat with i in tList
    t.car.Health = t.car.Health - i[1]
    t.car.impacts.deleteOne(i)
    if i.count = 3 then
      tEnemy = i[3]
    end if
  end repeat
  if t.car.Health <= 0 then
    if string(tEnemy) contains "player" then
      gGame.Statistics.rivalWrecked = gGame.Statistics.rivalWrecked + 1
    end if
    if t.general.controller = #player then
      gGame.Statistics.Wrecked = gGame.Statistics.Wrecked + 1
    end if
    CheckTrophies()
    PlaySound("Explosion_SFX", [#priority: #high, #surround: 1, #member3DName: gGame.member.name, #sender: t.car.Proxy.name, #targetName: t.car.Proxy.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 0])
    t.car.model.visibility = #both
    pRandomVector = randomVector()
    tImp = vector(pRandomVector.x * 1000, pRandomVector.y * 1000, 45000.0)
    tTorque = vector(pRandomVector.x * 450000, pRandomVector.y * 450000, pRandomVector.z * 550000)
    tImp2 = vector(pRandomVector.x * 70, pRandomVector.y * 70, 500.0)
    tTorque2 = vector(pRandomVector.x * 250, pRandomVector.y * 250, pRandomVector.z * 250)
    t.car.PhysicsCar.applyLinearImpulse(tImp)
    t.car.PhysicsCar.applyTorque(tTorque)
    repeat with i in t.car.wheellist
      tTransform = i.getWorldTransform()
      i.parent = gGame.member.group("World")
      i.transform = tTransform
      i.addModifier(#meshDeform)
      pRB = gGame.Physics.createRigidBody(i.name, i.name, #convexShape, #dynamic)
      pRB.restitution = 0.20000000000000001
      pRB.friction = 0.5
      pRB.mass = 20.0
      pRB.linearVelocity = t.car.PhysicsCar.linearVelocity * 0.69999999999999996
      pRB.applyLinearImpulse(tImp2)
      pRB.applyTorque(tTorque2)
      i.removeModifier(#meshDeform)
    end repeat
    tCount = t.car.model.child.count
    repeat with i = 1 to tCount
      tChild = t.car.model.child[i]
      if tChild.ilk <> #model then
        next repeat
      end if
      tChild.addModifier(#meshDeform)
      tPos = tChild.worldPosition
      tChild.parent = gGame.member.group("World")
      tChild.transform.position = tPos
      pRB = gGame.Physics.createRigidBody(tChild.name, tChild.name, #convexShape, #dynamic)
      pRB.restitution = 0.20000000000000001
      pRB.friction = 0.5
      pRB.mass = 20.0
      pRB.linearVelocity = t.car.PhysicsCar.linearVelocity * 0.69999999999999996
      pRB.applyLinearImpulse(tImp2)
      pRB.applyTorque(tTorque2)
      tChild.removeModifier(#meshDeform)
    end repeat
    if gGame.Effects = #high then
      tDebrisList = []
      repeat with i = 1 to 12
        tNewModel = gGame.member.newModel(t.general.tag & "Debris" & i, gGame.member.modelResource("Debris" & i))
        tNewModel.transform.position = t.car.model.worldPosition + (randomVector() * 2)
        tNewModel.shaderList = gGame.member.shader("Debris_Material")
        tNewModel.addModifier(#meshDeform)
        tName = t.general.tag & "Debris" & i
        pRB2 = gGame.Physics.createRigidBody(tName, tName, #box, #dynamic)
        pRB2.restitution = 0.20000000000000001
        pRB2.friction = 0.5
        pRB2.mass = 20.0
        pRB2.linearVelocity = t.car.PhysicsCar.linearVelocity * 1.10000000000000009
        pRB2.applyLinearImpulse(tImp2)
        pRB2.applyTorque(tTorque2)
        tNewModel.removeModifier(#meshDeform)
        if (random(1, 2) = 1) and (tDebrisList.count <> 3) then
          tDebrisList.add(tNewModel)
        end if
      end repeat
    end if
    tExploScript = new(script("[PS] Explosion"), gGame.member, #none, gGame.member.camera("PLayer1_camera"), t.car.model.name, 8000, vector(), t.car.PhysicsCar, tDebrisList)
    if tExploScript <> VOID then
      gGame.scriptList.add(tExploScript)
    end if
    t.car.Health = 0
    gGame.currentCar = t.general.tag
    gGame.currentController = t.general.controller
    event(#KillCar)
    gGame.currentCar = #none
    gGame.currentController = #none
    if t.general.controller = #player then
      gGame.camera[t.camera.index].offset = vector(0.0, -20.0, 0.0)
      gGame.camera[t.camera.index].rotation = vector(90.0, 0.0, 0.0)
      event("ImpactTimeOn")
    end if
  end if
  if t.car.Health < t.car.HealthStates.max() then
    if t.car.Health <= 0 then
      tState = 3
    else
      if t.car.Health < t.car.HealthStates.min() then
        tState = 2
      else
        tState = 1
      end if
    end if
    if t.car.damageState <> tState then
      tTexture = t.car.model.shader.texture
      tmember = tTexture.member
      tImage = tmember.image.duplicate()
      tImage.copyPixels(member("CarDamage" & tState & "_Texture").image, tImage.rect, tImage.rect)
      tTexture.image = tImage
      tNormalShader = gGame.member.shader(string(t.general.tag) & "_Material")
      tGlassShader = gGame.member.shader(string(t.general.tag) & "Glass_Material")
      if t.car.shaderList.getPos(tNormalShader) <> 0 then
        tNormalShader.textureList[2] = VOID
      end if
      if t.car.shaderList.getPos(tGlassShader) <> 0 then
        tGlassShader.textureList[2] = VOID
      end if
      if tState = 2 then
        t.car[#smoke] = CreateParticleSystem(gGame.member.name, [#type: #EngineSmoke, #NameTag: string(t.general.tag)])
      end if
      t.car.damageState = tState
      if tState = 1 then
        PlaySound("Crash", [#priority: #medium, #surround: 1, #member3DName: gGame.member.name, #random: [1, 3], #sender: t.car.model.name, #targetName: t.car.model.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1])
      end if
      if tState = 2 then
        PlaySound("Crash", [#priority: #medium, #surround: 1, #member3DName: gGame.member.name, #random: [1, 3], #sender: t.car.model.name, #targetName: t.car.model.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1])
        PlaySound("CrashGlass", [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #rateShift: random(-4, 4), #sender: t.car.model.name, #targetName: t.car.model.name, #referenceName: "Player1_Camera", #distance: [20, 100], #static: 1])
      end if
    end if
    if tState = 2 then
      t.car.smoke.resource.emitter.region = [t.car.Effects.smoke[1].getWorldTransform().position]
    end if
  else
    if t.car.damageState <> 0 then
      tTexture = t.car.model.shader.texture
      tmember = tTexture.member
      tImage = tmember.image.duplicate()
      tOrigMember = member(t.car.name & "Skin" & t.general.data.bodyKit.skin & "_Texture")
      tImage.copyPixels(tOrigMember.image, tImage.rect, tImage.rect)
      tTexture.image = tImage
      tNormalShader = gGame.member.shader(string(t.general.tag) & "_Material")
      tGlassShader = gGame.member.shader(string(t.general.tag) & "Glass_Material")
      tTexture = string(t.general.controller) & t.general.player & "CarReflection_Texture"
      if t.car.shaderList.getPos(tNormalShader) <> 0 then
        tNormalShader.textureList[2] = gGame.member.texture(tTexture)
      end if
      if t.car.shaderList.getPos(tGlassShader) <> 0 then
        tGlassShader.textureList[2] = gGame.member.texture(tTexture)
      end if
      if (t.car.name = "APache") and (t.car.shaderList.getPos(tNormalShader) <> 0) then
        tNormalShader.textureList[2] = VOID
      end if
      if t.car[#smoke] <> VOID then
        tResourceName = t.car.smoke.resource.name
        tName = t.car.smoke.name
        gGame.member.deleteModel(tName)
        gGame.member.deleteModelResource(tResourceName)
        t.car.deleteProp(#smoke)
      end if
      t.car.damageState = 0
    end if
  end if
  if (t.car.Health <= 0) and (tState = 3) then
    return 1
  end if
end

on reset_Damage me, t
  if t.car[#smoke] <> VOID then
    tResourceName = t.car.smoke.resource.name
    tName = t.car.smoke.name
    gGame.member.deleteModel(tName)
    gGame.member.deleteModelResource(tResourceName)
    t.car.deleteProp(#smoke)
  end if
  t.general.States.deleteOne(#update_Damage)
end

on setup_effects me, t
  t.car[#imageData] = [#none, #none]
  t.car[#adjColor] = rgb(80, 80, 80)
  t.car[#LMColor] = rgb(255, 255, 255)
end

on update_effects me, t
  if t.car.Nitro = 1 then
    tc = 0
    tTargetScale = t.car.nitroTargetScale
    if t.car.nitroModels[1].transform.scale = tTargetScale then
      tRandom = random(100, 130) * 0.01
      tTargetScale = vector(1, 1.39999999999999991, 1) * tRandom
    end if
    repeat with i in t.car.nitroModels
      tc = tc + 1
      if i.parent = VOID then
        i.parent = t.car.Effects.Nitro[tc]
      end if
      tStep = (tTargetScale - i.transform.scale) * gGame.TimeMP
      i.transform.scale = i.transform.scale + tStep
    end repeat
  else
    if t.car.nitroModels[1].parent <> VOID then
      tScale = t.car.nitroModels[1].transform.scale.z
      tScale = tScale - 0.14999999999999999
      tScale = max(0.001, tScale)
      repeat with i in t.car.nitroModels
        i.transform.scale = vector(1, 1, 1) * tScale
        if tScale = 0.001 then
          i.parent = VOID
        end if
      end repeat
    end if
  end if
  if gGame.Effects = #high then
    tDetails = t.car.intersectDetails
    if tDetails.count > 0 then
      tmodel = tDetails[1]
      if voidp(tmodel.userData[#FaceList2]) = 0 then
        tTexture = t.car.ISectShader.textureList[2]
        if tTexture <> VOID then
          if t.car.imageData[1] <> tTexture.name then
            tmember = tTexture.member
            t.car.imageData[2] = tmember.image
          end if
          tFace = tDetails[#faceID]
          tUVCoord = tDetails[#uvCoord]
          tUD = tmodel.userData
          tCoordList = tUD[#CoordList2]
          tFaceList = tUD[#FaceList2][tFace]
          tLocA = tCoordList[tFaceList[1]]
          tLocA = point(tLocA[1] * tTexture.width, (1 - tLocA[2]) * tTexture.height)
          tLocB = tCoordList[tFaceList[2]]
          tLocB = point(tLocB[1] * tTexture.width, (1 - tLocB[2]) * tTexture.height)
          tLocC = tCoordList[tFaceList[3]]
          tLocC = point(tLocC[1] * tTexture.width, (1 - tLocC[2]) * tTexture.height)
          tUVector = (tLocB - tLocA) * tUVCoord.u
          tVVector = (tLocC - tLocA) * tUVCoord.V
          tPos = tLocA + tUVector + tVVector
          if tPos = 0 then
            tColor = rgb(255, 255, 255)
          else
            tColor = t.car.imageData[2].getPixel(tPos)
          end if
          repeat with i in t.car.shaderList
            if i = VOID then
              next repeat
            end if
            i.specular = tColor
            i.emissive = tColor - rgb(64, 64, 64)
            i.diffuse = tColor
          end repeat
          t.car.LMColor = tColor
        end if
      end if
    end if
  end if
end

on reset_effects me, t
  repeat with i in t.car.nitroModels
    i.parent = VOID
  end repeat
  t.general.States.deleteOne(#update_effects)
end

on setup_Weapons me, t
  if (t.general.controller = #player) and (gGame[symbol("playerWeapons" & t.general.player)] = 0) then
    t.general.States.deleteOne(#update_Weapons)
  else
    if (t.general.controller = #AI) and (gGame.aiWeapons = 0) then
      t.general.States.deleteOne(#update_Weapons)
    else
      t[#Weapons] = [:]
      t.Weapons[#States] = []
      repeat with i in t.general.data.Weapons
        if i = "None" then
          next repeat
        end if
        t.Weapons.States.add(symbol("update_" & i))
        case i of
          "MachineGun":
            setup_machinegun(0, t)
          "DualMachineGun":
            setup_dualMachinegun(0, t)
          "MiniGun":
            setup_minigun(0, t)
          "DualMiniGun":
            Setup_DualMiniGun(0, t)
          "Laser":
            Setup_Laser(0, t)
          "RocketPod":
            Setup_RocketPod(0, t)
          "MineDeployer":
            setup_MineDeployer(0, t)
          "GrenadeDeployer":
            setup_GrenadeDeployer(0, t)
          "GrenadeLauncher":
            setup_GrenadeLauncher(0, t)
          "AirstrikeLauncher":
            setup_airstrikeLauncher(0, t)
          "MainGun":
            Setup_MainGun(0, t)
        end case
      end repeat
    end if
  end if
end

on update_Weapons me, t
  if (t.general.controller = #player) and (gGame[symbol("playerWeaponsActive" & t.general.player)] = 0) then
    return 0
  end if
  if (t.general.controller = #AI) and (gGame.AIWeaponsActive = 0) then
    return 0
  end if
  repeat with i in t.Weapons.States
    sendSprite(0, i, t)
  end repeat
end

on reset_Weapons me, t
  tList = t.Weapons.States.duplicate()
  SetItemDelimiter("_")
  repeat with i in tList
    tString = string(i)
    tHandler = symbol("reset_" & tString.item[2])
    sendSprite(0, tHandler, t)
  end repeat
  ResetItemDelimiter()
  t.general.States.deleteOne(#update_Weapons)
end

on setup_war me, t
  nothing()
end

on update_war me, t
  if gGame.input = 0 then
    exit
  end if
  tTransform1 = t.car.transform
  repeat with i in gGame.cars
    if i.general.tag = t.general.tag then
      next repeat
    end if
    tTransform2 = i.car.transform
    pos1 = tTransform1.position - tTransform2.position
    pos1.normalize()
    tForward = pos1.dot(tTransform2.yAxis)
    tLeftRight = pos1.dot(tTransform2.xAxis)
    if tForward > 0 then
      t.input.action1 = 0
      if (t.general.data.Weapons.secondary = "MineDeployer") or (t.general.data.Weapons.secondary = "GrenadeDeployer") then
        if abs(tLeftRight) <= 0.29999999999999999 then
          t.input.action2 = 1
        else
          t.input.action2 = 0
        end if
      end if
      next repeat
    end if
    if abs(tLeftRight) <= 0.29999999999999999 then
      t.input.action1 = 1
      if (t.general.data.Weapons.secondary <> "MineDeployer") or (t.general.data.Weapons.secondary <> "GrenadeDeployer") then
        if abs(tLeftRight) <= 0.29999999999999999 then
          t.input.action2 = 1
        else
          t.input.action2 = 0
        end if
      end if
      next repeat
    end if
    t.input.action1 = 0
    t.input.action2 = 0
  end repeat
end

on reset_war me, t
  t.general.States.deleteOne(#update_war)
end

on setup_tank me, t
  tgroup = gGame.member.newGroup(string(t.general.tag) & "MainGunHelper")
  t.Weapons.MainGun[#helper] = tgroup
  t.Weapons.MainGun.helper.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
end

on update_tank me, t
  if gGame.input = 0 then
    exit
  end if
  tTurret = t.Weapons.MainGun.turret
  tHelper = t.Weapons.MainGun.helper
  tTransform1 = tTurret.getWorldTransform()
  tTransform2 = gGame.cars[1].car.model.getWorldTransform()
  tHelper.transform.position = tTurret.worldPosition
  tPosition = tTransform2.position
  tPosition.z = tHelper.getWorldTransform().position.z
  tStoreT = tTurret.transform.duplicate()
  tTurret.pointAt(tPosition, vector(0, 0, 1))
  tNewT = transform()
  tNewT.rotation = t.car.model.getWorldTransform().rotation
  tNewT.rotation.z = tTurret.transform.rotation.z
  tTurret.transform = tStoreT
  tTurret.transform.interpolateTo(tNewT, 5)
  pos1 = tTransform1.position - tTransform2.position
  pos1.normalize()
  tDistance = tTransform1.position.distanceTo(tTransform2.position)
  if tDistance > 100 then
    t.input.action1 = 0
    t.input.action2 = 0
  else
    tLeftRight = pos1.dot(tTransform1.xAxis)
    if abs(tLeftRight) <= 0.20000000000000001 then
      t.input.action1 = 1
      t.input.action2 = 1
    else
      t.input.action1 = 0
      t.input.action2 = 0
    end if
  end if
end

on reset_tank me, t
  t.general.States.deleteOne(#update_tank)
end

on setup_Helpers me, t
  tTag = t.general.tag
  tmember = t.general.member
  if gGame[#ProxyShader] = VOID then
    CreateProxyShader(tmember)
  end if
  theModelResource = tmember.newModelResource(tTag & "LeaderSphere", #sphere)
  theModelResource.radius = 0.5
  tLeaderPoint = tmember.newModel(tTag & "LeaderSphere", theModelResource)
  tLeaderPoint.shader = gGame.ProxyShader
  CLONEMODELS(tmember, [#cloneMember: "LeaderHelper", #modelList: ["LeaderHelper"], #NameList: [tTag & "Leader"]])
  tLeaderArrow = tmember.model(tTag & "Leader")
  tLeaderArrow.shader = gGame.ProxyShader
  theModelResource = tmember.newModelResource(tTag & "LeaderCyl1", #cylinder)
  theModelResource.topRadius = 0.10000000000000001
  theModelResource.bottomRadius = 0.10000000000000001
  theModelResource.height = 100.0
  tLeaderCyl1 = tmember.newModel(tTag & "LeaderCyl1", theModelResource)
  tLeaderCyl1.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  theModelResource = tmember.newModelResource(tTag & "LeaderCyl2", #cylinder)
  theModelResource.topRadius = 0.10000000000000001
  theModelResource.bottomRadius = 0.10000000000000001
  theModelResource.height = 100.0
  tLeaderCyl2 = tmember.newModel(tTag & "LeaderCyl2", theModelResource)
  tLeaderCyl2.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  tLeaderCyl1.shader = gGame.ProxyShader
  tLeaderCyl2.shader = gGame.ProxyShader
  t[#Helpers] = [:]
  t[#Helpers][#LeaderPoint] = tLeaderPoint
  t[#Helpers][#LeaderArrow] = tLeaderArrow
  t[#Helpers][#LeaderCyl1] = tLeaderCyl1
  t[#Helpers][#LeaderCyl2] = tLeaderCyl2
end

on update_Helpers me, t
  t.Helpers.LeaderPoint.transform.position = t.race.WaypointT.position
  t.Helpers.LeaderArrow.transform = t.race.Leader.transform
  t.Helpers.LeaderArrow.transform.position = t.Helpers.LeaderArrow.transform.position + vector(0.0, 0.0, 1.5)
  t.Helpers.LeaderCyl1.transform.position = t.race.perpVector
  t.Helpers.LeaderCyl1.transform.rotation = t.race.WaypointT.rotation
  t.Helpers.LeaderCyl1.rotate(vector(0, 0, 90), #self)
  tResource = t.Helpers.LeaderCyl2.resource
  tResource.height = t.race.perpDistance
  t.Helpers.LeaderCyl2.transform.position = t.car.model.transform.position
  t.Helpers.LeaderCyl2.pointAt(t.race.perpVector, vector(0, 0, 1))
  t.Helpers.LeaderCyl2.translate(0, t.race.perpDistance * 0.5, 0, #self)
end

on reset_helpers me, t
  t.general.States.deleteOne(#update_Helpers)
end

on setup_sound me, t
  t[#sound] = [:]
  t.sound[#Mixer] = CreateMixer()
  t.sound.Mixer.bufferSize = 80
  t.sound[#channel] = gSound.DataSoundChannels.count + 1
  t.sound[#rate] = 1.0
  t.sound[#engine] = t.sound.Mixer.createSoundObject("CarStationair", member("CarStationair_SFX"), [#loopCount: 0])
  t.sound.engine.volume = 0
  t.sound[#filter] = audioFilter(#PitchShiftFilter, [#Shift: t.sound.rate])
  t.sound.engine.filterList.append(t.sound.filter)
  if (gGame.world = "City") or (gGame.world = "Snow") then
    tSoundSet = [member("CarAsphalt_SFX"), member("CarSkid_SFX")]
  else
    tSoundSet = [member("CarDirt_SFX"), member("CarSlide_SFX")]
  end if
  t.sound[#ground] = t.sound.Mixer.createSoundObject("CarGround", tSoundSet[1], [#loopCount: 0])
  t.sound.ground.volume = 0
  t.sound[#slip] = t.sound.Mixer.createSoundObject("CarSkid", tSoundSet[2], [#loopCount: 0, #loopStartTime: 135, #loopEndTime: tSoundSet[2].duration - 135])
  t.sound.slip.volume = 0
  t.sound.Mixer.play()
  if gSound.mute = 1 then
    t.sound.Mixer.mute()
    repeat with i in t.sound.Mixer.getSoundObjectList()
      i.mute()
    end repeat
  end if
  sound(t.sound.channel).volume = 255
end

on update_sound me, t
  if gSound.mute = 1 then
    return 0
  end if
  tDistance = t.camera.distanceToTarget[t.camera.index]
  tLeft = LeftOrRight(t.car.transform, gGame.camera[t.camera.index].transform)
  tPan = tLeft[2]
  tPan = max(-1.0, min(1.0, tPan))
  sound(t.sound.channel).pan = tPan
  if tDistance < 10.0 then
    tVolume = 255
  else
    tVolume = 255 - integer(255 * tDistance / 100.0)
    tVolume = max(0, min(255, tVolume))
  end if
  if sound(t.sound.channel).volume <> tVolume then
    sound(t.sound.channel).volume = tVolume
  end if
  if t.sound.engine.volume <> 164 then
    t.sound.engine.volume = 164
  end if
  tRate = 1.0 + (t.car.SpeedPerc * 1.69999999999999996)
  tRate = max(1.0, min(tRate, 5.0))
  if t.sound.filter.Shift <> tRate then
    t.sound.filter.Shift = tRate
  end if
  if t.car.Hovering = 1 then
    tVolume = integer(255 * t.car.SpeedPerc)
  else
    tVolume = 0
  end if
  if t.sound.ground.volume <> tVolume then
    t.sound.ground.volume = tVolume
  end if
  if (t.car.Hovering = 1) and (t.input.brake = 1) then
    tVolume = 200 * t.car.SpeedPerc
  else
    tVolume = 0
  end if
  if t.sound.slip.volume <> tVolume then
    t.sound.slip.volume = tVolume
  end if
  if (_player.runMode = "Author") and (t.sound.engine.playRate <> gGame.TimeMP) then
    t.sound.engine.playRate = gGame.TimeMP
    t.sound.slip.playRate = gGame.TimeMP
    t.sound.ground.playRate = gGame.TimeMP
    if t.sound[#primary] <> VOID then
      t.sound.primary.playRate = gGame.TimeMP
    end if
    if t.sound[#primary1] <> VOID then
      t.sound.primary1.playRate = gGame.TimeMP
    end if
    if t.sound[#primary2] <> VOID then
      t.sound.primary2.playRate = gGame.TimeMP
    end if
  end if
end

on reset_sound me, t
  t.sound.Mixer.mute()
  repeat with i in t.sound.Mixer.getSoundObjectList()
    i.mute()
  end repeat
  t.general.States.deleteOne(#update_sound)
end

on setup_sound2 me, t
  t[#sound] = [:]
  t.sound[#Mixer] = CreateMixer()
  t.sound.Mixer.bufferSize = 200
  t.sound[#channel] = gSound.DataSoundChannels.count + 1
  t.sound.Mixer.play()
  if gSound.mute = 1 then
    t.sound.Mixer.mute()
    repeat with i in t.sound.Mixer.getSoundObjectList()
      i.mute()
    end repeat
  end if
  sound(t.sound.channel).volume = 255
end

on update_sound2 me, t
  if gSound.mute = 1 then
    return 0
  end if
  tDistance = t.camera.distanceToTarget[t.camera.index]
  tLeft = LeftOrRight(t.car.transform, gGame.camera[t.camera.index].transform)
  tPan = tLeft[2]
  tPan = max(-1.0, min(1.0, tPan))
  sound(t.sound.channel).pan = tPan
  if tDistance < 10.0 then
    tVolume = 255
  else
    tVolume = 255 - integer(255 * tDistance / 100.0)
    tVolume = max(0, min(255, tVolume))
  end if
  if sound(t.sound.channel).volume <> tVolume then
    sound(t.sound.channel).volume = tVolume
  end if
end

on reset_sound2 me, t
  t.sound.Mixer.mute()
  repeat with i in t.sound.Mixer.getSoundObjectList()
    i.mute()
  end repeat
  t.general.States.deleteOne(#update_sound2)
end
