-- neoperro
-- Edit this table and execute neoperro.lua again to apply it.
-- Keybind format: {keyboard key, mouse button, active device}.
-- Use 'Keyboard' or 'Mouse' as the third value. Only that device is active.
-- Shared keybinds are allowed. The runtime will dispatch each enabled matching action.
-- Panic takes priority over other actions sharing its key.
-- Re-execution will replace the old instance and retain valid targets, toggles and whitelist state.
-- Supported place IDs and intro behavior belong inside the script, not this table.

getgenv()['neoperro'] = {

    -- Keep aim redirection inside firing windows; idle MOUSE updates pass through. No concealment guarantee.
    ['Anti-AimViewer'] = {
        ['Enabled'] = true;
    };

    -- Vertical compensation. Auto chooses the adjustment; Custom uses JumpOffset.
    ['Y-Axis'] = {
        ['Enabled'] = false; -- Enable vertical compensation.
        ['Mode'] = 'Auto'; -- Auto ignores JumpOffset; Custom uses it without automatic adjustment.
        ['JumpOffset'] = 1.0; -- Custom only: 1 = unchanged, below 1 = less upward lead, above 1 = more.
        ['SilentAim'] = true; -- Apply the Y-Axis section to Silent Aim.
        ['AimAssist'] = false; -- Apply the Y-Axis section to Aim Assist.
    };

    -- Order for every row: {Silent Aim, Aim Assist, Triggerbot}.
    ['Checks'] = {
        ['Dead']       = {true, true, true}; -- Reject dead targets.
        ['Knocked']    = {true, true, true}; -- Reject knocked/incapacitated targets.
        ['Wall']       = {true, true, true}; -- Require a clear visibility check.
        ['ForceField'] = {true, true, false}; -- Reject targets with spawn protection.
        ['Crew']       = {false, false, false}; -- Reject players in your crew.
        ['Tool']       = {false, true, true}; -- Require an equipped weapon.
    };

    -- Calculates the aim point used by the firing integration.
    ['Silent Aim'] = {
        ['Enabled'] = true;
        ['Mode'] = 'Auto'; -- Auto = nearest eligible to cursor; Target = select with a keybind.
        ['Ignore'] = false; -- Ignore circle/player-box bounds; other checks still apply.

        ['Target'] = {
            ['BasePart'] = 'UpperTorso'; -- Used when Closest is disabled; R6 falls back to Torso.
            ['Closest'] = {
                ['Enabled'] = true; -- Choose the body part nearest your crosshair.
                ['Raycast'] = false; -- Exact cursor surface hit before prediction; bypasses Reduce and Sharpness.
                ['Method'] = 'Part'; -- Part = nearest part center; Point = nearest point in that part.
                ['Axis'] = 'Center'; -- Point movement within the part: Center = Y only; All = XYZ.
                ['Sharpness'] = 0.65; -- Point response: 1 = immediate, 0.01 = slow.
                ['Reduce'] = {
                    ['Center'] = 0.7; -- Keep this far from Y edges: 0 = edges, 1 = center.
                    ['All'] = 0.7; -- Same reduction on all axes when Axis is All.
                };
            };
        };

        ['Fov'] = {
            ['Mode'] = '2d-Box'; -- 2d-Box = box on each player; 2d-Circle = circle around crosshair.

            ['2d-Circle'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = 50; -- Circle radius in pixels.
                ['Color'] = {255, 255, 255}; -- RGB, 0-255 per channel.
            };

        };

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'P', 'MouseButton2', 'Keyboard'};
        };

        -- Target selection controls, used when Mode is Target.
        ['Keybind Mode'] = {
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Unlock Mode'] = 'Repeat'; -- Repeat = select again on each press; clear if no eligible target.
            ['Keybind'] = {'T', 'MouseButton2', 'Keyboard'};
        };

        -- Barrel alignment checks. An unsafe angle falls back to your manual aim.
        ['AntiCurve'] = {
            ['Enabled'] = false;
            ['Mode'] = '3d-angles'; -- 3d-angles / endmath; selects one filter.

            ['3d-angles'] = {
                ['MaxAngle'] = 4; -- Maximum angle from camera direction to muzzle-to-target direction.
            };

            ['endmath'] = {
                ['Radius'] = 120; -- Maximum prediction displacement in studs.
                ['MaxAngle'] = 4; -- Maximum camera/barrel parallax in degrees.
                ['WallCheck'] = true; -- Recheck the ray from the actual muzzle to the final point.
            };
        };
    };

    -- Moves the camera toward the chosen aim point.
    ['Aim Assist'] = {
        ['Enabled'] = true;
        ['Mode'] = 'Auto'; -- Auto searches while its key is held; Target uses a selected player.
        ['Ignore'] = false; -- Ignore circle/player-box bounds; other checks still apply.

        ['Follow'] = 'Camera'; -- Camera tracking.
        ['Smoothness'] = 0.0068; -- Strength referenced to 60 FPS; runtime will compensate for frame time.

        ['Target'] = {
            ['BasePart'] = 'UpperTorso'; -- Used when Closest is disabled; R6 falls back to Torso.
            ['Closest'] = {
                ['Enabled'] = true; -- Choose the body part nearest your crosshair.
                ['Raycast'] = false; -- Exact cursor surface hit before prediction; bypasses Reduce and Sharpness.
                ['Method'] = 'Part'; -- Part = nearest part center; Point = nearest point in that part.
                ['Axis'] = 'Center'; -- Point movement within the part: Center = Y only; All = XYZ.
                ['Sharpness'] = 0.65; -- Point response: 1 = immediate, 0.01 = slow.
                ['Reduce'] = {
                    ['Center'] = 0.45; -- Keep this far from Y edges: 0 = edges, 1 = center.
                    ['All'] = 0.45; -- Same reduction on all axes when Axis is All.
                };
            };
        };

        ['Fov'] = {
            ['Mode'] = '2d-Box'; -- 2d-Box = box on each player; 2d-Circle = circle around crosshair.

            ['2d-Circle'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = 100; -- Circle radius in pixels.
                ['Color'] = {255, 255, 255}; -- RGB, 0-255 per channel.
            };

        };

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'M', 'MouseButton2', 'Keyboard'};
        };

        -- In Auto, Holding makes this the search input. In Target, this selects a player.
        ['Keybind Mode'] = {
            ['Holding'] = true; -- Auto: hold to search continuously. Target: hold the selected target.
            ['Unlock Mode'] = 'Normal'; -- Normal = lock on one press, unlock on the next.
            ['Keybind'] = {'Q', 'MouseButton2', 'Keyboard'};
        };
    };

    -- Velocity lead in seconds: 0.128 = 128 ms. Do not multiply it by ping again.
    ['Prediction'] = {
        ['SilentAim'] = 0.128;
        ['AimAssist'] = 0.121;
        ['Triggerbot'] = 0.132;
    };

    -- Shared final-point calculations and optional debug display.
    ['EndMath'] = {
        ['VelocityHistory'] = true; -- Fit velocity to recent position samples; teleport jumps reset the history.
        ['WallCheck'] = true; -- Check visibility of the final calculated point.
        ['Visualizer'] = false; -- Display the final aim point for tuning.
    };

    -- Up to four assigned players. Store UserIds, not display names.
    ['Whitelist'] = {
        ['Enabled'] = false;
        ['Mode'] = 'Friend'; -- Friend = ignore assigned players; Target = only assigned players.
        ['Players'] = {}; -- Up to four numeric UserIds.

        -- Add/remove the eligible player nearest your cursor.
        ['AssignKey'] = {
            ['Keybind'] = {'R', 'MouseButton2', 'Keyboard'};
        };
    };

    -- Recheck the target before firing; do not stack pending shots.
    ['Triggerbot'] = {
        ['Enabled'] = true;
        ['TargetOnly'] = false; -- When true, require the Silent Aim target.

        ['Delay'] = 0.1; -- Fixed delay in seconds when DelayMode is Normal.
        ['RandomDelay'] = {0.1, 0.12}; -- Minimum and maximum delay in seconds.
        ['SmartDelay'] = false; -- Distance-based timing; overrides DelayMode when enabled.
        ['DelayMode'] = 'Random'; -- Normal / Random. Delays are alternatives, not added together.

        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'V', 'MouseButton2', 'Keyboard'}; -- Arm/disarm Triggerbot.
        };
        ['Activation'] = {
            ['Enabled'] = true; -- Require this activation input in addition to Enabled.
            ['Holding'] = true;
            ['Keybind'] = {'Q', 'MouseButton2', 'Mouse'}; -- Hold RMB; change Mouse to Keyboard for Q.
        };
        ['Fov'] = {
            ['Enabled'] = false; -- False = cursor must hit the actual character. True = use a selection shape.
            ['Mode'] = '2d-Box'; -- Player-centered box or crosshair-centered circle.
            ['2d-Circle'] = {['Visible'] = false; ['Size'] = 50; ['Color'] = {255, 255, 255}};
        };
    };

    -- Player boxes and names. Appearance is in the 2d-Box section below.
    ['ESP'] = {
        ['Enabled'] = true;
        ['VisibleCheck'] = false; -- Hide ESP for obstructed players.
        ['Names'] = true; -- Also respects each box's Name setting.
        ['DeadCheck'] = true; -- Hide dead bodies; an enabled Silent Aim Dead check also hides them.
        ['MaxDistance'] = 5050; -- Maximum ESP distance in studs.

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'Z', 'MouseButton2', 'Keyboard'};
        };

    };

    -- Boxes follow each player's root without resizing for walking/limb animations.
    -- Width/Height are studs; their screen size still changes with distance.
    ['2d-Box'] = {
        ['Silent Aim'] = {
            ['Visible'] = true;
            ['Predicted Position'] = false;
            ['Name'] = {true, 'DisplayName'}; -- DisplayName / Name / UserId.
            ['Color'] = {['Box'] = {{255, 255, 255}, {0, 0, 0}}}; -- Foreground, outline.
            ['Size'] = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance'] = 5050;
            ['Filled'] = false;
            ['Transparency'] = 1; -- 1 = opaque, 0 = invisible.
        };
        ['Aim Assist'] = {
            ['Visible'] = false;
            ['Predicted Position'] = false;
            ['Name'] = {false, 'DisplayName'};
            ['Color'] = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size'] = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance'] = 5050;
            ['Filled'] = false;
            ['Transparency'] = 1;
        };
        ['Triggerbot'] = {
            ['Visible'] = false;
            ['Predicted Position'] = false;
            ['Name'] = {false, 'DisplayName'};
            ['Color'] = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size'] = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance'] = 5050;
            ['Filled'] = false;
            ['Transparency'] = 1;
        };
    };

    -- Weapon profiles change box dimensions only; prediction uses the main Prediction section.
    -- BoxSize = projected target-box width/height in studs, not cursor FOV pixels.
    -- Unlisted weapons and targets beyond Far use the general settings.
    ['Gun Specifications'] = {
        ['Enabled'] = false;

        ['Ranges'] = {
            ['Close'] = 15; -- Close: distance up to 15 studs.
            ['Medium'] = 30; -- Medium: over Close, up to 30 studs.
            ['Far'] = 90; -- Far: over Medium, up to 90 studs.
        };

        ['Revolver'] = {
            ['Close'] = {['BoxSize'] = {5, 6}};
            ['Medium'] = {['BoxSize'] = {5, 6}};
            ['Far'] = {['BoxSize'] = {4, 5}};
        };

        ['Double-Barrel SG'] = {
            ['Close'] = {['BoxSize'] = {7, 6}};
            ['Medium'] = {['BoxSize'] = {6, 5}};
            ['Far'] = {['BoxSize'] = {5, 5}};
        };

        ['TacticalShotgun'] = {
            ['Close'] = {['BoxSize'] = {7, 7}};
            ['Medium'] = {['BoxSize'] = {6, 6}};
            ['Far'] = {['BoxSize'] = {5, 5}};
        };

        ['Shotgun'] = {
            ['Close'] = {['BoxSize'] = {7, 7}};
            ['Medium'] = {['BoxSize'] = {6, 6}};
            ['Far'] = {['BoxSize'] = {5, 5}};
        };

        ['Usp'] = {
            ['Close'] = {['BoxSize'] = {5, 6}};
            ['Medium'] = {['BoxSize'] = {5, 6}};
            ['Far'] = {['BoxSize'] = {4, 5}};
        };
    };

    -- Local tracer visuals. Weapon handling stays inside the script.
    -- Uses the selected aim point when available, otherwise your normal mouse aim.
    ['Client Bullets'] = {
        ['Enabled'] = true; -- Always active by default; no separate keybind or target requirement.
    };

    -- Extra controls. No intro settings are exposed here.
    ['Misc'] = {
        ['AntiAfk'] = true; -- Idle prevention where supported.
        ['AntiFling'] = true; -- Mitigate fling-like movement while preserving normal movement.

        -- After weapon activation: unequip -> hold Ctrl -> re-equip -> release Ctrl.
        -- One cycle at a time; cancellation releases only the script's simulated input.
        ['Macro Abuse'] = {
            ['Enabled'] = false;
            ['Work With TB'] = false; -- Also run after Triggerbot fires.
            ['Check Ammo'] = true; -- Require an observed Ammo decrease before starting.
            ['Macro Check'] = true; -- Require movement plus repeated I/O or alternating wheel inputs.
        };

        -- Unload the runtime, remove visuals, and release simulated inputs.
        ['Panic'] = {
            ['Enabled'] = true;
            ['Keybind'] = {'E', 'MouseButton2', 'Keyboard'};
        };

        -- React to an opponent's detected shot while this input is held.
        ['Prefire'] = {
            ['Enabled'] = false;
            ['Range'] = 100; -- Maximum opponent distance in studs.
            ['Delay'] = 0.25; -- Seconds after detecting an opponent's shot.
            ['Holding'] = true; -- Active only while the chosen input is held.
            ['Keybind'] = {'C', 'MouseButton2', 'Keyboard'};
        };
    };
};



-- Runtime begins below.
-- neoperro v1.1.0 | generated by build-neoperro.py
local Core = (function()
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
    return key and spec[weapon][key] or nil
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

function Core.limit(v, maximum)
    local magnitude = v.Magnitude
    if magnitude > maximum and magnitude > 0 then return v * (maximum / magnitude) end
    return v
end

-- Bounded timestamp history; teleport spikes reset the fit instead of poisoning it.
function Core.sample(history, position, now)
    local last = history[#history]
    if last and now - last.t < 1 / 90 then return false end
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

-- A walking speed is not evidence of a macro. Require repeated alternating zoom inputs.
function Core.observeMacro(events, direction, time)
    local last = events[#events]
    if not last or direction ~= last.direction then events[#events + 1] = {direction = direction, time = time} end
    while #events > 8 or (#events > 0 and time - events[1].time > 0.65) do table.remove(events, 1) end
end

function Core.macroActive(events, time, moving)
    return moving and #events >= 4 and time - events[#events].time <= 0.65
end

-- Integer-like viewport geometry in world units, independent of limb animation.
function Core.projectedBox(x, y, depth, width, height, focal)
    if depth <= 0.1 then return nil end
    local w, h = width * focal / depth, height * focal / depth
    return x - w / 2, y - h / 2, w, h
end

return Core

end)()
local Defaults = (function()
return {

    -- Keep aim redirection inside firing windows; idle MOUSE updates pass through. No concealment guarantee.
    ['Anti-AimViewer'] = {
        ['Enabled'] = true;
    };

    -- Vertical compensation. Auto chooses the adjustment; Custom uses JumpOffset.
    ['Y-Axis'] = {
        ['Enabled'] = false; -- Enable vertical compensation.
        ['Mode'] = 'Auto'; -- Auto ignores JumpOffset; Custom uses it without automatic adjustment.
        ['JumpOffset'] = 1.0; -- Custom only: 1 = unchanged, below 1 = less upward lead, above 1 = more.
        ['SilentAim'] = true; -- Apply the Y-Axis section to Silent Aim.
        ['AimAssist'] = false; -- Apply the Y-Axis section to Aim Assist.
    };

    -- Order for every row: {Silent Aim, Aim Assist, Triggerbot}.
    ['Checks'] = {
        ['Dead']       = {true, true, true}; -- Reject dead targets.
        ['Knocked']    = {true, true, true}; -- Reject knocked/incapacitated targets.
        ['Wall']       = {true, true, true}; -- Require a clear visibility check.
        ['ForceField'] = {true, true, false}; -- Reject targets with spawn protection.
        ['Crew']       = {false, false, false}; -- Reject players in your crew.
        ['Tool']       = {false, true, true}; -- Require an equipped weapon.
    };

    -- Calculates the aim point used by the firing integration.
    ['Silent Aim'] = {
        ['Enabled'] = true;
        ['Mode'] = 'Auto'; -- Auto = nearest eligible to cursor; Target = select with a keybind.
        ['Ignore'] = false; -- Ignore circle/player-box bounds; other checks still apply.

        ['Target'] = {
            ['BasePart'] = 'UpperTorso'; -- Used when Closest is disabled; R6 falls back to Torso.
            ['Closest'] = {
                ['Enabled'] = true; -- Choose the body part nearest your crosshair.
                ['Raycast'] = false; -- Exact cursor surface hit before prediction; bypasses Reduce and Sharpness.
                ['Method'] = 'Part'; -- Part = nearest part center; Point = nearest point in that part.
                ['Axis'] = 'Center'; -- Point movement within the part: Center = Y only; All = XYZ.
                ['Sharpness'] = 0.65; -- Point response: 1 = immediate, 0.01 = slow.
                ['Reduce'] = {
                    ['Center'] = 0.7; -- Keep this far from Y edges: 0 = edges, 1 = center.
                    ['All'] = 0.7; -- Same reduction on all axes when Axis is All.
                };
            };
        };

        ['Fov'] = {
            ['Mode'] = '2d-Box'; -- 2d-Box = box on each player; 2d-Circle = circle around crosshair.

            ['2d-Circle'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = 50; -- Circle radius in pixels.
                ['Color'] = {255, 255, 255}; -- RGB, 0-255 per channel.
            };

        };

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'P', 'MouseButton2', 'Keyboard'};
        };

        -- Target selection controls, used when Mode is Target.
        ['Keybind Mode'] = {
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Unlock Mode'] = 'Repeat'; -- Repeat = select again on each press; clear if no eligible target.
            ['Keybind'] = {'T', 'MouseButton2', 'Keyboard'};
        };

        -- Barrel alignment checks. An unsafe angle falls back to your manual aim.
        ['AntiCurve'] = {
            ['Enabled'] = false;
            ['Mode'] = '3d-angles'; -- 3d-angles / endmath; selects one filter.

            ['3d-angles'] = {
                ['MaxAngle'] = 4; -- Maximum angle from camera direction to muzzle-to-target direction.
            };

            ['endmath'] = {
                ['Radius'] = 120; -- Maximum prediction displacement in studs.
                ['MaxAngle'] = 4; -- Maximum camera/barrel parallax in degrees.
                ['WallCheck'] = true; -- Recheck the ray from the actual muzzle to the final point.
            };
        };
    };

    -- Moves the camera toward the chosen aim point.
    ['Aim Assist'] = {
        ['Enabled'] = true;
        ['Mode'] = 'Auto'; -- Auto searches while its key is held; Target uses a selected player.
        ['Ignore'] = false; -- Ignore circle/player-box bounds; other checks still apply.

        ['Follow'] = 'Camera'; -- Camera tracking.
        ['Smoothness'] = 0.0068; -- Strength referenced to 60 FPS; runtime will compensate for frame time.

        ['Target'] = {
            ['BasePart'] = 'UpperTorso'; -- Used when Closest is disabled; R6 falls back to Torso.
            ['Closest'] = {
                ['Enabled'] = true; -- Choose the body part nearest your crosshair.
                ['Raycast'] = false; -- Exact cursor surface hit before prediction; bypasses Reduce and Sharpness.
                ['Method'] = 'Part'; -- Part = nearest part center; Point = nearest point in that part.
                ['Axis'] = 'Center'; -- Point movement within the part: Center = Y only; All = XYZ.
                ['Sharpness'] = 0.65; -- Point response: 1 = immediate, 0.01 = slow.
                ['Reduce'] = {
                    ['Center'] = 0.45; -- Keep this far from Y edges: 0 = edges, 1 = center.
                    ['All'] = 0.45; -- Same reduction on all axes when Axis is All.
                };
            };
        };

        ['Fov'] = {
            ['Mode'] = '2d-Box'; -- 2d-Box = box on each player; 2d-Circle = circle around crosshair.

            ['2d-Circle'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = 100; -- Circle radius in pixels.
                ['Color'] = {255, 255, 255}; -- RGB, 0-255 per channel.
            };

        };

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'M', 'MouseButton2', 'Keyboard'};
        };

        -- In Auto, Holding makes this the search input. In Target, this selects a player.
        ['Keybind Mode'] = {
            ['Holding'] = true; -- Auto: hold to search continuously. Target: hold the selected target.
            ['Unlock Mode'] = 'Normal'; -- Normal = lock on one press, unlock on the next.
            ['Keybind'] = {'Q', 'MouseButton2', 'Keyboard'};
        };
    };

    -- Velocity lead in seconds: 0.128 = 128 ms. Do not multiply it by ping again.
    ['Prediction'] = {
        ['SilentAim'] = 0.128;
        ['AimAssist'] = 0.121;
        ['Triggerbot'] = 0.132;
    };

    -- Shared final-point calculations and optional debug display.
    ['EndMath'] = {
        ['VelocityHistory'] = true; -- Fit velocity to recent position samples; teleport jumps reset the history.
        ['WallCheck'] = true; -- Check visibility of the final calculated point.
        ['Visualizer'] = false; -- Display the final aim point for tuning.
    };

    -- Up to four assigned players. Store UserIds, not display names.
    ['Whitelist'] = {
        ['Enabled'] = false;
        ['Mode'] = 'Friend'; -- Friend = ignore assigned players; Target = only assigned players.
        ['Players'] = {}; -- Up to four numeric UserIds.

        -- Add/remove the eligible player nearest your cursor.
        ['AssignKey'] = {
            ['Keybind'] = {'R', 'MouseButton2', 'Keyboard'};
        };
    };

    -- Recheck the target before firing; do not stack pending shots.
    ['Triggerbot'] = {
        ['Enabled'] = true;
        ['TargetOnly'] = false; -- When true, require the Silent Aim target.

        ['Delay'] = 0.1; -- Fixed delay in seconds when DelayMode is Normal.
        ['RandomDelay'] = {0.1, 0.12}; -- Minimum and maximum delay in seconds.
        ['SmartDelay'] = false; -- Distance-based timing; overrides DelayMode when enabled.
        ['DelayMode'] = 'Random'; -- Normal / Random. Delays are alternatives, not added together.

        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'V', 'MouseButton2', 'Keyboard'}; -- Arm/disarm Triggerbot.
        };
        ['Activation'] = {
            ['Enabled'] = true; -- Require this activation input in addition to Enabled.
            ['Holding'] = true;
            ['Keybind'] = {'Q', 'MouseButton2', 'Mouse'}; -- Hold RMB; change Mouse to Keyboard for Q.
        };
        ['Fov'] = {
            ['Enabled'] = false; -- False = cursor must hit the actual character. True = use a selection shape.
            ['Mode'] = '2d-Box'; -- Player-centered box or crosshair-centered circle.
            ['2d-Circle'] = {['Visible'] = false; ['Size'] = 50; ['Color'] = {255, 255, 255}};
        };
    };

    -- Player boxes and names. Appearance is in the 2d-Box section below.
    ['ESP'] = {
        ['Enabled'] = true;
        ['VisibleCheck'] = false; -- Hide ESP for obstructed players.
        ['Names'] = true; -- Also respects each box's Name setting.
        ['DeadCheck'] = true; -- Hide dead bodies; an enabled Silent Aim Dead check also hides them.
        ['MaxDistance'] = 5050; -- Maximum ESP distance in studs.

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'Z', 'MouseButton2', 'Keyboard'};
        };

    };

    -- Boxes follow each player's root without resizing for walking/limb animations.
    -- Width/Height are studs; their screen size still changes with distance.
    ['2d-Box'] = {
        ['Silent Aim'] = {
            ['Visible'] = true;
            ['Predicted Position'] = false;
            ['Name'] = {true, 'DisplayName'}; -- DisplayName / Name / UserId.
            ['Color'] = {['Box'] = {{255, 255, 255}, {0, 0, 0}}}; -- Foreground, outline.
            ['Size'] = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance'] = 5050;
            ['Filled'] = false;
            ['Transparency'] = 1; -- 1 = opaque, 0 = invisible.
        };
        ['Aim Assist'] = {
            ['Visible'] = false;
            ['Predicted Position'] = false;
            ['Name'] = {false, 'DisplayName'};
            ['Color'] = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size'] = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance'] = 5050;
            ['Filled'] = false;
            ['Transparency'] = 1;
        };
        ['Triggerbot'] = {
            ['Visible'] = false;
            ['Predicted Position'] = false;
            ['Name'] = {false, 'DisplayName'};
            ['Color'] = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size'] = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance'] = 5050;
            ['Filled'] = false;
            ['Transparency'] = 1;
        };
    };

    -- Weapon profiles change box dimensions only; prediction uses the main Prediction section.
    -- BoxSize = projected target-box width/height in studs, not cursor FOV pixels.
    -- Unlisted weapons and targets beyond Far use the general settings.
    ['Gun Specifications'] = {
        ['Enabled'] = false;

        ['Ranges'] = {
            ['Close'] = 15; -- Close: distance up to 15 studs.
            ['Medium'] = 30; -- Medium: over Close, up to 30 studs.
            ['Far'] = 90; -- Far: over Medium, up to 90 studs.
        };

        ['Revolver'] = {
            ['Close'] = {['BoxSize'] = {5, 6}};
            ['Medium'] = {['BoxSize'] = {5, 6}};
            ['Far'] = {['BoxSize'] = {4, 5}};
        };

        ['Double-Barrel SG'] = {
            ['Close'] = {['BoxSize'] = {7, 6}};
            ['Medium'] = {['BoxSize'] = {6, 5}};
            ['Far'] = {['BoxSize'] = {5, 5}};
        };

        ['TacticalShotgun'] = {
            ['Close'] = {['BoxSize'] = {7, 7}};
            ['Medium'] = {['BoxSize'] = {6, 6}};
            ['Far'] = {['BoxSize'] = {5, 5}};
        };

        ['Shotgun'] = {
            ['Close'] = {['BoxSize'] = {7, 7}};
            ['Medium'] = {['BoxSize'] = {6, 6}};
            ['Far'] = {['BoxSize'] = {5, 5}};
        };

        ['Usp'] = {
            ['Close'] = {['BoxSize'] = {5, 6}};
            ['Medium'] = {['BoxSize'] = {5, 6}};
            ['Far'] = {['BoxSize'] = {4, 5}};
        };
    };

    -- Local tracer visuals. Weapon handling stays inside the script.
    -- Uses the selected aim point when available, otherwise your normal mouse aim.
    ['Client Bullets'] = {
        ['Enabled'] = true; -- Always active by default; no separate keybind or target requirement.
    };

    -- Extra controls. No intro settings are exposed here.
    ['Misc'] = {
        ['AntiAfk'] = true; -- Idle prevention where supported.
        ['AntiFling'] = true; -- Mitigate fling-like movement while preserving normal movement.

        -- After weapon activation: unequip -> hold Ctrl -> re-equip -> release Ctrl.
        -- One cycle at a time; cancellation releases only the script's simulated input.
        ['Macro Abuse'] = {
            ['Enabled'] = false;
            ['Work With TB'] = false; -- Also run after Triggerbot fires.
            ['Check Ammo'] = true; -- Require an observed Ammo decrease before starting.
            ['Macro Check'] = true; -- Require movement plus repeated I/O or alternating wheel inputs.
        };

        -- Unload the runtime, remove visuals, and release simulated inputs.
        ['Panic'] = {
            ['Enabled'] = true;
            ['Keybind'] = {'E', 'MouseButton2', 'Keyboard'};
        };

        -- React to an opponent's detected shot while this input is held.
        ['Prefire'] = {
            ['Enabled'] = false;
            ['Range'] = 100; -- Maximum opponent distance in studs.
            ['Delay'] = 0.25; -- Seconds after detecting an opponent's shot.
            ['Holding'] = true; -- Active only while the chosen input is held.
            ['Keybind'] = {'C', 'MouseButton2', 'Keyboard'};
        };
    };
}

end)()
local function playIntro()
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

local duration = 3.2
local blurTail = 1.6
local withSound = true

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

local function loadAsset(name, prefix, expectedBytes, sourceBase)
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
        local data = fetch((sourceBase or assetBase) .. name)
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

    local letterGroup = make('Frame', {
        Name = 'LetterGroup', AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0, BackgroundTransparency = 1,
    }, screen)

    local logoContainer = make('Frame', {
        Name = 'Swirl', AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1800, 1800),
        BackgroundTransparency = 1, Rotation = -225,
    }, letterGroup)
    local logoScale = make('UIScale', {Scale = 0.08}, logoContainer)

    local logo = make('ImageLabel', {
        Name = 'Monogram', AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Fit, Visible = false,
    }, logoContainer)

    local fallback = make('TextLabel', {
        Name = 'Fallback', Text = 'N', Font = Enum.Font.Antique, TextScaled = true, TextTransparency = 1,
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
            local id = loadAsset('neoperro-n-clean.png', '\137PNG\r\n\26\n', 328429,
                'https://raw.githubusercontent.com/kasztingers11-lang/mysite/3707290a70ffdec3d2efb0c0c682864c5b6eddf9/neoperro-intro/assets/')
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
    tween(logo, 0.3, {ImageTransparency = 0})
    tween(fallback, 0.3, {TextTransparency = 0})
    tween(logoContainer, enter, {Rotation = 0})
    tween(logoScale, enter, {Scale = 1})

    task.wait(duration - leave)
    if not alive() then return end
    tween(logoContainer, leave, {Rotation = 12})
    tween(logoScale, leave, {Scale = 1.08})
    tween(fallback, leave, {TextTransparency = 1})
    local fade = tween(logo, leave, {ImageTransparency = 1})
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


end
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
if previous and previous.Intro then environment.__neoperroIntroSeenV1 = true end
local saved = previous and previous.Alive and previous:Snapshot() or nil
if previous and type(previous.Destroy) == 'function' then previous:Destroy('replace') end

local state = {
    Alive = true, Version = '1.1.0', Config = config, Connections = {}, Objects = {},
    Records = {}, Toggles = {}, Held = {}, Locks = {}, Points = {}, Targets = {},
    Warnings = {}, Capabilities = {}, ShotUntil = 0, NextFire = 0, Initial = {},
    Whitelist = Core.ids(config.Whitelist.Players), WhiteMode = config.Whitelist.Mode,
    InitialWhitelist = Core.ids(config.Whitelist.Players), InitialWhiteMode = config.Whitelist.Mode,
    Epoch = 0, Visuals = {}, Focused = true, MacroInputs = {},
    Stats = {AimPackets = 0, Activations = 0, TriggerAttempts = 0, AmmoDrops = 0},
}
environment[runtimeKey] = state
local zero = Vector3.new(0, 0, 0)
local now = os.clock
local camera, cursor, cursorRay
local localCharacter, localHumanoid, localRoot, equipped, weaponName, muzzleAttachment
local tryMacro, releaseShotInput
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
    if previous.Version == state.Version and state.InitialWhiteMode == saved.InitialWhiteMode then state.WhiteMode = saved.WhiteMode end
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
    if releaseShotInput then releaseShotInput() end
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
    if toggle and toggle.Enabled and toggle.Holding and not state.Held['toggle:' .. name] then return false end
    if name == 'Triggerbot' then
        local gate = feature.Activation
        if gate.Enabled and not state.Held['activation:Triggerbot'] then return false end
    end
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
    if muzzleAttachment and muzzleAttachment.Parent then return muzzleAttachment.WorldPosition end
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

local function cursorHit()
    rayParams.FilterDescendantsInstances = localCharacter and {localCharacter, camera} or {camera}
    return World:Raycast(cursorRay.Origin, cursorRay.Direction * 5000, rayParams)
end

local function targetPart(record, feature)
    if not record.character then return nil end
    local target = targetSettings(feature)
    if not target.Closest.Enabled then return partFor(record, target.BasePart) end
    local best, distance = nil, math.huge
    for _, part in ipairs(record.character:GetChildren()) do
        if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
            local p, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and p.Z > 0 then
                local d = (Vector2.new(p.X, p.Y) - cursor).Magnitude
                if d < distance then best, distance = part, d end
            end
        end
    end
    return best or partFor(record, target.BasePart)
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

local function playerBox(record, feature)
    if not record.root or not record.character then return nil end
    local style = config['2d-Box'][feature]
    local origin = record.root.Position
    if style['Predicted Position'] then
        origin = origin + velocity(record) * Core.number(config.Prediction[predictionKeys[feature]], 0.128, 0, 1)
    end
    local distance = (origin - (localRoot and localRoot.Position or camera.CFrame.Position)).Magnitude
    if distance > Core.number(style['Max Distance'], 5050, 0, 100000) then return nil end
    local projected = camera:WorldToViewportPoint(origin)
    local width, height = Core.number(style.Size.Width, 5, 0.1, 100), Core.number(style.Size.Height, 4.3, 0.1, 100)
    local profile = Core.profile(config['Gun Specifications'], weaponName, distance)
    if profile and profile.BoxSize then
        width = Core.number(profile.BoxSize[1], width, 0.1, 100)
        height = Core.number(profile.BoxSize[2], height, 0.1, 100)
    end
    local focal = camera.ViewportSize.Y / (2 * math.tan(math.rad(camera.FieldOfView) / 2))
    local x, y, w, h = Core.projectedBox(projected.X, projected.Y, projected.Z, width, height, focal)
    if not x or x+w < 0 or y+h < 0 or x > camera.ViewportSize.X or y > camera.ViewportSize.Y then return nil end
    return Vector2.new(x, y), Vector2.new(w, h)
end

local function inFov(record, feature, part)
    local settings = config[feature]
    if settings.Ignore then return true end
    if settings.Fov.Mode == '2d-Circle' then
        local p, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen or p.Z <= 0 then return false end
        return Core.fov(p.X - cursor.X, p.Y - cursor.Y, '2d-Circle', 0, 0,
            Core.number(settings.Fov['2d-Circle'].Size, 50, 1, 10000))
    end
    local position, size = playerBox(record, feature)
    return position ~= nil and cursor.X >= position.X and cursor.X <= position.X+size.X
        and cursor.Y >= position.Y and cursor.Y <= position.Y+size.Y
end

local function nearest(feature, assignment)
    if not captureView() then return nil end
    local choices = {}
    for _, record in pairs(state.Records) do
        local part = assignment and partFor(record, 'HumanoidRootPart') or targetPart(record, feature)
        if part and (assignment or (valid(record, feature, part, true) and inFov(record, feature, part))) then
            local projected, onScreen = camera:WorldToViewportPoint(part.Position)
            if projected.Z > 0 and (onScreen or (not assignment and config[feature].Ignore)) then
                local distance = (Vector2.new(projected.X, projected.Y) - cursor).Magnitude
                if not assignment or distance <= 150 then choices[#choices + 1] = {record = record, part = part, distance = distance} end
            end
        end
    end
    table.sort(choices, function(a, b) return a.distance < b.distance end)
    for _, choice in ipairs(choices) do
        if assignment or valid(choice.record, feature, choice.part) then return choice.record end
    end
end

local function aimPoint(record, feature)
    local settings = config[feature]
    local target = targetSettings(feature)
    local closest = target.Closest
    local part = targetPart(record, feature)
    if not valid(record, feature, part) then return nil end
    if (feature ~= 'Triggerbot' or settings.Fov.Enabled) and not inFov(record, feature, part) then return nil end
    local point = part.Position
    local exact = closest.Enabled and closest.Raycast and state.CursorHit
    if exact and exact.Instance:IsDescendantOf(record.character) and exact.Instance:IsA('BasePart') then
        part, point = exact.Instance, exact.Position
    elseif closest.Enabled and closest.Method == 'Point' then
        local depth = math.max(0, (point - cursorRay.Origin):Dot(cursorRay.Direction))
        local localPoint = part.CFrame:PointToObjectSpace(cursorRay.Origin + cursorRay.Direction * depth)
        local reduction = Core.number(closest.Reduce[closest.Axis == 'All' and 'All' or 'Center'], 0.7, 0, 1)
        local half = part.Size * (0.5 * (1 - reduction))
        localPoint = Vector3.new(
            closest.Axis == 'All' and math.clamp(localPoint.X, -half.X, half.X) or 0,
            math.clamp(localPoint.Y, -half.Y, half.Y),
            closest.Axis == 'All' and math.clamp(localPoint.Z, -half.Z, half.Z) or 0)
        record.pointState = record.pointState or {}
        local last = record.pointState[feature]
        if last and last.part == part then
            local alpha = Core.alpha(Core.number(closest.Sharpness, 0.65, 0.01, 1), now() - last.time)
            localPoint = last.point + (localPoint - last.point) * alpha
        end
        record.pointState[feature] = {part = part, point = localPoint, time = now()}
        point = part.CFrame:PointToWorldSpace(localPoint)
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
    local anti = feature == 'Silent Aim' and settings.AntiCurve
    if anti and anti.Enabled then
        local origin = muzzle()
        local barrelRay = point - origin
        if barrelRay.Magnitude < 0.01 then return nil end
        if anti.Mode == 'endmath' then
            point = base + Core.limit(point - base, Core.number(anti.endmath.Radius, 120, 0, 1000))
            local cameraRay = point - camera.CFrame.Position
            barrelRay = point - origin
            if cameraRay.Magnitude > 0.01 and barrelRay.Magnitude > 0.01 then
                local angle = math.deg(math.acos(math.clamp(cameraRay.Unit:Dot(barrelRay.Unit), -1, 1)))
                if angle > Core.number(anti.endmath.MaxAngle, 4, 0, 180) then return nil end
            end
            if anti.endmath.WallCheck and not visible(point, record.character, origin, true) then return nil end
        else
            local angle = math.deg(math.acos(math.clamp(camera.CFrame.LookVector:Dot(barrelRay.Unit), -1, 1)))
            if angle > Core.number(anti['3d-angles'].MaxAngle, 4, 0, 180) then return nil end
        end
    end
    if not Core.finiteVector(point) then return nil end
    if config.EndMath.WallCheck and (not visible(point, record.character, camera.CFrame.Position, true)
        or not visible(point, record.character, muzzle(), true)) then return nil end
    return point, part
end

local function selectTarget(feature)
    if not enabled(feature) or typing() then return nil end
    if config[feature].Mode == 'Auto' then
        if feature == 'Aim Assist' and config[feature]['Keybind Mode'].Holding and not state.Held['target:' .. feature] then return nil end
        return nearest(feature)
    end
    local mode = config[feature]['Keybind Mode']
    if mode.Holding and not state.Held['target:' .. feature] then return nil end
    local player = validPlayer(state.Locks[feature])
    return player and state.Records[player] or nil
end

local function updateAim()
    if not captureView() or not localHumanoid or localHumanoid.Health <= 0 then
        state.Points, state.Targets = {}, {}; return
    end
    state.CursorHit = cursorHit()
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
        if config['Anti-AimViewer'].Enabled and not shooting then state.PacketPoint = nil
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
    state.Stats.AimPackets = state.Stats.AimPackets + 1
    local ok, reason = pcall(function() state.Remote:FireServer('MOUSE', point) end)
    if not ok then warnOnce('remote-send', tostring(reason)) end
end

local function macroEnabled()
    local supplied = environment.neoperro
    local live = type(supplied) == 'table' and supplied.Misc and supplied.Misc['Macro Abuse']
    return config.Misc['Macro Abuse'].Enabled == true and type(live) == 'table' and live.Enabled == true
end

local function detectedMacro()
    local moving = localHumanoid and localHumanoid.MoveDirection.Magnitude > 0.05
    return Core.macroActive(state.MacroInputs, now(), moving)
end

local function beginMacro(source, tool, confirmed)
    local settings = config.Misc['Macro Abuse']
    if not macroEnabled() or macro or (source ~= 'Manual' and source ~= 'Triggerbot') then return end
    if source == 'Triggerbot' and not settings['Work With TB'] then return end
    if settings['Macro Check'] and not detectedMacro() then return end
    if settings['Check Ammo'] and not confirmed then
        local ammo = childValue(tool, 'Ammo')
        if type(ammo) ~= 'number' then warnOnce('macro-ammo', 'Macro Check Ammo is on, but this tool has no replicated Ammo value.'); return end
        local drop = state.LastAmmoDrop
        if not drop or drop.tool ~= tool or now() - drop.time > 0.2 then
            state.PendingMacro = {source = source, tool = tool, expires = now() + 0.65}
            return
        end
    end
    state.PendingMacro = nil
    if not virtualInput then warnOnce('macro-input', 'Macro needs VirtualInputManager key events.'); return end
    if not localHumanoid or localHumanoid.Health <= 0 or typing() then return end
    macro = {stage = 'wait', due = now() + 0.04, tool = tool, character = localCharacter}
end
tryMacro = beginMacro

local function macroStep(time)
    if not macro then return end
    local cycle = macro
    if not macroEnabled() or (config.Misc['Macro Abuse']['Macro Check'] and not detectedMacro()) or typing() or localCharacter ~= cycle.character
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

releaseShotInput = function()
    if state.ShotRelease then
        local release = state.ShotRelease
        state.ShotRelease = nil
        pcall(release)
    end
    state.MouseOwned = false
    if state.AutomatedTool then pcall(function() state.AutomatedTool:Deactivate() end) end
    state.AutomatedTool = nil
end

local function fire(source, record, point)
    if not equipped or not equipped.Enabled or macro or typing() or now() < state.NextFire then return false end
    if Input:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and not state.MouseOwned then return false end
    if not localHumanoid or localHumanoid.Health <= 0 or isKnocked(localCharacter) then return false end
    local ammo = childValue(equipped, 'Ammo')
    if type(ammo) == 'number' and ammo <= 0 then return false end
    local time, tool = now(), equipped
    state.NextFire, state.ShotUntil = time + 0.08, time + 0.14
    state.ForcedPoint, state.ForcedUntil = point, time + 0.14
    activation = {source = source, tool = tool, untilTime = time + 0.14, sent = true}
    state.Stats.TriggerAttempts = state.Stats.TriggerAttempts + 1
    sendAim(point)
    state.DeactivateAt = time + 0.04
    if type(mouse1press) == 'function' and type(mouse1release) == 'function' then
        state.MouseOwned = true
        state.ShotRelease = mouse1release
        local ok = pcall(mouse1press)
        if ok then state.Capabilities.FireInput = 'mouse1press'; return true end
        releaseShotInput()
    end
    if virtualInput then
        state.MouseOwned = true
        local x, y = cursor.X, cursor.Y
        state.ShotRelease = function() virtualInput:SendMouseButtonEvent(x, y, 0, false, game, 0) end
        local ok = pcall(function() virtualInput:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
        if ok then state.Capabilities.FireInput = 'VirtualInputManager'; return true end
        releaseShotInput()
    end
    state.AutomatedTool = tool
    local ok, reason = pcall(function() tool:Activate() end)
    state.Capabilities.FireInput = 'Tool.Activate fallback'
    if not ok then warnOnce('activate', tostring(reason)); return false end
    return true
end

local function activated(tool)
    if tool ~= equipped or typing() then return end
    local source = 'Manual'
    if activation and activation.tool == tool and now() <= activation.untilTime then source = activation.source end
    activation = nil
    state.Stats.Activations = state.Stats.Activations + 1
    state.ShotUntil = now() + 0.14
    updateAim()
    refreshPacket()
    if source == 'Manual' then sendAim(state.Points['Silent Aim']) end
    state.LastShot = {time = now(), tool = tool, origin = muzzle(), point = state.ClientPoint}
    beginMacro(source, tool)
end

local function bindTool(tool)
    if not tool:IsA('Tool') then return end
    local name = Core.weapon(tool.Name)
    local lower = tool.Name:lower()
    if lower:find('wallet') or lower:find('phone') or lower:find('knife') or lower:find('katana') then return end
    if not name and not tool:FindFirstChild('Ammo') and not tool:FindFirstChild('Handle') then return end
    disconnect(toolConnections)
    equipped, weaponName, muzzleAttachment = tool, name, nil
    for _, item in ipairs(tool:GetDescendants()) do
        if item:IsA('Attachment') and (item.Name:lower():find('muzzle') or item.Name == 'GunAttachment') then muzzleAttachment = item; break end
    end
    local ammoValue = tool:FindFirstChild('Ammo')
    if ammoValue and (ammoValue:IsA('IntValue') or ammoValue:IsA('NumberValue')) then
        local previousAmmo = ammoValue.Value
        connect(ammoValue:GetPropertyChangedSignal('Value'), function()
            local value = ammoValue.Value
            if value < previousAmmo then
                state.Stats.AmmoDrops = state.Stats.AmmoDrops + 1
                state.LastAmmoDrop = {tool = tool, time = now()}
                local pending = state.PendingMacro
                if pending and pending.tool == tool and now() <= pending.expires then tryMacro(pending.source, tool, true) end
            end
            previousAmmo = value
        end, toolConnections)
    end
    connect(tool.Activated, function() activated(tool) end, toolConnections)
    connect(tool.AncestryChanged, function()
        if tool.Parent ~= localCharacter and equipped == tool then
            equipped, weaponName, muzzleAttachment = nil, nil, nil
            state.PendingMacro = nil
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
    state.PendingMacro, state.MacroInputs, state.LastAmmoDrop = nil, {}, nil
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
    record.pointState = {}
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
    state.CursorHit = cursorHit()
    local record
    if config.Triggerbot.Fov.Enabled then record = nearest('Triggerbot')
    else
        local hit = state.CursorHit
        if not hit then return nil end
        local object, player = hit.Instance, nil
        while object and object ~= World do
            if object:IsA('Model') then player = Players:GetPlayerFromCharacter(object); if player then break end end
            object = object.Parent
        end
        record = player and state.Records[player]
    end
    if not record then return nil end
    if config.Triggerbot.TargetOnly and record.player ~= state.Targets['Silent Aim'] then return nil end
    local point = aimPoint(record, 'Triggerbot')
    if point then return record, point end
end

local random = Random.new()
local function automaticFire(time)
    local record, point = triggerCandidate()
    state.Targets.Triggerbot = record and record.player or nil
    state.Points.Triggerbot = point
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
for _, name in ipairs({'Silent Aim', 'Aim Assist', 'Triggerbot'}) do
    fovVisuals[name] = {box = visual('Square'), circle = visual('Circle')}
    debugVisuals[name] = visual('Circle')
end

local function color(rgb)
    return Color3.fromRGB(Core.number(rgb[1], 255, 0, 255), Core.number(rgb[2], 255, 0, 255), Core.number(rgb[3], 255, 0, 255))
end

local function drawFov()
    for name, shapes in pairs(fovVisuals) do
        local fov = config[name].Fov
        local circle = fov['2d-Circle']
        shapes.box:Set({Visible = false})
        shapes.circle:Set({Visible = enabled(name) and (name ~= 'Triggerbot' or fov.Enabled) and fov.Mode == '2d-Circle' and circle.Visible == true,
            Position = cursor, Radius = Core.number(circle.Size, 50, 1, 10000), Color = color(circle.Color), Transparency = 1})
        local point = state.Points[name]
        local projected, onScreen
        if point then projected, onScreen = camera:WorldToViewportPoint(point) end
        debugVisuals[name]:Set({Visible = config.EndMath.Visualizer and onScreen == true,
            Position = projected and Vector2.new(projected.X, projected.Y) or cursor,
            Radius = 3, Filled = true, Color = Color3.new(1, 1, 1), Transparency = 1})
    end
end

local function assignedColor(id, fallback)
    for _, assigned in ipairs(state.Whitelist) do
        if assigned == id then return state.WhiteMode == 'Target' and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(80, 230, 110) end
    end
    return fallback
end

local function drawPlayers(time)
    for _, record in pairs(state.Records) do
        local exists = record.root and record.humanoid and record.character and record.character.Parent
        local dead = exists and (record.humanoid.Health <= 0 or record.character:GetAttribute('Dead') == true)
        for _, feature in ipairs({'Silent Aim', 'Aim Assist', 'Triggerbot'}) do
            local style = config['2d-Box'][feature]
            local show = exists and enabled('ESP') and style.Visible
            if dead and (config.ESP.DeadCheck or config.Checks.Dead[checkIndices[feature]]) then show = false end
            if show then show = (record.root.Position - camera.CFrame.Position).Magnitude <= Core.number(config.ESP.MaxDistance, 5050, 0, 100000) end
            if show and config.ESP.VisibleCheck then
                if time >= (record.visibilityAt or 0) then
                    record.espVisible, record.visibilityAt = visible(record.root.Position, record.character), time + 0.08
                end
                show = record.espVisible
            end
            local position, size
            if show then position, size = playerBox(record, feature) end
            record.visuals = record.visuals or {}
            local v = record.visuals[feature]
            if position then
                if not v then v = {outline = visual('Square'), box = visual('Square'), name = visual('Text')}; record.visuals[feature] = v end
                local opacity = Core.number(style.Transparency, 1, 0, 1)
                local foreground = assignedColor(record.player.UserId, color(style.Color.Box[1]))
                v.outline:Set({Visible = true, Position = position, Size = size, Thickness = 3, Filled = false,
                    Color = color(style.Color.Box[2]), Transparency = opacity})
                v.box:Set({Visible = true, Position = position, Size = size, Filled = style.Filled == true,
                    Color = foreground, Transparency = opacity})
                local name = style.Name[2] == 'Name' and record.player.Name
                    or (style.Name[2] == 'UserId' and tostring(record.player.UserId) or record.player.DisplayName)
                v.name:Set({Visible = config.ESP.Names and style.Name[1], Text = name,
                    Position = Vector2.new(position.X + size.X / 2, position.Y - 17), Color = foreground, Transparency = opacity})
            elseif v then for _, object in pairs(v) do object:Set({Visible = false}) end end
        end
    end
end

local function inputMatches(input, action)
    return action and Core.input(action.Keybind, input.KeyCode.Name, input.UserInputType.Name)
end

local function inputChanged(input, began, processed)
    if state.MouseOwned and input.UserInputType == Enum.UserInputType.MouseButton1 then return end
    if began and not typing() and (input.KeyCode.Name == 'I' or input.KeyCode.Name == 'O') then
        Core.observeMacro(state.MacroInputs, input.KeyCode.Name == 'I' and 1 or -1, now())
    end
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
        local mode = config[name]['Keybind Mode']
        if inputMatches(input, mode) then
            state.Held['target:' .. name] = began
        end
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
        if inputMatches(input, config.Whitelist.AssignKey) then
            local record = nearest('Silent Aim', true)
            if record then
                local id, found = record.player.UserId, nil
                for i, value in ipairs(state.Whitelist) do if value == id then found = i; break end end
                if found then table.remove(state.Whitelist, found)
                elseif #state.Whitelist < 4 then state.Whitelist[#state.Whitelist + 1] = id end
            end
        end
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
    local remote = ReplicatedStorage:FindFirstChild('MAINEVENT') or ReplicatedStorage:FindFirstChild('MainEvent')
    state.Remote = remote and remote:IsA('RemoteEvent') and remote or nil
    state.Capabilities.Remote = state.Remote ~= nil
end

local function start()
    findRemote()
    installHooks()
    if not state.Remote then warnOnce('missing-remote', 'MAINEVENT is missing; firing redirection waits for it to appear.') end
    if not hooks.Namecall then warnOnce('no-hook', 'Namecall hooks unavailable: using Looten-style activation updates; Anti-AimViewer is unavailable.') end
    if not hooks.Index then warnOnce('no-index', 'Mouse hooks unavailable: local bullet redirection is limited to recognized Beams.') end
    connect(ReplicatedStorage.ChildAdded, function(child) if child.Name == 'MAINEVENT' or child.Name == 'MainEvent' then findRemote() end end)
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
            if record.visuals then for _, group in pairs(record.visuals) do for _, v in pairs(group) do v:Destroy(); state.Visuals[v] = nil end end end
            state.Records[player] = nil
        end
        for name, id in pairs(state.Locks) do if id == player.UserId then state.Locks[name] = nil end end
    end)
    connect(Input.InputBegan, function(input, processed) inputChanged(input, true, processed) end)
    connect(Input.InputEnded, function(input) inputChanged(input, false, false) end)
    connect(Input.InputChanged, function(input)
        if not typing() and input.UserInputType == Enum.UserInputType.MouseWheel and input.Position.Z ~= 0 then
            Core.observeMacro(state.MacroInputs, input.Position.Z > 0 and 1 or -1, now())
        end
    end)
    local function suspend()
        state.Held = {}; state.Points = {}; state.Targets = {}
        state.PacketPoint, state.ClientPoint = nil, nil
        pendingTrigger, pendingPrefire = nil, nil
        state.PendingMacro, state.MacroInputs = nil, {}
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
        if (state.ShotRelease or state.AutomatedTool) and time >= state.DeactivateAt then releaseShotInput() end
        if state.PendingMacro and (not macroEnabled() or time > state.PendingMacro.expires) then state.PendingMacro = nil end
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
