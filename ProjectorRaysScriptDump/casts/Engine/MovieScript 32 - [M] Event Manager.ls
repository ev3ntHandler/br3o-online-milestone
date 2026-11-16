global gSystem, gLoader, gData, gGame

on event tEvent
  if tEvent.ilk = #string then
    tEvent = StringEvaluator(tEvent)
  end if
  if voidp(gData[#Events][tEvent]) = 1 then
    ShowError(string(tEvent) & " does not exist.")
    return 0
  end if
  gSystem.event = tEvent
  if gSystem.debug = 1 then
    put tEvent
  end if
  repeat with i = 1 to gData[#Events][tEvent].count
    tFunction = gData[#Events][tEvent].getPropAt(i)
    tTarget = gData[#Events][tEvent][i][1]
    tDataList = gData[#Events][tEvent][i][2]
    if (tFunction <> #AddTrigger) and (tFunction <> #AddToList) and (tFunction <> #RemoveFromList) then
      tTarget = StringEvaluator(tTarget)
    end if
    tDataList = StringEvaluator(tDataList)
    if gSystem.debug = 1 then
      put tFunction && tTarget && tDataList
    end if
    case tFunction of
      #resetWorld:
        resetWorld(0, tTarget)
      #RESETCAST3D:
        RESETCAST3D(tTarget)
      #RemoveLod:
        RemoveLod(tTarget, tDataList)
      #RemoveLodCast:
        RemoveLodCast(tTarget)
      #ADDMESHMODIFIER:
        ADDMESHMODIFIER(tTarget, tDataList)
      #RESETALL3D:
        RESETALL3D()
      #CreateObject:
        CreateObject(0, tTarget, tDataList)
      #createTexture:
        createTexture(tTarget, tDataList)
      #ASSIGNTEXTURE:
        ASSIGNTEXTURE(tTarget, tDataList)
      #deleteTexture:
        deleteTexture(tTarget, tDataList)
      #SETMATERIAL:
        SETMATERIAL(tTarget, tDataList)
      #SetTexture:
        SetTexture(tTarget, tDataList)
      #CleanMaterials:
        CleanMaterials(tTarget, tDataList)
      #DuplicateShader:
        DuplicateShader(0, tTarget, tDataList)
      #SetShader:
        SetShader(0, tTarget, tDataList)
      #SetSkybox:
        SetSkybox(0, tTarget, tDataList)
      #Iterate:
        Iterate(0, tTarget, tDataList)
      #CLONEMODELS:
        CLONEMODELS(tTarget, tDataList)
      #CloneCameras:
        CloneCameras(tTarget, tDataList)
      #CloneModel:
        CloneModel(0, tTarget, tDataList)
      #Create3DText:
        Create3DText(0, tTarget, tDataList)
      #CreateTextTexture:
        CreateTextTexture(0, tTarget, tDataList)
      #CreateTextButton:
        CreateTextButton(0, tTarget, tDataList)
      #CreateButton:
        CreateButton(0, tTarget, tDataList)
      #DeleteButton:
        DeleteButton(0, tTarget, tDataList)
      #SetButton:
        SetButton(0, tTarget, tDataList)
      #addModifier:
        addModifier(0, tTarget, tDataList)
      #AddToRotator:
        AddToRotator(0, tTarget, tDataList)
      #AddToScroller:
        AddToScroller(0, tTarget, tDataList)
      #AddToBillBoard:
        AddToBillBoard(0, tTarget, tDataList)
      #AddToInterPolator:
        AddToInterPolator(0, tTarget, tDataList)
      #AddToPointAt:
        AddToPointAt(0, tTarget, tDataList)
      #AddToMimic:
        AddToMimic(0, tTarget, tDataList)
      #StoreParent:
        StoreParent(0, tTarget, tDataList)
      #SetParent:
        SetParent(0, tTarget, tDataList)
      #SetPosDir:
        SetPosDir(0, tTarget, tDataList)
      #CopyTextureCoordinates:
        CopyTextureCoordinates(tTarget, tDataList)
      #SETVISIBLE:
        SETVISIBLE(0, tTarget, tDataList)
      #SetAntiAliasing:
        SetAntiAliasing(tTarget, tDataList)
      #setCamera:
        setCamera(tTarget, tDataList)
      #AddCameraToSprite:
        AddCameraToSprite(0, tTarget, tDataList)
      #RemoveCameraFromSprite:
        RemoveCameraFromSprite(0, tTarget, tDataList)
      #ActivateCamera:
        ActivateCamera(tTarget, tDataList)
      #deleteLight:
        deleteLight(tTarget, tDataList)
      #createlight:
        createlight(tTarget, tDataList)
      #SetLight:
        SetLight(0, tTarget, tDataList)
      #CreateGroup:
        CreateGroup(tTarget, tDataList)
      #AddToGroup:
        AddToGroup(tTarget, tDataList)
      #load:
        load(tTarget, tDataList)
      #AddValue:
        AddValue(0, tTarget, tDataList)
      #SetValue:
        SetValue(0, tTarget, tDataList)
      #RemoveValue:
        RemoveValue(0, tTarget, tDataList)
      #AddToList:
        AddToList(0, tTarget, tDataList)
      #RemoveFromList:
        RemoveFromList(0, tTarget, tDataList)
      #RemoveFromHandlerList:
        RemoveFromHandlerList(0, tTarget, tDataList)
      #AddScript:
        AddScript(tTarget, tDataList)
      #AddModule:
        AddModule(tTarget, tDataList)
      #DeleteScript:
        DeleteScript(0, tTarget, tDataList)
      #SetAttribute:
        SetAttribute(tTarget, tDataList)
      #AddObstacle:
        AddObstacle(0, tTarget, tDataList)
      #SetObstacle:
        SetObstacle(tTarget, tDataList)
      #AddCollisionReport:
        AddCollisionReport(tTarget, tDataList)
      #Defog:
        Defog(tTarget)
      #SetFog:
        SetFog(0, tTarget, tDataList)
      #CreateSprite:
        CreateSprite(tTarget, tDataList)
      #ResetSprites:
        ResetSprites(tTarget, tDataList)
      #DeleteSprite:
        DeleteSprite(tTarget, tDataList)
      #CreateImage:
        CreateImage(tTarget, tDataList)
      #SetText:
        SetText(tTarget, tDataList)
      #SetModel:
        SetModel(0, tTarget, tDataList)
      #AddTimer:
        AddTimer(0, tTarget, tDataList)
      #RemoveTimer:
        RemoveTimer(0, tTarget, tDataList)
      #LinkToTheRoot:
        LinkToTheRoot(0, tTarget, tDataList)
      #DeleteTheModels:
        DeleteTheModels(0, tTarget, tDataList)
      #SetAnimation:
        SetAnimation(tTarget, tDataList)
      #BlendShader:
        BlendShader(tTarget, tDataList)
      #CMCreateTexturesCast:
        CMCreateTexturesCast(tTarget)
      #CMCloneAndSetModelsCast:
        CMCloneAndSetModelsCast(tTarget, tDataList)
      #SetParameters:
        SetParameters(tTarget, tDataList)
      #PlayMenuAnimation:
        PlayMenuAnimation(tTarget, tDataList)
      #SetupSoundManager:
        SetupSoundManager()
      #PlaySound:
        PlaySound(tTarget, tDataList)
      #StopSound:
        StopSound(tTarget, tDataList)
      #StopAllSound:
        StopAllSound()
      #SetSound:
        SetSound(tTarget, tDataList)
      #FadeSound:
        FadeSound(tTarget, tDataList)
      #BindKey:
        BindKey(tTarget, tDataList)
      #UnBindKey:
        UnBindKey(tTarget, tDataList)
      #AddButton3D:
        AddButton3D(tTarget, tDataList)
      #RemoveButton3D:
        RemoveButton3D(tTarget, tDataList)
      #SetupLighting:
        SetupLighting(tTarget, tDataList)
      #wait:
        _movie.updateStage()
      #updateStage:
        _movie.updateStage()
      #puppetTempo:
        _movie.puppetTempo(value(tTarget))
      #registerForEvent:
        registerForEvent(tTarget, tDataList)
      #unregisterAllEvents:
        unregisterAllEvents(tTarget, tDataList)
      #BlackOut:
        BlackOut(tTarget, tDataList)
      #Fade:
        Fade(tTarget, tDataList)
      #ClearFades:
        ClearFades(tTarget, tDataList)
      #RunHandler:
        RunHandler(tTarget, tDataList)
      #CreateItem3D:
        CreateItem3D(tTarget, tDataList)
      #DeleteItem3D:
        DeleteItem3D(tTarget, tDataList)
      #SetItem3D:
        SetItem3D(tTarget, tDataList)
      #ManipulateTime:
        ManipulateTime(tTarget, tDataList)
      #MiniCalculator:
        MiniCalculator(0, tTarget, tDataList)
      #cursor:
        _player.cursor(value(tTarget))
      #unload:
        member(tTarget).unload()
      #CreateTimeOut:
        CreateTimeOut(tTarget, tDataList)
      #goto:
        goto(tTarget, tDataList)
      #do:
        DoHandler(tTarget, tDataList)
      #PutMessage:
        put tTarget
      #AlertMessage:
        alert(string(tTarget))
      #OpenWebPage:
        gotoNetPage(tTarget, "_new")
      #AddTrigger:
        AddTrigger(tTarget, tDataList)
      #Evaluate:
        Evaluate(0, tTarget, tDataList)
      #AllShadersFullEmissive:
        AllShadersFullEmissive(tTarget, tDataList)
      #DefineWayPoints:
        DefineWayPoints(tTarget, tDataList)
      #CreateTile:
        CreateTile(0, tTarget, tDataList)
      #SetCheckPoints:
        SetCheckPoints(tTarget, tDataList)
      #event:
        event(tDataList)
      #DelayEvent:
        DelayEvent(0, tTarget, tDataList)
      #DelayCommand:
        DelayCommand(0, tTarget, tDataList)
      otherwise:
        ShowError("No Such Function. Function was: " & tFunction)
    end case
  end repeat
  gSystem.event = EMPTY
end

on DelayEvent me, tTarget, tDataList
  ShowError("Function: DelayEvent. Target: " & tTarget & " Parameters: " & tDataList)
  tDataList = tDataList
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if (tDataList = VOID) or (tDataList.ilk <> #propList) then
    ShowError("Function: DelayEvent. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  pDelay = tDataList[#delay]
  if pDelay = VOID then
    pDelay = 1000
  end if
  pevent = tDataList[#event]
  if pevent = VOID then
    pevent = EMPTY
  end if
  pAmount = _movie.timeoutList.count + 1
  if tDataList[#name].ilk = #string then
    tName = tDataList.name
  else
    tName = "Delay" & pevent & _system.milliSeconds & _movie.timeoutList.count + 1 & random(1, 10000)
  end if
  timeout().new(tName, pDelay, #DelayEventTimeOut, pevent)
end

on DelayEventTimeOut tEvent, tTimeOut
  event(tEvent)
  if _movie.timeoutList.getPos(tTimeOut) <> 0 then
    tTimeOut.forget()
  end if
end

on DelayCommand me, tTarget, tDataList
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tDelay = tDataList[#delay]
  if tDataList[#delay].ilk = #integer then
    tDelay = tDataList.delay
  else
    tDelay = 1000
  end if
  tList = []
  if tDataList[#command].ilk = #string then
    tCommand = tDataList.command
  else
    return 0
  end if
  if tDataList[#target].ilk = #string then
    tTarget = tDataList.target
  else
    return 0
  end if
  if tDataList[#data].ilk = #propList then
    tData = tDataList.data
  else
    return 0
  end if
  timeout().new("Delay" & tCommand & _system.milliSeconds & _movie.timeoutList.count + 1 & random(1, 10000), tDelay, #DelayCommandTimeOut, [#handler: tCommand, #target: tTarget, #data: tData])
end

on DelayCommandTimeOut tList, tTimeOut
  sendSprite(0, symbol(tList.handler), tList.target, tList.data)
  if _movie.timeoutList.getPos(tTimeOut) <> 0 then
    tTimeOut.forget()
  end if
end

on AddToGlobals tmember, tDataList
  repeat with i = 1 to tmember.text.line.count
    tLine = tmember.text.line[i]
    if tLine.word.count = 0 then
      next repeat
    end if
    if tLine contains "//" then
      next repeat
    end if
    AddValue(0, EMPTY, [#name: tLine.item[1], #value: tLine.item[2]])
  end repeat
end

on AddToData tmember, tDataList
  if (tmember = VOID) or (tmember.type <> #text) then
    ShowError("Function: AddEventsFromFile. Member: " & tmember & " Member VOID or no text member. Function aborted.")
    exit
  end if
  tDataList = value(tDataList)
  if tDataList.ilk <> #propList then
    tDataList = [:]
  end if
  tRemove = 0
  if voidp(tDataList[#Remove]) = 0 then
    tRemove = tDataList.Remove
  end if
  tAddEventState = 0
  tTag = VOID
  if tDataList.list = #Triggers then
    repeat with qw = 1 to tmember.line.count
      tLine = tmember.line[qw]
      if (tLine.word.count = 0) or (tLine.length = 0) or (tLine contains "//") then
        next repeat
      end if
      tTrigger = [:]
      SetItemDelimiter(TAB)
      tTriggers = tLine.item[1]
      tDataList = value(tLine.item[2])
      AddTrigger(tTriggers, tDataList)
    end repeat
  else
    repeat with qw = 1 to tmember.line.count
      tLine = tmember.line[qw]
      if (tLine.word.count = 0) or (tLine.length = 0) or (tLine contains "//") then
        next repeat
      end if
      if tLine.word.count = 1 then
        tWord = tLine.word[1]
        if tWord contains "_Begin" then
          SetItemDelimiter("_")
          tTag = tWord.item[1]
          if tRemove = 1 then
            gData[symbol("Stored" & string(tDataList.list))].add(symbol(tTag))
          end if
          tAddEventState = 1
          tSubList = [:]
          next repeat
        end if
        if tWord contains "_End" then
          gData[tDataList.list][symbol(tTag)] = tSubList
          tTag = VOID
          tAddEventState = 0
          next repeat
        end if
      end if
      if tAddEventState = 1 then
        SetItemDelimiter(TAB)
        delete tLine.char[1..1]
        tProp = symbol(tLine.item[1])
        if (tDataList.list = #data) or (tWord contains "Data") then
          tPropList = value(tLine.item[2])
          if tPropList = VOID then
            if tLine.item.count > 2 then
              tPropList = []
              repeat with n = 2 to tLine.item.count
                if (n = tLine.item.count) and (tLine.item[n] = EMPTY) then
                  nothing()
                  next repeat
                end if
                tPropList.add(tLine.item[n])
              end repeat
              if tPropList.count = 1 then
                tPropList = tPropList[1]
              end if
            else
              tPropList = tLine.item[2]
            end if
          end if
          tSubList.addProp(tProp, tPropList)
          next repeat
        end if
        tSubList.addProp(tProp, [tLine.item[2], tLine.item[3]])
      end if
    end repeat
  end if
end

on RemoveFromData tTag
  if tTag = VOID then
    exit
  end if
  if gData[symbol("Stored" & tTag)].ilk <> #list then
    exit
  end if
  if gData[symbol("Stored" & tTag)].count > 0 then
    repeat with i in gData[symbol("Stored" & tTag)]
      gData[tTag].deleteProp(i)
    end repeat
  end if
  gData[symbol("Stored" & tTag)] = []
end

on ShowError tString
  if gSystem.debug = 1 then
    put tString
  end if
end
