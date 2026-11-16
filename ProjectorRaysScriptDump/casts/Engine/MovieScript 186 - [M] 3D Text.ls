global gGame

on Create3DText me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tmember.type <> #shockwave3d then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tString = EMPTY
  if tDataList[#text].ilk = #string then
    tString = tDataList.text
  end if
  if tString = EMPTY then
    return 0
  end if
  tSize = 8
  if tDataList[#size].ilk = #integer then
    tSize = tDataList.size
  end if
  tSpacing = 0.05
  if tDataList[#spacing].ilk = #integer then
    tSpacing = tDataList.spacing * 0.01
  end if
  tLineSpacing = 0.0
  if tDataList[#lineSpacing].ilk = #integer then
    tLineSpacing = tDataList.lineSpacing
  end if
  tAlignH = #left
  if tDataList[#alignH].ilk = #symbol then
    tAlignH = tDataList.alignH
  end if
  if tDataList[#alignH].ilk = #string then
    tAlignH = GetReferenceType(tDataList.alignH)
  end if
  if tAlignH = VOID then
    tAlignH = #left
  end if
  tAlignHRef = VOID
  if tDataList[#alignHRef].ilk = #string then
    tAlignHRef = GetReferenceType(tmember, tDataList.alignHRef)
  end if
  tAlignV = #left
  if tDataList[#alignV].ilk = #symbol then
    tAlignV = tDataList.alignV
  end if
  if tDataList[#alignV].ilk = #string then
    tAlignV = GetReferenceType(tDataList.alignV)
  end if
  if tAlignH = VOID then
    tAlignV = #left
  end if
  tAlignVRef = VOID
  if tDataList[#alignVRef].ilk = #string then
    tAlignVRef = GetReferenceType(tmember, tDataList.alignVRef)
  end if
  tParent = VOID
  if tDataList[#parent].ilk = #string then
    tParent = GetReferenceType(tmember, tDataList.parent)
  end if
  tShader = tmember.shader("DefaultShader")
  if tDataList[#shader].ilk = #string then
    tShader = tmember.shader(tDataList.shader)
  end if
  if tShader = VOID then
    tShader = tmember.shader("DefaultShader")
  end if
  tGlow = 0
  if tDataList[#glow].ilk = #integer then
    tGlow = tDataList.glow
  end if
  tGlowShader = tmember.shader("DefaultShader")
  if tDataList[#glowShader].ilk = #string then
    tGlowShader = tmember.shader(tDataList.glowShader)
  end if
  if tGlowShader = VOID then
    tGlowShader = tmember.shader("DefaultShader")
  end if
  tOffset = vector()
  if tDataList[#offset].ilk = #vector then
    tOffset = tDataList.offset
  end if
  tgroup = tmember.newGroup(tString)
  tModelList = [#normal: [], #glow: []]
  tLastPosition = tgroup.transform.position
  tMaxHeight = 0.0
  repeat with i = 1 to tString.length
    tChar = tString.char[i]
    if tChar = " " then
      tModelList.normal.add(#space)
      if tGlow = 1 then
        tModelList.glow.add(#space)
      end if
      tLastPosition = tLastPosition + (vector(0.5, 0, 0) * tSize)
      next repeat
    end if
    tResource = tmember.modelResource(tChar)
    if tResource = VOID then
      next repeat
    end if
    tChar3D = tmember.newModel(tString & "_" & tChar & i, tResource)
    tChar3D.shader = tShader
    tChar3D.parent = tgroup
    tChar3D.transform.scale = vector(1, 1, 1) * tSize
    tChar3D.transform.position = tLastPosition + tOffset
    tWidth = VOID
    if tmember.userData <> VOID then
      tWidth = tmember.userData[#fontData][symbol(tChar)][#width]
    else
      tWidth = GetModelWidth(0, tChar3D)
    end if
    tHeight = VOID
    if tmember.userData <> VOID then
      tHeight = tmember.userData[#fontData][symbol(tChar)][#height]
    else
      tHeight = GetModelHeight(0, tChar3D)
    end if
    tCharHeight = tHeight * tSize
    if tCharHeight > tMaxHeight then
      tMaxHeight = tCharHeight
    end if
    tLastPosition = tLastPosition + (vector(tWidth, 0, 0) * tSize) + (vector(tSpacing, 0, 0) * tSize)
    tModelList.normal.add(tChar3D)
    if tGlow = 1 then
      tChar3DGlow = tmember.newModel(tString & "_" & tChar & "Glow" & i, tmember.modelResource(tChar & "Glow"))
      tChar3DGlow.shader = tGlowShader
      tChar3DGlow.parent = tgroup
      tChar3DGlow.transform.scale = tChar3D.getWorldTransform().scale
      tChar3DGlow.worldPosition = tChar3D.getWorldTransform().position
      tModelList.glow.add(tChar3DGlow)
    end if
  end repeat
  if tAlignHRef = VOID then
    tPosition = tgroup.getWorldTransform().position
  else
    tPosition = tAlignHRef.getWorldTransform().position
  end if
  if tAlignH = #left then
    tgroup.transform.position = vector(0, tPosition.y, tPosition.z)
  end if
  if tAlignH = #right then
    tgroup.transform.position = vector(gGame.resolution[1] - tLastPosition.x, tPosition.y, tPosition.z)
  end if
  if tAlignVRef = VOID then
    tPosition = tgroup.getWorldTransform().position
  else
    tPosition = tAlignVRef.getWorldTransform().position
  end if
  if tAlignV = #top then
    tgroup.transform.position = vector(tPosition.x, tPosition.y, tPosition.z - (tMaxHeight + tLineSpacing))
  end if
  if tAlignV = #bottom then
    tgroup.transform.position = vector(tPosition.x, tPosition.y, -gGame.resolution[2])
  end if
  if tParent <> VOID then
    tgroup.transform = tParent.getWorldTransform().inverse() * tgroup.transform
    tgroup.parent = tParent
  end if
  tgroup.userData.addProp(#modelList, tModelList)
  tgroup.userData.addProp(#shaderList, [tShader.name, tGlowShader.name])
  if (tDataList[#maxH].ilk = #integer) or (tDataList[#maxH].ilk = #float) then
    tMaxH = tDataList.maxH
  else
    tMaxH = #none
  end if
  if tMaxH <> #none then
    tSizeH = tChar3D.worldPosition.x + (tWidth * tSize) - tgroup.worldPosition.x
    repeat while tSizeH > tMaxH
      tgroup.transform.scale = tgroup.transform.scale - 0.01
      tSizeH = tChar3D.worldPosition.x + (tWidth * tSize) - tgroup.worldPosition.x
    end repeat
  end if
  return tgroup
end

on Delete3DText me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tmember.type <> #shockwave3d then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  if tDataList[#text].ilk = #string then
    tText = tDataList.text
  else
    tText = VOID
  end if
  if tText = VOID then
    return 0
  end if
  tgroup = tmember.group(tText)
  if tgroup = VOID then
    return 0
  end if
  if voidp(gGame.menu.textButtons[tText]) = 0 then
    gGame.menu.textButtons.deleteProp(tText)
  end if
  tList = []
  tCount = tgroup.child.count
  repeat with i = 1 to tCount
    tList.add(tgroup.child[i])
  end repeat
  repeat with i in tList
    if gGame.menu.buttons.getPos(i.name) <> 0 then
      DeleteButton(0, tmember.name, [#model: i.name])
    end if
    tmember.deleteModel(i.name)
  end repeat
  tmember.deleteGroup(tText)
  return 1
end

on GetModelWidth me, tmodel
  tmodel.addModifier(#meshDeform)
  tWidth = 0.0
  tVertexList = tmodel.meshDeform.mesh[1].vertexList
  repeat with j = 1 to tVertexList.count
    if tVertexList[j].x > tWidth then
      tWidth = tVertexList[j].x
    end if
  end repeat
  return tWidth
end

on GetModelHeight me, tmodel
  tmodel.addModifier(#meshDeform)
  tHeight = 0.0
  tVertexList = tmodel.meshDeform.mesh[1].vertexList
  repeat with j = 1 to tVertexList.count
    if tVertexList[j].z > tHeight then
      tHeight = tVertexList[j].z
    end if
  end repeat
  return tHeight
end
