property p
global gSystem, gGame

on new me, t, tPod
  p = [:]
  p[#member] = t.general.member
  p[#sender] = t.general.tag
  p[#model] = t.car.model
  p[#me] = me
  p[#RocketName] = string(p.sender) & "Rocket" & _system.milliSeconds
  p[#Rocket] = p.member.newModel(p.RocketName, p.member.modelResource("Rocket"))
  p.Rocket.shader = p.member.model("Rocket").shader
  p[#Flame] = p.member.newModel(p.RocketName & "Flame", p.member.modelResource("RocketFlame"))
  p.Flame.shader = p.member.shader("RocketFlame_Material")
  p.Flame.parent = p.Rocket
  p.Flame.transform.position = p.Rocket.worldPosition - (p.Flame.transform.yAxis * 0.5)
  tTransform = t.car.Effects.secondary[tPod].getWorldTransform().duplicate()
  p.Rocket.transform = tTransform
  tOffset = randomVector() * 0.25
  p.Rocket.transform.position = p.Rocket.transform.position + vector(tOffset.x, 0, tOffset.z)
  p.Rocket.transform.rotation = p.Rocket.transform.rotation + (tOffset * 1.10000000000000009)
  p[#VList] = []
  repeat with i = 1 to 102
    p.VList.add(vector())
  end repeat
  p[#faces] = 100
  p[#FList] = [[1, 3, 4], [1, 4, 2]]
  repeat with i = 1 to (p.faces / 2) - 1
    tCount = i * 2
    p.FList.add([1 + tCount, 3 + tCount, 4 + tCount])
    p.FList.add([1 + tCount, 4 + tCount, 2 + tCount])
  end repeat
  put p.FList.count
  p[#Counter] = 0
  p[#TrailResource] = p.member.newMesh(p.RocketName & "Trail", p.faces, p.VList.count, 0, 0, 0)
  p.TrailResource.vertexList = p.VList
  repeat with i = 1 to p.faces
    p.TrailResource.face[i].vertices = p.FList[i]
  end repeat
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
  timeout().new(p.RocketName & "DeleteRocket", 5000, #delete, p.me)
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
        tExploScript = new(script("[PPS] Car Explosion"), p.member, tDetails[2], gGame.member.camera("PLayer1_camera"), VOID, 100)
        if tExploScript <> VOID then
          gGame.scriptList.add(tExploScript)
        end if
        PlaySound("RocketPodExplosion_SFX", [#priority: #medium, #surround: 1, #member3DName: p.member.name, #sender: p.Rocket.name, #targetName: p.Rocket.name, #referenceName: "Player1_Camera", #distance: [20, 200], #static: 1, #Override: 1])
        tCarName = tName.char[1..tName.length - 5]
        if voidp(gGame.cars[symbol(tCarName)]) = 0 then
          gGame.cars[symbol(tCarName)].car.impacts.add([15, #Rocket])
          gGame.cars[symbol(tCarName)].car.PhysicsCar.applyLinearImpulse(tDetails[3] * -25000)
        end if
        tList = gGame.Physics.getRigidBodies()
        tDist = 15
        repeat with i in tList
          tRBName = i.name
          tObjectName = tRBName.char[1..tRBName.length - 5]
          if tObjectName = string(p.sender) then
            next repeat
          end if
          if tObjectName = tCarName then
            next repeat
          end if
          if voidp(gGame.cars[symbol(tObjectName)]) = 0 then
            tDistanceTo = p.Rocket.worldPosition.distanceTo(i.position)
            if tDistanceTo < tDist then
              tPerc = tDistanceTo / tDist
              tDamage = 15 * tPerc
              gGame.cars[symbol(tObjectName)].car.impacts.add([tDamage, #areaDamage])
              tDirection = i.position - p.Rocket.worldPosition
              gGame.cars[symbol(tObjectName)].car.PhysicsCar.applyLinearImpulse(tDirection * (15000 * tPerc))
            end if
          end if
        end repeat
        me.DeleteRocket()
        exit
      end if
    end if
    tRandom = random(10, 30) * 0.10000000000000001
    p.Flame.transform.scale = vector(tRandom, tRandom, tRandom)
    p.Counter = p.Counter + 1
    if p.Counter > 51 then
      p.VList.deleteAt(1)
      p.VList.deleteAt(1)
      p.VList.add((tTransform.zAxis * 0.40000000000000002) + (tTransform.yAxis * p.distance) + (tTransform.xAxis * 0.34999999999999998))
      p.VList.add((-tTransform.zAxis * 0.40000000000000002) + (tTransform.yAxis * p.distance) + (tTransform.xAxis * 0.34999999999999998))
      put 8 / 0
    else
      t1 = (p.Counter * 2) - 1
      t2 = p.Counter * 2
      p.VList[t1] = (tTransform.zAxis * 0.40000000000000002) + (tTransform.yAxis * p.distance) + (tTransform.xAxis * 0.34999999999999998)
      p.VList[t2] = (-tTransform.zAxis * 0.40000000000000002) + (tTransform.yAxis * p.distance) + (tTransform.xAxis * 0.34999999999999998)
      repeat with i = (p.Counter * 2) + 1 to p.VList.count
        p.VList[i] = (tTransform.zAxis * 0.40000000000000002) + (tTransform.yAxis * p.distance) + (tTransform.xAxis * 0.34999999999999998)
      end repeat
    end if
    tResource = p.Trail.resource
    tResource.vertexList = p.VList
    repeat with i = 1 to p.faces
      tResource.face[i].vertices = p.FList[i]
    end repeat
    tResource.generateNormals(#smooth)
    tResource.build()
    p.Trail.resource = tResource
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
  if _movie.timeoutList.getPos(timeout(p.RocketName & "DeleteRocket")) <> 0 then
    timeout(p.RocketName & "DeleteRocket").forget()
  end if
  gGame.scriptList.deleteOne(p.me)
end
