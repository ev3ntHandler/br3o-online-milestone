property p
global gGame

on new me, tParams
  p = new(script("pObject"))
  tSprite = sprite(tParams[#SpriteNR])
  tmember = member(tParams[#memberName])
  if getaProp(gGame, #camera) = VOID then
    gGame[#camera] = [:]
  end if
  tNr = gGame.camera.count + 1
  p[#index] = symbol("Camera" & tNr)
  gGame.camera[p.index] = [:]
  gGame.camera[p.index][#sprite] = tSprite
  gGame.camera[p.index][#member] = tmember
  tCamera = tmember.newCamera("Player" & tNr & "_Camera")
  tSkyboxCamera = member("Skyboxes").newCamera("Skybox" & tNr & "_Camera")
  tSkyboxCamera.rootNode = member("Skyboxes").group("Skybox_Group")
  member("Skyboxes").group("Skybox_Group").removeFromWorld()
  if gGame.Players > 1 then
    tDefaultCam = tmember.camera("DefaultView")
    tSprite.camera = tDefaultCam
    if tNr = 1 then
      tSprite.addCamera(tCamera, 2)
      tSprite.addCamera(tSkyboxCamera, 2)
      tCamera.rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2] / 2)
      tSkyboxCamera.rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2] / 2)
    end if
    if tNr = 2 then
      tSprite.addCamera(tCamera, 4)
      tSprite.addCamera(tSkyboxCamera, 4)
      tCamera.rect = rect(0, gGame.resolution[2] / 2, gGame.resolution[1], gGame.resolution[2])
      tSkyboxCamera.rect = rect(0, gGame.resolution[2] / 2, gGame.resolution[1], gGame.resolution[2])
    end if
  else
    tSprite.camera = tCamera
    tSprite.addCamera(tSkyboxCamera, 1)
    tCamera.rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2])
    tSkyboxCamera.rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2])
  end if
  tmember.camera("DefaultView").rootNode = VOID
  tmember.camera("DefaultView").parent = VOID
  tmember.camera("DefaultView").rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2])
  gGame.camera[p.index][#camera] = tCamera
  gGame.camera[p.index][#SkyBoxCamera] = tSkyboxCamera
  gGame.camera[p.index][#OldTarget] = tmember.group("World")
  if voidp(tParams[#target]) = 0 then
    gGame.camera[p.index][#target] = GetReferenceType(tmember, string(tParams[#target]))
  else
    gGame.camera[p.index][#target] = tmember.group("World")
  end if
  gGame.camera[p.index][#offset] = vector(0.0, 0.0, 0.0)
  gGame.camera[p.index][#OldOffSet] = vector()
  gGame.camera[p.index][#rotation] = vector(0.0, 0.0, 0.0)
  gGame.camera[p.index][#OldRotation] = vector()
  gGame.camera[p.index][#position] = vector(0.0, 0.0, 0.0)
  gGame.camera[p.index][#OldPosition] = vector()
  gGame.camera[p.index][#transform] = tCamera.transform
  gGame.camera[p.index][#interpolateSpeed] = 0.65000000000000002
  gGame.camera[p.index][#fov] = 55.0
  p[#ScriptName] = tParams[#ScriptName]
  if p.ScriptName = VOID then
    p.ScriptName = EMPTY
  end if
  gGame.camera[p.index][#pivot] = tmember.newGroup(tCamera.name & "Pivot")
  gGame.camera[p.index][#Camerapoint] = tmember.newGroup(tCamera.name & "Point")
  gGame.camera[p.index].Camerapoint.parent = gGame.camera[p.index].pivot
  if gGame[#CameraStates].ilk = #list then
    gGame.camera[p.index][#States] = gGame.CameraStates
  else
    gGame.camera[p.index][#States] = []
  end if
  if voidp(gGame[#Cheat]) = 0 then
    if gGame.Cheat = 1 then
      gGame.camera[p.index][#States].add(#DebugCameras)
    end if
  end if
  return me
end

on enterFrame me
  t = gGame.camera[p.index]
  if (t.OldTarget <> t.target) and (t.target.ilk <> #model) then
    t.target = GetReferenceType(t.member, string(t.target))
  end if
  if t.target = VOID then
    t.target = t.member.group("World")
  end if
  tCurrentTransform = t.Camerapoint.transform
  tTargetTransform = t.Camerapoint.transform.duplicate()
  tTargetTransform.position = t.offset
  tTargetTransform.rotation = t.rotation
  if tCurrentTransform <> tTargetTransform then
    tCurrentTransform.interpolateTo(tTargetTransform, 25)
  end if
  tCurrentFov = transform()
  tTargetFov = transform()
  tCurrentFov.position.z = float(t.camera.fieldOfView)
  tTargetFov.position.z = t.fov
  if tCurrentFov <> tTargetFov then
    tCurrentFov.interpolateTo(tTargetFov, 25)
  end if
  tCos = t.target.transform.zAxis.dot(vector(0, 0, 1))
  txform = t.target.getWorldTransform()
  pxr = t.pivot.transform.rotation
  pxp = t.pivot.transform.position
  if tCos < 0 then
    txform.rotation.z = 0.0
  end if
  pxr.x = pxr.x + (360 * (txform.rotation.x > (pxr.x + 180))) - (360 * (txform.rotation.x < (pxr.x - 180)))
  pxr.y = pxr.y + (360 * (txform.rotation.y > (pxr.y + 180))) - (360 * (txform.rotation.y < (pxr.y - 180)))
  pxr.z = pxr.z + (360 * (txform.rotation.z > (pxr.z + 180))) - (360 * (txform.rotation.z < (pxr.z - 180)))
  pxp = pxp + ((txform.position - pxp) * t.interpolateSpeed * gGame.TimeMP)
  pxr = pxr + ((txform.rotation - pxr) * (t.interpolateSpeed / 5) * gGame.TimeMP)
  t.pivot.transform.rotation.z = pxr.z
  if (pxr.x < 0) and (tCos > 0) then
    t.pivot.transform.rotation.x = pxr.x
  end if
  t.pivot.transform.position = pxp
  t.camera.transform = t.Camerapoint.getWorldTransform()
  t.camera.fieldOfView = tCurrentFov.position.z
  t.SkyBoxCamera.transform.rotation = t.camera.transform.rotation
  t.SkyBoxCamera.fieldOfView = t.camera.fieldOfView
  repeat with i in gGame.camera[p.index].States
    sendSprite(0, i, t)
  end repeat
end
