-- Bundler supplies Core, Defaults and playIntro; this file is the readable runtime body.
local environment = type(getgenv) == 'function' and getgenv() or _G
local supported = {
    [134196333708867] = 'Da Strike',
    [71324444457408] = 'Da Uphill',
    [139144803593140] = 'Da Downhill',
}
assert(supported[game.PlaceId], '[neoperro] This place is not supported.')
assert(type(environment.neoperro) == 'table', '[neoperro] Put the configuration above the runtime.')
local config = Core.merge(Defaults, environment.neoperro)
Core.validate(Defaults, config)
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Input = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local World = game:GetService('Workspace')
local localPlayer = Players.LocalPlayer
assert(localPlayer, '[neoperro] Run on the client.')
local mouse = localPlayer:GetMouse()
local playerGui = localPlayer:WaitForChild('PlayerGui', 5)
assert(playerGui, '[neoperro] PlayerGui unavailable.')
local runtimeKey, hooksKey = '__neoperroRuntimeV1', '__neoperroHooksV1'
local previous = environment[runtimeKey]
local saved = previous and previous.Alive and previous:Snapshot() or nil
if previous and type(previous.Destroy) == 'function' then previous:Destroy('replace') end

local state = {
    Alive = true, Version = '1.0.0', Config = config, Connections = {}, Objects = {},
    Records = {}, Toggles = {}, Held = {}, Locks = {}, Points = {}, Targets = {},
    Warnings = {}, Capabilities = {}, ShotUntil = 0, NextFire = 0, Initial = {},
    Whitelist = Core.ids(config.Whitelist.Players), WhiteMode = config.Whitelist.Mode,
    InitialWhitelist = Core.ids(config.Whitelist.Players), InitialWhiteMode = config.Whitelist.Mode,
    Epoch = 0, Visuals = {}, Focused = true,
}
environment[runtimeKey] = state
local zero = Vector3.new(0, 0, 0)
local now = os.clock
local camera, cursor, cursorRay
local localCharacter, localHumanoid, localRoot, equipped, weaponName
local charConnections, toolConnections = {}, {}
local pendingTrigger, pendingPrefire, macro, activation
local renderName = 'neoperro.' .. tostring(now())
local featureNames = {'Silent Aim', 'Aim Assist', 'Triggerbot', 'ESP'}
local checkIndices = {['Silent Aim'] = 1, ['Aim Assist'] = 2, Triggerbot = 3}
local predictionKeys = {['Silent Aim'] = 'SilentAim', ['Aim Assist'] = 'AimAssist', Triggerbot = 'Triggerbot'}
local virtualInput
pcall(function() virtualInput = game:GetService('VirtualInputManager') end)

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
    if saved then state.Toggles[name] = Core.restoreToggle(state.Initial[name], saved.Initial[name], saved.Toggles[name]) end
    if saved and saved.Locks[name] and validPlayer(saved.Locks[name]) then state.Locks[name] = saved.Locks[name] end
end
if saved then
    if Core.equal(state.InitialWhitelist, saved.InitialWhitelist) then state.Whitelist = Core.ids(saved.Whitelist) end
    if state.InitialWhiteMode == saved.InitialWhiteMode then state.WhiteMode = saved.WhiteMode end
end

function state:Snapshot()
    return Core.copy({Initial = self.Initial, Toggles = self.Toggles, Locks = self.Locks,
        Whitelist = self.Whitelist, WhiteMode = self.WhiteMode,
        InitialWhitelist = self.InitialWhitelist, InitialWhiteMode = self.InitialWhiteMode})
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
    self.Points, self.Targets = {}, {}
    local hooks = environment[hooksKey]
    if hooks and hooks.Active == self then hooks.Active = nil end
    RunService:UnbindFromRenderStep(renderName)
    disconnect(self.Connections)
    disconnect(charConnections)
    disconnect(toolConnections)
    cancelMacro()
    if self.AutomatedTool then pcall(function() self.AutomatedTool:Deactivate() end) end
    for _, record in pairs(self.Records) do disconnect(record.connections); disconnect(record.characterConnections) end
    if self.Intro and self.Intro.Destroy then self.Intro:Destroy() end
    for visual in pairs(self.Visuals) do pcall(function() visual:Destroy() end) end
    for i = #self.Objects, 1, -1 do pcall(function() self.Objects[i]:Destroy() end) end
    if environment[runtimeKey] == self then environment[runtimeKey] = nil end
    if reason ~= 'replace' then print('[neoperro] Unloaded.') end
end

local function enabled(name)
    local feature = config[name]
    if not state.Toggles[name] then return false end
    local toggle = feature.Toggle
    if toggle and toggle.Enabled and toggle.Holding then return state.Held['toggle:' .. name] == true end
    return true
end

local function typing()
    return not state.Focused or Input:GetFocusedTextBox() ~= nil
end

local function captureView()
    camera = World.CurrentCamera
    if not camera then return false end
    cursor = Input:GetMouseLocation()
    cursorRay = camera:ViewportPointToRay(cursor.X, cursor.Y)
    return true
end

local function childValue(parent, name)
    local item = parent and parent:FindFirstChild(name)
    return item and item:IsA('ValueBase') and item.Value or nil
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

local function valid(record, feature, part, skipWall)
    if not record or record.player == localPlayer or record.player.Parent ~= Players then return false end
    local character, humanoid, root = record.character, record.humanoid, record.root
    if not character or not character.Parent or not humanoid or not root or not part or not part.Parent then return false end
    if not Core.finiteVector(part.Position) then return false end
    if not Core.whitelisted(config.Whitelist.Enabled, state.WhiteMode, state.Whitelist, record.player.UserId) then return false end
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
    if not skipWall and check('Wall') and not visible(part.Position, character) then return false end
    return true
end

local function velocity(record)
    local raw = record.root.AssemblyLinearVelocity
    if not Core.finiteVector(raw) then raw = zero end
    if config.EndMath.VelocityHistory then return Core.velocity(record.history, raw, zero) end
    return Core.limit(raw, 180)
end

local function inFov(record, feature, part)
    local settings = config[feature]
    if settings.Ignore then return true end
    local projected, onScreen = camera:WorldToViewportPoint(part.Position)
    if not onScreen or projected.Z <= 0 then return false end
    local dx, dy = projected.X - cursor.X, projected.Y - cursor.Y
    local fov = settings.Fov
    local box, circle = fov['2d-Box'], fov['2d-Circle']
    local inside = Core.fov(dx, dy, fov.Mode,
        Core.number(box.Size.X, 100, 1, 10000), Core.number(box.Size.Y, 100, 1, 10000),
        Core.number(circle.Size, 50, 1, 10000))
    if not inside then return false end
    local distance = (record.root.Position - (localRoot and localRoot.Position or camera.CFrame.Position)).Magnitude
    local profile = Core.profile(config['Gun Specifications'], weaponName, distance)
    if profile and type(profile.BoxSize) == 'table' then
        local focal = camera.ViewportSize.Y / (2 * math.tan(math.rad(camera.FieldOfView) / 2))
        local width = Core.number(profile.BoxSize[1], 5, 0.1, 100) * focal / projected.Z
        local height = Core.number(profile.BoxSize[2], 6, 0.1, 100) * focal / projected.Z
        return math.abs(dx) <= width / 2 and math.abs(dy) <= height / 2
    end
    return true
end

local function nearest(feature, assignment)
    if not captureView() then return nil end
    local choices = {}
    for _, record in pairs(state.Records) do
        local part = partFor(record, assignment and 'HumanoidRootPart' or config[feature].Part)
        if part and (assignment or (valid(record, feature, part, true) and inFov(record, feature, part))) then
            local projected, onScreen = camera:WorldToViewportPoint(part.Position)
            if projected.Z > 0 and (onScreen or (not assignment and config[feature].Ignore)) then
                local distance = (Vector2.new(projected.X, projected.Y) - cursor).Magnitude
                if not assignment or distance <= 150 then
                    choices[#choices + 1] = {record = record, part = part, distance = distance}
                end
            end
        end
    end
    table.sort(choices, function(a, b) return a.distance < b.distance end)
    for _, choice in ipairs(choices) do
        if assignment or valid(choice.record, feature, choice.part) then return choice.record end
    end
end

local function aimPoint(record, feature)
    local settings = feature == 'Triggerbot' and config['Silent Aim'] or config[feature]
    local part = partFor(record, settings.Part)
    if not valid(record, feature, part) then return nil end
    if feature ~= 'Triggerbot' and not inFov(record, feature, part) then return nil end
    local point = part.Position
    if settings.Method == 'Point' then
        local depth = math.max(0, (point - cursorRay.Origin):Dot(cursorRay.Direction))
        local localPoint = part.CFrame:PointToObjectSpace(cursorRay.Origin + cursorRay.Direction * depth)
        local half = part.Size * (0.5 * (1 - Core.number(settings.PointReduction, 0.7, 0, 1)))
        point = part.CFrame:PointToWorldSpace(Vector3.new(
            math.clamp(localPoint.X, -half.X, half.X), math.clamp(localPoint.Y, -half.Y, half.Y),
            math.clamp(localPoint.Z, -half.Z, half.Z)))
    end
    local base = point
    local leadTime = Core.number(config.Prediction[predictionKeys[feature]], 0.128, 0, 1)
    local vel = velocity(record)
    local lead = vel * leadTime
    local ySettings = config['Y-Axis']
    if ySettings.Enabled and ySettings[predictionKeys[feature]] then
        local y = lead.Y
        if ySettings.Mode == 'Custom' then
            if vel.Y > 0 then y = y * Core.number(ySettings.JumpOffset, 1, 0, 5) end
        else
            local airborne = record.humanoid.FloorMaterial == Enum.Material.Air
            y = airborne and (vel.Y * leadTime - 0.5 * World.Gravity * leadTime * leadTime) or 0
            y = math.clamp(y, -part.Size.Y, part.Size.Y * 2)
        end
        lead = Vector3.new(lead.X, y, lead.Z)
    end
    point = point + lead
    if feature ~= 'Triggerbot' and settings.Axis == 'Center' then
        -- Preserve the user's horizontal ray; change pitch only.
        local ray = feature == 'Aim Assist' and {Origin = camera.CFrame.Position, Direction = camera.CFrame.LookVector} or cursorRay
        local horizontal = Vector3.new(ray.Direction.X, 0, ray.Direction.Z)
        local distance = Vector3.new(point.X - ray.Origin.X, 0, point.Z - ray.Origin.Z).Magnitude
        if horizontal.Magnitude > 1e-5 then
            local manual = ray.Origin + horizontal.Unit * distance
            point = Vector3.new(manual.X, point.Y, manual.Z)
        end
    end
    local anti = feature == 'Silent Aim' and settings.AntiCurve
    if anti and anti.Enabled then
        if anti.Mode == 'endmath' then
            point = base + Core.limit(point - base, Core.number(anti.endmath.Radius, 120, 0, 1000))
        else
            local origin = muzzle()
            local a, b = base - origin, point - origin
            if a.Magnitude > 0.01 and b.Magnitude > 0.01 then
                local angle = math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1))
                local maximum = math.rad(Core.number(anti['3d-angles'].MaxAngle, 4, 0, 180))
                if angle > maximum and angle > 1e-6 then
                    local perpendicular = b.Unit - a.Unit * a.Unit:Dot(b.Unit)
                    if perpendicular.Magnitude > 1e-6 then
                        point = origin + (a.Unit * math.cos(maximum) + perpendicular.Unit * math.sin(maximum)) * b.Magnitude
                    else point = base end
                end
            end
        end
    end
    if not Core.finiteVector(point) then return nil end
    if config.EndMath.WallCheck and (not visible(point, record.character, camera.CFrame.Position, true)
        or not visible(point, record.character, muzzle(), true)) then return nil end
    return point, part
end

local function selectTarget(feature)
    if not enabled(feature) or typing() then return nil end
    if config[feature].Mode == 'Auto' then return nearest(feature) end
    local mode = config[feature]['Keybind Mode']
    if mode.Holding and not state.Held['target:' .. feature] then return nil end
    local player = validPlayer(state.Locks[feature])
    return player and state.Records[player] or nil
end

local function updateAim()
    if not captureView() or not localHumanoid or localHumanoid.Health <= 0 then
        state.Points, state.Targets = {}, {}; return
    end
    for _, feature in ipairs({'Silent Aim', 'Aim Assist'}) do
        local record = selectTarget(feature)
        local point, part
        if record then point, part = aimPoint(record, feature) end
        state.Targets[feature] = point and record.player or nil
        state.Points[feature] = point
        if feature == 'Silent Aim' then state.AimPart = part end
    end
    state.ForwardPoint = camera.CFrame.Position + camera.CFrame.LookVector * 1000
    state.RawMousePoint = mouse.Hit.Position
end

-- One permanent pass-through dispatcher per metamethod; replacements only swap Active.
local hooks = environment[hooksKey]
if type(hooks) ~= 'table' then hooks = {}; environment[hooksKey] = hooks end
local function installHooks()
    local wrap = type(newcclosure) == 'function' and newcclosure or function(f) return f end
    if type(hookmetamethod) == 'function' and type(getnamecallmethod) == 'function' and not hooks.Namecall then
        local original
        local ok, result = pcall(function()
            return hookmetamethod(game, '__namecall', wrap(function(object, ...)
                local active = hooks.Active
                if active and active.Alive and object == active.Remote and getnamecallmethod() == 'FireServer' then
                    local args = table.pack(...)
                    if args[1] == 'MOUSE' and typeof(args[2]) == 'Vector3' and active.PacketPoint then
                        args[2] = active.PacketPoint
                        return original(object, table.unpack(args, 1, args.n))
                    end
                end
                return original(object, ...)
            end))
        end)
        if ok then original = result; hooks.Namecall = true else warnOnce('namecall', tostring(result)) end
    end
    if hooks.Namecall and type(hookmetamethod) == 'function' and type(checkcaller) == 'function' and not hooks.Index then
        local original
        local ok, result = pcall(function()
            return hookmetamethod(game, '__index', wrap(function(object, key)
                local active = hooks.Active
                if active and active.Alive and object == active.Mouse and not checkcaller()
                    and active.ClientPoint and os.clock() < active.ShotUntil then
                    if key == 'Hit' then return CFrame.new(active.ClientPoint) end
                    if key == 'Target' and active.AimPart then return active.AimPart end
                end
                return original(object, key)
            end))
        end)
        if ok then original = result; hooks.Index = true else warnOnce('index', tostring(result)) end
    end
    hooks.Active = state
    state.Mouse = mouse
    state.Capabilities.RemoteHook = hooks.Namecall == true
    state.Capabilities.ClientMouseHook = hooks.Index == true
end

local function refreshPacket()
    local point = state.Points['Silent Aim']
    local shooting = now() < state.ShotUntil or (not typing() and Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))
    if state.ForcedPoint and now() < state.ForcedUntil then point = state.ForcedPoint end
    state.PacketPoint = nil
    if equipped and enabled('Silent Aim') and not typing() then
        if config['Anti-AimViewer'].Enabled and not shooting then state.PacketPoint = state.ForwardPoint
        else state.PacketPoint = point end
    end
    if shooting and state.ForcedPoint and now() < state.ForcedUntil then state.PacketPoint = state.ForcedPoint end
    state.ClientPoint = config['Client Bullets'].Enabled and (point or state.Points['Aim Assist']) or nil
    -- Keep the local-visual hook from turning camera-only assistance into silent aim.
    if shooting and state.ClientPoint and not state.PacketPoint then state.PacketPoint = state.RawMousePoint end
end

local function sendAim(point)
    if not point or not state.Remote then return end
    state.PacketPoint = point
    local ok, reason = pcall(function() state.Remote:FireServer('MOUSE', point) end)
    if not ok then warnOnce('remote-send', tostring(reason)) end
end

local function beginMacro(source, tool)
    local settings = config.Misc['Macro Abuse']
    if macro or not settings.Enabled or (source == 'Triggerbot' and not settings['Work With TB']) then return end
    if not virtualInput then warnOnce('macro-input', 'Macro needs VirtualInputManager key events.'); return end
    if not localHumanoid or localHumanoid.Health <= 0 or typing() then return end
    macro = {stage = 'wait', due = now() + 0.04, tool = tool, character = localCharacter}
end

local function macroStep(time)
    if not macro then return end
    local cycle = macro
    if not config.Misc['Macro Abuse'].Enabled or typing() or localCharacter ~= cycle.character
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

local function fire(source, record, point)
    if not equipped or not equipped.Enabled or macro or typing() or now() < state.NextFire then return false end
    if not localHumanoid or localHumanoid.Health <= 0 or isKnocked(localCharacter) then return false end
    local ammo = childValue(equipped, 'Ammo')
    if type(ammo) == 'number' and ammo <= 0 then return false end
    local time, tool = now(), equipped
    state.NextFire, state.ShotUntil = time + 0.08, time + 0.12
    state.ForcedPoint, state.ForcedUntil = point, time + 0.12
    activation = {source = source, tool = tool, untilTime = time + 0.12, sent = true}
    sendAim(point)
    state.AutomatedTool, state.DeactivateAt = tool, time + 0.035
    local ok, reason = pcall(function() tool:Activate() end)
    if not ok then warnOnce('activate', tostring(reason)); return false end
    return true
end

local function activated(tool)
    if tool ~= equipped or typing() then return end
    local source = 'Manual'
    if activation and activation.tool == tool and now() <= activation.untilTime then source = activation.source end
    activation = nil
    state.ShotUntil = now() + 0.12
    updateAim()
    refreshPacket()
    if source == 'Manual' then sendAim(state.Points['Silent Aim']) end
    state.LastShot = {time = now(), tool = tool, origin = muzzle(), point = state.ClientPoint}
    beginMacro(source, tool)
end

local function bindTool(tool)
    if not tool:IsA('Tool') then return end
    local name = Core.weapon(tool.Name)
    if not name and not tool:FindFirstChild('Ammo') then return end
    disconnect(toolConnections)
    equipped, weaponName = tool, name
    connect(tool.Activated, function() activated(tool) end, toolConnections)
    connect(tool.AncestryChanged, function()
        if tool.Parent ~= localCharacter and equipped == tool then
            equipped, weaponName = nil, nil
            state.PacketPoint, state.ClientPoint = nil, nil
            pendingTrigger, pendingPrefire = nil, nil
            disconnect(toolConnections)
        end
    end, toolConnections)
end

local function bindCharacter(character)
    cancelMacro()
    disconnect(charConnections); disconnect(toolConnections)
    localCharacter, localHumanoid, localRoot = character, nil, nil
    equipped, weaponName = nil, nil
    pendingTrigger, pendingPrefire, activation = nil, nil, nil
    state.LastLocalVelocity, state.LastShot = nil, nil
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
    if not pendingPrefire then
        pendingPrefire = {record = record, tool = equipped, due = now() + Core.number(settings.Delay, 0.25, 0, 10)}
    end
end

local function bindOpponent(record, character)
    disconnect(record.characterConnections)
    record.character, record.root, record.humanoid, record.history = character, nil, nil, {}
    record.bounds, record.boundsAt, record.visibilityAt = nil, nil, nil
    record.lastAmmo, record.ammoTool = nil, nil
    local function added(item)
        if item.Name == 'HumanoidRootPart' and item:IsA('BasePart') then record.root = item end
        if item:IsA('Humanoid') then record.humanoid = item end
    end
    for _, item in ipairs(character:GetChildren()) do added(item) end
    connect(character.ChildAdded, added, record.characterConnections)
    connect(character.ChildRemoved, function(item)
        if item == record.root then record.root = nil; record.history = {} end
        if item == record.humanoid then record.humanoid = nil end
    end, record.characterConnections)
end

local function observeAmmo(record)
    if not record.character then return end
    local tool = record.character:FindFirstChildOfClass('Tool')
    local ammo = tool and childValue(tool, 'Ammo')
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

local function triggerCandidate()
    if not enabled('Triggerbot') or typing() or not equipped or not captureView() then return nil end
    rayParams.FilterDescendantsInstances = localCharacter and {localCharacter, camera} or {camera}
    local hit = World:Raycast(cursorRay.Origin, cursorRay.Direction * 5000, rayParams)
    if not hit then return nil end
    local object, player = hit.Instance, nil
    while object and object ~= World do
        if object:IsA('Model') then player = Players:GetPlayerFromCharacter(object); if player then break end end
        object = object.Parent
    end
    local record = player and state.Records[player]
    if not record then return nil end
    if config.Triggerbot.TargetOnly and player ~= state.Targets['Silent Aim'] then return nil end
    local point = aimPoint(record, 'Triggerbot')
    if point then return record, point end
end

local random = Random.new()
local function automaticFire(time)
    local record, point = triggerCandidate()
    if not record then pendingTrigger = nil
    elseif not pendingTrigger or pendingTrigger.record ~= record or pendingTrigger.tool ~= equipped then
        local distance = (record.root.Position - muzzle()).Magnitude
        pendingTrigger = {record = record, tool = equipped, due = time + Core.delay(config.Triggerbot, distance, random:NextNumber())}
    elseif time >= pendingTrigger.due then
        if fire('Triggerbot', record, point) then pendingTrigger = nil end
    end
    if pendingPrefire then
        local shot = pendingPrefire
        if not prefireActive() or equipped ~= shot.tool or not shot.record.root or not localRoot
            or (shot.record.root.Position - localRoot.Position).Magnitude > Core.number(config.Misc.Prefire.Range, 100, 0, 5000) then
            pendingPrefire = nil
        elseif time >= shot.due then
            pendingPrefire = nil
            local aim = aimPoint(shot.record, 'Triggerbot')
            if aim then fire('Prefire', shot.record, aim) end
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
        if kind == 'Circle' then drawable.NumSides = 64 end
        if kind ~= 'Text' then drawable.Thickness = 1; drawable.Filled = false end
        if kind == 'Text' then drawable.Size = 13; drawable.Center = true; drawable.Outline = true end
        function wrapper:Set(p) for k, v in pairs(p) do drawable[k] = v end end
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

local fovVisuals, debugVisuals = {}, {}
for _, name in ipairs({'Silent Aim', 'Aim Assist'}) do
    fovVisuals[name] = {box = visual('Square'), circle = visual('Circle')}
    debugVisuals[name] = visual('Circle')
end

local function color(rgb)
    return Color3.fromRGB(Core.number(rgb[1], 255, 0, 255), Core.number(rgb[2], 255, 0, 255), Core.number(rgb[3], 255, 0, 255))
end

local function drawFov()
    for name, shapes in pairs(fovVisuals) do
        local fov = config[name].Fov
        local box, circle = fov['2d-Box'], fov['2d-Circle']
        local size = Vector2.new(Core.number(box.Size.X, 100, 1, 10000), Core.number(box.Size.Y, 100, 1, 10000))
        shapes.box:Set({Visible = enabled(name) and fov.Mode == '2d-Box' and box.Visible == true,
            Position = cursor - size / 2, Size = size, Color = color(box.Color), Transparency = 1})
        shapes.circle:Set({Visible = enabled(name) and fov.Mode == '2d-Circle' and circle.Visible == true,
            Position = cursor, Radius = Core.number(circle.Size, 50, 1, 10000), Color = color(circle.Color), Transparency = 1})
        local point = state.Points[name]
        local projected, onScreen
        if point then projected, onScreen = camera:WorldToViewportPoint(point) end
        debugVisuals[name]:Set({Visible = config.EndMath.Visualizer and onScreen == true,
            Position = projected and Vector2.new(projected.X, projected.Y) or cursor,
            Radius = 3, Filled = true, Color = Color3.new(1, 1, 1), Transparency = 1})
    end
end

local function bounds(record, time)
    if not record.bounds or time >= (record.boundsAt or 0) then
        local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
        for _, part in ipairs(record.character:GetChildren()) do
            if part:IsA('BasePart') then
                for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
                    local corner = record.root.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2))
                    low = Vector3.new(math.min(low.X, corner.X), math.min(low.Y, corner.Y), math.min(low.Z, corner.Z))
                    high = Vector3.new(math.max(high.X, corner.X), math.max(high.Y, corner.Y), math.max(high.Z, corner.Z))
                end end end
            end
        end
        record.bounds, record.boundsAt = {low, high}, time + 0.25
    end
    local low, high = record.bounds[1], record.bounds[2]
    if not Core.finiteVector(low) or not Core.finiteVector(high) then return nil end
    local prediction = config.ESP['2d-Box'].PredictedPos and velocity(record) * Core.number(config.Prediction.SilentAim, 0.128, 0, 1) or zero
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, x in ipairs({low.X, high.X}) do for _, y in ipairs({low.Y, high.Y}) do for _, z in ipairs({low.Z, high.Z}) do
        local p = camera:WorldToViewportPoint(record.root.CFrame:PointToWorldSpace(Vector3.new(x, y, z)) + prediction)
        if p.Z < 0.1 then return nil end
        minX, minY, maxX, maxY = math.min(minX, p.X), math.min(minY, p.Y), math.max(maxX, p.X), math.max(maxY, p.Y)
    end end end
    if maxX < 0 or maxY < 0 or minX > camera.ViewportSize.X or minY > camera.ViewportSize.Y then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local function drawPlayers(time)
    for _, record in pairs(state.Records) do
        local show = enabled('ESP') and record.root and record.humanoid and record.humanoid.Health > 0 and record.character.Parent
        if show then show = (record.root.Position - camera.CFrame.Position).Magnitude <= Core.number(config.ESP.MaxDistance, 5050, 0, 100000) end
        if show and config.ESP.VisibleCheck then
            if time >= (record.visibilityAt or 0) then
                record.espVisible = visible(record.root.Position, record.character)
                record.visibilityAt = time + 0.08
            end
            show = record.espVisible
        end
        local position, size
        if show then position, size = bounds(record, time) end
        if position then
            if not record.visuals then record.visuals = {outline = visual('Square'), box = visual('Square'), name = visual('Text')} end
            local v, style = record.visuals, config.ESP['2d-Box']
            local opacity = Core.number(style.Transparency, 1, 0, 1)
            v.outline:Set({Visible = true, Position = position, Size = size, Thickness = 3, Filled = false,
                Color = Color3.new(0, 0, 0), Transparency = opacity})
            v.box:Set({Visible = true, Position = position, Size = size, Filled = style.Filled == true,
                Color = Color3.fromRGB(242, 240, 235), Transparency = opacity})
            v.name:Set({Visible = config.ESP.Names == true, Text = record.player.DisplayName,
                Position = Vector2.new(position.X + size.X / 2, position.Y - 17),
                Color = Color3.fromRGB(242, 240, 235), Transparency = opacity})
        elseif record.visuals then
            for _, v in pairs(record.visuals) do v:Set({Visible = false}) end
        end
    end
end

local function inputMatches(input, action)
    return action and Core.input(action.Keybind, input.KeyCode.Name, input.UserInputType.Name)
end

local function inputChanged(input, began, processed)
    if began and (processed or typing()) then return end
    if began and inputMatches(input, config.Misc.Panic) then state:Destroy('panic'); return end
    if began and input.UserInputType == Enum.UserInputType.MouseButton1 and equipped then
        state.ShotUntil = now() + 0.12; updateAim(); refreshPacket()
    end
    for _, name in ipairs(featureNames) do
        local toggle = config[name].Toggle
        if toggle.Enabled and inputMatches(input, toggle) then
            if toggle.Holding then state.Held['toggle:' .. name] = began
            elseif began then state.Toggles[name] = not state.Toggles[name] end
        end
    end
    for _, name in ipairs({'Silent Aim', 'Aim Assist'}) do
        local mode = config[name]['Keybind Mode']
        if config[name].Mode == 'Target' and inputMatches(input, mode) then
            if mode.Holding then
                state.Held['target:' .. name] = began
                if not began then state.Locks[name] = nil end
            end
            if began then
                if not mode.Holding and mode['Unlock Mode'] == 'Normal' and state.Locks[name] then state.Locks[name] = nil
                else local record = nearest(name); state.Locks[name] = record and record.player.UserId or nil end
            end
        end
    end
    if inputMatches(input, config.Misc.Prefire) then
        if config.Misc.Prefire.Holding then state.Held.prefire = began
        elseif began then state.PrefireToggle = not state.PrefireToggle end
    end
    if began then
        if inputMatches(input, config.Whitelist.AssignKey) then
            local record = nearest('Silent Aim', true)
            if record then
                local id, found = record.player.UserId, nil
                for i, value in ipairs(state.Whitelist) do if value == id then found = i; break end end
                if found then table.remove(state.Whitelist, found)
                elseif #state.Whitelist < 4 then state.Whitelist[#state.Whitelist + 1] = id end
            end
        end
        if inputMatches(input, config.Whitelist.ClearKey) then state.Whitelist = {} end
        if inputMatches(input, config.Whitelist.ToggleModeKey) then state.WhiteMode = state.WhiteMode == 'Friend' and 'Target' or 'Friend' end
    end
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
    if not (label:find('gun') or label:find('bullet') or label:find('tracer')) then return end
    if (a.WorldPosition - shot.origin).Magnitude > 6 then return end
    local previousPosition, target = b.Position, shot.point
    b.WorldPosition = target
    beamEdits[#beamEdits + 1] = {attachment = b, old = previousPosition, written = b.Position, expires = now() + 0.3}
end

local function restoreBeams(all)
    for i = #beamEdits, 1, -1 do
        local edit = beamEdits[i]
        if all or now() >= edit.expires or not edit.attachment.Parent then
            if edit.attachment.Parent and edit.attachment.Position == edit.written then edit.attachment.Position = edit.old end
            table.remove(beamEdits, i)
        end
    end
end

local originalDestroy = state.Destroy
function state:Destroy(reason)
    restoreBeams(true)
    originalDestroy(self, reason)
end

local function findRemote()
    local remote = ReplicatedStorage:FindFirstChild('MAINEVENT')
    state.Remote = remote and remote:IsA('RemoteEvent') and remote or nil
    state.Capabilities.Remote = state.Remote ~= nil
end

local function start()
    findRemote()
    installHooks()
    if not state.Remote then warnOnce('missing-remote', 'MAINEVENT is missing; firing redirection waits for it to appear.') end
    if not hooks.Namecall then warnOnce('no-hook', 'Namecall hooks unavailable: using Looten-style activation updates; Anti-AimViewer is unavailable.') end
    if not hooks.Index then warnOnce('no-index', 'Mouse hooks unavailable: local bullet redirection is limited to recognized Beams.') end
    connect(ReplicatedStorage.ChildAdded, function(child) if child.Name == 'MAINEVENT' then findRemote() end end)
    connect(ReplicatedStorage.ChildRemoved, function(child) if child == state.Remote then findRemote() end end)
    connect(localPlayer.CharacterAdded, bindCharacter)
    connect(localPlayer.CharacterRemoving, function()
        cancelMacro(); disconnect(charConnections); disconnect(toolConnections)
        localCharacter, localHumanoid, localRoot, equipped, weaponName = nil, nil, nil, nil, nil
        state.PacketPoint, state.ClientPoint, state.Points, state.Targets = nil, nil, {}, {}
        pendingTrigger, pendingPrefire = nil, nil
    end)
    if localPlayer.Character then bindCharacter(localPlayer.Character) end
    for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
    connect(Players.PlayerAdded, addPlayer)
    connect(Players.PlayerRemoving, function(player)
        local record = state.Records[player]
        if record then
            disconnect(record.connections); disconnect(record.characterConnections)
            if record.visuals then for _, v in pairs(record.visuals) do v:Destroy(); state.Visuals[v] = nil end end
            state.Records[player] = nil
        end
        for name, id in pairs(state.Locks) do if id == player.UserId then state.Locks[name] = nil end end
    end)
    connect(Input.InputBegan, function(input, processed) inputChanged(input, true, processed) end)
    connect(Input.InputEnded, function(input) inputChanged(input, false, false) end)
    local function suspend()
        state.Held = {}; state.Points = {}; state.Targets = {}
        state.PacketPoint, state.ClientPoint = nil, nil
        pendingTrigger, pendingPrefire = nil, nil
        cancelMacro()
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
        elapsed = elapsed + dt
        if elapsed >= 1 / 30 then
            elapsed = elapsed % (1 / 30)
            for _, record in pairs(state.Records) do
                if record.root and Core.finiteVector(record.root.Position) then Core.sample(record.history, record.root.Position, time) end
                if config.Misc.Prefire.Enabled then observeAmmo(record) end
            end
            updateAim()
            if not typing() then automaticFire(time) end
            refreshPacket()
        end
        if state.AutomatedTool and time >= state.DeactivateAt then
            pcall(function() state.AutomatedTool:Deactivate() end); state.AutomatedTool = nil
        end
        macroStep(time); antiFling(); restoreBeams(false)
    end)
    RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not state.Alive or not captureView() then return end
        local point = state.Points['Aim Assist']
        if point and enabled('Aim Assist') and not typing() and config['Aim Assist'].Follow == 'Camera' then
            local offset = point - camera.CFrame.Position
            if offset.Magnitude > 0.01 then
                camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, point), Core.alpha(config['Aim Assist'].Smoothness, dt))
            end
        end
        drawFov(); drawPlayers(now())
    end)
    -- Intro is bundled locally; no second downloaded script and no exposed intro options.
    state.Intro = playIntro()
    local panic = config.Misc.Panic.Keybind
    print('[neoperro] v' .. state.Version .. ' loaded for ' .. supported[game.PlaceId]
        .. '. ' .. tostring(panic[panic[3] == 'Mouse' and 2 or 1]) .. ' = panic/unload.')
end

local ok, reason = xpcall(start, debug.traceback)
if not ok then state:Destroy('startup-error'); error('[neoperro] ' .. tostring(reason), 0) end
return state
