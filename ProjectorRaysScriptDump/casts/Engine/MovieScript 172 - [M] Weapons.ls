global gSystem, gData, gGame, gSound

on BuildWeapon me, t, tProp, tWeaponList
  tWeaponsMember = member("Weapons")
  tWeapon = t.general.data.Weapons[tProp]
  if tWeapon = "none" then
    return 0
  end if
  tStringTag = string(t.general.tag)
  tModelList = CloneModel(0, gGame.member.name, [#sourceMember: tWeaponsMember.name, #model: tWeaponList, #NameTag: tStringTag, #shaderTag: tStringTag, #lod: 0])
  tLocations = gData.data[symbol(string(tProp) & "Weapons")][symbol(tWeapon)][#location]
  tCount = tLocations.count
  repeat with i = 1 to tCount
    tLoc = tLocations[i]
    tDummy = t.car.name & string(tProp) & "Weapon" & tLoc & "_Dummy"
    tmodel = tModelList
    if tModelList.ilk = #list then
      tmodel = tModelList[i]
    end if
    tDummy = member(t.car.name).group(tDummy)
    if tDummy <> VOID then
      tmodel.transform.position = tDummy.transform.position - t.car.model.transform.position
      tmodel.parent = t.car.model
    end if
    tDummy2 = tWeapon & "Flash" & i & "_Dummy"
    if tWeaponsMember.group(tDummy2) = VOID then
      return 0
    end if
    if i > tWeaponList.count then
      tName = tWeaponList[1]
    else
      tName = tWeaponList[i]
    end if
    tMuzzleDiff = tWeaponsMember.group(tDummy2).transform.position - tWeaponsMember.model(tName).transform.position
    tMuzzlePos = tmodel.transform.position + tMuzzleDiff
    tgroup = gGame.member.newGroup(tStringTag & tName & "Flash" & i)
    tgroup.transform.position = tMuzzlePos
    tgroup.parent = t.car.model
    t.car.Effects[tProp].add(tgroup)
    tShader = tmodel.shader
    if t.car.shaderList.getPos(tShader) = 0 then
      t.car.shaderList.add(tShader)
    end if
  end repeat
end

on setup_machinegun me, t
  tData = gData.data.PrimaryWeapons.MachineGun.duplicate()
  t.Weapons[#MachineGun] = [#rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.primary[1], #damage: tData.damage]
  BuildWeapon(0, t, #primary, ["MachineGun"])
  if t.car.name = "Apache" then
    gGame.member.model(string(t.general.tag) & "MachineGun").removeFromWorld()
  end if
  t.Weapons.MachineGun[#Flash1] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["MachineGunMuzzleFlash1"], #NameTag: string(t.general.tag), #lod: 0])
  t.Weapons.MachineGun.Flash1.parent = t.car.Effects.primary[1]
  t.Weapons.MachineGun.Flash1.transform.position = vector()
  t.Weapons.MachineGun.Flash1.transform.scale = vector(0.001, 0.001, 0.001)
  t.Weapons.MachineGun[#Flash1Scale] = vector(1, 1, 1)
  t.Weapons.MachineGun[#Flash2] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["MachineGunMuzzleFlash2"], #NameTag: string(t.general.tag), #lod: 0])
  t.Weapons.MachineGun.Flash2.parent = t.car.Effects.primary[1]
  t.Weapons.MachineGun.Flash2.transform.position = vector()
  t.Weapons.MachineGun.Flash2.transform.scale = vector(0.001, 0.001, 0.001)
  if t[#sound] <> VOID then
    t.sound[#primary] = t.sound.Mixer.createSoundObject("Primary", member("MachineGun_SFX"), [#loopCount: 0])
    t.sound.primary.volume = 0
    t.sound.primary.play()
  end if
  t.Weapons.MachineGun[#bullet] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Bullet"], #NameTag: string(t.general.tag), #hide: 1, #lod: 0])
  t.Weapons.MachineGun[#BulletScale] = 1.0
end

on update_machinegun me, t
  tData = t.Weapons.MachineGun
  tTransform = t.car.Effects.primary[1].getWorldTransform().duplicate()
  tDirection = tTransform.yAxis
  tBullet = tData.bullet
  tBulletT = tBullet.transform
  tFlash1 = tData.Flash1.transform
  tFlash2 = tData.Flash2.transform
  if t.input.action1 = 1 then
    if tData.ammo[1] > 0 then
      tData.rof[1] = tData.rof[1] + gGame.TimeMP
      if tData.rof[1] >= tData.rof[2] then
        tData.rof[1] = 0
        tData.ammo[1] = tData.ammo[1] - 1
        if (tData.ammo[1] = 0) and (tData.clips > 0) then
          tData.ammo[1] = tData.ammo[2]
          tData.clips = tData.clips - 1
        end if
        if t.general.controller = #player then
          gGame.Statistics.bullets = gGame.Statistics.bullets + 1
        end if
        if (gGame.Statistics.bullets >= gGame.GodOfWarBullets) and (gGame.Trophies.godofwar = 0) then
          DoTrophy(0, #godofwar)
        end if
        tFlash2.scale = vector(1.5, 1.5, 1.5)
        tFlash2.rotation.y = random(1, 120)
        tRandom = random(1000, 1400) * 0.001
        tData.Flash1Scale = vector(tRandom, tRandom * 1.5, tRandom)
        tFlash1.scale = tData.Flash1Scale
        tFlash1.rotation.y = random(1, 45)
        if (t[#sound] <> VOID) and (gSound.mute = 0) then
          t.sound.primary.volume = 180
        end if
        tBullet.addToWorld()
        tBullet.transform = tTransform.duplicate()
        tBulletT.scale.y = 100
        tBulletT.position = tTransform.position + (100 * tDirection)
        tData.BulletScale = 100
        tDetails = gGame.Physics.rayCastClosest(tTransform.position, tDirection)
        if tDetails.count > 0 then
          tBulletT.scale.y = tDetails[4]
          tBulletT.position = tTransform.position + (tDetails[4] * tDirection)
          tData.BulletScale = tDetails[4]
          tDetails.add(random(tData.damage[1], tData.damage[2]))
          tDetails.add(t.general.tag)
          gGame.BulletHits.add(tDetails)
        end if
      else
        tPerc = 1.0 - (tData.rof[1] / tData.rof[2])
        tPerc = max(tPerc, 0.001)
        tFlash1.scale = tData.Flash1Scale * tPerc
        tBulletScale = tData.BulletScale * tPerc
        if tBulletScale < 0.001 then
          tBulletScale = 0.001
        end if
        tBulletT.scale.y = tBulletScale
        if tData.rof[1] <= (tData.rof[2] * 0.5) then
          tPerc = 1.0 - (tData.rof[1] / (tData.rof[2] * 0.5))
          tPerc = max(tPerc, 0.001)
          tFlash2.scale = vector(1.39999999999999991, 1.39999999999999991, 1.39999999999999991) * tPerc
        else
          tPerc = (tData.rof[1] - (tData.rof[2] * 0.5)) / (tData.rof[2] * 0.5)
          tPerc = max(tPerc, 0.001)
          tFlash2.scale = vector(1.39999999999999991, 1.39999999999999991, 1.39999999999999991) * tPerc
        end if
      end if
    else
      if (t[#sound] <> VOID) and (gSound.mute = 0) then
        t.sound.primary.volume = 0
      end if
      tFlash1.scale = vector(0.001, 0.001, 0.001)
      tFlash2.scale = vector(0.001, 0.001, 0.001)
      tBulletT.scale = vector(0.001, 0.001, 0.001)
    end if
  else
    tFlash1.scale = vector(0.001, 0.001, 0.001)
    tFlash2.scale = vector(0.001, 0.001, 0.001)
    tBulletT.scale = vector(0.001, 0.001, 0.001)
    if (t[#sound] <> VOID) and (gSound.mute = 0) then
      t.sound.primary.volume = 0
    end if
    tData.rof[1] = tData.rof[2]
  end if
end

on reset_machinegun me, t
  gGame.member.deleteModel(t.Weapons.MachineGun.Flash1.name)
  gGame.member.deleteModel(t.Weapons.MachineGun.Flash2.name)
  gGame.member.deleteModel(t.Weapons.MachineGun.bullet.name)
  if t[#sound] <> VOID then
    t.sound.Mixer.deleteSoundObject(t.sound.primary)
  end if
  t.Weapons.deleteProp(#MachineGun)
  t.Weapons.States.deleteOne(#update_machinegun)
end

on setup_dualMachinegun me, t
  tData = gData.data.PrimaryWeapons.DualMachineGun.duplicate()
  t.Weapons[#DualMachineGun] = [#rof1: [integer(gGame.tempo / float(tData.rof) * 0.5), integer(gGame.tempo / float(tData.rof))], #rof2: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.primary[1], #damage: tData.damage]
  BuildWeapon(0, t, #primary, ["DualMachineGun"])
  repeat with i = 1 to 2
    tSymbol = symbol("RightFlash" & i)
    t.Weapons.DualMachineGun[tSymbol] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["DualMachineGunMuzzleFlashRight" & i], #NameTag: string(t.general.tag), #lod: 0])
    t.Weapons.DualMachineGun[tSymbol].parent = t.car.Effects.primary[2]
    t.Weapons.DualMachineGun[tSymbol].transform.position = vector()
    t.Weapons.DualMachineGun[tSymbol].transform.scale = vector(0.001, 0.001, 0.001)
    t.Weapons.DualMachineGun[symbol("RightFlash" & i & "Scale")] = vector(1, 1, 1)
  end repeat
  repeat with i = 1 to 2
    tSymbol = symbol("LeftFlash" & i)
    t.Weapons.DualMachineGun[tSymbol] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["DualMachineGunMuzzleFlashLeft" & i], #NameTag: string(t.general.tag), #lod: 0])
    t.Weapons.DualMachineGun[tSymbol].parent = t.car.Effects.primary[1]
    t.Weapons.DualMachineGun[tSymbol].transform.position = vector()
    t.Weapons.DualMachineGun[tSymbol].transform.scale = vector(0.001, 0.001, 0.001)
    t.Weapons.DualMachineGun[symbol("LeftFlash" & i & "Scale")] = vector(1, 1, 1)
  end repeat
  if t[#sound] <> VOID then
    t.sound[#primary] = t.sound.Mixer.createSoundObject("Primary1", member("MachineGun_SFX"), [#loopCount: 0])
    t.sound.primary.play()
    t.sound.primary.volume = 0
  end if
  t.Weapons.DualMachineGun[#bullet1] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Bullet"], #NameTag: string(t.general.tag) & "1", #hide: 1, #lod: 0])
  t.Weapons.DualMachineGun[#bullet2] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Bullet"], #NameTag: string(t.general.tag) & "2", #hide: 1, #lod: 0])
  t.Weapons.DualMachineGun[#BulletScale1] = 1.0
  t.Weapons.DualMachineGun[#BulletScale2] = 1.0
end

on update_dualMachinegun me, t
  tData = t.Weapons.DualMachineGun
  repeat with i = 1 to 2
    tProp = symbol("Rof" & i)
    tRof = tData[tProp]
    tBullet = tData[symbol("Bullet" & i)]
    tBulletT = tBullet.transform
    if i = 1 then
      tString = "RightFlash"
    else
      tString = "LeftFlash"
    end if
    tFlash1 = tData[symbol(tString & "1")].transform
    tFlash2 = tData[symbol(tString & "2")].transform
    tTransform = t.car.Effects.primary[i].getWorldTransform().duplicate()
    tDirection = tTransform.yAxis
    if t.input.action1 = 1 then
      if tData.ammo[1] > 0 then
        tRof[1] = tRof[1] + gGame.TimeMP
        if tRof[1] >= tRof[2] then
          tRof[1] = 0.0
          tData.ammo[1] = tData.ammo[1] - 1
          if (tData.ammo[1] = 0) and (tData.clips > 0) then
            tData.ammo[1] = tData.ammo[2]
            tData.clips = tData.clips - 1
          end if
          if t.general.controller = #player then
            gGame.Statistics.bullets = gGame.Statistics.bullets + 1
          end if
          if (gGame.Statistics.bullets >= gGame.GodOfWarBullets) and (gGame.Trophies.godofwar = 0) then
            DoTrophy(0, #godofwar)
          end if
          tFlash2.scale = vector(1.5, 1.5, 1.5)
          tFlash2.rotation.y = random(1, 120)
          tRandom = random(1000, 1400) * 0.001
          tData[symbol(tString & i & "Scale")] = vector(tRandom, tRandom * 1.5, tRandom)
          tFlash1.scale = tData[symbol(tString & i & "Scale")]
          tFlash1.rotation.y = random(1, 45)
          if (t[#sound] <> VOID) and (gSound.mute = 0) then
            t.sound.primary.volume = 180
          end if
          tBullet.addToWorld()
          tBullet.transform = tTransform.duplicate()
          tBulletT.scale.y = 100
          tBulletT.position = tTransform.position + (100 * tDirection)
          tData[symbol("BulletScale" & i)] = 100
          tDetails = gGame.Physics.rayCastClosest(tTransform.position, tDirection)
          if tDetails.count > 0 then
            tBulletT.scale.y = tDetails[4]
            tBulletT.position = tTransform.position + (tDetails[4] * tDirection)
            tData[symbol("BulletScale" & i)] = tDetails[4]
            tDetails.add(random(tData.damage[1], tData.damage[2]))
            tDetails.add(t.general.tag)
            gGame.BulletHits.add(tDetails)
          end if
        else
          tPerc = 1.0 - (tRof[1] / tRof[2])
          tPerc = max(tPerc, 0.001)
          tFlash1.scale = tData[symbol(tString & i & "Scale")] * tPerc
          tBulletScale = tData[symbol("BulletScale" & i)] * tPerc
          if tBulletScale < 0.001 then
            tBulletScale = 0.001
          end if
          tBulletT.scale.y = tBulletScale
          if tRof[1] <= (tRof[2] * 0.5) then
            tPerc = 1.0 - (tRof[1] / (tRof[2] * 0.5))
            tPerc = max(tPerc, 0.001)
            tFlash2.scale = vector(1.39999999999999991, 1.39999999999999991, 1.39999999999999991) * tPerc
          else
            tPerc = (tRof[1] - (tRof[2] * 0.5)) / (tRof[2] * 0.5)
            tPerc = max(tPerc, 0.001)
            tFlash2.scale = vector(1.39999999999999991, 1.39999999999999991, 1.39999999999999991) * tPerc
          end if
        end if
      else
        tFlash1.scale = vector(0.001, 0.001, 0.001)
        tFlash2.scale = vector(0.001, 0.001, 0.001)
        tBulletT.scale = vector(0.001, 0.001, 0.001)
        if (t[#sound] <> VOID) and (gSound.mute = 0) then
          t.sound.primary.volume = 0
        end if
      end if
      next repeat
    end if
    tFlash1.scale = vector(0.001, 0.001, 0.001)
    tFlash2.scale = vector(0.001, 0.001, 0.001)
    tBulletT.scale = vector(0.001, 0.001, 0.001)
    if (t[#sound] <> VOID) and (gSound.mute = 0) then
      t.sound.primary.volume = 0
    end if
    if i = 1 then
      tRof[1] = tRof[2] * 0.5
      next repeat
    end if
    tRof[1] = tRof[2]
  end repeat
end

on reset_dualmachinegun me, t
  gGame.member.deleteModel(t.Weapons.DualMachineGun.RightFlash1.name)
  gGame.member.deleteModel(t.Weapons.DualMachineGun.RightFlash2.name)
  gGame.member.deleteModel(t.Weapons.DualMachineGun.LeftFlash1.name)
  gGame.member.deleteModel(t.Weapons.DualMachineGun.LeftFlash2.name)
  gGame.member.deleteModel(t.Weapons.DualMachineGun.bullet1.name)
  gGame.member.deleteModel(t.Weapons.DualMachineGun.bullet2.name)
  if t[#sound] <> VOID then
    t.sound.Mixer.deleteSoundObject(t.sound.primary)
  end if
  t.Weapons.deleteProp(#DualMachineGun)
  t.Weapons.States.deleteOne(#update_dualMachinegun)
end

on setup_minigun me, t
  tData = gData.data.PrimaryWeapons.MiniGun.duplicate()
  t.Weapons[#MiniGun] = [#rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.primary[1], #damage: tData.damage, #chargeTime: [0, tData.chargeTime * gGame.tempo]]
  BuildWeapon(0, t, #primary, ["MiniGun", "MiniGunBarrel"])
  tmodel = gGame.member.model(string(t.general.tag) & "MiniGunBarrel")
  tmodel.transform = member("Weapons").model("MiniGun").getWorldTransform().inverse() * member("Weapons").model("MiniGunBarrel").transform
  tmodel.parent = gGame.member.model(string(t.general.tag) & "MiniGun")
  t.Weapons.MiniGun[#Barrel] = tmodel
  t.Weapons.MiniGun[#Flash1] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["MiniGunMuzzleFlash1"], #NameTag: string(t.general.tag), #lod: 0])
  t.Weapons.MiniGun.Flash1.parent = t.car.Effects.primary[1]
  t.Weapons.MiniGun.Flash1.transform.position = vector()
  t.Weapons.MiniGun.Flash1.transform.scale = vector(0.001, 0.001, 0.001)
  t.Weapons.MiniGun[#Flash1Scale] = vector(1, 1, 1)
  if t[#sound] <> VOID then
    t.sound[#primary] = t.sound.Mixer.createSoundObject("Primary", member("MiniGun_SFX"), [#loopCount: 0])
    t.sound.primary.volume = 0
    t.sound.primary.play()
  end if
  t.Weapons.MiniGun[#bullet] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Bullet"], #NameTag: string(t.general.tag), #hide: 1, #lod: 0])
  t.Weapons.MiniGun[#BulletScale] = 1.0
end

on update_minigun me, t
  tData = t.Weapons.MiniGun
  tTransform = t.car.Effects.primary[1].getWorldTransform().duplicate()
  tDirection = tTransform.yAxis
  tBullet = tData.bullet
  tBulletT = tBullet.transform
  tFlash1 = tData.Flash1.transform
  if t.input.action1 = 1 then
    if tData.chargeTime[1] < tData.chargeTime[2] then
      tData.chargeTime[1] = tData.chargeTime[1] + gGame.TimeMP
      t.Weapons.MiniGun.Barrel.rotate(vector(0, tData.chargeTime[1] * gGame.TimeMP, 0), #self)
    else
      if tData.ammo[1] > 0 then
        tData.rof[1] = tData.rof[1] + gGame.TimeMP
        t.Weapons.MiniGun.Barrel.rotate(vector(0, tData.chargeTime[1] * gGame.TimeMP, 0), #self)
        if tData.rof[1] >= tData.rof[2] then
          tData.rof[1] = 0
          tData.ammo[1] = tData.ammo[1] - 1
          if (tData.ammo[1] = 0) and (tData.clips > 0) then
            tData.ammo[1] = tData.ammo[2]
            tData.clips = tData.clips - 1
          end if
          if t.general.controller = #player then
            gGame.Statistics.bullets = gGame.Statistics.bullets + 1
          end if
          if (gGame.Statistics.bullets >= gGame.GodOfWarBullets) and (gGame.Trophies.godofwar = 0) then
            DoTrophy(0, #godofwar)
          end if
          tRandom = random(1000, 1400) * 0.001
          tData.Flash1Scale = vector(tRandom, tRandom * 1.5, tRandom)
          tFlash1.scale = tData.Flash1Scale
          tFlash1.rotation.y = random(1, 45)
          if (t[#sound] <> VOID) and (gSound.mute = 0) then
            t.sound.primary.volume = 180
          end if
          tBullet.addToWorld()
          tBullet.transform = tTransform.duplicate()
          tBulletT.scale.y = 100
          tBulletT.position = tTransform.position + (100 * tDirection)
          tData.BulletScale = 100
          tDetails = gGame.Physics.rayCastClosest(tTransform.position, tDirection)
          if tDetails.count > 0 then
            tBulletT.scale.y = tDetails[4]
            tBulletT.position = tTransform.position + (tDetails[4] * tDirection)
            tData.BulletScale = tDetails[4]
            tDetails.add(random(tData.damage[1], tData.damage[2]))
            tDetails.add(t.general.tag)
            gGame.BulletHits.add(tDetails)
          end if
        else
          tPerc = 1.0 - (tData.rof[1] / tData.rof[2])
          tPerc = max(tPerc, 0.001)
          tFlash1.scale = tData.Flash1Scale * tPerc
          tBulletScale = tData.BulletScale * tPerc
          if tBulletScale < 0.001 then
            tBulletScale = 0.001
          end if
          tBulletT.scale.y = tBulletScale
        end if
      else
        if (t[#sound] <> VOID) and (gSound.mute = 0) then
          t.sound.primary.volume = 0
        end if
        tFlash1.scale = vector(0.001, 0.001, 0.001)
        tBulletT.scale = vector(0.001, 0.001, 0.001)
      end if
    end if
  else
    if tData.chargeTime[1] > 0 then
      tData.chargeTime[1] = tData.chargeTime[1] - gGame.TimeMP
    end if
    t.Weapons.MiniGun.Barrel.rotate(vector(0, tData.chargeTime[1] * gGame.TimeMP, 0), #self)
    tFlash1.scale = vector(0.001, 0.001, 0.001)
    tBulletT.scale = vector(0.001, 0.001, 0.001)
    if (t[#sound] <> VOID) and (gSound.mute = 0) then
      t.sound.primary.volume = 0
    end if
    tData.rof[1] = tData.rof[2]
  end if
end

on reset_miniGun me, t
  gGame.member.deleteModel(t.Weapons.MiniGun.Flash1.name)
  gGame.member.deleteModel(t.Weapons.MiniGun.bullet.name)
  if t[#sound] <> VOID then
    t.sound.Mixer.deleteSoundObject(t.sound.primary)
  end if
  t.Weapons.deleteProp(#MiniGun)
  t.Weapons.States.deleteOne(#update_minigun)
end

on Setup_DualMiniGun me, t
  tData = gData.data.PrimaryWeapons.DualMiniGun.duplicate()
  t.Weapons[#DualMiniGun] = [#rof1: [integer(gGame.tempo / float(tData.rof) * 0.5), integer(gGame.tempo / float(tData.rof))], #rof2: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.primary[1], #damage: tData.damage, #chargeTime: [0, tData.chargeTime * gGame.tempo]]
  BuildWeapon(0, t, #primary, ["DualMiniGun"])
  CloneModel(0, gGame.member.name, [#sourceMember: "Weapons", #model: ["DualMiniGunBarrel1", "DualMiniGunBarrel2"], #NameTag: string(t.general.tag), #shaderTag: string(t.general.tag), #lod: 0])
  repeat with i = 1 to 2
    tmodel = gGame.member.model(string(t.general.tag) & "DualMiniGunBarrel" & i)
    tmodel.transform = member("Weapons").model("DualMiniGun").getWorldTransform().inverse() * member("Weapons").model("DualMiniGunBarrel" & i).transform
    tmodel.parent = gGame.member.model(string(t.general.tag) & "DualMiniGun")
    t.Weapons.DualMiniGun[symbol("Barrel" & i)] = tmodel
    tProp = symbol("Flash" & i)
    t.Weapons.DualMiniGun[tProp] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["DualMiniGunMuzzleFlash" & i], #NameTag: string(t.general.tag), #lod: 0])
    t.Weapons.DualMiniGun[tProp].parent = t.car.Effects.primary[i]
    t.Weapons.DualMiniGun[tProp].transform.position = vector()
    t.Weapons.DualMiniGun[tProp].transform.scale = vector(0.001, 0.001, 0.001)
    t.Weapons.DualMiniGun[symbol("Flash" & i & "Scale")] = vector(1, 1, 1)
  end repeat
  if t[#sound] <> VOID then
    t.sound[#primary] = t.sound.Mixer.createSoundObject("Primary1", member("MiniGun_SFX"), [#loopCount: 0])
    t.sound.primary.play()
    t.sound.primary.volume = 0
  end if
  t.Weapons.DualMiniGun[#bullet1] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Bullet"], #NameTag: string(t.general.tag) & "1", #hide: 1, #lod: 0])
  t.Weapons.DualMiniGun[#bullet2] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Bullet"], #NameTag: string(t.general.tag) & "2", #hide: 1, #lod: 0])
  t.Weapons.DualMiniGun[#BulletScale1] = 1.0
  t.Weapons.DualMiniGun[#BulletScale2] = 1.0
end

on update_dualMiniGun me, t
  tData = t.Weapons.DualMiniGun
  repeat with i = 1 to 2
    tProp = symbol("Rof" & i)
    tRof = tData[tProp]
    tBullet = tData[symbol("Bullet" & i)]
    tBulletT = tBullet.transform
    tFlash1 = tData[symbol("Flash" & i)].transform
    tFlash1Scale = tData[symbol("Flash" & i & "Scale")]
    tBarrel = tData[symbol("Barrel" & i)]
    tTransform = t.car.Effects.primary[i].getWorldTransform().duplicate()
    tDirection = tTransform.yAxis
    if t.input.action1 = 1 then
      if tData.chargeTime[1] < tData.chargeTime[2] then
        tData.chargeTime[1] = tData.chargeTime[1] + gGame.TimeMP
        tBarrel.rotate(vector(0, tData.chargeTime[1] * gGame.TimeMP, 0), #self)
      else
        if tData.ammo[1] > 0 then
          tRof[1] = tRof[1] + gGame.TimeMP
          tBarrel.rotate(vector(0, tData.chargeTime[1] * gGame.TimeMP, 0), #self)
          if tRof[1] >= tRof[2] then
            tRof[1] = 0.0
            tData.ammo[1] = tData.ammo[1] - 1
            if (tData.ammo[1] = 0) and (tData.clips > 0) then
              tData.ammo[1] = tData.ammo[2]
              tData.clips = tData.clips - 1
            end if
            if t.general.controller = #player then
              gGame.Statistics.bullets = gGame.Statistics.bullets + 1
            end if
            if (gGame.Statistics.bullets >= gGame.GodOfWarBullets) and (gGame.Trophies.godofwar = 0) then
              DoTrophy(0, #godofwar)
            end if
            tRandom = random(1000, 1400) * 0.001
            tFlash1Scale = vector(tRandom, tRandom * 1.5, tRandom)
            tFlash1.scale = tFlash1Scale
            tFlash1.rotation.y = random(1, 45)
            if (t[#sound] <> VOID) and (gSound.mute = 0) then
              t.sound.primary.volume = 180
            end if
            tBullet.addToWorld()
            tBullet.transform = tTransform.duplicate()
            tBulletT.scale.y = 100
            tBulletT.position = tTransform.position + (100 * tDirection)
            tData[symbol("BulletScale" & i)] = 100
            tDetails = gGame.Physics.rayCastClosest(tTransform.position, tDirection)
            if tDetails.count > 0 then
              tBulletT.scale.y = tDetails[4]
              tBulletT.position = tTransform.position + (tDetails[4] * tDirection)
              tData[symbol("BulletScale" & i)] = tDetails[4]
              tDetails.add(random(tData.damage[1], tData.damage[2]))
              tDetails.add(t.general.tag)
              gGame.BulletHits.add(tDetails)
            end if
          else
            tPerc = 1.0 - (tRof[1] / tRof[2])
            tPerc = max(tPerc, 0.001)
            tFlash1.scale = tFlash1Scale * tPerc
            tBulletScale = tData[symbol("BulletScale" & i)] * tPerc
            if tBulletScale < 0.001 then
              tBulletScale = 0.001
            end if
            tBulletT.scale.y = tBulletScale
          end if
        else
          tFlash1.scale = vector(0.001, 0.001, 0.001)
          tBulletT.scale = vector(0.001, 0.001, 0.001)
          if (t[#sound] <> VOID) and (gSound.mute = 0) then
            t.sound.primary.volume = 0
          end if
        end if
      end if
      next repeat
    end if
    tFlash1.scale = vector(0.001, 0.001, 0.001)
    tBulletT.scale = vector(0.001, 0.001, 0.001)
    if tData.chargeTime[1] > 0 then
      tData.chargeTime[1] = tData.chargeTime[1] - gGame.TimeMP
    end if
    tBarrel.rotate(vector(0, tData.chargeTime[1] * gGame.TimeMP, 0), #self)
    if (t[#sound] <> VOID) and (gSound.mute = 0) then
      t.sound.primary.volume = 0
    end if
    if i = 1 then
      tRof[1] = tRof[2] * 0.5
      next repeat
    end if
    tRof[1] = tRof[2]
  end repeat
end

on reset_dualMiniGun me, t
  gGame.member.deleteModel(t.Weapons.DualMiniGun.Flash1.name)
  gGame.member.deleteModel(t.Weapons.DualMiniGun.Flash2.name)
  gGame.member.deleteModel(t.Weapons.DualMiniGun.bullet1.name)
  gGame.member.deleteModel(t.Weapons.DualMiniGun.bullet2.name)
  if t[#sound] <> VOID then
    t.sound.Mixer.deleteSoundObject(t.sound.primary)
  end if
  t.Weapons.deleteProp(#DualMiniGun)
  t.Weapons.States.deleteOne(#update_dualMiniGun)
end

on Setup_Laser me, t
  tData = gData.data.PrimaryWeapons.Laser.duplicate()
  t.Weapons[#Laser] = [#fire: 0, #rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.primary[1], #damage: [tData.damage[1], tData.damage[2]], #chargedDamage: 1, #chargeTime: [0, tData.chargeTime * gGame.tempo]]
  BuildWeapon(0, t, #primary, ["Laser", "LaserCharge", "LaserBeam"])
  repeat with i = 1 to 2
    tmodel = gGame.member.model(string(t.general.tag) & "LaserCharge")
    tmodel.transform = member("Weapons").model("Laser").getWorldTransform().inverse() * member("Weapons").model("LaserCharge").transform
    tmodel.parent = gGame.member.model(string(t.general.tag) & "Laser")
    tmodel.transform.scale = vector(1, 1, 1) * 0.001
    t.Weapons.Laser[#laserCharge] = tmodel
    tmodel = gGame.member.model(string(t.general.tag) & "LaserBeam")
    tmodel.transform = member("Weapons").model("Laser").getWorldTransform().inverse() * member("Weapons").model("LaserBeam").transform
    tmodel.parent = gGame.member.model(string(t.general.tag) & "Laser")
    tmodel.transform.scale = vector(1, 1, 1) * 0.001
    t.Weapons.Laser[#laserBeam] = tmodel
  end repeat
end

on update_laser me, t
  tData = t.Weapons.Laser
  tTransform = t.car.Effects.primary[1].getWorldTransform().duplicate()
  tDirection = tTransform.yAxis
  tFire = tData.fire
  tCharge = tData.laserCharge
  tBeam = tData.laserBeam
  if t.input.action1 = 1 then
    if tData.chargeTime[1] < tData.chargeTime[2] then
      tData.chargeTime[1] = tData.chargeTime[1] + gGame.TimeMP
      tData.chargedDamage = tData.damage[2] * (tData.chargeTime[1] / tData.chargeTime[2])
      put tData.chargedDamage
      tCharge.transform.scale = vector(1, 1, 1) * (tData.chargeTime[1] / tData.chargeTime[2])
      tFire = 1
    end if
  else
    if (tFire = 1) and (tData.chargedDamage > 0) then
      tData.chargedDamage = tData.chargedDamage - (gGame.TimeMP * 0.5)
      if tData.chargedDamage <= 0 then
        tFire = 0
        tData.chargeTime[1] = 0
        tData.chargedDamage = 0
        tCharge.transform.scale = vector(1, 1, 1) * 0.001
        tBeam.transform.scale = vector(1, 1, 1) * 0.001
      else
        tPerc = tData.chargedDamage / tData.damage[2]
        tCharge.transform.scale = vector(1, 1, 1) * tPerc
        tDetails = gGame.Physics.rayCastClosest(tTransform.position, tDirection)
        if tDetails.count > 0 then
          tBeam.transform.scale = vector(1, 1, 1) * tPerc
          tBeam.transform.scale.y = tDetails[4]
          tDetails.add(tData.chargedDamage)
          tDetails.add(t.general.tag)
          gGame.BulletHits.add(tDetails)
        end if
      end if
    end if
  end if
  t.Weapons.Laser.fire = tFire
end

on reset_laser me, t
  gGame.member.deleteModel(t.Weapons.Laser.laserCharge.name)
  gGame.member.deleteModel(t.Weapons.Laser.laserBeam.name)
  if t[#sound] <> VOID then
    t.sound.Mixer.deleteSoundObject(t.sound.primary)
  end if
  t.Weapons.deleteProp(#Laser)
  t.Weapons.States.deleteOne(#update_laser)
end

on Setup_RocketPod me, t
  tData = gData.data.SecondaryWeapons.RocketPod.duplicate()
  t.Weapons[#RocketPod] = [#pod: [0, 2], #rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.secondary[1], #damage: tData.damage, #areaDamage: tData.areaDamage]
  BuildWeapon(0, t, #secondary, ["RocketPodLeft", "RocketPodRight"])
  if t.car.name = "Apache" then
    gGame.member.model(string(t.general.tag) & "RocketPodLeft").removeFromWorld()
  end if
  if t.car.name = "Apache" then
    gGame.member.model(string(t.general.tag) & "RocketPodRight").removeFromWorld()
  end if
  if t.general.member.model("Rocket") = VOID then
    tModelList = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Rocket", "RocketFlame"], #hide: 1, #lod: 0, #delete: 1])
    BlendShader(t.general.member.name, [#materialName: "RocketFlame_Material", #blendMode: #add])
  end if
end

on update_rocketPod me, t
  tData = t.Weapons.RocketPod
  if t.input.action2 = 1 then
    tData.rof[1] = tData.rof[1] + gGame.TimeMP
    if tData.rof[1] >= tData.rof[2] then
      tData.rof[1] = 0.0
      if tData.ammo[1] > 0 then
        tData.ammo[1] = tData.ammo[1] - 1
        if (tData.ammo[1] = 0) and (tData.clips > 0) then
          tData.ammo[1] = tData.ammo[2]
          tData.clips = tData.clips - 1
        end if
        tData.pod[1] = tData.pod[1] + 1
        if tData.pod[1] > tData.pod[2] then
          tData.pod[1] = 1
        end if
        tScript = new(script("[PS] Rocket"), t, tData.pod[1])
        if tScript <> VOID then
          gGame.scriptList.add(tScript)
        end if
      end if
    end if
  else
    tData.rof[1] = tData.rof[2]
  end if
end

on reset_rocketPod me, t
  t.Weapons.deleteProp(#RocketPod)
  t.Weapons.States.deleteOne(#update_rocketPod)
end

on setup_MineDeployer me, t
  tData = gData.data.SecondaryWeapons.mineDeployer.duplicate()
  t.Weapons[#mineDeployer] = [#pod: [0, 2], #rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.secondary[1], #damage: tData.damage, #areaDamage: tData.areaDamage]
  BuildWeapon(0, t, #secondary, ["MineDeployer"])
  if t.general.member.model("Mine") = VOID then
    tModelList = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Mine"], #hide: 1, #lod: 0, #delete: 1])
  end if
end

on update_MineDeployer me, t
  tData = t.Weapons.mineDeployer
  if t.input.action2 = 1 then
    tData.rof[1] = tData.rof[1] + gGame.TimeMP
    if tData.rof[1] >= tData.rof[2] then
      tData.rof[1] = 0.0
      if tData.ammo[1] > 0 then
        tData.ammo[1] = tData.ammo[1] - 1
        if (tData.ammo[1] = 0) and (tData.clips > 0) then
          tData.ammo[1] = tData.ammo[2]
          tData.clips = tData.clips - 1
        end if
        tScript = new(script("[PS] Mine"), t)
        if tScript <> VOID then
          gGame.scriptList.add(tScript)
        end if
      end if
    end if
  else
    tData.rof[1] = tData.rof[2]
  end if
end

on reset_MineDeployer me, t
  t.Weapons.deleteProp(#mineDeployer)
  t.Weapons.States.deleteOne(#update_MineDeployer)
end

on setup_GrenadeDeployer me, t
  tData = gData.data.SecondaryWeapons.GrenadeDeployer.duplicate()
  t.Weapons[#GrenadeDeployer] = [#pod: [0, 2], #rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.secondary[1], #damage: tData.damage, #areaDamage: tData.areaDamage]
  BuildWeapon(0, t, #secondary, ["GrenadeDeployer"])
  if t.general.member.model("Grenade1") = VOID then
    tModelList = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Grenade1"], #hide: 1, #lod: 0, #delete: 1])
  end if
end

on update_GrenadeDeployer me, t
  tData = t.Weapons.GrenadeDeployer
  if t.input.action2 = 1 then
    tData.rof[1] = tData.rof[1] + gGame.TimeMP
    if tData.rof[1] >= tData.rof[2] then
      tData.rof[1] = 0.0
      if tData.ammo[1] > 0 then
        tData.ammo[1] = tData.ammo[1] - 5
        if (tData.ammo[1] = 0) and (tData.clips > 0) then
          tData.ammo[1] = tData.ammo[2]
          tData.clips = tData.clips - 1
        end if
        tScript = new(script("[PS] Grenades"), t)
        if tScript <> VOID then
          gGame.scriptList.add(tScript)
        end if
      end if
    end if
  else
    tData.rof[1] = tData.rof[2]
  end if
end

on reset_GrenadeDeployer me, t
  t.Weapons.deleteProp(#mineDeployer)
  t.Weapons.States.deleteOne(#update_MineDeployer)
end

on setup_GrenadeLauncher me, t
  tData = gData.data.SecondaryWeapons.GrenadeLauncher.duplicate()
  t.Weapons[#GrenadeLauncher] = [#pod: [0, 2], #rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.secondary[1], #damage: tData.damage, #areaDamage: tData.areaDamage]
  BuildWeapon(0, t, #secondary, ["GrenadeLauncher"])
  if t.general.member.model("Grenade") = VOID then
    tModelList = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Grenade"], #hide: 1, #lod: 0, #delete: 1])
  end if
  t.Weapons.GrenadeLauncher[#flash] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["GrenadeLauncherMuzzleFlash"], #NameTag: string(t.general.tag), #lod: 0])
  t.Weapons.GrenadeLauncher.flash.transform = t.car.Effects.secondary[1].transform
  t.Weapons.GrenadeLauncher.flash.parent = t.car.Effects.secondary[1]
  t.Weapons.GrenadeLauncher.flash.transform.position = vector()
  t.Weapons.GrenadeLauncher.flash.transform.scale = vector(0.001, 0.001, 0.001)
  t.Weapons.GrenadeLauncher[#FlashScale] = vector(1, 1, 1)
end

on update_GrenadeLauncher me, t
  tData = t.Weapons.GrenadeLauncher
  tFlash = tData.flash.transform
  if t.input.action2 = 1 then
    if tData.ammo[1] > 0 then
      tData.rof[1] = tData.rof[1] + gGame.TimeMP
      if tData.rof[1] >= tData.rof[2] then
        tData.rof[1] = 0
        tData.ammo[1] = tData.ammo[1] - 1
        if (tData.ammo[1] = 0) and (tData.clips > 0) then
          tData.ammo[1] = tData.ammo[2]
          tData.clips = tData.clips - 1
        end if
        tRandom = random(2000, 2400) * 0.001
        tData.FlashScale = vector(tRandom, tRandom * 1.5, tRandom)
        tFlash.scale = tData.FlashScale
        tFlash.rotation.y = random(1, 45)
        tScript = new(script("[PS] Grenade"), t)
        if tScript <> VOID then
          gGame.scriptList.add(tScript)
        end if
      else
        if tData.rof[1] <= 3 then
          tPerc = 1.0 - (tData.rof[1] / 3)
          tPerc = max(tPerc, 0.001)
          tScaleXZ = tData.FlashScale.x * tPerc
          tScaleXZ = max(tScaleXZ, 0.001)
          if tScaleXZ = 0.001 then
            tScale = vector(tScaleXZ, tScaleXZ, tScaleXZ)
          else
            tScale = vector(tScaleXZ, tScaleXZ * 5, tScaleXZ)
          end if
          tFlash.scale = tScale
        else
          tFlash.scale = vector(0.001, 0.001, 0.001)
        end if
      end if
    else
      if tData.rof[1] <= 3 then
        tPerc = 1.0 - (tData.rof[1] / 3)
        tPerc = max(tPerc, 0.001)
        tScaleXZ = tData.FlashScale.x * tPerc
        tScaleXZ = max(tScaleXZ, 0.001)
        if tScaleXZ = 0.001 then
          tScale = vector(tScaleXZ, tScaleXZ, tScaleXZ)
        else
          tScale = vector(tScaleXZ, tScaleXZ * 5, tScaleXZ)
        end if
        tFlash.scale = tScale
      else
        tFlash.scale = vector(0.001, 0.001, 0.001)
      end if
    end if
  else
    if tData.rof[1] <= 3 then
      tPerc = 1.0 - (tData.rof[1] / 3)
      tPerc = max(tPerc, 0.001)
      tScaleXZ = tData.FlashScale.x * tPerc
      tScaleXZ = max(tScaleXZ, 0.001)
      if tScaleXZ = 0.001 then
        tScale = vector(tScaleXZ, tScaleXZ, tScaleXZ)
      else
        tScale = vector(tScaleXZ, tScaleXZ * 5, tScaleXZ)
      end if
    else
      tFlash.scale = vector(0.001, 0.001, 0.001)
    end if
    tData.rof[1] = tData.rof[2]
  end if
end

on GrenadeLauncher me, t
  t.Weapons.deleteProp(#GrenadeLauncher)
  t.Weapons.States.deleteOne(#update_GrenadeLauncher)
end

on setup_airstrikeLauncher me, t
  tData = gData.data.SecondaryWeapons.AirstrikeLauncher.duplicate()
  t.Weapons[#AirstrikeLauncher] = [#delay: [0, 45], #fire: 1, #rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.secondary[1], #damage: tData.damage, #areaDamage: tData.areaDamage]
  BuildWeapon(0, t, #secondary, ["AirstrikeLauncher"])
  if t.general.member.model("AirstrikeBeacon") = VOID then
    tmodel = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["AirstrikeBeacon"]])
    tmodel.parent = VOID
  end if
end

on update_AirstrikeLauncher me, t
  tDelay = t.Weapons.AirstrikeLauncher.delay[1]
  tFire = t.Weapons.AirstrikeLauncher.fire
  if tDelay > 0 then
    tDelay = tDelay - (1 * gGame.TimeMP)
    tDelay = max(0, tDelay)
    if tDelay = 0 then
      tFire = 1
    end if
  end if
  if (t.input.action2 = 1) and (tDelay = 0) and (tFire = 1) then
    tScript = new(script("[PS] Airstrike Beacon"), t)
    if tScript <> VOID then
      gGame.scriptList.add(tScript)
    end if
    tFire = 0
    tDelay = t.Weapons.AirstrikeLauncher.delay[2]
  end if
  t.Weapons.AirstrikeLauncher.delay[1] = tDelay
  t.Weapons.AirstrikeLauncher.fire = tFire
end

on Setup_MainGun me, t
  tData = gData.data.SecondaryWeapons.MainGun.duplicate()
  t.Weapons[#MainGun] = [#rof: [0.0, integer(gGame.tempo / float(tData.rof))], #ammo: [tData.ammo, tData.ammo], #clips: t.general.data.upgrades.secondary[1], #damage: tData.damage, #areaDamage: tData.areaDamage]
  if t.general.member.model("Shell") = VOID then
    tModelList = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["Shell"], #hide: 1, #lod: 0, #delete: 1])
  end if
  BuildWeapon(0, t, #secondary, ["MainGun"])
  t.Weapons.MainGun[#turret] = gGame.member.model(string(t.general.tag) & "Glass")
  t.Weapons.MainGun.turret.pointAtOrientation = [vector(0.0, 1.0, 0.0), vector(0.0, 0.0, 1.0)]
  t.Weapons.MainGun[#flash] = CloneModel(0, t.general.member.name, [#sourceMember: "Weapons", #model: ["MainGunMuzzleFlash1"], #NameTag: string(t.general.tag), #lod: 0])
  t.Weapons.MainGun.flash.transform = t.car.Effects.secondary[1].transform
  t.Weapons.MainGun.flash.parent = t.car.Effects.secondary[1]
  t.Weapons.MainGun.flash.transform.position = vector()
  t.Weapons.MainGun.flash.transform.scale = vector(0.001, 0.001, 0.001)
  t.Weapons.MainGun[#FlashScale] = vector(1, 1, 1)
  t.car.Effects.primary[1].parent = gGame.member.model(string(t.general.tag) & "Glass")
  t.car.Effects.secondary[1].parent = gGame.member.model(string(t.general.tag) & "Glass")
  gGame.member.model(string(t.general.tag) & "MachineGun").removeFromWorld()
  gGame.member.model(string(t.general.tag) & "MainGun").removeFromWorld()
  t.car.Effects.primary[1].transform.rotation = vector(-0.69999999999999996, 0, 0)
  t.car.Effects.secondary[1].transform.rotation = vector(-0.69999999999999996, 0, 0)
end

on update_MainGun me, t
  tData = t.Weapons.MainGun
  tTransform = t.car.Effects.secondary[1].getWorldTransform().duplicate()
  tDirection = tTransform.yAxis
  tFlash = tData.flash.transform
  if t.input.action2 = 1 then
    if tData.ammo[1] > 0 then
      tData.rof[1] = tData.rof[1] + gGame.TimeMP
      if tData.rof[1] >= tData.rof[2] then
        tData.rof[1] = 0
        tData.ammo[1] = tData.ammo[1] - 1
        if (tData.ammo[1] = 0) and (tData.clips > 0) then
          tData.ammo[1] = tData.ammo[2]
          tData.clips = tData.clips - 1
        end if
        tRandom = random(2000, 2400) * 0.001
        tData.FlashScale = vector(tRandom, tRandom * 1.5, tRandom)
        tFlash.scale = tData.FlashScale
        tFlash.rotation.y = random(1, 45)
        tDetails = gGame.Physics.rayCastClosest(tTransform.position, tDirection)
        if tDetails.count > 0 then
          tScript = new(script("[PS] Shell"), t)
          if tScript <> VOID then
            gGame.scriptList.add(tScript)
          end if
        end if
      else
        if tData.rof[1] <= 3 then
          tPerc = 1.0 - (tData.rof[1] / 3)
          tPerc = max(tPerc, 0.001)
          tScaleXZ = tData.FlashScale.x * tPerc
          tScaleXZ = max(tScaleXZ, 0.001)
          if tScaleXZ = 0.001 then
            tScale = vector(tScaleXZ, tScaleXZ, tScaleXZ)
          else
            tScale = vector(tScaleXZ, tScaleXZ * 7, tScaleXZ)
          end if
          tFlash.scale = tScale
        end if
      end if
    else
      if tData.rof[1] <= 3 then
        tPerc = 1.0 - (tData.rof[1] / 3)
        tPerc = max(tPerc, 0.001)
        tScaleXZ = tData.FlashScale.x * tPerc
        tScaleXZ = max(tScaleXZ, 0.001)
        if tScaleXZ = 0.001 then
          tScale = vector(tScaleXZ, tScaleXZ, tScaleXZ)
        else
          tScale = vector(tScaleXZ, tScaleXZ * 7, tScaleXZ)
        end if
        tFlash.scale = tScale
      end if
    end if
  else
    if tData.rof[1] <= 3 then
      tPerc = 1.0 - (tData.rof[1] / 3)
      tPerc = max(tPerc, 0.001)
      tScaleXZ = tData.FlashScale.x * tPerc
      tScaleXZ = max(tScaleXZ, 0.001)
      if tScaleXZ = 0.001 then
        tScale = vector(tScaleXZ, tScaleXZ, tScaleXZ)
      else
        tScale = vector(tScaleXZ, tScaleXZ * 7, tScaleXZ)
      end if
    else
      tFlash.scale = vector(0.001, 0.001, 0.001)
    end if
    tData.rof[1] = tData.rof[2]
  end if
end

on Reset_MainGun me, t
  gGame.member.deleteModel(t.Weapons.MainGun.flash.name)
  t.Weapons.deleteProp(#MainGun)
  t.Weapons.States.deleteOne(#update_MainGun)
end
