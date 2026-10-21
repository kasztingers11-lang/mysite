-- neoperro
-- Edit this table and execute neoperro.lua again to apply it.
-- Keybind format: {keyboard key, mouse button, active device}.
-- Use 'Keyboard' or 'Mouse' as the third value. Only that device is active.
-- Shared keybinds are allowed. The runtime will dispatch each enabled matching action.
-- Panic takes priority over other actions sharing its key.
-- Re-execution will replace the old instance and retain valid targets, toggles and whitelist state.
-- Supported place IDs and intro behavior belong inside the script, not this table.

getgenv()['neoperro'] = {

    -- Rewrites idle MOUSE updates to camera-forward; shot windows use real aim. No concealment guarantee.
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
        ['Ignore'] = false; -- Ignore FOV when true; other checks still apply.

        ['Part'] = 'UpperTorso'; -- UpperTorso / Head / HumanoidRootPart.
        ['Method'] = 'Part'; -- Part = part center; Point = a point within reduced part bounds.
        ['Axis'] = 'Center'; -- Center = Y-only assistance; All = XYZ.
        ['PointReduction'] = 0.7; -- Point mode: 0 = full bounds, 1 = center.

        ['Fov'] = {
            ['Mode'] = '2d-Box'; -- 2d-Box / 2d-Circle; only the selected shape is used.

            ['2d-Circle'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = 50; -- Circle radius in pixels.
                ['Color'] = {255, 255, 255}; -- RGB, 0-255 per channel.
            };

            ['2d-Box'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = {
                    ['X'] = 100; -- Full box width in pixels.
                    ['Y'] = 100; -- Full box height in pixels.
                };
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

        -- Limits prediction displacement; neither mode guarantees hits or cancels network lag.
        ['AntiCurve'] = {
            ['Enabled'] = false;
            ['Mode'] = '3d-angles'; -- 3d-angles / endmath; selects one filter.

            ['3d-angles'] = {
                ['MaxAngle'] = 4; -- Maximum angle between direct and predicted aim, in degrees.
            };

            ['endmath'] = {
                ['Radius'] = 120; -- Maximum final-point displacement from the body point, in studs.
            };
        };
    };

    -- Moves the camera toward the chosen aim point.
    ['Aim Assist'] = {
        ['Enabled'] = true;
        ['Mode'] = 'Target'; -- Target = keybind selection; Auto = automatic cursor-based selection.
        ['Ignore'] = false; -- Ignore FOV when true; other checks still apply.

        ['Follow'] = 'Camera'; -- Camera tracking.
        ['Smoothness'] = 0.0068; -- Strength referenced to 60 FPS; runtime will compensate for frame time.

        ['Part'] = 'UpperTorso'; -- UpperTorso / Head / HumanoidRootPart.
        ['Method'] = 'Part'; -- Part = part center; Point = a point within reduced part bounds.
        ['Axis'] = 'Center'; -- Center = Y-only assistance; All = XYZ.
        ['PointReduction'] = 0.45; -- Point mode: higher values keep the point nearer the center.

        ['Fov'] = {
            ['Mode'] = '2d-Box'; -- 2d-Box / 2d-Circle; only the selected shape is used.

            ['2d-Circle'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = 100; -- Circle radius in pixels.
                ['Color'] = {255, 255, 255}; -- RGB, 0-255 per channel.
            };

            ['2d-Box'] = {
                ['Visible'] = false; -- Show the FOV outline; hiding it does not disable the FOV check.
                ['Size'] = {
                    ['X'] = 200; -- Full box width in pixels.
                    ['Y'] = 200; -- Full box height in pixels.
                };
                ['Color'] = {255, 255, 255}; -- RGB, 0-255 per channel.
            };
        };

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'M', 'MouseButton2', 'Keyboard'};
        };

        -- Target selection controls, used when Mode is Target.
        ['Keybind Mode'] = {
            ['Holding'] = false; -- Press to toggle/select rather than holding.
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

        -- Clear the assigned player list.
        ['ClearKey'] = {
            ['Keybind'] = {'F', 'MouseButton2', 'Keyboard'};
        };

        -- Switch between Friend and Target modes.
        ['ToggleModeKey'] = {
            ['Keybind'] = {'B', 'MouseButton2', 'Keyboard'};
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

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = true; -- Active only while the chosen input is held.
            ['Keybind'] = {'V', 'MouseButton2', 'Keyboard'};
        };
    };

    -- Player boxes and names. Colors use the script's built-in visual style.
    ['ESP'] = {
        ['Enabled'] = true;
        ['VisibleCheck'] = false; -- Hide ESP for obstructed players.
        ['Names'] = true; -- Display player names.
        ['MaxDistance'] = 5050; -- Maximum ESP distance in studs.

        -- Enable/disable this feature through its input.
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false; -- Press to toggle/select rather than holding.
            ['Keybind'] = {'Z', 'MouseButton2', 'Keyboard'};
        };

        ['2d-Box'] = {
            ['Filled'] = false; -- Fill the box instead of using just an outline.
            ['Transparency'] = 1; -- Drawing convention: 1 = opaque, 0 = invisible.
            ['PredictedPos'] = false; -- Draw at the estimated future position.
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
            ['Work With TB'] = false; -- Also run the sequence after triggerbot activations.
        };

        -- Unload the runtime, remove visuals, and release simulated inputs.
        ['Panic'] = {
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

