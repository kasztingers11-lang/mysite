-- Bundler supplies Core, Posture, Defaults and playIntro; this is the readable runtime body.
local environment = type(getgenv) == 'function' and getgenv() or _G
local launchConfig = ...
if type(launchConfig) ~= 'table' then launchConfig = environment.neoperro end
local supported = {
    [134196333708867] = 'Da Strike',
    [71324444457408] = 'Da Uphill',
    [139144803593140] = 'Da Downhill',
}
assert(supported[game.PlaceId], '[neoperro] This place is not supported.')
assert(type(launchConfig) == 'table', '[neoperro] Put the configuration above the runtime.')
local suppliedConfig = Core.normalizeConfig(launchConfig)
local config = Core.merge(Defaults, suppliedConfig)
Core.validate(Defaults, config)
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Input = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local World = game:GetService('Workspace')
local localPlayer = Players.LocalPlayer
assert(localPlayer, '[neoperro] Run on the client.')
local mouse = localPlayer:GetMouse()
environment.__neoperroStartEpoch = (environment.__neoperroStartEpoch or 0) + 1
local startEpoch = environment.__neoperroStartEpoch
local playerGui = localPlayer:WaitForChild('PlayerGui', 5)
assert(playerGui, '[neoperro] PlayerGui unavailable.')
assert(environment.__neoperroStartEpoch == startEpoch, '[neoperro] A newer execution superseded this startup.')
local runtimeKey, hooksKey = '__neoperroRuntimeV1', '__neoperroHooksV1'
local previous = environment[runtimeKey]
if previous and previous.Intro then environment.__neoperroIntroSeenV1 = true end
local saved = previous and previous.Alive and type(previous.Snapshot) == 'function' and previous:Snapshot() or nil
if previous and type(previous.Destroy) == 'function' then previous:Destroy('replace') end

local state = {
    Alive = true, Version = '1.3.17', Distribution = 'Development', Config = config, Connections = {}, Objects = {},
    Records = {}, Toggles = {}, Held = {}, Locks = {}, Points = {}, Targets = {},
    Warnings = {}, Capabilities = {}, ShotUntil = 0, NextFire = 0, Initial = {},
    Whitelist = Core.ids(config.Whitelist.Players), WhiteMode = config.Whitelist.Method,
    InitialWhitelist = Core.ids(config.Whitelist.Players), InitialWhiteMode = config.Whitelist.Method,
    Epoch = 0, Visuals = {}, Focused = true,
    Stats = {AimPackets = 0, AimSendReturns = 0, AimSendErrors = 0, AimSendSkipped = 0, AimRestores = 0, AimRestoreErrors = 0, Activations = 0, TriggerAttempts = 0, AmmoDrops = 0},
    AimTrace = {}, Trace = {Events = {}, Sequence = 0, Until = 0, Limit = 128},
    Network = {NextSample = 0}, Performance = {Updates = 0, TotalMs = 0, MaxMs = 0, AimUpdates = 0, AimTotalMs = 0, AimMaxMs = 0},
    ControlOwned = false, MouseOwned = false, PrefireToggle = false,
    CursorHit = nil, ShotRelease = nil, AutomatedTool = nil, MacroMotion = nil,
    TriggerRandom = nil, LastMousePayload = nil, MouseRemainder = nil, Intro = nil,
    ToolEpoch = 0, AutoPrediction = {Interval = 0.5, Refreshes = 0, Features = {}},
    PostureStats = {Samples = 0, Changes = 0},
    WhiteLookup = {}, WhiteLookupSource = nil, WhiteLookupCount = -1,
}
environment[runtimeKey] = state
local zero = Vector3.new(0, 0, 0)
local now = os.clock
local camera, cursor, cursorRay
local localCharacter, localHumanoid, localRoot, equipped, weaponName, muzzleAttachment
local releaseShotInput
local charConnections, toolConnections = {}, {}
local pendingPrefire, macro, activation
local renderName = 'neoperro.' .. tostring(now())
local featureNames = {'Silent Aim', 'Aim Assist', 'Triggerbot', 'ESP'}
local checkIndices = {['Silent Aim'] = 1, ['Aim Assist'] = 2, Triggerbot = 3}
local virtualInput
pcall(function() virtualInput = game:GetService('VirtualInputManager') end)

local function vectorData(v)
    if not v then return nil end
    return {X = v.X, Y = v.Y, Z = v.Z}
end

-- Opt-in, bounded evidence. No console spam, instance references or executor data.
function state:StartTrace(seconds, limit)
    self.Trace = {Events = {}, Sequence = 0, Until = now() + Core.number(seconds, 10, 0.1, 30),
        Limit = math.floor(Core.number(limit, 128, 1, 256))}
end

function state:StopTrace() self.Trace.Until = 0 end

function state:ReadTrace() return Core.copy(self.Trace) end

local function traceEvent(kind, data)
    local trace = state.Trace
    if not state.Alive or now() >= trace.Until then return end
    trace.Sequence = trace.Sequence + 1
    local event = Core.copy(data or {})
    event.Kind, event.Time, event.Sequence = kind, now(), trace.Sequence
    trace.Events[#trace.Events + 1] = event
    if #trace.Events > trace.Limit then table.remove(trace.Events, 1) end
end

function state:Diagnose()
    local result = {Version = self.Version, Alive = self.Alive, Capabilities = Core.copy(self.Capabilities),
        Stats = Core.copy(self.Stats), Warnings = Core.copy(self.Warnings), Targets = {}, Boxes = {},
        AimRestore = Core.copy(self.LastAimRestore), Prefire = Core.copy(self.LastPrefire), MacroCheck = Core.copy(self.LastMacroCheck),
        MouseOwned = self.MouseOwned == true, ControlOwned = self.ControlOwned == true,
        Equipped = equipped and equipped.Name or nil, Remote = self.Remote and self.Remote.Name or nil,
        Aim = Core.copy(self.AimTrace), LastSend = Core.copy(self.LastSend), Network = Core.copy(self.Network),
        Performance = Core.copy(self.Performance), Input = self.InputStatus and self:InputStatus(),
        ConfigUpdates = self.ConfigUpdates, LastConfigMs = self.LastConfigMs,
        StartupProtection = Core.copy(self.StartupProtection),
        PostureStats = Core.copy(self.PostureStats), ShotRoute = Core.copy(self.LastShotRoute),
        AutoPrediction = Core.copy(self.AutoPrediction),
        ShotResult = 'unverified; activation and MOUSE submission do not establish damage'}
    for name, player in pairs(self.Targets) do result.Targets[name] = player.UserId end
    for _, record in pairs(self.Records) do
        if record.BoxInfo then result.Boxes[tostring(record.player.UserId)] = Core.copy(record.BoxInfo) end
    end
    return result
end

local function warnOnce(key, message)
    if state.Warnings[key] then return end
    state.Warnings[key] = message
    warn('[neoperro] ' .. message)
end

local function disconnect(list)
    for _, connection in ipairs(list) do connection:Disconnect() end
    for i = #list, 1, -1 do list[i] = nil end
end

local function connect(signal, callback, bucket)
    local connection = signal:Connect(function(...)
        if state.Alive then callback(...) end
    end)
    table.insert(bucket or state.Connections, connection)
    return connection
end

local function own(object)
    state.Objects[#state.Objects + 1] = object
    return object
end

local function make(class, props, parent)
    local object = Instance.new(class)
    for k, v in pairs(props) do object[k] = v end
    object.Parent = parent
    return object
end

local function validPlayer(id)
    return type(id) == 'number' and Players:GetPlayerByUserId(id) or nil
end

for _, name in ipairs(featureNames) do
    state.Initial[name] = config[name].Enabled == true
    state.Toggles[name] = state.Initial[name]
    if saved and config[name].Toggle.Enabled then
        state.Toggles[name] = Core.restoreToggle(state.Initial[name], saved.Initial[name], saved.Toggles[name])
    end
    if saved and saved.Locks[name] and validPlayer(saved.Locks[name]) then state.Locks[name] = saved.Locks[name] end
end
if saved and config.Whitelist.Enabled and saved.WhitelistEnabled ~= false then
    if Core.equal(state.InitialWhitelist, saved.InitialWhitelist) then state.Whitelist = Core.ids(saved.Whitelist) end
    if state.InitialWhiteMode == saved.InitialWhiteMode and (saved.WhiteMode == 'Friend' or saved.WhiteMode == 'Target') then
        state.WhiteMode = saved.WhiteMode
    end
end

if not config.Whitelist.Enabled then state.Whitelist = {} end

function state:Snapshot()
    return Core.copy({Initial = self.Initial, Toggles = self.Toggles, Locks = self.Locks,
        Whitelist = self.Whitelist, WhiteMode = self.WhiteMode,
        InitialWhitelist = self.InitialWhitelist, InitialWhiteMode = self.InitialWhiteMode,
        WhitelistEnabled = config.Whitelist.Enabled})
end

local function releaseControl()
    if state.ControlOwned then
        state.ControlOwned = false
        if virtualInput then pcall(function() virtualInput:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game) end) end
    end
end

local function cancelMacro()
    local old = macro
    macro = nil
    releaseControl()
    if old and old.tool and old.tool.Parent == localPlayer:FindFirstChildOfClass('Backpack')
        and localHumanoid and localHumanoid.Health > 0 and localCharacter
        and not localCharacter:FindFirstChildOfClass('Tool') then
        pcall(function() localHumanoid:EquipTool(old.tool) end)
    end
end

function state:Destroy(reason)
    if not self.Alive then return end
    self.Alive = false
    self:StopTrace()
    self.Points, self.Targets = {}, {}
    local hooks = environment[hooksKey]
    if hooks and hooks.Active == self then hooks.Active = nil end
    RunService:UnbindFromRenderStep(renderName)
    disconnect(self.Connections)
    disconnect(charConnections)
    disconnect(toolConnections)
    cancelMacro()
    if releaseShotInput then releaseShotInput() end
    if self.AutomatedTool then pcall(function() self.AutomatedTool:Deactivate() end) end
    for _, record in pairs(self.Records) do disconnect(record.connections); disconnect(record.characterConnections) end
    if self.Intro and self.Intro.Destroy then self.Intro:Destroy() end
    for visual in pairs(self.Visuals) do pcall(function() visual:Destroy() end) end
    for i = #self.Objects, 1, -1 do pcall(function() self.Objects[i]:Destroy() end) end
    if environment[runtimeKey] == self then environment[runtimeKey] = nil end
    if reason ~= 'replace' then print('[neoperro] Unloaded.') end
end

local function holding(slot, binding)
    local ok, down = pcall(function()
        if binding[3] == 'Mouse' then return Input:IsMouseButtonPressed(Enum.UserInputType[binding[2]]) end
        local key = tostring(binding[1] or '')
        if #key == 1 then key = key:upper() end
        return Input:IsKeyDown(Enum.KeyCode[key])
    end)
    if ok then state.Held[slot] = down == true end
    return state.Held[slot] == true
end

local function enabled(name)
    local feature = config[name]
    if feature.Enabled ~= true or not state.Toggles[name] then return false end
    local toggle = feature.Toggle
    if toggle and toggle.Enabled and toggle.Holding and not holding('toggle:' .. name, toggle.Keybind) then return false end
    if name == 'Triggerbot' then
        local gate = feature.Activation
        if gate.Enabled and not (gate.Holding and holding('activation:Triggerbot', gate.Keybind) or
            not gate.Holding and state.Held['activation:Triggerbot']) then return false end
    elseif feature.Activation and feature.Activation.Holding and
        not holding('target:' .. name, feature.Activation.Keybind) then return false
    end
    return true
end

local function typing()
    return not state.Focused or (type(isrbxactive) == 'function' and not isrbxactive()) or Input:GetFocusedTextBox() ~= nil
        or game:GetService('GuiService').MenuIsOpen == true
end

function state:InputStatus()
    local result = {Focused = not typing(), Features = {}}
    for _, name in ipairs({'Silent Aim', 'Aim Assist', 'Triggerbot'}) do
        local feature, activation = config[name], config[name].Activation
        local reason = not feature.Enabled and 'disabled' or not self.Toggles[name] and 'toggle-off' or typing() and 'focus-or-text-input' or nil
        if not reason and feature.Toggle.Enabled and feature.Toggle.Holding and
            not holding('toggle:' .. name, feature.Toggle.Keybind) then reason = 'toggle-not-held' end
        if not reason and activation and activation.Holding and (name ~= 'Triggerbot' or activation.Enabled) and
            not holding(name == 'Triggerbot' and 'activation:Triggerbot' or 'target:' .. name, activation.Keybind) then reason = 'activation-not-held' end
        if not reason and name == 'Triggerbot' and activation.Enabled and not activation.Holding and
            not self.Held['activation:Triggerbot'] then reason = 'activation-off' end
        result.Features[name] = {Ready = reason == nil, Reason = reason,
            Device = activation and activation.Keybind[3],
            Key = activation and (activation.Keybind[3] == 'Mouse' and activation.Keybind[2] or activation.Keybind[1])}
    end
    return result
end

local function captureView()
    camera = World.CurrentCamera
    if not camera then return false end
    -- Viewport projections and IgnoreGuiInset overlays share the raw mouse coordinate space.
    cursor = Input:GetMouseLocation()
    cursorRay = camera:ViewportPointToRay(cursor.X, cursor.Y)
    return true
end

local function childValue(parent, name)
    local item = parent and parent:FindFirstChild(name)
    return item and item:IsA('ValueBase') and item.Value or nil
end

local function ammoObject(tool)
    if not tool then return nil end
    local value = tool:FindFirstChild('AMMO') or tool:FindFirstChild('Ammo')
    return value and (value:IsA('IntValue') or value:IsA('NumberValue')) and value or nil
end

local function ammoCount(tool)
    local value = ammoObject(tool)
    return value and value.Value or nil
end

local function sampleNetwork(time)
    if time < state.Network.NextSample then return end
    state.Network.NextSample = time + 0.5
    local function retain(key, value)
        if type(value) == 'number' and value == value and value > 0 and value < 2 then
            local old = state.Network[key]
            state.Network[key] = old and old + (value - old) * 0.25 or value
        end
    end
    pcall(function() retain('RTT', localPlayer:GetNetworkPing()) end)
    pcall(function()
        local network = game:GetService('Stats'):FindFirstChild('Network')
        local items = network and network:FindFirstChild('ServerStatsItem')
        local item = items and items:FindFirstChild('Data Ping')
        if item and item:IsA('StatsItem') then retain('DataRTT', item:GetValue() / 1000) end
    end)
end

local function crew(player)
    local data = player:FindFirstChild('DataFolder')
    local information = data and data:FindFirstChild('Information')
    return childValue(information, 'Crew') or player:GetAttribute('Crew')
end

local function isKnocked(character)
    local effects = character:FindFirstChild('BodyEffects')
    return childValue(effects, 'K.O') == true or childValue(effects, 'Knocked') == true
        or character:GetAttribute('Knocked') == true or character:GetAttribute('K.O') == true
        or character:FindFirstChild('GRABBING_CONSTRAINT') ~= nil
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local function visible(point, character, origin, excludeTarget)
    if not camera or not Core.finiteVector(point) then return false end
    local exclusions = {camera}
    if localCharacter then exclusions[#exclusions + 1] = localCharacter end
    if excludeTarget and character then exclusions[#exclusions + 1] = character end
    rayParams.FilterDescendantsInstances = exclusions
    origin = origin or camera.CFrame.Position
    local direction = point - origin
    if direction.Magnitude < 0.001 then return true end
    local hit = World:Raycast(origin, direction, rayParams)
    return not hit or (not excludeTarget and character and hit.Instance:IsDescendantOf(character))
end

local function muzzle()
    if equipped and muzzleAttachment and muzzleAttachment.Parent and muzzleAttachment:IsDescendantOf(equipped) then
        return muzzleAttachment.WorldPosition
    end
    local handle = equipped and equipped:FindFirstChild('Handle')
    if handle and handle:IsA('BasePart') then return handle.Position end
    return localRoot and localRoot.Position or (camera and camera.CFrame.Position)
end

local function partFor(record, name)
    local character = record.character
    if not character then return nil end
    local part = character:FindFirstChild(name)
    if not part and name == 'UpperTorso' then part = character:FindFirstChild('Torso') end
    return part and part:IsA('BasePart') and part or record.root
end

local function targetSettings(feature)
    return config[feature].Target or config['Silent Aim'].Target
end

-- Do not aim at game-specific hitbox helpers such as the observed child "fix".
local bodyParts = {Head=true, Torso=true, UpperTorso=true, LowerTorso=true,
    ['Left Arm']=true, ['Right Arm']=true, ['Left Leg']=true, ['Right Leg']=true,
    LeftUpperArm=true, LeftLowerArm=true, LeftHand=true, RightUpperArm=true, RightLowerArm=true, RightHand=true,
    LeftUpperLeg=true, LeftLowerLeg=true, LeftFoot=true, RightUpperLeg=true, RightLowerLeg=true, RightFoot=true}

local function bodyPart(part, character)
    return part and part:IsA('BasePart') and part.Parent == character and bodyParts[part.Name] == true
end

local animationCatalog = {}
local function samplePosture(record, time)
    local pose, changed, sampled = Posture.sample(record, time, animationCatalog, bodyPart)
    record.pose = pose
    if sampled then state.PostureStats.Samples = state.PostureStats.Samples + 1 end
    if changed then
        state.PostureStats.Changes = state.PostureStats.Changes + 1
        record.pointState, record.renderAim = nil, nil
        for name, context in pairs(state.AutoPrediction.Features) do
            if context.Target == record.player.UserId then state.AutoPrediction.Features[name] = nil end
        end
    end
    return pose
end

local function nativeBodyPart(part, character)
    return part and part:IsA('BasePart') and part.Parent == character and part.CanQuery ~= false
        and (bodyParts[part.Name] == true or part.Name == 'HB' or part.Name == 'HumanoidRootPart')
end

local function characterSurface(part, character)
    if not part or not part:IsA('BasePart') then return false end
    local parent = part.Parent
    while parent and parent ~= character do
        if parent:IsA('Tool') then return false end
        parent = parent.Parent
    end
    return parent == character
end

local function cursorHit()
    rayParams.FilterDescendantsInstances = localCharacter and {localCharacter, camera} or {camera}
    return World:Raycast(cursorRay.Origin, cursorRay.Direction * 5000, rayParams)
end

local function nativeAimRay()
    local origin, point = muzzle(), mouse.Hit.Position
    if not (Core.finiteVector(origin) and Core.finiteVector(point)) then return nil end
    local direction = point - origin
    if direction.Magnitude < 0.001 then return nil end
    return {Origin = origin, Direction = direction / direction.Magnitude}
end

local function firingVisible(point, character, feature, excludeTarget)
    return visible(point, character, feature == 'Aim Assist' and camera.CFrame.Position or muzzle(), excludeTarget)
end

local function closestLocal(part, closest, lead, ray)
    local reduction = Core.number(closest.Reduce[closest.Axis == 'All' and 'All' or 'Center'], 0.7, 0, 1)
    local half = part.Size * (0.5 * (1 - reduction))
    if closest.Axis ~= 'All' then half = Vector3.new(0, half.Y, 0) end
    -- A predicted part is translated in world XYZ. Move the ray back by that
    -- translation before entering the actual rotated part's local frame.
    ray = ray or cursorRay
    local worldOrigin = ray.Origin - (lead or zero)
    local origin = part.CFrame:PointToObjectSpace(worldOrigin)
    local direction = part.CFrame:VectorToObjectSpace(ray.Direction)
    return Core.closestRayBox(origin, direction, half, Vector3.new), half
end

local function targetPart(record, feature)
    if not record.character then return nil end
    local target = targetSettings(feature)
    if not target.Closest.Enabled then return partFor(record, target.BasePart) end
    local best, distance = nil, math.huge
    for _, part in ipairs(record.character:GetChildren()) do
        if bodyPart(part, record.character) then
            local point = part.Position
            if target.Closest.Selection == 'Point' then
                local localPoint = closestLocal(part, target.Closest)
                point = part.CFrame:PointToWorldSpace(localPoint)
            end
            local p, onScreen = camera:WorldToViewportPoint(point)
            if onScreen and p.Z > 0 then
                local d = (Vector2.new(p.X, p.Y) - cursor).Magnitude
                if d < distance then best, distance = part, d end
            end
        end
    end
    return best or partFor(record, target.BasePart)
end

local function whitelistLookup()
    if state.WhiteLookupSource ~= state.Whitelist or state.WhiteLookupCount ~= #state.Whitelist then
        local lookup = {}
        for _, id in ipairs(state.Whitelist) do lookup[id] = true end
        state.WhiteLookup, state.WhiteLookupSource, state.WhiteLookupCount = lookup, state.Whitelist, #state.Whitelist
    end
    return state.WhiteLookup
end

local function valid(record, feature, part, skipWall)
    if not record or record.player == localPlayer or record.player.Parent ~= Players then return false end
    local character, humanoid, root = record.character, record.humanoid, record.root
    if not character or not character.Parent or not humanoid or not root or not part or not part.Parent then return false end
    if not Core.finiteVector(part.Position) then return false end
    if feature == 'Triggerbot' and config.Triggerbot.TargetOnly and record.player ~= state.Targets['Silent Aim'] then return false end
    if not Core.whitelisted(config.Whitelist.Enabled, state.WhiteMode, state.Whitelist, record.player.UserId, whitelistLookup()) then return false end
    local index = checkIndices[feature]
    local function check(key) return config.Checks[key] and config.Checks[key][index] == true end
    if check('Dead') and (humanoid.Health <= 0 or character:GetAttribute('Dead') == true) then return false end
    if check('Knocked') and isKnocked(character) then return false end
    if check('ForceField') and character:FindFirstChildOfClass('ForceField') then return false end
    if check('Tool') and not equipped then return false end
    if check('Crew') then
        local mine, theirs = crew(localPlayer), crew(record.player)
        if mine ~= nil and mine ~= '' and mine ~= '0' and mine ~= 0 and mine == theirs then return false end
    end
    if not skipWall and check('Wall') and not firingVisible(part.Position, character, feature) then return false end
    return true
end

local function velocity(record)
    local raw = record.root.AssemblyLinearVelocity
    if not Core.finiteVector(raw) then raw = zero end
    local last = record.history[#record.history]
    if record.velocityAt ~= (last and last.t) or record.velocityRaw ~= raw or not record.sampledVelocity then
        record.sampledVelocity = Core.velocity(record.history, raw, zero)
        record.resolvedVelocity, record.velocitySource = Core.resolveVelocity(record.history,
            record.root.AssemblyLinearVelocity, record.sampledVelocity, Vector3.new)
        record.trueVelocity, record.trueVelocitySource = Core.trueVelocity(record.history,
            record.root.AssemblyLinearVelocity, record.sampledVelocity, record.resolvedVelocity, record.velocitySource, Vector3.new)
        record.velocityAt = last and last.t
        record.velocityRaw = raw
        record.motion = Core.motion(record.history, record.root.AssemblyLinearVelocity, now())
    end
    if not config.Resolver.Enabled then return Core.limit(raw, 180) end
    return record.trueVelocity
end

local function prediction(record, feature, point)
    local origin = muzzle()
    -- Projectile travel is intentionally absent until the actual weapon controller
    -- establishes a speed. Visual tracer duration is not ballistic flight time.
    local vel = velocity(record)
    -- Point and replicated velocity are read live. History sampler age is not
    -- replication age; adding it again caused shot-time lead spikes between ticks.
    local context = state.AutoPrediction.Features[feature]
    local rtt, dataRTT = state.Network.RTT, state.Network.DataRTT
    if config[feature].Prediction.Auto and context and context.Target == record.player.UserId and context.ToolEpoch == state.ToolEpoch then
        rtt, dataRTT = context.RTT, context.DataRTT
    end
    return Core.predictionTime(config[feature].Prediction, rtt, dataRTT,
        0, origin and (point - origin).Magnitude or 0, nil,
        Vector3.new(vel.X, 0, vel.Z).Magnitude, record.humanoid.WalkSpeed)
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true
groundParams.RespectCanCollide = true
local function support(record, point, lead, fallLimit, checkCurrent, verticalVelocity)
    local root, humanoid = record.root, record.humanoid
    local stand = Core.number(humanoid.HipHeight, 2, 0, 10) + root.Size.Y / 2
    local leg = record.character:FindFirstChild('Left Leg')
    if leg and leg:IsA('BasePart') then stand = stand + leg.Size.Y end
    if record.pose and record.pose.SupportHeight then stand = math.min(stand, record.pose.SupportHeight) end
    groundParams.FilterDescendantsInstances = {record.character, localCharacter, camera}
    local origin = root.Position + Vector3.new(lead.X, 0, lead.Z)
    local function floorHit(hit)
        return hit and hit.Normal and hit.Normal.Y >= 0.45 and hit or nil
    end
    local hit = floorHit(World:Raycast(origin,
        Vector3.new(0, -(stand + math.max(0, -lead.Y, fallLimit or 0) + 1), 0), groundParams))
    local info = {PredictedOrigin=vectorData(origin), PredictedGroundY=hit and hit.Position.Y,
        CurrentProbed=false, RootSupportHeight=stand}
    local standing = false
    if checkCurrent and math.abs(verticalVelocity) < 3 then
        local contact
        if lead.X * lead.X + lead.Z * lead.Z < 1e-8 then contact = hit
        else contact = floorHit(World:Raycast(root.Position, Vector3.new(0, -(stand + 0.3), 0), groundParams)) end
        info.CurrentProbed, info.CurrentOrigin = true, vectorData(root.Position)
        info.CurrentClearance = contact and root.Position.Y - contact.Position.Y
        standing = contact ~= nil and info.CurrentClearance >= 0 and info.CurrentClearance <= stand + 0.3
        if standing and hit and contact and hit.Instance == contact.Instance then
            local delta = hit.Position - contact.Position
            -- Follow a measured continuous plane, never teleport onto a separate
            -- raised step merely because it lies below the future footprint.
            if hit.Normal:Dot(contact.Normal) > 0.98 and math.abs(contact.Normal:Dot(delta)) <= 0.05 then
                info.SupportLead = delta.Y
            end
        end
    end
    -- Retain the selected point's offset within the real rig, including foot points.
    return hit and hit.Position.Y + stand + (point.Y - root.Position.Y), standing, info
end

-- Shared forecast for selection, shot coordinates and unselected predicted boxes.
local function leadOffset(record, feature, part, point, evidence)
    local pose = samplePosture(record, now())
    local worldHeight = Posture.verticalSize(part)
    local raw = record.root.AssemblyLinearVelocity
    local leadTime, predictionSource, speedFactor, baseLeadTime = prediction(record, feature, point)
    local vel, motion = velocity(record), record.motion or {}
    baseLeadTime = baseLeadTime or leadTime
    local turnTime = Core.motionTime(leadTime, motion.TurnRate)
    local horizontalTime, limited = Core.fastLeadTime(turnTime, Vector3.new(vel.X, 0, vel.Z).Magnitude, record.humanoid.WalkSpeed)
    local lead = Vector3.new(vel.X * horizontalTime, vel.Y * baseLeadTime, vel.Z * horizontalTime)
    local beforeY, airborne = lead.Y, record.humanoid.FloorMaterial == Enum.Material.Air
    local ySettings = config['Y-Axis']
    local useY = ySettings.Enabled and ySettings[feature == 'Silent Aim' and 'SilentAim' or feature]
    local groundCheck = config.Checks.GroundShotCheck[checkIndices[feature]] == true
    local verticalRaw, verticalMotion = raw.Y, motion
    if config.Resolver.Enabled and record.trueVelocitySource == 'true-velocity'
        and vel.Y ~= record.resolvedVelocity.Y then
        verticalRaw, verticalMotion = vel.Y, nil
    end
    local minY, supportedGround, groundContact
    local needsGround = lead.Y ~= 0 or raw.Y ~= 0 or (motion.VerticalConfidence or 0) >= 0.5
    if needsGround and (groundCheck or (useY and ySettings.Method == 'Auto')) then
        minY, supportedGround, groundContact = support(record, point, lead, worldHeight,
            useY and ySettings.Method == 'Auto', verticalRaw)
    end
    local vertical, source, correction, accelerationMode
    local appliedAcceleration = 0
    if useY and ySettings.Method == 'Custom' then
        if vel.Y > 0 then lead = Vector3.new(lead.X, lead.Y * Core.number(ySettings.Offset, 1, 0, 5), lead.Z) end
    elseif useY then
        -- Remote FloorMaterial is not replicated. Only current-footprint contact
        -- can stop Auto Y; future XZ support is reserved for the landing clamp.
        local grounded = supportedGround == true
        vertical, source = Core.autoVertical(vel.Y, verticalRaw)
        local y
        y, correction, accelerationMode = Core.verticalLead(vertical, verticalRaw, baseLeadTime, worldHeight, grounded, verticalMotion,
            groundContact and groundContact.SupportLead)
        if verticalMotion and (accelerationMode == 'measured-acceleration' or accelerationMode == 'braking-stop') then
            appliedAcceleration = verticalMotion.VerticalAcceleration * verticalMotion.VerticalConfidence
        end
        lead = Vector3.new(lead.X, y, lead.Z)
    end
    local groundCorrected
    if groundCheck and lead.Y < 0 and minY and point.Y + lead.Y < minY then
        groundCorrected = true
        lead = Vector3.new(lead.X, math.min(point.Y, minY) - point.Y, lead.Z)
    end
    if evidence then
        evidence.Posture, evidence.PostureSource = pose and pose.Kind, pose and pose.Source
        evidence.PartWorldHeight = worldHeight
        evidence.Part, evidence.PartPosition, evidence.BasePoint = part.Name, vectorData(part.Position), vectorData(point)
        evidence.RawVelocity, evidence.SampledVelocity = vectorData(raw), vectorData(record.sampledVelocity)
        evidence.ResolvedVelocity = vectorData(vel)
        evidence.VelocitySource = config.Resolver.Enabled and record.trueVelocitySource or 'raw'
        evidence.Resolver = config.Resolver.Enabled and 'TrueVelocity' or 'Disabled'
        evidence.PredictionSource, evidence.SpeedFactor, evidence.LeadTime = predictionSource, speedFactor, leadTime
        evidence.BaseLeadTime, evidence.HorizontalLeadTime, evidence.FastMotionLimited = baseLeadTime, horizontalTime, limited
        evidence.TurnRate, evidence.TurnLeadTime = motion.TurnRate, turnTime
        evidence.MeasuredTurnRate, evidence.TurnValidated = motion.MeasuredTurnRate, motion.TurnValidated
        evidence.VerticalAcceleration, evidence.VerticalConfidence = motion.VerticalAcceleration, motion.VerticalConfidence
        evidence.VerticalValidated = motion.VerticalValidated
        evidence.VerticalPositionError, evidence.VerticalLinearError = motion.VerticalPositionError, motion.VerticalLinearError
        evidence.AppliedVerticalAcceleration = appliedAcceleration
        evidence.VerticalModelSource = verticalMotion and 'raw-velocity-fit' or 'linear-resolved-motion'
        evidence.VerticalModelSampleAge = motion.SampleAge
        evidence.AutoVerticalVelocity, evidence.AutoVerticalSource, evidence.AccelerationCorrection = vertical, source, correction
        evidence.AccelerationMode = accelerationMode
        evidence.HistoryCount = #record.history
        local last = record.history[#record.history]
        evidence.HorizontalVelocitySource, evidence.VerticalVelocitySource = last and last.horizontalSource, last and last.verticalSource
        evidence.HistoryAge = record.history[#record.history] and now() - record.history[#record.history].t
        evidence.Airborne, evidence.FloorMaterial, evidence.Health = airborne, record.humanoid.FloorMaterial.Name, record.humanoid.Health
        evidence.MuzzleOrigin, evidence.CameraOrigin = vectorData(muzzle()), vectorData(camera.CFrame.Position)
        evidence.YMethod = useY and ySettings.Method or 'Disabled'
        evidence.GroundCorrected, evidence.GroundMinimumY, evidence.GroundedByGeometry = groundCorrected, minY, supportedGround
        evidence.GroundContact = groundContact
        evidence.LeadBeforeY = vectorData(Vector3.new(lead.X, beforeY, lead.Z))
        evidence.LeadAfterY, evidence.PredictedPoint = vectorData(lead), vectorData(point + lead)
        evidence.VerticalAdjustment = lead.Y - beforeY
    end
    return lead
end

-- Read-only forecast evidence; it never selects a target or submits coordinates.
function state:Forecast(player, feature, partName)
    if not self.Alive or not checkIndices[feature] or not captureView() then return nil end
    local record = self.Records[player]
    if not record or not record.root or not record.humanoid then return nil end
    local part = partFor(record, partName or targetSettings(feature).BasePart)
    if not part or not part.Parent or not Core.finiteVector(part.Position) then return nil end
    local evidence = {Feature = feature, Time = now(), Result = 'forecast only; no selection or send'}
    local lead = leadOffset(record, feature, part, part.Position, evidence)
    local point = part.Position + lead
    return Core.finiteVector(point) and point or nil, evidence
end

local function playerBox(record, feature, standalone)
    if not record.root or not record.character then return nil end
    local style = config['2d-Box'][feature]
    local origin = record.root.Position
    local projected = camera:WorldToViewportPoint(origin)
    local width, height = Core.number(style.Size.Width, 5, 0.1, 100), Core.number(style.Size.Height, 4.3, 0.1, 100)
    if standalone then width, height = 6, 6 end
    local profile, range
    local physicalDistance = (record.root.Position - (localRoot and localRoot.Position or camera.CFrame.Position)).Magnitude
    if feature == 'Silent Aim' then
        weaponName = equipped and Core.weapon(equipped.Name) or nil
        profile, range = Core.profile(config['Gun Specifications'], weaponName, physicalDistance)
    end
    if profile and profile.BoxSize then
        width = Core.number(profile.BoxSize[1], width, 0.1, 100)
        height = Core.number(profile.BoxSize[2], height, 0.1, 100)
    end
    record.BoxInfo = record.BoxInfo or {}
    local boxInfo = record.BoxInfo[feature] or {}
    record.BoxInfo[feature] = boxInfo
    boxInfo.Width, boxInfo.Height, boxInfo.Distance = width, height, physicalDistance
    boxInfo.Weapon, boxInfo.Range, boxInfo.Standalone = weaponName, profile and range or nil, standalone == true
    local focal = camera.ViewportSize.Y / (2 * math.tan(math.rad(camera.FieldOfView) / 2))
    local x, y, w, h = Core.projectedBox(projected.X, projected.Y, projected.Z, width, height, focal)
    if not x or x+w < 0 or y+h < 0 or x > camera.ViewportSize.X or y > camera.ViewportSize.Y then return nil end
    return Vector2.new(x, y), Vector2.new(w, h)
end

local function inFov(record, feature, part, predictedPoint)
    local settings = config[feature]
    if feature == 'Silent Aim' and settings.Ignore then return true end
    if settings.Fov.Method == '2d-Circle' then
        local p, onScreen = camera:WorldToViewportPoint(predictedPoint or part.Position)
        if not onScreen or p.Z <= 0 then return false end
        return Core.fov(p.X - cursor.X, p.Y - cursor.Y, '2d-Circle', 0, 0,
            Core.number(settings.Fov['2d-Circle'].Size, 50, 1, 10000))
    end
    local position, size = playerBox(record, feature, false)
    return position ~= nil and cursor.X >= position.X and cursor.X <= position.X+size.X
        and cursor.Y >= position.Y and cursor.Y <= position.Y+size.Y
end

local function nearest(feature, assignment, resolve)
    if not captureView() then return nil end
    local choices = {}
    for _, record in pairs(state.Records) do
        local part = assignment and partFor(record, 'HumanoidRootPart') or targetPart(record, feature)
        if part and (assignment or (valid(record, feature, part, true))) then
            local projected, onScreen = camera:WorldToViewportPoint(part.Position)
            if projected.Z > 0 and (onScreen or (not assignment and feature == 'Silent Aim' and config[feature].Ignore)) then
                local distance = (Vector2.new(projected.X, projected.Y) - cursor).Magnitude
                if not assignment or distance <= 150 then choices[#choices + 1] = {record = record, part = part, distance = distance} end
            end
        end
    end
    table.sort(choices, function(a, b) return a.distance < b.distance end)
    for _, choice in ipairs(choices) do
        if assignment or valid(choice.record, feature, choice.part, resolve ~= nil) then
            if resolve then
                local point, part = resolve(choice.record, feature, nil, nil, choice.part)
                if point then return choice.record, point, part end
            else
                return choice.record
            end
        end
    end
    return nil
end

local function aimPoint(record, feature, hitPart, hitPoint, selectedPart, selection)
    local settings = config[feature]
    local target = targetSettings(feature)
    local closest = target.Closest
    local part = hitPart or selectedPart or targetPart(record, feature)
    if hitPart and not bodyPart(hitPart, record.character) then part = partFor(record, 'UpperTorso') end
    local evidence = {Feature = feature, Time = now(), Target = record.player.UserId,
        Part = part and part.Name, Accepted = false, CandidateAttempt = selection and selection.Attempt or 1,
        SelectionRay = selection and selection.Source}
    if selection and selection.Ray then
        evidence.SelectionOrigin, evidence.SelectionDirection = vectorData(selection.Ray.Origin), vectorData(selection.Ray.Direction)
    end
    state.AimTrace[feature] = evidence
    local function reject(reason)
        evidence.Reason = reason
        traceEvent('aim', evidence)
        return nil
    end
    if not valid(record, feature, part, true) then return reject('eligibility') end
    samplePosture(record, now())
    local point = hitPoint or part.Position
    local lead, pendingPointState
    local exact = closest.Enabled and closest.Raycast and state.CursorHit
    if hitPart then
        -- Triggerbot without FOV uses the actual unobstructed cursor surface.
        evidence.PointSource, evidence.SurfacePart = 'cursor-surface', hitPart.Name
        if record.pointState then record.pointState[feature] = nil end
    elseif exact and characterSurface(exact.Instance, record.character) then
        -- Accessory handles can be the actual first surface of the cursor ray.
        -- Keep the body part for rig/Y math, but retain the exact surface point.
        if bodyPart(exact.Instance, record.character) then part = exact.Instance end
        point = exact.Position
        evidence.PointSource, evidence.SurfacePart = 'cursor-surface', exact.Instance.Name
        if record.pointState then record.pointState[feature] = nil end
    elseif closest.Enabled and closest.Selection == 'Point' then
        lead = leadOffset(record, feature, part, part.Position, evidence)
        evidence.PointSource = lead.Magnitude > 1e-8 and 'closest-point-predicted' or 'closest-point'
        local localPoint, half = closestLocal(part, closest, lead)
        local pointRay, pointRaySource = cursorRay, 'camera'
        local nativeRay = feature == 'Silent Aim' and nativeAimRay()
        if nativeRay and (not selection or selection.PointRay ~= 'camera') then
            local nativeLocal = closestLocal(part, closest, lead, nativeRay)
            local nativePoint = part.CFrame:PointToWorldSpace(nativeLocal) + lead
            local cameraPoint = part.CFrame:PointToWorldSpace(localPoint) + lead
            local nativeGap = Core.rayDistance(nativePoint, nativeRay.Origin, nativeRay.Direction)
            local cameraGap = Core.rayDistance(cameraPoint, cursorRay.Origin, cursorRay.Direction)
            local projected, onScreen = camera:WorldToViewportPoint(nativePoint)
            if nativeGap and onScreen and projected.Z > 0 and
                ((selection and selection.PointRay == 'muzzle') or nativeGap + 1e-6 < (cameraGap or math.huge)) then
                localPoint, pointRay, pointRaySource = nativeLocal, nativeRay, 'muzzle'
            end
        end
        evidence.PointRay, evidence.PointRayOrigin = pointRaySource, vectorData(pointRay.Origin)
        evidence.PointRayDirection = vectorData(pointRay.Direction)
        local last = record.pointState and record.pointState[feature]
        if last and last.part.Parent == record.character and last.axis == closest.Axis and last.ray == pointRaySource and now() - last.time <= 0.2 then
            local alpha = Core.alpha(Core.number(closest.Sharpness, 0.65, 0.01, 1), now() - last.time)
            local prior = last.part == part and last.point or part.CFrame:PointToObjectSpace(last.part.CFrame:PointToWorldSpace(last.point))
            localPoint = prior + (localPoint - prior) * alpha
        end
        localPoint = Vector3.new(closest.Axis == 'All' and math.clamp(localPoint.X, -half.X, half.X) or 0,
            math.clamp(localPoint.Y, -half.Y, half.Y), closest.Axis == 'All' and math.clamp(localPoint.Z, -half.Z, half.Z) or 0)
        pendingPointState = {part = part, point = localPoint, time = now(), axis = closest.Axis, ray = pointRaySource}
        point = part.CFrame:PointToWorldSpace(localPoint)
    else
        if record.pointState then record.pointState[feature] = nil end
    end
    local basePoint = point
    if lead then
        -- Verified weapons are hitscan: timing and motion do not depend on the
        -- local point inside this part. Ground minimum preserves its rig offset.
        -- Rebase evidence instead of repeating the same support ray.
        local minimum = rawget(evidence, 'GroundMinimumY')
        if type(minimum) == 'number' then evidence.GroundMinimumY = minimum + point.Y - part.Position.Y end
        evidence.BasePoint, evidence.PredictedPoint = vectorData(point), vectorData(point + lead)
    else lead = leadOffset(record, feature, part, point, evidence) end
    local rawMousePoint = mouse.Hit.Position
    evidence.RawMousePoint = vectorData(rawMousePoint)
    point = point + lead
    if not Core.finiteVector(point) then return reject('nonfinite') end
    evidence.WallOrigin = vectorData(feature == 'Aim Assist' and camera.CFrame.Position or muzzle())
    if (feature ~= 'Triggerbot' or settings.Fov.Enabled) and not inFov(record, feature, part, point) then return reject('fov') end
    if config.Checks.Wall[checkIndices[feature]] and not firingVisible(point, record.character, feature) then return reject('predicted-wall') end
    -- Final Silent settings never reject camera assistance or independent trigger candidates.
    local anti = feature == 'Silent Aim' and settings.AntiCurve
    if anti and anti.Enabled then
        local cameraGap, cameraPoint = Core.rayDistance(point, cursorRay.Origin, cursorRay.Direction)
        local nativeRay = nativeAimRay()
        local nativeGap, nativePoint
        if nativeRay then nativeGap, nativePoint = Core.rayDistance(point, nativeRay.Origin, nativeRay.Direction) end
        evidence.AntiCurveCameraDistance, evidence.AntiCurveMuzzleDistance = cameraGap, nativeGap
        evidence.NativeAimOrigin = nativeRay and vectorData(nativeRay.Origin)
        evidence.NativeAimDirection = nativeRay and vectorData(nativeRay.Direction)
        if anti.Method == 'Endmath' then
            local projected, onScreen = camera:WorldToViewportPoint(point)
            evidence.AntiCurveUnit, evidence.AntiCurveLimit = 'pixels', Core.curveLimit(anti.Endmath.Radius, 120)
            local screenGap = (Vector2.new(projected.X, projected.Y) - cursor).Magnitude
            local nativeScreenGap
            if nativePoint then
                local p = camera:WorldToViewportPoint(nativePoint)
                if p.Z > 0 then nativeScreenGap = (Vector2.new(projected.X, projected.Y) - Vector2.new(p.X, p.Y)).Magnitude end
            end
            evidence.AntiCurveCameraPixels, evidence.AntiCurveMuzzlePixels = screenGap, nativeScreenGap
            evidence.AntiCurveDistance = math.min(screenGap, nativeScreenGap or math.huge)
            evidence.AntiCurveReference = nativeScreenGap and nativeScreenGap < screenGap and 'muzzle-to-mouse-ray' or 'forward-cursor-ray'
            if not onScreen or projected.Z <= 0 or
                evidence.AntiCurveDistance > evidence.AntiCurveLimit then return reject('anti-curve-pixels') end
            if anti.Endmath.WallCheck and not visible(point, record.character, muzzle(), true) then return reject('anti-curve-wall') end
        elseif anti.Method == '3d-angles' then
            evidence.AntiCurveUnit, evidence.AntiCurveLimit = 'studs', Core.curveLimit(anti['3d-angles'].Max, 2.2)
            local useMuzzle = nativeGap and nativeGap < (cameraGap or math.huge)
            evidence.AntiCurveReference = useMuzzle and 'muzzle-to-mouse-ray' or 'forward-cursor-ray'
            evidence.AntiCurveCursorPoint = vectorData(useMuzzle and nativePoint or cameraPoint)
            evidence.AntiCurveRawSurfaceDistance = (point - rawMousePoint).Magnitude
            evidence.AntiCurveDistance = math.min(cameraGap or math.huge, nativeGap or math.huge)
            if not (cameraGap or nativeGap) then return reject('anti-curve-direction') end
            if evidence.AntiCurveDistance > evidence.AntiCurveLimit then return reject('anti-curve-studs') end
        end
    end
    if not Core.finiteVector(point) then return reject('nonfinite') end
    if feature == 'Silent Aim' and
        not firingVisible(point, record.character, feature, true) then return reject('final-wall') end
    evidence.Accepted = true
    if pendingPointState then
        record.pointState = record.pointState or {}
        record.pointState[feature] = pendingPointState
    end
    record.renderAim = record.renderAim or {}
    record.renderAim[feature] = {part = part, localPoint = part.CFrame:PointToObjectSpace(basePoint), lead = lead, time = now()}
    traceEvent('aim', evidence)
    return point, part
end

local retryReasons = {fov=true, ['predicted-wall']=true, ['final-wall']=true,
    ['anti-curve-pixels']=true, ['anti-curve-studs']=true, ['anti-curve-wall']=true, ['anti-curve-direction']=true}
local function resolveAimPoint(record, feature, hitPart, hitPoint, selectedPart)
    local point, part = aimPoint(record, feature, hitPart, hitPoint, selectedPart)
    if point then return point, part end
    local closest, first = targetSettings(feature).Closest, state.AimTrace[feature]
    if hitPart or not closest.Enabled or not first or not retryReasons[first.Reason]
        or (closest.Raycast and state.CursorHit and characterSurface(state.CursorHit.Instance, record.character)) then return nil end
    -- Box membership belongs to the player, so no alternate part/ray can fix it.
    if first.Reason == 'fov' and config[feature].Fov.Method ~= '2d-Circle' then return nil end
    local initial = selectedPart or targetPart(record, feature)
    local attempt = 1
    local function alternate(candidate)
        local evidence = state.AimTrace[feature]
        if feature ~= 'Silent Aim' or closest.Selection ~= 'Point' or not evidence or not retryReasons[evidence.Reason]
            or not nativeAimRay() then return nil end
        attempt = attempt + 1
        return aimPoint(record, feature, nil, nil, candidate,
            {Attempt=attempt, PointRay=evidence.PointRay == 'muzzle' and 'camera' or 'muzzle'})
    end
    point, part = alternate(initial)
    if point then return point, part end
    -- Only rejected paths scan alternate real body parts. Every candidate keeps
    -- the same prediction, FOV, AntiCurve and final muzzle-obstruction checks.
    local choices = {}
    for _, candidate in ipairs(record.character:GetChildren()) do
        if candidate ~= initial and bodyPart(candidate, record.character) then
            local projected, onScreen = camera:WorldToViewportPoint(candidate.Position)
            if onScreen and projected.Z > 0 then
                choices[#choices + 1] = {part=candidate, distance=(Vector2.new(projected.X, projected.Y)-cursor).Magnitude}
            end
        end
    end
    table.sort(choices, function(a,b) return a.distance < b.distance end)
    for _, choice in ipairs(choices) do
        attempt = attempt + 1
        point, part = aimPoint(record, feature, nil, nil, choice.part, {Attempt=attempt})
        if point then return point, part end
        point, part = alternate(choice.part)
        if point then return point, part end
    end
    return nil
end

local function renderPoint(feature)
    local point, player = state.Points[feature], state.Targets[feature]
    local record = player and state.Records[player]
    local sample = record and record.renderAim and record.renderAim[feature]
    if point and sample and sample.part.Parent == record.character and now() - sample.time <= 0.1 then
        return sample.part.CFrame:PointToWorldSpace(sample.localPoint) + sample.lead
    end
    return point
end

local function selectTarget(feature)
    if not enabled(feature) or typing() then return nil end
    if config[feature].Method == 'Auto' then
        if config[feature].Activation.Holding and not holding('target:' .. feature, config[feature].Activation.Keybind) then return nil end
        -- A rejected final prediction must not starve another eligible candidate.
        return nearest(feature, false, resolveAimPoint)
    end
    local mode = config[feature].Activation
    if mode.Holding and not holding('target:' .. feature, mode.Keybind) then return nil end
    local player = validPlayer(state.Locks[feature])
    return player and state.Records[player] or nil
end

local function followAssist(point, dt)
    if not point or not enabled('Aim Assist') or typing() then state.MouseRemainder = nil; return false end
    local settings = config['Aim Assist']
    if settings.Follow == 'Mouse' and type(mousemoverel) == 'function' then
        local screen, onScreen = camera:WorldToViewportPoint(point)
        if onScreen then
            local delta = (Vector2.new(screen.X, screen.Y) - cursor) * Core.alpha(settings.Smoothness, math.min(dt, 0.05))
            state.MouseRemainder = (state.MouseRemainder or Vector2.new()) + delta
            local x, y = math.floor(state.MouseRemainder.X + 0.5), math.floor(state.MouseRemainder.Y + 0.5)
            state.MouseRemainder = state.MouseRemainder - Vector2.new(x, y)
            if x ~= 0 or y ~= 0 then mousemoverel(x, y); return true end
        end
    elseif settings.Follow == 'Camera' then
        local offset = point - camera.CFrame.Position
        if offset.Magnitude > 0.01 then
            local look, up = Core.cursorOrientation(cursorRay.Direction, offset, camera.CFrame.LookVector,
                camera.CFrame.UpVector or Vector3.new(0, 1, 0))
            if look then
                local desired = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + look, up)
                camera.CFrame = camera.CFrame:Lerp(desired, Core.alpha(settings.Smoothness, dt))
                return true
            end
        end
    end
    return false
end

local function updateAim(dt)
    state.AimTrace['Silent Aim'], state.AimTrace['Aim Assist'] = nil, nil
    if not captureView() or not localHumanoid or localHumanoid.Health <= 0 then
        state.Points, state.Targets = {}, {}; return
    end
    state.CursorHit = cursorHit()
    for _, feature in ipairs({'Aim Assist', 'Silent Aim'}) do
        local record, point, part = selectTarget(feature)
        if record and not point then point, part = resolveAimPoint(record, feature) end
        state.Targets[feature] = point and record.player or nil
        state.Points[feature] = point
        if feature == 'Silent Aim' then state.AimPart = part end
        if feature == 'Aim Assist' and dt and followAssist(renderPoint('Aim Assist'), dt) then
            captureView()
            state.CursorHit = cursorHit()
        end
    end
    state.ForwardPoint = camera.CFrame.Position + camera.CFrame.LookVector * 1000
    state.RawMousePoint = mouse.Hit.Position
end

local function refreshAutoPrediction(time)
    for _, feature in ipairs({'Silent Aim', 'Aim Assist', 'Triggerbot'}) do
        local player, settings = state.Targets[feature], config[feature].Prediction
        local record = player and state.Records[player]
        local context = state.AutoPrediction.Features[feature]
        if not settings.Enabled or not settings.Auto or not record or not enabled(feature) or typing() then
            state.AutoPrediction.Features[feature] = nil
        elseif not context or context.Target ~= player.UserId or context.ToolEpoch ~= state.ToolEpoch or time >= context.NextSample then
            local point = state.Points[feature] or record.root.Position
            local vel = velocity(record)
            local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            local raw = record.root.AssemblyLinearVelocity
            local origin = muzzle()
            local distance = origin and (point - origin).Magnitude or 0
            local seconds, source, factor, base = Core.predictionTime(settings, state.Network.RTT, state.Network.DataRTT,
                0, distance, nil, speed, record.humanoid.WalkSpeed)
            local horizontal = Core.fastLeadTime(Core.motionTime(seconds, record.motion and record.motion.TurnRate), speed, record.humanoid.WalkSpeed)
            state.AutoPrediction.Features[feature] = {Target = player.UserId, ToolEpoch = state.ToolEpoch,
                Time = time, NextSample = time + state.AutoPrediction.Interval, Source = source,
                RTT = state.Network.RTT, DataRTT = state.Network.DataRTT, BaseSeconds = base,
                SpeedSeconds = seconds, HorizontalSeconds = horizontal, SpeedFactor = factor,
                RawSpeed = math.sqrt(raw.X * raw.X + raw.Z * raw.Z), ResolvedSpeed = speed,
                Distance = distance, Weapon = weaponName, Ballistics = weaponName and 'hitscan' or 'unverified',
                BulletSpeed = nil, TravelSeconds = 0, MuzzleOrigin = vectorData(origin)}
            state.AutoPrediction.Refreshes = state.AutoPrediction.Refreshes + 1
        end
    end
end

-- One permanent pass-through dispatcher per metamethod; replacements only swap Active.
local hooks = environment[hooksKey]
if type(hooks) ~= 'table' then hooks = {}; environment[hooksKey] = hooks end
function state:TracePacket(inputPoint, outputPoint)
    self.LastMousePayload = outputPoint -- Also works through an older permanent dispatcher.
    if now() >= self.Trace.Until then return end
    local time = now()
    if time < (self.NextPacketTrace or 0) then return end
    self.NextPacketTrace = time + 0.02
    traceEvent('mouse-payload', {Input = vectorData(inputPoint), Point = vectorData(outputPoint),
        Redirected = outputPoint ~= inputPoint, Target = self.Targets['Silent Aim'] and self.Targets['Silent Aim'].UserId,
        AimTime = self.AimTrace['Silent Aim'] and self.AimTrace['Silent Aim'].Time,
        Result = 'passed to original FireServer; no server acknowledgement'})
end
local function installHooks()
    local wrap = type(newcclosure) == 'function' and newcclosure or function(f) return f end
    if type(hookmetamethod) == 'function' and type(getnamecallmethod) == 'function' and not hooks.Namecall then
        local original
        local ok, result = pcall(function()
            return hookmetamethod(game, '__namecall', wrap(function(object, ...)
                local active = hooks.Active
                if active and active.Alive and object == active.Remote and getnamecallmethod() == 'FireServer' then
                    local args = table.pack(...)
                    if args[1] == 'MOUSE' and typeof(args[2]) == 'Vector3' then
                        local inputPoint = args[2]
                        args[2] = active.PacketPoint or args[2]
                        if active.TracePacket then active:TracePacket(inputPoint, args[2]) end
                        return original(object, table.unpack(args, 1, args.n))
                    end
                end
                return original(object, ...)
            end))
        end)
        if ok then original = result; hooks.Namecall = true; hooks.PacketTrace = true else warnOnce('namecall', tostring(result)) end
    end
    -- Existing dispatchers from older executions stay pass-through because this
    -- runtime never supplies ClientPoint. No new Mouse.Hit/Target hook is needed.
    hooks.Active = state
    state.Mouse = mouse
    state.Capabilities.RemoteHook = hooks.Namecall == true
    state.Capabilities.ClientMouseHook = false
    state.Capabilities.PacketTrace = hooks.PacketTrace == true
end

local function refreshPacket()
    local point = state.Points['Silent Aim']
    local shooting = now() < state.ShotUntil or (not typing() and Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))
    if state.ForcedPoint and now() < state.ForcedUntil then point = state.ForcedPoint end
    state.PacketPoint = nil
    if not config['Anti-AimViewer'].Enabled then
        if equipped and enabled('Silent Aim') and not typing() then state.PacketPoint = point end
        if shooting and state.ForcedPoint and now() < state.ForcedUntil then state.PacketPoint = state.ForcedPoint end
    end
    state.ClientPoint = nil -- Disable legacy Mouse.Hit/Target substitution on replacement.
    -- Local visuals never create or change a server redirection point.
end

local function findRemote()
    state.Remote = nil
    for _, name in ipairs({'MAINEVENT', 'MainEvent'}) do
        local candidate = ReplicatedStorage:FindFirstChild(name)
        if candidate and candidate:IsA('RemoteEvent') then state.Remote = candidate; break end
    end
    state.Capabilities.Remote = state.Remote ~= nil
end

local function queueAimRestore()
    if not config['Anti-AimViewer'].Enabled then return end
    state.AimRestoreSequence = (state.AimRestoreSequence or 0) + 1
    local sequence, character = state.AimRestoreSequence, localCharacter
    -- Run after the current activation stack has queued the actual shot. Do not
    -- leave target coordinates installed across later render/replication frames.
    task.defer(function()
        if not state.Alive or sequence ~= state.AimRestoreSequence or localCharacter ~= character
            or not config['Anti-AimViewer'].Enabled then return end
        state.PacketPoint = nil
        local raw = state.RawMousePoint
        if typeof(raw) ~= 'Vector3' or not Core.finiteVector(raw) then return end
        if not state.Remote or state.Remote.Parent ~= ReplicatedStorage or not state.Remote:IsA('RemoteEvent') then findRemote() end
        if not state.Remote then return end
        local ok, reason = pcall(function() state.Remote:FireServer('MOUSE', raw) end)
        state.Stats[ok and 'AimRestores' or 'AimRestoreErrors'] = state.Stats[ok and 'AimRestores' or 'AimRestoreErrors'] + 1
        state.LastAimRestore = {Time = now(), Point = vectorData(raw), Returned = ok}
        traceEvent('aim-restore', state.LastAimRestore)
        if not ok then warnOnce('aim-restore', tostring(reason)) end
    end)
end

local function sendAim(point)
    local function skip(reason)
        state.PacketPoint = nil
        state.Stats.AimSendSkipped = state.Stats.AimSendSkipped + 1
        traceEvent('send-skipped', {Reason = reason})
        return false
    end
    if typeof(point) ~= 'Vector3' or not Core.finiteVector(point) then return skip('invalid-point') end
    -- Reacquire after replacement or a stale cache; never retry a failed send and
    -- risk submitting an old point in a later firing window.
    if not state.Remote or state.Remote.Parent ~= ReplicatedStorage or not state.Remote:IsA('RemoteEvent') then findRemote() end
    if not state.Remote then return skip('missing-remote') end
    state.PacketPoint = not config['Anti-AimViewer'].Enabled and point or nil
    state.Stats.AimPackets = state.Stats.AimPackets + 1
    local ok, reason = pcall(function() state.Remote:FireServer('MOUSE', point) end)
    state.LastSend = {Time = now(), Argument = 'MOUSE', Point = vectorData(point),
        Returned = ok, Evidence = Core.copy(state.AimTrace),
        Result = 'client call only; server acceptance and damage unverified'}
    state.Stats[ok and 'AimSendReturns' or 'AimSendErrors'] = state.Stats[ok and 'AimSendReturns' or 'AimSendErrors'] + 1
    traceEvent('send', state.LastSend)
    if not ok then state.PacketPoint = nil; warnOnce('remote-send', tostring(reason))
    else queueAimRestore() end
    return ok
end

local function macroEnabled()
    local supplied = environment.neoperro
    local live = type(supplied) == 'table' and supplied.Misc and supplied.Misc['Macro Abuse']
    return state.Alive and config.Misc['Macro Abuse'].Enabled == true and type(live) == 'table' and live.Enabled == true
end

local function observeMacroMotion(time)
    local motion = state.MacroMotion or {LastFastAt = -math.huge}
    state.MacroMotion = motion
    local part = localCharacter and localCharacter:FindFirstChild('Head') or localRoot
    local velocity = part and part.AssemblyLinearVelocity
    motion.Part = part and part.Name
    motion.Speed = velocity and Core.finiteVector(velocity) and math.sqrt(velocity.X * velocity.X + velocity.Z * velocity.Z) or 0
    if velocity and Core.macroActive(velocity) then
        motion.LastFastAt, motion.LastFastSpeed = time, motion.Speed
    end
    return motion
end

local function detectedMacro()
    local time = now()
    local motion = observeMacroMotion(time)
    -- Game shot acknowledgement can clear velocity before Tool.Activated listeners run.
    -- Retain only 120ms of pre-shot motion, never an input-pattern or indefinite latch.
    local current = motion.Speed > 30
    local recent = time >= motion.LastFastAt and time - motion.LastFastAt <= 0.12
    local detected = current or recent
    state.LastMacroCheck = {Time = time, Part = motion.Part, Detected = detected,
        HorizontalSpeed = motion.Speed, Threshold = 30, RecentSpeed = motion.LastFastSpeed,
        RecentAge = recent and time - motion.LastFastAt or nil,
        Source = current and 'current-speed' or recent and 'recent-pre-shot-speed' or 'below-threshold'}
    return detected
end

local function beginMacro(source, tool)
    local settings = config.Misc['Macro Abuse']
    if not macroEnabled() or macro or (source ~= 'Manual' and source ~= 'Triggerbot') then return end
    if source == 'Triggerbot' and not settings['Triggerbot check'] then return end
    if settings['Macro Check'] and not detectedMacro() then return end
    if not virtualInput then warnOnce('macro-input', 'Macro needs VirtualInputManager key events.'); return end
    if not localHumanoid or localHumanoid.Health <= 0 or typing() then return end
    macro = {stage = 'wait', due = now() + 0.04, tool = tool, character = localCharacter}
end

local function macroStep(time)
    if not macro then return end
    local cycle = macro
    -- Latch eligibility at activation: the game's shot handler itself zeros speed.
    if not macroEnabled() or typing() or localCharacter ~= cycle.character
        or not localHumanoid or localHumanoid.Health <= 0 or not cycle.tool.Parent then cancelMacro(); return end
    if time < cycle.due then return end
    if cycle.stage == 'wait' then
        if cycle.tool ~= equipped then cancelMacro(); return end
        localHumanoid:UnequipTools()
        cycle.stage, cycle.due = 'crouch', time + 0.06
    elseif cycle.stage == 'crouch' then
        -- Never release a Ctrl key the user was already holding.
        if not Input:IsKeyDown(Enum.KeyCode.LeftControl) and not Input:IsKeyDown(Enum.KeyCode.RightControl) then
            local ok = pcall(function() virtualInput:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game) end)
            if not ok then warnOnce('macro-denied', 'This executor cannot send Ctrl input.'); cancelMacro(); return end
            state.ControlOwned = true
        end
        cycle.stage, cycle.due = 'equip', time + 0.07
    elseif cycle.stage == 'equip' then
        if localCharacter:FindFirstChildOfClass('Tool') then cancelMacro(); return end
        if cycle.tool.Parent ~= localPlayer:FindFirstChildOfClass('Backpack') then cancelMacro(); return end
        localHumanoid:EquipTool(cycle.tool)
        cycle.stage, cycle.due = 'release', time + 0.07
    else releaseControl(); macro = nil end
end

releaseShotInput = function(preserveShot)
    if state.ShotRelease then
        local release = state.ShotRelease
        state.ShotRelease = nil
        pcall(release)
    end
    state.MouseOwned = false
    if not preserveShot then
        state.PacketPoint = nil
        state.ForcedPoint, state.ForcedUntil = nil, nil
        state.FiringRecord, state.FiringSource, state.FiringTool = nil, nil, nil
        activation = nil
    end
    if state.AutomatedTool then pcall(function() state.AutomatedTool:Deactivate() end) end
    state.AutomatedTool = nil
end

local function routedShotPoint(source, record, point)
    local aimFeature, aimRecord = source, record
    if source == 'Triggerbot' and enabled('Silent Aim') and state.Points['Silent Aim'] then
        local selected = state.Targets['Silent Aim']
        local selectedRecord = selected and state.Records[selected]
        if selectedRecord and (not config.Triggerbot.TargetOnly or selectedRecord == record) then
            point, aimFeature, aimRecord = state.Points['Silent Aim'], 'Silent Aim', selectedRecord
        end
    end
    return point, aimFeature, aimRecord
end

local function fire(source, record, point)
    if state.ShotRelease or state.AutomatedTool then return false end
    if not equipped or not equipped.Enabled or macro or typing() or now() < state.NextFire then return false end
    if Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not state.MouseOwned then return false end
    if not localHumanoid or localHumanoid.Health <= 0 or isKnocked(localCharacter) then return false end
    local ammo = ammoCount(equipped)
    if type(ammo) == 'number' and ammo <= 0 then return false end
    local time, tool = now(), equipped
    local aimFeature, aimRecord
    point, aimFeature, aimRecord = routedShotPoint(source, record, point)
    state.LastShotRoute = {Source=source, AimFeature=aimFeature, TriggerTarget=record.player.UserId,
        AimTarget=aimRecord.player.UserId, Point=vectorData(point), Time=time}
    traceEvent('shot-routing', state.LastShotRoute)
    state.NextFire, state.ShotUntil = time + 0.08, time + 0.14
    state.ForcedPoint, state.ForcedUntil = point, time + 0.14
    activation = {source = source, tool = tool, untilTime = time + 0.14, sent = true}
    state.Stats.TriggerAttempts = state.Stats.TriggerAttempts + 1
    sendAim(point)
    state.DeactivateAt = time + (source == 'Triggerbot' and Core.delay(config.Triggerbot, (record.root.Position - muzzle()).Magnitude, state.TriggerRandom or 0.5) or 0.04)
    state.ForcedUntil = math.max(state.ForcedUntil, state.DeactivateAt + 0.05)
    state.ShotUntil = state.ForcedUntil
    activation.untilTime = state.ForcedUntil
    state.FiringRecord, state.FiringSource, state.FiringTool = record, source, tool
    if type(mouse1press) == 'function' and type(mouse1release) == 'function' then
        state.MouseOwned = true
        state.ShotRelease = mouse1release
        local ok = pcall(mouse1press)
        if ok then state.Capabilities.FireInput = 'mouse1press'; return true end
        releaseShotInput(true)
    end
    if virtualInput then
        state.MouseOwned = true
        local screen = Input:GetMouseLocation()
        local x, y = screen.X, screen.Y
        state.ShotRelease = function() virtualInput:SendMouseButtonEvent(x, y, 0, false, game, 0) end
        local ok = pcall(function() virtualInput:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
        if ok then state.Capabilities.FireInput = 'VirtualInputManager'; return true end
        releaseShotInput(true)
    end
    state.AutomatedTool = tool
    local ok, reason = pcall(function() tool:Activate() end)
    state.Capabilities.FireInput = 'Tool.Activate fallback'
    if not ok then releaseShotInput(); warnOnce('activate', tostring(reason)); return false end
    return true
end

local function activated(tool)
    if tool ~= equipped or typing() then return end
    local source = 'Manual'
    if state.FiringTool == tool and (state.MouseOwned or state.AutomatedTool) then source = state.FiringSource
    elseif activation and activation.tool == tool and now() <= activation.untilTime then source = activation.source end
    activation = nil
    state.Stats.Activations = state.Stats.Activations + 1
    traceEvent('activation', {Source = source, Tool = tool.Name})
    state.ShotUntil = now() + 0.14
    updateAim()
    refreshPacket()
    local serverPoint = state.PacketPoint or state.LastMousePayload or state.RawMousePoint
    if source == 'Manual' and enabled('Silent Aim') then
        local point = state.Points['Silent Aim']
        if sendAim(point) then serverPoint = point end
    elseif state.ForcedPoint and now() < state.ForcedUntil then serverPoint = state.ForcedPoint end
    state.LastShot = {time = now(), tool = tool, origin = muzzle(), point = config['Client Bullets'].Enabled and state.RawMousePoint or nil,
        serverPoint = serverPoint}
    beginMacro(source, tool)
end

local function bindTool(tool)
    if not tool:IsA('Tool') then return end
    local name = Core.weapon(tool.Name)
    local lower = tool.Name:lower()
    if lower:find('wallet') or lower:find('phone') or lower:find('knife') or lower:find('katana') then return end
    if not name and not ammoObject(tool) and not tool:FindFirstChild('Handle') then return end
    releaseShotInput()
    disconnect(toolConnections)
    equipped, weaponName, muzzleAttachment = tool, name, nil
    state.ToolEpoch = state.ToolEpoch + 1
    for _, item in ipairs(tool:GetDescendants()) do
        if item:IsA('Attachment') and (item.Name:lower():find('muzzle') or item.Name == 'GunAttachment' or item.Name == 'Flare') then muzzleAttachment = item; break end
    end
    local ammoValue = ammoObject(tool)
    if ammoValue and (ammoValue:IsA('IntValue') or ammoValue:IsA('NumberValue')) then
        local previousAmmo = ammoValue.Value
        connect(ammoValue:GetPropertyChangedSignal('Value'), function()
            local value = ammoValue.Value
            if value < previousAmmo then
                state.Stats.AmmoDrops = state.Stats.AmmoDrops + 1
            end
            previousAmmo = value
        end, toolConnections)
    end
    connect(tool.Activated, function() activated(tool) end, toolConnections)
    connect(tool.AncestryChanged, function()
        if tool.Parent ~= localCharacter and equipped == tool then
            releaseShotInput()
            equipped, weaponName, muzzleAttachment = nil, nil, nil
            state.PacketPoint, state.ClientPoint = nil, nil
            pendingPrefire = nil
            disconnect(toolConnections)
        end
    end, toolConnections)
end

local function bindCharacter(character)
    releaseShotInput()
    cancelMacro()
    disconnect(charConnections); disconnect(toolConnections)
    localCharacter, localHumanoid, localRoot = character, nil, nil
    equipped, weaponName, muzzleAttachment = nil, nil, nil
    pendingPrefire, activation = nil, nil
    state.LastLocalVelocity, state.LastShot, state.MacroMotion = nil, nil, nil
    local function added(child)
        if child:IsA('Humanoid') then localHumanoid = child
        elseif child.Name == 'HumanoidRootPart' and child:IsA('BasePart') then localRoot = child
        elseif child:IsA('Tool') then bindTool(child) end
    end
    for _, child in ipairs(character:GetChildren()) do added(child) end
    connect(character.ChildAdded, added, charConnections)
    connect(character.ChildRemoved, function(child)
        if child == localHumanoid then localHumanoid = nil end
        if child == localRoot then localRoot = nil end
    end, charConnections)
end

local function prefireActive()
    local settings = config.Misc.Prefire
    return settings.Enabled and not typing() and (settings.Holding and state.Held.prefire or (not settings.Holding and state.PrefireToggle))
end

local function opponentShot(record)
    local settings = config.Misc.Prefire
    if not prefireActive() or not localRoot or not equipped or not record.root then return end
    if (record.root.Position - localRoot.Position).Magnitude > Core.number(settings.Range, 100, 0, 5000) then return end
    state.LastPrefire = {DetectedAt = now(), Target = record.player.UserId, Status = 'queued'}
    if not pendingPrefire then
        pendingPrefire = {record = record, tool = equipped, due = now() + Core.number(settings.Delay, 0.25, 0, 10)}
    end
end

local function bindOpponent(record, character)
    disconnect(record.characterConnections)
    record.character, record.root, record.humanoid, record.history = character, nil, nil, {}
    record.sampledVelocity, record.velocityAt = nil, nil
    record.bounds, record.boundsAt, record.visibilityAt = nil, nil, nil
    record.pointState = {}
    record.pose = nil
    record.lastAmmo, record.ammoTool = nil, nil
    local function added(item)
        if item.Name == 'HumanoidRootPart' and item:IsA('BasePart') then record.root = item end
        if item:IsA('Humanoid') then record.humanoid = item end
    end
    for _, item in ipairs(character:GetChildren()) do added(item) end
    connect(character.ChildAdded, added, record.characterConnections)
    connect(character.ChildRemoved, function(item)
        if item == record.root then record.root = nil; record.history = {}; record.sampledVelocity = nil end
        if item == record.humanoid then record.humanoid = nil end
    end, record.characterConnections)
end

local function observeAmmo(record)
    if not record.character then return end
    local tool = record.character:FindFirstChildOfClass('Tool')
    local ammo = ammoCount(tool)
    if type(ammo) == 'number' then
        if tool == record.ammoTool and record.lastAmmo and ammo < record.lastAmmo then opponentShot(record) end
        record.lastAmmo = ammo
        state.Capabilities.ReplicatedAmmo = true
    else record.lastAmmo = nil end
    record.ammoTool = tool
end

local function addPlayer(player)
    if player == localPlayer or state.Records[player] then return end
    local record = {player = player, connections = {}, characterConnections = {}, history = {}}
    state.Records[player] = record
    connect(player.CharacterAdded, function(character) bindOpponent(record, character) end, record.connections)
    connect(player.CharacterRemoving, function()
        disconnect(record.characterConnections)
        record.character, record.root, record.humanoid, record.history = nil, nil, nil, {}
    end, record.connections)
    if player.Character then bindOpponent(record, player.Character) end
end

local function scaledCursorTarget(hit, onlyRecord, ray)
    local scale = Core.number(config.Triggerbot.Fov.Character, 1.2, 0.1, 3)
    ray = ray or cursorRay
    if scale == 1 or not ray then return nil end
    local best, bestPart, bestPoint, distance = nil, nil, nil, 5000
    if hit and not onlyRecord then distance = (hit.Position - ray.Origin).Magnitude end
    for _, record in pairs(state.Records) do
        if (not onlyRecord or record == onlyRecord) and record.character and record.root and valid(record, 'Triggerbot', record.root, true) then
            for _, part in ipairs(record.character:GetChildren()) do
                -- This game's real cursor ray also hits the transparent HB. Scaling
                -- only visible limbs left 1.3 no larger than its native hitbox.
                if nativeBodyPart(part, record.character) then
                    local origin = part.CFrame:PointToObjectSpace(ray.Origin)
                    local direction = part.CFrame:VectorToObjectSpace(ray.Direction)
                    local entry = Core.rayBox(origin, direction, part.Size * (scale * 0.5))
                    if entry and entry < distance then
                        local p = origin + direction * entry
                        local half = part.Size * 0.5
                        local point = part.CFrame:PointToWorldSpace(Vector3.new(
                            math.clamp(p.X, -half.X, half.X), math.clamp(p.Y, -half.Y, half.Y), math.clamp(p.Z, -half.Z, half.Z)))
                        if visible(point, record.character, ray.Origin) then
                            best, bestPart, bestPoint, distance = record, part, point, entry
                        end
                    end
                end
            end
        end
    end
    return best, bestPart, bestPoint
end

local function triggerRayTarget(ray, hit)
    local record, part, point
    if hit then
        for _, candidate in pairs(state.Records) do
            if candidate.character and characterSurface(hit.Instance, candidate.character) then
                record, part, point = candidate, hit.Instance, hit.Position
                break
            end
        end
    end
    local scale = Core.number(config.Triggerbot.Fov.Character, 1.2, 0.1, 3)
    if scale < 1 or not record then return scaledCursorTarget(hit, scale < 1 and record or nil, ray) end
    return record, part, point
end

local function triggerRayPoint(ray, hit, source)
    local record, part, point = triggerRayTarget(ray, hit)
    if not record then return nil end
    local predicted = aimPoint(record, 'Triggerbot', part, point, nil, {Source=source, Ray=ray})
    if predicted then return record, predicted end
    return nil
end

local function triggerCandidate()
    if not enabled('Triggerbot') or typing() or not equipped or not captureView() then return nil end
    state.CursorHit = cursorHit()
    if config.Triggerbot.Fov.Enabled then return nearest('Triggerbot', false, resolveAimPoint) end
    local record, point = triggerRayPoint(cursorRay, state.CursorHit, 'camera')
    if point then return record, point end
    -- Complete eligibility and predicted-point checks before accepting a camera
    -- hit; a knocked/ineligible camera target must not starve the native ray.
    local nativeRay = nativeAimRay()
    if nativeRay then
        rayParams.FilterDescendantsInstances = localCharacter and {localCharacter, camera} or {camera}
        local hit = World:Raycast(nativeRay.Origin, nativeRay.Direction * 5000, rayParams)
        return triggerRayPoint(nativeRay, hit, 'muzzle')
    end
    return nil
end

local random = Random.new()
local function automaticFire(time)
    local record, point = triggerCandidate()
    state.Targets.Triggerbot = record and record.player or nil
    state.Points.Triggerbot = point
    -- Looten presses immediately, holds for Delay, then releases. Never overlap cycles.
    if state.FiringSource == 'Triggerbot' and (not record or record ~= state.FiringRecord or equipped ~= state.FiringTool) then releaseShotInput() end
    if record and state.FiringRecord == record and state.FiringSource == 'Triggerbot' then
        state.ForcedPoint = routedShotPoint('Triggerbot', record, point)
    end
    if record then state.TriggerRandom = random:NextNumber(); fire('Triggerbot', record, point) end
    if pendingPrefire then
        local shot = pendingPrefire
        if not prefireActive() or equipped ~= shot.tool or not shot.record.root or not localRoot
            or (shot.record.root.Position - localRoot.Position).Magnitude > Core.number(config.Misc.Prefire.Range, 100, 0, 5000) then
            pendingPrefire = nil
        elseif time >= shot.due then
            pendingPrefire = nil
            local aim = resolveAimPoint(shot.record, 'Triggerbot')
            local fired = aim and fire('Prefire', shot.record, aim)
            state.LastPrefire = {DetectedAt = shot.due - Core.number(config.Misc.Prefire.Delay, 0.25, 0, 10),
                Target = shot.record.player.UserId, Status = fired and 'input-started' or 'rejected',
                Reason = not fired and (not aim and state.AimTrace.Triggerbot and state.AimTrace.Triggerbot.Reason or 'weapon/input readiness') or nil}
        end
    end
end

-- Drawing is optional. Native GUI fallback keeps feature behavior available.
local gui = own(make('ScreenGui', {Name = 'NeoperroOverlay', ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 9000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui))
local function visual(kind)
    local wrapper = {}
    local drawable
    if Drawing and type(Drawing.new) == 'function' then
        local ok, result = pcall(Drawing.new, kind)
        if ok then drawable = result end
    end
    if drawable then
        drawable.Visible = false
        if kind ~= 'Text' then drawable.Thickness = 1; drawable.Filled = false end
        if kind == 'Text' then drawable.Size = 13; drawable.Center = true; drawable.Outline = true end
        local applied = {}
        function wrapper:Set(p)
            for k, v in pairs(p) do
                if applied[k] ~= v then drawable[k] = v; applied[k] = v end
            end
        end
        function wrapper:Destroy() drawable:Remove() end
    else
        local obj = make(kind == 'Text' and 'TextLabel' or 'Frame', {
            Visible = false, BorderSizePixel = 0, BackgroundTransparency = 1,
        }, gui)
        local stroke
        if kind == 'Text' then
            obj.BackgroundTransparency = 1; obj.Font = Enum.Font.Code; obj.TextSize = 13
            obj.TextStrokeTransparency = 0.2; obj.AnchorPoint = Vector2.new(0.5, 0)
            obj.Size = UDim2.fromOffset(240, 18)
        else
            stroke = make('UIStroke', {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, obj)
            if kind == 'Circle' then make('UICorner', {CornerRadius = UDim.new(1, 0)}, obj) end
        end
        local props = {Transparency = 1, Filled = false, Radius = 1, Color = Color3.new(1, 1, 1)}
        function wrapper:Set(p)
            local changed = false
            for k, v in pairs(p) do if props[k] ~= v then changed = true; break end end
            if not changed then return end
            for k, v in pairs(p) do props[k] = v end
            if p.Visible ~= nil then obj.Visible = p.Visible end
            if props.Position then
                local offset = kind == 'Circle' and props.Radius or 0
                obj.Position = UDim2.fromOffset(props.Position.X - offset, props.Position.Y - offset)
            end
            if kind == 'Text' then
                if p.Text then obj.Text = p.Text end
                obj.TextColor3 = props.Color; obj.TextTransparency = 1 - props.Transparency
                obj.TextStrokeTransparency = 1 - props.Transparency * 0.8
            else
                local size = kind == 'Circle' and Vector2.new(props.Radius * 2, props.Radius * 2) or props.Size
                if size then obj.Size = UDim2.fromOffset(size.X, size.Y) end
                obj.BackgroundColor3 = props.Color
                obj.BackgroundTransparency = props.Filled and 1 - props.Transparency or 1
                stroke.Color = props.Color; stroke.Transparency = 1 - props.Transparency
                stroke.Thickness = props.Thickness or 1
            end
        end
        function wrapper:Destroy() obj:Destroy() end
    end
    state.Visuals[wrapper] = true
    return wrapper
end

local fovVisuals = {}
for _, name in ipairs({'Silent Aim', 'Aim Assist', 'Triggerbot'}) do
    fovVisuals[name] = {outline = visual('Circle'), circle = visual('Circle')}
end

local function color(rgb)
    return Color3.fromRGB(Core.number(rgb[1], 255, 0, 255), Core.number(rgb[2], 255, 0, 255), Core.number(rgb[3], 255, 0, 255))
end

local function drawFov()
    for name, shapes in pairs(fovVisuals) do
        local fov = config[name].Fov
        local circle = fov['2d-Circle']
        local show = enabled(name) and (name ~= 'Triggerbot' or fov.Enabled) and fov.Method == '2d-Circle' and circle.Visible == true
        local radius = Core.number(circle.Size, 50, 1, 10000)
        shapes.outline:Set({Visible = show, Position = cursor, Radius = radius, Filled = false,
            Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 0.8})
        shapes.circle:Set({Visible = show, Position = cursor, Radius = radius, Filled = false,
            Thickness = 1, Color = color(circle.Color), Transparency = 1})
    end
end

local function assignedColor(id, fallback)
    if not config.Whitelist.Enabled then return fallback end
    if whitelistLookup()[id] then return state.WhiteMode == 'Target' and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(80, 230, 110) end
    return fallback
end

local function drawPlayers(time)
    for _, record in pairs(state.Records) do
        local ok, reason = pcall(function()
            local exists = record.root and record.humanoid and record.character and record.character.Parent
            local dead = exists and (record.humanoid.Health <= 0 or record.character:GetAttribute('Dead') == true)
            local knocked = exists and isKnocked(record.character)
            for _, feature in ipairs({'Silent Aim', 'Aim Assist', 'Triggerbot'}) do
                local style = config['2d-Box'][feature]
                local standalone = feature == 'Silent Aim' and not style.Visible
                local show = exists and enabled('ESP') and (style.Visible or standalone)
                if dead and (config.ESP.DeadCheck or config.Checks.Dead[checkIndices[feature]]) then show = false end
                if knocked and config.ESP.KnockedCheck then show = false end
                if show and config.ESP.VisibleCheck then
                    if time >= (record.visibilityAt or 0) then
                        record.espVisible, record.visibilityAt = visible(record.root.Position, record.character), time + 0.08
                    end
                    show = record.espVisible
                end
                local position, size
                if show then position, size = playerBox(record, feature, standalone) end
                record.visuals = record.visuals or {}
                local v = record.visuals[feature]
                if position then
                    if not v then v = {outline = visual('Square'), box = visual('Square'), name = visual('Text')}; record.visuals[feature] = v end
                    local foreground = assignedColor(record.player.UserId, color(style.Color.Box[1]))
                    size = Vector2.new(math.max(1, size.X), math.max(1, size.Y))
                    v.outline:Set({Visible = true, Position = position, Size = size, Thickness = 3, Filled = false,
                        Color = color(style.Color.Box[2]), Transparency = 1})
                    v.box:Set({Visible = true, Position = position, Size = size, Filled = false,
                        Color = foreground, Transparency = 1})
                    local display = record.humanoid.DisplayName
                    if type(display) ~= 'string' or display == '' then display = record.player.DisplayName end
                    local name = style.Name[2] == 'Name' and record.player.Name
                        or (style.Name[2] == 'UserId' and tostring(record.player.UserId) or display)
                    v.name:Set({Visible = config.ESP.Names and style.Name[1], Text = name,
                        Position = Vector2.new(position.X + size.X / 2, position.Y - 17), Color = foreground, Transparency = 1})
                elseif v then for _, object in pairs(v) do object:Set({Visible = false}) end end
            end
        end)
        if not ok then
            if record.visuals then for _, group in pairs(record.visuals) do for _, v in pairs(group) do pcall(function() v:Set({Visible = false}) end) end end end
            warnOnce('draw-player:' .. tostring(record.player.UserId), tostring(reason))
        end
    end
end

local function inputMatches(input, action)
    return action and Core.input(action.Keybind, input.KeyCode.Name, input.UserInputType.Name)
end

local function inputChanged(input, began, processed)
    if state.MouseOwned and input.UserInputType == Enum.UserInputType.MouseButton1 then return end
    if began and (processed or typing()) then return end
    if began and config.Misc.Panic.Enabled and inputMatches(input, config.Misc.Panic) then state:Destroy('panic'); return end
    if began and input.UserInputType == Enum.UserInputType.MouseButton1 and equipped then
        state.ShotUntil = now() + 0.14; updateAim(); refreshPacket(); sendAim(state.Points['Silent Aim'])
    end
    for _, name in ipairs(featureNames) do
        local toggle = config[name].Toggle
        if toggle.Enabled and inputMatches(input, toggle) then
            if toggle.Holding then state.Held['toggle:' .. name] = began
            elseif began then state.Toggles[name] = not state.Toggles[name] end
        end
    end
    for _, name in ipairs({'Silent Aim', 'Aim Assist'}) do
        local mode = config[name].Activation
        if inputMatches(input, mode) then
            state.Held['target:' .. name] = began
            if not began and mode.Holding then state.Points[name], state.Targets[name] = nil, nil end
        end
        if config[name].Method == 'Target' and inputMatches(input, mode) then
            if mode.Holding then
                state.Held['target:' .. name] = began
                if not began then state.Locks[name] = nil end
            end
            if began then
                if not mode.Holding and mode['Unlock Method'] == 'Normal' and state.Locks[name] then state.Locks[name] = nil
                else local record = nearest(name); state.Locks[name] = record and record.player.UserId or nil end
            end
        end
    end
    local activationKey = config.Triggerbot.Activation
    if activationKey.Enabled and inputMatches(input, activationKey) then
        if activationKey.Holding then state.Held['activation:Triggerbot'] = began
        elseif began then state.Held['activation:Triggerbot'] = not state.Held['activation:Triggerbot'] end
    end
    if inputMatches(input, config.Misc.Prefire) then
        if config.Misc.Prefire.Holding then state.Held.prefire = began
        elseif began then state.PrefireToggle = not state.PrefireToggle end
    end
    if began then
        if config.Whitelist.Enabled and inputMatches(input, config.Whitelist.AssignKey) then
            local record = nearest('Silent Aim', true)
            if record then
                local id, found = record.player.UserId, nil
                for i, value in ipairs(state.Whitelist) do if value == id then found = i; break end end
                if found then table.remove(state.Whitelist, found)
                else state.Whitelist[#state.Whitelist + 1] = id end
                state.WhiteLookupSource = nil
            end
        end
    end
    if state.FiringSource == 'Triggerbot' and not enabled('Triggerbot') then releaseShotInput() end
    refreshPacket()
end

local function antiFling()
    if not config.Misc.AntiFling or not localRoot or not localHumanoid or localHumanoid.Health <= 0 then return end
    local linear, angular = localRoot.AssemblyLinearVelocity, localRoot.AssemblyAngularVelocity
    local last = state.LastLocalVelocity
    if last and linear.Magnitude > 180 and angular.Magnitude > 40 and (linear - last).Magnitude > 120 then
        localRoot.AssemblyLinearVelocity = Core.limit(last, 60)
        localRoot.AssemblyAngularVelocity = zero
    end
    state.LastLocalVelocity = linear.Magnitude < 180 and linear or zero
end

-- Recognize only tracer-like Beams near this player's most recent shot.
-- Ownership cannot be inferred for arbitrary effects; leave unmatched effects alone.
local beamEdits = {}
local function inspectBeam(beam)
    if not state.Alive or not config['Client Bullets'].Enabled or not beam:IsA('Beam') then return end
    local shot = state.LastShot
    if not shot or now() - shot.time > 0.18 or not shot.point or not shot.origin then return end
    local a, b = beam.Attachment0, beam.Attachment1
    if not a or not b then return end
    local parentName = beam.Parent and beam.Parent.Name:lower() or ''
    local label = beam.Name:lower() .. parentName
    if not (beam.Name == 'gb' or label:find('gun') or label:find('bullet') or label:find('tracer')) then return end
    if (a.WorldPosition - shot.origin).Magnitude > 6 then return end
    local previousPosition = b.Position
    local target = Core.redirectTracer(a.WorldPosition, b.WorldPosition, shot.serverPoint, shot.point, Vector3.new)
    if not target then return end
    b.WorldPosition = target
    beamEdits[#beamEdits + 1] = {beam = beam, attachment = b, old = previousPosition, written = b.Position}
end

local function restoreBeams(all)
    for i = #beamEdits, 1, -1 do
        local edit = beamEdits[i]
        if all or not config['Client Bullets'].Enabled or not edit.beam.Parent or not edit.attachment.Parent then
            if edit.attachment.Parent and edit.attachment.Position == edit.written then edit.attachment.Position = edit.old end
            table.remove(beamEdits, i)
        end
    end
end

local originalDestroy = state.Destroy
state.Destroy = function(self, reason)
    restoreBeams(true)
    originalDestroy(self, reason)
end

-- Update only configuration. Validation precedes all mutation; listeners,
-- drawings, motion history, hooks and the authorized runtime stay in place.
function state:ApplyConfig(supplied)
    assert(self == state and self.Alive and environment[runtimeKey] == self,
        '[neoperro] This runtime is no longer active.')
    assert(type(supplied) == 'table', '[neoperro] Configuration must be a table.')
    local started = now()
    local incoming = Core.merge(Defaults, Core.normalizeConfig(supplied))
    Core.validate(Defaults, incoming)
    local incomingWhitelist = Core.ids(incoming.Whitelist.Players)
    local keepWhitelist = config.Whitelist.Enabled and Core.equal(incomingWhitelist, self.InitialWhitelist)
    local keepWhiteMode = incoming.Whitelist.Method == self.InitialWhiteMode

    releaseShotInput()
    cancelMacro()
    if not incoming['Client Bullets'].Enabled then restoreBeams(true) end
    for _, name in ipairs(featureNames) do
        local initial = incoming[name].Enabled == true
        if incoming[name].Toggle.Enabled then
            self.Toggles[name] = Core.restoreToggle(initial, self.Initial[name], self.Toggles[name])
        else self.Toggles[name] = initial end
        self.Initial[name] = initial
        if not initial or not validPlayer(self.Locks[name]) then self.Locks[name] = nil end
    end
    self.Whitelist = incoming.Whitelist.Enabled and (keepWhitelist and self.Whitelist or incomingWhitelist) or {}
    self.WhiteMode = keepWhiteMode and self.WhiteMode or incoming.Whitelist.Method
    self.InitialWhitelist, self.InitialWhiteMode = incomingWhitelist, incoming.Whitelist.Method
    config, self.Config = incoming, incoming
    self.Held, self.Points, self.Targets, self.AimTrace = {}, {}, {}, {}
    self.CursorHit, self.MouseRemainder, self.TriggerRandom = nil, nil, nil
    self.PacketPoint, self.ClientPoint, self.LastMousePayload = nil, nil, nil
    self.ShotUntil = 0
    self.NextFire = math.max(self.NextFire, now() + 0.08)
    self.AutoPrediction.Features = {}
    pendingPrefire = nil
    for _, record in pairs(self.Records) do
        record.pointState, record.renderAim, record.BoxInfo = nil, nil, nil
        record.visibilityAt, record.espVisible = nil, nil
    end
    self.ConfigUpdates = (self.ConfigUpdates or 0) + 1
    self.LastConfigMs = (now() - started) * 1000
    return self
end

local function start()
    animationCatalog = Posture.catalog(ReplicatedStorage:FindFirstChild('Animations'))
    findRemote()
    installHooks()
    if not state.Remote then warnOnce('missing-remote', 'MAINEVENT is missing; firing redirection waits for it to appear.') end
    if not hooks.Namecall then warnOnce('no-hook', 'Namecall hooks unavailable: using Looten-style activation updates; Anti-AimViewer is unavailable.') end
    connect(ReplicatedStorage.ChildAdded, function(child)
        if child.Name == 'MAINEVENT' or child.Name == 'MainEvent' then findRemote() end
        if child.Name == 'Animations' then animationCatalog = Posture.catalog(child) end
    end)
    connect(ReplicatedStorage.ChildRemoved, function(child) if child == state.Remote then findRemote() end end)
    connect(localPlayer.CharacterAdded, bindCharacter)
    connect(localPlayer.CharacterRemoving, function()
        releaseShotInput(); cancelMacro(); disconnect(charConnections); disconnect(toolConnections)
        localCharacter, localHumanoid, localRoot, equipped, weaponName, muzzleAttachment = nil, nil, nil, nil, nil, nil
        state.PacketPoint, state.ClientPoint, state.Points, state.Targets = nil, nil, {}, {}
        pendingPrefire = nil
    end)
    if localPlayer.Character then bindCharacter(localPlayer.Character) end
    for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
    connect(Players.PlayerAdded, addPlayer)
    connect(Players.PlayerRemoving, function(player)
        local record = state.Records[player]
        if record then
            disconnect(record.connections); disconnect(record.characterConnections)
            if record.visuals then for _, group in pairs(record.visuals) do for _, v in pairs(group) do v:Destroy(); state.Visuals[v] = nil end end end
            state.Records[player] = nil
        end
        for name, id in pairs(state.Locks) do if id == player.UserId then state.Locks[name] = nil end end
    end)
    connect(Input.InputBegan, function(input, processed) inputChanged(input, true, processed) end)
    connect(Input.InputEnded, function(input) inputChanged(input, false, false) end)
    local function suspend()
        state.Held = {}; state.Points = {}; state.Targets = {}; state.MacroMotion = nil
        state.PacketPoint, state.ClientPoint = nil, nil
        pendingPrefire = nil
        cancelMacro(); releaseShotInput()
        if state.AutomatedTool then pcall(function() state.AutomatedTool:Deactivate() end); state.AutomatedTool = nil end
    end
    connect(Input.WindowFocusReleased, function() state.Focused = false; suspend() end)
    connect(Input.WindowFocused, function() state.Focused = true end)
    connect(Input.TextBoxFocused, suspend)
    connect(localPlayer.Idled, function()
        if config.Misc.AntiAfk then
            local ok, reason = pcall(function() local virtualUser = game:GetService('VirtualUser')
                virtualUser:CaptureController()
                local view = World.CurrentCamera
                if view then
                    virtualUser:Button2Down(Vector2.new(0, 0), view.CFrame)
                    virtualUser:Button2Up(Vector2.new(0, 0), view.CFrame)
                end end)
            if not ok then warnOnce('idle', 'AntiAfk unavailable: ' .. tostring(reason)) end
        end
    end)
    connect(World.DescendantAdded, function(object)
        if object:IsA('Beam') then task.defer(function() if state.Alive then inspectBeam(object) end end) end
    end)
    local elapsed = 0
    connect(RunService.Heartbeat, function(dt)
        local time = now()
        if macroEnabled() and config.Misc['Macro Abuse']['Macro Check'] then observeMacroMotion(time)
        else state.MacroMotion = nil end
        if not config.Whitelist.Enabled then state.Whitelist = {} end
        if state.FiringSource == 'Triggerbot' then
            local ammo = ammoCount(state.FiringTool)
            if not enabled('Triggerbot') or (type(ammo) == 'number' and ammo <= 0) then releaseShotInput() end
        end
        if (state.ShotRelease or state.AutomatedTool) and (time >= state.DeactivateAt or not localHumanoid or localHumanoid.Health <= 0) then releaseShotInput() end
        elapsed = elapsed + dt
        if elapsed >= 1 / 60 then
            local updateStarted = now()
            elapsed = elapsed % (1 / 60)
            sampleNetwork(time)
            for _, record in pairs(state.Records) do
                if record.root and Core.finiteVector(record.root.Position) then
                    samplePosture(record, time)
                    Core.sample(record.history, record.root.Position, time, record.root.AssemblyLinearVelocity)
                end
                if config.Misc.Prefire.Enabled then observeAmmo(record) end
            end
            local cost = (now() - updateStarted) * 1000
            state.Performance.Updates = state.Performance.Updates + 1
            state.Performance.TotalMs = state.Performance.TotalMs + cost
            state.Performance.MaxMs = math.max(state.Performance.MaxMs, cost)
        end
        if (state.ShotRelease or state.AutomatedTool) and time >= state.DeactivateAt then releaseShotInput() end
        macroStep(time); antiFling(); restoreBeams(false)
    end)
    RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not state.Alive or not captureView() then return end
        local aimStarted = now()
        updateAim(dt)
        if not typing() then automaticFire(aimStarted) end
        refreshAutoPrediction(aimStarted)
        refreshPacket()
        state.Performance.AimUpdates = state.Performance.AimUpdates + 1
        local aimMs = (now() - aimStarted) * 1000
        state.Performance.AimTotalMs = state.Performance.AimTotalMs + aimMs
        state.Performance.AimMaxMs = math.max(state.Performance.AimMaxMs, aimMs)
        local renderStarted = now()
        if state.Intro and state.Intro.Alive then
            for visual in pairs(state.Visuals) do visual:Set({Visible = false}) end
            return
        end
        local ok, reason = pcall(drawFov)
        if not ok then warnOnce('draw-fov', tostring(reason)) end
        drawPlayers(now())
        state.Performance.RenderUpdates = (state.Performance.RenderUpdates or 0) + 1
        local renderMs = (now() - renderStarted) * 1000
        state.Performance.RenderTotalMs = (state.Performance.RenderTotalMs or 0) + renderMs
        state.Performance.RenderMaxMs = math.max(state.Performance.RenderMaxMs or 0, renderMs)
    end)
    -- Intro is bundled locally; no second downloaded script and no exposed intro options.
    if not environment.__neoperroIntroSeenV1 then
        environment.__neoperroIntroSeenV1 = true
        state.Intro = playIntro()
    end
    local panic = config.Misc.Panic.Keybind
    print('[neoperro] v' .. state.Version .. ' loaded for ' .. supported[game.PlaceId]
        .. '. ' .. (config.Misc.Panic.Enabled and (tostring(panic[panic[3] == 'Mouse' and 2 or 1]) .. ' = panic/unload.') or 'Panic key disabled.'))
end

local ok, reason = xpcall(start, debug.traceback)
if not ok then state:Destroy('startup-error'); error('[neoperro] ' .. tostring(reason), 0) end
return state
