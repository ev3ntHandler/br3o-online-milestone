property p
global gGame, gData

on new me, tURLList, tCastList, tProps, tHolder, tWorld
  p = [:]
  if tURLList.ilk <> #list then
    return 0
  end if
  if tURLList.count = 0 then
    return 0
  end if
  p[#cast] = tCastList[1]
  p[#url] = tURLList[1]
  p[#props] = tProps
  p[#NetID] = preloadNetThing(p.url)
  p[#URLList] = tURLList.duplicate()
  p[#CastList] = tCastList.duplicate()
  p[#Holder] = tHolder
  p[#world] = tWorld
  p[#Percentage] = 0
  p[#member] = member("Main")
  p[#model] = p.member.model("DownloadingTag")
  if (p.model.isInWorld() = 0) and (gGame.CurrentMenu <> "Logo") then
    p.model.addToWorld()
  end if
  tText = "DOWNLOADING SHARED DATA 100 %"
  CreateTextTexture(0, p.member.name, [#text: tText, #texture: "Downloading_Texture", #fontSize: 10, #align: #right, #color: gData.data.TextColor.White, #width: 256, #filters: [gData.data.ButtonFilters.BR3GlowWhite]])
  ASSIGNTEXTURE(p.member.name, [#material: "Downloading_Material", #texture1: "Downloading_Texture"])
  p[#me] = me
  return me
end

on stepFrame me
  if (netDone(p.NetID) = 1) and (netError(p.NetID) = "OK") then
    DownloadDone(1)
  else
    if netError(p.NetID) <> EMPTY then
      p[#NetIDError] = netError(p.NetID)
      case p.NetIDError of
        4:
          p.error = "Bad MOA class. The required network or nonnetwork Xtra extensions are improperly installed or not installed at all."
        5:
          p.error = "Bad MOA Interface."
        6:
          p.error = "Bad URL or Bad MOA class. The required network or nonnetwork Xtra extensions are improperly installed or not installed at all."
        20:
          p.error = "Internal error. Returned by netError() in the Netscape browser if the browser detected a network or internal error."
        4146:
          p.error = "Connection could not be established with the remote host."
        4149:
          p.error = "Data supplied by the server was in an unexpected format."
        415:
          p.error = "Unexpected early closing of connection."
        4154:
          p.error = "Operation could not be completed due to timeout."
        4155:
          p.error = "Not enough memory available to complete the transaction."
        4156:
          p.error = "Protocol reply to request indicates an error in the reply."
        4157:
          p.error = "Transaction failed to be authenticated."
        4159:
          p.error = "Invalid URL."
        4164:
          p.error = "Could not create a socket."
        4165:
          p.error = "Requested object could not be found (URL may be incorrect)."
        4166:
          p.error = "Generic proxy failure."
        4167:
          p.error = "Transfer was intentionally interrupted by client."
        4242:
          p.error = "Download stopped by netAbort(url)."
        4836:
          p.error = "Download stopped for an unknown reason, possibly a network error, or the download was abandoned."
        otherwise:
          p.error = "Error unknown"
      end case
      DownloadDone(0)
    end if
  end if
  tData = getStreamStatus(p.NetID)
  if tData.bytesSoFar > 10000 then
    tFPerc = float(tData.bytesSoFar) / float(tData.bytesTotal)
    tIPerc = 100.0 * tFPerc
    p.Percentage = integer(tIPerc)
    tString = "00" & string(p.Percentage)
    tString = tString.char[tString.length - 2..tString.length]
    tText = convertToUpperCase(0, "downloading " & p.cast & ": " & tString & " %")
    CreateTextTexture(0, p.member.name, [#text: tText, #texture: "Downloading_Texture", #fontSize: 10, #align: #right, #color: gData.data.TextColor.White, #width: 256, #filters: [gData.data.ButtonFilters.BR3GlowWhite]])
  end if
end

on DownloadDone tState
  if tState = 1 then
    put string(p.cast & " was downloaded succesfull. URL was: " & p.url)
    _movie.castLib(p.cast).fileName = p.url
    gGame[p.props[1]] = 1
    p.URLList.deleteAt(1)
    p.CastList.deleteAt(1)
    p.props.deleteAt(1)
    if p.URLList.count = 0 then
      p.model.removeFromWorld()
      gGame[p.Holder] = #none
    else
      tScript = new(script("[PS] Preload Casts"), p.URLList, p.CastList, p.props, p.Holder)
      if (tScript <> VOID) or (tScript <> 0) then
        _movie.actorList.add(tScript)
      end if
    end if
    if p.cast = "Cars" then
      LoadExternalTextures()
    end if
  else
    put string(p.cast & " was not downloaded. URL was: " & p.url & " Error was: " & p.error)
  end if
  _movie.actorList.deleteOne(p.me)
end

on AbortDownload me
  netAbort(p.NetID)
  put string(p.cast & " was aborted. URL was: " & p.url)
  _movie.actorList.deleteOne(p.me)
end

on ReturnWorld me
  return p.world
end

on returnPercentage me
  return p.Percentage
end
