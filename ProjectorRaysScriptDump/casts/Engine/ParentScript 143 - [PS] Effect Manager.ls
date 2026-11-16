property p
global gSystem, gData, gGame

on new me, tParams
  p = [:]
  p[#member] = member(tParams.memberName)
  event("SetupDebris")
  CloneModel(0, gGame.member.name, [#sourceMember: "Debris", #hide: 1, #lod: 0, #delete: 1])
  event("Setup3DParticles")
  CloneModel(0, p.member.name, [#sourceMember: "Particles", #hide: 1, #delete: 1])
  BlendShader(p.member.name, [#materialName: "ParticleExplosion1_Material", #blendMode: #add])
  BlendShader(p.member.name, [#materialName: "ParticleSmoke1_Material", #blendMode: #multiply])
  if gGame.traffic = 1 then
    CloneModel(0, gGame.member.name, [#sourceMember: "TrafficDestroyed", #hide: 1, #lod: 0, #delete: 1])
  end if
  gGame[#BulletHits] = []
  gGame[#AreaDamageList] = []
  if voidp(gGame[#destructiveList]) = 1 then
    gGame[#destructiveList] = []
  end if
  p[#RicochetsList] = []
  return me
end

on enterFrame me
  tList = gGame.BulletHits.duplicate()
  repeat with i in tList
    tName = i[1].name
    if tName contains "Proxy" then
      gGame.cars[symbol(tName.char[1..tName.length - 5])].car.impacts.add([i[5], #bullet, i[6]])
      tSound = "HitMetal" & random(1, 4) & "_SFX"
      PlaySound(tSound, [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: i[1].name, #targetName: i[1].name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1])
      if random(1, 3) = 1 then
        tSound = "HitGlass" & random(1, 3) & "_SFX"
        PlaySound(tSound, [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: i[1].name, #targetName: i[1].name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1])
      end if
    else
      tmodel = p.member.model(tName)
      tData = tmodel.userData
      if gGame.destructiveList.getPos(tmodel) <> 0 then
        tData.Health = tData.Health - i[5]
        if tData.Health <= 0 then
          me.DestructObject(tmodel, tData, i[6], i[1])
        end if
        if voidp(tData[#type]) = 0 then
          case tData.type of
            #metal:
              tSound = "HitMetal" & random(1, 4) & "_SFX"
            #concrete:
              tSound = "HitConcrete" & random(1, 2) & "_SFX"
            #wood:
              tSound = "HitWood" & random(1, 3) & "_SFX"
            otherwise:
              tSound = "HitDefault" & random(1, 6) & "_SFX"
          end case
          PlaySound(tSound, [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: i[1].name, #targetName: i[1].name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1])
        end if
      else
        tSound = "HitDefault" & random(1, 6) & "_SFX"
        PlaySound(tSound, [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: i[1].name, #targetName: i[1].name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1])
      end if
    end if
    gGame.BulletHits.deleteOne(i)
  end repeat
  tList = gGame.AreaDamageList.duplicate()
  repeat with i in tList
    tmodel = p.member.model(i[1].name)
    tData = tmodel.userData
    if gGame.destructiveList.getPos(tmodel) <> 0 then
      tData.Health = tData.Health - i[2]
      if tData.Health <= 0 then
        me.DestructObject(tmodel, tData, i[3], i[1])
      end if
      gGame.AreaDamageList.deleteOne(i)
    end if
  end repeat
  repeat with i in p.RicochetsList
  end repeat
end

on DestructObject me, tmodel, tData, tSender, tRB, tImpulse
  gGame.destructiveList.deleteOne(tmodel)
  if voidp(gGame.cars[tSender]) = 0 then
    gGame.cars[tSender].race.score = gGame.cars[tSender].race.score + tData.score
    gGame.cars[tSender].race.addScore = gGame.cars[tSender].race.addScore + tData.score
    if gGame.cars[tSender].general.controller = #player then
      tUD = tmodel.userData
      if voidp(tUD[#traffic]) = 0 then
        gGame.Statistics.vehicles = gGame.Statistics.vehicles + 1
        CheckTrophies()
      end if
    end if
  end if
  if tData[#effect].ilk = #symbol then
    if tData.effect = #explosion then
      tResource = p.member.modelResource(tData.model & "Destroyed_Object")
      if tResource <> VOID then
        tmodel.resource = tResource
      end if
      tmodel.shader = p.member.shader("Debris_Material")
      tRandom = random(-70, 70) * 0.01
      tMass = tData.mass
      if tMass <> #static then
        tRB.applyLinearImpulse(vector(tRandom * tMass, tRandom * tMass, tMass * 20))
        tRB.applyAngularImpulse(vector(tRandom * (tMass * random(20, 30)), tRandom * (tMass * random(20, 30)), tMass))
      end if
      tExploScript = new(script("[PS] Rocket Explosion"), p.member, tmodel.worldPosition, gGame.member.camera("PLayer1_camera"), VOID, 1500)
      if tExploScript <> VOID then
        gGame.scriptList.add(tExploScript)
      end if
      PlaySound("Explosion_SFX", [#priority: #medium, #surround: 1, #member3DName: gGame.member.name, #sender: tRB.name, #targetName: tRB.name, #referenceName: "Player1_Camera", #distance: [100, 350], #static: 1, #Override: 1])
      areaDamage(0, tmodel.worldPosition, tData.areaDamage, tmodel.name, tData.parent)
    end if
  else
    tmodel.shader = p.member.shader("Debris_Material")
  end if
end
