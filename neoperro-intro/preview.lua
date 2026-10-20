local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')
local ContentProvider = game:GetService('ContentProvider')
local SoundService = game:GetService('SoundService')

local environment = type(getgenv) == 'function' and getgenv() or _G
local stateKey = '__neoperroIntroPreviewRuntime'
local previous = environment[stateKey]
if type(previous) == 'table' and type(previous.Destroy) == 'function' then
    previous:Destroy()
end

local options = environment.neoperroIntroPreview
if type(options) ~= 'table' then options = {} end
local duration = tonumber(options.Duration) or 3.2
if duration ~= duration or duration == math.huge or duration == -math.huge then
    duration = 3.2
end
duration = math.clamp(duration, 2, 10)
local blurTail = tonumber(options.BlurTail) or 1.6
if blurTail ~= blurTail or blurTail == math.huge or blurTail == -math.huge then blurTail = 1.6 end
blurTail = math.clamp(blurTail, 0.5, 4)
local withSound = options.Sound ~= false

local state = {Alive = true, Objects = {}, Tweens = {}, Workers = {}}
environment[stateKey] = state

function state:Destroy()
    if not self.Alive then return end
    self.Alive = false
    for _, tween in ipairs(self.Tweens) do
        pcall(function() tween:Cancel() end)
    end
    for _, worker in ipairs(self.Workers) do
        if worker ~= coroutine.running() then pcall(task.cancel, worker) end
    end
    for i = #self.Objects, 1, -1 do
        pcall(function() self.Objects[i]:Destroy() end)
    end
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
    if not alive() then return end
    local animation = TweenService:Create(
        object, TweenInfo.new(seconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties
    )
    table.insert(state.Tweens, animation)
    animation:Play()
    return animation
end

local function worker(callback)
    local thread = coroutine.create(callback)
    table.insert(state.Workers, thread)
    task.spawn(thread)
end

local assetBase = 'https://raw.githubusercontent.com/kasztingers11-lang/mysite/c639f51026efe14a602368f0dc6865616ccc8a5a/neoperro-intro/assets/'
local registerAsset = getcustomasset or getsynasset
local httpRequest = request or http_request or (syn and syn.request)

local function fetch(url)
    if type(httpRequest) == 'function' then
        local response = httpRequest({Url = url, Method = 'GET'})
        local code = tonumber(response and response.StatusCode)
        if type(response) ~= 'table' or (code and (code < 200 or code >= 300)) then
            error('Asset request failed')
        end
        if type(response.Body) ~= 'string' then error('Missing asset body') end
        return response.Body
    end
    return game:HttpGet(url)
end

local function loadAsset(name, prefix, expectedBytes)
    if type(registerAsset) ~= 'function' or type(writefile) ~= 'function' then
        error('Local assets require getcustomasset and writefile')
    end
    local path = 'neoperro-intro-v1-' .. name
    if type(makefolder) == 'function' and type(isfolder) == 'function' then
        local ok = pcall(function()
            if not isfolder('neoperro') then makefolder('neoperro') end
            if not isfolder('neoperro/intro-v1') then makefolder('neoperro/intro-v1') end
        end)
        if ok then path = 'neoperro/intro-v1/' .. name end
    end
    local valid = false
    if type(isfile) == 'function' and type(readfile) == 'function' then
        local ok, data = pcall(function()
            if isfile(path) then return readfile(path) end
        end)
        valid = ok and type(data) == 'string' and #data == expectedBytes
            and data:sub(1, #prefix) == prefix
    end
    if not valid then
        local data = fetch(assetBase .. name)
        if not alive() then return nil end
        if type(data) ~= 'string' or #data ~= expectedBytes or data:sub(1, #prefix) ~= prefix then
            error('Unexpected asset response: ' .. name)
        end
        writefile(path, data)
    end
    if not alive() then return nil end
    return registerAsset(path)
end

local function run()
    local player = Players.LocalPlayer
    assert(player, 'Run this preview on the client')
    local playerGui = player:WaitForChild('PlayerGui', 5)
    if not alive() then return end
    assert(playerGui, 'PlayerGui is unavailable')

    local screen = make('ScreenGui', {
        Name = 'NeoperroIntroPreview', ResetOnSpawn = false,
        IgnoreGuiInset = true, DisplayOrder = 10000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    local letterGroup = make('CanvasGroup', {
        Name = 'LetterGroup', AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 440),
        BorderSizePixel = 0, BackgroundTransparency = 1, GroupTransparency = 1,
    }, screen)

    local logoContainer = make('Frame', {
        Name = 'Swirl', AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 300),
        BackgroundTransparency = 1, Rotation = -225,
    }, letterGroup)
    local logoScale = make('UIScale', {Scale = 0.08}, logoContainer)

    local logo = make('ImageLabel', {
        Name = 'Monogram', AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false,
    }, logoContainer)

    local fallback = make('TextLabel', {
        Name = 'Fallback', Text = 'N', Font = Enum.Font.Antique, TextSize = 150,
        TextColor3 = Color3.fromRGB(248, 245, 235), BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
    }, logoContainer)

    local blur = make('BlurEffect', {Name = 'NeoperroIntroBlur', Size = 0}, Lighting)
    local soundGroup = make('SoundGroup', {
        Name = 'NeoperroIntroResonance', Volume = 1,
    }, SoundService)
    make('ReverbSoundEffect', {
        Name = 'Cathedral', DecayTime = 2.8, Density = 0.9,
        Diffusion = 0.95, DryLevel = -2, WetLevel = -5,
    }, soundGroup)
    local sound = make('Sound', {
        Name = 'NeoperroIntroBell', Volume = 0.22,
        PlaybackSpeed = 0.52, SoundGroup = soundGroup,
    }, SoundService)
    local undertone = make('Sound', {
        Name = 'NeoperroIntroUndertone', Volume = 0.07,
        PlaybackSpeed = 0.26, SoundGroup = soundGroup,
    }, SoundService)
    local logoReady, soundReady = false, false
    local logoFinished, soundFinished = false, not withSound

    worker(function()
        local ok, reason = pcall(function()
            local id = loadAsset('neoperro-n.png', '\137PNG\r\n\26\n', 327349)
            if not alive() or not id then return end
            logo.Image = id
            ContentProvider:PreloadAsync({logo})
            if alive() then logoReady = logo.IsLoaded end
        end)
        logoFinished = true
        if not ok and alive() then warn('[neoperro intro] Image fallback: ' .. tostring(reason)) end
    end)

    if withSound then
        worker(function()
            local ok, reason = pcall(function()
                local id = loadAsset('neoperro-chime.ogg', 'OggS', 7825)
                if not alive() or not id then return end
                sound.SoundId = id
                ContentProvider:PreloadAsync({sound})
                if alive() then soundReady = sound.IsLoaded end
            end)
            soundFinished = true
            if not ok and alive() then warn('[neoperro intro] Sound unavailable: ' .. tostring(reason)) end
        end)
    end

    local deadline = os.clock() + 8
    while alive() and not (logoFinished and soundFinished) and os.clock() < deadline do
        task.wait(0.03)
    end
    if not alive() then return end

    logo.Visible = logoReady
    fallback.Visible = not logoReady
    if not logoReady then warn('[neoperro intro] Using text N; image was unavailable or timed out') end
    if withSound and soundReady then
        undertone.SoundId = sound.SoundId
        sound:Play()
        undertone:Play()
    end

    local enter = math.min(1.05, duration * 0.4)
    local leave = math.min(0.6, duration * 0.25)
    tween(blur, enter, {Size = 22})
    tween(letterGroup, 0.3, {GroupTransparency = 0})
    tween(logoContainer, enter, {Rotation = 0})
    tween(logoScale, enter, {Scale = 1})

    task.wait(duration - leave)
    if not alive() then return end
    tween(logoContainer, leave, {Rotation = 12})
    tween(logoScale, leave, {Scale = 1.08})
    local fade = tween(letterGroup, leave, {GroupTransparency = 1})
    fade.Completed:Wait()
    if not alive() then return end

    tween(soundGroup, blurTail, {Volume = 0})
    local clearBlur = tween(blur, blurTail, {Size = 0})
    clearBlur.Completed:Wait()
end

worker(function()
    local ok, reason = xpcall(run, debug.traceback)
    state:Destroy()
    if not ok then warn('[neoperro intro] ' .. tostring(reason)) end
end)

return state
