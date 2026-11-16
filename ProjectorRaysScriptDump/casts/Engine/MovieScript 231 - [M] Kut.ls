global g, gGame, gData

on roughVram me, tList
  tList = ["Main", "Hangar", "Earth", "Car", "Logo"]
  tResult = EMPTY
  tTotalRam = 0
  repeat with j in tList
    tmember = member(j)
    tMemberRam = 0
    repeat with i = 1 to tmember.texture.count
      tTexture = member("Main").texture[i]
      if (tTexture.renderFormat = #rgba8888) or (tTexture.renderFormat = #rgba8880) then
        tBit = 32
      else
        tBit = 16
      end if
      tTextureRam = tTexture.height * tTexture.width * tBit / 8.0 / 1024.0 / 1024.0
      tMemberRam = tMemberRam + tTextureRam
    end repeat
    tTotalRam = tTotalRam + tMemberRam
    tResult = tResult && j & ": " & string(tMemberRam) && " "
  end repeat
  put "very rough VRAM usage. Excluding all frame buffers"
  put tResult
  put "Total ram: " & tTotalRam
end

on REPAIR me
  gGame.currentCar = gGame.cars[1].general.tag
  event(#RepairPickup)
  gGame.currentCar = #none
end

on doIt me
  p = [:]
  p[#member] = member("Main")
  tText = "DOWNLOADING SHARED DATA 100 %"
  CreateTextTexture(0, p.member.name, [#text: tText, #texture: "Downloading_Texture", #fontSize: 10, #align: #right, #color: gData.data.TextColor.White, #width: 256, #filters: [gData.data.ButtonFilters.BR3GlowWhite]])
  ASSIGNTEXTURE(p.member.name, [#material: "Downloading_Material", #texture1: "Downloading_Texture"])
end

on repeatDown me
  t1 = 20
  t2 = 1
  repeat with j = t1 to t2
    put j
  end repeat
end

on test1 me
  AddToInterPolator(0, "Hangar", [#object: "Hangar_CameraTarget", #target: "Nissan_CameraTarget", #Percentage: 10])
end

on test2 me
  AddToInterPolator(0, "Hangar", [#object: "Hangar_CameraTarget", #target: "BMW_CameraTarget", #Percentage: 10])
end

on test3 me
  AddToInterPolator(0, "Hangar", [#object: "Hangar_CameraTarget", #target: "Eclipse_CameraTarget", #Percentage: 10])
end

on test4 me
  AddToInterPolator(0, "Hangar", [#object: "Hangar_CameraTarget", #target: "AudiR8_CameraTarget", #Percentage: 10])
end

on test234321 me
  AddToPointAt(0, "Earth", [#object: "Earth_Camera", #target: "Earth_CameraTarget"])
  AddToInterPolator(0, "Earth", [#object: "Earth_Camera", #target: "America_Camera", #Percentage: 3])
  AddToInterPolator(0, "Earth", [#object: "Earth_CameraTarget", #target: "America_CameraTarget", #Percentage: 5])
end

on test234232 me
  AddToInterPolator(0, "Earth", [#object: "Earth_Camera", #target: "Asia_Camera", #Percentage: 3])
  AddToInterPolator(0, "Earth", [#object: "Earth_CameraTarget", #target: "Asia_CameraTarget", #Percentage: 5])
end

on test3453434 me
  AddToInterPolator(0, "Earth", [#object: "Earth_Camera", #target: "Africa_Camera", #Percentage: 3])
end
