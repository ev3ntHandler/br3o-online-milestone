property p
global g

on new me, tParams
  p = [:]
  p[#member] = member(tParams[#memberName])
  p[#controller] = tParams[#controller]
  p[#tag] = tParams[#tag]
  p[#CarName] = "Car"
  p[#collModelName] = tParams[#collModelName]
  tParams = VOID
  p[#reset] = 0
  me.SetupCarMixer()
  p[#me] = me
  p[#ScriptLimit] = 0
  return me
end

on SetupCarMixer tTag, tNr
  t = g.cars[1]
  t[#sound] = [:]
  t.sound[#Mixer] = CreateMixer()
  t.sound.Mixer.volume = 128
  t.sound[#channel] = g.sound.DataSoundChannels.count + 1
  t.sound[#rate] = 1.0
  t.sound[#engine] = t.sound.Mixer.createSoundObject("Engine", member("Engine01_SFX"), [#loopCount: 0, #playRate: t.sound.rate])
  t.sound.engine.volume = 255
  t.sound[#filter] = audioFilter(#PitchShiftFilter, [#Shift: t.sound.rate])
  t.sound.engine.filterList.append(t.sound.filter)
  t.sound[#slip] = t.sound.Mixer.createSoundObject("Drift", member("Drift_SFX"), [#loopCount: 0, #loopStartTime: 10])
  t.sound.slip.volume = 0
  t.sound.Mixer.play()
  if g.sound.mute = 1 then
    sound(t.sound.channel).volume = 0
  else
    sound(t.sound.channel).volume = 255
  end if
end

on enterFrame me
  t = g.cars[1]
  if (t.state = "Done") or (t.state = "Finished") then
    if p.reset = 0 then
      me.reset()
    end if
    exit
  end if
  tPerc = t.specifics.speedMS / t.specifics.maxSpeed
  tRate = 1.0 + (tPerc * 1.69999999999999996)
  tRate = max(1.0, min(tRate, 5.0))
  if t.sound.filter.Shift <> tRate then
    t.sound.filter.Shift = tRate
  end if
  if (t.specifics.falling = 0) and (t.Keys.brake = 1) then
    tVolume = integer(160 * tPerc)
  else
    tVolume = 0
  end if
  t.sound.slip.volume = tVolume
  if g.sound.mute = 1 then
    sound(t.sound.channel).volume = 0
  end if
  t.sound.Mixer.volume = 128
end

on reset me
  t = g.cars[1]
  t.sound.engine.volume = 0
  t.sound.slip.volume = 0
  p.reset = 1
end
