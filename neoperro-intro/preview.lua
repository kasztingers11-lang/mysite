local onShown = ...
local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')
local ContentProvider = game:GetService('ContentProvider')
local SoundService = game:GetService('SoundService')
local Workspace = game:GetService('Workspace')

local environment = type(getgenv) == 'function' and getgenv() or _G
local stateKey = '__neoperroIntroPreviewRuntime'
local previous = environment[stateKey]
if type(previous) == 'table' and type(previous.Destroy) == 'function' then previous:Destroy() end

local state = {Alive = true, Shown = false, Objects = {}, Tweens = {}, Workers = {}, Assets = {}}
environment[stateKey] = state

function state:Destroy()
    if not self.Alive then return end
    self.Alive = false
    for _, tween in ipairs(self.Tweens) do pcall(function() tween:Cancel() end) end
    for _, worker in ipairs(self.Workers) do
        if worker ~= coroutine.running() then pcall(task.cancel, worker) end
    end
    for i = #self.Objects, 1, -1 do pcall(function() self.Objects[i]:Destroy() end) end
    self.Objects, self.Tweens, self.Workers = {}, {}, {}
    if environment[stateKey] == self then environment[stateKey] = nil end
end

local function alive()
    return state.Alive and environment[stateKey] == state
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    table.insert(state.Objects, object)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end

local function tween(object, seconds, properties)
    if not object or not alive() then return end
    local animation = TweenService:Create(object, TweenInfo.new(seconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
    table.insert(state.Tweens, animation)
    animation:Play()
end

local function worker(callback)
    local thread = coroutine.create(callback)
    table.insert(state.Workers, thread)
    task.spawn(thread)
end

local function pause(seconds)
    task.wait(seconds)
    return alive()
end

local wordmarkPng = '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'
local soundUrl = 'https://raw.githubusercontent.com/kasztingers11-lang/mysite/b2d6c13c7ee8030d8a1ff09da60386b9229ad61e/neoperro-intro/assets/neoperro-dark-meow.ogg'
local registerAsset = getcustomasset or getsynasset
local canRegister = type(registerAsset) == 'function' and type(writefile) == 'function'

local function decodePng()
    local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local value = {}
    for i = 1, #alphabet do value[alphabet:byte(i)] = i - 1 end
    return (wordmarkPng:gsub('....', function(chunk)
        local a, b, c, d = chunk:byte(1, 4)
        local first = value[a] * 4 + math.floor(value[b] / 16)
        if c == 61 then return string.char(first) end
        local second = (value[b] % 16) * 16 + math.floor(value[c] / 4)
        if d == 61 then return string.char(first, second) end
        return string.char(first, second, (value[c] % 4) * 64 + value[d])
    end))
end

local function readAsset(path)
    if type(isfile) ~= 'function' or type(readfile) ~= 'function' then return nil end
    local ok, data = pcall(function() return isfile(path) and readfile(path) or nil end)
    if ok then return data end
end

local function register(path, data)
    if not alive() then return nil end
    if data then writefile(path, data) end
    if not alive() then return nil end
    local id = registerAsset(path)
    return type(id) == 'string' and id ~= '' and id or nil
end

local function wordmarkId()
    local path = 'neoperro-intro-v2-wordmark.png'
    local data = decodePng()
    local cached = readAsset(path)
    if cached == data then return register(path) end
    return register(path, data)
end

local function soundId()
    local path = 'neoperro-intro-v2-meow.ogg'
    local function valid(data)
        return type(data) == 'string' and #data == 13158 and data:sub(1, 4) == 'OggS'
    end
    if valid(readAsset(path)) then return register(path) end
    local data = game:HttpGet(soundUrl)
    if valid(data) then return register(path, data) end
end

local function preload(object)
    local fetched = false
    ContentProvider:PreloadAsync({object}, function(_, status)
        if status == Enum.AssetFetchStatus.Success then fetched = true end
    end)
    return fetched or object.IsLoaded
end

local eyeRows = {
    {1, 6, 118, 122},
    {1, 11, 113, 122},
    {2, 16, 107, 122},
    {2, 16, 107, 121},
    {3, 17, 106, 120},
    {3, 17, 23, 26, 98, 100, 106, 120},
    {4, 18, 23, 28, 95, 100, 106, 119},
    {6, 18, 22, 30, 93, 101, 105, 118},
    {7, 19, 21, 32, 91, 102, 104, 116},
    {9, 34, 90, 114},
    {11, 35, 88, 112},
    {14, 36, 87, 109},
    {20, 36, 87, 103},
}

local function drawEyes(parent, width, height)
    local canvas = make('Frame', {
        Name = 'Eyes', Size = UDim2.fromOffset(width, height), BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    }, parent)
    local red = Color3.fromRGB(255, 0, 25)
    for row, spans in ipairs(eyeRows) do
        local top = math.floor((row - 1) * height / #eyeRows)
        local bottom = math.floor(row * height / #eyeRows)
        for i = 1, #spans, 2 do
            local left = math.floor(spans[i] * width / 123)
            local right = math.ceil(spans[i + 1] * width / 123)
            make('Frame', {
                BackgroundColor3 = red, BorderSizePixel = 0, Position = UDim2.fromOffset(left, top),
                Size = UDim2.fromOffset(right - left, bottom - top),
            }, canvas)
        end
    end
end

local function run()
    local player = Players.LocalPlayer
    assert(player, 'Run this intro on the client')
    local playerGui = player:FindFirstChild('PlayerGui') or player:WaitForChild('PlayerGui', 5)
    if not alive() then return end
    assert(playerGui, 'PlayerGui is unavailable')

    local screen = make('ScreenGui', {
        Name = 'NeoperroIntroPreview', ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 10000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)
    local shade = make('Frame', {
        Size = UDim2.fromScale(1, 1), BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
    }, screen)

    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
    local viewWidth = viewport and viewport.X > 100 and viewport.X or 800
    local viewHeight = viewport and viewport.Y > 100 and viewport.Y or 600
    local width = math.floor(math.min(448, viewWidth * 0.62, viewHeight * 0.9))
    local titleHeight = math.floor(width * 163 / 538)
    local eyeWidth = math.max(36, math.floor(width * 0.27))
    local eyeHeight = math.max(#eyeRows, math.floor(eyeWidth * 26 / 123))
    local gap = math.max(10, math.floor(width * 0.045))
    local lockup = make('Frame', {
        Name = 'Lockup', AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, titleHeight + gap + eyeHeight), BackgroundTransparency = 1,
    }, shade)
    local eyelids = make('Frame', {
        Name = 'Eyelids', AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, eyeHeight / 2),
        Size = UDim2.fromOffset(eyeWidth, 0), ClipsDescendants = true, BackgroundTransparency = 1,
    }, lockup)
    drawEyes(eyelids, eyeWidth, eyeHeight)

    local title = make('ImageLabel', {
        Name = 'SiteWordmark', ImageTransparency = 1, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
        Position = UDim2.fromOffset(0, eyeHeight + gap + 9), Size = UDim2.fromOffset(width, titleHeight),
    }, lockup)
    local blur
    pcall(function() blur = make('BlurEffect', {Name = 'NeoperroIntroBlur', Size = 0}, Lighting) end)

    local titleReady, soundReady
    if canRegister then
        worker(function()
            local ok = pcall(function()
                local id = wordmarkId()
                if not id or not alive() then return end
                title.Image = id
                titleReady = preload(title)
            end)
            if alive() then state.Assets.Wordmark = ok and titleReady and 'loaded' or 'fallback' end
        end)
        worker(function()
            local ok = pcall(function()
                local id = soundId()
                if not id or not alive() then return end
                local sound = make('Sound', {Name = 'NeoperroIntroMeow', SoundId = id, Volume = 0.3}, SoundService)
                if preload(sound) and alive() then soundReady = sound end
            end)
            if alive() then state.Assets.Sound = ok and soundReady and 'loaded' or 'unavailable' end
        end)
    end

    tween(shade, 0.22, {BackgroundTransparency = 0.08})
    tween(blur, 0.24, {Size = 18})
    if not pause(0.28) then return end

    local activeTitle, opacity = title, 'ImageTransparency'
    if not titleReady and not title.IsLoaded then
        activeTitle = make('TextLabel', {
            Name = 'WordmarkFallback', Text = 'neoperro', Font = Enum.Font.Antique, TextScaled = true,
            TextTransparency = 1, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
            Position = title.Position, Size = title.Size,
        }, lockup)
        make('UITextSizeConstraint', {MaxTextSize = math.max(12, math.floor(width / 5))}, activeTitle)
        opacity = 'TextTransparency'
    end
    state.Assets.Display = opacity == 'ImageTransparency' and 'image' or 'fallback'
    tween(activeTitle, 0.38, {Position = UDim2.fromOffset(0, eyeHeight + gap), [opacity] = 0})
    state.Shown = true
    if type(onShown) == 'function' then onShown() end
    if not pause(0.10) then return end

    tween(eyelids, 0.40, {Size = UDim2.fromOffset(eyeWidth, eyeHeight)})
    if soundReady then pcall(function() soundReady:Play() end) end
    if not pause(1.15) then return end

    tween(eyelids, 0.21, {Size = UDim2.fromOffset(eyeWidth, 0)})
    if not pause(0.19) then return end

    tween(activeTitle, 0.36, {[opacity] = 1})
    tween(shade, 0.53, {BackgroundTransparency = 1})
    tween(blur, 0.53, {Size = 0})
    tween(soundReady, 0.37, {Volume = 0})
    pause(0.55)
end

worker(function()
    local ok, reason = xpcall(run, debug.traceback)
    state:Destroy()
    if not ok then warn('[neoperro intro] ' .. tostring(reason)) end
end)

return state
