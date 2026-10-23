-- Shared math/state helpers. No executor or Roblox services are used here.
local Core = {}

function Core.number(value, fallback, low, high)
    if type(value) ~= 'number' or value ~= value or math.abs(value) == math.huge then value = fallback end
    return math.max(low or -math.huge, math.min(high or math.huge, value))
end

function Core.copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = Core.copy(v) end
    return result
end

function Core.merge(defaults, supplied)
    local result = Core.copy(defaults)
    if type(supplied) ~= 'table' then return result end
    for k, v in pairs(supplied) do
        if type(v) == 'table' and type(result[k]) == 'table' and #result[k] == 0 and #v == 0 then
            result[k] = Core.merge(result[k], v)
        else
            result[k] = Core.copy(v)
        end
    end
    return result
end

function Core.equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k, v in pairs(a) do if not Core.equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

function Core.validate(defaults, supplied, path)
    path = path or 'neoperro'
    for key, default in pairs(defaults) do
        local value = supplied[key]
        local label = path .. '.' .. tostring(key)
        assert(type(value) == type(default), label .. ' must be a ' .. type(default))
        if type(default) == 'table' then Core.validate(default, value, label) end
    end
end

function Core.alpha(strength, dt)
    strength = Core.number(strength, 0.0068, 0, 1)
    return 1 - (1 - strength) ^ (math.max(0, dt) * 60)
end

function Core.fov(dx, dy, mode, width, height, radius)
    if mode == '2d-Circle' then return dx * dx + dy * dy <= radius * radius end
    return math.abs(dx) <= width / 2 and math.abs(dy) <= height / 2
end

function Core.ids(list)
    local result, seen = {}, {}
    if type(list) ~= 'table' then return result end
    for _, id in ipairs(list) do
        if type(id) == 'number' and id > 0 and id < math.huge and id % 1 == 0 and not seen[id] then
            result[#result + 1], seen[id] = id, true
            if #result == 4 then break end
        end
    end
    return result
end

function Core.whitelisted(enabled, mode, ids, id)
    if not enabled then return true end
    local present = false
    for _, item in ipairs(ids) do if item == id then present = true; break end end
    if mode == 'Target' then return present end
    return not present
end

function Core.weapon(name)
    local token = (name:match('%[(.-)%]') or name):lower():gsub('[%s%-%_]', '')
    local aliases = {
        rev = 'Revolver', revolver = 'Revolver', db = 'Double-Barrel SG',
        doublebarrel = 'Double-Barrel SG', doublebarrelsg = 'Double-Barrel SG',
        tacticalsg = 'TacticalShotgun', tacticalshotgun = 'TacticalShotgun',
        sg = 'Shotgun', shotgun = 'Shotgun', usp = 'Usp', silencer = 'Silencer', smg = 'SMG',
    }
    return aliases[token]
end

function Core.profile(spec, weapon, distance)
    if not spec.Enabled or not weapon or type(spec[weapon]) ~= 'table' then return nil end
    local ranges = spec.Ranges or {}
    local close = Core.number(ranges.Close, 15, 0)
    local medium = Core.number(ranges.Medium, 30, close)
    local far = Core.number(ranges.Far, 90, medium)
    local key
    if distance <= close then key = 'Close'
    elseif distance <= medium then key = 'Medium'
    elseif distance <= far then key = 'Far' end
    return key and spec[weapon][key] or nil, key
end

-- Entry distance into an oriented box after transforming the ray to its local frame.
function Core.rayBox(origin, direction, half)
    local near, far = 0, math.huge
    for _, axis in ipairs({'X', 'Y', 'Z'}) do
        local o, d, h = origin[axis], direction[axis], half[axis]
        if math.abs(d) < 1e-8 then
            if math.abs(o) > h then return nil end
        else
            local a, b = (-h - o) / d, (h - o) / d
            if a > b then a, b = b, a end
            near, far = math.max(near, a), math.min(far, b)
            if near > far then return nil end
        end
    end
    return near
end

function Core.input(binding, key, mouse)
    if type(binding) ~= 'table' then return false end
    if binding[3] == 'Mouse' then return mouse == binding[2] end
    return type(binding[1]) == 'string' and string.lower(key or '') == string.lower(binding[1])
end

function Core.delay(config, distance, random)
    if config.SmartDelay then
        return Core.number(config.Delay, 0.1, 0.01, 10) + math.min(distance / 2000, 0.15)
    end
    if config.DelayMode == 'Random' then
        local range = type(config.RandomDelay) == 'table' and config.RandomDelay or {}
        local low = Core.number(range[1], 0.1, 0.01, 10)
        local high = Core.number(range[2], 0.12, 0.01, 10)
        if low > high then low, high = high, low end
        return low + (high - low) * random
    end
    return Core.number(config.Delay, 0.1, 0.01, 10)
end

function Core.finiteVector(v)
    return v and v.X == v.X and v.Y == v.Y and v.Z == v.Z
        and math.abs(v.X) < 1e8 and math.abs(v.Y) < 1e8 and math.abs(v.Z) < 1e8
end

-- Rotate a native pellet ray toward local mouse aim without merging endpoints.
-- Native length, pairwise spread and all Beam styling remain independent.
function Core.redirectTracer(origin, endpoint, serverPoint, mousePoint, newVector)
    if not (Core.finiteVector(origin) and Core.finiteVector(endpoint)
        and Core.finiteVector(serverPoint) and Core.finiteVector(mousePoint)) then return nil end
    local from, toward, ray = serverPoint - origin, mousePoint - origin, endpoint - origin
    if from.Magnitude < 1e-5 or toward.Magnitude < 1e-5 or ray.Magnitude < 1e-5 then return nil end
    local a, b = from / from.Magnitude, toward / toward.Magnitude
    local dot = math.max(-1, math.min(1, a:Dot(b)))
    if dot > 1 - 1e-8 then return endpoint end
    local rotated
    if dot < -1 + 1e-6 then
        -- Use one shared rotation plane for all pellets, including the center ray.
        if not newVector then return nil end
        local basis = math.abs(a.X) < 0.9 and newVector(1, 0, 0) or newVector(0, 1, 0)
        local axis = a:Cross(basis)
        axis = axis / axis.Magnitude
        rotated = axis * (2 * axis:Dot(ray)) - ray
    else
        local cross = a:Cross(b)
        local first = cross:Cross(ray)
        rotated = ray + first + cross:Cross(first) / (1 + dot)
    end
    return origin + rotated
end

function Core.limit(v, maximum)
    local magnitude = v.Magnitude
    if magnitude > maximum and magnitude > 0 then return v * (maximum / magnitude) end
    return v
end

-- Bounded timestamp history; teleport spikes reset the fit instead of poisoning it.
function Core.sample(history, position, now)
    local last = history[#history]
    if last and now >= last.t and now - last.t < 1 / 90 then return false end
    if last then
        local dt = now - last.t
        if dt <= 0 or dt > 0.4 or (position - last.p).Magnitude > math.max(12, dt * 180) then
            for i = #history, 1, -1 do history[i] = nil end
        end
    end
    history[#history + 1] = {p = position, t = now}
    while #history > 8 or (#history > 2 and now - history[1].t > 0.18) do table.remove(history, 1) end
    return true
end

-- RTT sources overlap: use the larger estimate, never add them together.
-- No assumed projectile speed: travel is included only when supplied by a
-- verified weapon adapter. Auto deliberately does not read the manual Value.
function Core.predictionTime(settings, networkRTT, dataRTT, age, distance, speed)
    if not settings.Enabled then return 0, 'disabled' end
    if not settings.Auto then return Core.number(settings.Value, 0.121, 0, 1), 'manual' end
    local latency = math.max(Core.number(networkRTT, 0, 0, 1), Core.number(dataRTT, 0, 0, 1))
    local source = latency > 0 and 'latency-estimate' or 'fallback-estimate'
    if latency == 0 then latency = 0.1 end
    local travel = type(speed) == 'number' and speed > 0 and math.max(0, distance or 0) / speed or 0
    return Core.number(latency + Core.number(age, 0, 0, 0.05) + travel, 0.1, 0, 0.35), source
end

-- A conservative vertical lead, without inventing gravity from FloorMaterial.
-- FloorMaterial is not replicated reliably for remote humanoids.
function Core.autoVertical(sampled, raw)
    -- A position-history fit describes the recent interval, so it can still rise
    -- after the replicated velocity turns downward at the jump apex (and vice versa).
    -- Use the current direction only when it is finite and outside resting noise.
    if type(raw) == 'number' and raw == raw and math.abs(raw) > 3 and math.abs(raw) <= 180
        and sampled * raw < 0 then return raw, 'raw-direction-change' end
    return sampled, 'resolved'
end

function Core.autoY(vertical, seconds, height, grounded)
    if grounded then return 0 end
    return Core.number(vertical * seconds, 0, -height, height * 2)
end

function Core.velocity(history, fallback, zero)
    if #history < 3 then return Core.limit(fallback, 180) end
    local meanTime, meanPosition = 0, zero
    for _, sample in ipairs(history) do
        meanTime = meanTime + sample.t
        meanPosition = meanPosition + sample.p
    end
    meanTime, meanPosition = meanTime / #history, meanPosition / #history
    local numerator, denominator = zero, 0
    for _, sample in ipairs(history) do
        local dt = sample.t - meanTime
        numerator = numerator + (sample.p - meanPosition) * dt
        denominator = denominator + dt * dt
    end
    if denominator < 1e-7 then return zero end
    return Core.limit(numerator / denominator, 180)
end

-- State changes in the supplied config win; otherwise keep the running toggle.
function Core.restoreToggle(incoming, oldInitial, oldValue)
    if incoming == oldInitial and type(oldValue) == 'boolean' then return oldValue end
    return incoming == true
end

-- Mirrors the observed game shot handler's Head XZ-speed condition.
function Core.macroActive(velocity)
    return Core.finiteVector(velocity) and velocity.X * velocity.X + velocity.Z * velocity.Z > 30 * 30
end

-- Integer-like viewport geometry in world units, independent of limb animation.
function Core.projectedBox(x, y, depth, width, height, focal)
    if depth <= 0.1 then return nil end
    local w, h = width * focal / depth, height * focal / depth
    return x - w / 2, y - h / 2, w, h
end

return Core
