global gSystem, gLoader, gData, gSound, gGame, gEmo

on Emo me, tSpriteNr
  put tSpriteNr
  if gSystem.Emo = 0 then
    InitEmo(0, tSpriteNr)
  else
    closeEmo()
  end if
end

on InitEmo me, tSpriteNr
  put "InitEMo"
  gSystem.Emo = 1
  gEmo = [:]
  gEmo[#member] = member("Console")
  gEmo.member.resetWorld()
  createTexture(gEmo.member.name, [#fileName: "WindowStyle_Texture", #renderFormat: #rgba8888, #filtering: #lowFiltered, #nearFiltering: 0])
  gEmo[#camera] = gEmo.member.camera("DefaultView")
  gEmo.camera.transform.position = vector(gGame.resolution[1] / 2, -gGame.resolution[2] / 2, 775.0)
  gEmo.camera.rect = rect(0, 0, gGame.resolution[1], gGame.resolution[2])
  gEmo.camera.projection = #orthographic
  gEmo.camera.orthoHeight = gGame.resolution[2]
  gEmo.camera.colorBuffer.clearAtRender = 0
  sprite(tSpriteNr).addCamera(gEmo.camera)
  gEmo[#windows] = [:]
  SetupWindow(0, #console)
end

on closeEmo
  put "closeEmo"
  gSystem.Emo = 0
end

on SetupWindow me, tWindowName
  if tWindowName = VOID then
    exit
  end if
  tWindow = [:]
  tWindow[#ROOT] = gEmo.member.newGroup(tWindowName & "_Window")
  tList = [#consoleDisplay: [#name: "ConsoleTextDisplay", #size: [512, 256]], #consoleInput: [#name: "ConsoleTextInput", #size: [512, 16], #align: [#TextDisplay: #bottom], #Function: #consoleInput]]
  tType = #TextDisplay
  tMesh = gEmo.member.newMesh(string(tWindowName & tType), 2, 4, 0, 0, 4)
  tMesh.vertexList = [vector(0, 0, 0), vector(512, 0, 0), vector(512, -256, 0), vector(0, -256, 0)]
  tMesh.face[1].vertices = [3, 2, 1]
  tMesh.face[2].vertices = [4, 3, 1]
  tMesh.textureCoordinateList = [[0.0, 1.0], [1.0, 1.0], [1.0, 0.0], [0.0, 0.0]]
  tMesh.face[1].texCoords = [3, 2, 1]
  tMesh.face[2].texCoords = [4, 3, 1]
  tMesh.generateNormals(#flat)
  repeat with i = 1 to tMesh.vertexList.count
    tMesh.normalList[i] = vector(0, 0, 1)
  end repeat
  tMesh.build()
  tmodel = gEmo.member.newModel(string(tWindowName & tType), tMesh)
  tmodel.shader = EmoStandardShaderAndTexture(0, string(tWindowName & tType), VOID, [512, 256])
end

on EmoStandardShaderAndTexture me, tName, tTextureName, tTextureSize
  tShader = gEmo.member.newShader(tName & "_Material", #standard)
  tShader.ambient = rgb(0, 0, 0)
  tShader.diffuse = rgb(0, 0, 0)
  tShader.specular = rgb(0, 0, 0)
  tShader.emissive = rgb(255, 255, 255)
  tShader.shininess = 0.0
  if tTextureName = VOID then
    tImage = image(tTextureSize[1], tTextureSize[2], 32)
    tTexture = gEmo.member.newTexture(tName & "_Texture", #fromImageObject, tImage)
    tTexture.renderFormat = #rgba8888
    tTexture.quality = #lowFiltered
    tTexture.nearFiltering = 0
  else
    tTexture = gEmo.member.texture(tTextureName)
  end if
  tShader.texture = tTexture
  tShader.blendFunctionList[2] = #replace
  return tShader
end
