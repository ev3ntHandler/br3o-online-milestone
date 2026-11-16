property p
global gGame

on new me, tParams
  p = [:]
  tmember = member(tParams[#member])
  if tmember = VOID then
    exit
  end if
  p[#ScriptName] = "[PS] Physics"
  gGame[#Physics] = createMember(tmember.name & "_Physics", [#type: #Physics])
  p[#timeStep] = 0.0333
  p[#subSteps] = 4
  gGame.Physics.destroy()
  gGame.Physics.Init(tmember, vector(1.0, 1.0, 1.0), #equal, p.timeStep, p.subSteps)
  gGame.Physics.gravity = vector(0.0, 0.0, -39.24000000000000199)
  gGame.Physics.sleepThreshold = 1
  gGame.Physics.sleepMode = #linearVelocity
  gGame.Physics.RegisterCollisionCallback(#collisionCallback)
  return me
end

on enterFrame me
  gGame.Physics.timeStep = p.timeStep * gGame.TimeMP
  gGame.Physics.simulate()
end
