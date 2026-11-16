property p
global gSystem, gGame, gData

on new me, t, tPod
  p = [:]
  p[#member] = t.general.member
  p[#sender] = t.general.tag
  p[#model] = t.car.model
  p[#data] = gData.data.SecondaryWeapons.RocketPod
  p[#me] = me
  p[#RocketName] = string(p.sender) & "Rocket" & _system.milliSeconds
  p[#Rocket] = p.member.newModel(p.RocketName, p.member.modelResource("Rocket"))
  p.Rocket.shader = p.member.shader("Weapons_Material")
  p[#Flame] = p.member.newModel(p.RocketName & "Flame", p.member.modelResource("RocketFlame"))
  p.Flame.shader = p.member.shader("Effects_Material")
  p.Flame.parent = p.Rocket
  p.Flame.transform.position = p.Rocket.worldPosition - (p.Flame.transform.yAxis * 0.5)
  tTransform = t.car.Effects.secondary[tPod].getWorldTransform().duplicate()
  p.Rocket.transform = tTransform
  tOffset = randomVector() * 0.25
  p.Rocket.transform.position = p.Rocket.transform.position
  p.Rocket.transform.rotation = p.Rocket.transform.rotation + (tOffset * 1.10000000000000009)
  p[#VList] = [p.Rocket.transform.zAxis * 0.40000000000000002, -p.Rocket.transform.zAxis * 0.40000000000000002]
  p[#faces] = 0
  p[#FList] = []
  p[#tList] = []
  p[#TrailResource] = p.member.newMesh(p.RocketName & "Trail", 0, p.VList.count, 0, 0, p.tList.count)
  p[#Trail] = p.member.newModel(p.RocketName & "Trail", p.TrailResource)
  p[#shader] = CreateShader(0, p.member.name, [#shader: p.RocketName & "Trail_Material", #texture: "RocketTrail_Texture", #blend: 100.0])
  tTexture = p.member.texture("RocketTrail2_Texture")
  if tTexture = VOID then
    tTexture = createTexture(p.member.name, [#fileName: "RocketTrail2_Texture"])
  end if
  p.shader.textureList[2] = tTexture
  p.shader.textureModeList[2] = #wrapPlanar
  p.shader.wrapTransformList[2].rotation = p.Rocket.transform.rotation
  p.Trail.shader = p.shader
  p.Trail.transform.position = tTransform.position
  p.Trail.visibility = #both
  p[#alive] = 1
  p[#Speed] = 5.0
  p[#rotation] = 25
  p[#distance] = 0
  PlaySound("RocketPodLaunch_SFX", [#priority: #low, #surround: 1, #member3DName: gGame.member.name, #sender: t.car.Proxy.name, #targetName: t.car.Proxy.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 0, #Override: 1])
  p[#timeout] = 4 * gGame.tempo
  return me
end

on enterFrame me
  if gGame.pause = 1 then
    exit
  end if
  if p.alive = 1 then
    p.Rocket.translate(0, p.Speed * gGame.TimeMP, 0, #self)
    p.Rocket.rotate(0, p.rotation * gGame.TimeMP, 0, #self)
    p.distance = p.distance + (p.Speed * gGame.TimeMP)
    tTransform = p.Rocket.transform
    tDetails = gGame.Physics.rayCastClosest(tTransform.position, tTransform.yAxis)
    if tDetails.count > 0 then
      if tDetails[4] < (0.75 + (p.Speed * gGame.TimeMP)) then
        tName = tDetails[1].name
        tmodel = p.member.model(tName)
        tExploScript = new(script("[PS] Rocket Explosion"), p.member, tDetails[2], gGame.member.camera("PLayer1_camera"), VOID, 1500)
        if tExploScript <> VOID then
          gGame.scriptList.add(tExploScript)
        end if
        PlaySound("RocketPodExplosion_SFX", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #sender: p.Rocket.name, #targetName: p.Rocket.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
        areaDamage(0, p.Rocket.worldPosition, p.data.areaDamage, p.sender, p.member.model(tDetails[1].name).parent)
        me.DeleteRocket()
        exit
      end if
    end if
    tRandom = random(10, 30) * 0.10000000000000001
    p.Flame.transform.scale = vector(tRandom, tRandom, tRandom)
    p.member.deleteModelResource(p.Trail.resource.name)
    p.VList.add((tTransform.zAxis * 0.40000000000000002) + (tTransform.yAxis * p.distance) + (tTransform.xAxis * 0.25))
    p.VList.add((-tTransform.zAxis * 0.40000000000000002) + (tTransform.yAxis * p.distance) + (tTransform.xAxis * 0.25))
    p.tList.add([0, p.distance * 0.20000000000000001])
    p.tList.add([1, p.distance * 0.20000000000000001])
    tCount = p.faces
    p.faces = p.faces + 2
    p.FList.add([1 + tCount, 3 + tCount, 4 + tCount])
    p.FList.add([1 + tCount, 4 + tCount, 2 + tCount])
    p.TrailResource = p.member.newMesh(p.Rocket.name & "Trail" & gSystem.frame, p.faces, p.VList.count, 0, 0, p.tList.count)
    p.TrailResource.vertexList = p.VList
    p.TrailResource.textureCoordinateList = p.tList
    repeat with i = 1 to p.faces
      p.TrailResource.face[i].vertices = p.FList[i]
      p.TrailResource.face[i].texCoords = p.FList[i]
    end repeat
    p.TrailResource.build()
    p.Trail.resource = p.TrailResource
    p.Trail.shader = p.shader
  else
    tBlend = p.shader.blend
    tBlend = tBlend - 5
    tBlend = max(0, tBlend)
    p.shader.blend = tBlend
    if tBlend = 0 then
      delete me
    end if
  end if
  p.timeout = p.timeout - (1.0 * gGame.TimeMP)
  if p.timeout <= 0 then
    delete me
  end if
end

on DeleteRocket me
  p.member.deleteModel(p.Rocket.name)
  p.member.deleteModel(p.Flame.name)
  p.alive = 0
end

on delete me
  if p.alive = 1 then
    me.DeleteRocket()
  end if
  p.member.deleteShader(p.shader.name)
  p.member.deleteModel(p.Trail.name)
  p.member.deleteModelResource(p.TrailResource.name)
  gGame.scriptList.deleteOne(p.me)
end
