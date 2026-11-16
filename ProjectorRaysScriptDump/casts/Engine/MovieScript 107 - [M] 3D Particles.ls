global gSystem, gData, gGame

on CreateParticleSystem tTarget, tDataList
  if tTarget = VOID then
    exit
  end if
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    value(tDataList)
  end if
  tType = VOID
  if getaProp(tDataList, #type).ilk = #symbol then
    tType = tDataList[#type]
  end if
  tNameTag = EMPTY
  if tDataList[#NameTag].ilk = #string then
    tNameTag = tDataList[#NameTag]
  end if
  tPartDataList = gData.data.Particles[tType]
  if tPartDataList = VOID then
    return 0
  end if
  tNr = 1
  tFutureName = tNameTag & tType & tNr & "_Particle" & _system.milliSeconds
  tPartResource = tmember.newModelResource(tFutureName, #particle)
  tPartResource.emitter.numParticles = 20
  tPartResource.lifeTime = 500.0
  tPartResource.emitter.minSpeed = 0.0
  tPartResource.emitter.maxSpeed = 0.0
  tPartResource.sizeRange.start = 1.0
  tPartResource.sizeRange.end = 0.0
  tPartResource.blendRange.start = 100.0
  tPartResource.blendRange.end = 0.0
  tPartResource.colorRange.start = color(255, 255, 255)
  tPartResource.colorRange.end = color(255, 255, 255)
  tPartResource.emitter.distribution = #linear
  tPartResource.emitter.mode = #stream
  tPartResource.tweenMode = #age
  tPartResource.emitter.loop = 1
  tPartResource.emitter.angle = 0.0
  tPartResource.drag = 0.0
  tPartResource.emitter.direction = vector(0.0, 0.0, 1.0)
  tPartResource.gravity = vector(0.0, 0.0, 0.0)
  tPartResource.wind = vector(0.0, 0.0, 0.0)
  tPartResource.emitter.region = [vector(0.0, 0.0, 0.0)]
  tPartResource.texture = VOID
  tPartResource.paused = 0
  if tPartDataList <> VOID then
    if getaProp(tPartDataList, #amount).ilk = #integer then
      tPartResource.emitter.numParticles = tPartDataList[#amount]
    end if
    if getaProp(tPartDataList, #lifeTime).ilk = #float then
      tPartResource.lifeTime = tPartDataList[#lifeTime]
    end if
    if getaProp(tPartDataList, #minSpeed).ilk = #float then
      tPartResource.emitter.minSpeed = tPartDataList[#minSpeed]
    end if
    if getaProp(tPartDataList, #maxSpeed).ilk = #float then
      tPartResource.emitter.maxSpeed = tPartDataList[#maxSpeed]
    end if
    if getaProp(tPartDataList, #SizeStart).ilk = #float then
      tPartResource.sizeRange.start = tPartDataList[#SizeStart]
    end if
    if getaProp(tPartDataList, #SizeEnd).ilk = #float then
      tPartResource.sizeRange.end = tPartDataList[#SizeEnd]
    end if
    if getaProp(tPartDataList, #blendStart).ilk = #float then
      tPartResource.blendRange.start = tPartDataList[#blendStart]
    end if
    if getaProp(tPartDataList, #blendEnd).ilk = #float then
      tPartResource.blendRange.end = tPartDataList[#blendEnd]
    end if
    if getaProp(tPartDataList, #colorStart).ilk = #color then
      tPartResource.colorRange.start = tPartDataList[#colorStart]
    end if
    if getaProp(tPartDataList, #colorEnd).ilk = #color then
      tPartResource.colorRange.end = tPartDataList[#colorEnd]
    end if
    if getaProp(tPartDataList, #distribution).ilk = #symbol then
      tPartResource.emitter.distribution = tPartDataList[#distribution]
    end if
    if getaProp(tPartDataList, #mode).ilk = #symbol then
      tPartResource.emitter.mode = tPartDataList[#mode]
    end if
    if getaProp(tPartDataList, #tweenMode).ilk = #symbol then
      tPartResource.tweenMode = tPartDataList[#tweenMode]
    end if
    if getaProp(tPartDataList, #loop).ilk = #integer then
      tPartResource.emitter.loop = tPartDataList[#loop]
    end if
    if getaProp(tPartDataList, #angle).ilk = #float then
      tPartResource.emitter.angle = tPartDataList[#angle]
    end if
    if getaProp(tPartDataList, #drag).ilk = #float then
      tPartResource.drag = tPartDataList[#drag]
    end if
    if getaProp(tPartDataList, #direction).ilk = #vector then
      tPartResource.emitter.direction = tPartDataList[#direction]
    end if
    if getaProp(tPartDataList, #gravity).ilk = #vector then
      tPartResource.gravity = tPartDataList[#gravity]
    end if
    if getaProp(tPartDataList, #wind).ilk = #vector then
      tPartResource.wind = tPartDataList[#wind]
    end if
    if getaProp(tPartDataList, #region).ilk = #list then
      tPartResource.emitter.region = tPartDataList[#region]
    end if
    if getaProp(tPartDataList, #texture).ilk = #string then
      tTexture = tmember.texture(tPartDataList[#texture])
      if tTexture = VOID then
        tTexture = createTexture(tmember.name, [#fileName: tPartDataList[#texture], #filtering: #lowFiltered, #renderFormat: #rgba8888])
      end if
      tPartResource.texture = tTexture
    end if
    if getaProp(tPartDataList, #pause).ilk = #integer then
      tPartResource.emitter.pause = tPartDataList[#pause]
    end if
  end if
  tPartModel = tmember.newModel(tFutureName, tPartResource)
  return tPartModel
end
