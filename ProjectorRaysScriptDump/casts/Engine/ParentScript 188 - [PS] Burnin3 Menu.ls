property p
global gData, gGame

on new me, tParams
  p = [:]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = member(tParams[#member])
  p[#Cameras] = [p.member.camera("DefaultView")]
  if tParams[#camera].ilk = #string then
    p.Cameras = [p.member.camera(tParams[#camera])]
  else
    if tParams[#camera].ilk = #list then
      p.Cameras = []
      repeat with i = 1 to tParams[#camera].count
        tCamera = p.member.camera(tParams[#camera][i])
        if tCamera <> VOID then
          p.Cameras.add(tCamera)
        end if
      end repeat
    end if
  end if
  if p.Cameras.count = 0 then
    p.Cameras = [p.member.camera("DefaultView")]
  end if
  p[#button] = VOID
  p[#PreviousButton] = VOID
  p[#mouseDown] = 0
  p[#rightMouseDown] = 0
  gGame[#menu] = [:]
  gGame.menu[#menu] = 0
  gGame.menu[#textButtons] = [:]
  gGame.menu[#buttons] = [:]
  gGame.menu[#script] = me
  return me
end

on enterFrame me
  tOptionList = [#maxNumberOfModels: 3, #levelOfDetail: #detailed]
  tPoint = _mouse.mouseLoc
  tList = []
  repeat with i = 1 to p.Cameras.count
    tModelList = p.Cameras[i].modelsUnderLoc(_mouse.mouseLoc, tOptionList)
    if tModelList.count > 0 then
      repeat with j = 1 to tModelList.count
        tmodel = tModelList[j].model
        if voidp(gGame.menu.buttons[tmodel.name]) = 0 then
          if gGame.menu.buttons[tmodel.name].menu = gGame.menu.menu then
            tData = gGame.menu.buttons[tmodel.name]
            if tData.alpha = 0 then
              tList.add(tmodel)
            else
              if GetAlphaPixel(tModelList[1]) <> color(0) then
                tList.add(tmodel)
              end if
            end if
          end if
          next repeat
        end if
        if voidp(gGame.menu.textButtons[tmodel.parent.name]) = 0 then
          if gGame.menu.textButtons[tmodel.parent.name].menu = gGame.menu.menu then
            tList.add(tmodel.parent)
          end if
        end if
      end repeat
    end if
  end repeat
  if tList.count = 0 then
    p.button = VOID
  else
    p.button = tList[1]
  end if
  if (p.button = VOID) and (p.PreviousButton <> VOID) then
    me.ButtonLeave(p.PreviousButton)
  end if
  if p.button <> VOID then
    me.ButtonEnter()
  end if
  if _mouse.mouseDown and (p.button <> VOID) and (p.mouseDown = 0) then
    me.ButtonDown()
  end if
  if _mouse.mouseUp and (p.button <> VOID) and (p.mouseDown = 1) then
    me.ButtonUp()
  end if
end

on ButtonEnter me
  if p.button = p.PreviousButton then
    return 
  else
    me.ButtonLeave()
  end if
  _player.cursor(280)
  if p.button.ilk = #group then
    me.TextButtonEnter(p.button)
  else
    me.NormalButtonEnter(p.button)
  end if
  p.PreviousButton = p.button
end

on ButtonLeave me
  _player.cursor(-1)
  if p.PreviousButton.ilk = #group then
    me.TextButtonLeave(p.PreviousButton)
  else
    if p.PreviousButton.ilk = #model then
      me.NormalButtonLeave(p.PreviousButton)
    end if
  end if
end

on ButtonDown me
  if p.PreviousButton.ilk = #group then
    me.TextButtonDown(p.button)
  else
    if p.PreviousButton.ilk = #model then
      me.NormalButtonDown(p.button)
    end if
  end if
  p.mouseDown = 1
end

on ButtonUp me
  if p.PreviousButton.ilk = #group then
    me.TextButtonUp(p.button)
  else
    if p.PreviousButton.ilk = #model then
      me.NormalButtonUp(p.button)
    end if
  end if
  p.mouseDown = 0
  _player.cursor(-1)
end

on TextButtonEnter me, tButton
  tList = gGame.menu.textButtons[tButton.name]
  tData = tButton.userData
  tCount = tData.modelList.normal.count
  repeat with i = 1 to tCount
    tChar3D = tData.modelList.normal[i]
    if tChar3D = #space then
      next repeat
    end if
    tChar3D.shader = p.member.shader(tList.rollover[1])
    tChar3DGlow = tData.modelList.glow[i]
    if tChar3DGlow <> VOID then
      tChar3DGlow.shader = p.member.shader(tList.rollover[2])
    end if
  end repeat
  if tList.effect <> #none then
    case tList.effect of
      #offset:
        tButton.transform.position = tButton.transform.position + gData.data.ButtonEffects.offset
    end case
  end if
  PlaySound(tList.rollover_sfx, [#Override: 1])
end

on TextButtonLeave me, tButton
  tList = gGame.menu.textButtons[tButton.name]
  tData = tButton.userData
  tCount = tData.modelList.normal.count
  repeat with i = 1 to tCount
    tChar3D = tData.modelList.normal[i]
    if tChar3D = #space then
      next repeat
    end if
    tChar3D.shader = p.member.shader(tList.normal[1])
    tChar3DGlow = tData.modelList.glow[i]
    if tChar3DGlow <> VOID then
      tChar3DGlow.shader = p.member.shader(tList.normal[2])
    end if
  end repeat
  if tList.effect <> #none then
    case tList.effect of
      #offset:
        tButton.transform.position = tList.transform.position
    end case
  end if
  p.PreviousButton = VOID
end

on TextButtonDown me, tButton
  tList = gGame.menu.textButtons[tButton.name]
  PlaySound(tList.pressed_sfx, [#Override: 1])
end

on TextButtonUp me, tButton
  tList = gGame.menu.textButtons[tButton.name]
  me.TextButtonLeave(tButton)
  gGame.PressedButton = tButton.name
  if tList[#event].ilk = #string then
    event(symbol(tList.event))
  end if
  if tList[#handler].ilk = #string then
    sendSprite(0, symbol(tList.handler), tButton.name)
  end if
  gGame.PressedButton = #none
end

on NormalButtonEnter me, tButton
  tList = gGame.menu.buttons[tButton.name]
  if tList.shader = 1 then
    tButton.shader = p.member.shader(tList.rolloverShader)
  else
    tButton.shader.textureList[1] = p.member.texture(tList.rollover)
  end if
  if tList.effect <> #none then
    case tList.effect of
      #scale:
        tButton.transform.scale = tButton.transform.scale + gData.data.ButtonEffects.scale
      #HiddenPackage:
        EnterHiddenPackage(0, tButton)
    end case
  end if
  PlaySound(tList.rollover_sfx, [#Override: 1])
end

on NormalButtonLeave me, tButton
  tList = gGame.menu.buttons[tButton.name]
  if tList.shader = 1 then
    tButton.shader = p.member.shader(tList.normalShader)
  else
    tButton.shader.textureList[1] = p.member.texture(tList.normal)
  end if
  if tList.effect <> #none then
    case tList.effect of
      #scale:
        tButton.transform.scale = tList.transform.scale
      #HiddenPackage:
        LeaveHiddenPackage(0, tButton)
    end case
  end if
  p.PreviousButton = VOID
end

on NormalButtonDown me, tButton
  tList = gGame.menu.buttons[tButton.name]
  PlaySound(tList.pressed_sfx, [#Override: 1])
end

on NormalButtonUp me, tButton
  tList = gGame.menu.buttons[tButton.name]
  me.NormalButtonLeave(tButton)
  gGame.PressedButton = tButton.name
  if tList[#event].ilk = #string then
    event(symbol(tList.event))
  end if
  if tList[#handler].ilk = #string then
    sendSprite(0, symbol(tList.handler), tButton.name)
  end if
  gGame.PressedButton = #none
end

on GetAlphaPixel iSectList
  tmodel = iSectList.model
  tmember = tmodel.shader.textureList[1].member
  tImage = tmember.image
  tmodel.addModifier(#meshDeform)
  tFace = iSectList.faceID
  tUVCoord = iSectList.uvCoord
  tCoordList = tmodel.meshDeform.mesh[iSectList.meshID].textureCoordinateList
  tFaceList = tmodel.meshDeform.mesh[iSectList.meshID].face[tFace]
  tmodel.removeModifier(#meshDeform)
  tLocA = tCoordList[tFaceList[1]]
  tLocA = point(tLocA[1] * tImage.width, (1 - tLocA[2]) * tImage.height)
  tLocB = tCoordList[tFaceList[2]]
  tLocB = point(tLocB[1] * tImage.width, (1 - tLocB[2]) * tImage.height)
  tLocC = tCoordList[tFaceList[3]]
  tLocC = point(tLocC[1] * tImage.width, (1 - tLocC[2]) * tImage.height)
  tUVector = (tLocB - tLocA) * tUVCoord.u
  tVVector = (tLocC - tLocA) * tUVCoord.V
  tPos = tLocA + tUVector + tVVector
  tAlpha = tImage.extractAlpha().getPixel(tPos)
  return tAlpha
end
