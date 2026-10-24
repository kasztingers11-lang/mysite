-- Same dimensions at every distance/FOV. Keep Width=5 / Height=4.3.
-- One size unit = 16 pixels, independent of display resolution.
local function projectBox(camera, position, width, height)
    local point = camera:WorldToViewportPoint(position)
    if point.Z <= 0.1 then return nil end
    local pixelWidth, pixelHeight = width * 16, height * 16
    return Vector2.new(point.X - pixelWidth / 2, point.Y - pixelHeight / 2),
        Vector2.new(pixelWidth, pixelHeight)
end

-- Gun Specifications picks width/height by Close/Medium/Far before this formula.
return projectBox
