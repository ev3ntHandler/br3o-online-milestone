global gGame

on CreateTextButton me, tTarget, tDataList
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
  if voidp(gGame[#menu]) = 1 then
    return 0
  end if
  tText = VOID
  if tDataList[#text].ilk = #string then
    tText = tDataList.text
  end if
  if tText = VOID then
    return 0
  end if
  tgroup = tmember.group(tText)
  if tgroup = VOID then
    return 0
  end if
  if tgroup.child.count = 0 then
    return 0
  end if
  tList = [#parent: tgroup]
  if tDataList[#menu].ilk = #integer then
    tList[#menu] = tDataList.menu
  else
    tList[#menu] = 0
  end if
  if tDataList[#event].ilk = #string then
    tList[#event] = tDataList.event
  end if
  if tDataList[#handler].ilk = #string then
    tList[#handler] = tDataList.handler
  end if
  tList[#transform] = tgroup.transform.duplicate()
  tNormalShaderList = ["DefaultShader", "DefaultShader"]
  if voidp(tgroup.userData[#shaderList]) = 0 then
    tNormalShaderList = tgroup.userData.shaderList
  end if
  if tDataList[#normal].ilk = #list then
    tNormalShaderList = tDataList.normal
  end if
  tList[#normal] = tNormalShaderList
  tRolloverShaderList = ["DefaultShader", "DefaultShader"]
  if voidp(tgroup.userData[#shaderList]) = 0 then
    tRolloverShaderList = tgroup.userData.shaderList
  end if
  if tDataList[#rollover].ilk = #list then
    tRolloverShaderList = tDataList.rollover
  end if
  tList[#rollover] = tRolloverShaderList
  tPressedShaderList = ["DefaultShader", "DefaultShader"]
  if voidp(tgroup.userData[#shaderList]) = 0 then
    tPressedShaderList = tgroup.userData.shaderList
  end if
  if tDataList[#pressed].ilk = #list then
    tPressedShaderList = tDataList.pressed
  end if
  tList[#pressed] = tPressedShaderList
  tRollover_sfx = EMPTY
  if tDataList[#rollover_sfx].ilk = #string then
    tList[#rollover_sfx] = tDataList.rollover_sfx
  end if
  tPressed_sfx = EMPTY
  if tDataList[#pressed_sfx].ilk = #string then
    tList[#pressed_sfx] = tDataList.pressed_sfx
  end if
  tEffect = #none
  if tDataList[#effect].ilk = #symbol then
    tEffect = tDataList.effect
  end if
  tList[#effect] = tEffect
  gGame.menu.textButtons[tText] = tList
  return tList.duplicate()
end

on SetTextButton me, tTarget, tDataList
end

on DeleteTextButton me, tTarget, tDataList
end

on CreateButton me, tTarget, tDataList
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
  tmodel = VOID
  if tDataList[#model].ilk = #string then
    tmodel = GetReferenceType(tmember, tDataList.model)
  end if
  if tmodel = VOID then
    return 0
  end if
  tList = [:]
  if tDataList[#menu].ilk = #integer then
    tList[#menu] = tDataList.menu
  else
    tList[#menu] = 0
  end if
  tList[#event] = EMPTY
  if tDataList[#event].ilk = #string then
    tList[#event] = tDataList.event
  end if
  tList[#handler] = EMPTY
  if tDataList[#handler].ilk = #string then
    tList[#handler] = tDataList.handler
  end if
  tList[#transform] = tmodel.transform.duplicate()
  tAlpha = 0
  if tDataList[#alpha].ilk = #integer then
    tAlpha = tDataList.alpha
  end if
  tList[#alpha] = tAlpha
  tNormal = tmodel.shader.textureList[1].name
  if tDataList[#normal].ilk = #string then
    tNormal = tDataList.normal
  end if
  tList[#normal] = tNormal
  tRollover = tmodel.shader.textureList[1].name
  if tDataList[#rollover].ilk = #string then
    tRollover = tDataList.rollover
  end if
  tList[#rollover] = tRollover
  tPressed = tmodel.shader.textureList[1].name
  if tDataList[#pressed].ilk = #string then
    tPressed = tDataList.pressed
  end if
  tList[#pressed] = tPressed
  if tDataList[#shader].ilk = #integer then
    tList[#shader] = tDataList.shader
  else
    tList[#shader] = 0
  end if
  tNormalShader = tmodel.shader.name
  if tDataList[#normalShader].ilk = #string then
    tNormalShader = tDataList.normalShader
  end if
  tList[#normalShader] = tNormalShader
  tRolloverShader = tmodel.shader.name
  if tDataList[#rolloverShader].ilk = #string then
    tRolloverShader = tDataList.rolloverShader
  end if
  tList[#rolloverShader] = tRolloverShader
  tPressedShader = tmodel.shader.name
  if tDataList[#pressedShader].ilk = #string then
    tPressedShader = tDataList.pressedShader
  end if
  tList[#pressedShader] = tPressedShader
  tRollover_sfx = EMPTY
  if tDataList[#rollover_sfx].ilk = #string then
    tList[#rollover_sfx] = tDataList.rollover_sfx
  end if
  tPressed_sfx = EMPTY
  if tDataList[#pressed_sfx].ilk = #string then
    tList[#pressed_sfx] = tDataList.pressed_sfx
  end if
  tEffect = #none
  if tDataList[#effect].ilk = #symbol then
    tEffect = tDataList.effect
  end if
  tList[#effect] = tEffect
  gGame.menu.buttons[tmodel.name] = tList
  return tList.duplicate()
end

on SetButton me, tTarget, tDataList
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
  tmodel = VOID
  if tDataList[#model].ilk = #string then
    tmodel = GetReferenceType(tmember, tDataList.model)
  end if
  if tmodel = VOID then
    return 0
  end if
  if voidp(gGame.menu.buttons[symbol(tmodel.name)]) = 1 then
    return 0
  else
    tList = gGame.menu.buttons[symbol(tmodel.name)]
  end if
  if tDataList[#event].ilk = #string then
    tList.event = tDataList.event
  end if
  if tDataList[#handler].ilk = #string then
    tList.handler = tDataList.handler
  end if
  if tDataList[#alpha].ilk = #integer then
    tList.alpha = tDataList.alpha
  end if
  if tDataList[#position].ilk = #vector then
    tList.transform.position = tDataList.position
  end if
  if tDataList[#normal].ilk = #string then
    tList.normal = tDataList.normal
    tmodel.shader.textureList[1] = tmember.texture(tList.normal)
  end if
  if tDataList[#rollover].ilk = #string then
    tList.rollover = tDataList.rollover
  end if
  if tDataList[#pressed].ilk = #string then
    tList.pressed = tDataList.pressed
  end if
  if tDataList[#rollover_sfx].ilk = #string then
    tList.rollover_sfx = tDataList.rollover_sfx
  end if
  if tDataList[#pressed_sfx].ilk = #string then
    tList.pressed_sfx = tDataList.pressed_sfx
  end if
  if tDataList[#effect].ilk = #symbol then
    tList.effect = tDataList.effect
  end if
  return tList.duplicate()
end

on DeleteButton me, tTarget, tDataList
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
  tmodel = VOID
  if tDataList[#model].ilk = #string then
    tmodel = GetReferenceType(tmember, tDataList.model)
  end if
  if tmodel = VOID then
    return 0
  end if
  gGame.menu.buttons.deleteProp(tmodel.name)
  tDelete = 0
  if tDataList[#delete].ilk = #integer then
    tDelete = tDataList.delete
  end if
  if tDelete = 1 then
    tmember.deleteModel(tmodel.name)
  end if
  tHide = 0
  if tDataList[#hide].ilk = #integer then
    tHide = tDataList.hide
  end if
  if tHide = 1 then
    tUD = tmodel.userData
    tUD[#parent] = tmodel.parent
    tmodel.parent = VOID
  end if
  return 1
end
