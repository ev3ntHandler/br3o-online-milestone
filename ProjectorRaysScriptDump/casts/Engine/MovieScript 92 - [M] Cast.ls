on ClearCast tCast
  if _movie.castLib(tCast) = VOID then
    ShowError("ClearCast: no such cast exists. Cast called was: " & tCast)
    exit
  end if
  pCount = _movie.castLib(tCast).member.count
  EraseMembers(1, pCount, tCast)
end

on ClearCasts tCastList
  if tCastList.ilk <> #list then
    ShowError("ClearCasts: parameter was not a linearList. List calles was: " & tCastList)
    exit
  end if
  pCount = tCastList.count
  repeat with i = 1 to pCount
    tCast = tCastList[i]
    if _movie.castLib(tCast) = VOID then
      ShowError("ClearCasts: no such cast exists. Cast called was: " & tCast)
      next repeat
      next repeat
    end if
    pMemberCount = _movie.castLib(tCast).member.count
    EraseMembers(1, pMemberCount, tCast)
  end repeat
end
