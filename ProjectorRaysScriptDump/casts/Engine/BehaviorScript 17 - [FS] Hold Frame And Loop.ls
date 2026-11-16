global gSystem

on enterFrame me
  if (_key.commandDown = 1) and keyPressed("i") then
    ShowVersion()
  end if
  if _player.runMode = "Projector" then
    if (_key.commandDown = 1) and keyPressed("q") then
      _player.quit()
    end if
    if (_key.optionDown = 1) and _key.keyPressed(RETURN) then
      fullscreen()
    end if
  end if
end

on exitFrame me
  _movie.go(_movie.frame)
  gSystem.frame = gSystem.frame + 1
end
