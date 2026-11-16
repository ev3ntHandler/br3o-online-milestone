global gData, gGame

on Clean me
  cleanMemory()
end

on SetCarSelectionTabs me, tSendTab
  tmember = member("Main")
  tState = gGame.CarsList[symbol(gGame.SelectedCar)]
  tList = ["Cars", "Upgrades", "BodyKits", "Weapons"]
  if tSendTab = VOID then
    tSendTab = gGame.selectedTab
  end if
  repeat with i = 1 to 4
    tTab = tList[i]
    if tTab = tSendTab then
      CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tTab & "TabName")], #texture: tTab & "TabNameNormal_Texture", #fontSize: 19, #lineSpacing: 18, #width: 128, #align: #left, #color: gData.data.TextColor.Black, #filters: [gData.data.ButtonFilters.BR3Bevel]])
      DeleteButton(0, "Main", [#model: tTab])
      SETVISIBLE(0, "Main", [#model: tTab & "Tab", #parent: "CarSelection2D", #state: 1])
      if gGame.Bosses.getPos(symbol(gGame.SelectedCar)) <> 0 then
        CreateTextTexture(0, "Main", [#text: gData.data.text.bossCar, #texture: "CarSelectionTabInfo_Texture", #align: #left, #fontSize: 10, #width: 512, #color: gData.data.TextColor.Black])
      else
        CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tTab & "TabInfo")], #texture: "CarSelectionTabInfo_Texture", #align: #left, #fontSize: 10, #width: 512, #color: gData.data.TextColor.Black])
      end if
      tmember.model(tTab).shader.blend = 100
      next repeat
    end if
    if (tState = #new) or (gGame.Bosses.getPos(symbol(gGame.SelectedCar)) <> 0) then
      DeleteButton(0, "Main", [#model: tTab])
      CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tTab & "TabName")], #texture: tTab & "TabNameNormal_Texture", #fontSize: 19, #lineSpacing: 18, #width: 128, #align: #left, #color: gData.data.TextColor.Grey, #filters: [gData.data.ButtonFilters.BR3Bevel]])
      SETVISIBLE(0, "Main", [#model: tTab & "Tab", #state: 0])
      tmember.model(tTab).shader.blend = 50
      next repeat
    end if
    CreateTextTexture(0, "Main", [#text: gData.data.text[symbol(tTab & "TabName")], #texture: tTab & "TabNameNormal_Texture", #fontSize: 19, #lineSpacing: 18, #width: 128, #align: #left, #color: gData.data.TextColor.Grey, #filters: [gData.data.ButtonFilters.BR3Bevel]])
    if voidp(gGame.menu.buttons[tTab]) = 1 then
      CreateButton(0, "Main", [#model: tTab, #event: "TabSelection", #rollover: tTab & "TabNameRollover_Texture", #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX"])
    end if
    SETVISIBLE(0, "Main", [#model: tTab & "Tab", #state: 0])
    tmember.model(tTab).shader.blend = 100
  end repeat
  if (gGame.GameMode = "Race") or (gGame.GameMode = "Goosehunt") or (gGame.GameMode = "Elimination") then
    DeleteButton(0, "Main", [#model: "Weapons"])
    CreateTextTexture(0, "Main", [#text: gData.data.text[symbol("WeaponsTabName")], #texture: "WeaponsTabNameNormal_Texture", #fontSize: 19, #lineSpacing: 18, #width: 128, #align: #left, #color: gData.data.TextColor.Grey, #filters: [gData.data.ButtonFilters.BR3Bevel]])
    tmember.model("Weapons").shader.blend = 50
  end if
end

on BuildCarPositions me
  tmember = member("Hangar")
  tList = gGame.availableCars.duplicate()
  tList.deleteOne("Tank")
  tList.deleteOne("Apache")
  tOffset = 360.0 / tList.count
  tShadowResource = tmember.modelResource("SimpleShadow")
  if tShadowResource = VOID then
    CLONEMODELS(tmember, [#cloneMember: member("SimpleShadow")])
    tmember.deleteModel("SimpleShadow")
    tmember.deleteShader("SimpleShadow_Material")
    tShadowResource = tmember.modelResource("SimpleShadow")
  end if
  repeat with i = 1 to tList.count
    tCar = tList[i]
    tVector = vector(0, 0, -tOffset + (i * tOffset))
    tNewShadow = tmember.newModel(tCar & "_Shadow", tShadowResource)
    tNewShadow.shader = DuplicateShader(0, tmember.name, [#shader: "Shadow_Material", #shaderTag: tCar])
    createTexture("Hangar", [#fileName: tCar & "Shadow_Texture"])
    tNewShadow.shader.texture = tmember.texture(tCar & "Shadow_Texture")
    tNewShadow.shader.blend = 75
    tNewShadow.transform.position = tmember.model("_Dummy").worldPosition
    tNewShadow.transform.position.z = 0.02
    tNewShadow.rotate(tVector, #world)
    tNewShadow.rotate(vector(0, 0, -90), #self)
    tNewShadow.transform.scale = vector(1, 1, 1) * gGame.ShadowScale[symbol(tCar)]
    tNewShadow.transform.scale.x = tNewShadow.transform.scale.x + 0.5
    tNewDummy = tmember.newModel(tCar & "_Dummy", tmember.modelResource("_Dummy"))
    tNewDummy.transform.position = tmember.model("_Dummy").worldPosition
    tNewDummy.rotate(tVector, #world)
    tNewDummy.removeFromWorld()
    tNewTarget = tmember.newModel(tCar & "_CameraTarget", tmember.modelResource("_CameraTarget"))
    tNewTarget.transform.rotation = tVector
    tNewTarget.removeFromWorld()
  end repeat
  createTexture("Hangar", [#fileName: "TankShadow_Texture"])
  tmember.shader("TankShadow_Material").texture = tmember.texture("TankShadow_Texture")
  tShadowModel = tmember.model("Tank_Shadow")
  tShadowModel.transform.scale = vector(1, 1, 1) * 2.5
  tShadowModel.transform.scale.x = tShadowModel.transform.scale.x + 0.5
  createTexture("Hangar", [#fileName: "ApacheShadow_Texture"])
  tmember.shader("ApacheShadow_Material").texture = tmember.texture("ApacheShadow_Texture")
  tShadowModel = tmember.model("Apache_Shadow")
  tShadowModel.transform.scale = vector(1, 1, 1) * 1.5
  tShadowModel.transform.scale.x = tShadowModel.transform.scale.x + 0.5
  tmember.deleteModel("_Shadow")
  tmember.deleteModel("_Dummy")
  tmember.deleteModel("_CameraTarget")
end

on GetAndSetCars me
  repeat with i = 1 to gGame.CarsList.count
    tCar = string(gGame.CarsList.getPropAt(i))
    tState = gGame.CarsList[i]
    BuildCarInHangar(0, tCar, tState)
  end repeat
end

on BuildCarInHangar me, tCar, tState
  tBodyKit = gData.data.bodyKit[symbol("Player" & tCar)]
  tWeapons = gData.data.Weapons[symbol("Player" & tCar)]
  tmember = member("Hangar")
  tCarMember = member(tCar)
  tWheelList = [tCar & "Wheel_LB", tCar & "Wheel_RB", tCar & "Wheel_RF", tCar & "Wheel_LF"]
  if tBodyKit.Rims > 0 then
    tResource = tCarMember.modelResource(tCar & "Rims" & tBodyKit.Rims)
    if tResource <> VOID then
      repeat with i in tWheelList
        tCarMember.model(i).resource = tResource
        tCarMember.model(i).shader = tCarMember.model(tWheelList[1]).shader
      end repeat
    end if
  end if
  tModelList = [tCar, tCar & "Glass", tCar & "Wheel_LB", tCar & "Wheel_RB", tCar & "Wheel_RF", tCar & "Wheel_LF"]
  tCount = tBodyKit.count
  repeat with i = 1 to tCount
    tProp = tBodyKit.getPropAt(i)
    if (tProp = #skin) or (tProp = #Rims) then
      next repeat
      next repeat
    end if
    if tBodyKit[i] > 0 then
      tModelList.add(tCar & string(tProp) & tBodyKit[i])
    end if
  end repeat
  if tCar = "Apache" then
    tModelList.add("ApacheTopRotor")
    tModelList.add("ApacheBackRotor")
  end if
  tModelList = CloneModel(0, tmember.name, [#sourceMember: tCar, #model: tModelList])
  tCarModel = tmember.model(tCar)
  repeat with i in tModelList
    if i.name = tCar then
      next repeat
    end if
    i.transform = tCarModel.getWorldTransform().inverse() * i.transform
    i.parent = tCarModel
    if (i.name = (tCar & "Wheel_LF")) or (i.name = (tCar & "Wheel_RF")) then
      i.transform.rotation = vector(0, 0, -25)
    end if
    if gGame.Bosses.getPos(symbol(tCar)) = 0 then
      if (i.name = (tCar & "Wheel_RF")) or (i.name = (tCar & "Wheel_RB")) then
        i.transform.scale.x = -i.transform.scale.x
        if (tCar = "Porsche") and (i.name = (tCar & "Wheel_RB")) then
          i.transform.rotation = vector(0, 0, 180)
        end if
      end if
    end if
  end repeat
  tDummy = tmember.model(tCar & "_Dummy")
  tCarModel.transform.rotation = tDummy.transform.rotation + vector(0, 0, 270)
  tCarModel.transform.position = vector(tDummy.transform.position.x, tDummy.transform.position.y, tCarModel.transform.position.z)
  if tState = #new then
    tShaderList = [tmember.shader(tCar & "_Material"), tmember.shader(tCar & "Glass_Material"), tmember.shader(tCar & "Wheels_Material")]
    repeat with i in tShaderList
      i.texture = VOID
      i.emissive = rgb(0, 0, 0)
      i.diffuse = rgb(0, 0, 0)
      i.specular = rgb(32, 32, 32)
      i.shininess = 75.0
    end repeat
  else
    tTexture = createTexture(tmember.name, [#fileName: tCar & "Skin" & tBodyKit.skin & "_Texture"])
    tShader = tmember.shader(tCar & "_Material")
    tGlassShader = tmember.shader(tCar & "Glass_Material")
    tWheelsShader = tmember.shader(tCar & "Wheels_Material")
    tShader.textureList[1] = tTexture
    tGlassShader.textureList[1] = tTexture
    tWheelsShader.textureList[1] = tTexture
    if tCar <> "Apache" then
      tShader.textureList[2] = tmember.texture("DefaultReflection_Texture")
      tShader.textureModeList[2] = #reflection
      tShader.blendFunctionList[2] = #add
      tShader.emissive = rgb(190, 180, 170)
      tShader.specular = rgb(200, 200, 200)
      tShader.shininess = 45.0
      tGlassShader.textureList[2] = tmember.texture("DefaultReflection_Texture")
      tGlassShader.textureModeList[2] = #reflection
      tGlassShader.blendFunctionList[2] = #add
      tGlassShader.emissive = rgb(190, 180, 170)
      tGlassShader.specular = rgb(200, 200, 200)
      tGlassShader.shininess = 45.0
    else
      tRotorTexture = createTexture(tmember.name, [#fileName: "ApacheRotor_Texture"])
      tmember.shader(tCar & "Rotor_Material").textureList[1] = tRotorTexture
    end if
    tWheelsShader.emissive = rgb(190, 180, 170)
    tWheelsShader.specular = rgb(200, 200, 200)
    tWheelsShader.shininess = 85.0
    if gGame.Bosses.getPos(symbol(tCar)) = 0 then
      if tmember.texture("Wheels_Texture") = VOID then
        tTexture = createTexture(tmember.name, [#fileName: "Wheels_Texture"])
      else
        tTexture = tmember.texture("Wheels_Texture")
      end if
      tmember.shader(tCar & "Wheels_Material").texture = tTexture
    else
      tmember.shader(tCar & "Wheels_Material").texture = tTexture
    end if
    tmember.shader(tCar & "Shadow_Material").blend = 85
  end if
  event("SetupWeapons")
  if (tCar <> "Tank") and (tCar <> "Apache") then
    repeat with i = 1 to tWeapons.count
      tProp = tWeapons.getPropAt(i)
      tWeapon = tWeapons[i]
      BuildWeapon(0, tProp, tWeapon, tCar)
    end repeat
  end if
  gGame.carsBuild.add(tCar)
end

on UpdateCars me
  tmember = member("Hangar")
  tCount = tmember.model.count
  repeat with i = 1 to tCount
    tmodel = tmember.model[i]
    tShader = tmodel.shader
    if tShader = VOID then
      next repeat
    end if
    if tShader.name = "Weapons_Material" then
      if (gGame.GameMode = "Race") or (gGame.GameMode = "Goosehunt") or (gGame.GameMode = "Elimination") then
        SETVISIBLE(0, "Hangar", [#model: tmodel.name, #state: 0])
        next repeat
      end if
      SETVISIBLE(0, "Hangar", [#model: tmodel.name, #state: 1])
    end if
  end repeat
  repeat with i = 1 to gGame.CarsList.count
    tCar = string(gGame.CarsList.getPropAt(i))
    if gGame.carsBuild.getPos(tCar) = 0 then
      BuildCarInHangar(0, tCar, gGame.CarsList[i])
    end if
  end repeat
end

on SelectCar me
  tMain = member("Main")
  tmember = member("Hangar")
  tCar = gGame.SelectedCar
  if gGame.lastBuildText <> #none then
    Delete3DText(0, "Main", [#text: gGame.lastBuildText.name])
  end if
  tText = gData.data.carsettings[symbol(tCar)].name
  gGame.lastBuildText = Create3DText(0, "Main", [#text: tText, #size: 32, #spacing: 10, #alignH: #left, #alignV: #top, #alignVRef: "CarStatistics", #parent: "CarStatistics", #shader: "WhiteFont3D_Material", #glow: 1, #glowShader: "Dark2Font3DGlow_Material", #offset: vector(0, 0, 0)])
  gGame.lastBuildText.transform.position = gGame.lastBuildText.transform.position + vector(0, -7, 25)
  CreateButton(0, "Main", [#model: "<NextCar", #handler: "SelectNextCar", #shader: 1, #rolloverShader: "YellowFont3D_Material", #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX"])
  CreateButton(0, "Main", [#model: ">PreviousCar", #handler: "SelectPreviousCar", #shader: 1, #rolloverShader: "YellowFont3D_Material", #rollover_sfx: "ButtonRollover_SFX", #pressed_sfx: "ButtonPressed_SFX"])
  if gGame.CarsList[symbol(tCar)] = #new then
    SETVISIBLE(0, "Main", [#model: "BuyForTag", #parent: "BuyForParent", #state: 1])
    tMain.model("CarStatisticsParent").transform.position = vector(0, 0, -21)
  else
    SETVISIBLE(0, "Main", [#model: "BuyForTag", #state: 0])
    tMain.model("CarStatisticsParent").transform.position = vector(0, 0, 0)
  end if
  tState = gGame.CarsList[symbol(tCar)]
  if tState = #new then
    SETVISIBLE(0, "Main", [#model: "NextButton", #state: 0])
    tCost = string(gData.data.carsettings[symbol(tCar)].cost)
    if tCost.length >= 4 then
      put "." before tCost.char[the length of tCost - 2]
    end if
    tCost = gData.data.text.BuyFor & " $ " & tCost
    CreateTextTexture(0, "Main", [#text: tCost, #texture: "BuyForButtonNormal_Texture", #fontSize: 19, #lineSpacing: 18, #width: 256, #align: #left, #color: gData.data.TextColor.Grey, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowGrey], #nearFiltering: 1])
    CreateTextTexture(0, "Main", [#text: tCost, #texture: "BuyForButtonRollover_Texture", #fontSize: 19, #lineSpacing: 18, #width: 256, #align: #left, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite], #nearFiltering: 1])
  else
    SETVISIBLE(0, "Main", [#model: "NextButton", #state: 1])
  end if
  tTab = gGame.selectedTab
  if gGame.Bosses.getPos(symbol(gGame.SelectedCar)) <> 0 then
    tTab = "Cars"
  end if
  if tState = #new then
    tTab = "Cars"
  end if
  SetCarSelectionTabs(0, tTab)
  gGame.car = tCar
  gGame.selectedCarTemplate = [#car: tCar, #personality: tCar, #bodyKit: "Player" & tCar, #upgrades: "Player" & tCar, #Weapons: "Player" & tCar, #settings: tCar]
  gData.data.cars.player = gGame.selectedCarTemplate
  AddToInterPolator(0, "Hangar", [#object: "Hangar_CameraTarget", #target: tCar & "_CameraTarget", #Threshold: 0.01, #Percentage: 10])
  if tCar = "BlackTruck" then
    tTag = tCar
  else
    if tCar = "Tank" then
      tTag = tCar
    else
      if tCar = "Apache" then
        tTag = tCar
      else
        tTag = EMPTY
      end if
    end if
  end if
  AddToInterPolator(0, "Hangar", [#object: "DefaultView", #target: "_NormalView" & tTag, #Threshold: 0.01, #Percentage: 10])
  UpdateStatistics()
end

on SelectNextCar me
  tPos = gGame.availableCars.findPos(gGame.SelectedCar)
  repeat with i = 1 to gGame.availableCars.count
    tPos = tPos - 1
    if tPos <= 0 then
      tPos = gGame.availableCars.count
    end if
    tNextCar = gGame.availableCars[tPos]
    if gGame.CarsList.findPos(symbol(tNextCar)) <> 0 then
      gGame.SelectedCar = tNextCar
      exit repeat
    end if
  end repeat
  gGame.scriptList[1].GetAndSetButtonList(0, 0, 1)
  SelectCar()
end

on SelectPreviousCar me
  tPos = gGame.availableCars.findPos(gGame.SelectedCar)
  repeat with i = tPos to gGame.availableCars.count
    tPos = tPos + 1
    if tPos > gGame.availableCars.count then
      tPos = 1
    end if
    tNextCar = gGame.availableCars[tPos]
    if gGame.CarsList.findPos(symbol(tNextCar)) <> 0 then
      gGame.SelectedCar = tNextCar
      exit repeat
    end if
  end repeat
  gGame.scriptList[1].GetAndSetButtonList(0, 0, 1)
  SelectCar()
end

on BuySelectedCar me
  tCost = gData.data.carsettings[symbol(gGame.SelectedCar)].cost
  if gGame.Cash >= tCost then
    event("ShowBuyCarDialog")
    tText = FormatPrice(0, tCost)
    tText = gData.data.text.BuyThisCarFor & " " & tText & " ?"
    CreateTextTexture(0, "Main", [#text: tText, #texture: "DialogText_Texture", #fontSize: 22, #lineSpacing: 22, #width: 256, #height: 64, #align: #center, #wrap: 1, #color: gData.data.TextColor.Black])
  else
    event("ShowNotEnoughMoneyDialog")
  end if
end

on buycar me
  tmember = member("Hangar")
  tCar = gGame.SelectedCar
  tCost = gData.data.carsettings[symbol(gGame.SelectedCar)].cost
  UpdateCashFlow(-tCost)
  gGame.CarsList[symbol(tCar)] = #Unlocked
  tBodyKit = gData.data.bodyKit[symbol("Player" & tCar)]
  tWeapons = gData.data.Weapons[symbol("Player" & tCar)]
  tTexture = createTexture(tmember.name, [#fileName: tCar & "Skin" & tBodyKit.skin & "_Texture", #filtering: #lowFiltered])
  tShaderList = [tmember.shader(tCar & "_Material"), tmember.shader(tCar & "Glass_Material"), tmember.shader(tCar & "Wheels_Material")]
  repeat with i in tShaderList
    i.texture = VOID
    i.emissive = rgb(190, 180, 170)
    i.diffuse = rgb(255, 255, 255)
    i.specular = rgb(200, 200, 200)
    i.shininess = 45.0
    case i.name of
      (tCar & "_Material"):
        i.textureList[1] = tTexture
        i.textureList[2] = tmember.texture("DefaultReflection_Texture")
        i.textureModeList[2] = #reflection
        i.blendFunctionList[2] = #add
      (tCar & "Glass_Material"):
        i.textureList[1] = tTexture
        i.textureList[2] = tmember.texture("DefaultReflection_Texture")
        i.textureModeList[2] = #reflection
        i.blendFunctionList[2] = #add
      (tCar & "Wheels_Material"):
        i.texture = tmember.texture("Wheels_Texture")
        i.shininess = 85.0
    end case
  end repeat
  tmember.shader(tCar & "Shadow_Material").blend = 100
  SelectCar()
  event("HideDialog")
end

on CheckWeapons me
  tList = gData.data.Weapons[symbol(gGame.selectedCarTemplate.Weapons)]
  if (gGame.GameMode = "Race") or (gGame.GameMode = "Goosehunt") or (gGame.GameMode = "Elimination") then
    event("PreStartChallenge")
  else
    if gGame.Bosses.getPos(gGame.SelectedCar) <> 0 then
      event("PreStartChallenge")
    else
      tState = 0
      if tList.primary <> "None" then
        tState = 1
      end if
      if tList.secondary <> "None" then
        tState = 1
      end if
      if tState = 0 then
        event("ShowNoWeaponsDialog")
      else
        event("PreStartChallenge")
      end if
    end if
  end if
end

on UpdateStatistics me
  tList = gData.data.upgrades[symbol(gGame.selectedCarTemplate.upgrades)]
  tmember = member("main")
  repeat with i = 1 to tList.count
    tProp = tList.getPropAt(i)
    tTag = "Upgrade"
    if (tProp = #primary) or (tProp = #secondary) then
      tCount = 12
      tTag = "Weapon"
    else
      tCount = 10
    end if
    repeat with j = 1 to tCount
      if j > tList[tProp][2] then
        tmodel = tmember.model(tTag & "SlotBlack")
      else
        if j > tList[tProp][1] then
          tmodel = tmember.model(tTag & "SlotGrey")
        else
          tmodel = tmember.model(tTag & "SlotRed")
        end if
      end if
      if (tProp = #secondary) and (tmodel = tmember.model("WeaponSlotRed")) then
        tmodel = tmember.model("WeaponSlotYellow")
      end if
      tSlot = tmember.model("Upgrade" & string(tProp) & "Slot" & j)
      tSlot.shader = tmodel.shader
    end repeat
  end repeat
end

on SetBodykits me, tBodyKit
  tmember = member("Hangar")
  tCar = gGame.SelectedCar
  tList = gData.data.bodyKit[symbol(gGame.selectedCarTemplate.bodyKit)]
  tKit = tBodyKit.name
  gGame.SelectedBodyKit = tBodyKit
  tState = gGame.BodykitList[symbol(gGame.SelectedCar)][symbol(tKit)]
  tCost = gData.data.CarBodyKits[symbol(gGame.SelectedCar)][symbol(tKit)]
  if tState = #new then
    if gGame.Cash >= tCost then
      event("ShowBuyBodyKitDialog")
      tCost = FormatPrice(0, tCost)
      tText = gData.data.text.BuyThisBodyKitFor && tCost & " ?"
      CreateTextTexture(0, "Main", [#text: tText, #texture: "DialogText_Texture", #fontSize: 22, #lineSpacing: 22, #width: 256, #height: 64, #align: #center, #wrap: 1, #color: gData.data.TextColor.Black])
    else
      event("ShowNotEnoughMoneyDialog")
    end if
  else
    if tKit contains "Skin" then
      tNr = value(tKit.char[tKit.length])
      tTexture = tmember.model(gGame.SelectedCar).shader.texture
      if tTexture <> VOID then
        tTexture.image = member(gGame.SelectedCar & "Skin" & tNr & "_Texture").image
      end if
      tList[#skin] = tNr
    end if
    if tKit contains "Spoiler" then
      if tKit = "NoSpoiler" then
        if tmember.model(tCar & "Spoiler1") <> VOID then
          tmember.deleteModel(tCar & "Spoiler1")
        end if
        tList[#spoiler] = 0
      else
        if tmember.modelResource(tCar & "Spoiler1") = VOID then
          CloneModel(0, "Hangar", [#sourceMember: tCar, #model: tCar & "Spoiler1", #delete: 1])
        end if
        if tmember.model(tCar & "Spoiler1") = VOID then
          tmodel = tmember.newModel(tCar & "Spoiler1", tmember.modelResource(tCar & "Spoiler1"))
          tmodel.transform = tmember.model(tCar).transform
          tList[#spoiler] = 1
        end if
      end if
    end if
    if tKit contains "rims" then
      tNr = value(tKit.char[tKit.length])
      tWheelList = ["Wheel_LF", "Wheel_RF", "Wheel_RB", "Wheel_LB"]
      if tmember.modelResource(tCar & tKit) = VOID then
        CloneModel(0, "Hangar", [#sourceMember: tCar, #model: tCar & tKit, #delete: 1])
      end if
      repeat with i in tWheelList
        tmember.model(tCar & i).resource = tmember.modelResource(tCar & tKit)
      end repeat
      tList[#Rims] = tNr
    end if
    if tKit contains "bumper" then
      tNr = value(tKit.char[tKit.length])
      tIntLessKit = tKit.char[1..tKit.length - 1]
      if tmember.modelResource(tCar & tKit) = VOID then
        CloneModel(0, "Hangar", [#sourceMember: tCar, #model: tCar & tKit, #delete: 1])
      end if
      tBumperModel = tmember.model(tCar & tIntLessKit & "1")
      if tBumperModel = VOID then
        tBumperModel = tmember.model(tCar & tIntLessKit & "2")
      end if
      tBumperModel.resource = tmember.modelResource(tCar & tKit)
      if tCar = "Eclipse" then
        if tNr = 2 then
          tBumperModel.transform.scale.z = 0.87890000000000001
        else
          tBumperModel.transform.scale.z = 1
        end if
      end if
      tList[symbol(tIntLessKit)] = tNr
    end if
    gGame.SelectedBodyKit = #none
    PlaySound("Equip_SFX")
  end if
end

on BuySelectedBodykit me
  event("HideDialog")
  tCost = gData.data.CarBodyKits[symbol(gGame.SelectedCar)][symbol(gGame.SelectedBodyKit.name)]
  UpdateCashFlow(-tCost)
  gGame.BodykitList[symbol(gGame.SelectedCar)][symbol(gGame.SelectedBodyKit.name)] = #Unlocked
  SetBodykits(0, gGame.SelectedBodyKit)
  gGame.scriptList[1].GetAndSetButtonList(0, 0, 1)
end

on SetUpgrades me, tUpgrade
  gGame.selectedUpgrade = tUpgrade
  tUpgrade = tUpgrade.name
  tState = gGame.UpgradesList[symbol(tUpgrade)]
  tUpgradeList = gData.data.upgrades[symbol(gGame.selectedCarTemplate[#upgrades])][symbol(tUpgrade)]
  tCurrent = tUpgradeList[1]
  tMax = tUpgradeList[2]
  if tCurrent < tMax then
    tCost = gData.data.CarUpgrades[symbol(tUpgrade)][#cost][tCurrent + 1]
    if gGame.Cash >= tCost then
      event("ShowBuyUpgradeDialog")
      tCost = FormatPrice(0, tCost)
      tText = gData.data.text.BuyThisUpgradeFor && tCost & " ?"
      CreateTextTexture(0, "Main", [#text: tText, #texture: "DialogText_Texture", #fontSize: 22, #lineSpacing: 22, #width: 256, #height: 64, #align: #center, #wrap: 1, #color: gData.data.TextColor.Black])
    else
      event("ShowNotEnoughMoneyDialog")
    end if
  else
    event("ShowMaxedOutDialog")
  end if
end

on BuySelectedUpgrade me
  event("HideDialog")
  tUpgrade = gGame.selectedUpgrade.name
  tState = gGame.UpgradesList[symbol(tUpgrade)]
  tUpgradeList = gData.data.upgrades[symbol(gGame.selectedCarTemplate[#upgrades])][symbol(tUpgrade)]
  tCurrent = tUpgradeList[1]
  tCost = gData.data.CarUpgrades[symbol(tUpgrade)][#cost][tCurrent + 1]
  UpdateCashFlow(-tCost)
  tUpgradeList = gData.data.upgrades[symbol(gGame.selectedCarTemplate[#upgrades])][symbol(gGame.selectedUpgrade.name)]
  tUpgradeList[1] = tUpgradeList[1] + 1
  UpdateStatistics()
  gGame.scriptList[1].GetAndSetButtonList(0, 0, 1)
  PlaySound("Equip_SFX")
end

on SetWeapons me, tWeapon
  gGame.selectedWeapon = tWeapon
  tList = gData.data.Weapons[symbol(gGame.selectedCarTemplate.Weapons)]
  SetItemDelimiter("_")
  tProp = tWeapon.name.item[1]
  tWeapon = tWeapon.name.item[2]
  ResetItemDelimiter()
  tState = gGame[symbol(tProp & "WeaponsList")][symbol(tWeapon)]
  if tState = #Unlocked then
    if tList[symbol(tProp)] = tWeapon then
      nothing()
    else
      if (tWeapon = "NoPrimary") or (tWeapon = "NoSecondary") then
        DeleteWeapon(0, tList[symbol(tProp)])
      else
        DeleteWeapon(0, tList[symbol(tProp)])
        BuildWeapon(0, tProp, tWeapon, gGame.SelectedCar)
      end if
    end if
    gGame.selectedWeapon = #none
    if (tWeapon = "NoPrimary") or (tWeapon = "NoSecondary") then
      tList[symbol(tProp)] = "None"
    else
      tList[symbol(tProp)] = tWeapon
    end if
    PlaySound("Equip_SFX")
  else
    if tState = #new then
      tCost = gData.data[symbol(string(tProp) & "Weapons")][symbol(tWeapon)].cost
      if gGame.Cash >= tCost then
        event("ShowBuyWeaponDialog")
        tText = FormatPrice(0, tCost)
        tText = gData.data.text.BuyThisWeaponFor & " " & tText & " ?"
        CreateTextTexture(0, "Main", [#text: tText, #texture: "DialogText_Texture", #fontSize: 22, #lineSpacing: 22, #width: 256, #height: 64, #align: #center, #wrap: 1, #color: gData.data.TextColor.Black])
      else
        event("ShowNotEnoughMoneyDialog")
      end if
    end if
  end if
end

on BuildWeapon me, tProp, tWeapon, tCar
  if tWeapon = "None" then
    return 0
  end if
  tDummies = gData.data[symbol(string(tProp) & "Weapons")][symbol(tWeapon)][#location]
  if tWeapon = "RocketPod" then
    tWeapon = ["RocketPodLeft", "RocketPodright"]
  end if
  tModelList = CloneModel(0, "Hangar", [#sourceMember: "Weapons", #model: tWeapon, #NameTag: tCar, #lod: 0])
  if tModelList.ilk <> #list then
    tModelList = [tModelList]
  end if
  repeat with j = 1 to tModelList.count
    tDummy = member(tCar).group(tCar & string(tProp) & "Weapon" & tDummies[j] & "_Dummy")
    tModelList[j].transform = member(tCar).model(tCar).getWorldTransform().inverse() * tDummy.transform
    tModelList[j].parent = member("Hangar").model(tCar)
    tModelList[j].userData.addProp(#parent, member("Hangar").model(tCar))
  end repeat
  if tWeapon = "MiniGun" then
    tModelList = CloneModel(0, "Hangar", [#sourceMember: "Weapons", #model: "MiniGunBarrel", #NameTag: tCar, #lod: 0])
    tModelList.transform = member("Weapons").model("MiniGun").getWorldTransform().inverse() * member("Weapons").model("MiniGunBarrel").transform
    tModelList.parent = member("Hangar").model(tCar & "MiniGun")
    tModelList.userData.addProp(#parent, member("Hangar").model(tCar & "MiniGun"))
  end if
  if tWeapon = "DualMiniGun" then
    tModelList = CloneModel(0, "Hangar", [#sourceMember: "Weapons", #model: ["DualMiniGunBarrel1", "DualMiniGunBarrel2"], #NameTag: tCar, #lod: 0])
    repeat with i = 1 to tModelList.count
      tModelList[i].transform = member("Weapons").model("DualMiniGun").getWorldTransform().inverse() * member("Weapons").model("DualMiniGunBarrel" & i).transform
      tModelList[i].parent = member("Hangar").model(tCar & "DualMiniGun")
      tModelList[i].userData.addProp(#parent, member("Hangar").model(tCar & "DualMiniGun"))
    end repeat
  end if
  tShader = member("Hangar").shader("Weapons_Material")
  tShader.emissive = rgb(190, 180, 170)
  tShader.diffuse = rgb(255, 255, 255)
  tShader.specular = rgb(200, 200, 200)
  tShader.shininess = 45.0
end

on DeleteWeapon me, tWeapon
  tmember = member("Hangar")
  if tWeapon = "RocketPod" then
    tWeapon = ["RocketPodLeft", "RocketPodright"]
  else
    tWeapon = [tWeapon]
  end if
  if tWeapon[1] = "MiniGun" then
    tWeapon.add("MiniGunBarrel")
  end if
  if tWeapon[1] = "DualMiniGun" then
    tWeapon.add("DualMiniGunBarrel1")
    tWeapon.add("DualMiniGunBarrel2")
  end if
  repeat with i in tWeapon
    tmember.deleteModel(gGame.SelectedCar & i)
  end repeat
end

on BuySelectedWeapon me
  event("HideDialog")
  SetItemDelimiter("_")
  tProp = gGame.selectedWeapon.name.item[1]
  tWeapon = gGame.selectedWeapon.name.item[2]
  ResetItemDelimiter()
  tCost = gData.data[symbol(string(tProp) & "Weapons")][symbol(tWeapon)].cost
  UpdateCashFlow(-tCost)
  gGame[symbol(tProp & "WeaponsList")][symbol(tWeapon)] = #Unlocked
  SetWeapons(0, gGame.selectedWeapon)
  gGame.scriptList[1].GetAndSetButtonList(0, 0, 1)
end
