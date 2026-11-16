property p
global g

on beginSprite me
  p = [:]
  p[#sprite] = sprite(me.spriteNum)
  p[#member] = p.sprite.member
  if p.member.type = #text then
    p.member.text = "0%"
  end if
  p[#LoadingSprite] = sprite(me.spriteNum + 1)
  p[#LoadingSpriteData] = [0, 130]
  p.LoadingSprite.width = p.LoadingSpriteData[1]
end

on enterFrame me
  if p.member.type = #text then
    if getaProp(g, #DownloadPercentage) <> VOID then
      if g.DownloadPercentage.ilk = #float then
        pString = string(integer(g.DownloadPercentage * 100.0)) & "%"
        p.member.text = pString
        p.LoadingSprite.width = g.DownloadPercentage * p.LoadingSpriteData[2]
      else
        p.member.text = "No float, no info..."
      end if
    end if
  end if
end
