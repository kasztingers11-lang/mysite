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
