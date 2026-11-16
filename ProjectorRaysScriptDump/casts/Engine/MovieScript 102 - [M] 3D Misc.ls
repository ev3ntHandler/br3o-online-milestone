global g, gGame

on SETVISIBLE me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return []
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return []
  end if
  tProp = #model
  if voidp(tDataList[#group]) = 0 then
    tProp = #group
  end if
  if voidp(tDataList[#light]) = 0 then
    tProp = #light
  end if
  if voidp(tDataList[#camera]) = 0 then
    tProp = #camera
  end if
  tTargetList = []
  if tDataList[tProp].ilk = #void then
    tDataList[#model] = "*.*"
  end if
  if tDataList[tProp].ilk = #list then
    tTargetList = tDataList[tProp]
    tList = []
    repeat with i in tTargetList
      if tProp = #model then
        tEntry = tmember.model(i)
      end if
      if tProp = #group then
        tEntry = tmember.group(i)
      end if
      if tProp = #light then
        tEntry = tmember.light(i)
      end if
      if tProp = #camera then
        tEntry = tmember.camera(i)
      end if
      if tEntry <> VOID then
        tList.add(tEntry)
      end if
    end repeat
    tTargetList = tList.duplicate()
  else
    if tDataList[tProp].ilk = #string then
      if tDataList[tProp].char[1] = "*" then
        tString = tDataList[tProp]
        if tString <> "*.*" then
          delete tString.char[1]
        end if
        tTargetList = GetObjectList(0, tmember.name, [#type: tProp, #string: tString, #Reference: 1])
      else
        if tProp = #model then
          tTargetList.add(tmember.model(tDataList[tProp]))
        end if
        if tProp = #group then
          tTargetList.add(tmember.group(tDataList[tProp]))
        end if
        if tProp = #light then
          tTargetList.add(tmember.light(tDataList[tProp]))
        end if
        if tProp = #camera then
          tTargetList.add(tmember.camera(tDataList[tProp]))
        end if
      end if
    end if
  end if
  if tTargetList.count = 0 then
    return []
  end if
  tState = 1
  if tDataList[#state].ilk = #integer then
    tState = tDataList.state
  end if
  tParent = VOID
  if tDataList[#parent].ilk = #string then
    tParent = GetReferenceType(tmember, tDataList.parent)
  end if
  repeat with i in tTargetList
    if i = VOID then
      next repeat
    end if
    if tState = 1 then
      tUD = i.userData
      if tParent = VOID then
        if voidp(tUD[#parent]) = 1 then
          i.parent = tmember.group("World")
        else
          i.parent = tUD[#parent]
        end if
      else
        i.parent = tParent
      end if
      next repeat
    end if
    tUD = i.userData
    if voidp(tUD[#parent]) = 1 then
      tUD[#parent] = i.parent
    end if
    i.parent = VOID
  end repeat
  return tTargetList
end

on CreateObject me, tTarget, tDataList
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
  tName = VOID
  if tDataList[#name].ilk = #string then
    tName = tDataList.name
  end if
  if tName = VOID then
    return 0
  end if
  tType = VOID
  tTypes = [#texture, #shader, #model, #light, #group, #motion, #camera]
  if tDataList[#type].ilk = #symbol then
    if tTypes.getPos(tDataList.type) <> 0 then
      tType = tDataList.type
    end if
  end if
  if tType = VOID then
    return 0
  end if
  case tType of
    #texture:
      return tmember.newTexture(tName)
    #shader:
      return tmember.newShader(tName, #standard)
    #model:
      return tmember.newModel(tName, tmember.modelResource("DefaultModel"))
    #camera:
      return tmember.newCamera(tName)
    #light:
      return tmember.newLight(tName, #point)
    #group:
      return tmember.newGroup(tName)
    #motion:
      return tmember.newMotion(tName)
    otherwise:
      return 0
  end case
end

on SetPosDir me, tTarget, tDataList
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
  tObject = VOID
  if tDataList[#object].ilk = #string then
    tObject = GetReferenceType(tmember, tDataList.object)
  end if
  if tObject = VOID then
    return 0
  end if
  tPosition = VOID
  if tDataList[#position].ilk = #vector then
    tPosition = tDataList.position
  else
    if tDataList[#position].ilk = #string then
      tRefObject = GetReferenceType(tmember, tDataList.position)
      if tRefObject <> VOID then
        tPosition = tRefObject.getWorldTransform().position
      end if
    end if
  end if
  if tPosition <> VOID then
    tObject.worldPosition = tPosition
  end if
  tRotation = VOID
  if tDataList[#rotation].ilk = #vector then
    tPosition = tDataList.position
  else
    if tDataList[#rotation].ilk = #string then
      tRefObject = GetReferenceType(tmember, tDataList.rotation)
      if tRefObject <> VOID then
        tRotation = tRefObject.getWorldTransform().rotation
      end if
    end if
  end if
  if tRotation <> VOID then
    tObject.transform.rotation = tRotation
  end if
  if tDataList[#PositionOffSet].ilk = #vector then
    tObject.worldPosition = tObject.worldPosition + tDataList.PositionOffSet
  end if
end

on RESETALL3D me
  pCastCount = _movie.castLib.count
  repeat with i = 1 to pCastCount
    pMemberCount = _movie.castLib(i).member.count
    repeat with j = 1 to pMemberCount
      pMemberType = member(j, i).type
      if pMemberType = #shockwave3d then
        member(j, i).resetWorld()
      end if
    end repeat
  end repeat
end

on RESETMEMBER3D tmember
  if (tmember = VOID) or (tmember.type <> #shockwave3d) then
    ShowError("RESET3D: You're referring to a NON 3d or existing pMember. Check name or castnumber.")
    exit
  else
    tmember.resetWorld()
  end if
end

on RESETCAST3D tCast
  pMemberCount = _movie.castLib(tCast).member.count
  repeat with j = 1 to pMemberCount
    pMemberType = member(j, tCast).type
    if pMemberType = #shockwave3d then
      member(j, tCast).resetWorld()
    end if
  end repeat
end

on GetReferenceType tmember, tString
  if tmember.model(tString) <> VOID then
    return tmember.model(tString)
  end if
  if tmember.light(tString) <> VOID then
    return tmember.light(tString)
  end if
  if tmember.camera(tString) <> VOID then
    return tmember.camera(tString)
  end if
  if tmember.group(tString) <> VOID then
    return tmember.group(tString)
  end if
  ShowError("Function: GetReferenceType. Member: " & tmember & " String: " & tString & " String not a string. Returned VOID")
  return VOID
end

on GetObjectList me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return []
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return []
  end if
  tType = #model
  if tDataList[#type].ilk = #symbol then
    tType = tDataList.type
  end if
  tString = "*.*"
  if tDataList[#string].ilk = #string then
    tString = tDataList.string
  end if
  tRef = 0
  if tDataList[#Reference].ilk = #integer then
    tRef = tDataList.Reference
  end if
  tList = []
  if tType = #model then
    repeat with i = 1 to tmember.model.count
      if tString = "*.*" then
        tList.add(tmember.model[i].name)
        next repeat
      end if
      if tmember.model[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.model[i])
          next repeat
        end if
        tList.add(tmember.model[i].name)
      end if
    end repeat
    return tList
  end if
  if tType = #modelResource then
    repeat with i = 1 to tmember.modelResource.count
      if tmember.modelResource[i].name = "DefaultModel" then
        next repeat
      end if
      if tString = "*.*" then
        tList.add(tmember.modelResource[i].name)
        next repeat
      end if
      if tmember.modelResource[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.modelResource[i])
          next repeat
        end if
        tList.add(tmember.modelResource[i].name)
      end if
    end repeat
    return tList
  end if
  if tType = #motion then
    repeat with i = 1 to tmember.motion.count
      if tmember.motion[i].name = "DefaultMotion" then
        next repeat
      end if
      if tString = "*.*" then
        tList.add(tmember.motion[i].name)
        next repeat
      end if
      if tmember.motion[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.motion[i])
          next repeat
        end if
        tList.add(tmember.motion[i].name)
      end if
    end repeat
    return tList
  end if
  if tType = #shader then
    repeat with i = 1 to tmember.shader.count
      if tmember.shader[i].name = "DefaultShader" then
        next repeat
      end if
      if tString = "*.*" then
        tList.add(tmember.shader[i].name)
        next repeat
      end if
      if tmember.shader[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.shader[i])
          next repeat
        end if
        tList.add(tmember.shader[i].name)
      end if
    end repeat
    return tList
  end if
  if tType = #texture then
    repeat with i = 1 to tmember.texture.count
      if tmember.texture[i].name = "DefaultTexture" then
        next repeat
      end if
      if tString = "*.*" then
        tList.add(tmember.texture[i].name)
        next repeat
      end if
      if tmember.texture[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.texture[i])
          next repeat
        end if
        tList.add(tmember.texture[i].name)
      end if
    end repeat
    return tList
  end if
  if tType = #light then
    repeat with i = 1 to tmember.light.count
      if tString = "*.*" then
        tList.add(tmember.light[i].name)
        next repeat
      end if
      if tmember.light[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.light[i])
          next repeat
        end if
        tList.add(tmember.light[i].name)
      end if
    end repeat
    return tList
  end if
  if tType = #camera then
    repeat with i = 1 to tmember.camera.count
      if tmember.camera[i].name = "DefaultView" then
        next repeat
      end if
      if tString = "*.*" then
        tList.add(tmember.camera[i].name)
        next repeat
      end if
      if tmember.camera[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.camera[i])
          next repeat
        end if
        tList.add(tmember.camera[i].name)
      end if
    end repeat
    return tList
  end if
  if tType = #group then
    repeat with i = 1 to tmember.group.count
      if tmember.group[i].name = "World" then
        next repeat
      end if
      if tString = "*.*" then
        tList.add(tmember.group[i].name)
        next repeat
      end if
      if tmember.group[i].name contains tString then
        if tRef = 1 then
          tList.add(tmember.group[i])
          next repeat
        end if
        tList.add(tmember.group[i].name)
      end if
    end repeat
    return tList
  end if
end

on SimpleShadow tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    exit
  end if
  tOrigModel = tmember.model("SimpleShadow")
  if tOrigModel = VOID then
    tSSMember = member("SimpleShadow")
    if tSSMember = VOID then
      exit
    end if
    createTexture("SimpleShadow", [#fileName: "SimpleShadow_Texture"])
    if tSSMember.texture("SimpleShadow_Texture") = VOID then
      tSSMember.model("SimpleShadow").shader = tSSMember.shader("DefaultShader")
    end if
    tmember.cloneModelFromCastmember("SimpleShadow", "SimpleShadow", tSSMember)
    tOrigModel = tmember.model("SimpleShadow")
    tOrigModel.removeFromWorld()
  end if
  tmodel = VOID
  if getaProp(tDataList, #model).ilk = #model then
    tmodel = tDataList[#model]
  end if
  if tmodel = VOID then
    exit
  end if
  tSize = VOID
  if getaProp(tDataList, #size).ilk = #float then
    tSize = tDataList[#size]
  end if
  if tSize = VOID then
    tSize = tmodel.boundingSphere[2]
  end if
  tSizeMulti = 1.0
  if getaProp(tDataList, #sizeMulti).ilk = #float then
    tSizeMulti = tDataList[#sizeMulti]
  end if
  tScale = (vector(0.0, 0.0, 0.0) + tSize) * tSizeMulti
  tSimpleShadow = tmember.newModel(tmodel.name & "SimpleShadow", tmember.modelResource("SimpleShadow"))
  tSimpleShadow.addToWorld()
  tSimpleShadow.shader = tOrigModel.shader
  tSimpleShadow.transform.scale = tScale
  tSimpleShadow.pointAtOrientation = [vector(0, 0, 1), vector(0, 1, 0)]
  return tSimpleShadow
end
