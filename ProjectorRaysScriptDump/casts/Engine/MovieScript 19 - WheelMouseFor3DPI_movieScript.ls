on WheelMouseEvent val
  tell the frontWindow
    sendSprite(1, #do3DPI_WheelMouseEvent, val)
  end tell
end
