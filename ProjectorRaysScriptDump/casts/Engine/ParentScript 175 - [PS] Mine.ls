property p
global gSystem, gGame, gData

on new me, t, tPod
  p = [:]
  p[#member] = t.general.member
  p[#sender] = t.general.tag
  p[#model] = t.car.model
  p[#data] = gData.data.SecondaryWeapons.mineDeployer
  p[#me] = me
  tDetails = gGame.Physics.rayCastClosest(t.car.Effects.secondary[1].worldPosition, -t.car.transform.zAxis)
  if tDetails.count > 0 then
    p[#MineName] = string(p.sender) & "Mine" & _system.milliSeconds
    p[#Mine] = p.member.newModel(p.MineName, p.member.modelResource("Mine"))
    p.Mine.shader = p.member.shader("Weapons_Material")
    p.Mine.pointAtOrientation = [vector(0.0, 0.0, 1.0), vector(0.0, 1.0, 0.0)]
    p.Mine.transform.position = tDetails[2]
    p.Mine.pointAt(tDetails[3] * 100000)
    p[#parent] = p.member.model(tDetails[1].name).parent
    p.Mine.transform = p.parent.getWorldTransform().inverse() * p.Mine.transform
    p.Mine.parent = p.parent
    PlaySound("Mine1_SFX", [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: p.Mine.name, #targetName: p.Mine.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
    p[#timeout] = 25 * gGame.tempo
    return me
  else
    return VOID
  end if
end

on enterFrame me
  repeat with i in gGame.cars
    if i.general.tag = p.sender then
      next repeat
    end if
    if i.car.transform.position.distanceTo(p.Mine.worldPosition) <= p.data.range then
      areaDamage(0, p.Mine.worldPosition, p.data.areaDamage, p.sender, p.parent)
      tExploScript = new(script("[PS] Rocket Explosion"), p.member, p.Mine.worldPosition, gGame.member.camera("PLayer1_camera"), VOID, 500)
      if tExploScript <> VOID then
        gGame.scriptList.add(tExploScript)
      end if
      PlaySound("MineGrenadeExplosion_SFX", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #sender: p.Mine.name, #targetName: p.Mine.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
      delete me
      exit repeat
    end if
  end repeat
  p.timeout = p.timeout - (1.0 * gGame.TimeMP)
  if p.timeout <= 0 then
    delete me
  end if
end

on delete me
  p.member.deleteModel(p.Mine.name)
  gGame.scriptList.deleteOne(p.me)
end
