property p
global g

on new me, tParams
  p = [:]
  pRayMemberName = tParams[#memberName]
  if pRayMemberName = VOID then
    ShowError("Script: [PS] 3D Button Script. Params: " & tParams & " Need a member to cast ray into...")
    exit
  end if
  pRayMember = member(pRayMemberName)
  if pRayMember = VOID then
    ShowError("Script: [PS] 3D Button Script. Params: " & tParams & "No such member to cast ray into..")
    exit
  end if
  pCameraName = tParams[#cameraName]
  if pCameraName = VOID then
    ShowError("Script: [PS] 3D Button Script. Params: " & tParams & " No cameraname. DefaultView has been set.")
    pCameraName = "Interface_Camera"
  end if
  if _movie.frameLabel <> "Race" then
    pCameraName = "Menu_Camera"
  end if
  p[#camera] = pRayMember.camera(pCameraName)
  if p.camera = VOID then
    ShowError("Script: [PS] 3D Button Script. Params: " & tParams & " No such camera in this member.")
    exit
  end if
  p[#member] = pRayMember
  p[#ScriptName] = "3D Button Script"
  g[#Button3DList] = []
  p[#button] = VOID
  p[#PreviousButton] = VOID
  p[#SoundPlayed] = 0
  p[#dataList] = VOID
  p[#event] = VOID
  p[#handler] = "Nothing"
  p[#alpha] = 1
  p[#CosOffset] = -PI / 2.0
  p[#StepList] = []
  return me
end

on stepFrame me
  if _mouse.mouseUp = 1 then
    if p.event <> VOID then
      pSoundName = p.dataList[#pressedSoundName]
      if pSoundName <> VOID then
        PlaySound(pSoundName)
      end if
      event(p.event)
      p.event = VOID
    end if
    if p.handler <> "Nothing" then
      pSoundName = p.dataList[#pressedSoundName]
      if pSoundName <> VOID then
        PlaySound(pSoundName)
      end if
      do(p.handler)
      p.handler = "Nothing"
    end if
  end if
  if getaProp(g, #Button3DList) = VOID then
    exit
  end if
  if p.camera = VOID then
    exit
  end if
  pButtonList = []
  pCount = g.Button3DList.count
  repeat with i = 1 to pCount
    pButtonModel = g.Button3DList[i][#model]
    if pButtonModel.ilk <> #symbol then
      pButtonList.add(pButtonModel)
    end if
  end repeat
  pOptionList = [#maxNumberOfModels: 1, #levelOfDetail: #detailed, #modelList: pButtonList]
  pPoint = _mouse.mouseLoc
  pModelList = p.camera.modelsUnderLoc(pPoint, pOptionList)
  if pModelList <> [] then
    pmodel = pModelList[1][#model]
    if pmodel <> p.PreviousButton then
      ClearButton()
    end if
    pCount = g.Button3DList.count
    p.dataList = VOID
    repeat with i = 1 to pCount
      pButtonModel = g.Button3DList[i][#model]
      if pButtonModel = VOID then
        exit
      end if
      if pmodel = pButtonModel then
        p.dataList = g.Button3DList[i]
      end if
      pButtonList.add(pButtonModel)
    end repeat
    tPick = 1
    p.alpha = p.dataList[#alpha]
    if p.alpha = 1 then
      pTextureMember = pmodel.shader.texture.member
      pimage = pTextureMember.image
      pPos = mMapPointToTexture(pModelList[1], pimage.width, pimage.height)
      pAlpha = pimage.extractAlpha().getPixel(pPos)
      if pAlpha <> color(0) then
        tPick = 1
      else
        tPick = 0
      end if
    end if
    if tPick = 1 then
      _player.cursor(280)
      p.button = pmodel
      if p.button.name contains "Branding" then
        nothing()
      else
        tSize = vector(1.0, 1.0, 1.0) * 0.29999999999999999 * abs(cos(p.CosOffset))
        p.button.transform.scale = vector(1.0, 1.0, 1.0) + tSize
        p.CosOffset = p.CosOffset + 0.19500000000000001
      end if
      if p.dataList.hack = 0 then
        tName = p.button.shaderList[1].name
        tOldDelimiter = the itemDelimiter
        the itemDelimiter = "_"
        tName = tName.item[1]
        the itemDelimiter = tOldDelimiter
        pRollOverTexture = p.member.texture(tName & "RollOver_Texture")
        if pRollOverTexture <> VOID then
          p.button.shader.texture = pRollOverTexture
        end if
      else
        tData = p.button.userData
        p.button.parent = tData.parent
      end if
      pSoundName = p.dataList[#rollOverSoundName]
      if (pSoundName <> VOID) and (p.SoundPlayed = 0) then
        PlaySound(pSoundName)
        p.SoundPlayed = 1
      end if
      if _mouse.mouseDown = 1 then
        p.event = p.dataList[#event]
        p.handler = p.dataList[#handler]
      end if
    else
      ClearButton()
    end if
  else
    ClearButton()
  end if
  if p.StepList.count > 0 then
    repeat with i in p.StepList
      if i.button.ilk = #model then
        i.button.transform.scale = i.StepList[1]
      end if
      i.StepList.deleteAt(1)
    end repeat
  end if
  tList = p.StepList.duplicate()
  repeat with i in p.StepList
    if i.StepList.count = 0 then
      tList.deleteOne(i)
    end if
  end repeat
  p.StepList = tList.duplicate()
end

on ClearButton me
  if p.button <> VOID then
    p.PreviousButton = p.button
    if p.dataList.hack = 0 then
      tName = p.button.shaderList[1].name
      tOldDelimiter = the itemDelimiter
      the itemDelimiter = "_"
      tName = tName.item[1]
      the itemDelimiter = tOldDelimiter
      pNormalTexture = p.member.texture(tName & "Normal_Texture")
      if pNormalTexture <> VOID then
        p.button.shader.texture = pNormalTexture
      end if
    else
      p.button.removeFromWorld()
    end if
    if p.button.name contains "Branding" then
      nothing()
    else
      tSteps = 3
      tScale = vector(1.0, 1.0, 1.0)
      tdiff = p.button.transform.scale - tScale
      tStep = tdiff / float(tSteps)
      tList = [#button: p.button, #StepList: []]
      repeat with i = 1 to tSteps
        if i = 1 then
          tList.StepList.add(p.button.transform.scale - tStep)
          next repeat
        end if
        tList.StepList.add(tList.StepList[i - 1] - tStep)
      end repeat
      p.StepList.add(tList)
    end if
  end if
  p.button = VOID
  p.SoundPlayed = 0
  p[#CosOffset] = -PI / 2.0
  _player.cursor(-1)
end

on mMapPointToTexture iSectList, tWidth, tHeight
  tmodel = iSectList.model
  tmodel.addModifier(#meshDeform)
  tFace = iSectList.faceID
  tUVCoord = iSectList.uvCoord
  tCoordList = tmodel.meshDeform.mesh[iSectList.meshID].textureCoordinateList
  tFaceList = tmodel.meshDeform.mesh[iSectList.meshID].face[tFace]
  tmodel.removeModifier(#meshDeform)
  tLocA = tCoordList[tFaceList[1]]
  tLocA = point(tLocA[1] * tWidth, (1 - tLocA[2]) * tHeight)
  tLocB = tCoordList[tFaceList[2]]
  tLocB = point(tLocB[1] * tWidth, (1 - tLocB[2]) * tHeight)
  tLocC = tCoordList[tFaceList[3]]
  tLocC = point(tLocC[1] * tWidth, (1 - tLocC[2]) * tHeight)
  tUVector = (tLocB - tLocA) * tUVCoord.u
  tVVector = (tLocC - tLocA) * tUVCoord.V
  return tLocA + tUVector + tVVector
end
