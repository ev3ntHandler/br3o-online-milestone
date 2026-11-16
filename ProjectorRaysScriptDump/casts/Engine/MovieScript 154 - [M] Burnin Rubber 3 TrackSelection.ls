global gData, gGame, g

on BuildTrackInfo me
  tList = [:]
  tText = member("TrackInfo").text
  SetItemDelimiter(TAB)
  tProps = tText.line[1]
  repeat with i = 1 to tProps.item.count
    tList[symbol(tProps.item[i])] = []
  end repeat
  repeat with i = 2 to tText.line.count
    tLine = tText.line[i]
    repeat with j = 1 to tLine.item.count
      tList[j].add(tLine.item[j])
    end repeat
  end repeat
  gGame[#trackInfo] = tList.duplicate()
  tContinentList = []
  repeat with i in tList.Continent
    if tContinentList.getPos(i) = 0 then
      tContinentList.add(i)
    end if
  end repeat
  CompleteContintentsList(0, tContinentList)
end

on CompleteContintentsList me, tList
  tTotalList = [:]
  repeat with j in tList
    tContinent = j
    tTotalList[symbol(tContinent)] = [:]
    tTotalList[symbol(tContinent)][#state] = #locked
    tContinentList = [:]
    repeat with i = 1 to gGame.trackInfo.Continent.count
      if gGame.trackInfo.Continent[i] = tContinent then
        tLoc = gGame.trackInfo.location[i]
        if voidp(tContinentList[tLoc]) = 1 then
          tContinentList[tLoc] = [#state: #locked, #tracks: [:], #data: [#GameMode: [], #target: [], #PrizeMoney: [], #rewards: [], #Unlockables: [], #description: []]]
        end if
        tTrackname = gGame.trackInfo.TrackName[i]
        if gGame.Cheat = 1 then
          tLock = #new
        else
          tLock = #locked
        end if
        if voidp(gGame.trackList[symbol(tTrackname)]) = 1 then
          tContinentList[tLoc][#tracks].addProp(symbol(tTrackname), tLock)
        else
          tContinentList[tLoc][#tracks].addProp(symbol(tTrackname), gGame.trackList[symbol(tTrackname)])
        end if
        tContinentList[tLoc].data.GameMode.add(gGame.trackInfo.GameMode[i])
        tContinentList[tLoc].data.Unlockables.add(gGame.trackInfo.Unlockables[i])
        tContinentList[tLoc].data.PrizeMoney.add(gGame.trackInfo.PrizeMoney[i])
        tContinentList[tLoc].data.target.add(gGame.trackInfo.target[i])
        tContinentList[tLoc].data.rewards.add(gGame.trackInfo.rewards[i])
        tContinentList[tLoc].data.description.add(gGame.trackInfo.description[i])
      end if
    end repeat
    tTotalList[symbol(j)][#locations] = tContinentList.duplicate()
  end repeat
  gGame[#ContinentsList] = tTotalList.duplicate()
  repeat with i in gGame.ContinentsList
    repeat with j in i.locations
      tList = []
      repeat with k in j.tracks
        tList.add(k)
      end repeat
      if tList.getPos(#new) <> 0 then
        j.state = #new
        i.state = #new
        next repeat
      end if
      tCompleted = 1
      repeat with m in tList
        if m <> #Completed then
          tCompleted = 0
          exit repeat
        end if
      end repeat
      tLocked = 1
      repeat with m in tList
        if m <> #locked then
          tLocked = 0
          exit repeat
        end if
      end repeat
      if tCompleted = 1 then
        j.state = #Cleared
        next repeat
      end if
      if tLocked = 0 then
        j.state = #Unlocked
        next repeat
      end if
      j.state = #locked
    end repeat
    tNew = 0
    repeat with j in i.locations
      if j.state = #new then
        tNew = 1
        exit repeat
      end if
    end repeat
    if tNew = 1 then
      i.state = #new
      next repeat
    end if
    tLocked = 1
    repeat with j in i.locations
      if (j.state = #Cleared) or (j.state = #Unlocked) then
        tLocked = 0
        exit repeat
      end if
    end repeat
    if tLocked = 0 then
      i.state = #Unlocked
      next repeat
    end if
    i.state = #locked
  end repeat
end

on buildContinentButtons me
  repeat with i = 1 to gGame.ContinentsList.count
    tProp = gGame.ContinentsList.getPropAt(i)
    if tProp = #DailyChallenge then
      exit repeat
    end if
    tList = gGame.ContinentsList[i]
    CreateTextTexture(0, "Main", [#text: gData.data.text[tProp], #texture: "Continent" & i & "ButtonNormal_Texture", #fontSize: 15, #width: 128, #color: rgb(132, 133, 137)])
    CreateTextTexture(0, "Main", [#text: gData.data.text[tProp], #texture: "Continent" & i & "ButtonRollover_Texture", #fontSize: 15, #width: 128, #color: rgb(255, 255, 255)])
    ASSIGNTEXTURE("Main", [#material: "Continent" & i & "Button_Material", #texture1: "Continent" & i & "ButtonNormal_Texture"])
    if (tList.state = #new) or (tList.state = #Unlocked) then
      CreateButton(0, "Main", [#model: string(tProp), #event: "ShowContinent", #rollover: "Continent" & i & "ButtonRollover_Texture", #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX"])
      if tList.state = #new then
        SETVISIBLE(0, "Main", [#model: "Continent" & i & "State", #parent: "Continents", #state: 1])
      else
        SETVISIBLE(0, "Main", [#model: "Continent" & i & "State", #state: 0])
      end if
      member("Main").shader("Continent" & i & "Button_Material").blend = 100
      next repeat
    end if
    member("Main").shader("Continent" & i & "Button_Material").blend = 50
    SETVISIBLE(0, "Main", [#model: "Continent" & i & "State", #state: 0])
  end repeat
end

on SetContinentButtons me
  repeat with i = 1 to gGame.ContinentsList.count
    tProp = gGame.ContinentsList.getPropAt(i)
    if tProp = #DailyChallenge then
      exit repeat
    end if
    tList = gGame.ContinentsList[i]
    if string(tProp) = gGame.selectedContinent then
      CreateTextTexture(0, "Main", [#text: gData.data.text[tProp], #texture: "Continent" & i & "ButtonNormal_Texture", #fontSize: 15, #width: 128, #color: rgb(0, 0, 0)])
      SetModel(0, "Main", [#model: "Continent" & i & "Tag", #shader: "Orange_Material"])
      DeleteButton(0, "Main", [#model: string(tProp)])
      next repeat
    end if
    CreateTextTexture(0, "Main", [#text: gData.data.text[tProp], #texture: "Continent" & i & "ButtonNormal_Texture", #fontSize: 15, #width: 128, #color: rgb(132, 133, 137)])
    CreateTextTexture(0, "Main", [#text: gData.data.text[tProp], #texture: "Continent" & i & "ButtonRollover_Texture", #fontSize: 15, #width: 128, #color: rgb(255, 255, 255)])
    ASSIGNTEXTURE("Main", [#material: "Continent" & i & "Button_Material", #texture1: "Continent" & i & "ButtonNormal_Texture"])
    SetModel(0, "Main", [#model: "Continent" & i & "Tag", #shader: "Black_Material"])
    if (tList.state = #new) or (tList.state = #Unlocked) then
      CreateButton(0, "Main", [#model: string(tProp), #event: "ShowContinent", #rollover: "Continent" & i & "ButtonRollover_Texture", #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX"])
      if tList.state = #new then
        SETVISIBLE(0, "Main", [#model: "Continent" & i & "State", #parent: "Continents", #state: 1])
      else
        SETVISIBLE(0, "Main", [#model: "Continent" & i & "State", #state: 0])
      end if
      member("Main").shader("Continent" & i & "Button_Material").blend = 100
      next repeat
    end if
    member("Main").shader("Continent" & i & "Button_Material").blend = 50
    SETVISIBLE(0, "Main", [#model: "Continent" & i & "State", #state: 0])
  end repeat
end

on BuildLocationButtons me
  tEarth = member("Earth")
  tmember = member("Main")
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations
  if gGame.selectedContinent = "DailyChallenge" then
    return 0
  end if
  repeat with i = 1 to tList.count
    tLoc = tList.getPropAt(i)
    tState = tList[tLoc].state
    tState = tList[tLoc].state
    if tState <> #locked then
      tScreenSpace = tEarth.camera("Earth_Camera").worldSpaceToSpriteSpace(tEarth.model(tLoc).worldPosition)
      tVector = vector(tScreenSpace.locH * gGame.ResRatio, 0, -tScreenSpace.locV * gGame.ResRatio) + vector(0, 0, -1002.5)
      tGameMode = tList[tLoc].data.GameMode[1]
      tTag = "Track"
      if tGameMode = "BossBattle" then
        tTag = "Boss"
      end if
      if tLoc = "Ignition" then
        tTag = "Boss"
      end if
      tmodel = tmember.newModel(tLoc, tmember.modelResource(tTag & "Normal"))
      tmodel.transform.position = tVector
      tmodel.shader = member("Main").shader(tTag & "Normal_Material")
      tmodel.transform.scale = vector(1, 1, 1) * 0.69999999999999996
      tmodel.parent = tmember.model("TrackSelection2D")
      tParent = tmember.model("TrackSelection2D")
      tmodel.transform = tParent.getWorldTransform().inverse() * tmodel.transform
      tmodel.parent = tParent
      gGame.currentMarkers.buttons.add(tmodel)
      SETVISIBLE(0, "Main", [#model: tmodel.name, #state: 0])
      if gGame.CurrentMenu = "CarSelection" then
        SETVISIBLE(0, "Main", [#model: tmodel.name, #state: 1])
      else
        DelayCommand(0, EMPTY, [#delay: -66 + (i * 100), #command: "SetVisible", #target: "Main", #data: [#model: tmodel.name, #state: 1]])
      end if
      if tState = #new then
        tNewModel = tmember.newModel("NewTag_" & tLoc, tmember.modelResource("NewTag"))
        tNewModel.shader = tmember.shader("NewTag_Material")
        tNewModel.parent = tmodel
        if tTag = "Boss" then
          tNewModel.transform.position = vector(0, -10, 3)
        else
          tNewModel.transform.position = vector(0, -10, 20)
        end if
        tNewModel.transform.rotation = vector(0, -15, 20)
        tNewModel.transform.scale = vector(1, 1, 1) * 0.80000000000000004
        gGame.currentMarkers.Misc.add(tNewModel)
      end if
      if tState = #Cleared then
        tmodel.shader = member("Main").shader(tTag & "Cleared_Material")
        tClearedModel = tmember.newModel("ClearedTag_" & tLoc, tmember.modelResource("ClearedTag"))
        tClearedModel.shader = tmember.shader("ClearedTag_Material")
        tClearedModel.parent = tmodel
        tClearedModel.transform.position = vector(0, -1, 21)
        tClearedModel.transform.rotation = vector(0, -15, 20)
        tClearedModel.transform.scale = vector(1, 1, 1) * 0.80000000000000004
        gGame.currentMarkers.Misc.add(tClearedModel)
      end if
      CreateButton(0, "Main", [#model: tmodel.name, #event: "ShowChallenges", #shader: 1, #rolloverShader: tTag & "Rollover_Material", #alpha: 0, #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX", #effect: #scale])
      next repeat
    end if
    nothing()
  end repeat
end

on SetLocationButtons me
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations
  tmember = member("Main")
  repeat with i = 1 to tList.count
    tLoc = tList.getPropAt(i)
    tmodel = tmember.model(tLoc)
    if tmodel = VOID then
      next repeat
    end if
    tGameMode = tList[tLoc].data.GameMode[1]
    tTag = "Track"
    if tGameMode = "BossBattle" then
      tTag = "Boss"
    end if
    if tLoc = "Ignition" then
      tTag = "Boss"
    end if
    if tmodel.name = gGame.selectedLocation then
      DeleteButton(0, "Main", [#model: tmodel.name])
      tmodel.shader = tmember.shader(tTag & "Selected_Material")
      tmodel.transform.scale = vector(1, 1, 1)
      next repeat
    end if
    tmodel.shader = tmember.shader(tTag & "Normal_Material")
    if voidp(gGame.menu.buttons[tmodel.name]) = 1 then
      tmodel.transform.scale = vector(1, 1, 1) * 0.69999999999999996
      CreateButton(0, "Main", [#model: tmodel.name, #event: "ShowChallenges", #shader: 1, #rolloverShader: tTag & "Rollover_Material", #alpha: 1, #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX", #effect: #scale])
    end if
  end repeat
end

on DeleteLocationButtons me
  tmember = member("Main")
  tList = gGame.currentMarkers.buttons.duplicate()
  repeat with i in tList
    tName = i.name
    gGame.currentMarkers.buttons.deleteOne(i)
    DeleteButton(0, "Main", [#model: tName])
    tmember.deleteModel(tName)
  end repeat
  tList = gGame.currentMarkers.Misc.duplicate()
  repeat with i in tList
    tName = i.name
    gGame.currentMarkers.Misc.deleteOne(i)
    tmember.deleteModel(i.name)
  end repeat
end

on BuildChallengeButtons me
  tLoc = gGame.selectedLocation
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations[tLoc]
  tmember = member("Main")
  if gGame.lastBuildText <> #none then
    Delete3DText(0, "Main", [#text: gGame.lastBuildText.name])
  end if
  gGame.lastBuildText = Create3DText(0, "Main", [#text: tLoc & " ", #size: 50, #alignH: #left, #alignV: #top, #alignVRef: "Challenge1Bullet", #parent: "Challenges", #shader: "WhiteFont3D_Material", #glow: 1, #glowShader: "WhiteFont3DGlow_Material", #offset: vector(0, 0, 0)])
  gGame.lastBuildText.transform.position = gGame.lastBuildText.transform.position + vector(0, 0, 57)
  repeat with i = 1 to 4
    if i > tList.tracks.count then
      SETVISIBLE(0, "Main", [#model: ["Challenge" & i & "State", "Challenge" & i & "Button"], #state: 0])
      next repeat
    end if
    SETVISIBLE(0, "Main", [#model: "Challenge" & i & "State", #parent: "Challenge" & i & "Bullet", #state: 1])
    SETVISIBLE(0, "Main", [#model: "Challenge" & i & "Button", #parent: "Challenge" & i, #state: 1])
    tProp = tList.tracks.getPropAt(i)
    tTrackname = string(tProp)
    tTrackState = tList.tracks[i]
    tGameMode = tList.data.GameMode[i]
    tmodel = tmember.model("Challenge" & i & "State")
    if tTrackState = #Unlocked then
      SETVISIBLE(0, "Main", [#model: tmodel.name, #state: 0])
    else
      tmodel.resource = tmember.modelResource(tTrackState & "Tag")
      tmodel.shader = tmember.model(tTrackState & "Tag").shader
      tmodel.transform.scale = vector(1, 1, 1) * 0.5
      if tTrackState = #new then
        tmodel.transform.rotation.z = 15
      else
        tmodel.transform.rotation.z = 0
      end if
    end if
    if tTrackState = #locked then
      CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tGameMode)], #texture: "Challenge" & i & "ButtonNormal_Texture", #fontSize: 15, #width: 256, #color: rgb(132, 133, 137), #nearFiltering: 1])
      ASSIGNTEXTURE("Main", [#material: "Challenge" & i & "Button_Material", #texture1: "Challenge" & i & "ButtonNormal_Texture"])
      tmember.shader("Challenge" & i & "Button_Material").blend = 50
      if gGame.HiddenPackageList.getPos(symbol(tTrackname)) = 0 then
        tmember.model("Challenge" & i & "HiddenPackage").resource = tmember.modelResource("HiddenPackageNone")
      end if
      next repeat
    end if
    CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tGameMode)], #texture: "Challenge" & i & "ButtonNormal_Texture", #fontSize: 15, #width: 256, #color: rgb(132, 133, 137), #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowGrey], #nearFiltering: 1])
    CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tGameMode)], #texture: "Challenge" & i & "ButtonRollover_Texture", #fontSize: 15, #width: 256, #color: rgb(255, 255, 255), #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite], #nearFiltering: 1])
    ASSIGNTEXTURE("Main", [#material: "Challenge" & i & "Button_Material", #texture1: "Challenge" & i & "ButtonNormal_Texture"])
    CreateButton(0, "Main", [#model: "Challenge" & i & "Button", #handler: "SelectChallenge", #rollover: "Challenge" & i & "ButtonRollover_Texture", #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX", #effect: #HiddenPackage])
    tmember.shader("Challenge" & i & "Button_Material").blend = 100
    if gGame.HiddenPackageList.getPos(symbol(tTrackname)) = 0 then
      tmember.model("Challenge" & i & "HiddenPackage").resource = tmember.modelResource("HiddenPackageNone")
      next repeat
    end if
    tmember.model("Challenge" & i & "HiddenPackage").resource = tmember.modelResource("HiddenPackageNormal")
  end repeat
  tPos = 1
  tPos = tList.tracks.getPos(#new)
  tPos = tList.tracks.getPos(#Completed)
  tPos = tList.tracks.getPos(#Unlocked)
  if tPos = 0 then
    tPos = 1
  end if
  gGame.PressedButton = "Challenge" & tPos & "Button"
  SelectChallenge()
end

on SetChallengeButtons me
  tLoc = gGame.selectedLocation
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations[tLoc].duplicate()
  tmember = member("Main")
  repeat with i = 1 to 4
    if i > tList.tracks.count then
      SetModel(0, "Main", [#model: "Challenge" & i, #shader: "Black_Material"])
      next repeat
    end if
    tmodel = tmember.model("Challenge" & i & "Button")
    tTrackname = string(tList.tracks.getPropAt(i))
    tGameMode = tList.data.GameMode[i]
    tTrackState = tList.tracks[i]
    if i = gGame.SelectedTrack[2] then
      DeleteButton(0, "Main", [#model: tmodel.name])
      CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tGameMode)], #texture: "Challenge" & i & "ButtonNormal_Texture", #fontSize: 15, #width: 256, #color: rgb(0, 0, 0), #nearFiltering: 1])
      SetModel(0, "Main", [#model: "Challenge" & i, #shader: "Orange_Material"])
      UpdateChallengeInfo()
      if gGame.HiddenPackageList.getPos(symbol(tTrackname)) = 0 then
        tmember.model("Challenge" & i & "HiddenPackage").resource = tmember.modelResource("HiddenPackageNone")
      else
        tmember.model("Challenge" & i & "HiddenPackage").resource = tmember.modelResource("HiddenPackageSelected")
      end if
    else
      if tTrackState = #locked then
        DeleteButton(0, "Main", [#model: tmodel.name])
      else
        if voidp(gGame.menu.buttons[tmodel.name]) = 1 then
          CreateButton(0, "Main", [#model: tmodel.name, #handler: "SelectChallenge", #rollover: "Challenge" & i & "ButtonRollover_Texture", #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX", #effect: #HiddenPackage])
        end if
        CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tGameMode)], #texture: "Challenge" & i & "ButtonNormal_Texture", #fontSize: 15, #width: 256, #color: rgb(132, 133, 137), #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowGrey], #nearFiltering: 1])
        SetModel(0, "Main", [#model: "Challenge" & i, #shader: "Black_Material"])
        if gGame.HiddenPackageList.getPos(symbol(tTrackname)) = 0 then
          tmember.model("Challenge" & i & "HiddenPackage").resource = tmember.modelResource("HiddenPackageNone")
        else
          tmember.model("Challenge" & i & "HiddenPackage").resource = tmember.modelResource("HiddenPackageNormal")
        end if
      end if
    end if
    tTag = tmember.model("Challenge" & i & "State")
    if tTrackState = #Unlocked then
      SETVISIBLE(0, "Main", [#model: tTag.name, #state: 0])
      next repeat
    end if
    tTag.resource = tmember.modelResource(tTrackState & "Tag")
    tTag.shader = tmember.model(tTrackState & "Tag").shader
    tTag.transform.scale = vector(1, 1, 1) * 0.5
    if tTrackState = #new then
      tTag.transform.rotation.z = 15
      next repeat
    end if
    tTag.transform.rotation.z = 0
  end repeat
end

on EnterHiddenPackage me, tButton
  tmember = member("Main")
  tLoc = gGame.selectedLocation
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations[tLoc].duplicate()
  tPos = value(tButton.name.char[10])
  tTrackname = string(tList.tracks.getPropAt(tPos))
  if gGame.HiddenPackageList.getPos(symbol(tTrackname)) <> 0 then
    tmember.model("Challenge" & tPos & "HiddenPackage").resource = tmember.modelResource("HiddenPackageRollover")
  end if
end

on LeaveHiddenPackage me, tButton
  tmember = member("Main")
  tLoc = gGame.selectedLocation
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations[tLoc].duplicate()
  tPos = value(tButton.name.char[10])
  tTrackname = string(tList.tracks.getPropAt(tPos))
  if gGame.HiddenPackageList.getPos(symbol(tTrackname)) <> 0 then
    tmember.model("Challenge" & tPos & "HiddenPackage").resource = tmember.modelResource("HiddenPackageNormal")
  end if
end

on SelectChallenge me
  tButtonList = ["Challenge1Button", "Challenge2Button", "Challenge3Button", "Challenge4Button"]
  tPos = tButtonList.getPos(gGame.PressedButton)
  tLoc = gGame.selectedLocation
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations[tLoc]
  tTrackname = string(tList.tracks.getPropAt(tPos))
  tGameMode = tList.data.GameMode[tPos]
  gGame.SelectedTrack = [tTrackname, tPos]
  gGame.selectedGameMode = tGameMode
  SetChallengeButtons()
  event(#ChallengeSelected)
end

on UpdateChallengeInfo me
  tmember = member("Main")
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations[gGame.selectedLocation]
  tInfo = convertToUpperCase(0, tList.data.description[gGame.SelectedTrack[2]])
  CreateTextTexture(0, "Main", [#text: tInfo, #texture: "TrackInfo_Texture", #fontSize: 11, #lineSpacing: 10, #width: 384, #height: 64, #align: #left, #wrap: 1, #forceSize: [512, 64], #color: rgb(0, 0, 0)])
  tMoney = tList.data.PrizeMoney[gGame.SelectedTrack[2]]
  tMoney = FormatPrice(0, tMoney)
  if tMoney = EMPTY then
    tMoney = "0"
  end if
  CreateTextTexture(0, "Main", [#text: tMoney, #texture: "PrizeMoney_Texture", #fontSize: 27, #lineSpacing: 30, #width: 256, #height: 64, #align: #right, #color: rgb(0, 0, 0)])
  if gGame.selectedGameMode = "Rampage" then
    CreateTextTexture(0, "Main", [#text: gData.data.text.DamageTarget, #texture: "PrizeMoneyTag_Texture", #fontSize: 14, #width: 256, #height: 32, #align: #right, #color: gData.data.TextColor.Black, #nearFiltering: 1])
  else
    CreateTextTexture(0, "Main", [#text: gData.data.text.PrizeMoney, #texture: "PrizeMoneyTag_Texture", #fontSize: 15, #width: 256, #height: 32, #align: #right, #color: gData.data.TextColor.Black, #nearFiltering: 1])
  end if
  SetItemDelimiter("!")
  repeat with i = 1 to 3
    tText = tList.data.Unlockables[gGame.SelectedTrack[2]]
    if (gGame.selectedGameMode <> "Rampage") and (gGame.selectedGameMode <> "Elimination") then
      tTargetTime = FormatTime(0, tList.data.target[gGame.SelectedTrack[2]])
      tText = tText & "FOR A BONUS - FINISH UNDER " & tTargetTime & "!"
    end if
    if i > tText.item.count then
      SETVISIBLE(0, "Main", [#model: "ChallengeUnlock" & i, #state: 0])
      next repeat
    end if
    tString = convertToUpperCase(0, tText.item[i])
    if tString.char[1] = " " then
      delete tString.char[1]
    end if
    if tString <> EMPTY then
      SETVISIBLE(0, "Main", [#model: "ChallengeUnlock" & i, #parent: "ChallengeInfo", #state: 1])
      CreateTextTexture(0, "Main", [#text: "• " & tString & "!", #texture: "Unlock" & i & "_Texture", #fontSize: 9, #width: 256, #align: #left, #color: rgb(0, 0, 0)])
      next repeat
    end if
    SETVISIBLE(0, "Main", [#model: "ChallengeUnlock" & i, #state: 0])
  end repeat
  ResetItemDelimiter()
end

on SetupTrackVariables me
  tTempTrack = gGame.SelectedTrack[1]
  if tTempTrack contains "Desert" then
    gGame.world = "Desert"
    gGame.track = value(tTempTrack.char[12..tTempTrack.length])
  end if
  if tTempTrack contains "City" then
    gGame.world = "City"
    gGame.track = value(tTempTrack.char[10..tTempTrack.length])
  end if
  if tTempTrack contains "Snow" then
    gGame.world = "Snow"
    gGame.track = value(tTempTrack.char[10..tTempTrack.length])
  end if
  if tTempTrack contains "Jungle" then
    gGame.world = "Jungle"
    gGame.track = value(tTempTrack.char[12..tTempTrack.length])
  end if
  tList = gGame.ContinentsList[symbol(gGame.selectedContinent)].locations[gGame.selectedLocation]
  gGame.GameMode = gGame.selectedGameMode
  gGame.TrackName = gGame.selectedLocation
  gGame.target = value(tList.data.target[gGame.SelectedTrack[2]])
  gGame.PrizeMoney = value(tList.data.PrizeMoney[gGame.SelectedTrack[2]])
  gGame.rewards = tList.data.rewards[gGame.SelectedTrack[2]]
  put "HIER STAAT DE TRACK NAAM EN DE GAME MODE: " & gGame.TrackName && tTempTrack && gGame.GameMode
end

on FormatTime me, tMillisec
  sec = integer(tMillisec / 1000)
  min = integer(sec / 60)
  sec = sec - (min * 60)
  Hour = integer(min / 60)
  min = min - (Hour * 60)
  tMillisec = integer((tMillisec - (sec * 1000) - (min * 60 * 1000) - (Hour * 60 * 60 * 1000)) / 10.0)
  if min < 10 then
    minString = "0" & string(min + 100).char[3..3] & "."
  else
    minString = string(min + 100).char[3..3] & "."
  end if
  secString = string(sec + 100).char[2..3]
  tString = minString & secString
  tString = tString.char[2..tString.length]
  return tString
end

on FormatPrice me, tPrice
  if tPrice.ilk <> #string then
    tPrice = string(tPrice)
  end if
  if tPrice.length >= 4 then
    put "," before tPrice.char[the length of tPrice - 2]
  end if
  if tPrice.length >= 8 then
    put "," before tPrice.char[the length of tPrice - 6]
  end if
  return "$ " & tPrice
end

on UpdateCashFlow tCost
  gGame.Cash = gGame.Cash + tCost
  UpdateCash()
end

on UpdateCash me
  tCash = FormatPrice(0, string(gGame.Cash))
  CreateTextTexture(0, "Main", [#text: tCash, #texture: "Cash_Texture", #fontSize: 15, #width: 128, #align: #right, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite]])
end
