property pFPS_MIN, pFPS_MAX, pFPS_NOW, pFPS_TALLY, pFPS_ENTRIES, pNEXTMILLISECOND, pFRAMECOUNT, pFPS_FLAG, pMAXINTERVAL, pTIMEPEROID, pText, p, gFrameInterval, gMilliseconds
global gGame

on new me, tParams
  if voidp(gGame[#FPSCounter]) = 0 then
    if gGame.FPSCounter = 0 then
      exit
    end if
  end if
  p = [:]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = p.sprite.member
  if p.member = VOID then
    ShowError("Script: [PS] FPS Counter. p.Member was VOID. Script creation exited.")
    exit
  end if
  p[#textMember] = member("gFPSCounter")
  p[#ScriptName] = tParams[#ScriptName]
  if p.ScriptName = VOID then
    p.ScriptName = EMPTY
  end if
  p[#texture] = p.member.newTexture("FPS_Texture")
  p.texture.quality = #lowFiltered
  p.texture.renderFormat = #rgba4444
  p.texture.member = p.textMember
  p[#camera] = gGame.camera[1][#camera]
  p.camera.addOverlay(p.texture, point(2, 0), 0)
  FPS_RESET()
  return me
end

on FPS_RESET me
  pFPS_MIN = the maxinteger
  pFPS_MAX = 0
  pFPS_NOW = 0
  pFPS_TALLY = 0
  pFPS_ENTRIES = 0
  pFPS_FLAG = 1
  pFRAMECOUNT = 0
  pMAXINTERVAL = 100
  pTIMEPEROID = 2000
  gMilliseconds = the milliSeconds
  gFrameInterval = 100
  pNEXTMILLISECOND = gMilliseconds + 2000
  member("gFPSCOUNTER").text = " FPS COUNTER "
end

on mouseDown me
  FPS_RESET(me)
end

on enterFrame me
  gFrameInterval = (the milliSeconds - gMilliseconds + gFrameInterval) / 2
  if gFrameInterval > pMAXINTERVAL then
    gFrameInterval = pMAXINTERVAL
  end if
  if gFrameInterval < 1 then
    gFrameInterval = 1
  end if
  gMilliseconds = the milliSeconds
  pFRAMECOUNT = pFRAMECOUNT + 1
  if pFPS_FLAG = 0 then
    exit
  end if
  if gMilliseconds > pNEXTMILLISECOND then
    pFPS_NOW = pFRAMECOUNT / float(gMilliseconds - pNEXTMILLISECOND + pTIMEPEROID) * 1000
    pNEXTMILLISECOND = gMilliseconds + pTIMEPEROID
    pFRAMECOUNT = 0
    if (pFPS_NOW < pFPS_MIN) and (pFPS_MAX <> 0) then
      pFPS_MIN = pFPS_NOW
    end if
    if pFPS_NOW > pFPS_MAX then
      pFPS_MAX = pFPS_NOW
    end if
    if pFPS_MIN <> the maxinteger then
      pFPS_TALLY = pFPS_TALLY + pFPS_NOW
      pFPS_ENTRIES = pFPS_ENTRIES + 1
      fptemp = pFPS_TALLY / pFPS_ENTRIES
    end if
    set the floatPrecision to 1
    tCodeTime = 0
    tFrameTime = 0
    if gGame[#CodeTime] <> VOID then
      tCodeTime = gGame.CodeTime
    end if
    if gGame[#FrameTime] <> VOID then
      tFrameTime = gGame.FrameTime
    end if
    pText = "MIN:" & string(pFPS_MIN) & "   MAX:" & string(pFPS_MAX) & "   NOW:" & string(pFPS_NOW) & "   AVG:" & string(fptemp) & "   CT: " & tCodeTime & "   FT: " & tFrameTime
    member("gFPSCOUNTER").text = pText
    set the floatPrecision to 4
    p.texture.image = p.textMember.image
  end if
end
