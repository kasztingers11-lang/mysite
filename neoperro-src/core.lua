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

function Core.normalizeConfig(supplied)
    local result = Core.copy(supplied)
    local function alias(value, old, new)
        if value[new] == nil then value[new] = value[old] end
        value[old] = nil
    end
    local function names(value)
        if type(value) ~= 'table' then return end
        alias(value, 'Mode', 'Method')
        alias(value, 'DelayMode', 'DelayMethod')
        alias(value, 'Unlock Mode', 'Unlock Method')
        for _, child in pairs(value) do names(child) end
    end
    names(result)
    for _, name in ipairs({'Silent Aim', 'Aim Assist'}) do
        local feature = result[name]
        if type(feature) == 'table' then
            alias(feature, 'Keybind Mode', 'Activation')
            local closest = feature.Target and feature.Target.Closest
            if type(closest) == 'table' then alias(closest, 'Method', 'Selection') end
        end
    end
    local silent = result['Silent Aim']
    if type(silent) == 'table' then
        silent.EndMath = nil
        if result.Resolver == nil then result.Resolver = silent.Resolver end
        silent.Resolver = nil
        if silent.GroundShotCheck ~= nil then
            if result.Checks == nil then result.Checks = {} end
            if type(result.Checks) == 'table' and result.Checks.GroundShotCheck == nil then
                result.Checks.GroundShotCheck = {silent.GroundShotCheck, true, true}
            end
            silent.GroundShotCheck = nil
        end
        local anti = silent.AntiCurve
        if type(anti) == 'table' then
            alias(anti, 'endmath', 'Endmath')
            if anti.Method == 'endmath' then anti.Method = 'Endmath' end
        end
    end
    if type(result.Resolver) == 'table' then result.Resolver.Method = nil end
    local assist, y = result['Aim Assist'], result['Y-Axis']
    if type(assist) == 'table' then assist.Ignore = nil end
    if type(y) == 'table' then
        alias(y, 'JumpOffset', 'Offset')
        alias(y, 'AimAssist', 'Aim Assist')
    end
    if type(result.ESP) == 'table' then result.ESP.MaxDistance = nil end
    if type(result['2d-Box']) == 'table' then
        for _, style in pairs(result['2d-Box']) do
            if type(style) == 'table' then
                style.Filled, style.Transparency, style['Predicted Position'], style['Max Distance'] = nil, nil, nil, nil
            end
        end
    end
    local macro = result.Misc and result.Misc['Macro Abuse']
    if type(macro) == 'table' then alias(macro, 'Work With TB', 'Triggerbot check') end
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
        end
    end
    return result
end

function Core.whitelisted(enabled, mode, ids, id, lookup)
    if not enabled or #ids == 0 then return true end
    local present = false
    if lookup then present = lookup[id] == true
    else for _, item in ipairs(ids) do if item == id then present = true; break end end end
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

-- Exact closest pair between a forward ray and an axis-aligned box. Transform
-- into part space first; zero half-extents also support a center axis or point.
function Core.closestRayBox(origin, direction, half, newVector)
    local cuts = {0}
    for _, axis in ipairs({'X', 'Y', 'Z'}) do
        local d = direction[axis]
        if math.abs(d) > 1e-8 then
            for _, bound in ipairs({-half[axis], half[axis]}) do
                local t = (bound - origin[axis]) / d
                if t > 0 then cuts[#cuts + 1] = t end
            end
        end
    end
    table.sort(cuts)
    local bestT, bestDistance = 0, math.huge
    local function test(t)
        local distance = 0
        for _, axis in ipairs({'X', 'Y', 'Z'}) do
            local x = origin[axis] + direction[axis] * t
            local excess = math.max(0, math.abs(x) - half[axis])
            distance = distance + excess * excess
        end
        if distance < bestDistance then bestT, bestDistance = t, distance end
    end
    for i, low in ipairs(cuts) do
        local high = cuts[i + 1] or math.huge
        local middle = high < math.huge and (low + high) / 2 or low + 1
        local numerator, denominator = 0, 0
        for _, axis in ipairs({'X', 'Y', 'Z'}) do
            local x = origin[axis] + direction[axis] * middle
            local bound = x < -half[axis] and -half[axis] or (x > half[axis] and half[axis] or nil)
            if bound then
                numerator = numerator + direction[axis] * (origin[axis] - bound)
                denominator = denominator + direction[axis] * direction[axis]
            end
        end
        test(low)
        if denominator > 1e-12 then test(math.max(low, math.min(high, -numerator / denominator))) end
    end
    local p = origin + direction * bestT
    return newVector(Core.number(p.X, 0, -half.X, half.X), Core.number(p.Y, 0, -half.Y, half.Y),
        Core.number(p.Z, 0, -half.Z, half.Z)), bestT
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
    if config.DelayMethod == 'Random' then
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

-- Rotate the camera basis so its cursor ray, rather than its center ray, reaches the target.
function Core.cursorOrientation(ray, target, look, up)
    if ray.Magnitude < 1e-8 or target.Magnitude < 1e-8 then return nil end
    ray, target = ray / ray.Magnitude, target / target.Magnitude
    local cosine = math.max(-1, math.min(1, ray:Dot(target)))
    local axis = ray:Cross(target)
    local sine = axis.Magnitude
    if sine < 1e-8 then
        if cosine > 0 then return look, up end
        axis = ray:Cross(up)
        if axis.Magnitude < 1e-8 then axis = ray:Cross(look) end
        axis, sine = axis / axis.Magnitude, 0
    else axis = axis / sine end
    local function rotate(vector)
        return vector * cosine + axis:Cross(vector) * sine + axis * (axis:Dot(vector) * (1 - cosine))
    end
    return rotate(look), rotate(up)
end

-- Distance to a forward ray, independent of direction length and surface depth.
function Core.rayDistance(point, origin, direction)
    if not (Core.finiteVector(point) and Core.finiteVector(origin) and Core.finiteVector(direction)) then return nil end
    local lengthSquared = direction:Dot(direction)
    if lengthSquared < 1e-10 then return nil end
    local t = (point - origin):Dot(direction) / lengthSquared
    if t < 0 then return nil end
    local closest = origin + direction * t
    return (point - closest).Magnitude, closest, t
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
function Core.sample(history, position, now, raw)
    local last = history[#history]
    if last and now >= last.t and now - last.t < 1 / 90 then return false end
    if last then
        local dt = now - last.t
        if dt <= 0 or dt > 0.4 or (position - last.p).Magnitude > math.max(12, dt * 180) then
            for i = #history, 1, -1 do history[i] = nil end
        end
    end
    history[#history + 1] = {p = position, t = now, raw = Core.finiteVector(raw) and Core.limit(raw, 180) or nil}
    while #history > 8 or (#history > 2 and now - history[1].t > 0.18) do table.remove(history, 1) end
    return true
end

-- RTT sources overlap: use the larger estimate, never add them together.
-- No assumed projectile speed: travel is included only when supplied by a
-- verified weapon adapter. Auto deliberately does not read the manual Value.
function Core.predictionTime(settings, networkRTT, dataRTT, age, distance, speed, movementSpeed, walkSpeed)
    if not settings.Enabled then return 0, 'disabled' end
    local factor = 1
    if type(movementSpeed) == 'number' then
        -- Horizontal speed only. Gentle bounds prevent quadratic lead growth at
        -- macro speeds; ordinary walking keeps the configured baseline unchanged.
        factor = Core.number(math.sqrt(Core.number(movementSpeed, 0, 0, 180) /
            Core.number(walkSpeed, 22, 1, 180)), 1, 0.75, 1.25)
    end
    if not settings.Auto then
        local base = Core.number(settings.Value, 0.121, 0, 1)
        return base * factor, 'manual-speed', factor, base
    end
    local latency = math.max(Core.number(networkRTT, 0, 0, 1), Core.number(dataRTT, 0, 0, 1))
    local source = latency > 0 and 'latency-estimate' or 'fallback-estimate'
    if latency == 0 then latency = 0.1 end
    local travel = type(speed) == 'number' and speed > 0 and math.max(0, distance or 0) / speed or 0
    local base = Core.number(latency + Core.number(age, 0, 0, 0.05) + travel, 0.1, 0, 0.35)
    return Core.number(base * factor, 0.1, 0, 0.35), source, factor, base
end

-- Always-on motion guard. Above the game's observed fast-motion threshold,
-- limit extrapolated travel to one normal/fast-boundary stride over this horizon.
-- It never changes the selected point, direction, vertical motion or manual Value.
function Core.fastLeadTime(seconds, horizontalSpeed, walkSpeed)
    local reference = math.max(30, Core.number(walkSpeed, 22, 1, 180))
    if horizontalSpeed > reference then return seconds * reference / horizontalSpeed, true end
    return seconds, false
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

-- Compare earlier forecasts with positions that actually arrived, on this client's
-- clock. Replication interpolation can make a position fit faster than real motion.
-- Keep history as a fallback, rather than always preferring it over valid velocity.
function Core.resolveVelocity(history, raw, fitted, newVector)
    local last = history[#history]
    if last then last.fitted = fitted end
    local function resolved(value, source)
        if last then last.resolved = value end
        return value, source
    end
    if not Core.finiteVector(raw) or raw.Magnitude > 180 then return resolved(fitted, 'history-fallback') end
    local horizontalTransition = raw.X * fitted.X + raw.Z * fitted.Z <= 0
        or (raw.X * raw.X + raw.Z * raw.Z < 1 and fitted.X * fitted.X + fitted.Z * fitted.Z > 9)
    local verticalTransition = raw.Y * fitted.Y <= 0 and raw.Y ~= fitted.Y
        or (math.abs(raw.Y) < 1 and math.abs(fitted.Y) > 3)
    local tail = history[#history - 1]
    local recent = tail and last.t - tail.t >= 1 / 90 and (last.p - tail.p) / (last.t - tail.t)
    local recentXZ, recentY = false, false
    if Core.finiteVector(recent) and recent.Magnitude <= 180 then
        local rawDX, rawDZ = recent.X - raw.X, recent.Z - raw.Z
        local fitDX, fitDZ = recent.X - fitted.X, recent.Z - fitted.Z
        recentXZ = rawDX * rawDX + rawDZ * rawDZ < fitDX * fitDX + fitDZ * fitDZ
        recentY = math.abs(recent.Y - raw.Y) < math.abs(recent.Y - fitted.Y)
    end
    local horizontalTolerance = math.max(3, math.sqrt(raw.X * raw.X + raw.Z * raw.Z) * 0.25)
    local verticalTolerance = math.max(3, math.abs(raw.Y) * 0.25)
    local rawXZ, fitXZ, rawY, fitY, count = 0, 0, 0, 0, 0
    for _, sample in ipairs(history) do
        local dt = last.t - sample.t
        -- A short observed segment can establish an acute turn or braking before
        -- the full fit catches up. A changed raw value alone is not that evidence.
        if dt >= 0 and dt <= 0.05 and Core.finiteVector(sample.raw) then
            local dx, dz = raw.X - sample.raw.X, raw.Z - sample.raw.Z
            if recentXZ and dx * dx + dz * dz > horizontalTolerance * horizontalTolerance then horizontalTransition = true end
            if recentY and math.abs(raw.Y - sample.raw.Y) > verticalTolerance then verticalTransition = true end
        end
        if dt >= 0.035 and sample.raw and sample.fitted then
            local a = last.p - (sample.p + sample.raw * dt)
            local b = last.p - (sample.p + sample.fitted * dt)
            rawXZ, fitXZ = rawXZ + a.X * a.X + a.Z * a.Z, fitXZ + b.X * b.X + b.Z * b.Z
            rawY, fitY, count = rawY + a.Y * a.Y, fitY + b.Y * b.Y, count + 1
        end
    end
    local horizontal = not horizontalTransition and count >= 2 and fitXZ < rawXZ and fitted or raw
    local vertical = not verticalTransition and count >= 2 and fitY < rawY and fitted or raw
    if last then
        last.horizontalSource = horizontal == fitted and 'history-validated' or horizontalTransition and 'raw-transition' or 'raw-validated'
        last.verticalSource = vertical == fitted and 'history-validated' or verticalTransition and 'raw-transition' or 'raw-validated'
    end
    if horizontal.X == raw.X and horizontal.Z == raw.Z and vertical.Y == raw.Y then
        return resolved(raw, (horizontalTransition or verticalTransition) and 'raw-transition' or 'raw-validated')
    end
    if horizontal.X == fitted.X and horizontal.Z == fitted.Z and vertical.Y == fitted.Y then return resolved(fitted, 'history-validated') end
    return resolved(newVector(horizontal.X, vertical.Y, horizontal.Z), 'split-validated')
end

-- A persistent replicated-velocity mismatch needs coherent observed movement.
-- A newly changed velocity remains immediate while history catches up.
function Core.trueVelocity(history, raw, fitted, fallback, source, newVector)
    if #history < 4 or not Core.finiteVector(raw) or not Core.finiteVector(fitted) then return fallback, source end
    local last, first = history[#history], history[1]
    local span = last.t - first.t
    if span < 0.05 or span > 0.2 then return fallback, source end
    local fitXZ = math.sqrt(fitted.X * fitted.X + fitted.Z * fitted.Z)
    local rawXZ = math.sqrt(raw.X * raw.X + raw.Z * raw.Z)
    local xzStable, yStable, xzError, yError = last.t, last.t, 0, 0
    local xzTail, yTail, recent
    for i = #history, 1, -1 do
        local sample = history[i]
        local dt = last.t - sample.t
        local error = last.p - sample.p - fitted * dt
        xzError = math.max(xzError, math.sqrt(error.X * error.X + error.Z * error.Z))
        yError = math.max(yError, math.abs(error.Y))
        if not recent and dt >= 0.035 then recent = (last.p - sample.p) / dt end
        if not sample.raw or not Core.finiteVector(sample.raw) then
            xzTail, yTail = true, true
        else
            local dx, dz = sample.raw.X - raw.X, sample.raw.Z - raw.Z
            if dx * dx + dz * dz > math.max(1, rawXZ * 0.1) ^ 2 then xzTail = true end
            if math.abs(sample.raw.Y - raw.Y) > math.max(2, math.abs(raw.Y) * 0.1) then yTail = true end
        end
        if not xzTail then xzStable = sample.t end
        if not yTail then yStable = sample.t end
    end
    if not recent then return fallback, source end
    local dx, dz = recent.X - fitted.X, recent.Z - fitted.Z
    local mismatchX, mismatchZ = raw.X - fitted.X, raw.Z - fitted.Z
    local useXZ = fitXZ >= 1 and last.t - xzStable >= 0.05
        and xzError <= math.max(0.05, fitXZ * span * 0.15)
        and dx * dx + dz * dz <= math.max(3, fitXZ * 0.25) ^ 2
        and mismatchX * mismatchX + mismatchZ * mismatchZ >= math.max(3, fitXZ * 0.25) ^ 2
    local useY = math.abs(fitted.Y) >= 1 and last.t - yStable >= 0.05
        and yError <= math.max(0.05, math.abs(fitted.Y) * span * 0.15)
        and math.abs(recent.Y - fitted.Y) <= math.max(3, math.abs(fitted.Y) * 0.25)
        and math.abs(raw.Y - fitted.Y) >= math.max(3, math.abs(fitted.Y) * 0.25)
    if not useXZ and not useY then return fallback, source end
    return Core.limit(newVector(useXZ and fitted.X or fallback.X, useY and fitted.Y or fallback.Y,
        useXZ and fitted.Z or fallback.Z), 180), 'true-velocity'
end

-- Fit only measured replicated velocities. A stable slope is useful at a jump
-- apex; sparse updates, a one-frame impulse and noisy slopes are not gravity.
function Core.motion(history, raw, time)
    local model = {VerticalAcceleration = 0, VerticalConfidence = 0, TurnRate = 0}
    if #history < 4 or not Core.finiteVector(raw) or raw.Magnitude > 180 then return model end
    local last, first = history[#history], history[1]
    local span = last.t - first.t
    if span < 0.05 or span > 0.2 then return model end
    local sampleAge = type(time) == 'number' and time - last.t or 0
    if sampleAge ~= sampleAge or sampleAge < 0 or sampleAge > 0.05 then return model end
    model.SampleAge = sampleAge
    local count, timeMean, meanY, changes = 0, 0, 0, 0
    local prior
    for _, sample in ipairs(history) do
        if not sample.raw then return model end
        if prior and math.abs(sample.raw.Y - prior.Y) > 0.25 then changes = changes + 1 end
        prior = sample.raw
        count, timeMean, meanY = count + 1, timeMean + sample.t, meanY + sample.raw.Y
    end
    timeMean, meanY = timeMean / count, meanY / count
    local numerator, denominator = 0, 0
    for _, sample in ipairs(history) do
        local dt = sample.t - timeMean
        numerator, denominator = numerator + dt * (sample.raw.Y - meanY), denominator + dt * dt
    end
    if denominator < 1e-7 then return model end
    local acceleration, errorSum = numerator / denominator, 0
    for _, sample in ipairs(history) do
        local error = sample.raw.Y - (meanY + acceleration * (sample.t - timeMean))
        errorSum = errorSum + error * error
    end
    local tolerance = math.max(2.5, math.abs(acceleration) * span * 0.2)
    local rms = math.sqrt(errorSum / count)
    -- A live velocity can be either held at the latest sampled tick or updated
    -- within this short sampling interval. Validate that bounded range instead
    -- of making confidence flicker with render phase. Never add this age to lead.
    local atSample = meanY + acceleration * (last.t - timeMean)
    local atRead = atSample + acceleration * sampleAge
    local endpointError = math.max(0, math.min(atSample, atRead) - raw.Y, raw.Y - math.max(atSample, atRead))
    if changes >= 3 and math.abs(acceleration) >= 5 and math.abs(acceleration) <= 600 and
        rms < tolerance and endpointError < tolerance then
        model.VerticalAcceleration = acceleration
        model.VerticalConfidence = 1 - math.max(rms, endpointError) / tolerance
    end
    local speed = math.sqrt(raw.X * raw.X + raw.Z * raw.Z)
    if speed >= 3 then
        for i = #history - 1, 1, -1 do
            local sample = history[i]
            local dt = last.t - sample.t
            if dt >= 0.05 then
                local old = sample.raw
                local oldSpeed = math.sqrt(old.X * old.X + old.Z * old.Z)
                if oldSpeed >= 3 then
                    local dot = Core.number((raw.X * old.X + raw.Z * old.Z) / (speed * oldSpeed), 1, -1, 1)
                    model.TurnRate = math.acos(dot) / dt
                end
                break
            end
        end
    end
    last.turnRate = model.TurnRate
    model.MeasuredTurnRate = model.TurnRate
    local straightError, turnError, forecasts = 0, 0, 0
    for _, sample in ipairs(history) do
        local dt = last.t - sample.t
        local velocity = sample.resolved or sample.raw
        if dt >= 0.035 and sample.turnRate and sample.turnRate > 0 and velocity then
            local time = Core.motionTime(dt, sample.turnRate)
            local straight, turned = last.p - sample.p - velocity * dt, last.p - sample.p - velocity * time
            straightError = straightError + straight.X * straight.X + straight.Z * straight.Z
            turnError = turnError + turned.X * turned.X + turned.Z * turned.Z
            forecasts = forecasts + 1
        end
    end
    model.TurnValidated = forecasts >= 2 and turnError < straightError
    if not model.TurnValidated then model.TurnRate = 0 end
    return model
end

function Core.motionTime(seconds, turnRate)
    local angle = math.min(math.pi / 2, seconds * Core.number(turnRate, 0, 0, 100))
    if angle < 1e-5 then return seconds end
    -- The forward component of a constant-rate turn is sin(angle)/rate.
    return seconds * math.sin(angle) / angle
end

function Core.curveLimit(value, fallback)
    if value == math.huge then return math.huge end
    return Core.number(value, fallback, 0.000000001)
end

function Core.verticalLead(vertical, rawY, seconds, height, grounded, model, supportLead)
    if grounded then
        local lead = Core.number(supportLead, 0, -height, height * 2)
        return lead, 0, lead ~= 0 and 'support-follow' or 'grounded'
    end
    local confidence = model and model.VerticalConfidence or 0
    local correction, mode = 0, 'resolved'
    if confidence >= 0.5 then
        vertical = rawY
        local acceleration = model.VerticalAcceleration * confidence
        local duration = seconds
        mode = 'measured-acceleration'
        -- Remote landing interpolation can look like positive acceleration while
        -- still falling. Stop at rest; a new ascent needs observed upward speed.
        if rawY <= 0 and acceleration > 0 then
            duration = math.min(seconds, -rawY / acceleration)
            mode = 'braking-stop'
        end
        correction = vertical * duration + 0.5 * acceleration * duration * duration - vertical * seconds
    end
    return Core.number(vertical * seconds + correction, 0, -height, height * 2), correction, mode
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
