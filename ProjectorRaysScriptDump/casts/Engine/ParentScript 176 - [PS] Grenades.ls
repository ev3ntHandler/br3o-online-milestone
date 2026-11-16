property p
global gSystem, gGame, gData

on new me, t
  p = [:]
  p[#member] = t.general.member
  p[#sender] = t.general.tag
  p[#model] = t.car.model
  p[#data] = gData.data.SecondaryWeapons.GrenadeDeployer
  p[#parent] = t.car.currentFloor.parent
  p[#me] = me
  p[#Counter] = 0
  p[#Grenades] = 5
  p[#GrenadeList] = []
  p[#SpawnPos] = t.car.Effects.secondary[1]
  p[#AllSpawned] = 0
  p[#timeout] = 25 * gGame.tempo
  return me
end

on enterFrame me
  p.Counter = p.Counter + gGame.TimeMP
  if (p.Counter >= 2) and (p.Grenades >= 1) then
    p.Counter = 0
    tName = string(p.sender) & "Grenade" & p.Grenades & _system.milliSeconds
    tGrenade = p.member.newModel(tName, p.member.modelResource("Grenade1"))
    tGrenade.shader = p.member.shader("Weapons_Material")
    tGrenade.transform.position = p.SpawnPos.worldPosition
    tGrenade.transform.rotation = randomVector() * 90
    tGrenade.transform = p.parent.getWorldTransform().inverse() * tGrenade.transform
    tGrenade.parent = p.parent
    tGrenade.addModifier(#meshDeform)
    tRB = gGame.Physics.createRigidBody(tName, tName, #convexShape, #dynamic)
    tRB.restitution = 0.75
    tRB.friction = 0.5
    tRB.mass = 20.0
    tGrenade.removeModifier(#meshDeform)
    tVector = vector(random(-50, 50) * 0.01, abs(p.SpawnPos.transform.yAxis), random(-50, 50) * 0.01) * 500
    tRB.applyLinearImpulse(tVector)
    p.GrenadeList.add(tGrenade)
    p.Grenades = p.Grenades - 1
    if p.Grenades = 0 then
      p.AllSpawned = 1
    end if
    tSound = "Grenade" & random(1, 5) & "_SFX"
    PlaySound(tSound, [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: tGrenade.name, #targetName: tGrenade.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
  end if
  if p.AllSpawned = 1 then
    repeat with i in gGame.cars
      if i.general.tag = p.sender then
        next repeat
      end if
      tList = p.GrenadeList.duplicate()
      repeat with j in tList
        if i.car.transform.position.distanceTo(j.worldPosition) <= p.data.range then
          areaDamage(0, j.worldPosition, p.data.areaDamage, p.sender, p.parent)
          tExploScript = new(script("[PS] Rocket Explosion"), p.member, j.worldPosition, gGame.member.camera("PLayer1_camera"), VOID, 500)
          if tExploScript <> VOID then
            gGame.scriptList.add(tExploScript)
          end if
          PlaySound("MineGrenadeExplosion_SFX", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #sender: j.name, #targetName: j.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
          tName = j.name
          p.GrenadeList.deleteOne(j)
          p.member.deleteModel(tName)
          gGame.Physics.deleteRigidBody(tName)
          if p.GrenadeList.count = 0 then
            delete me
          end if
        end if
      end repeat
    end repeat
  end if
  p.timeout = p.timeout - gGame.TimeMP
  if p.timeout <= 0 then
    delete me
  end if
end

on delete me
  tList = p.GrenadeList.duplicate()
  repeat with i in tList
    tName = i.name
    p.GrenadeList.deleteOne(i)
    p.member.deleteModel(tName)
    gGame.Physics.deleteRigidBody(tName)
  end repeat
  gGame.scriptList.deleteOne(p.me)
end
