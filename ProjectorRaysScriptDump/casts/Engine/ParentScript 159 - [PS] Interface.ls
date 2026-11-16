property p
global gGame

on new me, tParams
  p = [:]
  p[#sprite] = sprite(tParams[#SpriteNR])
  p[#member] = member(tParams[#memberName])
  p[#timer] = 0
  if tParams[#timer].ilk = #integer then
    p.timer = tParams.timer
  end if
  p[#TimerModels] = [gGame.interface.model("Time1"), gGame.interface.model("Time2"), gGame.interface.model("Time3"), gGame.interface.model("Time4"), gGame.interface.model("Time5")]
  p[#CountDown] = 0
  if tParams[#CountDown].ilk = #integer then
    p.CountDown = tParams.CountDown
  end if
  p[#CountDownModels] = [gGame.interface.model("CountDown1"), gGame.interface.model("CountDown2"), gGame.interface.model("CountDown3")]
  p[#Elimination] = 0
  if tParams[#Elimination].ilk = #integer then
    p.Elimination = tParams.Elimination
  end if
  p[#EliminationModels] = [gGame.interface.model("Elimination1"), gGame.interface.model("Elimination2")]
  p[#score] = 0
  if tParams[#score].ilk = #integer then
    p.score = tParams.score
  end if
  p[#ScoreModels] = []
  repeat with i = 1 to 6
    p.ScoreModels.add(gGame.interface.model("Score" & i))
  end repeat
  p[#Speedo] = 0
  if tParams[#Speedo].ilk = #integer then
    p.Speedo = tParams.Speedo
  end if
  p[#SpeedoModels] = [gGame.interface.model("Speedo1"), gGame.interface.model("Speedo2"), gGame.interface.model("Speedo3")]
  t = gGame.cars[gGame.camera[1].target]
  p[#Weapons] = 0
  if tParams[#Weapons].ilk = #integer then
    p.Weapons = tParams.Weapons
  end if
  if p.Weapons = 1 then
    p[#PrimData] = t.Weapons[symbol(t.general.data.Weapons.primary)]
    p[#SecData] = t.Weapons[symbol(t.general.data.Weapons.secondary)]
    p[#PrimModels] = [gGame.interface.model("PrimaryAmmo1"), gGame.interface.model("PrimaryAmmo2"), gGame.interface.model("PrimaryWeaponSlots")]
    p[#SecModels] = [gGame.interface.model("SecondaryAmmo1"), gGame.interface.model("SecondaryAmmo2"), gGame.interface.model("SecondaryWeaponSlots")]
  end if
  p[#SSFont] = []
  repeat with i = 0 to 9
    p.SSFont.add(gGame.interface.modelResource("SSFont" & i))
  end repeat
  p[#WhiteFont] = []
  repeat with i = 0 to 9
    p.WhiteFont.add(gGame.interface.modelResource("WhiteFont" & i))
  end repeat
  return me
end

on enterFrame me
  t = gGame.cars[symbol(gGame.camera[1].target.name)]
  if p.timer = 1 then
    if voidp(gGame[#timer]) = 0 then
      tMillisec = gGame.timer
      sec = integer(tMillisec / 1000)
      min = integer(sec / 60)
      sec = sec - (min * 60)
      Hour = integer(min / 60)
      min = min - (Hour * 60)
      tMillisec = integer((tMillisec - (sec * 1000) - (min * 60 * 1000) - (Hour * 60 * 60 * 1000)) / 10.0)
      if min < 10 then
        minString = "0" & string(min + 100).char[3..3]
      else
        minString = string(min + 100).char[3..3]
      end if
      secString = string(sec + 100).char[2..3]
      if tMillisec < 10 then
        MilliString = "0" & string(tMillisec)
      else
        MilliString = string(tMillisec)
      end if
      if tMillisec = 100 then
        MilliString = "00"
      end if
      tString = minString & secString & MilliString
      tString = tString.char[2..tString.length]
      repeat with i = 1 to 5
        p.TimerModels[i].resource = gGame.interface.modelResource("WhiteFont" & tString.char[i])
        if (gGame.GameMode = "Rampage") and (gGame.timer <= 10000) then
          p.TimerModels[i].shader = gGame.interface.shader("InterfaceRed_Material")
          gGame.interface.model("Time:1").shader = gGame.interface.shader("InterfaceRed_Material")
          gGame.interface.model("Time:2").shader = gGame.interface.shader("InterfaceRed_Material")
        end if
      end repeat
    end if
  end if
  if gGame.GameMode = "elimination" then
    if voidp(gGame[#Elimination]) = 0 then
      if gGame.Elimination > 0 then
        tString = "0" & string(integer(gGame.Elimination / 1000.0))
        tString = tString.char[tString.length - 1..tString.length]
        repeat with i = 1 to 2
          p.EliminationModels[i].resource = gGame.interface.modelResource("WhiteFont" & tString.char[i])
        end repeat
      end if
    end if
  end if
  if p.CountDown = 1 then
    if voidp(gGame[#CountDown]) = 0 then
      if gGame.CountDown > 0 then
        tString = "00" & string(integer(gGame.CountDown / 10.0))
        tString = tString.char[tString.length - 2..tString.length]
        repeat with i = 1 to 3
          p.CountDownModels[i].resource = gGame.interface.modelResource("WhiteFont" & tString.char[i])
        end repeat
      end if
    end if
  end if
  if p.score = 1 then
    tAddScore = t.race.addScore
    tScore = t.race.storedScore
    if tAddScore > 0 then
      tStep = 100
      if tAddScore < 100 then
        tStep = tAddScore
      end if
      tScore = tScore + tStep
      tScore = string("00000" & tScore)
      tScore = tScore.char[tScore.length - 5..tScore.length]
      repeat with i = 1 to 6
        tValue = value(tScore.char[i]) + 1
        p.ScoreModels[i].resource = p.WhiteFont[tValue]
      end repeat
      tAddScore = tAddScore - tStep
    end if
    t.race.addScore = tAddScore
    t.race.storedScore = value(tScore)
  end if
  if p.Speedo = 1 then
    tString = "00" & string(integer(abs(t.car.Speed) * 3600) / 1000)
    tString = tString.char[tString.length - 2..tString.length]
    repeat with i = 1 to 3
      tValue = value(tString.char[i])
      p.SpeedoModels[i].resource = gGame.interface.modelResource("SSFont" & tValue)
    end repeat
  end if
  if p.Weapons = 1 then
    if voidp(p[#PrimData]) = 0 then
      tString = "0" & string(p.PrimData.ammo[1])
      p.PrimModels[1].resource = p.SSFont[value(tString.char[tString.length - 1]) + 1]
      p.PrimModels[2].resource = p.SSFont[value(tString.char[tString.length]) + 1]
      p.PrimModels[3].resource = gGame.interface.modelResource("PrimaryWeaponSlots" & p.PrimData.clips)
    else
      if gGame.interface.model("Primary").isInWorld() = 1 then
        gGame.interface.model("Primary").parent = VOID
      end if
    end if
    if voidp(p[#SecData]) = 0 then
      tString = "0" & string(p.SecData.ammo[1])
      p.SecModels[1].resource = p.SSFont[value(tString.char[tString.length - 1]) + 1]
      p.SecModels[2].resource = p.SSFont[value(tString.char[tString.length]) + 1]
      p.SecModels[3].resource = gGame.interface.modelResource("SecondaryWeaponSlots" & p.SecData.clips)
    else
      if gGame.interface.model("Secondary").isInWorld() = 1 then
        gGame.interface.model("Secondary").parent = VOID
      end if
    end if
  else
    gGame.interface.model("Primary").parent = VOID
    gGame.interface.model("Secondary").parent = VOID
  end if
end
