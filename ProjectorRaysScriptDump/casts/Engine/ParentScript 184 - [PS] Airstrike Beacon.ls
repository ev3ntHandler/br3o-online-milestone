property p
global gSystem, gGame

on new me, t, tPod
  p = [:]
  p[#member] = t.general.member
  p[#sender] = t.general.tag
  p[#model] = t.car.model
  p[#me] = me
  p[#BeaconName] = string(p.sender) & "AirstrikeBeacon" & _system.milliSeconds
  p[#Beacon] = p.member.newModel(p.BeaconName, p.member.modelResource("AirstrikeBeacon"))
  p.Beacon.shader = p.member.model("AirstrikeBeacon").shader
  p.Beacon.pointAtOrientation = [vector(0.0, 0.0, 1.0), vector(0.0, 1.0, 0.0)]
  tTransform = t.car.Effects.secondary[1].getWorldTransform().duplicate()
  p.Beacon.transform = tTransform
  p[#Stuck] = 0
  p[#Speed] = 5.0
  p[#gravity] = -0.07000000000000001
  p[#rotation] = 25
  p[#distance] = 0
  p[#Bombs] = 12
  p[#TargetList] = []
  p[#Counter] = 5.0
  PlaySound("RocketPodLaunch_SFX", [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: t.car.Proxy.name, #targetName: t.car.Proxy.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 0, #Override: 1])
  return me
end

on enterFrame me
  if gGame.pause = 1 then
    exit
  end if
  if p.Stuck = 0 then
    p.Beacon.translate(0, p.Speed * gGame.TimeMP, p.gravity * gGame.TimeMP, #self)
    p.distance = p.distance + (p.Speed * gGame.TimeMP)
    tTransform = p.Beacon.transform
    tDetails1 = gGame.Physics.rayCastClosest(tTransform.position, tTransform.yAxis)
    tDetails2 = gGame.Physics.rayCastClosest(tTransform.position, vector(0.0001, 0.0001, -1.00009999999999999))
    if tDetails1.count > 0 then
      if tDetails1[4] < (0.5 + (p.Speed * gGame.TimeMP)) then
        me.Stuck(tDetails1)
      end if
    end if
    if (tDetails2.count > 0) and (p.Stuck = 0) then
      if tDetails2[4] < 0.20000000000000001 then
        me.Stuck(tDetails2)
      end if
    end if
  else
    p.Counter = p.Counter - (1 * gGame.TimeMP)
    if (p.Bombs > 0) and (p.Counter = 0) then
      tVector = p.TargetList[p.Bombs]
      tDetails = gGame.Physics.rayCastClosest(tVector + vector(0, 0, 100), vector(0, 0, -1))
      if tDetails.count > 0 then
        tVector = tDetails[2]
      end if
      tVector = tVector + vector(0, 0, 1.5)
      tExploScript = new(script("[PS] Explosion"), p.member, tVector, gGame.member.camera("PLayer1_camera"), VOID, 500)
      if tExploScript <> VOID then
        gGame.scriptList.add(tExploScript)
      end if
      PlaySound("RocketPodExplosion_SFX", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #sender: p.Beacon.name, #targetName: p.Beacon.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 0, #Override: 1])
      p.Counter = 5
      p.Bombs = p.Bombs - 1
    end if
  end if
end

on Stuck me, tDetails
  tName = tDetails[1].name
  tmodel = p.member.model(tName)
  p.Beacon.transform.position = tDetails[2] + (tDetails[3] * 0.05)
  p.Beacon.pointAt(tDetails[3] * 100000, vector(0, 0, 1))
  tOffset = p.Beacon.worldPosition - tmodel.worldPosition
  p.Beacon.transform.position = tmodel.worldPosition
  p.Beacon.parent = tmodel
  p.Beacon.transform.position = tOffset
  p.Stuck = 1
  tOffset = 24
  tTransform = p.Beacon.getWorldTransform().duplicate()
  repeat with i = 1 to p.Bombs
    tVector = tTransform.position
    tVector = tVector - (tTransform.xAxis * tOffset)
    tVector = tVector + (tTransform.xAxis * (i * 4))
    tOdd = i mod 2
    if tOdd = 1 then
      tVector = tVector - (tTransform.yAxis * 4)
    else
      tVector = tVector + (tTransform.yAxis * 4)
    end if
    tVector = tVector + randomVector()
    p.TargetList.add(tVector)
  end repeat
end

on DeleteBeacon me
  p.member.deleteModel(p.Beacon.name)
  p.alive = 0
end

on delete me
  if _movie.timeoutList.getPos(timeout(p.BeaconName & "DeleteBeacon")) <> 0 then
    timeout(p.BeaconName & "DeleteBeacon").forget()
  end if
  if p.alive = 1 then
    me.DeleteBeacon()
  end if
  gGame.scriptList.deleteOne(p.me)
end
