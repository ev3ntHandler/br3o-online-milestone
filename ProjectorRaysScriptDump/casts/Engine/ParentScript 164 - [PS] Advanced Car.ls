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
  tBanking = tCarParams[#Banking]
  tAdjBanking = 0.0
  tHoverDist = member(tCarName).model(tCarName).transform.position.z + tCarParams[#hoverOffset]
  tStrength = tCarParams[#strength]
  tDamping = tCarParams[#damping]
  tGrip = tCarParams[#grip]
  tDrag = tCarParams[#drag]
  tAdjGrip = tGrip
  tDriftGrip = tCarParams[#driftGrip]
  tCollisionDetails = [EMPTY, EMPTY, vector(1.0, 0.0, 0.0), vector(1.0, 0.0, 0.0)]
  tIntersectDetails = [:]
  tHealth = tData.personality.Health
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
  tLeader = tmember.newGroup(tTag & "Leader_Group")
  tLeader.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  tStates = [#update_WayPoints]
  if voidp(tParams[#States]) = 0 then
    tStates = tParams[#States]
  end if
  if tStates.ilk <> #list then
    tStates = [#update_WayPoints, #update_Racing]
  end if
  if gGame[#CarHelpers] = 1 then
    tStates.add(#update_Helpers)
  end if
  if (tCarName = "Tank") and (tController = #AI) then
    tStates.deleteOne(#update_war)
    tStates.add(#update_tank)
  end if
  t[#general] = [#sprite: tSprite, #member: tmember, #controller: tController, #tag: tTag, #Boss: 0, #player: gGame.cars.count + 1, #limit: 0, #data: tData, #buildData: tBuildData, #States: tStates.duplicate(), #script: me]
  t[#car] = [#name: tCarName, #model: tmodel, #Proxy: tProxy, #shadowmodel: tShadowModel, #nitroModels: tNitroModels, #nitroTargetScale: vector(1, 1, 1), #shaderList: tShaderList, #transform: tTransform, #previousT: tTransform.duplicate(), #ResetPosition: tResetPosition, #ResetRotation: tResetRotation, #mass: tMass, #Speed: tCurrentSpeed, #maxSpeed: tMaxSpeed, #SpeedPerc: tSpeedPerc, #Hovering: tHovering, #slip: tSlip, #Nitro: 0, #accGain: tAccGain, #decGain: tDecGain, #turnGain: tTurnGain, #currentGain: 0.0, #MaxWheelTurn: tMaxWheelTurn, #WheelTurnSpeed: tWheelTurnSpeed, #WheelTurn: tWheelTurn, #WheelSpin: tWheelSpin, #Banking: tBanking, #AdjBanking: tAdjBanking, #HoverDist: tHoverDist, #strength: tStrength, #damping: tDamping, #grip: tGrip, #AdjGrip: tGrip, #driftGrip: tDriftGrip, #drag: tDrag, #currentFloor: VOID, #FloorList: [], #currentRootNr: 1, #previousRootNR: 0, #RootList: [1, 2], #previousRootList: [1, 2], #collisionDetails: tCollisionDetails, #intersectDetails: tIntersectDetails, #Health: tHealth, #Effects: tEffectlist]
  t[#race] = [#state: #none, #position: gGame.cars.count + 1, #Leader: tLeader, #leaderModel: VOID, #time: 0, #score: 0, #storedScore: 0, #addScore: 0, #CheckPoints: 0, #WayPointList: [], #waypoint: 1, #WaypointDistance: 0.0, #WaypointT: transform(), #waypointZ: 0.0, #perpVector: vector(), #perpDistance: 0.0, #stuckCounter: 0, #stuckPosition: tmodel.worldPosition, #wrongWayCounter: 0]
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
  t.car[#IsHoveringList] = [0, 0, 0, 0]
  t.car[#HoverDistList] = [0.0, 0.0, 0.0, 0.0]
  com = t.car.PhysicsCar.centerOfMass
  tWidth = abs(tWheelList[1].transform.position.x) + abs(tWheelList[2].transform.position.x)
  tWheelBase = (abs(tWheelList[2].transform.position.y) + abs(tWheelList[4].transform.position.y)) / 2
  posA = com + (tWheelBase * vector(0, 1, 0)) + (tWidth * 0.5 * -vector(1, 0, 0))
  posB = com + (tWheelBase * vector(0, 1, 0)) + (tWidth * 0.5 * vector(1, 0, 0))
  posC = com + (tWheelBase * -vector(0, 1, 0)) + (tWidth * 0.5 * -vector(1, 0, 0))
  posD = com + (tWheelBase * -vector(0, 1, 0)) + (tWidth * 0.5 * vector(1, 0, 0))
  t.car[#WheelPointList] = [posA, posB, posC, posD]
  t.car[#WheelRadius] = member(t.car.name).model(t.car.name & "Wheel_LF").boundingSphere[2]
  t.car[#WheelRadiusDEV] = abs(tWheelList[1].transform.position.y - tWheelBase)
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
  tPhysicsCar = t.car.PhysicsCar
  tChassisPos = t.car.Proxy.transform.position + tPhysicsCar.centerOfMass
  tCurrentVel = tPhysicsCar.linearVelocity
  tForwardVel = tWorldForward * tCurrentVel
  tAngularVel = tPhysicsCar.angularVelocity
  t.car.Speed = tCurrentVel.dot(tWorldForward)
  t.car.SpeedPerc = abs(t.car.Speed / t.car.maxSpeed)
  tPowerCoeff = t.car.IsHoveringList[1] + t.car.IsHoveringList[2] + t.car.IsHoveringList[3] + t.car.IsHoveringList[4]
  tPowerCoeff = tPowerCoeff / 4.0
  tProxyT = t.car.Proxy.transform
  repeat with i = 1 to t.car.WheelPointList.count
    t.car.IsHoveringList[i] = 0
    tWorldWheelPoint = tProxyT * t.car.WheelPointList[i]
    tIntersectDetails = gGame.Physics.rayCastClosest(tWorldWheelPoint, tWorldDown + vector(0.0001, 0.0001, 0.0001))
    if tIntersectDetails.count > 0 then
      if tIntersectDetails[4] < t.car.HoverDist then
        tPointVelocity = tCurrentVel + tAngularVel.cross(tWorldWheelPoint - tChassisPos)
        tdiff = tIntersectDetails[2] - tWorldWheelPoint
        tLength = tdiff.length
        tF = -t.car.strength * (t.car.HoverDist - tLength)
        tF = tF - (t.car.damping * tPointVelocity.dot(tdiff))
        tForce = tdiff * tF * t.car.mass
        tPhysicsCar.applyLinearImpulse(tForce, t.car.WheelPointList[i])
        t.car.IsHoveringList[i] = 1
        t.car.HoverDistList[i] = tLength
      end if
    end if
  end repeat
  if t.car.IsHoveringList.getPos(1) = 0 then
    t.car.Hovering = 0
    if tPhysicsCar.angularVelocity.magnitude < 0.69999999999999996 then
      tPhysicsCar.angularVelocity = tPhysicsCar.angularVelocity * 0.69999999999999996
    end if
  else
    t.car.Hovering = 1
  end if
  tDirection = vector(0.0001, 0.0001, -1.00009999999999999)
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
    t.car[#ISectShader] = tIntersectDetails[#model].shaderList[tIntersectDetails[#meshID]]
    t.car.intersectDetails = tIntersectDetails
    tShadowModel = t.car.shadowmodel
    if tShadowModel.isInWorld() = 0 then
      tShadowModel.addToWorld()
    end if
    tShadowModel.transform.position = tIntersectDetails[#isectPosition] + vector(0, 0, 0.05)
    tShadowModel.pointAtOrientation = [vector(0, 0, 1), vector(0, 1, 0)]
    tShadowModel.pointAt(tShadowModel.transform.position + tIntersectDetails[#isectNormal])
    tDot = t.car.Proxy.transform.yAxis.dot(vector(1, 0, 0))
    tAngle = t.car.Proxy.transform.yAxis.angleBetween(vector(0, 1, 0))
    if tDot > 0 then
      tAngle = -tAngle
    end if
    tShadowModel.rotate(0, 0, tAngle)
    if t.car.Health = 0 then
      t.general.member.deleteModel(tShadowModel.name)
    end if
  else
    t.car.shadowmodel.parent = VOID
  end if
  if tPowerCoeff > 0.0 then
    tAdjTurnGain = t.car.turnGain
    if t.car.Nitro = 1 then
      tAdjMaxSpeed = t.car.maxSpeed + gGame.NitroBoost
    else
      tAdjMaxSpeed = t.car.maxSpeed
    end if
    if abs(t.car.Speed) >= (t.car.maxSpeed * 0.22500000000000001) then
      tAdjTurnGain = t.car.turnGain
    else
      tPercentage = abs(t.car.Speed) / (t.car.maxSpeed * 0.22500000000000001)
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
      imp = tdiff * t.car.accGain * t.car.mass * tWorldForward * tPowerCoeff
      tPhysicsCar.applyLinearImpulse(imp)
    end if
    if t.input.backward = 1 then
      tdiff = (-tAdjMaxSpeed / 2.0) - t.car.Speed
      imp = tdiff * t.car.decGain * t.car.mass * tWorldForward * tPowerCoeff
      tPhysicsCar.applyLinearImpulse(imp)
    end if
    if t.input.brake = 1 then
      t.car.slip = 1
      t.car.AdjGrip = 0.02
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
        imp = tWorldAxis * (tAdjTurnGain * (t.car.mass * 0.90000000000000002)) * tPowerCoeff
        if t.car.Speed < 0.0 then
          imp = -imp
        end if
        if t.input.joystick = 1 then
          imp = imp * t.input.leftPerc
        end if
        tPhysicsCar.applyAngularImpulse(imp)
      end if
      if t.input.right = 1 then
        imp = tWorldAxis * (-tAdjTurnGain * (t.car.mass * 0.90000000000000002)) * tPowerCoeff
        if t.car.Speed < 0.0 then
          imp = -imp
        end if
        if t.input.joystick = 1 then
          imp = imp * t.input.rightPerc
        end if
        tPhysicsCar.applyAngularImpulse(imp)
      end if
    end if
    tAngVelLength = tAngularVel.length
    if tAngVelLength > 0.0 then
      if abs(t.car.Speed) <= (t.car.maxSpeed * 7) then
        tPerc = abs(t.car.Speed) / (t.car.maxSpeed * 0.69999999999999996)
      else
        tPerc = 1.0
      end if
      tCompensateGain = 0.25 + (tAdjTurnGain * tPerc)
      if tCompensateGain > tAdjTurnGain then
        tCompensateGain = tAdjTurnGain
      end if
      imp = tWorldAxis * tAngularVel.dot(tWorldAxis) * (-tCompensateGain * t.car.mass) * tPowerCoeff
      tPhysicsCar.applyAngularImpulse(imp)
    end if
    tSlideSpeed = tWorldRight.dot(tCurrentVel)
    imp = tWorldRight * (-tSlideSpeed * t.car.mass * t.car.AdjGrip) * tPowerCoeff
    tPhysicsCar.applyLinearImpulse(imp)
    imp = -tCurrentVel * (t.car.drag * t.car.mass)
    tPhysicsCar.applyLinearImpulse(imp)
  end if
  if t.input.left and not (t.car.WheelTurn < -0.90000000000000002) then
    t.car.WheelTurn = t.car.WheelTurn - 0.10000000000000001
  end if
  if t.input.right and not (t.car.WheelTurn > 0.90000000000000002) then
    t.car.WheelTurn = t.car.WheelTurn + 0.10000000000000001
  end if
  if not t.input.left and not t.input.right then
    if not (t.car.WheelTurn = 0) then
      if t.car.WheelTurn < 0 then
        t.car.WheelTurn = t.car.WheelTurn + 0.10000000000000001
      else
        t.car.WheelTurn = t.car.WheelTurn - 0.10000000000000001
      end if
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
  repeat with i = 1 to t.car.IsHoveringList.count
    if t.car.IsHoveringList[i] = 1 then
      tWorldWheelPoint = tProxyT * (t.car.WheelPointList[i] + vector(0, t.car.WheelRadiusDEV, 0))
      t.car.wheellist[i].transform.position = tWorldWheelPoint + (t.car.HoverDistList[i] * tWorldDown) - (t.car.WheelRadius * tWorldDown)
    else
      if t.car.IsHoveringList[i] = 0 then
        tWorldWheelPoint = tProxyT * (t.car.WheelPointList[i] + vector(0, t.car.WheelRadiusDEV, 0))
        t.car.wheellist[i].transform.position = tWorldWheelPoint + (t.car.HoverDist * tWorldDown) - (t.car.WheelRadius * tWorldDown)
      end if
    end if
    t.car.wheellist[i].transform.rotation = tProxyT.rotation
    tTempTrans = t.car.wheellist[i].transform.duplicate()
    tTempTrans.position = vector(0, 0, 0)
    tWheelRightDir = tTempTrans * vector(1, 0, 0)
    tWheelRightDir.normalize()
    tWheelSpin = t.car.WheelSpin
    if ((i = 2) or (i = 4)) and (t.general.Boss = 0) then
      tWheelSpin = -tWheelSpin
    end if
    if (i = 1) or (i = 2) then
      tRot = t.car.MaxWheelTurn * t.car.WheelTurn
      t.car.wheellist[i].transform.rotate(t.car.wheellist[i].transform.position, tWheelRightDir, tWheelSpin)
      t.car.wheellist[i].transform.rotate(t.car.wheellist[i].transform.position, tWorldDown, tRot)
    else
      t.car.wheellist[i].transform.rotate(t.car.wheellist[i].transform.position, tWheelRightDir, tWheelSpin)
    end if
    if ((i = 2) or (i = 4)) and (t.general.Boss = 0) then
      t.car.wheellist[i].transform.rotate(t.car.wheellist[i].transform.position, tWorldDown, 180.0)
    end if
  end repeat
  if t.input.left and not (t.car.AdjBanking < -0.90000000000000002) then
    t.car.AdjBanking = t.car.AdjBanking - (0.10000000000000001 * gGame.TimeMP)
  end if
  if t.input.right and not (t.car.AdjBanking > 0.90000000000000002) then
    t.car.AdjBanking = t.car.AdjBanking + (0.10000000000000001 * gGame.TimeMP)
  end if
  if ((t.input.left = 0) and (t.input.right = 0)) or (t.car.Hovering = 0) then
    if not (t.car.AdjBanking = 0) then
      if t.car.AdjBanking < 0 then
        t.car.AdjBanking = t.car.AdjBanking + (0.10000000000000001 * gGame.TimeMP)
      else
        t.car.AdjBanking = t.car.AdjBanking - (0.10000000000000001 * gGame.TimeMP)
      end if
    end if
  end if
  tBanking = t.car.SpeedPerc * (t.car.AdjBanking * t.car.Banking)
  t.car.model.transform.rotate(t.car.model.transform.position, t.car.model.transform.yAxis, tBanking)
  t.car.previousT = t.car.transform.duplicate()
  tCos = tWorldAxis.dot(vector(0, 0, 1))
  if (t.car.Hovering = 0) and (abs(t.car.Speed) <= 0.25) and (tCos < 0.29999999999999999) then
    me.reset(t, 1, 0)
  end if
  if (t.car.Hovering = 0) and (t.race.waypointZ <= -35.0) then
    me.reset(t, 1, 0)
  end if
  if (t.car.Hovering = 0) and (gGame.RaceState = #Racing) and (t.race.waypointZ >= 60.0) then
    DoTrophy(0, #thunderstruck)
  end if
  if gGame.RaceState = #Pending then
    me.reset(t)
  end if
  if (_player.runMode <> "Plugin") and (t.general.controller = #player) and (gGame.SlowMo = 0) then
    if keyPressed("r") then
      me.reset(t, 1, 0)
    end if
  end if
end

on reset me, t, tWaypoint, tRay
  tPosition = t.car.ResetPosition
  tRotation = t.car.ResetRotation
  if tWaypoint = 1 then
    if t.race.WayPointList.count <= 2 then
      me.reset(t, 0, 1)
      put "RERESET"
      exit
    end if
    tTransform = t.race.WayPointList[t.race.waypoint].duplicate()
    tPosition = tTransform.position + vector(0, 0, t.car.HoverDist)
    tRotation = tTransform.axisAngle
  end if
  if tRay = 1 then
    tRayDetails = gGame.Physics.rayCastClosest(tPosition + vector(0, 0, 25), vector(0, 0, -1.00099999999999989))
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
