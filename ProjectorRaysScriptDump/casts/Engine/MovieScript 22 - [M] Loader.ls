global gSystem, gLoader, gData, gGame

on load tFile, tDataList
  if (tFile = EMPTY) or (tFile contains "//") then
    tFile = VOID
  else
    tFile = gSystem.path & StringEvaluator(tFile)
  end if
  if tFile = VOID then
    ShowError("Function: Load. Path: " & tFile & " DataList: " & tDataList & ". No path available. Load aborted.")
    exit
  end if
  tDataList = value(tDataList)
  if tDataList.ilk <> #propList then
    tDataList = [:]
  end if
  if (tFile contains ".txt") and (gSystem.local = 1) then
    tResult = LoadTxt(tFile, tDataList.duplicate())
    put tFile && tResult
    if tDataList[#event].ilk = #string then
      event(tDataList.event)
    end if
  else
    if gSystem.local = 1 then
      ImportFile(tFile, tDataList.duplicate())
    end if
  end if
end

on LoadTxt tFile, tDataList
  if voidp(tFile) = 1 then
    ShowError("Function: LoadTxt. Parameters: " & tFile && tDataList & " No path available. LoadTxt aborted.")
    exit
  end if
  tDataList = value(tDataList)
  if tDataList.ilk <> #propList then
    tDataList = [:]
  end if
  tCast = "Internal"
  if voidp(tDataList[#cast]) = 0 then
    tCast = tDataList.cast
  end if
  SetItemDelimiter("\")
  tFileName = tFile.item[tFile.item.count]
  tFutureName = tFileName.char[1..tFileName.length - 4]
  ResetItemDelimiter()
  if member(tFutureName) = VOID then
    tmember = createMember(EMPTY, [#type: #text, #cast: tCast])
    tImported = tmember.importFileInto(tFile)
    if tImported <> 0 then
      HandleTxt(tmember, tDataList.duplicate())
    else
      ShowError("Function: LoadTxt. Parameters: " & tFile && tDataList & " IMport failed, member was erased.")
      EraseMember(tmember)
      return 0
    end if
  else
    return 0
  end if
  return 1
end

on HandleTxt tmember, tDataList
  tDataList = tDataList.duplicate()
  if tmember.name contains "LoadingArray" then
    repeat with i = 1 to tmember.text.line.count
      SetItemDelimiter(TAB)
      tPath = tmember.text.line[i].item[1]
      tTextDataList = value(tmember.text.line[i].item[2])
      if tTextDataList.ilk <> #propList then
        tTextDataList = tDataList
      end if
      if voidp(tTextDataList[#event]) = 0 then
        tTextDataList.deleteProp(#event)
      end if
      load(tPath, tTextDataList.duplicate())
    end repeat
  end if
  if tmember.name contains "Globals" then
    AddToGlobals(tmember, tDataList)
  end if
  if tmember.name contains "Events" then
    tDataList[#list] = #Events
    AddToData(tmember, tDataList)
  end if
  if tmember.name contains "Data" then
    tDataList[#list] = #data
    AddToData(tmember, tDataList)
  end if
  if tmember.name contains "Triggers" then
    tDataList[#list] = #Triggers
    AddToData(tmember, tDataList)
  end if
end

on ImportFile tFile, tDataList
  if voidp(tFile) = 1 then
    ShowError("Function: ImportFile. Parameters: " & tFile && tDataList & " No path available. ImportFile aborted.")
    exit
  end if
  tDataList = value(tDataList)
  if tDataList.ilk <> #propList then
    tDataList = [:]
  end if
  tCast = "Internal"
  repeat with m = 1 to _movie.castLib.count
    if tFile contains _movie.castLib[m].name then
      tCast = _movie.castLib[m].name
    end if
  end repeat
  if voidp(tDataList[#cast]) = 0 then
    tCast = tDataList.cast
  end if
  ResetItemDelimiter()
  if tFile.item.count > 1 then
    tFile = tFile.item[1]
    tDataList = value(tFile.item[2])
  end if
  tSingleFile = 0
  tType = VOID
  tFiles = [".W3D", ".bmp", ".png", ".tga", ".wav", ".swf", ".txt", ".jpg", ".swa", ".tif", ".mp3"]
  tTypes = [#shockwave3d, #bitmap, #bitmap, #bitmap, #sound, #flash, #text, #bitmap, #sound, #bitmap, #sound]
  tTag = tFile.char[tFile.length - 3..tFile.length]
  if tFiles.getPos(tTag) <> 0 then
    tSingleFile = 1
    tType = tTypes[tFiles.getPos(tTag)]
  end if
  if tSingleFile = 1 then
    tmember = createMember([#type: tType, #cast: tCast])
    case tType of
      #bitmap:
        tImported = tmember.importFileInto(tFile, [#dither: 0, #trimWhiteSpace: 0])
      #text:
        tImported = tmember.importFileInto(tFile)
        HandleTxt(tmember, tDataList.duplicate())
      otherwise:
        tImported = tmember.importFileInto(tFile)
    end case
  else
    repeat with j = 1 to 101
      tNextFile = getNthFileNameInFolder(tFile, j)
      if tNextFile = EMPTY then
        exit repeat
      end if
      if tNextFile contains "svn" then
        next repeat
      end if
      tTag = tNextFile.char[tNextFile.length - 3..tNextFile.length]
      if tFiles.getPos(tTag) <> 0 then
        tSingleFile = 1
        tType = tTypes[tFiles.getPos(tTag)]
      end if
      if voidp(tType) = 1 then
        ShowError("tType was VOID. This means it could be a folder or you're trying to import a file that is (currently) not supported.")
        next repeat
      end if
      tFutureName = tNextFile.char[1..tNextFile.length - 4]
      if member(tFutureName) <> VOID then
        next repeat
      end if
      tmember = createMember(EMPTY, [#type: tType, #cast: tCast])
      case tType of
        #bitmap:
          tImported = tmember.importFileInto(tFile & tNextFile, [#dither: 0, #trimWhiteSpace: 0])
        #text:
          tImported = tmember.importFileInto(tFile & tNextFile)
          HandleTxt(tmember, tDataList.duplicate())
        otherwise:
          tImported = tmember.importFileInto(tFile & tNextFile)
      end case
    end repeat
  end if
  if tImported = 0 then
    if tmember <> VOID then
      EraseMember(tmember)
    end if
  end if
end

on GetFileName tString
  pOldDelimiter = the itemDelimiter
  the itemDelimiter = "/"
  pFullFileName = tString.item[tString.item.count]
  the itemDelimiter = "."
  pFilename = pFullFileName.item[1]
  the itemDelimiter = pOldDelimiter
  return pFilename
end

on FilterForCasts tString
  pMember = member(tString)
  if pMember = VOID then
    return VOID
    exit
  end if
  if pMember.type <> #text then
    return VOID
    exit
  end if
  PList = []
  pCount = pMember.line.count
  pOldDelimiter = the itemDelimiter
  the itemDelimiter = "\"
  repeat with i = 1 to pCount
    pLine = pMember.line[i]
    pCast = pLine.item[3]
    if PList.getPos(pCast) = 0 then
      PList.add(pCast)
    end if
  end repeat
  the itemDelimiter = pOldDelimiter
  return PList
end

on OnlineLoad tTarget, tLocation
  put "OnlineLoad"
  tCount = _movie.castLib("Internal").member.count
  repeat with i = 1 to tCount
    tmember = member(i, "Internal")
    if tmember.type = #text then
      HandleTxt(tmember, [:])
    end if
  end repeat
  tCount = _movie.castLib("TrackData").member.count
  repeat with i = 1 to tCount
    tmember = member(i, "TrackData")
    if tmember.type = #text then
      HandleTxt(tmember, [:])
    end if
  end repeat
end
