property p
global gGame, gData, gSystem

on new me, tParams
  if voidp(gGame[#Bloom]) = 1 then
    exit
  end if
  if gGame.Bloom = 0 then
    exit
  end if
  if voidp(gData[#data][#Bloom]) = 1 then
    exit
  end if
  if voidp(gData[#data][#Bloom][#default]) = 1 then
    exit
  end if
  p = [:]
  p[#ScriptName] = "Bloom"
  tMemberName = EMPTY
  if getaProp(tParams, #memberName).ilk = #string then
    tMemberName = tParams[#memberName]
  end if
  p[#member] = member(tMemberName)
  if p.member = VOID then
    exit
  end if
  if voidp(gGame[#StageImage]) = 1 then
    AddScript(EMPTY, [#script: "[PS] Stage Grabber", #system: 1, #data: [:]])
  end if
  p[#SourceCamera] = p.member.camera("RTTBloomCamera")
  if p.SourceCamera = VOID then
    p.SourceCamera = p.member.newCamera("RTTBloomCamera")
  end if
  tTargetCameraName = "DefaultView"
  if getaProp(tParams, #targetCameraName).ilk = #string then
    tTargetCameraName = tParams[#targetCameraName]
  end if
  p[#TargetCamera] = p.member.camera(tTargetCameraName)
  if p.TargetCamera = VOID then
    exit
  end if
  tSize = 0.25
  if getaProp(tParams, #size).ilk = #float then
    tSize = tParams[#size]
  end if
  p[#size] = tSize * gGame.ResRatio
  p[#sprite] = sprite(GetEmptyChannel())
  tWidth = integer(gGame.resolution[1] * p.size)
  tHeight = integer(gGame.resolution[2] * p.size)
  p[#rect] = rect(0, 0, tWidth, tHeight)
  tLoc = point(integer(tWidth / 2), integer(tHeight / 2))
  CreateSprite(p.member.name, [#channel: p.sprite.spriteNum, #size: [tWidth, tHeight], #loc: tLoc, #update: 1, #dts: 0])
  p[#template] = #default
  p[#BloomData] = gData.data.Bloom[p.template]
  if voidp(tParams[#template]) = 0 then
    p.template = tParams[#template]
  end if
  if voidp(gData[#data][#Bloom][p.template]) = 0 then
    p[#BloomData] = gData.data.Bloom[p.template]
  end if
  tTextureName = "Bloom" & string(p.template) & "_Texture"
  if p.member.texture(tTextureName) = VOID then
    p[#texture] = p.member.newTexture(tTextureName)
  end if
  p.texture.quality = #lowFiltered
  p.texture.renderFormat = #rgba8888
  tShaderName = "Bloom" & string(p.template) & "_Material"
  p[#shader] = p.member.newShader(tShaderName, #standard)
  p.shader.texture = p.texture
  BlendShader(p.member.name, [#materialName: tShaderName, #blendMode: #add])
  p.TargetCamera.addOverlay(p.texture, point(0, 0), 0)
  tCount = p.TargetCamera.overlay.count
  repeat with i = 1 to tCount
    tSource = p.TargetCamera.overlay[i].source
    if tSource.name = tTextureName then
      p[#overlay] = i
      exit repeat
    end if
  end repeat
  if p.SourceCamera.name <> "DefaultView" then
    ActivateCamera(p.sprite.spriteNum, [#camera: p.SourceCamera.name])
  end if
  p.SourceCamera.colorBuffer.clearAtRender = 0
  p.SourceCamera.transform = p.TargetCamera.transform
  p.SourceCamera.fieldOfView = p.TargetCamera.fieldOfView
  if tParams[#skybox].ilk = #integer then
    tSkybox = tParams.skybox
  else
    tSkybox = 0
  end if
  if tSkybox = 1 then
    tSkyBoxMember = member("Skyboxes")
    if tSkyBoxMember <> VOID then
      p[#SkyBloomCamera] = tSkyBoxMember.newCamera("SkyBoxBloom_Camera")
      p.SkyBloomCamera.rootNode = tSkyBoxMember.group("SkyBox_Group")
      p.sprite.addCamera(p.SkyBloomCamera, 1)
      p.SkyBloomCamera.rect = rect(0, 0, p.rect[3], p.rect[4])
      p.SkyBloomCamera.transform = p.TargetCamera.transform
      p.SkyBloomCamera.fieldOfView = p.TargetCamera.fieldOfView
    end if
  end if
  p[#Counter] = 0
  p[#me] = me
  _movie.puppetTempo(60)
  return me
end

on enterFrame me
  p.Counter = p.Counter + 1
  if p.Counter = 4 then
    p.TargetCamera.overlay[1].scale = 1.0 / p.size
    tList = []
    tCount = p.member.model.count
    repeat with i = 1 to tCount
      tList.add(p.member.model(i).name)
    end repeat
    tPos = tList.getPos("Overlay-copy1")
    if tPos = 0 then
      tPos = tList.getPos("Overlay-copy2")
    end if
    if tPos = 0 then
      delete me
      exit
    end if
    p.member.model[tPos].shaderList = p.shader
    tList = VOID
    p.TargetCamera.rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2])
  end if
  p.SourceCamera.transform = p.TargetCamera.getWorldTransform()
  p.SourceCamera.fieldOfView = p.TargetCamera.fieldOfView
  if voidp(p[#SkyBloomCamera]) = 0 then
    p.SkyBloomCamera.transform.rotation = p.TargetCamera.getWorldTransform().rotation
    p.SkyBloomCamera.fieldOfView = p.TargetCamera.fieldOfView
  end if
  if voidp(gGame[#StageImage]) = 0 then
    tImg = gGame.StageImage.crop(p.sprite.rect)
    tAdjustColorData = p.BloomData.colorFilter
    tBlurData = p.BloomData.blur
    tAdjustFilter = filter(#AdjustColorFilter, tAdjustColorData)
    tBlurFilter = filter(#BlurFilter, tBlurData)
    tImg.applyFilter(tAdjustFilter)
    tImg.applyFilter(tBlurFilter)
    tNewImage = image(p.rect[3], p.rect[4], 32)
    tNewImage.fill(tNewImage.rect, rgb(0, 0, 0))
    tNewImage.copyPixels(tImg, tNewImage.rect, tImg.rect, [#blend: p.BloomData.intensity])
    p.texture.image = tNewImage
  end if
end

on delete me
  _movie.puppetSprite(p.sprite.spriteNum, 0)
  tName = p.SourceCamera.name
  p.member.deleteCamera(tName)
  tName = p.texture.name
  p.member.deleteTexture(tName)
  gGame.AddShaders.deleteOne(p.shader)
  tName = p.shader.name
  p.member.deleteShader(tName)
  if voidp(p[#SkyBloomCamera]) = 0 then
    p.member.deleteCamera("SkyBoxBloom_Camera")
  end if
  gSystem.scriptList.deleteOne(p.me)
end
