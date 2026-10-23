-- Internal pose measurements. No user configuration or animation-ID guesses.
local Posture = {}

function Posture.verticalSize(part)
    local cf, size = part.CFrame, part.Size
    local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
    if not right or not up or not look then return size.Y end
    return math.abs(right.Y) * size.X + math.abs(up.Y) * size.Y + math.abs(look.Y) * size.Z
end

function Posture.kind(name, emoteFolder)
    local token = tostring(name):lower():gsub('[^%a]', '')
    if token:find('crouch', 1, true) then return 'Crouched' end
    if token:match('^lay') or token:match('^lying') or token:match('^prone')
        or token:match('^crawl') or token:match('^sleep') then return 'Prone' end
    if token:match('^sit') then return 'Seated' end
    if emoteFolder or token:find('emote', 1, true) or token:match('^dance') then return 'Emote' end
    return nil
end

local function animationId(animation)
    return animation and tostring(animation.AnimationId or ''):match('%d+')
end

function Posture.catalog(folder)
    local result, visited = {}, 0
    if not folder then return result end
    local function add(animation, emote)
        visited = visited + 1
        if visited > 128 or not animation:IsA('Animation') then return end
        local kind, id = Posture.kind(animation.Name, emote), animationId(animation)
        if kind and id then result[id] = kind end
    end
    for _, child in ipairs(folder:GetChildren()) do
        if visited >= 128 then break end
        if child:IsA('Animation') then add(child, false)
        elseif child.Name:lower() == 'dances' or child.Name:lower() == 'emotes' then
            for _, animation in ipairs(child:GetChildren()) do add(animation, true); if visited >= 128 then break end end
        end
    end
    return result
end

local rank = {Emote=1, Seated=2, Crouched=3, Prone=4}

function Posture.sample(record, time, catalog, bodyPart)
    local old = record.pose
    if old and time < old.NextSample then return old, false, false end
    local root, humanoid, character = record.root, record.humanoid, record.character
    if not root or not humanoid or not character then return nil, false, false end
    local animationKind = old and old.AnimationKind
    local nextAnimation = old and old.NextAnimationSample or 0
    if time >= nextAnimation then
        animationKind, nextAnimation = nil, time + 0.2
        local animator = humanoid:FindFirstChildOfClass('Animator')
        if animator then
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok then
                for i, track in ipairs(tracks) do
                    if i > 16 then break end
                    if track.IsPlaying and (type(track.WeightCurrent) ~= 'number' or track.WeightCurrent > 0.05) then
                        local animation = track.Animation
                        local kind = catalog[animationId(animation)] or Posture.kind(animation and animation.Name or track.Name, false)
                        if kind and (not animationKind or rank[kind] > rank[animationKind]) then animationKind = kind end
                    end
                end
            end
        end
    end
    local head = character:FindFirstChild('Head')
    local torso = character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso') or root
    local anchor = torso.Position - root.Position
    local kind, source = animationKind or 'Upright', animationKind and 'game-animation' or 'rig-geometry'
    local up = root.CFrame.UpVector
    if not animationKind then
        if humanoid.PlatformStand then kind = 'Ragdoll'
        elseif humanoid.Sit then kind = 'Seated'
        elseif anchor.Magnitude > torso.Size.Magnitude * 2 then kind = 'Detached'
        elseif up and math.abs(up.Y) < 0.4 then kind = 'Prone'
        elseif head then
            local axis = head.Position - torso.Position
            if axis.Magnitude > head.Size.Y * 0.5 and math.abs(axis.Y) / axis.Magnitude < 0.4 then kind = 'Prone'
            elseif head.Position.Y - root.Position.Y < head.Size.Y * 0.25 then kind = 'Crouched' end
        end
    end
    local supportHeight
    if kind == 'Prone' or kind == 'Crouched' or kind == 'Seated' or kind == 'Emote' then
        local bottom = math.huge
        for _, part in ipairs(character:GetChildren()) do
            if bodyPart(part, character) then bottom = math.min(bottom, part.Position.Y - Posture.verticalSize(part) * 0.5) end
        end
        if bottom < root.Position.Y then supportHeight = root.Position.Y - bottom end
    end
    local changed = old ~= nil and (old.Kind ~= kind or (anchor - old.Anchor).Magnitude > torso.Size.Magnitude * 0.3)
    return {Kind=kind, Source=source, Anchor=anchor, SupportHeight=supportHeight,
        AnimationKind=animationKind, NextAnimationSample=nextAnimation, NextSample=time + 0.05}, changed, true
end

return Posture
