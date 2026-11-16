global gSystem, gData, gGame

on LinkToTheRoot me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  tRootList = []
  tCount = tmember.model.count
  repeat with i = 1 to tCount
    tmodel = tmember.model(i)
    if tmodel.name contains "_Root" then
      tRootList.add(tmodel)
    end if
  end repeat
  if tRootList.count > 0 then
    SetItemDelimiter("_")
    repeat with i in tRootList
      tTag = i.name.item[1]
      repeat with j = 1 to tCount
        tmodel = tmember.model(j)
        if tmodel.name contains tTag then
          tmodel.parent = i
        end if
      end repeat
      i.parent = VOID
    end repeat
    ResetItemDelimiter()
    return 1
  else
    return 0
  end if
end

on DeleteTheModels me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  tCount = tmember.model.count
  tList = []
  repeat with i = 1 to tCount
    tName = tmember.model[i].name
    if tName contains "TrackRoot" then
      next repeat
    end if
    if tName contains "DecoRoot" then
      next repeat
    end if
    tList.add(tName)
  end repeat
  repeat with i in tList
    tmember.deleteModel(i)
  end repeat
end

on CreateTile me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tType = VOID
  if tDataList[#type].ilk = #string then
    tType = tDataList.type
  end if
  tDirection = EMPTY
  if tDataList[#direction].ilk = #string then
    tDirection = tDataList.direction
  end if
  tAIPath = EMPTY
  if tDataList[#aipath].ilk = #list then
    if tDataList.aipath[1].ilk = #string then
      tAIPath = tDataList.aipath[1]
    end if
  end if
  if tAIPath = EMPTY then
    tAIPath = tType
  end if
  tPosition = vector()
  if tDataList[#position].ilk = #vector then
    tPosition = tDataList.position
  end if
  tDeco = 0
  if tDataList[#deco].ilk = #integer then
    tDeco = tDataList.deco
  end if
  tParentRoot = 0
  if tDataList[#parent].ilk = #integer then
    tParentRoot = tDataList.parent
  end if
  if tDeco = 0 then
    tTag = "Track"
  else
    tTag = "Deco"
  end if
  tRoot = tmember.model(tType & "_Root")
  if tRoot = VOID then
    return 0
  end if
  if voidp(gGame[#RootList]) = 1 then
    gGame[#RootList] = []
  end if
  if voidp(gGame[#DecoList]) = 1 then
    gGame[#DecoList] = []
  end if
  if tDeco = 0 then
    tCount = gGame.RootList.count + 1
  else
    tCount = gGame.DecoList.count + 1
  end if
  tGroupRootName = tTag & "Root" & tCount
  tGroupRoot = tmember.newGroup(tGroupRootName & "_Group")
  tNewModelList = []
  tChildCount = tRoot.child.count
  repeat with i = 1 to tChildCount
    tmodel = tRoot.child[i]
    tNewModel = tmember.newModel(tTag & "Root" & tCount & "_" & tmodel.name, tmodel.resource)
    tNewModel.transform = tmodel.transform
    tNewModel.shaderList = tmodel.shaderList
    tNewModel.parent = tGroupRoot
    if voidp(gGame[#Lightmaps]) = 0 then
      if gGame.Lightmaps = 1 then
        tNewModel.addModifier(#meshDeform)
        tShaderList = []
        repeat with j = 1 to tmodel.shaderList.count
          if (tNewModel.meshDeform.mesh.textureLayer.count > 1) and (tNewModel.name contains "Street") then
            tShader = DuplicateShader(0, tmember.name, [#shader: tmodel.shaderList[j].name, #shaderTag: tGroupRootName])
            tLightMap = tType & "StreetLightmap_Texture"
            if tmember.texture(tLightMap) = VOID then
              createTexture(tmember.name, [#fileName: tLightMap, #renderFormat: #rgba5650, #filtering: #lowFiltered])
            end if
            ASSIGNTEXTURE(tmember.name, [#material: tShader.name, #lightmap: tLightMap])
            tShaderList.add(tShader)
          else
            tShader = tmodel.shaderList[j]
          end if
          tShaderList.add(tShader)
        end repeat
        tNewModel.shaderList = tShaderList
        if (tNewModel.meshDeform.mesh.textureLayer.count > 1) and (tNewModel.name contains "Street") then
          tUD = tNewModel.userData
          tFaceList = []
          repeat with k = 1 to tNewModel.meshDeform.mesh[1].face.count
            tFaceList.add(tNewModel.meshDeform.mesh[1].face[k])
          end repeat
          tNewModel.userData.addProp(#FaceList2, tFaceList)
          tNewModel.userData.addProp(#CoordList2, tNewModel.meshDeform.mesh[1].face.textureLayer[2].textureCoordinateList)
        end if
        tNewModel.removeModifier(#meshDeform)
      end if
    end if
    tNewModelList.add(tNewModel)
  end repeat
  if tDeco <> 0 then
    tGroupRoot.transform.position = tPosition
    tParent = gGame.RootList[tParentRoot]
    tOffset = tGroupRoot.worldPosition - tParent.worldPosition
    tGroupRoot.transform.position = tParent.worldPosition
    tGroupRoot.parent = tParent
    tGroupRoot.transform.position = tOffset
  else
    tGroupRoot.transform.position = tPosition
  end if
  if tDeco = 0 then
    gGame.RootList.add(tGroupRoot)
  else
    gGame.DecoList.add(tGroupRoot)
  end if
  if tDeco = 0 then
    repeat with i in tNewModelList
      if i.name contains "Street" then
        SetAttribute(tmember.name, [#ModelName: i.name, #attribute: #floor])
      end if
      if i.shader.name = "Waves_Material" then
        nothing()
        next repeat
      end if
      if not (i.name contains "Transparent") then
        AddObstacle(0, tmember.name, [#model: i.name, #type: #static, #bodyProxy: #concaveShape])
      end if
      if i.name contains "NonTransparent" then
        AddObstacle(0, tmember.name, [#model: i.name, #type: #static, #bodyProxy: #concaveShape])
      end if
    end repeat
    if getaProp(gGame, #WayPointList) = VOID then
      gGame[#WayPointList] = [:]
    end if
    tResult = BuildTileAIPath(0, tGroupRoot, tAIPath, tDirection)
    tPointList = tResult[1]
    tReverse = tResult[2]
    if tPointList.count = 0 then
      tPointList.add(tGroupRoot.transform.duplicate())
    end if
    gGame.WayPointList[symbol(tGroupRoot.name)] = tPointList
    if voidp(gGame[#InvWalls]) = 0 then
      if gGame.InvWalls = 1 then
        if tmember.modelResource("InvisibleWallStraight") = VOID then
          CloneModel(0, tmember.name, [#sourceMember: "InvisibleWall", #hide: 1, #lod: 0, #delete: 1])
        end if
        if (tDirection = "SouthNorth") or (tDirection = "NorthSouth") or (tDirection = "EastWest") or (tDirection = "WestEast") then
          tInvWall = tmember.newModel(tTag & "Root" & tCount & "_InvisibleWallStraight", tmember.modelResource("InvisibleWallStraight"))
          tInvWall.shaderList = tmember.shader("InvisibleWall_Material")
          if (tDirection = "EastWest") or (tDirection = "WestEast") then
            tInvWall.rotate(0, 0, 90, #self)
          end if
          tInvWall.parent = tGroupRoot
          tInvWall.transform.position = vector()
          AddObstacle(0, tmember.name, [#model: tInvWall.name, #type: #static, #bodyProxy: #concaveShape])
        else
          tInvWall = tmember.newModel(tTag & "Root" & tCount & "_InvisibleWallCorner", tmember.modelResource("InvisibleWallCorner"))
          tInvWall.shaderList = tmember.shader("InvisibleWall_Material")
          if (tDirection = "SouthEast") or (tDirection = "EastSouth") then
            tInvWall.rotate(0, 0, 90, #self)
          end if
          if (tDirection = "NorthWest") or (tDirection = "WestNorth") then
            tInvWall.rotate(0, 0, -90, #self)
          end if
          if (tDirection = "NorthEast") or (tDirection = "EastNorth") then
            tInvWall.rotate(0, 0, 180, #self)
          end if
          tInvWall.parent = tGroupRoot
          tInvWall.transform.position = vector()
          AddObstacle(0, tmember.name, [#model: tInvWall.name, #type: #static, #bodyProxy: #concaveShape])
        end if
        if tCount = 1 then
          tInvWall = tmember.newModel(tTag & "Root" & tCount & "_InvisibleWall", tmember.modelResource("InvisibleWallSpecial"))
          tInvWall.shaderList = tmember.shader("InvisibleWall_Material")
          tInvWall.transform = tPointList[1].duplicate()
          tInvWall.rotate(0, 0, 180, #self)
          tInvWall.transform = tGroupRoot.getWorldTransform().inverse() * tInvWall.transform
          tInvWall.parent = tGroupRoot
          AddObstacle(0, tmember.name, [#model: tInvWall.name, #type: #static, #bodyProxy: #concaveShape])
        end if
      end if
    end if
    tGroupRoot.userData.addProp(#Obstacles, [])
    tGroupRoot.userData.addProp(#Pickups, [])
    tGroupRoot.userData.addProp(#traffic, [])
    if voidp(gGame[#Obstacles]) = 1 then
      tObstacles = 0
    else
      tObstacles = gGame.Obstacles
    end if
    if voidp(gGame[#Pickups]) = 1 then
      tPickups = 0
    else
      tPickups = gGame.Pickups
    end if
    if voidp(gGame[#traffic]) = 1 then
      tTraffic = 0
    else
      tTraffic = gGame.traffic
    end if
    repeat with i = 1 to tDataList.count
      tDataProp = tDataList.getPropAt(i)
      if (tDataProp = #type) or (tDataProp = #aipath) or (tDataProp = #direction) or (tDataProp = #position) then
        next repeat
        next repeat
      end if
      if (string(tDataProp) contains "object") and (tObstacles = 1) then
        BuildTileObjects(0, tGroupRootName, tDataProp, tDataList[tDataProp], tGroupRoot)
        next repeat
      end if
      if (string(tDataProp) contains "pickup") and (tPickups = 1) then
        BuildTilePickups(0, tGroupRootName, tDataProp, tDataList[tDataProp], tGroupRoot)
        next repeat
      end if
      if tTraffic = 1 then
        BuildTraffic(0, tGroupRootName, tDataProp, tDataList[tDataProp], tGroupRoot)
      end if
    end repeat
  end if
  if voidp(gGame[#checkpointList]) = 1 then
    gGame[#checkpointList] = [:]
  end if
  repeat with j = gData.Events[gSystem.event].count down to 1
    tLine = gData.Events[gSystem.event][j]
    tLineData = value(tLine[2])
    if voidp(tLineData[#deco]) = 0 then
      next repeat
      next repeat
    end if
    exit repeat
  end repeat
  if tLineData = tDataList then
    if voidp(tLineData[#Checkpoint]) = 1 then
      tCheckPoint = tPointList[tPointList.count / 2.0].duplicate()
      gGame.checkpointList[symbol(tGroupRoot.name)] = [tCheckPoint]
    end if
    if voidp(gGame[#InvWalls]) = 0 then
      if gGame.InvWalls = 1 then
        tInvWall = tmember.newModel(tTag & "Root" & tCount & "_InvisibleWall", tmember.modelResource("InvisibleWallSpecial"))
        tInvWall.shaderList = tmember.shader("InvisibleWall_Material")
        tInvWall.transform = tPointList[tPointList.count].duplicate()
        tInvWall.transform = tGroupRoot.getWorldTransform().inverse() * tInvWall.transform
        tInvWall.parent = tGroupRoot
        AddObstacle(0, tmember.name, [#model: tInvWall.name, #type: #static, #bodyProxy: #concaveShape])
      end if
    end if
    createTexture("Finish", [#fileName: "Finish_Texture", #filtering: #lowFiltered])
    tFinish = CloneModel(0, tmember.name, [#sourceMember: "Finish", #model: "Finish", #NameTag: tGroupRootName & "_", #lod: 0])
    tFinish.transform = tCheckPoint.duplicate()
    tFinish.transform = tGroupRoot.getWorldTransform().inverse() * tFinish.transform
    tFinish.parent = tGroupRoot
  end if
  tGroupRoot.removeFromWorld()
end

on BuildTileAIPath me, tGroupRoot, tAIPath, tDirection
  tDataList = gData.data[symbol(gGame.world & "AIPaths")]
  tWayPointList = []
  tReverse = 0
  tProp = symbol(tAIPath & "_" & tDirection)
  if voidp(tDataList[tProp]) = 0 then
    tTileList = tDataList[tProp].duplicate()
  else
    tSwitchList = [#SouthNorth: "NorthSouth", #NorthSouth: "SouthNorth", #WestEast: "EastWest", #EastWest: "WestEast", #SouthWest: "WestSouth", #WestSouth: "SouthWest", #SouthEast: "EastSouth", #EastSouth: "SouthEast", #WestNorth: "NorthWest", #NorthWest: "WestNorth", #EastNorth: "NorthEast", #NorthEast: "EastNorth"]
    tProp = symbol(tAIPath & "_" & tSwitchList[tDirection])
    tReverse = 1
    if voidp(tDataList[tProp]) = 0 then
      tTileList = tDataList[tProp].duplicate()
    else
      put "Couldn't find a waypointlist for last build tile. GroupRoot was: " & string(tGroupRoot) && "Type was: " & string(tAIPath)
      put string(tReverse && tProp)
      return [tWayPointList, tReverse]
      exit
    end if
    put string(tReverse && tProp)
  end if
  tgroup = gGame.member.newGroup("WaypointHelper")
  tgroup.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  tRootTransform = tGroupRoot.getWorldTransform()
  t1 = 1
  t2 = tTileList.count
  if tReverse = 0 then
    repeat with j = t1 to t2
      tWayPointPos = tRootTransform.position + tTileList[j]
      if j < tTileList.count then
        tFutWayPointPos = tRootTransform.position + tTileList[j + 1]
        tgroup.transform.position = tWayPointPos
        tgroup.pointAt(tFutWayPointPos, vector(0, 0, 1))
        tEntry = tgroup.transform.duplicate()
      else
        tgroup.transform.position = tWayPointPos
        tEntry = tgroup.transform.duplicate()
      end if
      tWayPointList.append(tEntry)
    end repeat
  else
    repeat with j = t2 down to t1
      tWayPointPos = tRootTransform.position + tTileList[j]
      if j < tTileList.count then
        tFutWayPointPos = tRootTransform.position + tTileList[j + 1]
        tgroup.transform.position = tWayPointPos
        tgroup.pointAt(tFutWayPointPos, vector(0, 0, 1))
        tgroup.rotate(0, 0, 180, #self)
        tEntry = tgroup.transform.duplicate()
      else
        tgroup.transform.position = tWayPointPos
        tgroup.rotate(0, 0, 180, #self)
        tEntry = tgroup.transform.duplicate()
      end if
      tWayPointList.append(tEntry)
    end repeat
  end if
  if voidp(gGame[#WPHelpers]) = 0 then
    if gGame.WPHelpers = 1 then
      tResource = gGame.member.modelResource("WPHelper")
      if tResource = VOID then
        tResource = gGame.member.newModelResource("WPHelper", #box)
      end if
      tResource.width = 10.0
      tResource.height = 1.0
      tResource.length = 1.0
      if gGame.member.shader("Proxy_Material") = VOID then
        CreateProxyShader(gGame.member)
      end if
      repeat with j = 1 to tWayPointList.count
        tmodel = gGame.member.newModel(tGroupRoot.name & "WPHelper" & j, tResource)
        tmodel.shaderList = gGame.member.shader("Proxy_Material")
        tmodel.transform = tWayPointList[j].duplicate()
      end repeat
    end if
  end if
  gGame.member.deleteGroup("WaypointHelper")
  return [tWayPointList, tReverse]
end

on BuildTileObjects me, tGroupRootName, tObject, tPositionList, tGroupRoot
  if gGame.member.model(string(tObject)) = VOID then
    CloneModel(0, gGame.member.name, [#sourceMember: "Objects", #model: string(tObject), #lod: 0, #delete: 1])
  end if
  tResource = gGame.member.modelResource(string(tObject))
  repeat with i = 1 to tPositionList.count
    tNewModel = gGame.member.newModel(tGroupRootName & "_" & string(tObject) & i, tResource)
    tShaderName = member("Objects").model(string(tObject)).shader.name
    tShader = gGame.member.shader(tShaderName)
    if tShader = VOID then
      tShader = DuplicateShader(0, gGame.member, [#shader: tShaderName, #sourceMember: "Objects"])
    end if
    tNewModel.shaderList = tShader
    tNewModel.parent = tGroupRoot
    tNewModel.worldPosition = tPositionList[i][1]
    q = tPositionList[i][2]
    tAngle = 2 * atan(sqrt(1.0 - (q[4] * q[4])), q[4]) * 180 / PI
    t = sqrt(1 - (q[4] * q[4]))
    if t = 0 then
      tVector = vector(0, 1, 0)
    else
      x = q[1] / sqrt(1 - (q[4] * q[4]))
      y = q[2] / sqrt(1 - (q[4] * q[4]))
      z = q[3] / sqrt(1 - (q[4] * q[4]))
      tVector = vector(x, z, y)
    end if
    tAxisAngle = [tVector, tAngle]
    tNewModel.transform.axisAngle = tAxisAngle
    tNewModel.addModifier(#meshDeform)
    tPhysicsData = gData.data.PhysicsObjects[#Default_Object]
    if voidp(gData.data.PhysicsObjects[tObject]) = 0 then
      tPhysicsData = gData.data.PhysicsObjects[tObject]
    end if
    if tPhysicsData.weight = #static then
      tRB = AddObstacle(0, gGame.member.name, [#model: tNewModel.name, #type: #static, #bodyProxy: #concaveShape, #restitution: 0.10000000000000001, #friction: 0.10000000000000001])
    else
      tRB = AddObstacle(0, gGame.member.name, [#model: tNewModel.name, #type: #dynamic, #bodyProxy: #convexShape, #restitution: 0.90000000000000002, #friction: 0.90000000000000002, #mass: tPhysicsData.weight])
    end if
    tType = #none
    if tPhysicsData[#type].ilk = #symbol then
      tType = tPhysicsData.type
    end if
    tHealth = #infinite
    if (tPhysicsData[#Health].ilk = #float) or (tPhysicsData[#Health].ilk = #integer) then
      tHealth = tPhysicsData.Health
    end if
    tScore = 0
    if (tPhysicsData[#score].ilk = #float) or (tPhysicsData[#score].ilk = #integer) then
      tScore = tPhysicsData.score
    end if
    tNewModel.userData.addProp(#model, string(tObject))
    tNewModel.userData.addProp(#type, tType)
    tNewModel.userData.addProp(#Health, tHealth)
    tNewModel.userData.addProp(#score, tScore)
    tNewModel.userData.addProp(#mass, tPhysicsData.weight)
    tNewModel.userData.addProp(#parent, tGroupRoot)
    tNewModel.removeModifier(#meshDeform)
    if voidp(gGame[#destructiveList]) = 1 then
      gGame[#destructiveList] = []
    end if
    if tHealth <> #infinite then
      tNewModel.userData.addProp(#effect, tPhysicsData.effect)
      tNewModel.userData.addProp(#areaDamage, [5, 15, 16])
      gGame.destructiveList.add(tNewModel)
    end if
    tGroupRoot.userData.Obstacles.add(tRB)
  end repeat
end

on BuildTilePickups me, tGroupRootName, tPickup, tPositionList, tGroupRoot
  if tPickup = #HiddenPackage_PickUp then
    tTrack = symbol(gGame.world & "Track" & gGame.track)
    if gGame.HiddenPackageList.getPos(tTrack) <> 0 then
      exit
    end if
  end if
  if gGame.member.model(string(tPickup)) = VOID then
    CloneModel(0, gGame.member.name, [#sourceMember: "Pickups", #model: string(tPickup), #lod: 0, #delete: 1])
  end if
  tResource = gGame.member.modelResource(string(tPickup))
  repeat with i = 1 to tPositionList.count
    tNewModel = gGame.member.newModel(tGroupRootName & "_" & string(tPickup) & i, tResource)
    tNewModel.pointAtOrientation = [vector(0, -1, 0), vector(0, 0, 1)]
    tShaderName = member("Pickups").model(string(tPickup)).shader.name
    tShader = gGame.member.shader(tShaderName)
    if tShader = VOID then
      tShader = DuplicateShader(0, gGame.member, [#shader: tShaderName, #sourceMember: "Objects"])
    end if
    tNewModel.shaderList = tShader
    tNewModel.parent = tGroupRoot
    tNewModel.worldPosition = tPositionList[i][1]
    tGroupRoot.userData.Pickups.add(tNewModel)
  end repeat
end

on BuildTraffic me, tGroupRootName, tType, tPositionList, tGroupRoot
  tData = gData.data.traffic[symbol(tType)]
  if tData = VOID then
    return 0
  end if
  tModelName = tData.model
  repeat with i = 1 to tPositionList.count
    if gGame.member.model(tModelName) = VOID then
      CloneModel(0, gGame.member.name, [#sourceMember: tModelName, #model: tModelName, #lod: 0, #delete: 1])
    end if
    tNewModel = gGame.member.newModel(tGroupRootName & "_" & string(tType) & i, gGame.member.modelResource(tModelName))
    tShaderName = member(tModelName).model(tModelName).shader.name
    tShader = DuplicateShader(0, gGame.member.name, [#shader: tShaderName, #shaderTag: tGroupRootName & "_" & string(tType) & i])
    tNewModel.shaderList = tShader
    tTextureName = tModelName & "Skin" & tData.skin & "_Texture"
    tTexture = gGame.member.texture(tTextureName)
    if tTexture = VOID then
      tTexture = createTexture(gGame.member.name, [#fileName: tTextureName])
    end if
    tShader.texture = tTexture
    tNewModel.worldPosition = tPositionList[i][1]
    q = tPositionList[i][2]
    tAngle = 2 * atan(sqrt(1.0 - (q[4] * q[4])), q[4]) * 180 / PI
    t = sqrt(1 - (q[4] * q[4]))
    if t = 0 then
      tVector = vector(0, 1, 0)
    else
      x = q[1] / sqrt(1 - (q[4] * q[4]))
      y = q[2] / sqrt(1 - (q[4] * q[4]))
      z = q[3] / sqrt(1 - (q[4] * q[4]))
      tVector = vector(x, z, y)
    end if
    tAxisAngle = [tVector, tAngle]
    tNewModel.transform.axisAngle = tAxisAngle
    tRB = AddObstacle(0, gGame.member.name, [#model: tNewModel.name, #type: #dynamic, #bodyProxy: #box, #restitution: 0.34999999999999998, #friction: 0.80000000000000004, #mass: tData.weight])
    tNewModel.userData.addProp(#traffic, 1)
    tNewModel.userData.addProp(#model, tData.model)
    tNewModel.userData.addProp(#score, tData.score)
    tNewModel.userData.addProp(#Health, tData.Health)
    tNewModel.userData.addProp(#type, #metal)
    tNewModel.userData.addProp(#effect, tData.effect)
    tNewModel.userData.addProp(#areaDamage, [10, 25, 16])
    tNewModel.userData.addProp(#mass, tData.weight)
    tNewModel.userData.addProp(#parent, tGroupRoot)
    if voidp(gGame[#destructiveList]) = 1 then
      gGame[#destructiveList] = []
    end if
    gGame.destructiveList.add(tNewModel)
    tGroupRoot.userData.Obstacles.add(tRB)
    tGroupRoot.userData.traffic.add(tNewModel)
  end repeat
end
