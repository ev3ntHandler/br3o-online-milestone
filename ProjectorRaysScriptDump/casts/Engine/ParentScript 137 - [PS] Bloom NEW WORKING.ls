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
  p[#sprite] = sprite(1)
  p[#SourceCamera] = p.member.camera("StageGrabber_Camera")
  if p.SourceCamera = VOID then
    p.SourceCamera = p.member.newCamera("StageGrabber_Camera")
  end if
  tTargetCameraName = "DefaultView"
  if getaProp(tParams, #targetCameraName).ilk = #string then
    tTargetCameraName = tParams[#targetCameraName]
  end if
  p[#TargetCamera] = p.member.camera(tTargetCameraName)
  if p.TargetCamera = VOID then
    exit
  end if
  tSize = 0.125
  if getaProp(tParams, #size).ilk = #float then
    tSize = tParams[#size]
  end if
  p[#size] = tSize * gGame.ResRatio
  tWidth = integer(gGame.resolution[1] * p.size)
  tHeight = integer(gGame.resolution[2] * p.size)
  p[#rect] = rect(0, 0, tWidth, tHeight)
  p[#LensTexture] = p.member.newTexture("LensDirt", #fromCastMember, member("LensDirt"))
  p.LensTexture.quality = #lowFiltered
  p.LensTexture.renderFormat = #rgba8888
  tShaderName = "LensDirt_Material"
  p[#LensShader] = p.member.newShader(tShaderName, #standard)
  p.LensShader.texture = p.LensTexture
  BlendShader(p.member.name, [#materialName: tShaderName, #blendMode: #add])
  p.TargetCamera.addOverlay(p.LensTexture, point(0, 0), 0)
  tModelList = []
  tSortedNameList = []
  tSortedNameList.sort()
  repeat with i = 1 to p.member.model.count
    tmodel = p.member.model(i)
    if tmodel.name contains "Overlay-" then
      tSortedNameList.add(tmodel.name)
      tModelList.add(tmodel)
    end if
  end repeat
  tName = tSortedNameList[tSortedNameList.count]
  repeat with j in tModelList
    if j.name = tName then
      tOverlayModel = j
    end if
  end repeat
  tOverlayModel.shaderList = p.LensShader
  p[#template] = #default
  p[#BloomData] = gData.data.Bloom[p.template]
  if voidp(tParams[#template]) = 0 then
    p.template = tParams[#template]
  end if
  if voidp(gData[#data][#Bloom][p.template]) = 0 then
    p[#BloomData] = gData.data.Bloom[p.template]
  end if
  p[#RT] = p.member.newTexture("Render_Texture", #renderTexture, tWidth, tHeight)
  p.RT.renderFormat = #rgba8888
  p.RT.quality = #lowFiltered
  p.RT.updateRTImageOnRender = 1
  p[#image] = image(tWidth, tHeight, 32, 0)
  p[#BlackImage] = image(tWidth, tHeight, 32, 0)
  p.BlackImage.fill(p.BlackImage.rect, rgb(0, 0, 0))
  tTextureName = "Bloom" & string(p.template) & "_Texture"
  p[#texture] = p.member.newTexture(tTextureName, #fromImageObject, p.BlackImage)
  p.texture.quality = #lowFiltered
  p.texture.renderFormat = #rgba8888
  tShaderName = "Bloom" & string(p.template) & "_Material"
  p[#shader] = p.member.newShader(tShaderName, #standard)
  p.shader.texture = p.texture
  BlendShader(p.member.name, [#materialName: tShaderName, #blendMode: #add])
  p.TargetCamera.addOverlay(p.texture, point(0, 0), 0)
  tModelList = []
  tSortedNameList = []
  tSortedNameList.sort()
  repeat with i = 1 to p.member.model.count
    tmodel = p.member.model(i)
    if tmodel.name contains "Overlay-" then
      tSortedNameList.add(tmodel.name)
      tModelList.add(tmodel)
    end if
  end repeat
  tName = tSortedNameList[tSortedNameList.count]
  repeat with j in tModelList
    if j.name = tName then
      tOverlayModel = j
    end if
  end repeat
  tOverlayModel.shaderList = p.shader
  tOverlay = p.TargetCamera.overlay.count
  p[#overlay] = tOverlay
  p.SourceCamera.colorBuffer.clearAtRender = 0
  p.SourceCamera.transform = p.TargetCamera.transform
  p.SourceCamera.fieldOfView = p.TargetCamera.fieldOfView
  p.SourceCamera.yon = p.TargetCamera.yon
  p[#update] = 1
  tSkyBoxMember = member("Skyboxes")
  if tSkyBoxMember <> VOID then
    if tSkyBoxMember.camera("Skybox1_Camera") = p.sprite.camera(1) then
      p.member.deleteCamera("StageGrabber_Camera")
      p.SourceCamera = p.sprite.camera(1)
      p.update = 0
    end if
  end if
  p[#Counter] = 0
  p[#me] = me
  _movie.puppetTempo(60)
  return me
end

on enterFrame me
  tList = []
  tCount = p.sprite.cameraCount()
  repeat with i = 3 to tCount
    tCamera = p.sprite.camera(i)
    tList.add(tCamera.rootNode)
    tCamera.rootNode = 0
  end repeat
  tScaleList = []
  repeat with i = 1 to p.TargetCamera.overlay.count
    tScaleList.add(p.TargetCamera.overlay[i].scale)
    p.TargetCamera.overlay[i].scale = 0.0
  end repeat
  if p.update then
    p.SourceCamera.transform = p.TargetCamera.transform
    p.SourceCamera.fieldOfView = p.TargetCamera.fieldOfView
    p.SourceCamera.yon = p.TargetCamera.yon
  end if
  p.sprite.renderToTexture(p.SourceCamera, p.RT)
  repeat with i = 3 to tCount
    tCamera = p.sprite.camera(i)
    tCamera.rootNode = tList[i - 2]
  end repeat
  repeat with i = 1 to p.TargetCamera.overlay.count
    p.TargetCamera.overlay[i].scale = tScaleList[i]
  end repeat
  p.TargetCamera.overlay[p.overlay].scale = 1.0 / p.size
  p.TargetCamera.rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2])
  tSourceImage = p.image
  tTargetImage = p.RT.image
  tBlack = p.BlackImage
  tSourceImage.copyPixels(tTargetImage, tSourceImage.rect, tTargetImage.rect)
  tAdjustColorData = p.BloomData.colorFilter
  tBlurData = p.BloomData.blur
  tAdjustFilter = filter(#AdjustColorFilter, tAdjustColorData)
  tBlurFilter = filter(#BlurFilter, tBlurData)
  tSourceImage.applyFilter(tAdjustFilter)
  tSourceImage.applyFilter(tBlurFilter)
  tSourceImage.copyPixels(tBlack, tSourceImage.rect, tBlack.rect, [#blend: 100 - p.BloomData.intensity])
  p.texture.image = tSourceImage
  member("BloomImage").image = tSourceImage
end

on delete me, tTag
  if tTag = VOID then
    repeat with i = p.TargetCamera.overlay.count down to 1
      if p.TargetCamera.overlay[i].source = p.texture then
        p.TargetCamera.removeOverlay(i)
        next repeat
      end if
      if p.TargetCamera.overlay[i].source = p.member.texture("DefaultTexture") then
        p.TargetCamera.removeOverlay(i)
      end if
    end repeat
  end if
  p.image = VOID
  p.BlackImage = VOID
  p.member.deleteTexture(p.texture.name)
  p.member.deleteTexture(p.RT.name)
  gGame.AddShaders.deleteOne(p.shader)
  p.member.deleteShader(p.shader.name)
  tScript = GetScript(0, EMPTY, [#script: "[PS] Motion Blur"])
  if tScript = VOID then
    tScript = GetScript(0, EMPTY, [#script: "[PS] StageGrabber"])
    if tScript <> VOID then
      delete tScript
    end if
  end if
  if gSystem.scriptList.getPos(me) <> 0 then
    gSystem.scriptList.deleteOne(me)
  else
    gGame.scriptList.deleteOne(me)
  end if
end
