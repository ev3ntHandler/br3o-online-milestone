property p, pID
global gSystem, gGame

on new me, theWorld, theLocation, theCameraToPointAt, tmodel, tDuration
  p = [:]
  p[#member] = theWorld
  p[#camera] = theCameraToPointAt
  p[#Jetting] = 1
  if tmodel = VOID then
    tResource = p.member.newModelResource("NoModelExplosion" & _system.milliSeconds & random(1, 1000), #plane, #front)
    p[#model] = p.member.newModel("NoModelExplosion" & _system.milliSeconds & random(1, 1000), tResource)
  else
    p[#model] = p.member.model(tmodel)
  end if
  p[#ModelName] = p.model.name
  p[#duration] = tDuration
  if p.duration = VOID then
    p.duration = 4000
  end if
  p[#Counter] = 0.0
  me.script.pID = me.script.pID + 1
  p[#group] = p.member.newGroup("CarExplosion" & p.ModelName & me.script.pID & "_Group")
  p.group.transform.position = theLocation
  p[#PartResource] = p.member.modelResource("ParticleExplosion")
  if p.PartResource = VOID then
    p[#PartResource] = p.member.newModelResource("ParticleExplosion", #plane, #front)
    p.PartResource.width = 4
    p.PartResource.length = 4
  end if
  p[#ExploShader] = me.getShader("PartExplosion_Material", #add)
  p[#SmokeShader] = me.getShader("PartSmoke_Material", #multiply)
  p[#Particles] = []
  p[#TimeOutName] = p.ModelName & "StopJetting" & pID
  timeout().new(p.TimeOutName, p.duration, #StopJetting, me)
  p[#me] = me
  return me
end

on enterFrame me
  if gGame.pause = 1 then
    exit
  end if
  if p.model = VOID then
    me.deleteSystem()
    exit
  end if
  p.Counter = p.Counter + gGame.TimeMP
  if p.Counter >= 1.0 then
    if p.Jetting = 1 then
      me.AddParticle(p.ExploShader)
      me.AddParticle(p.SmokeShader, vector(0, 0, 1))
      p.Counter = 0
    end if
  end if
  pCount = p.Particles.count
  repeat while pCount > 0
    me.doParticle(pCount)
    pCount = pCount - 1
  end repeat
end

on start me
  p.Jetting = 1
  p.Counter = 0
end

on stop me
  p.Jetting = 0
end

on getGroup me
  return p.group
end

on name me
  return "particle"
end

on StopJetting me
  me.stop()
  timeout(p.TimeOutName).forget()
end

on getShader me, tShaderName, tBlendMode
  pShader = p.member.shader(tShaderName)
  if pShader <> VOID then
    return pShader
  end if
  if tShaderName = "PartExplosion_Material" then
    pTextureName = "Explosion2_Texture"
  end if
  if tShaderName = "PartSmoke_Material" then
    pTextureName = "Smoke2_Texture"
  end if
  pTexture = p.member.texture(pTextureName)
  if pTexture = VOID then
    pTexture = createTexture(p.member.name, [#fileName: pTextureName, #filtering: #lowFiltered, #renderFormat: #rgba8888])
  end if
  pShader = p.member.newShader(tShaderName, #standard)
  pShader.texture = pTexture
  pShader.emissive = rgb(255, 255, 255)
  pShader.shininess = 0.0
  BlendShader(p.member.name, [#materialName: pShader.name, #blendMode: tBlendMode])
  return pShader
end

on deleteSystem me
  me.stop()
  if _movie.timeoutList.getPos(timeout(p.TimeOutName)) <> 0 then
    timeout(p.TimeOutName).forget()
  end if
  pCount = p.Particles.count
  repeat with i = 1 to pCount
    pPart = p.Particles[i]
    pmodel = pPart.model
    if pmodel = VOID then
      next repeat
    end if
    p.member.deleteModel(pPart.model.name)
  end repeat
  gGame.scriptList.deleteOne(p.me)
end

on AddParticle me, tShaderToUse, velocitybump
  if voidp(velocitybump) then
    velocitybump = vector(0, 0, 0)
  end if
  pID = pID + 1
  m = p.member.newModel("PartExplosion" & p.ModelName & pID, p.PartResource)
  m.parent = p.group
  m.shader = tShaderToUse
  V = randomVector() * 1.64999999999999991
  Pos = p.model.getWorldTransform().position + (randomVector() * (random(5, 12) * 0.10000000000000001))
  s = random(19) - 9
  tRandom = random(10, 30) * 0.10000000000000001
  m.transform.scale = vector(tRandom, tRandom, tRandom)
  if tShaderToUse.name = "firejet.smoke.shd" then
    V = V + velocitybump
  end if
  m.transform.rotation = vector(0.0, 0.0, random(1, 360))
  p.Particles.add([#model: m, #position: Pos, #velocity: V, #life: 0, #spin: s, #startSize: tRandom])
end

on doParticle me, tCount, tNr
  if p.model = VOID then
    me.deleteSystem()
  end if
  pPart = p.Particles[tCount]
  pPart.life = pPart.life + (1.0 * gGame.TimeMP)
  if pPart.life > 19 then
    p.member.deleteModel(pPart.model.name)
    p.Particles.deleteAt(tCount)
    if p.Particles.count = 0 then
      me.deleteSystem()
    end if
    return 
  end if
  s = sin(pPart.life * PI / 20.0)
  s = max(0.01, s)
  if s < 0.10000000000000001 then
    s = 0.10000000000000001
  end if
  pPart.model.transform.scale = vector(s, s, s)
  pPart.velocity = (pPart.velocity * 0.40000000000000002) + vector(0, 0, 0.05)
  pPart.velocity = pPart.velocity * gGame.TimeMP
  pPart.position = pPart.position + pPart.velocity
  pPart.model.transform.position = pPart.position
  pPart.model.pointAt(p.camera.transform.position)
end
