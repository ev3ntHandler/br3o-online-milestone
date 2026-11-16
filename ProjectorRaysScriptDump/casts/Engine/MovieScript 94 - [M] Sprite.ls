global gSystem, gLoader, gData, gGame

on CreateSprite tTarget, tDataList
  if (tTarget = VOID) or (tTarget = EMPTY) then
    ShowError("Function: CreateSprite. Target: " & tTarget & " Parameters: " & tDataList & " No target. Function aborted.")
    exit
  end if
  pMember = member(tTarget)
  if pMember = VOID then
    ShowError("Function: CreateSprite. Target: " & tTarget & " Parameters: " & tDataList & " No member with target name.")
    exit
  end if
  if (tDataList = VOID) or (tDataList = EMPTY) then
    ShowError("Function: CreateSprite. Target: " & tTarget & " Parameters: " & tDataList & " DataList VOID. Datalist will be set to default settings.")
    pLoc = GetStageSize()
    pDataList = [#channel: GetEmptyChannel(), #loc: point(pLoc[1] / 2, pLoc[2] / 2), #size: [pMember.width, pMember.height]]
  else
    pDataList = value(tDataList)
    if pDataList.ilk <> #propList then
      ShowError("Function: CreateSprite. Target: " & tTarget & " Parameters: " & tDataList & " After value() datalist wasn't a proplist.")
      exit
    end if
  end if
  _movie.puppetSprite(pDataList[#channel], 1)
  sprite(pDataList[#channel]).member = pMember
  tSize = [pMember.width, pMember.height]
  if getaProp(pDataList, #size).ilk = #list then
    tSize = pDataList[#size]
  end if
  if getaProp(pDataList, #size).ilk = #symbol then
    tSize = pDataList[#size]
  end if
  if tSize = #fullscreen640 then
    t1 = gGame.resolution[1] / 640.0
    t2 = gGame.resolution[2] / 480.0
    tSize = [integer(pMember.width * t1), integer(pMember.height * t2)]
  end if
  sprite(pDataList[#channel]).width = tSize[1]
  sprite(pDataList[#channel]).height = tSize[2]
  tFlipH = 0
  tFlipV = 0
  if getaProp(pDataList, #flipH).ilk = #integer then
    tFlipH = pDataList[#flipH]
  end if
  if getaProp(pDataList, #flipV).ilk = #integer then
    tFlipV = pDataList[#flipV]
  end if
  sprite(pDataList[#channel]).flipH = tFlipH
  sprite(pDataList[#channel]).flipV = tFlipV
  tInk = 0
  if getaProp(pDataList, #ink).ilk = #integer then
    tInk = pDataList[#ink]
  end if
  sprite(pDataList[#channel]).ink = tInk
  tBlend = 100
  if getaProp(pDataList, #blend).ilk = #integer then
    tBlend = pDataList[#blend]
  end if
  sprite(pDataList[#channel]).blend = tBlend
  tStageLoc = GetStageSize()
  tLoc = point(tStageLoc[1] / 2, tStageLoc[2] / 2)
  if getaProp(pDataList, #loc).ilk = #point then
    tLoc = pDataList[#loc]
  end if
  if getaProp(pDataList, #loc).ilk = #symbol then
    tLoc = pDataList[#loc]
  end if
  if tLoc = #centerSprite then
    tLoc = point(sprite(pDataList[#channel]).width / 2, sprite(pDataList[#channel]).height / 2)
  end if
  sprite(pDataList[#channel]).loc = tLoc
  if sprite(pDataList[#channel]).member.type = #shockwave3d then
    tDTS = 1
    if voidp(pDataList[#dts]) = 0 then
      tDTS = pDataList.dts
    end if
    _movie.updateStage()
    sprite(pDataList[#channel]).directToStage = tDTS
  end if
  tManager = 0
  if voidp(pDataList[#manager]) = 0 then
    tManager = pDataList.manager
  end if
  if tManager = 1 then
    tScript = script("[PS] Script Manager").new([#SpriteNR: pDataList[#channel]])
    sprite(pDataList[#channel]).scriptInstanceList.add(tScript)
  end if
  tDefault3d = 0
  if voidp(pDataList[#default3d]) = 0 then
    tDefault3d = pDataList.default3d
  end if
  if tDefault3d = 1 then
  end if
end

on DeleteDynamicSprites me
end
