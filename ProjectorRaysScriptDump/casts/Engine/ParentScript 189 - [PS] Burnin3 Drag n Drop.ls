property p
global gData, gGame

on new me, tParams
  p = [:]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = member(tParams[#memberName])
  p[#Cameras] = [p.member.camera("DefaultView")]
  if tParams[#camera].ilk = #string then
    p.Cameras = [p.member.camera(tParams[#camera])]
  else
    if tParams[#camera].ilk = #list then
      p.Cameras = []
      repeat with i = 1 to tParams[#camera].count
        tCamera = p.member.camera(tParams[#camera][i])
        if tCamera <> VOID then
          p.Cameras.add(tCamera)
        end if
      end repeat
    end if
  end if
  if p.Cameras.count = 0 then
    p.Cameras = [p.member.camera("DefaultView")]
  end if
  p[#button] = VOID
  p[#PreviousButton] = VOID
  p[#mouseDown] = 0
  p[#rightMouseDown] = 0
  p[#sound] = 1
  p[#ButtonList] = []
  me.GetAndSetButtonList(1)
  gGame[#DragNDrop] = me
  p[#info] = p.member.model("IconInfo")
  p[#interpolate] = 0
  return me
end

on GetAndSetButtonList me, tNewShader, tIgnore
  p.ButtonList = []
  tParents = [p.member.model("UpgradesTab"), p.member.model("BodyKitsTab"), p.member.model("WeaponsTab")]
  repeat with i in tParents
    tCount = i.child.count
    repeat with j = 1 to tCount
      tButton = i.child[j]
      if tButton.name = "WeaponsHeaderBar" then
        next repeat
      end if
      if tButton.name = "BodyKitHeaderBar" then
        next repeat
      end if
      if tButton.name = "UpgradesHeaderBar" then
        next repeat
      end if
      tUD = tButton.userData
      if tIgnore <> 1 then
        tUD[#transform] = tButton.getWorldTransform().duplicate()
        tUD[#menu] = 0
        tUD[#parent] = i
      end if
      case i.name of
        "UpgradesTab":
          tUD[#tab] = "Upgrades"
        "BodyKitsTab":
          tUD[#tab] = "Bodykits"
        "WeaponsTab":
          tUD[#tab] = "Weapons"
      end case
      if tUD.tab = "Upgrades" then
        if voidp(gGame.UpgradesList[symbol(tButton.name)]) = 1 then
          tState = #locked
        else
          tState = gGame.UpgradesList[symbol(tButton.name)]
        end if
        tUD[#state] = tState
        tUD[#name] = convertToUpperCase(0, gData.data.CarUpgrades[symbol(tButton.name)].name)
        tUpgradeList = gData.data.upgrades[symbol("Player" & gGame.SelectedCar)][symbol(tButton.name)]
        tSet = tUpgradeList[1] + 1
        tMax = tUpgradeList[2]
        if tState <> #locked then
          if tSet <= tMax then
            tUD[#cost] = gData.data.CarUpgrades[symbol(tButton.name)].cost[tSet]
          else
            tUD[#cost] = "MAXED OUT!"
          end if
        else
          tUD[#cost] = "Locked"
        end if
        tUD[#View] = "_NormalView"
      end if
      if tUD.tab = "Bodykits" then
        tName = "MODIFIED"
        if voidp(gData.data.CarBodyKits[#Unlocked][symbol(tButton.name)]) = 0 then
          tState = #Unlocked
          tName = "DEFAULT"
        else
          if voidp(gGame.BodykitList[symbol(gGame.SelectedCar)]) = 0 then
            if voidp(gGame.BodykitList[symbol(gGame.SelectedCar)][symbol(tButton.name)]) = 0 then
              tState = gGame.BodykitList[symbol(gGame.SelectedCar)][symbol(tButton.name)]
            else
              tState = #locked
            end if
          else
            tState = #locked
          end if
        end if
        tUD[#state] = tState
        tUD[#name] = tName
        if tState = #locked then
          tUD[#cost] = "Locked"
        else
          if tState = #new then
            tUD[#cost] = gData.data.CarBodyKits[symbol(gGame.SelectedCar)][symbol(tButton.name)]
          else
            tUD[#cost] = 0
          end if
        end if
        tUD[#View] = "_NormalView"
        if (tButton.name contains "Rear") or (tButton.name contains "Spoiler") then
          tUD[#View] = "_BackView"
        else
          if tButton.name contains "Rims" then
            tUD[#View] = "_RimsView"
          else
            if tButton.name contains "Front" then
              tUD[#View] = "_FrontView"
            else
              tUD[#View] = "_NormalView"
            end if
          end if
        end if
      end if
      if tUD.tab = "Weapons" then
        SetItemDelimiter("_")
        tProp = tButton.name.item[1]
        tWeapon = tButton.name.item[2]
        if voidp(gGame[symbol(tProp & "WeaponsList")][symbol(tWeapon)]) = 1 then
          tState = #locked
        else
          tState = gGame[symbol(tProp & "WeaponsList")][symbol(tWeapon)]
        end if
        tUD[#state] = tState
        tUD[#name] = convertToUpperCase(0, gData.data[symbol(tProp & "Weapons")][symbol(tWeapon)].name)
        if tState = #new then
          tUD[#cost] = gData.data[symbol(tProp & "Weapons")][symbol(tWeapon)].cost
        else
          if tState = #Unlocked then
            tUD[#cost] = 0
          else
            tUD[#cost] = "Locked"
          end if
        end if
        if tWeapon contains "Deployer" then
          tUD[#View] = "_BackView"
        else
          if tWeapon contains "Launcher" then
            tUD[#View] = "_RoofView"
          else
            tUD[#View] = "_WeaponView"
          end if
        end if
        if (tWeapon = "RocketPod") or (tWeapon = "NoPrimary") or (tWeapon = "NoSecondary") then
          tUD[#View] = "_NormalView"
        end if
      end if
      if (tNewShader = 1) and (p.member.shader(tButton.name & "Icons_Material") = VOID) then
        tButton.shader = DuplicateShader(0, p.member.name, [#shader: "Icons_Material", #shaderTag: tButton.name])
      end if
      p.ButtonList.add(tButton)
    end repeat
  end repeat
  repeat with i in p.ButtonList
    tShader = i.shader
    if i.userData.state = #locked then
      SetShader(0, p.member.name, [#shader: i.shader.name, #emissive: rgb(0, 0, 0), #diffuse: rgb(0, 0, 0), #useDiffuseWithTexture: 1])
      next repeat
    end if
    SetShader(0, p.member.name, [#shader: i.shader.name, #emissive: rgb(255, 255, 255), #diffuse: rgb(255, 255, 255), #useDiffuseWithTexture: 0])
  end repeat
end

on enterFrame me
  if p.mouseDown = 0 then
    tOptionList = [#maxNumberOfModels: 3, #levelOfDetail: #detailed, #modelList: p.ButtonList]
    tPoint = _mouse.mouseLoc
    tList = []
    repeat with i = 1 to p.Cameras.count
      tModelList = p.Cameras[i].modelsUnderLoc(_mouse.mouseLoc, tOptionList)
      if tModelList.count > 0 then
        repeat with j = 1 to tModelList.count
          tmodel = tModelList[j].model
          if tmodel.isInWorld() and (tmodel.userData.menu = gGame.menu.menu) then
            tMouseLoc = p.Cameras[1].spriteSpaceToWorldSpace(_mouse.mouseLoc)
            tPos = tmodel.worldPosition.duplicate()
            tPos.y = tMouseLoc.y
            tDistance = tMouseLoc.distanceTo(tPos)
            if tDistance <= 30.0 then
              tList.add([tDistance, tmodel])
            end if
          end if
        end repeat
      end if
    end repeat
    tList.sort()
    if tList.count = 0 then
      p.button = VOID
    else
      p.button = tList[1][2]
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
  tPos = p.button.worldPosition + vector(0, -15, 0)
  p.button.parent = p.member.group("World")
  p.button.transform.position = tPos
  p.button.transform.rotation = vector(90, 0, 0)
  p.button.transform.scale = p.button.transform.scale * 1.5
  p.info.transform.position = p.button.transform.position + vector(0, -300, -30)
  CreateTextTexture(0, "Main", [#text: p.button.userData.name, #texture: "IconInfoName_Texture", #fontSize: 15, #width: 256, #resize: 1, #align: #left, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3GlowBlack], #nearFiltering: 1])
  if p.button.userData.cost = 0 then
    tCost = EMPTY
  else
    if p.button.userData.cost.ilk <> #integer then
      tCost = convertToUpperCase(0, p.button.userData.cost)
    else
      tCost = FormatPrice(0, p.button.userData.cost)
    end if
  end if
  CreateTextTexture(0, "Main", [#text: tCost, #texture: "IconInfoCost_Texture", #fontSize: 15, #width: 128, #align: #left, #resize: 1, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3GlowBlack], #nearFiltering: 1])
  p.PreviousButton = p.button
end

on ButtonLeave me, tButton
  _player.cursor(-1)
  if tButton = VOID then
    exit
  end if
  tButton.transform.scale = tButton.userData.transform.scale
  tButton.transform.position = tButton.userData.transform.position
  tButton.transform = tButton.userData.parent.transform.inverse() * tButton.transform.duplicate()
  tButton.parent = tButton.userData.parent
  p.info.transform.position = vector(-300, 0, -1000)
  p.sound = 1
  p.PreviousButton = VOID
end

on ButtonDown me
  if p.button.userData.state = #locked then
    if p.sound = 1 then
      PlaySound("CannotSelect_SFX")
      p.sound = 0
    end if
    return 0
  end if
  gGame.menu.menu = 2
  if p.interpolate = 0 then
    AddToInterPolator(0, "Hangar", [#object: "DefaultView", #target: p.button.userData.View, #Percentage: 15])
    p.interpolate = 1
  end if
  _player.cursor(290)
  if p.sound = 1 then
    PlaySound("PreEquip_SFX")
    p.sound = 0
  end if
  p.button.transform.position = p.Cameras[1].spriteSpaceToWorldSpace(_mouse.mouseLoc) + vector(0, -550, 0)
  p.info.transform.position = p.button.worldPosition + vector(0, -10, -30)
  p.mouseDown = 1
end

on ButtonUp me
  tmodel = member("Hangar").camera("Hangar_Camera").modelUnderLoc(_mouse.mouseLoc)
  if (tmodel <> VOID) and tmodel.isInWorld() and (tmodel.name contains gGame.SelectedCar) then
    if tmodel.name contains "Shadow" then
      nothing()
    else
      sendSprite(0, symbol("Set" & p.button.userData.tab), p.button)
    end if
  end if
  p.button.parent = p.button.userData.parent
  p.button.transform = p.button.userData.transform.duplicate()
  p.info.transform.position = vector(-300, 0, -1000)
  p.mouseDown = 0
  p.interpolate = 0
  me.GetAndSetButtonList(0, 1)
  if gGame.menu.menu = 2 then
    gGame.menu.menu = 0
  end if
end

on GetAlphaPixel iSectList
  tmodel = iSectList.model
  tmember = tmodel.shader.textureList[1].member
  tImage = tmember.image
  tmodel.addModifier(#meshDeform)
  tFace = iSectList.faceID
  tUVCoord = iSectList.uvCoord
  tCoordList = tmodel.meshDeform.mesh[iSectList.meshID].textureCoordinateList
  tFaceList = tmodel.meshDeform.mesh[iSectList.meshID].face[tFace]
  tmodel.removeModifier(#meshDeform)
  tLocA = tCoordList[tFaceList[1]]
  tLocA = point(tLocA[1] * tImage.width, (1 - tLocA[2]) * tImage.height)
  tLocB = tCoordList[tFaceList[2]]
  tLocB = point(tLocB[1] * tImage.width, (1 - tLocB[2]) * tImage.height)
  tLocC = tCoordList[tFaceList[3]]
  tLocC = point(tLocC[1] * tImage.width, (1 - tLocC[2]) * tImage.height)
  tUVector = (tLocB - tLocA) * tUVCoord.u
  tVVector = (tLocC - tLocA) * tUVCoord.V
  tPos = tLocA + tUVector + tVVector
  tAlpha = tImage.extractAlpha().getPixel(tPos)
  return tAlpha
end

on delete me
end
