global gGame

on SetAntiAliasing tTarget, tDataList
  put tTarget && tDataList
  if tTarget.ilk = #sprite then
    tSprite = tTarget
  else
    tSprite = sprite(value(tTarget))
  end if
  if tSprite = sprite(0) then
    if gGame[#sprite].ilk = #sprite then
      tTarget = gGame.sprite
    else
      return 0
    end if
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tMode = #none
  if tDataList[#mode].ilk = #symbol then
    tCheckList = [#none, #multiSample2x, #multiSample4x, #multiSample8x, #multiSample16x]
    if tCheckList.getPos(tDataList.mode) <> 0 then
      tMode = tDataList.mode
    end if
  end if
  if tSprite.antiAliasingSupported = 1 then
    if tMode = #none then
      tSprite.antiAliasingEnabled = 0
    else
      tSprite.antiAliasingEnabled = 1
      tSprite.antiAliasingMode = tMode
    end if
  end if
end
