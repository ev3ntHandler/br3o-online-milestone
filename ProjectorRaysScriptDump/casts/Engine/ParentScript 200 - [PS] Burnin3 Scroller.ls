property p
global gData, gGame

on new me, tParams
  p = [:]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = member(tParams[#memberName])
  p[#button] = VOID
  p[#PreviousButton] = VOID
  p[#mouseDown] = 0
  p[#rightMouseDown] = 0
  p[#MouseStart] = _mouse.mouseLoc
  p[#tag] = tParams[#tag]
  p[#camera] = p.member.camera("3D_Camera")
  p[#Slider] = p.member.model(p.tag & "Slider")
  p[#SliderSize] = 16
  p[#Bar] = p.member.model(p.tag & "bar")
  p[#BarSize] = 256
  p[#minMax] = [p.Bar.transform.position.z, p.Bar.transform.position.z - (p.BarSize - p.SliderSize)]
  p[#shader] = p.member.shader(p.tag & "_Material")
  if tParams[#ShaderMax].ilk = #float then
    p[#ShaderMax] = tParams.ShaderMax
  else
    p[#ShaderMax] = 0.5
  end if
  p.Slider.transform.position.z = p.Bar.transform.position.z
  p[#transform] = p.Slider.transform.duplicate()
  p.shader.textureTransformList[1].position = vector(0.0, 0.0, 0.0)
  p[#normal] = p.member.shader("WhiteFont3D_Material")
  p[#rollover] = p.member.shader("YellowFont3D_Material")
  p.Slider.shader = p.normal
  p[#me] = me
  return me
end

on enterFrame me
  if p.mouseDown = 0 then
    tmodel = p.camera.modelUnderLoc(_mouse.mouseLoc)
    if tmodel <> VOID then
      if tmodel.name = p.Slider.name then
        p.button = tmodel
        p.MouseStart = _mouse.mouseLoc
      else
        p.button = VOID
      end if
    end if
    if (p.button = VOID) and (p.PreviousButton <> VOID) then
      me.ButtonLeave(p.PreviousButton)
    end if
    if p.button <> VOID then
      me.ButtonEnter()
    end if
  end if
  if _mouse.mouseDown and (p.button <> VOID) then
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
    me.ButtonLeave(p.PreviousButton)
  end if
  _player.cursor(260)
  p.button.shader = p.rollover
  p.PreviousButton = p.button
end

on ButtonLeave me, tButton
  _player.cursor(-1)
  if tButton <> VOID then
    tButton.shader = p.normal
  end if
  p.PreviousButton = VOID
end

on ButtonDown me
  _player.cursor(290)
  tDiffV = _mouse.mouseV - p.MouseStart.locV
  p.button.transform.position.z = p.transform.position.z - tDiffV
  if p.button.transform.position.z > p.minMax[1] then
    p.button.transform.position.z = p.minMax[1]
  end if
  if p.button.transform.position.z < p.minMax[2] then
    p.button.transform.position.z = p.minMax[2]
  end if
  tPerc = abs((p.minMax[1] - p.button.transform.position.z) / (p.minMax[2] - p.minMax[1]))
  p.shader.textureTransformList[1].position = vector(0.0, p.ShaderMax * tPerc, 0.0)
  p.mouseDown = 1
  gGame.menu.menu = 2
end

on ButtonUp me
  p.transform = p.button.transform.duplicate()
  p.button = VOID
  p.mouseDown = 0
  gGame.menu.menu = 0
end

on delete me
end
