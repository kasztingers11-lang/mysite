-- Keep Width=5 / Height=4.3. The box follows the character's perspective.
-- Physical dimensions stay fixed within each gun-profile range; no size smoothing.
local function projectBox(camera, position, width, height)
    local point = camera:WorldToViewportPoint(position)
    if point.Z <= 0.1 then return nil end
    local focal = camera.ViewportSize.Y / (2 * math.tan(math.rad(camera.FieldOfView) / 2))
    local scale = focal / point.Z
    local pixelWidth, pixelHeight = width * scale, height * scale
    return Vector2.new(point.X - pixelWidth / 2, point.Y - pixelHeight / 2),
        Vector2.new(pixelWidth, pixelHeight)
end

-- Gun Specifications picks width/height by Close/Medium/Far before this formula.
return projectBox
