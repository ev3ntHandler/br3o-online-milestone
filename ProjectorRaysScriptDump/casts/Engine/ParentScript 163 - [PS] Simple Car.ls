property p
global gSystem, gData, gGame

on new me, tParams
  p = [:]
  t = new(script("pObject"))
  if voidp(gGame[#cars]) = 1 then
    gGame[#cars] = [:]
  end if
  if voidp(gGame[#Physics]) = 1 then
    return VOID
  end if
  tSprite = sprite(tParams[#SpriteNR])
  tmember = member(tParams[#memberName])
  tScriptName = tParams[#ScriptName]
  tController = tParams[#controller]
  if (tController <> #player) and (tController <> #AI) then
    return VOID
  end if
  if (voidp(gGame[#AI]) = 0) and (tController = #AI) then
    if gGame.AI = 0 then
      return VOID
    end if
  end if
  if tController = #player then
    tBuildData = gData.Events[symbol(gGame.world & "Track" & gGame.track & "Data")][#PlayerCar]
    if tBuildData <> VOID then
      tBuildData[#car] = gGame[symbol("PlayerCar" & gGame.Iteration)]
    else
      tBuildData = [#car: "Default", #position: #waypoint, #orientation: #waypoint]
    end if
  else
    if (gGame.TrackData.AI.count > 0) and (gGame.AIsBuild < gGame.TrackData.AI.count) then
      tBuildData = gGame.TrackData.AI[gGame.AIsBuild + 1]
    else
      tBuildData = VOID
    end if
  end if
  if tBuildData = VOID then
    return VOID
  else
    tBuildData = tBuildData.duplicate()
  end if
  tResult = BuildCar(0, tmember, tController, tBuildData[#car])
  tCarName = tResult.CarName
  tmodel = tResult.model
  tProxy = tResult.Proxy
  tShadowModel = tResult.shadowmodel
  tModelList = tResult.modelList
  tNitroModels = tResult.nitroModels
  tData = tResult.data
  tEffectlist = tResult.effectList
  tTag = symbol(tmodel.name)
  tTransform = tmodel.transform
  tPosRot = GetStartPositionRotation(0, tBuildData)
  tResetPosition = tPosRot[1]
  tResetRotation = tPosRot[2]
  tCarParams = tData.settings
  tMass = tCarParams[#mass]
  tCurrentSpeed = 0.0
  tMaxSpeed = tCarParams[#maxSpeed]
  tSpeedPerc = 0.0
  tHovering = 0
  tSlip = 0
  tAccGain = tCarParams[#accGain]
  tDecGain = tCarParams[#brakegain]
  tTurnGain = tCarParams[#turnGain]
  tWheelTurn = 0.0
  tWheelSpin = 0.0
  tMaxWheelTurn = tCarParams[#MaxWheelTurn]
  tWheelTurnSpeed = float(tMaxWheelTurn * 0.10000000000000001)
  tHoverDist = member(tCarName).model(tCarName).transform.position.z + 0.08
  tStrength = tCarParams[#strength]
  tDamping = tCarParams[#damping]
  tGrip = tCarParams[#grip]
  tDrag = tCarParams[#drag]
  tAdjGrip = tGrip
  tDriftGrip = tCarParams[#driftGrip]
  tCollisionDetails = [EMPTY, EMPTY, vector(1.0, 0.0, 0.0), vector(1.0, 0.0, 0.0)]
  tIntersectDetails = [:]
  tHealth = tCarParams[#Health]
  tShaderList = []
  repeat with i in tResult.modelList
    tShader = i.shader
    tShader.useDiffuseWithTexture = 1
    if (tShaderList.getPos(tShader) = 0) and not (i.shader.name contains "Proxy") then
      tShaderList.add(tShader)
    end if
  end repeat
  tCamIndex = 1
  if tController = #player then
    tCount = gGame.cars.count
    repeat with i in gGame.cars
      if i.general.controller = #player then
        tCamIndex = tCamIndex + 1
      end if
    end repeat
  end if
  tgroup = tmember.newGroup(tmodel.name & "_Group")
  tLeader = tmember.newGroup(tTag & "Leader_Group")
  tLeader.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  tStates = [#update_WayPoints]
  if voidp(tParams[#States]) = 0 then
    tStates = tParams[#States]
  end if
  if tStates.ilk <> #list then
    tStates = [#update_WayPoints, #update_Racing]
  end if
  if tCarName = "Tank" then
    tStates.deleteOne(#update_war)
    tStates.add(#update_tank)
  end if
  if gGame.Effects = #low then
    tStates.deleteOne(#update_sound2)
  end if
  if gGame[#CarHelpers] = 1 then
    tStates.add(#update_Helpers)
  end if
  t[#general] = [#sprite: tSprite, #member: tmember, #controller: tController, #tag: tTag, #Boss: 0, #player: gGame.cars.count + 1, #limit: 0, #data: tData, #buildData: tBuildData, #States: tStates.duplicate(), #script: me]
  t[#car] = [#name: tCarName, #model: tmodel, #Proxy: tProxy, #shadowmodel: tShadowModel, #nitroModels: tNitroModels, #shaderList: tShaderList, #transform: tTransform, #previousT: tTransform, #group: tgroup, #ResetPosition: tResetPosition, #ResetRotation: tResetRotation, #mass: tMass, #Speed: tCurrentSpeed, #maxSpeed: tMaxSpeed, #SpeedPerc: tSpeedPerc, #Hovering: tHovering, #Nitro: 0, #slip: tSlip, #accGain: tAccGain, #decGain: tDecGain, #turnGain: tTurnGain, #MaxWheelTurn: tMaxWheelTurn, #WheelTurnSpeed: tWheelTurnSpeed, #WheelTurn: tWheelTurn, #WheelSpin: tWheelSpin, #HoverDist: tHoverDist, #strength: tStrength, #damping: tDamping, #grip: tGrip, #AdjGrip: tGrip, #driftGrip: tDriftGrip, #drag: tDrag, #currentFloor: VOID, #FloorList: [], #currentRootNr: 1, #previousRootNR: 0, #RootList: [1, 2], #previousRootList: [1, 2], #collisionDetails: tCollisionDetails, #intersectDetails: tIntersectDetails, #Effects: tEffectlist, #Health: tHealth]
  t[#race] = [#state: #none, #position: gGame.cars.count, #Leader: tLeader, #leaderModel: VOID, #time: 0, #score: 0, #storedScore: 0, #addScore: 0, #CheckPoints: 0, #WayPointList: [], #waypoint: 1, #WaypointDistance: 0.0, #WaypointT: transform(), #waypointZ: 0.0, #perpVector: vector(), #perpDistance: 0.0, #stuckCounter: 0, #stuckPosition: tmodel.worldPosition]
  t[#input] = [:]
  t[#camera] = [#index: tCamIndex, #inView: [], #inViewPos: [], #distanceToTarget: [], #MaxDistanceToTarget: 30.0]
  t.general.Boss = gGame.Bosses.getPos(symbol(tCarName)) > 0
  gGame.cars[tTag] = t
  SetItemDelimiter("_")
  repeat with i in tStates
    tString = string(i)
    tHandler = symbol("setup_" & tString.item[2])
    sendSprite(0, tHandler, t)
  end repeat
  ResetItemDelimiter()
  p[#tag] = t.general.tag
  t = InitializeCar(t, tCarParams)
  if t.general.controller = #player then
    gGame.playersBuild = gGame.playersBuild + 1
  else
    gGame.AIsBuild = gGame.AIsBuild + 1
  end if
  t = VOID
  return me
end

on InitializeCar t, tCarParams
  t.car.Proxy.addModifier(#meshDeform)
  t.car.Proxy.removeFromWorld()
  tPhysicsCar = gGame.Physics.createRigidBody(t.car.Proxy.name, t.car.Proxy.name, #convexShape, #dynamic)
  tPhysicsCar.friction = tCarParams[#friction]
  tPhysicsCar.restitution = tCarParams[#restitution]
  tPhysicsCar.mass = t.car.mass
  tPhysicsCar.angularDamping = 1.30000000000000004
  tPhysicsCar.position = t.car.ResetPosition
  tPhysicsCar.orientation = t.car.ResetRotation
  tPhysicsCar.linearVelocity = vector(0, 0, 0)
  tPhysicsCar.angularVelocity = vector(0, 0, 0)
  t.car[#PhysicsCar] = tPhysicsCar
  AddCollisionReport(EMPTY, [#nameA: t.car.Proxy.name, #nameB: #all])
  tName = t.car.model.name
  tmember = t.general.member
  tWheelList = [tmember.model(tName & "Wheel_LF"), tmember.model(tName & "Wheel_RF"), tmember.model(tName & "Wheel_LB"), tmember.model(tName & "Wheel_RB")]
  t.car[#wheellist] = tWheelList
  tCarMember = member(t.car.name)
  tOrigNames = [t.car.name & "Wheel_LF", t.car.name & "Wheel_RF", t.car.name & "Wheel_LB", t.car.name & "Wheel_RB"]
  tCount = tWheelList.count
  repeat with i = 1 to tCount
    tdiff = tCarMember.model(tOrigNames[i]).transform.position - tCarMember.model(t.car.name).transform.position
    tWheelList[i].parent = t.car.model
    tWheelList[i].transform.position = vector(0.0, 0.0, 0.0)
    tWheelList[i].transform.position = tWheelList[i].transform.position + tdiff
  end repeat
  gGame.member.model(tName & "Glass").transform.position = vector(0, 0, 0)
  gGame.member.model(tName & "Glass").parent = t.car.model
  tFloorList = []
  repeat with i in t.car.RootList
    if i <= gGame.FloorList.count then
      tFloorList.add(gGame.FloorList[i])
    end if
  end repeat
  t.car.FloorList = tFloorList
  return t
end

on enterFrame me
  t = gGame.cars[p.tag]
  t.camera.inView = []
  t.camera.inViewPos = []
  t.camera.distanceToTarget = []
  repeat with i in gGame.camera
    tInViewPos = i.camera.worldSpaceToSpriteSpace(t.car.Proxy.transform.position)
    if tInViewPos = VOID then
      t.camera.inView.add(0)
    else
      t.camera.inView.add(1)
    end if
    t.camera.inViewPos.add(tInViewPos)
    tCameraPos = i.transform.position
    t.camera.distanceToTarget.add(tCameraPos.distanceTo(t.car.Proxy.transform.position))
  end repeat
  tLimit = 0
  if t.camera.inView.getOne(1) = 0 then
    tLimit = 1
  end if
  if t.camera.distanceToTarget.min() < t.camera.MaxDistanceToTarget then
    tLimit = 0
  end if
  t.general.limit = tLimit
  t.car.model.transform = t.car.Proxy.transform
  if t.car.Health = 0 then
    exit
  end if
  tList = t.general.States.duplicate()
  repeat with i in tList
    tResult = sendSprite(0, i, t)
    if tResult = 1 then
      exit repeat
    end if
  end repeat
  tTransform = transform()
  tTransform.rotation = t.car.Proxy.transform.rotation.duplicate()
  tWorldForward = tTransform * vector(0.0, 1.0, 0.0)
  tWorldAxis = tTransform * -vector(0.0, 0.0, -1.0)
  tWorldRight = tWorldForward.cross(tWorldAxis)
  tWorldDown = tTransform * vector(0.0, 0.0, -1.0)
  tWorldForward.normalize()
  tWorldAxis.normalize()
  tWorldRight.normalize()
  tWorldDown.normalize()
  tChassisPos = t.car.Proxy.transform.position
  tPhysicsCar = t.car.PhysicsCar
  tCurrentVel = tPhysicsCar.linearVelocity
  tForwardVel = tWorldForward * tCurrentVel
  t.car.Speed = tCurrentVel.dot(tWorldForward)
  t.car.SpeedPerc = abs(t.car.Speed / t.car.maxSpeed)
  tDirection = tWorldDown + vector(0.0001, 0.0001, 0.0001)
  if t.car.Hovering = 0 then
    tDirection = vector(0.0001, 0.0001, -1.00009999999999999)
  end if
  tOptionList = [#maxNumberOfModels: 1, #levelOfDetail: #detailed, #modelList: t.car.FloorList, #maxDistance: 5.0]
  tIntersectDetails = t.general.member.modelsUnderRay(tChassisPos, tDirection, tOptionList)
  if tIntersectDetails.count > 0 then
    tIntersectDetails = tIntersectDetails[1]
  end if
  if tIntersectDetails.count > 0 then
    t.car.currentFloor = tIntersectDetails.model
    t.car.currentRootNr = gGame.FloorList.getPos(t.car.currentFloor)
    tRootList = [t.car.currentRootNr]
    tRootList.sort()
    if (tRootList[1] - 1) > 0 then
      tRootList.add(tRootList[1] - 1)
    end if
    repeat with i = 1 to gGame.visibleTiles
      if (tRootList[tRootList.count] + 1) <= gGame.RootList.count then
        tRootList.add(tRootList[tRootList.count] + 1)
      end if
    end repeat
    if tRootList <> t.car.RootList then
      t.car.previousRootList = t.car.RootList
    end if
    t.car.RootList = tRootList
    tFloorList = []
    repeat with i in t.car.RootList
      tFloorList.add(gGame.FloorList[i])
    end repeat
    t.car.FloorList = tFloorList
    if tIntersectDetails[#distance] < t.car.HoverDist then
      tPhysicsCar.angularVelocity = vector(0, 0, 0)
      tdiff = tIntersectDetails[#isectPosition] - tChassisPos
      tLength = tdiff.length
      tF = -t.car.strength * (t.car.HoverDist - tLength)
      tF = tF - (t.car.damping * tCurrentVel.dot(tdiff))
      tForce = tdiff * tF * t.car.mass
      tForce = tForce * 4
      tPhysicsCar.applyLinearImpulse(tForce, tChassisPos)
      t.car.Hovering = 1
      t.car[#ISectShader] = tIntersectDetails[#model].shaderList[tIntersectDetails[#meshID]]
      t.car.intersectDetails = tIntersectDetails
      tgroup = t.car.group
      tgroup.transform = t.car.Proxy.transform.duplicate()
      thisPosn = tgroup.getWorldTransform().position - (1050.0 * tIntersectDetails[#isectNormal])
      startT = tgroup.getWorldTransform()
      tgroup.pointAt(thisPosn, tWorldForward)
      endT = tgroup.getWorldTransform()
      newT = startT.interpolate(endT, 45)
      tgroup.transform = newT
      tPhysicsCar.orientation = tgroup.transform.axisAngle
      tPhysicsCar.angularVelocity = vector(0, 0, 0)
    else
      t.car.Hovering = 0
    end if
    tShadowModel = t.car.shadowmodel
    if tShadowModel.isInWorld() = 0 then
      tShadowModel.addToWorld()
    end if
    tShadowModel.transform.position = tIntersectDetails[#isectPosition] + vector(0, 0, 0.05)
    tShadowModel.pointAtOrientation = [vector(0, 0, 1), vector(0, 1, 0)]
    tShadowModel.pointAt(tShadowModel.transform.position + tIntersectDetails[#isectNormal])
    tShadowModel.rotate(0, 0, t.car.Proxy.transform.rotation[3])
    if t.car.Health = 0 then
      t.general.member.deleteModel(tShadowModel.name)
    end if
  else
    t.car.shadowmodel.parent = VOID
    t.car.Hovering = 0
  end if
  if t.car.Hovering = 1 then
    tAdjTurnGain = t.car.turnGain
    if t.car.Nitro = 1 then
      tAdjMaxSpeed = t.car.maxSpeed + gGame.NitroBoost
    else
      tAdjMaxSpeed = t.car.maxSpeed
    end if
    if abs(t.car.Speed) >= (t.car.maxSpeed * 0.25) then
      tAdjTurnGain = t.car.turnGain
    else
      tPercentage = abs(t.car.Speed) / (t.car.maxSpeed * 0.25)
      tPercentage = min(1.0, tPercentage)
      tAdjTurnGain = t.car.turnGain * tPercentage
    end if
    if tAdjTurnGain < 0.05 then
      tAdjTurnGain = 0.0
    end if
    if (t.car.Speed < 0) and (t.input.forward = 1) then
      tSteering = 0
    else
      if (t.car.Speed > 0) and (t.input.backward = 1) then
        tSteering = 0
      else
        tSteering = 1
      end if
    end if
    if t.input.forward = 1 then
      tdiff = tAdjMaxSpeed - t.car.Speed
      imp = tdiff * t.car.accGain * t.car.mass * tWorldForward
      tPhysicsCar.applyLinearImpulse(imp)
    end if
    if t.input.backward = 1 then
      tdiff = (-tAdjMaxSpeed / 2.0) - t.car.Speed
      imp = tdiff * t.car.decGain * t.car.mass * tWorldForward
      tPhysicsCar.applyLinearImpulse(imp)
    end if
    if t.input.brake = 1 then
      t.car.slip = 1
      t.car.AdjGrip = t.car.driftGrip
    end if
    if t.car.slip = 1 then
      if t.car.AdjGrip < t.car.grip then
        t.car.AdjGrip = t.car.AdjGrip + 0.02
      end if
      if t.car.AdjGrip > t.car.grip then
        t.car.AdjGrip = t.car.grip
      end if
      if t.car.AdjGrip = t.car.grip then
        t.car.slip = 0
      end if
    end if
    if tSteering = 1 then
      if t.input.left = 1 then
        imp = tWorldAxis * (tAdjTurnGain * (t.car.mass * 0.90000000000000002))
        if t.car.Speed < 0.0 then
          imp = -imp
        end if
        if t.input.joystick = 1 then
          imp = imp * t.input.leftPerc
        end if
        tPhysicsCar.applyAngularImpulse(imp)
      end if
      if t.input.right = 1 then
        imp = tWorldAxis * (-tAdjTurnGain * (t.car.mass * 0.90000000000000002))
        if t.car.Speed < 0.0 then
          imp = -imp
        end if
        if t.input.joystick = 1 then
          imp = imp * t.input.rightPerc
        end if
        tPhysicsCar.applyAngularImpulse(imp)
      end if
    end if
    tSlideSpeed = tWorldRight.dot(tCurrentVel)
    imp = tWorldRight * (-tSlideSpeed * t.car.mass * t.car.AdjGrip)
    tPhysicsCar.applyLinearImpulse(imp)
    imp = -tCurrentVel * (t.car.drag * t.car.mass)
    tPhysicsCar.applyLinearImpulse(imp)
  end if
  if tLimit = 0 then
    if (t.input.left = 1) or (t.input.right = 1) then
      if t.input.left = 1 then
        if t.car.WheelTurn < t.car.MaxWheelTurn then
          t.car.WheelTurn = t.car.WheelTurn + t.car.WheelTurnSpeed
        end if
        if t.input.joystick = 1 then
          t.car.WheelTurn = t.car.MaxWheelTurn * t.input.Keys.leftPerc
        end if
      else
        if t.car.WheelTurn > -t.car.MaxWheelTurn then
          t.car.WheelTurn = t.car.WheelTurn - t.car.WheelTurnSpeed
        end if
        if t.input.joystick = 1 then
          t.car.WheelTurn = t.car.MaxWheelTurn * t.input.Keys.rightPerc
        end if
      end if
      t.car.WheelTurn = max(-t.car.MaxWheelTurn, min(t.car.MaxWheelTurn, t.car.WheelTurn))
    else
      if not (t.car.WheelTurn = 0) then
        if t.car.WheelTurn < 0 then
          t.car.WheelTurn = t.car.WheelTurn + t.car.WheelTurnSpeed
        else
          t.car.WheelTurn = t.car.WheelTurn - t.car.WheelTurnSpeed
        end if
      end if
      if t.input.joystick = 1 then
        t.car.WheelTurn = 0.0
      end if
    end if
    t.car.WheelSpin = t.car.WheelSpin - (tForwardVel * (2.0 * gGame.TimeMP))
    if t.car.WheelSpin > 360 then
      t.car.WheelSpin = t.car.WheelSpin - 360
    else
      if t.car.WheelSpin < -360 then
        t.car.WheelSpin = t.car.WheelSpin - 360
      end if
    end if
    repeat with i = 1 to t.car.wheellist.count
      t.car.wheellist[i].transform.rotation = t.car.Proxy.transform.rotation
      t.car.wheellist[i].transform.rotation.y = 0.0
      t.car.wheellist[i].transform.rotation.z = 0.0
      if (i = 1) or (i = 2) then
        t.car.wheellist[i].transform.rotation.z = t.car.WheelTurn
      end if
      tWheelSpin = t.car.WheelSpin
      if ((i = 2) or (i = 4)) and (t.general.Boss = 0) then
        tWheelSpin = -tWheelSpin
      end if
      t.car.wheellist[i].rotate(tWheelSpin, 0, 0, #self)
      if ((i = 2) or (i = 4)) and (t.general.Boss = 0) then
        t.car.wheellist[i].rotate(0, 0, 180, #self)
      end if
    end repeat
  end if
  t.car.previousT = t.car.transform.duplicate()
  tCos = tWorldAxis.dot(vector(0, 0, 1))
  if (t.car.Hovering = 0) and (abs(t.car.Speed) <= 0.25) and (tCos < 0.29999999999999999) then
    me.reset(t, 1, 0)
  end if
  if (t.car.Hovering = 0) and (t.race.waypointZ <= -35.0) then
    me.reset(t, 1, 0)
  end if
  if gGame.RaceState = #Pending then
    me.reset(t)
  end if
end

on reset me, t, tWaypoint, tRay
  tPosition = t.car.ResetPosition
  tRotation = t.car.ResetRotation
  if tWaypoint = 1 then
    tTransform = t.race.WayPointList[t.race.waypoint].duplicate()
    tPosition = tTransform.position + vector(0, 0, 0.5)
    tRotation = tTransform.axisAngle
  end if
  if tRay = 1 then
    tRayDetails = gGame.Physics.rayCastClosest(tPosition + vector(0, 0, 15), vector(0, 0, -1.00099999999999989))
    if tRayDetails.count > 0 then
      tPosition = tRayDetails[2] + vector(0.0, 0.0, 4.5)
    else
      tPosition = tPosition + vector(0.0, 0.0, 4.5)
    end if
  end if
  t.car.Proxy.transform.position = tPosition
  t.car.Proxy.transform.axisAngle = tRotation
  t.car.PhysicsCar.position = tPosition
  t.car.PhysicsCar.orientation = tRotation
  t.car.PhysicsCar.linearVelocity = vector(0, 0, 0)
  t.car.PhysicsCar.angularVelocity = vector(0, 0, 0)
  tOptionList = [#maxNumberOfModels: 1, #levelOfDetail: #detailed, #modelList: gGame.FloorList, #maxDistance: 5.0]
  tIntersectDetails = t.general.member.modelsUnderRay(t.car.Proxy.worldPosition, vector(0.0001, 0.0001, -1.00009999999999999), tOptionList)
  if tIntersectDetails.count > 0 then
    tIntersectDetails = tIntersectDetails[1]
  end if
  if tIntersectDetails.count > 0 then
    t.car.currentFloor = tIntersectDetails.model
    t.car.currentRootNr = gGame.FloorList.getPos(t.car.currentFloor)
    tRootList = [t.car.currentRootNr]
    tRootList.sort()
    if (tRootList[1] - 1) > 0 then
      tRootList.add(tRootList[1] - 1)
    end if
    repeat with i = 1 to 1
      if (tRootList[tRootList.count] + 1) <= gGame.RootList.count then
        tRootList.add(tRootList[tRootList.count] + 1)
      end if
    end repeat
    if tRootList <> t.car.RootList then
      t.car.previousRootList = t.car.RootList
    end if
    t.car.RootList = tRootList
    tFloorList = []
    repeat with i in t.car.RootList
      tFloorList.add(gGame.FloorList[i])
    end repeat
    t.car.FloorList = tFloorList
  end if
end
