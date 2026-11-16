property pFunction, pScoreMem, pGameID, pScreenW, pScreenH, pmarker, pScoreDes
global gGame, gSwScoreSetupList, gSwScoreNetID

on getPropertyDescriptionList me
  return [#pFunction: [#comment: "Submit / View Button?", #format: #symbol, #range: [#SUBMIT, #View], #default: #SUBMIT], #pScoreMem: [#comment: "Field or text member holding score:", #format: #member, #default: EMPTY], #pGameID: [#comment: "Game ID:", #format: #string, #default: EMPTY], #pTitle1: [#comment: "Game Title:", #format: #string, #default: EMPTY], #pScreenW: [#comment: "Screen Width", #format: #integer, #default: (the stage).rect.width], #pScreenH: [#comment: "Screen Height", #format: #integer, #default: (the stage).rect.height], #pmarker: [#comment: "Marker to wait at while HS Hub downloads:", #format: #marker, #default: EMPTY], #pScoreDes: [#comment: "Score Descriptor (points, kills, etc.)", #format: #string, #default: "points"]]
end

on getBehaviorDescription
  return "DESCRIPTION:" & RETURN & "This is the only behavior required for high score setup. It will configure your movie for Name, Score scores display." & RETURN & "Additional optional behaviors are required if you want to use more fields or have multiple players." & RETURN & RETURN & "PARAMETERS:" & RETURN & "• Submit Scores Button / View Scores Button: Which button is this behavior on?" & RETURN & "• Text member holding Score: The text member holding the score." & RETURN & "• Game ID: Unique ID provided to you by Macromedia." & RETURN & "• Game Title: Title to display in the HS Hub." & RETURN & "• Screen Width: Width of your game's screen." & RETURN & "• Screen Height: Height of your game's screen." & RETURN & "• Marker to wait at while HS Hub downloads: set up this marker in your game." & RETURN & "• Score descriptor: How would you like your score labeled?" & RETURN & RETURN & "-- © kwik 2000"
end

on mouseDown me
  initList(me)
end

on mouseUp me
  branchToScores(me)
end

on initList me
  if not listp(gSwScoreSetupList) then
    gSwScoreSetupList = [:]
    sort(gSwScoreSetupList)
  end if
  put string("DailytrackState: " & gGame.DailyChallenge)
  put string("Score: " & gGame.HighscoreMember.text)
  if gGame.DailyChallenge = 1 then
    tGameID = "br3dailychallenge_hs"
    tTitle = "BR3: Daily Challenge"
  else
    tGameID = convertToLowerCase(0, "br3" & gGame.world & "Track" & gGame.track & "_hs")
    tTitle = gGame.selectedLocation & " " & gGame.GameMode
  end if
  put string(tGameID)
  put string(tTitle)
  AddToList(me, #gameid, tGameID)
  AddToList(me, #gametitle1, tTitle)
  AddToList(me, #gametitle2, EMPTY)
  AddToList(me, #width, pScreenW)
  AddToList(me, #height, pScreenH)
  AddToList(me, #userName, EMPTY)
  AddToList(me, #userscore, pScoreMem.text)
  AddToList(me, #scoredesc, pScoreDes)
  AddToList(me, #movielocation, the moviePath & the movieName)
  AddToList(me, #optional1, [])
  AddToList(me, #optional2, [])
  AddToList(me, #optional3, [])
  AddToList(me, #Function, pFunction)
  AddToList(me, #status, #start)
end

on AddToList me, whatProp, whatValue
  if voidp(getaProp(gSwScoreSetupList, whatProp)) then
    addProp(gSwScoreSetupList, whatProp, whatValue)
  else
    setaProp(gSwScoreSetupList, whatProp, whatValue)
  end if
end

on branchToScores me
  case (the environment).runMode of
    "Plugin":
      if (the environment).shockMachine = 1 then
        myURL = setupGlobalBranch(me)
      else
        if the moviePath contains "http://" then
          myURL = setupGlobalBranch(me)
        else
          myURL = EMPTY
        end if
      end if
      gSwScoreNetID = [gotoNetMovie(myURL), myURL]
    "Author":
      repeat with n = 1 to count(the windowList)
        if (the windowList)[n].name contains "scorez-2000" then
          forget(window(n))
        end if
      end repeat
      open(window("http://www.shockwave.com/content/highscores/nosave/hshub-2000-2.dcr"))
    "Projector":
  end case
  go(pmarker)
end

on setupGlobalBranch me
  if not voidp(externalParamValue("swURL")) then
    myURL = externalParamValue("swURL")
  else
    myGameURL = the moviePath
    the itemDelimiter = "/"
    mySite = item 3 of myGameURL
    if (myGameURL contains "http://") and (mySite contains "shockwave.com") then
      the itemDelimiter = "."
      myPrefix = item 1 of mySite
      myURL = "http://" & myPrefix & ".shockwave.com/content/highscores/scorez-2000.dcr"
    else
      myURL = "http://www.shockwave.com/content/highscores/scorez-2000.dcr"
    end if
  end if
  return myURL
end
