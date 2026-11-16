property p
global g

on new me, tParams
  p = [:]
  p[#member] = tParams[#member]
  p[#ProxyModelName] = tParams[#collModelName]
  p[#car] = tParams[#car]
  p[#CarName] = tParams[#CarName]
  p[#wheellist] = tParams[#wheellist]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#tag] = tParams[#tag]
  p[#controller] = tParams[#controller]
  p[#collModelName] = symbol(tParams[#collModelName])
  p[#TotalModelList] = tParams[#TotalModelList]
  p[#CollisionPosition] = VOID
  p[#PhysicsCar] = g.Physics.getRigidBody(tParams[#collModelName])
  p[#mass] = p.PhysicsCar.mass
  pHealth = tParams[#Health]
  p[#StartHealth] = tParams[#StartHealth]
  p[#Health1] = integer(pHealth / 100.0 * 80.0)
  p[#Health2] = integer(pHealth / 100.0 * 35.0)
  p[#SoundPrio1] = #low
  p[#SoundPrio2] = #medium
  if p.controller = #player then
    p.SoundPrio1 = #medium
    p.SoundPrio2 = #high
  end if
  p[#ScriptLimit] = 0
  p[#OverHeated] = 0
  p[#AlarmCounter] = 10
  SetupCollision()
  p[#me] = me
  return me
end

on enterFrame me
  HandleCollision()
end

on SetupDirtCam me
  tmodel = g.interface.model("DIrt")
  tCount = tmodel.child.count
  p[#DirtList] = []
  repeat with i = 1 to tCount
    tChild = tmodel.child[i]
    p.DirtList.add(tChild)
  end repeat
end

on SetupCollision me
  p[#CrashTexture3] = p.member.texture("Crumpled_Texture")
  if p.CrashTexture3 = VOID then
    p.CrashTexture3 = createTexture(p.member.name, [#fileName: "Crumpled_Texture", #filtering: #lowFiltered])
  end if
  p[#shaderList] = [p.member.shader("player1TruckTruck_Material"), p.member.shader("player1TruckTruckWheel_Material")]
  p[#OriginalTexture] = p.member.texture(p.CarName & "_Texture")
  p[#ReflectionTexture] = p.member.texture(p.CarName & "Reflection_Texture")
  p[#CarModel] = p.member.model(p.car)
  p[#GlassModel] = p.member.model(p.car & "Glass")
  p[#CurrentState] = 1
end

on HandleCollision me
  if (g.cars[p.tag][#state] = "Done") or (g.cars[p.tag][#state] = "Finished") then
    exit
  end if
  p[#Health] = g.cars[p.tag][#specifics][#Health]
  p[#CrashState] = g.cars[p.tag][#specifics][#CrashState]
  p[#nitroState] = g.cars[p.tag][#specifics][#nitroState]
  p[#falling] = g.cars[p.tag][#specifics][#falling]
  if (p.Health = 0) or (p.OverHeated = 1) then
    exit
  end if
  if p.CurrentState <> p.CrashState then
    SetState(p.CrashState)
  end if
  if getaProp(g, #collisionReports) = VOID then
    exit
  end if
  if getaProp(g.collisionReports, p.collModelName) <> VOID then
    pCollisionDetails = g.collisionReports[p.collModelName]
    g.cars[p.tag][#specifics][#collisionDetails] = pCollisionDetails.duplicate()
  else
    pCollisionDetails = []
  end if
  if p.CollisionPosition <> VOID then
    pLength = (p.PhysicsCar.linearMomentum - p.CollisionPosition).length
    pLength = pLength / p.mass
    pForce = p.mass * (pLength / (2.0 / 30))
    pForce = pForce * 0.00001
    p.CollisionPosition = VOID
    if g.cars[p.tag][#state] = "None" then
      p.Health = p.Health - pForce
      if (p.Health <= p.Health1) and (p.CrashState < 2) then
        SetState(2)
      end if
      if (p.Health <= p.Health2) and (p.CrashState < 3) then
        SetState(3)
      end if
      if (p.Health <= 0.0) and (p.CrashState < 4) then
        SetState(4)
      end if
      if (p.Health <= 80) and (p.Health > 60) then
        SETVISIBLE(g.interface.name, [#modelList: ["HealthBar1"], #parentName: "Thermometer", #state: 1])
      end if
      if (p.Health <= 61) and (p.Health > 40) then
        SETVISIBLE(g.interface.name, [#modelList: ["HealthBar2"], #parentName: "Thermometer", #state: 1])
      end if
      if (p.Health <= 41) and (p.Health > 20) then
        SETVISIBLE(g.interface.name, [#modelList: ["HealthBar3"], #parentName: "Thermometer", #state: 1])
      end if
      if (p.Health <= 21) and (p.Health > 0) then
        SETVISIBLE(g.interface.name, [#modelList: ["HealthBar4"], #parentName: "Thermometer", #state: 1])
      end if
      if p.Health <= 0 then
        SETVISIBLE(g.interface.name, [#modelList: ["HealthBar5"], #parentName: "Thermometer", #state: 1])
      end if
    end if
    if g.GameInput = 1 then
      PlaySound("Bump", [#priority: #low, #rateShift: random(-6, 8), #surround: 1, #member3DName: p.member.name, #sender: p.ProxyModelName, #targetName: p.ProxyModelName, #referenceName: "DefaultView", #distance: [10, 60], #static: 1])
      if pForce >= 0.75 then
        PlaySound("Clunk", [#priority: #low, #surround: 1, #member3DName: p.member.name, #random: [1, 3], #sender: p.ProxyModelName, #targetName: p.ProxyModelName, #referenceName: "DefaultView", #distance: [10, 60], #static: 1])
      end if
    end if
  end if
  if pCollisionDetails <> [] then
    p.CollisionPosition = p.PhysicsCar.linearMomentum
  end if
  g.cars[p.tag][#specifics][#collisionDetails] = g.collisionReports[p.collModelName].duplicate()
  g.collisionReports[p.collModelName] = []
  g.cars[p.tag][#specifics][#Health] = p.Health
end

on SetState tCrashState
  if tCrashState = 1 then
    SetReflectionTexture(p.ReflectionTexture)
    p.CarModel.visibility = #front
    p.GlassModel.visibility = #front
    pCount = p.wheellist.count
    repeat with j = 1 to pCount
      if g.Physics.getRigidBody(p.wheellist[j].name) <> VOID then
        g.Physics.deleteRigidBody(p.wheellist[j].name)
      end if
    end repeat
    p.Health = p.StartHealth
    SETVISIBLE(g.interface.name, [#modelList: ["HealthBar1", "HealthBar2", "HealthBar3", "HealthBar4", "HealthBar5"], #state: 0])
  end if
  if tCrashState = 2 then
    SetReflectionTexture(VOID)
  end if
  if tCrashState = 3 then
  end if
  if tCrashState = 4 then
    SetTexture(p.CrashTexture3)
    SetReflectionTexture(VOID)
    p.Health = 0
    g.cars[p.tag][#specifics][#Health] = p.Health
    g.cars[p.tag][#state] = "Dead"
    g.cars[p.tag][#specifics][#score] = 0
    g.cars[p.tag][#specifics][#positionBonus] = 0
    g.cars[p.tag][#specifics][#timeBonus] = 0
    g.cars[p.tag][#specifics][#conditionBonus] = 0
    g.cars[p.tag][#specifics][#totalScore] = 0
    g.cars[p.tag][#specifics][#finalTime] = g.RaceTime
    pExplosion = new(script("[PPS] Car Explosion"), p.member, vector(0, 0, 0), p.member.camera("DefaultView"), p.PhysicsCar.name, 8000)
    _movie.actorList.add(pExplosion)
    p.CarModel.visibility = #both
    p.GlassModel.visibility = #none
    pRandomVector = randomVector()
    p.PhysicsCar.applyLinearImpulse(vector(pRandomVector.x * 1000, pRandomVector.y * 1000, 25000.0))
    p.PhysicsCar.applyTorque(vector(pRandomVector.x * 450000, pRandomVector.y * 450000, pRandomVector.z * 550000))
    pCount = p.wheellist.count
    repeat with i = 1 to pCount
      pWheel = p.wheellist[i]
      pTransform = pWheel.getWorldTransform()
      pWheel.parent = p.member.group("World")
      pWheel.transform = pTransform
      pModifierList = pWheel.modifier
      if pModifierList.getPos(#meshDeform) = 0 then
        pWheel.addModifier(#meshDeform)
      end if
      tName = pWheel.name
      pRB = g.Physics.createRigidBody(tName, tName, #convexShape, #dynamic)
      pRB.restitution = 0.20000000000000001
      pRB.friction = 0.5
      pRB.mass = 20.0
      tList = g.LocalData.TruckCollectedOptions
      repeat with i in tList
        if i = "Rims" then
          next repeat
        end if
        tmodel = g.member.model(g.cars[1].car & i)
        tmodel.addModifier(#meshDeform)
        tPos = tmodel.worldPosition
        tmodel.parent = g.member.group("World")
        tmodel.transform.position = tPos
        tName = tmodel.name
        pRB = g.Physics.createRigidBody(tName, tName, #convexShape, #dynamic)
        pRB.restitution = 0.20000000000000001
        pRB.friction = 0.5
        pRB.mass = 20.0
        pRB.linearVelocity = p.PhysicsCar.linearVelocity
      end repeat
      g.member.model(g.cars[1].car).shader.blendConstantList[3] = 0
    end repeat
    if g.RaceState = "Pending" then
      if p.controller = #player then
        timeout().new("DelayImpactTime", 100, #DelayImpactTime, p.me)
        g.camera.offset = vector(0.0, -10.0, 5.0)
        g.camera.rotation = vector(60.0, 0.0, 0.0)
        g.RaceState = "RaceOver"
        timeout().new("PlayerEndRace", 5000, #PlayerEndRace, p.me)
      else
      end if
    end if
  end if
  p.CurrentState = tCrashState
  p.CrashState = tCrashState
  g.cars[p.tag][#specifics][#CrashState] = p.CrashState
  if (tCrashState = 2) or (tCrashState = 3) then
    PlaySound("Crash", [#priority: p.SoundPrio1, #surround: 1, #member3DName: p.member.name, #random: [1, 3], #sender: p.ProxyModelName, #targetName: p.ProxyModelName, #referenceName: "DefaultView", #distance: [20, 200], #static: 1])
    PlaySound("BreakingGlass", [#priority: p.SoundPrio1, #surround: 1, #member3DName: p.member.name, #rateShift: random(-4, 4), #sender: p.ProxyModelName, #targetName: p.ProxyModelName, #referenceName: "DefaultView", #distance: [20, 200], #static: 1])
  end if
  if tCrashState = 4 then
    PlaySound("CrashGlass", [#priority: #high, #surround: 1, #member3DName: p.member.name, #rateShift: random(-4, 4), #sender: p.ProxyModelName, #targetName: p.ProxyModelName, #referenceName: "DefaultView", #distance: [20, 200], #static: 1])
    PlaySound("Explosion1", [#priority: #high, #surround: 1, #member3DName: p.member.name, #sender: p.ProxyModelName, #targetName: p.ProxyModelName, #referenceName: "DefaultView", #distance: [20, 200], #static: 1])
    PlaySound("Fire", [#priority: #high, #surround: 1, #member3DName: p.member.name, #sender: p.ProxyModelName, #targetName: p.ProxyModelName, #referenceName: "DefaultView", #distance: [20, 200], #static: 1, #loopCount: 3])
  end if
end

on SetTexture tTexture
  if tTexture = VOID then
    exit
  end if
  pCount = p.shaderList.count
  repeat with i = 1 to pCount
    pShader = p.shaderList[i]
    pShader.texture = tTexture
  end repeat
end

on SetReflectionTexture tTexture
  pCount = p.shaderList.count
  repeat with i = 1 to pCount
    pShader = p.shaderList[i]
    if pShader.name contains "Wheel" then
      next repeat
    end if
    pShader.textureList[2] = tTexture
  end repeat
end

on reset me
  SetState(1)
end

on DelayImpactTime me
  event("ImpactTimeOn")
  timeout("DelayImpactTime").forget()
end

on PlayerEndRace me
  timeout("PlayerEndRace").forget()
  g.MissionState = "Failure"
  event("FinishRace")
end

on ShowDirt tAmount, tState
  if tAmount = VOID then
    tAmount = p.DirtList.count
  end if
  tList = p.DirtList.duplicate()
  tNewList = []
  repeat with i = 1 to tAmount
    tDirt = p.DirtList[random(1, tList.count)]
    tNewList.add(tDirt)
    tList.deleteOne(tDirt)
  end repeat
  repeat with i in tNewList
    p.DirtList.deleteOne(i)
  end repeat
  tTimeOut = timeout().new("ShowAnimatedDirt", 100, #ShowAnimatedDirt, tNewList)
end

on HandleEngineHeat me
  if p.OverHeated = 1 then
    exit
  end if
  p[#heat] = g.cars[p.tag][#specifics][#heat]
  tDuration = 150.0
  if p.nitroState = 1 then
    p.heat = p.heat + g.NitroFill
  else
    p.heat = p.heat - g.NitroDrain
  end if
  p.heat = max(0, min(tDuration, p.heat))
  x = p.heat / tDuration
  y = (-1.0 * (x * x)) + (2.0 * x)
  tPosition = 1.0 - y
  g.cars[p.tag][#specifics][#heat] = p.heat
  g.interface.shader("BoostGradient_Material").textureTransformList[2].position = vector(0.0, tPosition, 0.0)
  if p.heat >= (tDuration - 40) then
    if _movie.timeoutList.getPos(timeout("HeatWarning")) = 0 then
      timeout().new("HeatWarning", 462, #HeatWarning, p.me)
    end if
  end if
  if p.nitroState = 0 then
    if _movie.timeoutList.getPos(timeout("HeatWarning")) <> 0 then
      timeout("HeatWarning").forget()
      g.interface.shader("BoostGradient_Material").blendFunctionList[2] = #multiply
    end if
  end if
end

on HeatWarning me
  PlaySound("Warning", [#priority: #high])
  timeout("HeatWarning").period = timeout("HeatWarning").period - 33
  tBlend = g.interface.shader("BoostGradient_Material").blendFunctionList[2]
  if tBlend = #add then
    tBlend = #multiply
  else
    tBlend = #add
  end if
  g.interface.shader("BoostGradient_Material").blendFunctionList[2] = tBlend
  if timeout("HeatWarning").period = 0 then
    p.OverHeated = 1
    SetState(4)
    timeout("HeatWarning").forget()
  end if
end

on CreateCrashParticles tParams
  pTag = tParams[#tag]
  pPosition = tParams[#position]
  pDirection = tParams[#direction]
  pTexture = tParams[#texture]
  pType = tParams[#type]
  pResource = p.member.newModelResource(pTag & pType, #particle)
  pResource.emitter.numParticles = 20
  pResource.emitter.mode = #burst
  pResource.emitter.minSpeed = 5.0
  pResource.emitter.maxSpeed = 6.0
  pResource.emitter.loop = 0
  pResource.colorRange.start = color(0, 0, 0)
  pResource.colorRange.end = color(0, 0, 0)
  pResource.sizeRange.start = 1.5
  pResource.sizeRange.end = 1.5
  pResource.emitter.angle = 90.0
  pResource.emitter.direction = pDirection
  pResource.lifeTime = 2500.0
  pResource.blendRange.start = 100.0
  pResource.blendRange.end = 100
  pResource.drag = 0
  pResource.gravity = vector(0.0, 0.0, -0.25)
  pTexture = p.member.texture(pTexture)
  if pTexture = VOID then
    pTexture = createTexture(p.member.name, [#fileName: pTexture, #filtering: #lowFiltered, #renderFormat: #rgba4444])
  end if
  pResource.texture = pTexture
  pmodel = p.member.newModel(pTag & pType, pResource)
  pmodel.transform.position = pPosition
  return pmodel
end

on DeleteCrashParticles me
  pName = p.DebrisParticles.name
  p.member.deleteModel(pName)
  p.member.deleteModelResource(pName)
  timeout("DeleteCrashParticles").forget()
end
