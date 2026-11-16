global gSystem, gLoader, gData, gSound, gGame, gStarter

on prepareMovie me
  reset(#nothing)
  if voidp(gSystem) = 1 then
    InitGlobals()
  end if
  if not voidp(gStarter) then
    gGame[#HighResCarTextures] = gStarter.Visuals[#HighResCarTextures]
    gGame[#Bloom] = gStarter.Visuals[#Bloom]
    gGame[#BloomPlus] = gStarter.Visuals[#BloomPlus]
    gGame[#MotionBlur] = gStarter.Visuals[#MotionBlur]
    gGame[#MotionBlurQuality] = gStarter.Visuals[#MotionBlurQuality]
    gGame[#Shadows] = gStarter.Visuals[#Shadows]
    gGame[#ShadowsDetail] = gStarter.Visuals[#ShadowsDetail]
    gGame[#AntiAliasing] = gStarter.Visuals[#AntiAliasing]
    gGame.resolution = gStarter.resolution
    if gGame.resolution[1] > 640 then
      gGame.SourceRatio = 2
    end if
    if gGame.resolution[1] >= 1440 then
      gGame.SourceRatio = 4
    end if
    SetStageSize()
  end if
  gGame[#ResRatio] = 640.0 / gGame.resolution[1]
end

on startMovie me
  if gGame.succes = 0 then
    gotoNetPage("http://www.shockwave.com")
  else
    if gSystem.Init = 1 then
      event("MenuInitialization")
    else
      if (gSystem.local = 0) and (gLoader.Preloader = 1) then
        PreloadMyMovie()
      end if
      if gLoader.Preloader = 0 then
        if gSystem.local = 1 then
          load("\Data\LoadingArray.txt")
        else
          OnlineLoad()
        end if
        if voidp(gSound) = 1 then
          SetupSoundManager()
        end if
        event("GameInitialization")
      end if
    end if
  end if
end

on stopMovie me
  if gGame.fullscreen = 1 then
    ResXoff()
  end if
  if me <> VOID then
    exit
  end if
  DeleteDynamicMembers()
  DeleteDynamicSprites()
  ClearSoundManager()
  _movie.actorList = []
  _movie.timeoutList = []
  gGame.scriptList = []
  if gSystem.local = 1 then
    reset(#nothing)
  end if
end

on InitGlobals me
  if voidp(gSystem) = 0 then
    put "exited from initglobals"
    if gSystem.Init = 1 then
      exit
    end if
  end if
  gSystem = [:]
  gSystem[#debug] = 1
  gSystem[#local] = 1
  gSystem[#Init] = 0
  gSystem[#path] = chars(_movie.path, 1, _movie.path.length - 1)
  gSystem[#frame] = 0
  gSystem[#DefaultCast] = "Internal"
  gSystem[#InternalCasts] = GetInternalCasts()
  gSystem[#ExternalCasts] = GetExternalCasts()
  gSystem[#MessageWindow] = gSystem.local
  gSystem[#itemDelimiter] = TAB
  gSystem[#DynamicMembers] = []
  gSystem[#DynamicSprites] = []
  gSystem[#handlerList] = []
  gSystem[#scriptList] = []
  gSystem[#event] = VOID
  gSystem[#Emo] = 0
  if _player.runMode = "Plugin" then
    gSystem.local = 0
  end if
  gLoader = [:]
  gLoader[#state] = "Free"
  gLoader[#Preloader] = 0
  gLoader[#DownloadState] = "Free"
  gLoader[#DownloadPerc] = 0
  gLoader[#DownloadingCast] = #none
  gLoader[#DownloadedCasts] = []
  gLoader[#Member3dList] = []
  gData = [:]
  gData[#Events] = [:]
  gData[#data] = [:]
  gData[#Triggers] = []
  gData[#StoredEvents] = []
  gData[#StoredData] = []
  gData[#StoredTriggers] = []
  gGame = [:]
  gGame[#version] = 0.01
  gGame[#name] = "UnknownGame"
  gGame[#PrefFile] = "XData.txt"
  gGame[#pause] = 0
  gGame[#input] = 0
  gGame[#tempo] = 32
  gGame[#TimeMP] = 1.0
  gGame[#fullscreen] = 0
  gGame[#resolution] = [(the stage).drawRect[3], (the stage).drawRect[4]]
  gGame[#LockEscape] = 0
  gGame[#Iteration] = VOID
  gGame[#timeoutList] = []
  gGame[#actorList] = []
  gGame[#timerList] = [:]
  gGame[#timerData] = [:]
  gGame.timerData[#Lastupdate] = _system.milliSeconds
  gGame[#scriptList] = []
  gGame[#SourceRatio] = 1.0
  gGame[#HighResCarTextures] = 1
  gGame[#Bloom] = 0
  gGame[#MotionBlur] = 0
  gGame[#Shadows] = 0
  gGame[#ShadowsDetail] = 0
  gGame[#AntiAliasing] = #none
  gGame[#BloomSize] = 0.125
  gGame[#succes] = 1
  _movie.exitLock = gGame.LockEscape
  _player.debugPlaybackEnabled = gSystem.MessageWindow
  put "gGame.succes was " & gGame.succes
end
