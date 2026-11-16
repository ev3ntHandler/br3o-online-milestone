global gSystem, gLoader, gData, gGame

on createMember tTarget, tDataList
  tDataList = value(tDataList)
  if tDataList.ilk <> #propList then
    tDataList = [:]
  end if
  if voidp(tDataList[#type]) = 1 then
    ShowError("Function: CreateMember. Parameters: " & tTarget && tDataList & " No type defined.")
    exit
  end if
  tCast = "Internal"
  if voidp(tDataList[#cast]) = 0 then
    tCast = tDataList.cast
  end if
  tEmpty = castLib(tCast).findEmpty()
  tmember = new(tDataList.type, member(tEmpty, tCast))
  tmember.name = tTarget
  gSystem.DynamicMembers.add(tmember)
  return tmember
end

on DeleteDynamicMembers me
  if gSystem.local = 1 then
    tCount = gSystem.DynamicMembers.count
    repeat with i = 1 to tCount
      gSystem.DynamicMembers[i].erase()
    end repeat
    gSystem.DynamicMembers = []
  end if
end

on EraseMember tmember
  if gSystem.DynamicMembers.getPos(tmember) <> 0 then
    gSystem.DynamicMembers.deleteOne(tmember)
  end if
  tmember.erase()
end

on EraseMembers tStart, tEnd, tCast
  repeat with i = tStart to tEnd
    member(i, tCast).erase()
  end repeat
end
