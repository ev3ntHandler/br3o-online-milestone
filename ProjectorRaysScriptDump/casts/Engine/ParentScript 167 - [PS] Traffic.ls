property p
global gSystem, gData, gGame

on new me, tmember, tData, tParent, tmodel, tRB
  p = [:]
  p[#member] = tmember
  p[#ScriptName] = "Traffic"
  p[#model] = tmodel
  p[#rb] = tRB
  p[#group] = tmember.newGroup(p.model.name & "_Group")
  p[#Leader] = p.member.newGroup(p.model.name & "Leader_Group")
  p.Leader.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  p[#parent] = tParent
  p[#maxSpeed] = 10
  p[#accGain] = 0.10000000000000001
  p[#Hovering] = 0
  p[#HoverDist] = 1.10000000000000009
  p[#strength] = 6.0
  p[#damping] = 0.29999999999999999
  p[#offset] = vector(0, 0, 1)
  p[#Active] = [0, 2]
  return me
end

on enterFrame me
  if p.parent.isInWorld() then
    if p.Active[1] = 0 then
      p.Active[1] = 1
    end if
  else
    if p.Active[1] = 1 then
      p.Active[1] = 2
    end if
  end if
  if p.Active[1] <> 1 then
    return 
  end if
  tTransform = transform()
  tTransform.rotation = p.model.transform.rotation.duplicate()
  tWorldForward = tTransform * vector(0.0, 1.0, 0.0)
  tWorldAxis = tTransform * -vector(0.0, 0.0, -1.0)
  tWorldRight = tWorldForward.cross(tWorldAxis)
  tWorldDown = tTransform * vector(0.0, 0.0, -1.0)
  tWorldForward.normalize()
  tWorldAxis.normalize()
  tWorldRight.normalize()
  tWorldDown.normalize()
  tChassisPos = p.rb.position
  tPhysicsCar = p.rb
  tCurrentVel = tPhysicsCar.linearVelocity
  tForwardVel = tWorldForward * tCurrentVel
  tSpeed = tCurrentVel.dot(tWorldForward)
  tDirection = tWorldDown + vector(0.0001, 0.0001, 0.0001)
  tIntersectDetails = gGame.Physics.rayCastClosest(tChassisPos + p.offset, tDirection)
  if tIntersectDetails.count > 0 then
    if tIntersectDetails[4] < p.HoverDist then
      tPhysicsCar.angularVelocity = vector(0, 0, 0)
      tdiff = tIntersectDetails[2] - (tChassisPos + p.offset)
      tLength = tdiff.length
      tF = -p.strength * (p.HoverDist - tLength)
      tF = tF - (p.damping * tCurrentVel.dot(tdiff))
      tForce = tdiff * tF * p.rb.mass
      tForce = tForce * 4
      tPhysicsCar.applyLinearImpulse(tForce, tChassisPos)
      p.Hovering = 1
      tgroup = p.group
      tgroup.transform = p.model.transform.duplicate()
      thisPosn = tgroup.getWorldTransform().position - (1050.0 * tIntersectDetails[3])
      startT = tgroup.getWorldTransform()
      tgroup.pointAt(thisPosn, tWorldForward)
      endT = tgroup.getWorldTransform()
      newT = startT.interpolate(endT, 45)
      tgroup.transform = newT
      tPhysicsCar.orientation = tgroup.transform.axisAngle
      tPhysicsCar.angularVelocity = vector(0, 0, 0)
    else
      p.Hovering = 0
    end if
  else
    p.Hovering = 0
  end if
  if p.Hovering = 1 then
    tdiff = p.maxSpeed - tSpeed
    imp = tdiff * p.accGain * p.rb.mass * p.model.getWorldTransform().yAxis
    tPhysicsCar.applyLinearImpulse(imp)
    tSlideSpeed = tWorldRight.dot(tCurrentVel)
    imp = tWorldRight * (-tSlideSpeed * p.rb.mass * 1.25)
    tPhysicsCar.applyLinearImpulse(imp)
    imp = -tCurrentVel * (0.01 * p.rb.mass)
    tPhysicsCar.applyLinearImpulse(imp)
  end if
end
