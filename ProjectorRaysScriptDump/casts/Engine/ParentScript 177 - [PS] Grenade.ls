property p
global gSystem, gGame, gData

on new me, t, tPod
  p = [:]
  p[#member] = t.general.member
  p[#sender] = t.general.tag
  p[#model] = t.car.model
  p[#data] = gData.data.SecondaryWeapons.GrenadeLauncher
  p[#me] = me
  tName = string(p.sender) & "Grenade" & _system.milliSeconds
  p[#GrenadeName] = tName
  p[#Grenade] = p.member.newModel(tName, p.member.modelResource("Grenade"))
  p.Grenade.shader = p.member.shader("Weapons_Material")
  p.Grenade.pointAtOrientation = [vector(0.0, 0.0, 1.0), vector(0.0, 1.0, 0.0)]
  p.Grenade.transform = t.car.Effects.secondary[1].getWorldTransform()
  p.Grenade.transform.scale = vector(1, 1, 1) * 1
  p.Grenade.addModifier(#meshDeform)
  p[#rb] = gGame.Physics.createRigidBody(tName, tName, #sphere, #dynamic)
  p.rb.restitution = 0.90000000000000002
  p.rb.friction = 0.5
  p.rb.mass = 20.0
  p.Grenade.removeModifier(#meshDeform)
  p.rb.linearVelocity = p.Grenade.transform.yAxis * 100
  p.rb.angularVelocity = vector()
  p[#SmokeModel] = CreateParticleSystem(p.member.name, [#type: #GrenadeSmoke, #NameTag: tName])
  p[#SmokeResource] = p.SmokeModel.resource
  tSound = "GrenadeLauncher" & random(1, 3) & "_SFX"
  PlaySound(tSound, [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: t.car.Proxy.name, #targetName: t.car.Proxy.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 0, #Override: 1])
  p[#timeout] = 2 * gGame.tempo
  return me
end

on enterFrame me
  repeat with i in gGame.cars
    if i.general.tag = p.sender then
      next repeat
    end if
    if i.car.transform.position.distanceTo(p.Grenade.worldPosition) <= 4.0 then
      tExploScript = new(script("[PS] Rocket Explosion"), p.member, p.Grenade.worldPosition, gGame.member.camera("PLayer1_camera"), VOID, 500)
      if tExploScript <> VOID then
        gGame.scriptList.add(tExploScript)
      end if
      PlaySound("GrenadeExplosion_SFX", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #sender: p.Grenade.name, #targetName: p.Grenade.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
      areaDamage(0, p.Grenade.worldPosition, p.data.areaDamage, p.sender, VOID)
      delete me
      exit
    end if
  end repeat
  if p.Grenade <> VOID then
    pRegion = p.Grenade.getWorldTransform().position - (p.Grenade.transform.yAxis * 0.10000000000000001)
    p.SmokeResource.emitter.region = [pRegion]
  end if
  p.timeout = p.timeout - (1.0 * gGame.TimeMP)
  if p.timeout <= 0 then
    tExploScript = new(script("[PS] Rocket Explosion"), p.member, p.Grenade.worldPosition, gGame.member.camera("PLayer1_camera"), VOID, 500)
    if tExploScript <> VOID then
      gGame.scriptList.add(tExploScript)
    end if
    tScript = PlaySound("GrenadeExplosion_SFX", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #sender: p.Grenade.name, #targetName: p.Grenade.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
    put tScript
    areaDamage(0, p.Grenade.worldPosition, p.data.areaDamage, p.sender, VOID)
    delete me
  end if
end

on delete me
  p.member.deleteModel(p.SmokeModel.name)
  p.member.deleteModelResource(p.SmokeResource.name)
  p.SmokeResource = VOID
  p.deleteProp(#SmokeModel)
  tName = p.Grenade.name
  p.member.deleteModel(tName)
  gGame.Physics.deleteRigidBody(tName)
  gGame.scriptList.deleteOne(p.me)
end
