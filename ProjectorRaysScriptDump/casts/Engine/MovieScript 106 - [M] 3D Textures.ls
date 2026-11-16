on DuplicateTexture me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return []
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return []
  end if
  tSourceMember = tmember
  if tDataList[#sourceMember].ilk = #string then
    tSourceMember = member(tDataList.sourceMember)
  end if
  tTargetList = []
  if tDataList[#texture].ilk = #void then
    tDataList[#texture] = "*.*"
  end if
  if tDataList[#texture].ilk = #list then
    tTargetList = tDataList.texture
  else
    if tDataList[#texture].ilk = #string then
      if tDataList.texture.char[1] = "*" then
        tString = tDataList.shader
        if tString <> "*.*" then
          delete tString.char[1]
        end if
        tTargetList = GetStringList(0, tSourceMember.name, [#type: #texture, #string: tString])
      else
        tTargetList.add(tDataList.texture)
      end if
    end if
  end if
  if tTargetList.count = 0 then
    return []
  end if
  tNameTag = VOID
  if tDataList[#NameTag].ilk = #string then
    tNameTag = tDataList.NameTag
  end if
  tTextureList = []
  repeat with i in tTargetList
    tTexture = tSourceMember.texture(i)
    tTextureMember = tTexture.member
    tImage = tTextureMember.image.duplicate()
    tNewTexture = tmember.newTexture(tNameTag & tTexture.name, #fromImageObject, tImage)
    tNewTexture.quality = tTexture.quality
    tNewTexture.nearFiltering = tTexture.nearFiltering
    tNewTexture.compressed = tTexture.compressed
    tNewTexture.renderFormat = tTexture.renderFormat
    tNewTexture.member = tTexture.member
    tTextureList.add(tNewTexture)
  end repeat
  if tTextureList.count = 1 then
    return tTextureList[1]
  else
    return tTextureList
  end if
end
