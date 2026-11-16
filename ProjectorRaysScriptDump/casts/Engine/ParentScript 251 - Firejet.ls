property pID, pWorld, pGroup, pParticles, pBlastShader, pSmokeShader, pParticleResource, pcamera, pJetting, pPosition, pCounter, pMe
global g

on start me
  pJetting = 1
  pCounter = 0
end

on stop me
  pJetting = 0
end

on getGroup me
  return pGroup
end

on new me, theWorld, theLocation, theCameraToPointAt, tmodel
  pWorld = theWorld
  pcamera = theCameraToPointAt
  pJetting = 1
  pPosition = pWorld.model(tmodel)
  me.script.pID = me.script.pID + 1
  pGroup = pWorld.newGroup("firejet." & me.script.pID & ".grp")
  pGroup.transform.position = theLocation
  pParticleResource = pWorld.modelResource("firejet.res")
  if voidp(pParticleResource) then
    pParticleResource = pWorld.newModelResource("firejet.res", #plane, #front)
    pParticleResource.width = 4
    pParticleResource.length = 4
  end if
  pBlastShader = me.getShader("blast", #add)
  pSmokeShader = me.getShader("smoke", #multiply)
  pParticles = []
  pMe = me
  return me
end

on getShader me, theType, theBlendMode
  shd = pWorld.shader("firejet." & theType & ".shd")
  if not voidp(shd) then
    return shd
  end if
  tex = pWorld.texture("firejet." & theType & ".tex")
  if voidp(tex) then
    i = member("firejet." & theType).image.duplicate()
    tex = pWorld.newTexture("firejet." & theType & ".tex", #fromImageObject, i)
    tex.renderFormat = #rgba8888
  end if
  shd = pWorld.newShader("firejet." & theType & ".shd", #standard)
  shd.transparent = 1
  shd.blend = 0.0
  shd.texture = tex
  shd.blendFunctionList[1] = #blend
  shd.blendConstantList[1] = 0.0
  if _movie.active3dRenderer = #openGL then
    shd.textureList[2] = tex
    shd.blendFunctionList[2] = theBlendMode
    shd.blendConstantList[2] = 0.0
  else
    shd.textureList[2] = tex
    shd.textureList[3] = tex
    shd.blendFunctionList[2] = #blend
    shd.blendConstantList[2] = 0.0
    shd.blendFunctionList[3] = theBlendMode
    shd.blendConstantList[3] = 0.0
  end if
  shd.emissive = rgb(0, 0, 0)
  shd.ambient = rgb(0, 0, 0)
  shd.diffuse = rgb(0, 0, 0)
  shd.specular = rgb(0, 0, 0)
  shd.shininess = 0.0
  return shd
end

on name me
  return "particle"
end

on deleteSystem me
  stop()
  pCount = pParticles.count
  repeat with i = 1 to pCount
    p = pParticles[i]
    pWorld.deleteModel(p.model.name)
  end repeat
  _movie.actorList.deleteOne(pMe)
end

on AddParticle me, shaderToUse, velocitybump
  if voidp(velocitybump) then
    velocitybump = vector(0, 0, 0)
  end if
  pID = pID + 1
  pFutureModel = pWorld.model("firejet.particle." & pID)
  if pFutureModel <> VOID then
    pID = pID + random(1500, 9999)
  end if
  m = pWorld.newModel("firejet.particle." & pID, pParticleResource)
  m.parent = pGroup
  m.shader = shaderToUse
  V = randomVector() * 1.64999999999999991
  p = pPosition.getWorldTransform().position
  s = random(19) - 9
  if shaderToUse.name = "firejet.smoke.shd" then
    V = V + velocitybump
  end if
  m.transform.rotation = vector(0.0, 0.0, random(1, 360))
  pParticles.add([#model: m, #position: p, #velocity: V, #life: 0, #spin: s])
end

on stepFrame me
  pCounter = pCounter + g.TimeMP
  if pCounter >= 1 then
    if pJetting then
      me.AddParticle(pBlastShader)
      me.AddParticle(pSmokeShader, vector(0, 0, 1))
    end if
    pCounter = 0
  end if
  looper = pParticles.count
  repeat while looper > 0
    me.doParticle(looper)
    looper = looper - 1
  end repeat
end

on doParticle me, looper
  p = pParticles[looper]
  p.life = p.life + (1.0 * g.TimeMP)
  if p.life > 19 then
    pWorld.deleteModel(p.model.name)
    pParticles.deleteAt(looper)
    return 
  end if
  s = 1.0 - (p.life / 19.0)
  if s < 0.10000000000000001 then
    s = 0.10000000000000001
  end if
  p.model.transform.scale = vector(s, s, s)
  p.velocity = (p.velocity * 0.40000000000000002) + vector(0, 0, 0.05)
  p.velocity = p.velocity * g.TimeMP
  p.position = p.position + p.velocity
  p.model.transform.position = p.position
  p.model.pointAt(pcamera.transform.position)
  pPp = p.life * p.spin * g.TimeMP
  p.model.rotate(0, 0, pPp, #self)
end
