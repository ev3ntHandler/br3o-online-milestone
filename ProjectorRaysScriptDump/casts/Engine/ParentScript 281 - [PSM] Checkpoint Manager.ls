property p
global g

on new me, tParams
  p = [:]
  p[#controller] = tParams[#controller]
  p[#tag] = tParams[#tag]
  p[#model] = tParams[#RayCastModel]
  p[#ScriptLimit] = 0
  if getaProp(g, #CheckPoints) = VOID then
    ShowError("Script: [PSM] Checkpoint Manager. " & tParams & " g.CheckPoints does not exist! Function not exited, but checkpoints will not be checked.")
  end if
  p[#CurrentT] = transform()
  p[#previousT] = transform()
  p[#UpdateWayPoints] = 0
  p[#OldRootNr] = 0
  if getaProp(tParams, #UpdateWayPoints).ilk = #integer then
    p.UpdateWayPoints = tParams[#UpdateWayPoints]
  end if
  me.SetFinalCheckpoint()
  return me
end

on SetFinalCheckpoint me
  tCount = g.RootList.count
  tChildCount = g.RootList[tCount].child.count
  repeat with i = 1 to tChildCount
    tChild = g.RootList[tCount].child[i]
    if tChild.name contains "SkyTube" then
      if tChild.name contains "SkyTubeBase" then
        nothing()
        next repeat
      end if
      tChild.shader = g.member.shader("SkyTubeChecker_Material")
    end if
  end repeat
end

on enterFrame me
  if getaProp(g, #CheckPoints) <> VOID then
    UpdateCheckpoints()
  end if
  if p.UpdateWayPoints = 1 then
    UpdateWayPoints()
  end if
end

on UpdateWayPoints me
  if getaProp(g, #WayPointList) = VOID then
    exit
  end if
  if g.WayPointList.count = 0 then
    exit
  end if
  pCurrentRoot = g.cars[p.tag][#specifics][#currentRootNr]
  if p.OldRootNr <> pCurrentRoot then
    pFutureRoot = g.cars[p.tag][#specifics][#currentRootNr] + 1
    if pFutureRoot > g.RootList.count then
      pFutureRoot = pCurrentRoot
    end if
    p[#MyWayPointList] = g.WayPointList[symbol("TrackRoot" & pCurrentRoot & "_Group")].duplicate()
    if pFutureRoot <> pCurrentRoot then
      pExtraList = g.WayPointList[symbol("TrackRoot" & pFutureRoot & "_Group")].duplicate()
      pCount = pExtraList.count
      repeat with i = 1 to pCount
        p.MyWayPointList.add(pExtraList[i])
      end repeat
    end if
    g.cars[p.tag][#specifics][#WayPointList] = p.MyWayPointList.duplicate()
    p.OldRootNr = pCurrentRoot
  end if
  pCount = p.MyWayPointList.count
  pNearestWaypoint = 1
  pNearestWaypointPos = vector(0.0, 0.0, 0.0)
  pNearestDistance = 15.0
  g.cars[p.tag][#specifics][#currentWaypoint] = 1
  repeat with i = 1 to pCount
    pWaypointPos = p.MyWayPointList[i][1]
    pTempDistance = pWaypointPos.distanceTo(p.model.worldPosition)
    if pTempDistance <= pNearestDistance then
      pNearestWaypoint = i + 1
      if pNearestWaypoint > p.MyWayPointList.count then
        pNearestWaypoint = p.MyWayPointList.count
      end if
      pNearestWaypointPos = p.MyWayPointList[pNearestWaypoint][1]
      g.cars[p.tag][#specifics][#currentWaypoint] = pNearestWaypoint
      g.cars[p.tag][#specifics][#currentDistance] = pTempDistance
      exit repeat
    end if
  end repeat
  tCurrentWaypoint = p.MyWayPointList[g.cars[p.tag][#specifics][#currentWaypoint]][1]
  if tCurrentWaypoint <> VOID then
    tZDistance = abs(tCurrentWaypoint.z - p.model.worldPosition.z)
    if p.model.worldPosition.z < tCurrentWaypoint.z then
      tZDistance = -tZDistance
    end if
    g.cars[p.tag][#specifics][#currentDistanceZ] = tZDistance
  end if
end

on UpdateCheckpoints me
  if g.CheckPoints.count = 0 then
    exit
  end if
  tFloor = g.cars[p.tag].specifics.currentFloor
  tRootName = tFloor.name
  tOldDelimiter = the itemDelimiter
  the itemDelimiter = "_"
  tRootName = tRootName.item[1]
  the itemDelimiter = tOldDelimiter
  tProp = symbol(tRootName)
  tPos = g.CheckPoints.findPos(tProp)
  if g.CheckPoints[tProp] <> VOID then
    tTransform1 = g.CheckPoints[tPos].duplicate()
    tTransform2 = p.model.transform.duplicate()
    tAxis = tTransform2.position - p.previousT.position
    tAxis.normalize()
    tInt = LineLineIntersect(tTransform1, tTransform2, #y, tAxis)
    tPoint1 = point(p.previousT.position.x, p.previousT.position.y)
    tPoint2 = point(p.model.transform.position.x, p.model.transform.position.y)
    tXList = [tInt.x, tPoint1.locH, tPoint2.locH]
    tYList = [tInt.y, tPoint1.locV, tPoint2.locV]
    tXList.sort()
    tYList.sort()
    if (tXList[2] = tInt.x) and (tYList[2] = tInt.y) then
      UpdateCheckpoint(tPos, tProp)
      g.CheckPoints[tPos] = VOID
      if g.CheckPoints.count = tPos then
        finish()
      end if
    end if
  end if
  p.previousT = p.model.transform.duplicate()
end

on finish me
  g.cars[p.tag][#state] = "Done"
  g.cars[p.tag][#specifics][#finalTime] = g.RaceTime
  g.RaceState = "Finished"
  g.MissionState = "Succes"
  event("FinishRace")
end
