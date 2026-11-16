global gGame, gSound

on PauseGame tKey
  if gGame.input = 0 then
    exit
  end if
  if gGame.pause = 0 then
    gGame[#PauseTime] = _system.milliSeconds
    gGame.timeoutList = _movie.timeoutList.duplicate()
    _movie.timeoutList = []
    PauseParticles(1)
    event("PauseGame")
    gSound[#OldMute] = gSound.mute
    gSound.mute = 1
    MuteSound()
    gGame.pause = 1
    exit
  end if
  if gGame.pause = 1 then
    gGame[#PauseTime] = _system.milliSeconds - gGame.PauseTime
    _movie.timeoutList = gGame.timeoutList.duplicate()
    gGame.timeoutList = []
    PauseParticles(0)
    event("UnPauseGame")
    gSound.mute = gSound.OldMute
    MuteSound()
    gGame.pause = 0
    exit
  end if
end

on PauseParticles tState
  pCount = gGame.member.modelResource.count
  repeat with i = 1 to pCount
    pResource = gGame.member.modelResource[i]
    if pResource.type = #particle then
      pResource.paused = tState
    end if
  end repeat
end

on UltraPause me
  gGame.pause = 1
  PauseParticles(1)
  gGame.timeoutList = _movie.timeoutList.duplicate()
  _movie.timeoutList = []
  StopAllSound(EMPTY, [#exception: gGame.CurrentWorld & "Music"])
end

on MuteGame me
  if gSound.mute = 1 then
    gSound.mute = 0
  else
    gSound.mute = 1
  end if
  MuteSound()
end
