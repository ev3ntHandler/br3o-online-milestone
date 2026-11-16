property p
global gData, gGame

on new me, tParams
  p = [:]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = member(tParams[#memberName])
  p[#button] = VOID
  p[#PreviousButton] = VOID
  p[#mouseDown] = 0
  p[#rightMouseDown] = 0
  p[#EnterName] = 0
  p[#StandardName] = "PLAYER"
  p[#Bar] = "|"
  p[#BarState] = 0
  p[#name] = p.StandardName
  p[#StoredName] = p.name
  p[#AmountChars] = 10
  p[#AllowedChars] = "abcdefghijklmnopqrstuvwxyz1234567890"
  CreateTextTexture(0, "Main", [#text: gData.data.text.PlayerName, #texture: "PlayerName_Texture", #align: #center, #fontSize: 26, #lineSpacing: 18, #width: 512, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite], #nearFiltering: 1])
  p[#me] = me
  gGame[#EnterName] = me
  return me
end

on enterFrame me
  if p.EnterName = 0 then
    if p.mouseDown = 0 then
      tmodel = member("Main").camera("3D_Camera").modelUnderLoc(_mouse.mouseLoc)
      if tmodel <> VOID then
        if tmodel.name = "EnterNameText" then
          p.button = tmodel
        else
          p.button = VOID
        end if
      end if
      if (p.button = VOID) and (p.PreviousButton <> VOID) then
        me.ButtonLeave(p.PreviousButton)
      end if
      if p.button <> VOID then
        me.ButtonEnter()
      end if
    end if
    if _mouse.mouseDown and (p.button <> VOID) then
      me.ButtonDown()
    end if
    if _mouse.mouseUp and (p.button <> VOID) and (p.mouseDown = 1) then
      me.ButtonUp()
    end if
  else
  end if
end

on ButtonEnter me
  if p.button = p.PreviousButton then
    return 
  else
    me.ButtonLeave(p.PreviousButton)
  end if
  _player.cursor(280)
  p.PreviousButton = p.button
end

on ButtonLeave me, tButton
  _player.cursor(-1)
  p.PreviousButton = VOID
end

on ButtonDown me
  PlaySound("ButtonPressed_SFX")
  p.EnterName = 1
  CreateTextTexture(0, "Main", [#text: p.name, #texture: "PlayerName_Texture", #align: #center, #fontSize: 26, #lineSpacing: 18, #width: 512, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite]])
  CreateTextTexture(0, "Main", [#text: gData.data.text.PlayerNameInfo, #texture: "Warning_Texture", #fontSize: 15, #width: 512, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite]])
  SETVISIBLE(0, "Main", [#model: "EnterNameWarning", #parent: "EnterName", #state: 1])
  SETVISIBLE(0, "Main", [#model: ["BackButton", "NextButton"], #state: 0])
  timeout().new("UpdateVerticalBar", 500, #UpdateVerticalBar, p.me)
  p.button = VOID
  p.mouseDown = 1
end

on ButtonUp me
  p.mouseDown = 0
end

on keyDown me, tKey, tKeyCode
  if p.EnterName = 0 then
    exit
  end if
  tString = p.name
  if p.EnterName = 1 then
    if tString = p.StoredName then
      tString = EMPTY
    end if
    case tKey of
      BACKSPACE:
        delete char tString.length of tString
        p.name = tString
      ENTER, RETURN:
        me.checkNames()
      otherwise:
        if p.AllowedChars contains tKey then
          tLength = tString.length
          if tLength < p.AmountChars then
            tChar = convertToUpperCase(0, tKey)
            tString = tString & tChar
            p.name = tString
          end if
        end if
    end case
  end if
  CreateTextTexture(0, "Main", [#text: p.name, #texture: "PlayerName_Texture", #align: #center, #fontSize: 26, #lineSpacing: 18, #width: 512, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite]])
end

on UpdateVerticalBar me
  tString = p.name
  if p.BarState = 0 then
    tString = tString & p.Bar
    p.BarState = 1
  else
    p.BarState = 0
  end if
  CreateTextTexture(0, "Main", [#text: tString, #texture: "PlayerName_Texture", #align: #center, #fontSize: 26, #lineSpacing: 18, #width: 512, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite]])
end

on checkNames me
  tString = p.name
  if tString = "xCheatItx" then
    event("CheatIt")
    OtherStuff()
  else
    if tString.length > p.AmountChars then
      tString = "Max. 10 characters"
    else
      if tString.length = 0 then
        tString = "Please enter a name"
      end if
    end if
    if (tString = "Please enter a name") or (tString = "Max. 10 characters") then
      nothing()
    else
      gGame.PlayerName = tString
      OtherStuff()
    end if
  end if
  PlaySound("ButtonPressed_SFX")
  p.name = tString
  CreateTextTexture(0, "Main", [#text: p.name, #texture: "PlayerName_Texture", #align: #center, #fontSize: 26, #lineSpacing: 18, #width: 512, #color: gData.data.TextColor.White, #filters: [gData.data.ButtonFilters.BR3Bevel, gData.data.ButtonFilters.BR3GlowWhite]])
  p.StoredName = p.name
  if gGame.Cheat = 0 then
    SetupDefaultData()
  end if
  SaveData()
end

on OtherStuff me
  p.EnterName = 0
  p.mouseDown = 0
  timeout("UpdateVerticalBar").forget()
  if gGame.gameSaved = 1 then
    event("ShowDominationWarning")
  else
    SETVISIBLE(0, "Main", [#model: "EnterNameWarning", #state: 0])
  end if
  SETVISIBLE(0, "Main", [#model: ["BackButton", "NextButton"], #state: 1])
end

on delete me
end
