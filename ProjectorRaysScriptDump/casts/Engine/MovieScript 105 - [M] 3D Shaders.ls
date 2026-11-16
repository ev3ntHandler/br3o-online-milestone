global gGame

on CreateShader me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tShaderName = "DefaultShader" & tmember.shader.count & "_Material"
  if tDataList[#shader].ilk = #string then
    tShaderName = tDataList.shader
  end if
  tType = #standard
  tShader = tmember.newShader(tShaderName, tType)
  tShader.ambient = rgb(0, 0, 0)
  tShader.diffuse = rgb(255, 255, 255)
  tShader.emissive = rgb(255, 255, 255)
  tShader.specular = rgb(255, 255, 255)
  tShader.shininess = 0.0
  tShader.blend = 100.0
  tShader.transparent = 1
  tShader.textureList[1] = tmember.texture("DefaultTexture")
  if tDataList[#ambient].ilk = #color then
    tShader.ambient = tDataList.ambient
  end if
  if tDataList[#diffuse].ilk = #color then
    tShader.diffuse = tDataList.diffuse
  end if
  if tDataList[#emissive].ilk = #color then
    tShader.emissive = tDataList.emissive
  end if
  if tDataList[#specular].ilk = #color then
    tShader.specular = tDataList.specular
  end if
  if tDataList[#shininess].ilk = #float then
    tShader.shininess = tDataList.shininess
  end if
  if tDataList[#blend].ilk = #float then
    tShader.blend = tDataList.blend
  end if
  if tDataList[#transparent].ilk = #integer then
    tShader.transparent = tDataList.transparent
  end if
  if tDataList[#texture].ilk = #string then
    tTexture = tmember.texture(tDataList.texture)
    if tTexture = VOID then
      tTexture = createTexture(tmember.name, [#fileName: tDataList.texture, #filtering: #lowFiltered])
    end if
    tShader.textureList[1] = tTexture
  end if
  if tDataList[#texture].ilk = #void then
    tShader.textureList[1] = VOID
  end if
  return tShader
end

on SetShader me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tShader = VOID
  if tDataList[#shader].ilk = #string then
    tShader = tmember.shader(tDataList.shader)
  end if
  if tShader = VOID then
    return 0
  end if
  if tDataList[#ambient].ilk = #color then
    tShader.ambient = tDataList.ambient
  end if
  if tDataList[#diffuse].ilk = #color then
    tShader.diffuse = tDataList.diffuse
  end if
  if tDataList[#emissive].ilk = #color then
    tShader.emissive = tDataList.emissive
  end if
  if tDataList[#specular].ilk = #color then
    tShader.specular = tDataList.specular
  end if
  if (tDataList[#shininess].ilk = #integer) or (tDataList[#shininess].ilk = #float) then
    tShader.shininess = tDataList.shininess
  end if
  if tDataList[#useDiffuseWithTexture].ilk = #integer then
    tShader.useDiffuseWithTexture = tDataList.useDiffuseWithTexture
  end if
  if (tDataList[#blend].ilk = #float) or (tDataList[#blend].ilk = #integer) then
    tShader.blend = tDataList.blend
  end if
  if tDataList[#transparent].ilk = #integer then
    tShader.transparent = tDataList.transparent
  end if
  if tDataList[#flat].ilk = #integer then
    tShader.flat = tDataList.flat
  end if
  tRenderStyles = [#point, #wire, #fill]
  if tDataList[#renderStyle].ilk = #symbol then
    if tRenderStyles.getPos(tDataList.renderStyle) <> 0 then
      tShader.renderStyle = tDataList.renderStyle
    end if
  end if
  tTextureModes = [#none, #wrapPlanar, #wrapCylindrical, #wrapSpherical, #reflection, #diffuseLight, #specularLight]
  tBlendFunctions = [#multiply, #replace, #add, #blend]
  tBlendSources = [#alpha, #constant]
  repeat with i = 1 to 8
    if tDataList[symbol("Texture" & i)].ilk = #string then
      tShader.textureList[i] = tmember.texture(tDataList[symbol("Texture" & i)])
    end if
    if tDataList[symbol("TextureMode" & i)].ilk = #symbol then
      if tTextureModes.getPos(tDataList[symbol("TextureMode" & i)]) <> 0 then
        tShader.textureModeList[i] = tDataList[symbol("TextureMode" & i)]
      end if
    end if
    if tDataList[symbol("BlendFunction" & i)].ilk = #symbol then
      if tBlendFunctions.getPos(tDataList[symbol("BlendFunction" & i)]) <> 0 then
        tShader.blendFunctionList[i] = tDataList[symbol("BlendFunction" & i)]
      end if
    end if
    if tDataList[symbol("BlendSource" & i)].ilk = #symbol then
      if tBlendSources.getPos(tDataList[symbol("BlendSource" & i)]) <> 0 then
        tShader.blendSourceList[i] = tDataList[symbol("BlendSource" & i)]
      end if
    end if
    if (tDataList[symbol("blendConstant" & i)].ilk = #float) or (tDataList[symbol("blendConstant" & i)].ilk = #integer) then
      tShader.blendConstantList[i] = tDataList[symbol("blendConstant" & i)]
    end if
    if tDataList[symbol("TextureRepeat" & i)].ilk = #integer then
      tShader.textureRepeat[i] = tDataList[symbol("TextureRepeat" & i)]
    end if
    if tDataList[symbol("TexturePosition" & i)].ilk = #vector then
      tShader.textureTransformList[i].position = tDataList[symbol("TexturePosition" & i)]
    end if
    if tDataList[symbol("TextureRotation" & i)].ilk = #vector then
      tShader.textureTransformList[i].rotation = tDataList[symbol("TextureRotation" & i)]
    end if
    if tDataList[symbol("TextureScale" & i)].ilk = #vector then
      tShader.textureTransformList[i].scale = tDataList[symbol("TextureScale" & i)]
    end if
  end repeat
end

on deleteShader me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tTargetList = []
  if tDataList[#shader].ilk = #void then
    tDataList[#shader] = "*.*"
  end if
  if tDataList[#shader].ilk = #list then
    tTargetList = tDataList.shader
  else
    if tDataList[#shader].ilk = #string then
      if tDataList.shader.char[1] = "*" then
        tString = tDataList.shader
        if tString <> "*.*" then
          delete tString.char[1]
        end if
        tTargetList = GetStringList(0, tmember.name, [#type: #shader, #string: tString])
      else
        tTargetList.add(tDataList.shader)
      end if
    end if
  end if
  if tTargetList.count = 0 then
    return VOID
  end if
  repeat with i in tTargetList
    if tmember.shader(i) <> VOID then
      tmember.deleteShader(i)
    end if
  end repeat
  return 1
end

on DuplicateShader me, tTarget, tDataList
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
  tSourceMember = tmember
  if tDataList[#sourceMember].ilk = #string then
    tSourceMember = member(tDataList.sourceMember)
  end if
  tTargetList = []
  if tDataList[#shader].ilk = #void then
    tDataList[#shader] = "*.*"
  end if
  if tDataList[#shader].ilk = #list then
    tTargetList = tDataList.shader
  else
    if tDataList[#shader].ilk = #string then
      if tDataList.shader.char[1] = "*" then
        tString = tDataList.shader
        if tString <> "*.*" then
          delete tString.char[1]
        end if
        tTargetList = GetStringList(0, tSourceMember.name, [#type: #shader, #string: tString])
      else
        tTargetList.add(tDataList.shader)
      end if
    end if
  end if
  if tTargetList.count = 0 then
    return []
  end if
  tShaderList = []
  tShaderTag = VOID
  if tDataList[#shaderTag].ilk = #string then
    tShaderTag = tDataList.shaderTag
  end if
  tTextureTag = VOID
  if tDataList[#textureTag].ilk = #string then
    tTextureTag = tDataList.textureTag
  end if
  repeat with i in tTargetList
    tOrigShader = tSourceMember.shader(i)
    tDupShader = tmember.newShader(tShaderTag & tOrigShader.name, tOrigShader.type)
    tDupShader.ambient = tOrigShader.ambient
    tDupShader.diffuse = tOrigShader.diffuse
    tDupShader.emissive = tOrigShader.emissive
    tDupShader.specular = tOrigShader.specular
    tDupShader.shininess = tOrigShader.shininess
    tDupShader.blend = tOrigShader.blend
    tDupShader.transparent = tOrigShader.transparent
    tDupShader.flat = tOrigShader.flat
    tDupShader.renderStyle = tOrigShader.renderStyle
    tDupShader.useDiffuseWithTexture = tOrigShader.useDiffuseWithTexture
    repeat with ii = 1 to 8
      if tOrigShader.textureList[ii] = VOID then
        next repeat
      end if
      tTexture = tOrigShader.textureList[ii]
      tNewTexture = tmember.texture(tTextureTag & tTexture.name)
      if tNewTexture = VOID then
        tNewTexture = DuplicateTexture(0, tmember.name, [#texture: tTexture.name, #sourceMember: tSourceMember.name, #NameTag: tTextureTag])
      end if
      tDupShader.textureList[ii] = tNewTexture
      tDupShader.textureModeList[ii] = tOrigShader.textureModeList[ii]
      tDupShader.wrapTransformList[ii] = tOrigShader.wrapTransformList[ii]
      tDupShader.textureTransformList[ii] = tOrigShader.textureTransformList[ii]
      tDupShader.blendFunctionList[ii] = tOrigShader.blendFunctionList[ii]
      tDupShader.blendSourceList[ii] = tOrigShader.blendSourceList[ii]
      tDupShader.blendConstantList[ii] = tOrigShader.blendConstantList[ii]
      tDupShader.textureRepeatList[ii] = tOrigShader.textureRepeatList[ii]
    end repeat
    tShaderList.add(tDupShader)
  end repeat
  if tShaderList.count = 1 then
    return tShaderList[1]
  else
    return tShaderList
  end if
end

on BlendShader tTarget, tDataList
  getRendererServices().MultiTexturing = 0
  if tTarget = VOID then
    exit
  end if
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tmember.type <> #shockwave3d then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  tShaderName = VOID
  if getaProp(tDataList, #materialName).ilk = #string then
    tShaderName = tDataList[#materialName]
  end if
  if tShaderName = VOID then
    exit
  end if
  tShader = tmember.shader(tShaderName)
  if tShader = VOID then
    exit
  end if
  tBlendMode = #add
  if getaProp(tDataList, #blendMode).ilk = #symbol then
    tBlendMode = tDataList[#blendMode]
  end if
  tShader.transparent = 1
  tShader.blend = 0.0
  tShader.blendFunctionList[1] = #blend
  tShader.blendConstantList[1] = 0.0
  if _movie.active3dRenderer = #openGL then
    tShader.textureList[2] = tShader.textureList[1]
    tShader.blendFunctionList[2] = tBlendMode
    tShader.blendConstantList[2] = 0.0
  else
    tShader.textureList[2] = tShader.textureList[1]
    tShader.textureList[3] = tShader.textureList[1]
    tShader.blendFunctionList[2] = #blend
    tShader.blendConstantList[2] = 0.0
    tShader.blendFunctionList[3] = tBlendMode
    tShader.blendConstantList[3] = 0.0
  end if
  if getaProp(gGame, #AddShaders) = VOID then
    gGame[#AddShaders] = []
  end if
  gGame.AddShaders.add(tShader)
  return tShader
end

on CreateProxyShader tmember
  if tmember = VOID then
    exit
  end if
  if tmember.type <> #shockwave3d then
    exit
  end if
  gGame[#ProxyShader] = tmember.member.newShader("Proxy_Material", #standard)
  gGame.ProxyShader.ambient = rgb(250, 0, 247)
  gGame.ProxyShader.diffuse = rgb(250, 0, 247)
  gGame.ProxyShader.emissive = rgb(54, 102, 191)
  gGame.ProxyShader.specular = rgb(0, 0, 0)
  gGame.ProxyShader.shininess = 0.0
  gGame.ProxyShader.textureList = VOID
end
