global gSystem, gData, gGame

on CreateTextTexture me, tTarget, tDataList
  tmember = member(tTarget)
  if tmember = VOID then
    return 0
  end if
  if tDataList.ilk = #string then
    tDataList = value(tDataList)
  end if
  if tDataList.ilk <> #propList then
    return 0
  end if
  tTextMember = member("Text")
  tText = VOID
  if tDataList[#text].ilk = #string then
    tText = tDataList.text
  end if
  if tText = VOID then
    return 0
  end if
  tTextureName = VOID
  if tDataList[#texture].ilk = #string then
    tTextureName = tDataList.texture
  end if
  if tTextureName = VOID then
    tTextureName = tText
  end if
  tFont = "Arial"
  if voidp(gGame[#font]) = 0 then
    tFont = gGame.font
  end if
  tFontSize = tTextMember.fontSize
  if tDataList[#fontSize].ilk = #integer then
    tFontSize = tDataList.fontSize * gGame.SourceRatio
  end if
  tTextMember.fontSize = tFontSize
  if tDataList[#height].ilk = #integer then
    tTextMember.height = tDataList.height * gGame.SourceRatio
  else
    tList = [2, 4, 8, 16, 32, 64, 128, 256, 512]
    tList.sort()
    if tList.getPos(tFontSize) <> 0 then
      tHeight = tList[tList.getPos(tFontSize) + 1]
    else
      tList.add(tFontSize)
      if tList.getPos(tFontSize) = tList.count then
        tHeight = tList[tList.count - 1]
      else
        tHeight = tList[tList.getPos(tFontSize) + 1]
      end if
    end if
    tTextMember.height = tHeight
  end if
  tWrap = 0
  if tDataList[#wrap].ilk = #integer then
    tWrap = tDataList[#wrap]
  end if
  tTextMember.wordWrap = tWrap
  tWidth = 256
  if tDataList[#width].ilk = #integer then
    tWidth = tDataList[#width]
  end if
  tTextMember.width = tWidth * gGame.SourceRatio
  tTextMember.topSpacing = 0
  tTextMember.fixedLineSpace = 0
  tFixedLineSpace = 12
  if tDataList[#lineSpacing].ilk = #integer then
    tFixedLineSpace = tDataList.lineSpacing
  end if
  tTextMember.fixedLineSpace = tFixedLineSpace * gGame.SourceRatio
  tTextMember.topSpacing = (tFontSize / 2) - (2.5 * gGame.SourceRatio)
  tALign = #left
  if tDataList[#align].ilk = #symbol then
    tList = [#left, #center, #right, #Full]
    if tList.getPos(tDataList.align) <> 0 then
      tALign = tDataList.align
    end if
  end if
  tTextMember.alignment = tALign
  tFontStyle = tTextMember.fontStyle
  if tDataList[#fontStyle].ilk = #symbol then
    tList = [#bold, #italic, #underline]
    if tList.getPos(tDataList.fontStyle) <> 0 then
      tFontSize = tDataList.fontStyle
    end if
  end if
  tTextMember.fontStyle = tFontStyle
  tKerning = 0
  if tDataList[#kerning].ilk = #integer then
    tKerning = tDataList.kerning
  end if
  tTextMember.kerningThreshold = tKerning
  tColor = member("Text").color
  if tDataList[#color].ilk = #color then
    tColor = tDataList.color
  end if
  tTextMember.color = tColor
  tFilters = VOID
  if tDataList[#filters].ilk = #list then
    tFilters = tDataList.filters
  end if
  tResize = 0
  if tDataList[#resize].ilk = #integer then
    tResize = tDataList.resize
  end if
  tOffSetH = 0
  if tDataList[#offsetH].ilk = #integer then
    tOffSetH = tDataList.offsetH
  end if
  tEmpty = castLib("Menu").findEmpty()
  tTextureMember = new(#bitmap, member(tEmpty, "Menu"))
  tTextureMember.name = tTextureName
  gSystem.DynamicMembers.add(tTextureMember)
  tTextMember.text = tText
  if tResize = 1 then
    resizeText(tTextMember)
  end if
  member("ImageTemplate").image = tTextMember.image
  if tOffSetH = 0 then
    tImage = member("ImageTemplate").image
  else
    tNewImage = image(tTextMember.rect[3], tTextMember.rect[4], 32, 1)
    tTempImage = tTextMember.image.duplicate()
    tNewImage.copyPixels(tTempImage, rect(tOffSetH, 0, tTextMember.rect[3] + tOffSetH, tTextMember.rect[4]), tTempImage.rect)
    tNewAlpha = tTempImage.extractAlpha()
    tNewAlpha.fill(tNewAlpha.rect, rgb(255, 255, 255))
    tTempAlpha = tTempImage.extractAlpha()
    tNewAlpha.copyPixels(tTempAlpha, rect(tOffSetH, 0, tTextMember.rect[3] + tOffSetH, tTextMember.rect[4]), tTempAlpha.rect)
    tNewImage.setAlpha(tNewAlpha)
    member("ImageTemplate").image = tNewImage
    tImage = member("ImageTemplate").image
  end if
  if tFilters <> VOID then
    repeat with i = 1 to tFilters.count
      tFilter = filter(tFilters[i].getPropAt(1), tFilters[i][1])
      tImage.applyFilter(tFilter, tImage.rect)
    end repeat
  end if
  tTextureMember.image = tImage
  tForceSize = []
  if tDataList[#forceSize].ilk = #list then
    tForceSize = tDataList.forceSize
  end if
  if tForceSize.count > 0 then
    tForceImage = image(tForceSize[1] * gGame.SourceRatio, tForceSize[2] * gGame.SourceRatio, 32, 1)
    tForceImage.copyPixels(tImage, tImage.rect, tImage.rect)
    tForceAlpha = tForceImage.extractAlpha()
    tForceAlpha.fill(tForceAlpha.rect, rgb(255, 255, 255))
    tTempAlpha = tImage.extractAlpha()
    tForceAlpha.copyPixels(tTempAlpha, tTempAlpha.rect, tTempAlpha.rect)
    tForceImage.setAlpha(tForceAlpha)
    tImage = tForceImage.duplicate()
  end if
  tNearFiltering = 0
  if tDataList[#nearFiltering].ilk = #integer then
    tNearFiltering = tDataList.nearFiltering
  end if
  if gGame.SourceRatio > 1 then
    tNearFiltering = 1
  end if
  tTexture = tmember.texture(tTextureName)
  if tTexture = VOID then
    tTexture = tmember.newTexture(tTextureName, #fromCastMember, tTextureMember)
    tTexture.quality = #lowFiltered
    tTexture.nearFiltering = tNearFiltering
    tTexture.renderFormat = #rgba4444
  else
    tTexture.image = tImage
  end if
  return tTexture
end

on resizeText tmember
  tFontSize = tmember.fontSize
  repeat with i = 1 to tFontSize
    tCharPos = tmember.charPosToLoc(tmember.text.length + 1)
    if tCharPos[1] > tmember.rect[3] then
      tText = tmember.text
      tmember.text = EMPTY
      tmember.fontSize = tmember.fontSize - 1
      tmember.text = tText
      textBottom = tmember.charPosToLoc(tText.char.count + 1).locV
      spaceAtTop = (tmember.pageHeight - textBottom + tmember.topSpacing) / 2
      if spaceAtTop >= 0 then
        tmember.topSpacing = spaceAtTop * gGame.SourceRatio
      else
        tmember.topSpacing = 0
      end if
      next repeat
    end if
    exit repeat
  end repeat
end

on convertToUpperCase me, tString
  tNewString = EMPTY
  tList = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
  repeat with i = 1 to tString.length
    tChar = tString.char[i]
    if tList.getPos(tChar) <> 0 then
      tChar = charToNum(tString.char[i])
      tChar = numToChar(tChar - 32)
    end if
    tNewString = tNewString & tChar
  end repeat
  return tNewString
end

on convertToLowerCase me, tString
  tNewString = EMPTY
  tList = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
  repeat with i = 1 to tString.length
    tChar = tString.char[i]
    if tList.getPos(tChar) <> 0 then
      tChar = charToNum(tString.char[i])
      tChar = numToChar(tChar + 32)
    end if
    tNewString = tNewString & tChar
  end repeat
  put tNewString
  return tNewString
end
