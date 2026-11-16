property p
global gGame

on new me, tParams
  p = [:]
  if getaProp(gGame, #cars) = VOID then
    gGame[#cars] = [:]
  end if
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = member(tParams[#memberName])
  p[#Physics] = gGame.Physics
  p[#ScriptName] = tParams[#ScriptName]
  if p.ScriptName = VOID then
    p.ScriptName = "GenericCarScript" & string(random(1, 9999))
  end if
  p[#CarName] = tParams[#car]
  p[#controller] = symbol(tParams[#controller])
  if p.CarName = "None" then
    return VOID
  end if
  p[#CarMember] = member(p.CarName)
  p[#texture] = tParams[#texture]
  pReference = VOID
  if tParams[#startPosition] = VOID then
    pCount = 1
    pCount = pCount + gGame.cars.count
    pString = "StartPos" & pCount
    pReference = GetReferenceType(p.member, pString)
  else
    pReference = GetReferenceType(p.member, tParams[#startPosition])
  end if
  if pReference <> VOID then
    p[#ResetPosition] = pReference.transform.position
    p[#ResetRotation] = pReference.transform.axisAngle
  else
    p[#ResetPosition] = vector(0.0, 0.0, 1.0)
    p[#ResetRotation] = [vector(0.0, 0.0, 1.0), 0.0]
  end if
  tc = gGame.cars.count
  tc = tc + 1
  tPos = tc * 2.0
  p[#ResetPosition] = vector(0.0, tc, 1.0)
  p[#ResetRotation] = [vector(0.0, 0.0, 1.0), 0.0]
  p[#cManager] = 0
  if getaProp(tParams, #cManager).ilk = #integer then
    p.cManager = tParams[#cManager]
  end if
  pParamMember = member(p.CarName & "Parameters")
  if pParamMember = VOID then
    ShowError("Car script needs car parameters. Couldn't find text file for this car. Script aborted...")
    exit
  else
    p[#CarParams] = value(member(p.CarName & "Parameters").text)
  end if
  event("Setup" & p.CarName)
  pNR = gGame.cars.count + 1
  p[#car] = string(p.controller) & pNR & p.CarName
  p[#tag] = symbol(p.car)
  p[#CarGlass] = p.car & "Glass"
  p[#ChassisName] = p.car & "Proxy"
  p[#WheelNameA] = p.car & "Wheel_LB"
  p[#WheelNameB] = p.car & "Wheel_RB"
  p[#WheelNameC] = p.car & "Wheel_RF"
  p[#WheelNameD] = p.car & "Wheel_LF"
  tModelList = [p.CarName, p.CarName & "Glass", p.CarName & "Proxy", p.CarName & "Wheel_LB", p.CarName & "Wheel_RB", p.CarName & "Wheel_RF", p.CarName & "Wheel_LF"]
  tNameList = [p.car, p.CarGlass, p.ChassisName, p.WheelNameA, p.WheelNameB, p.WheelNameC, p.WheelNameD]
  CLONEMODELS(p.member, [#cloneMember: p.CarMember, #modelList: tModelList, #NameList: tNameList, #cloneShaderTag: p.car])
  if p.texture <> VOID then
    if p.member.texture(p.texture) = VOID then
      createTexture(p.member.name, [#fileName: p.texture, #filtering: #lowFiltered])
    end if
    ASSIGNTEXTURE(p.member.name, [#material: p.car & p.CarName & "_Material", #texture1: p.texture])
    ASSIGNTEXTURE(p.member.name, [#material: p.car & p.CarName & "Glass_Material", #texture1: p.texture])
    ASSIGNTEXTURE(p.member.name, [#material: p.car & p.CarName & "Wheel_Material", #texture1: p.texture])
  end if
  p[#TotalModelList] = tNameList.duplicate()
  p[#GroupHelper] = p.member.newGroup(p.car & "_Group")
  p.GroupHelper.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  p[#BBox] = p.CarMember.model(p.CarName).boundingSphere
  p[#LeftFront] = p.CarMember.model(p.CarName & "Wheel_LF")
  p[#RightFront] = p.CarMember.model(p.CarName & "Wheel_RF")
  p[#LeftBack] = p.CarMember.model(p.CarName & "Wheel_LB")
  p[#RightBack] = p.CarMember.model(p.CarName & "Wheel_RB")
  p[#LocalDown] = vector(0.0, 0.0, -1.0)
  p[#LocalForward] = vector(0.0, 1.0, 0.0)
  p[#LocalRight] = vector(1.0, 0.0, 0.0)
  p[#TempTrans] = transform()
  p[#WorldForward] = vector(0.0, 0.0, 0.0)
  p[#WorldAxis] = vector(0.0, 0.0, 0.0)
  p[#WorldRight] = vector(0.0, 0.0, 0.0)
  p[#WorldDown] = vector(0.0, 0.0, 0.0)
  p[#CurrentVel] = vector(0.0, 0.0, 0.0)
  p[#CurrentSpeed] = 0.0
  p[#AngularVel] = vector(0.0, 0.0, 0.0)
  p[#width] = abs(p.LeftFront.transform.position.x) + abs(p.RightFront.transform.position.x)
  p[#FrontWheelBase] = (abs(p.RightFront.transform.position.y) + abs(p.RightBack.transform.position.y)) / 2
  p[#BackWheelBase] = (abs(p.RightFront.transform.position.y) + abs(p.RightBack.transform.position.y)) / 2
  p[#WheelRadius] = p.CarMember.model(p.CarName & "Wheel_RF").boundingSphere[2]
  p[#WheelRadiusDEV] = abs(p.RightFront.transform.position.y - p.FrontWheelBase)
  p[#mass] = p.CarParams[#mass]
  p[#friction] = p.CarParams[#friction]
  p[#restitution] = p.CarParams[#restitution]
  p[#MaxWheelTurn] = p.CarParams[#MaxWheelTurn]
  p[#WheelSpinCoeff] = p.CarParams[#WheelSpinCoeff]
  p[#angularDamping] = 1.30000000000000004
  p[#HoverDist] = p.CarMember.model(p.CarName).transform.position.z + p.CarParams[#hoverOffset]
  p[#strength] = p.CarParams[#strength]
  p[#damping] = p.CarParams[#damping]
  p[#maxSpeed] = p.CarParams[#maxSpeed]
  p[#minSpeed] = p.CarParams[#minSpeed]
  p[#CurrentSpeed] = 0.0
  p[#buffer] = 20
  p[#topSpeed] = (p.maxSpeed - p.buffer) * 3600 / 1000
  p[#accGain] = p.CarParams[#accGain]
  p[#decGain] = p.CarParams[#decGain]
  p[#brakegain] = p.CarParams[#brakegain]
  p[#turnGain] = p.CarParams[#turnGain]
  p[#grip] = p.CarParams[#grip]
  p[#drag] = p.CarParams[#drag]
  p[#AdjGrip] = p.grip
  p[#Started] = 1
  p[#Nitro] = 0
  p[#Nitros] = 0
  p[#nitroState] = 0
  p[#NitroCounter] = 0
  p[#slip] = 0
  p[#Health] = 100.0
  if getaProp(p.CarParams, #Health).ilk = #integer then
    p.Health = p.CarParams[#Health]
  end if
  if p.controller = #AI then
    p.Health = p.Health * 2.0
  end if
  p[#StartHealth] = p.Health
  p[#CrashState] = 1
  p[#falling] = 0
  p[#flipped] = 0
  p[#TileSystem] = 1
  p[#WayPointList] = []
  p[#joystick] = 0
  if getaProp(tParams, #joystick).ilk = #integer then
    p.joystick = tParams[#joystick]
  end if
  p[#transform] = p.member.model(p.ChassisName).transform
  p[#CarList] = [:]
  p.CarList = [#origcar: p.CarName, #car: p.car, #chassis: p.ChassisName, #controller: p.controller, #state: "None", #specifics: [#speedMS: p.CurrentSpeed, #maxSpeed: p.maxSpeed, #slip: p.slip, #nitroState: p.nitroState, #heat: 0, #Started: p.Started, #checkpointList: [], #transform: p.transform, #falling: p.falling, #flipped: p.flipped, #LMColor: rgb(255, 255, 255), #rcPoint: point(0, 0), #collisionDetails: [], #WayPointList: [], #currentPosition: 1, #currentFloor: #none, #currentRootNr: 1, #currentWaypoint: 1, #currentDistance: 0.0, #inView: 0, #distanceToTarget: 0.0, #finalTime: 0, #score: 0, #positionBonus: 0, #timeBonus: 0, #conditionBonus: 0, #totalScore: 0, #pointsMultiplier: 1, #CrashState: p.CrashState, #Health: p.Health], #Keys: [#forward: 0, #backward: 0, #left: 0, #right: 0, #brake: 0, #Nitro: 0, #Crash: 0, #ImpactTime: 0]]
  gGame.cars[p.tag] = p.CarList
  p[#scriptList] = []
  InitializePhysics()
  p[#me] = me
  if p.controller = #player then
    AddScript(VOID, "[PSM] Car Player Input", [:])
  end if
  if p.cManager = 1 then
    AddScript(VOID, "[PSM] Car Collision Manager", [:])
  end if
  return me
end

on AddScript tParent, tScriptName, tDataList
  tDataList[#member] = p.member
  tDataList[#RayCastModel] = p.RayCastModel
  tDataList[#wheellist] = p.wheellist
  tDataList[#controller] = p.controller
  tDataList[#tag] = p.tag
  tDataList[#collModelName] = p.RayCastModel.name
  tDataList[#CarName] = p.CarName
  tDataList[#car] = p.car
  tDataList[#Health] = p.Health
  tDataList[#StartHealth] = p.StartHealth
  tDataList[#TotalModelList] = p.TotalModelList
  tDataList[#joystick] = p.joystick
  if getaProp(p, #me) <> VOID then
    tDataList[#parent] = p.me
  end if
  pScript = script(tScriptName).new(tDataList)
  if pScript <> VOID then
    p.scriptList.add(pScript)
  else
    ShowError("Script (Module) not added. Script was: " & tScriptName & " DataList was: " & tDataList)
  end if
end

on InitializePhysics me
  p[#ChassisMDL] = p.member.model(p.ChassisName)
  p[#RayCastModel] = p.ChassisMDL
  p[#ChassisMass] = p.mass
  p[#GravityStrength] = p.Physics.gravity.length
  p.ChassisMDL.addModifier(#meshDeform)
  p[#PhysicsCar] = p.Physics.createRigidBody(p.ChassisName, p.ChassisName, #convexShape, #dynamic)
  p.PhysicsCar.friction = p.friction
  p.PhysicsCar.restitution = p.restitution
  p.PhysicsCar.mass = p.mass
  p.PhysicsCar.angularDamping = p.angularDamping
  p.member.model(p.car).transform.position = vector(0, 0, 0)
  p.member.model(p.CarGlass).transform.position = vector(0, 0, 0)
  p.member.model(p.car).parent = p.ChassisMDL
  p.member.model(p.CarGlass).parent = p.member.model(p.car)
  repeat with i in p.TotalModelList
    if (i contains "Wheel") or (i contains "Proxy") then
      next repeat
      next repeat
    end if
    if i = p.car then
      p.member.model(i).transform.position = vector(0, 0, 0)
      p.member.model(i).parent = p.ChassisMDL
      next repeat
    end if
    tmodel = p.member.model(i)
    tParent = p.member.model(p.car)
    tOffset = tmodel.worldPosition - tParent.worldPosition
    tmodel.transform.position = tParent.worldPosition
    tmodel.parent = tParent
    tmodel.transform.position = tOffset
  end repeat
  p[#Banking] = p.CarParams[#Banking]
  p[#AdjBanking] = p.Banking
  p[#StandardTransform] = p.member.model(p.car).transform.duplicate()
  p[#LeftTransform] = p.member.model(p.car).transform.duplicate()
  p.LeftTransform.rotation = vector(0, p.AdjBanking, 0)
  p[#RightTransform] = p.member.model(p.car).transform.duplicate()
  p.RightTransform.rotation = vector(0, -p.AdjBanking, 0)
  p[#targetTransform] = p.StandardTransform
  p.Physics.RegisterCollisionCallback(#collisionCallback)
  p.member.shader(p.car & "carproxy_material").blend = 0
  p.PhysicsCar.position = p.ResetPosition
  p.PhysicsCar.orientation = p.ResetRotation
  p.PhysicsCar.linearVelocity = vector(0, 0, 0)
  p.PhysicsCar.angularVelocity = vector(0, 0, 0)
  initializeDrive()
  initializeHover()
end

on initializeDrive me
  p[#GoingForward] = 0
  p[#GoingBackward] = 0
  p[#GoingLeft] = 0
  p[#GoingRight] = 0
  p[#Braking] = 0
  p[#WheelTurn] = 0.0
  p[#WheelSpin] = 0.0
end

on initializeHover me
  p[#wheellist] = [p.member.model(p.WheelNameA), p.member.model(p.WheelNameB), p.member.model(p.WheelNameC), p.member.model(p.WheelNameD)]
  p[#IsHoveringList] = [0, 0, 0, 0]
  p[#HoverDistList] = [0.0, 0.0, 0.0, 0.0]
  com = p.PhysicsCar.centerOfMass
  p.LocalForward.normalize()
  p.LocalDown.normalize()
  p.LocalRight = p.LocalDown.cross(p.LocalForward)
  p.LocalRight.normalize()
  posA = com + (p.BackWheelBase * -p.LocalForward) + (p.width * 0.5 * -p.LocalRight)
  posB = com + (p.BackWheelBase * -p.LocalForward) + (p.width * 0.5 * p.LocalRight)
  posC = com + (p.FrontWheelBase * p.LocalForward) + (p.width * 0.5 * p.LocalRight)
  posD = com + (p.FrontWheelBase * p.LocalForward) + (p.width * 0.5 * -p.LocalRight)
  p[#WheelPointList] = [posA, posB, posC, posD]
end

on enterFrame me
  me.getKeys()
  me.UpdateVariables()
  if p.CarList[#specifics][#Health] > 0 then
    me.updateHover()
    me.updateDrive()
    me.updateWheelModels()
    me.FlipCheck()
  end if
  pLimit = me.UpdateLimit()
  pCount = p.scriptList.count
  repeat with i = 1 to pCount
    pScript = p.scriptList[i]
    pScriptLimit = pScript.p.ScriptLimit
    if (pScriptLimit = 1) and (pLimit = 1) then
      pScript.clear()
      next repeat
    end if
    pScript.enterFrame()
  end repeat
  gGame.cars[p.tag] = p.CarList
end

on UpdateVariables me
  p.TempTrans = p.ChassisMDL.transform.duplicate()
  if p.TempTrans = VOID then
    p.TempTrans = p.LastCarTransform.duplicate()
  end if
  p.TempTrans.position = vector(0, 0, 0)
  p.TempTrans.scale = vector(1, 1, 1)
  p.WorldForward = p.TempTrans * p.LocalForward
  p.WorldAxis = p.TempTrans * -p.LocalDown
  p.WorldRight = p.WorldForward.cross(p.WorldAxis)
  p.WorldDown = p.TempTrans * p.LocalDown
  p.WorldForward.normalize()
  p.WorldAxis.normalize()
  p.WorldRight.normalize()
  p.WorldDown.normalize()
  p.CurrentVel = p.PhysicsCar.linearVelocity
  p.CurrentSpeed = p.CurrentVel.dot(p.WorldForward)
  p.AngularVel = p.PhysicsCar.angularVelocity
  pTarget = p.member.model(gGame.camera.target)
  if pTarget <> VOID then
    if gGame.camera.target = p.car then
      p.CarList[#specifics][#distanceToTarget] = 0.0
    else
      P1 = p.ChassisMDL.transform.position
      P2 = pTarget.getWorldTransform().position
      p.CarList[#specifics][#distanceToTarget] = P1.distanceTo(P2)
    end if
  end if
  pPos = gGame.camera.activeCamera.worldSpaceToSpriteSpace(p.ChassisMDL.transform.position)
  if pPos = VOID then
    p.CarList[#specifics][#inView] = 0
  end if
  if pPos <> VOID then
    p.CarList[#specifics][#inView] = 1
  end if
  p.nitroState = p.CarList[#specifics][#nitroState]
  p.WayPointList = p.CarList[#specifics][#WayPointList]
  p.CarList[#specifics][#speedMS] = p.CurrentSpeed
  p.CarList[#specifics][#slip] = p.slip
  if p.joystick <> p.CarList[#joystick] then
    p.joystick = p.CarList[#joystick]
  end if
  if p.CarList[#state] = "Finished" then
    if p.joystick = 1 then
      p.joystick = 0
    end if
  end if
end

on UpdateLimit me
  if getaProp(gGame, #VisibleRootList) <> VOID then
    pCurrentRoot = gGame.cars[p.tag][#specifics][#currentRootNr]
    if gGame.VisibleRootList.getPos(pCurrentRoot) = 0 then
      return 1
    end if
  end if
  pInView = gGame.cars[p.tag][#specifics][#inView]
  if pInView = 0 then
    return 1
  end if
  pDistanceToTarget = gGame.cars[p.tag][#specifics][#distanceToTarget]
end

on reset tPosition, tRotation
  p.Health = p.StartHealth
  p.CrashState = 1
  p.CarList[#specifics][#CrashState] = p.CrashState
  p.CarList[#specifics][#Health] = p.Health
  p.PhysicsCar.position = p.ResetPosition
  p.PhysicsCar.orientation = p.ResetRotation
  p.PhysicsCar.linearVelocity = vector(0, 0, 0)
  p.PhysicsCar.angularVelocity = vector(0, 0, 0)
  pCount = p.scriptList.count
  repeat with i = 1 to pCount
    pScript = p.scriptList[i]
    pHandlers = pScript.handlers()
    if pHandlers.getPos(#reset) <> 0 then
      pScript.reset()
    end if
  end repeat
  initializeHover()
  initializeDrive()
end

on FlipCheck me
  pCosine = p.WorldAxis.dot(-p.LocalDown)
  if pCosine < 0.5 then
    p.flipped = 1
    p.CarList[#specifics][#flipped] = p.flipped
  else
    p.flipped = 0
    p.CarList[#specifics][#flipped] = p.flipped
  end if
  if (abs(p.CurrentSpeed) <= 0.25) and (p.flipped = 1) then
    me.Flip()
  end if
end

on Flip me
  p.PhysicsCar.linearVelocity = vector(0, 0, 0)
  p.PhysicsCar.angularVelocity = vector(0, 0, 0)
  pNewPos = p.PhysicsCar.position
  pNewRot = [vector(0.0, 0.0, 1.0), 0.0]
  if getaProp(gGame, #WayPointList) = VOID then
    pNewPos = p.PhysicsCar.position
    pNewRot = [vector(0.0, 0.0, 1.0), 0.0]
  else
    if gGame.WayPointList.count = 0 then
      pNewPos = p.PhysicsCar.position
      pNewRot = [vector(0.0, 0.0, -1.0), 0.0]
    else
      pCurrentWayPoint = p.CarList[#specifics][#currentWaypoint]
      pCheckList = []
      pCount = gGame.cars.count
      repeat with i = 1 to pCount
        pProp = gGame.cars.getPropAt(i)
        if pProp = symbol(p.car) then
          next repeat
        end if
        if gGame.cars[i][#specifics][#currentRootNr] = p.CarList[#specifics][#currentRootNr] then
          pCheckList.add(gGame.cars[i][#specifics][#currentWaypoint])
        end if
      end repeat
      if pCheckList <> [] then
        pCount = pCheckList.count
        repeat with i = 1 to pCount
          if pCheckList.getPos(pCurrentWayPoint) = 0 then
            exit repeat
            next repeat
          end if
          pCurrentWayPoint = pCurrentWayPoint - 1
        end repeat
      end if
      if pCurrentWayPoint < 1 then
        pCurrentWayPoint = 1
      end if
      if (pCurrentWayPoint = VOID) or (p.WayPointList = []) then
        pNewPos = p.PhysicsCar.position
        pNewRot = [vector(0.0, 0.0, 1.0), 0.0]
      else
        pFutureNr = pCurrentWayPoint + 1
        if pFutureNr > p.WayPointList.count then
          pFutureNr = p.WayPointList.count
        end if
        if pFutureNr = pCurrentWayPoint then
          pCurrentWayPoint = pCurrentWayPoint - 1
        end if
        pNewPos = p.WayPointList[pCurrentWayPoint][1]
        pFuturePos = p.WayPointList[pFutureNr][1]
        p.GroupHelper.transform.position = pNewPos
        p.GroupHelper.pointAt(pFuturePos, vector(0.0, 0.0, 1.0))
        pNewRot = p.GroupHelper.transform.axisAngle
      end if
    end if
  end if
  p.PhysicsCar.position = pNewPos + vector(0.0, 0.0, 1.25)
  p.PhysicsCar.orientation = pNewRot
end

on getKeys me
  p[#GoingForward] = p.CarList[#Keys][#forward]
  p[#GoingBackward] = p.CarList[#Keys][#backward]
  p[#GoingLeft] = p.CarList[#Keys][#left]
  p[#GoingRight] = p.CarList[#Keys][#right]
  p[#Nitro] = p.CarList[#Keys][#Nitro]
  p[#Braking] = p.CarList[#Keys][#brake]
  if (_player.runMode = "Author") or (_player.runMode = "Projector") then
    if keyPressed("r") then
      reset(p.ResetPosition, p.ResetRotation)
    end if
    if keyPressed("f") then
      Flip()
    end if
    if keyPressed("q") then
      p.CarList[#specifics][#CrashState] = 1
    end if
  end if
end

on updateDrive me
  pPowerCoeff = p.IsHoveringList[1] + p.IsHoveringList[2] + p.IsHoveringList[3] + p.IsHoveringList[4]
  pPowerCoeff = pPowerCoeff / 4.0
  if pPowerCoeff = 0 then
    return 
  end if
  if p.CurrentSpeed >= (p.maxSpeed * 0.69999999999999996) then
    pAdjTurnGain = p.turnGain
  else
    pPercentage = p.CurrentSpeed / (p.maxSpeed * 0.69999999999999996)
    pAdjTurnGain = p.turnGain * pPercentage
  end if
  if p.nitroState = 1 then
    p.NitroCounter = p.NitroCounter + 1
    gGame.NitroPercentage = p.NitroCounter / float(gGame.NitroCounter / gGame.tempo)
    gGame.NitroPercentage = max(0.0, min(1.0, gGame.NitroPercentage))
    pAdjMaxSpeed = p.maxSpeed + integer(p.maxSpeed / 4.0)
    pAdjAccGain = p.accGain * 2.0 * gGame.NitroPercentage
  else
    p.NitroCounter = 0
    gGame.NitroPercentage = 0.0
    pAdjMaxSpeed = p.maxSpeed
    pAdjAccGain = p.accGain
  end if
  pPercentage = abs(p.CurrentSpeed / pAdjMaxSpeed)
  if p.GoingForward = 1 then
    pDiff = pAdjMaxSpeed - p.CurrentSpeed
    pCurrAccGain = 0.007 + (pPercentage * pAdjAccGain)
    imp = pDiff * pCurrAccGain * p.ChassisMass * p.WorldForward * pPowerCoeff
    p.PhysicsCar.applyLinearImpulse(imp)
  end if
  if p.GoingBackward = 1 then
    pDiff = (-pAdjMaxSpeed / 2.0) - p.CurrentSpeed
    imp = pDiff * p.decGain * p.ChassisMass * p.WorldForward * pPowerCoeff
    p.PhysicsCar.applyLinearImpulse(imp)
  end if
  if p.Braking = 1 then
    imp = p.WorldForward * (-p.CurrentSpeed * p.ChassisMass) * pPowerCoeff * p.brakegain
    if p.Physics.type = #Physics then
      p.PhysicsCar.applyLinearImpulse(imp)
    end if
    if (p.GoingLeft = 1) or (p.GoingRight = 1) then
      if p.CurrentSpeed > 0.0 then
        pSpeedToCheck = p.minSpeed * 1.5
      end if
      if p.CurrentSpeed < 0.0 then
        pSpeedToCheck = p.minSpeed * 0.40000000000000002
      end if
      if abs(p.CurrentSpeed) >= pSpeedToCheck then
        p.slip = 1
        p.AdjGrip = 0.0
        if p.controller = #AI then
          pAdjGrip = pAdjGrip + 1.10000000000000009
        end if
        pAdjTurnGain = p.turnGain * 2.0
        if p.CurrentSpeed < 0.0 then
          pAdjTurnGain = -p.turnGain * 2.0
        end if
      end if
    end if
  end if
  if p.slip = 1 then
    if p.AdjGrip < p.grip then
      p.AdjGrip = p.AdjGrip + 0.02
    end if
    if p.AdjGrip > p.grip then
      p.AdjGrip = p.grip
    end if
    if p.AdjGrip = p.grip then
      p.slip = 0
    end if
  end if
  if (p.GoingLeft = 1) or (p.GoingRight = 1) then
    if (p.CurrentSpeed > 0.0) and (p.GoingForward = 1) then
      if p.GoingLeft = 1 then
        imp = p.WorldAxis * (pAdjTurnGain * (p.ChassisMass * 0.90000000000000002)) * pPowerCoeff
        if p.joystick = 1 then
          imp = imp * gGame.cars[p.tag][#Keys][#leftPerc]
        end if
        p.PhysicsCar.applyAngularImpulse(imp)
        p.targetTransform = p.LeftTransform
      end if
      if p.GoingRight = 1 then
        imp = p.WorldAxis * (-pAdjTurnGain * (p.ChassisMass * 0.90000000000000002)) * pPowerCoeff
        if p.joystick = 1 then
          imp = imp * gGame.cars[p.tag][#Keys][#rightPerc]
        end if
        p.PhysicsCar.applyAngularImpulse(imp)
        p.targetTransform = p.RightTransform
      end if
    end if
    if (p.CurrentSpeed < 0.0) and (p.GoingBackward = 1) then
      if p.GoingLeft = 1 then
        imp = p.WorldAxis * (pAdjTurnGain * (p.ChassisMass * 0.90000000000000002)) * pPowerCoeff
        if p.joystick = 1 then
          imp = imp * gGame.cars[p.tag][#Keys][#leftPerc]
        end if
        p.PhysicsCar.applyAngularImpulse(imp)
        p.targetTransform = p.LeftTransform
      end if
      if p.GoingRight = 1 then
        imp = p.WorldAxis * (-pAdjTurnGain * (p.ChassisMass * 0.90000000000000002)) * pPowerCoeff
        if p.joystick = 1 then
          imp = imp * gGame.cars[p.tag][#Keys][#rightPerc]
        end if
        p.PhysicsCar.applyAngularImpulse(imp)
        p.targetTransform = p.RightTransform
      end if
    end if
  else
    p.targetTransform = p.StandardTransform
  end if
  if (p.GoingForward = 0) and (p.GoingBackward = 0) then
    if p.GoingLeft = 1 then
      imp = p.WorldAxis * (pAdjTurnGain * (p.ChassisMass * 0.90000000000000002)) * pPowerCoeff
      p.PhysicsCar.applyAngularImpulse(imp)
      p.targetTransform = p.LeftTransform
    end if
    if p.GoingRight = 1 then
      imp = p.WorldAxis * (-pAdjTurnGain * (p.ChassisMass * 0.90000000000000002)) * pPowerCoeff
      p.PhysicsCar.applyAngularImpulse(imp)
      p.targetTransform = p.RightTransform
    end if
  end if
  pAngVelLength = p.AngularVel.length
  if pAngVelLength > 0.0 then
    pNewAdjTurnGain = pAdjTurnGain
    if pNewAdjTurnGain > 1.0 then
      pNewAdjTurnGain = 1.0
    end if
    if p.CurrentSpeed >= 0.0 then
      pCompensateGain = -pAdjTurnGain
    end if
    if p.CurrentSpeed < 0.0 then
      pCompensateGain = pAdjTurnGain
    end if
    imp = p.WorldAxis * p.AngularVel.dot(p.WorldAxis) * (pCompensateGain * p.ChassisMass) * pPowerCoeff
    p.PhysicsCar.applyAngularImpulse(imp)
  end if
  pSlideSpeed = p.WorldRight.dot(p.CurrentVel)
  imp = p.WorldRight * (-pSlideSpeed * p.ChassisMass * p.AdjGrip) * pPowerCoeff
  p.PhysicsCar.applyLinearImpulse(imp)
  imp = -p.CurrentVel * (p.drag * p.ChassisMass)
  p.PhysicsCar.applyLinearImpulse(imp)
  p[#LastCarTransform] = p.ChassisMDL.transform.duplicate()
  pCurrentTransform = p.member.model(p.car).transform
  pAdjBanking = p.Banking * (p.CurrentSpeed / pAdjMaxSpeed)
  p.LeftTransform.rotation = vector(0, pAdjBanking, 0)
  p.RightTransform.rotation = vector(0, -pAdjBanking, 0)
  if pCurrentTransform <> p.targetTransform then
    pCurrentTransform.interpolateTo(p.targetTransform, 10)
  end if
end

on updateHover me
  p.TempTrans = p.ChassisMDL.transform.duplicate()
  pChassisPos = p.PhysicsCar.position + p.PhysicsCar.centerOfMass
  repeat with i = 1 to p.WheelPointList.count
    p.IsHoveringList[i] = 0
    pWorldWheelPoint = p.TempTrans * p.WheelPointList[i]
    pIntersectDetails = p.Physics.rayCastClosest(pWorldWheelPoint, p.WorldDown + vector(0.0001, 0.0001, 0.0001))
    if pIntersectDetails <> [] then
      if (p.TileSystem = 1) and (i = 4) then
        UpdateFloorAndRoot(pIntersectDetails)
      end if
      if pIntersectDetails[4] < p.HoverDist then
        pPointVelocity = p.CurrentVel + p.AngularVel.cross(pWorldWheelPoint - pChassisPos)
        pHoverPnt = pIntersectDetails[2]
        pDiff = pHoverPnt - pWorldWheelPoint
        pLength = pDiff.length
        pF = -p.strength * (p.HoverDist - pLength)
        pF = pF - (p.damping * pPointVelocity.dot(pDiff))
        pForce = pDiff * pF * p.ChassisMass
        p.PhysicsCar.applyLinearImpulse(pForce, p.WheelPointList[i])
        p.IsHoveringList[i] = 1
        p.HoverDistList[i] = pLength
      end if
    end if
  end repeat
  if (p.IsHoveringList[1] = 0) and (p.IsHoveringList[2] = 0) and (p.IsHoveringList[3] = 0) and (p.IsHoveringList[4] = 0) then
    p.CarList[#specifics][#falling] = 1
    if p.PhysicsCar.angularVelocity.magnitude < 0.69999999999999996 then
      p.PhysicsCar.angularVelocity = p.PhysicsCar.angularVelocity * 0.69999999999999996
    end if
  else
    p.CarList[#specifics][#falling] = 0
  end if
end

on UpdateFloorAndRoot tIntersectDetails
  pName = tIntersectDetails[1].name
  pFLoorModel = p.member.model(pName)
  if pFLoorModel <> VOID then
    if gGame.FloorList.getPos(pFLoorModel) = 0 then
      exit
    end if
    p.CarList[#specifics][#currentFloor] = pFLoorModel
    pOldDelimiter = the itemDelimiter
    the itemDelimiter = "_"
    pFloorName = pFLoorModel.name
    pTrackRoot = pFloorName.item[1]
    pTrackNumber = value(pTrackRoot.char[10..pTrackRoot.length])
    if pTrackNumber < p.CarList[#specifics][#currentRootNr] then
      if gGame.camera.target = p.CarList.car then
        InterfaceWrongWay()
      end if
    end if
    p.CarList[#specifics][#currentRootNr] = pTrackNumber
    the itemDelimiter = pOldDelimiter
  end if
end

on updateWheelModels me
  pForwardVel = p.WorldForward * p.CurrentVel
  if p.GoingLeft and not (p.WheelTurn < -0.90000000000000002) then
    p.WheelTurn = p.WheelTurn - 0.10000000000000001
  end if
  if p.GoingRight and not (p.WheelTurn > 0.90000000000000002) then
    p.WheelTurn = p.WheelTurn + 0.10000000000000001
  end if
  if not p.GoingLeft and not p.GoingRight then
    if not (p.WheelTurn = 0) then
      if p.WheelTurn < 0 then
        p.WheelTurn = p.WheelTurn + 0.10000000000000001
      else
        p.WheelTurn = p.WheelTurn - 0.10000000000000001
      end if
    end if
  end if
  p[#WheelSpin] = p.WheelSpin - (pForwardVel * (p.WheelSpinCoeff * gGame.TimeMP))
  if p.WheelSpin > 360 then
    p.WheelSpin = p.WheelSpin - 360
  else
    if p.WheelSpin < -360 then
      p.WheelSpin = p.WheelSpin - 360
    end if
  end if
  repeat with i = 1 to p.IsHoveringList.count
    if p.IsHoveringList[i] = 1 then
      pWorldWheelPoint = p.ChassisMDL.transform * (p.WheelPointList[i] + vector(0, p.WheelRadiusDEV, 0))
      p.wheellist[i].transform.position = pWorldWheelPoint + (p.HoverDistList[i] * p.WorldDown) - (p.WheelRadius * p.WorldDown)
    else
      if p.IsHoveringList[i] = 0 then
        pWorldWheelPoint = p.ChassisMDL.transform * (p.WheelPointList[i] + vector(0, p.WheelRadiusDEV, 0))
        p.wheellist[i].transform.position = pWorldWheelPoint + (p.HoverDist * p.WorldDown) - (p.WheelRadius * p.WorldDown)
      end if
    end if
    p.wheellist[i].transform.rotation = p.ChassisMDL.transform.rotation
    if (i = 3) or (i = 4) then
      tempRot = p.ChassisMDL.transform.rotation
      tempRot = tempRot + (p.MaxWheelTurn * p.WheelTurn * p.WorldDown)
      p.wheellist[i].transform.rotation = tempRot
    else
      p.wheellist[i].transform.rotation = p.ChassisMDL.transform.rotation
    end if
    pTempTrans = p.wheellist[i].transform.duplicate()
    pTempTrans.position = vector(0, 0, 0)
    pTempTrans.scale = vector(1, 1, 1)
    pWheelRightDir = pTempTrans * p.LocalRight
    pWheelRightDir.normalize()
    p.wheellist[i].transform.rotate(p.wheellist[i].transform.position, pWheelRightDir, p.WheelSpin)
  end repeat
end
