global gSystem, gData, gGame

on collisionCallback collisionReport
  repeat with i in collisionReport
    if voidp(gGame.collisionReports[symbol(i.ObjectA.name)]) = 0 then
      gGame.collisionReports[symbol(i.ObjectA.name)] = [i.ObjectB.name, i.contactPoints[1][1], i.contactNormals[1]]
    end if
    if voidp(gGame.collisionReports[symbol(i.ObjectB.name)]) = 0 then
      gGame.collisionReports[symbol(i.ObjectB.name)] = [i.ObjectA.name, i.contactPoints[1][1], i.contactNormals[1]]
    end if
  end repeat
end

on AddObstacle me, tTarget, tDataList
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
  if voidp(gGame[#Physics]) = 1 then
    tScript = new(script("[PS] Physics"), [#member: tmember])
    gGame.scriptList.add(tScript)
  end if
  if gGame.Physics = VOID then
    return 0
  end if
  tTargetList = []
  if tDataList[#model].ilk = #void then
    tDataList[#model] = "*.*"
  end if
  if tDataList[#model].ilk = #list then
    tTargetList = tDataList.model
  else
    if tDataList[#model].ilk = #string then
      if tDataList.model.char[1] = "*" then
        tString = tDataList.model
        if tString <> "*.*" then
          delete tString.char[1]
        end if
        tTargetList = GetObjectList(0, tmember.name, [#type: #model, #string: tString])
      else
        tTargetList.add(tDataList.model)
      end if
    end if
  end if
  if tTargetList.count = 0 then
    return []
  end if
  if voidp(gGame[#StaticRBList]) = 1 then
    gGame[#StaticRBList] = []
  end if
  if voidp(gGame[#DynamicRBList]) = 1 then
    gGame[#DynamicRBList] = []
  end if
  if tDataList[#type].ilk = #symbol then
    if [#static, #dynamic].getPos(tDataList.type) <> 0 then
      tType = tDataList.type
    else
      tType = #static
    end if
  else
    tType = #static
  end if
  if tDataList[#pinned].ilk = #integer then
    tPinned = tDataList.pinned
  else
    tPinned = 0
  end if
  if (tDataList[#restitution].ilk = #integer) or (tDataList[#restitution].ilk = #float) then
    tRestitution = tDataList.restitution
  else
    if tType = #static then
      tRestitution = 0.10000000000000001
    else
      tRestitution = 0.20000000000000001
    end if
  end if
  if (tDataList[#friction].ilk = #integer) or (tDataList[#friction].ilk = #float) then
    tFriction = tDataList.friction
  else
    if tType = #static then
      tFriction = 0.10000000000000001
    else
      tFriction = 0.5
    end if
  end if
  if (tDataList[#mass].ilk = #integer) or (tDataList[#mass].ilk = #float) then
    tMass = tDataList.mass
  else
    tMass = 0.0
  end if
  tList = []
  repeat with i in tTargetList
    tmodel = tmember.model(i)
    tmodel.addModifier(#meshDeform)
    if tDataList[#bodyProxy].ilk = #symbol then
      if [#convexShape, #concaveShape, #box, #sphere].getPos(tDataList.bodyProxy) <> 0 then
        tBodyProxy = tDataList.bodyProxy
      else
        tBodyProxy = #convexShape
      end if
    else
      tBodyProxy = #convexShape
    end if
    tRB = gGame.Physics.createRigidBody(i, i, tBodyProxy, tType)
    tRB.restitution = tRestitution
    tRB.friction = tFriction
    tRB.mass = tMass
    tRB.isPinned = tPinned
    if tType = #dynamic then
      gGame.DynamicRBList.add(tRB)
    else
      gGame.StaticRBList.add(tRB)
    end if
    tmodel.removeModifier(#meshDeform)
    tList.add(tRB)
  end repeat
  if tList.count = 1 then
    return tList[1]
  end if
end

on AddCollisionReport tTarget, tDataList
  if voidp(gGame[#Physics]) = 1 then
    ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " There is no physic reference in gGame.")
    exit
  end if
  if gGame.Physics = VOID then
    ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " There is no physic member ageia found (or is VOID).")
    exit
  end if
  pDataList = value(tDataList)
  if (pDataList = VOID) or (pDataList.ilk <> #propList) then
    ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " Datalist obsolete (VOID or not #proplist).")
    exit
  end if
  if voidp(gGame[#collisionReports]) = 1 then
    gGame[#collisionReports] = [:]
  end if
  pNameA = pDataList[#nameA]
  pNameB = pDataList[#nameB]
  if (pNameA = VOID) or (pNameB = VOID) then
    ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " NameA and/or NameB was VOID. Needed!")
    exit
  end if
  if pNameA = #all then
    gGame.Physics.EnableCollisionCallback()
    ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " PLEASE NOTE! pName = #all. NOTHING IS ADDED TO THE COLLISIONREPORTLIST,.. YOU KNOW WHY!!!")
    exit
  end if
  if pNameB = #all then
    pA = gGame.Physics.getRigidBody(pNameA)
    if pA = VOID then
      ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " No rigidbody found in physics file with nameA.")
      exit
    end if
    PList = gGame.Physics.getRigidBodies()
    pCount = PList.count
    repeat with i = 1 to pCount
      pB = PList[i]
      if pA = pB then
        next repeat
      end if
      gGame.Physics.EnableCollisionCallback(pA, pB)
    end repeat
    gGame.collisionReports[symbol(pA.name)] = []
    exit
  end if
  if pNameB = #cars then
    pA = gGame.Physics.getRigidBody(pNameA)
    if (pA = VOID) or (pA = VOID) then
      ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " No rigidbody found in physics file with nameA.")
      exit
    end if
    if getaProp(gGame, #cars) = VOID then
      ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " Tag was #cars, but was not found in g as a sub array.")
      exit
    end if
    pCount = gGame.cars.count
    repeat with i = 1 to pCount
      pB = gGame.Physics.getRigidBody(gGame.cars[i][#chassis])
      if pA = pB then
        next repeat
      end if
      gGame.Physics.EnableCollisionCallback(pA, pB)
    end repeat
    gGame.collisionReports[symbol(pA.name)] = []
    exit
  end if
  pA = gGame.Physics.getRigidBody(pNameA)
  pB = gGame.Physics.getRigidBody(pNameB)
  if (pA = VOID) or (pA = VOID) then
    ShowError("Function: AddCollisionReport. Target: " & tTarget & " Parameters: " & tDataList & " No rigidbody found in physics file with nameA and/ NameB.")
    exit
  end if
  gGame.Physics.EnableCollisionCallback(pA, pB)
  gGame.collisionReports[symbol(pA.name)] = []
end
