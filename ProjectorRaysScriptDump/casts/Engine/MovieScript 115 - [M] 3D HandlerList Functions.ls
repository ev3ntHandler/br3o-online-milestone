global gSystem

on RunHandlerList me
  repeat with i in gSystem.handlerList
    case i of
      #Rotator:
        Rotator()
      #Scroller:
        Scroller()
      #billboard:
        billboard()
      #Interpolator:
        Interpolator()
      #PointAtor:
        PointAtor()
      #Mimic:
        Mimic()
      otherwise:
        if i.ilk = #string then
          do(i)
        end if
        if i.ilk = #list then
          RunHandlerSubList(i)
        end if
    end case
  end repeat
end

on RunHandlerSubList tList
  if tList[2] = tList[3] then
    do(tList[1])
    tList[2] = 0
  else
    tList[2] = tList[2] + 1
  end if
end

on RemoveFromHandlerList me, tTarget, tDataList
  tOne = VOID
  repeat with i in gSystem.handlerList
    if i.ilk = #list then
      if i[1] = value(tTarget) then
        tOne = i
      end if
      exit repeat
    end if
  end repeat
  if tOne <> VOID then
    gSystem.handlerList.deleteOne(tOne)
    return 1
  else
    return 0
  end if
end

on ClearHandlerLists me
  tList = [#RotatorList, #ScrollerList, #BillBoardList, #InterPolatorList, #PointAtList, #MimicList]
  repeat with i in tList
    gSystem[i] = [:]
  end repeat
end

on AddToRotator me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    exit
  end if
  tModelList = []
  tString = EMPTY
  if tDataList[#string].ilk = #string then
    tString = tDataList[#string]
  end if
  if (tString <> EMPTY) and (tString <> VOID) then
    tModelList = GetModelList(tmember, tString)
  end if
  tModelName = EMPTY
  if tDataList[#model].ilk = #string then
    tModelName = tDataList[#model]
  end if
  tmodel = tmember.model(tModelName)
  if tmodel <> VOID then
    tModelList.add(tmodel)
  end if
  if tModelList.count = 0 then
    exit
  end if
  tVector = vector(0, 0, 0)
  if tDataList[#rotation].ilk = #vector then
    tVector = tDataList[#rotation]
  end if
  tRelativeTo = #self
  if tDataList[#relativeTo] = #symbol then
    tRelativeTo = tDataList[#relativeTo]
  end if
  if tDataList[#relativeTo] = #string then
    tRelativeTo = GetReferenceType(tmember, tDataList[#relativeTo])
  end if
  if tRelativeTo = VOID then
    exit
  end if
  tList = [tModelList, tVector, tRelativeTo]
  if gSystem[#RotatorList] = VOID then
    gSystem[#RotatorList] = [:]
  end if
  gSystem.RotatorList[symbol(tmodel.name)] = tList
  if gSystem.handlerList.getPos(#Rotator) = VOID then
    gSystem.handlerList.add(#Rotator)
  end if
end

on Rotator me
  repeat with i in gSystem.RotatorList
    repeat with j in i[1]
      j.rotate(i[2], i[3])
    end repeat
  end repeat
end

on AddToScroller me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tShader = VOID
  if tDataList[#shader].ilk = #string then
    tShader = tmember.shader(tDataList[#shader])
  end if
  if tShader = VOID then
    return 0
  end if
  tLayer = 1
  if tDataList[#layer].ilk = #integer then
    tLayer = tDataList[#layer]
  end if
  tPosition = vector(0, 0, 0)
  if tDataList[#position].ilk = #vector then
    tPosition = tDataList[#position]
  end if
  tRotation = vector(0, 0, 0)
  if tDataList[#rotation].ilk = #vector then
    tRotation = tDataList[#rotation]
  end if
  tCap = 0
  if tDataList[#cap].ilk = #integer then
    tCap = tDataList[#cap]
  end if
  tList = [[tShader], tLayer, tPosition, tRotation]
  if gSystem[#ScrollerList] = VOID then
    gSystem[#ScrollerList] = []
  end if
  gSystem.ScrollerList[symbol(tShader.name)] = tList
  if gSystem.handlerList.getPos(#Scroller) = VOID then
    gSystem.handlerList.add(#Scroller)
  end if
end

on Scroller me
  repeat with i in gSystem.ScrollerList
    repeat with j in i[1]
      j.textureTransformList[i[2]].position = j.textureTransformList[i[2]].position + i[3]
      j.textureTransformList[i[2]].rotation = j.textureTransformList[i[2]].rotation + i[4]
    end repeat
  end repeat
end

on AddToBillBoard me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tmodel = VOID
  if tDataList[#model].ilk = #string then
    tmodel = tmember.model(tDataList[#model])
  end if
  if tmodel = VOID then
    return 0
  end if
  tmodel.pointAtOrientation = [vector(0, 1, 0), vector(0, 0, 1)]
  tCamera = VOID
  if tDataList[#camera].ilk = #string then
    tCamera = tmember.camera(tDataList[#camera])
  end if
  if tCamera = VOID then
    return 0
  end if
  tUpVector = vector(0, 0, 1)
  if tDataList[#upvector].ilk = #string then
    tUpVector = tDataList[#upvector]
  end if
  tList = [tmodel, tCamera, tUpVector]
  if gSystem[#BillBoardList] = VOID then
    gSystem[#BillBoardList] = [:]
  end if
  gSystem.BillBoardList[symbol(tmodel.name)] = tList
  if gSystem.handlerList.getPos(#billboard) = VOID then
    gSystem.handlerList.add(#billboard)
  end if
end

on billboard me
  repeat with i in gSystem.BillBoardList
    i[1].pointAt(i[2].getWorldTransform().position, i[3])
  end repeat
end

on AddToInterPolator me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  if tDataList[#object].ilk = #string then
    tObject = GetReferenceType(tmember, tDataList.object)
  else
    return 0
  end if
  if tObject = VOID then
    return 0
  else
    t1 = tObject.transform
  end if
  tTarget = VOID
  if tDataList[#target].ilk = #string then
    tTarget = GetReferenceType(tmember, tDataList.target)
  end if
  if tTarget <> VOID then
    t2 = tTarget.transform
  else
    t2 = tObject.transform.duplicate()
    if (tDataList[#OffSetX].ilk = #integer) or (tDataList[#OffSetX].ilk = #float) then
      t2.position.x = t2.position.x + tDataList.OffSetX
    end if
  end if
  if tDataList[#Percentage].ilk = #integer then
    tPerc = tDataList.Percentage
  else
    tPerc = 50
  end if
  if tDataList[#event].ilk = #string then
    tEvent = tDataList.event
  else
    tEvent = EMPTY
  end if
  if tDataList[#handler].ilk = #string then
    tHandler = tDataList.handler
  else
    tHandler = EMPTY
  end if
  if (tDataList[#Threshold].ilk = #integer) or (tDataList[#Threshold].ilk = #float) then
    tThreshold = tDataList.Threshold
  else
    tThreshold = 0.10000000000000001
  end if
  tList = [t1, t2, tPerc, tThreshold, tEvent, tHandler]
  if gSystem[#InterPolatorList] = VOID then
    gSystem[#InterPolatorList] = [:]
  end if
  gSystem.InterPolatorList[symbol(tObject.name)] = tList
  if gSystem.handlerList.getPos(#Interpolator) = VOID then
    gSystem.handlerList.add(#Interpolator)
  end if
end

on Interpolator me
  tList = gSystem.InterPolatorList.duplicate()
  repeat with i in tList
    i[1].interpolateTo(i[2], i[3])
    if (abs((i[1].position - i[2].position) * vector(1, 1, 1)) < i[4]) and (abs((i[1].rotation - i[2].rotation) * vector(1, 1, 1)) < i[4]) then
      event(i[5])
      sendSprite(0, symbol(i[6]), 0)
      i[1].position = i[2].position
      gSystem.InterPolatorList.deleteOne(i)
    end if
  end repeat
end

on AddToPointAt me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  if tDataList[#object].ilk = #string then
    tObject = GetReferenceType(tmember, tDataList.object)
  else
    return 0
  end if
  if tObject = VOID then
    return 0
  end if
  if tDataList[#target].ilk = #string then
    tTarget = GetReferenceType(tmember, tDataList.target)
  else
    return 0
  end if
  if tTarget = VOID then
    return 0
  end if
  if tDataList[#upvector].ilk = #vector then
    tUpVector = tDataList.upvector
  else
    tUpVector = vector(0, 0, 1)
  end if
  tList = [tObject, tTarget, tUpVector]
  if gSystem[#PointAtList] = VOID then
    gSystem[#PointAtList] = [:]
  end if
  gSystem.PointAtList[symbol(tObject.name)] = tList
  if gSystem.handlerList.getPos(#PointAtor) = VOID then
    gSystem.handlerList.add(#PointAtor)
  end if
end

on PointAtor me
  repeat with i in gSystem.PointAtList
    i[1].pointAt(i[2].worldPosition, i[3])
  end repeat
end

on AddToMimic me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    exit
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  if tDataList[#object].ilk = #string then
    tObject = GetReferenceType(tmember, tDataList.object)
  else
    return 0
  end if
  if tObject = VOID then
    return 0
  end if
  if tDataList[#target].ilk = #string then
    tTarget = GetReferenceType(tmember, tDataList.target)
  else
    return 0
  end if
  if tTarget = VOID then
    return 0
  end if
  tList = [tObject, tTarget]
  if gSystem[#MimicList] = VOID then
    gSystem[#MimicList] = [:]
  end if
  gSystem.MimicList[symbol(tTarget.name)] = tList
  if gSystem.handlerList.getPos(#Mimic) = VOID then
    gSystem.handlerList.add(#Mimic)
  end if
end

on Mimic me
  repeat with i in gSystem.MimicList
    i[1].transform = i[2].getWorldTransform()
  end repeat
end
