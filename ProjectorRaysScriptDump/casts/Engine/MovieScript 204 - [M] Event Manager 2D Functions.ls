global g

on CreateImage tTarget, tDataList
  if tTarget = VOID then
    exit
  end if
  if tTarget.ilk <> #string then
    exit
  end if
  if member(tTarget) = VOID then
    exit
  end if
  if tDataList.ilk <> #propList then
    if tDataList.ilk = #string then
      tDataList = value(tDataList)
    else
      exit
    end if
  end if
  tEmpty = castLib("Shared").findEmpty()
  tmember = new(#bitmap, member(tEmpty, "Shared"))
  tmember.name = tDataList.name
  g.DynamicMembers.add(tmember)
  tTargetImage = member(tTarget).image
  tImage = image(tDataList.size[1], tDataList.size[2], 32, 1)
  x = tDataList.startPoint.locH
  y = tDataList.startPoint.locV
  tRect = rect(x, y, x + tDataList.size[1], y + tDataList.size[2])
  tImage.copyPixels(tTargetImage, rect(0, 0, tDataList.size[1], tDataList.size[2]), tRect)
  tmember.image = tImage
end

on SetText tTarget, tDataList
  if tTarget = VOID then
    exit
  end if
  if tTarget.ilk <> #string then
    exit
  end if
  if member(tTarget) = VOID then
    exit
  end if
  if member(tTarget).type <> #text then
    exit
  end if
  if tDataList.ilk <> #propList then
    if tDataList.ilk = #string then
      tDataList = value(tDataList)
    else
      exit
    end if
  end if
  tString = EMPTY
  if tDataList.text = #hack then
    if g.targetAmount = 0 then
      tString = "  = "
    else
      tString = " x " & g.targetAmount & " = "
    end if
    member(tTarget).text = tString
  else
    member(tTarget).text = string(tDataList.text)
  end if
end

on DeleteSprite tTarget, tDataList
  tTarget = value(tTarget)
  sprite(tTarget).scriptInstanceList = []
  sprite(tTarget).member = VOID
  _movie.puppetSprite(tTarget, 0)
end

on ShowHideSprites tProperties
  P1 = tProperties[#start]
  P2 = tProperties[#end]
  pState = tProperties[#state]
  if P1 = VOID then
    P1 = 1
  end if
  if P2 = VOID then
    P2 = P1
  end if
  repeat with i = P1 to P2
    sprite(i).visible = pState
    sprite(i).locZ = i
  end repeat
end

on ResetSprites tTarget, tDataList
  pDataList = tDataList
  if pDataList.ilk = #string then
    pDataList = value(pDataList)
  end if
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: ResetSprites. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  if (pDataList = VOID) or (pDataList = EMPTY) then
    P1 = 1
    P2 = _movie.lastChannel
    pState = 0
  else
    P1 = pDataList[#start]
    P2 = pDataList[#end]
    pState = pDataList[#state]
  end if
  if P1 = VOID then
    P1 = 0
  end if
  if P2 = VOID then
    P2 = _movie.lastChannel
  end if
  if (pState = VOID) or (pState = 0) then
    pState = 0
  end if
  repeat with i = P1 to P2
    repeat with j in sprite(i).scriptInstanceList
      delete j
    end repeat
    sprite(i).member = member(0, 0)
    _movie.puppetSprite(i, pState)
  end repeat
end
