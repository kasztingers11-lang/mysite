script_key = "FLOW-REPLACE-WITH-YOUR-KEY";

-- Put your own key above. Edit the table, then run this whole file.
-- Prediction can lead a moving player in X, Y and Z. Auto ignores Value.
-- Empty Whitelist lists allow everyone. There is no assignment cap.
-- Crouch, lying and emote pose measurements run automatically.
-- Table replacements and nested edits apply in this session, checked four times per second.
-- Manual Value calibrates at the current ping; later ping changes adapt the lead.
-- The intro plays once per client session. There are no intro settings.
-- P: Silent toggle | M: Assist toggle | hold Q: Assist | V: Trigger toggle | hold RMB: Trigger | E: stop.

getgenv()['neoperro'] = {
    -- Skip players who fail these checks. Each row is: Silent Aim, Aim Assist, Triggerbot.
    ['Checks']             = {
        ['Dead']            = {true, true, true};                                -- Skip dead players.
        ['Knocked']         = {true, true, true};                                -- Skip knocked players.
        ['Wall']            = {true, true, true};                                -- Skip aim points blocked by a wall.
        ['ForceField']      = {true, true, false};                               -- Skip players with spawn protection.
        ['Crew']            = {false, false, false};                             -- Skip players in your crew.
        ['Tool']            = {false, true, true};                               -- Require a held tool.
        ['GroundShotCheck'] = {true, true, true};                                -- Keep downward aim lead above detected ground. Columns: Silent, Assist, Triggerbot.
    };

    -- Extra up/down aim adjustment. The three switches choose which features use it.
    ['Y-Axis']             = {
        ['Enabled']    = false;                                                  -- Main on/off switch for this option.
        ['Method']     = 'Auto';                                                 -- Auto handles up/down lead. Custom uses Offset.
        ['Offset']     = 1.0;                                                    -- Custom only: upward lead. 1 is normal; 0.5 is less; 2 is more.
        ['SilentAim']  = true;                                                   -- Let Silent Aim use this Y-Axis section.
        ['Aim Assist'] = true;                                                   -- Let Aim Assist use this Y-Axis section.
        ['Triggerbot'] = true;                                                   -- Let Triggerbot use this Y-Axis section.
    };

    -- Use coherent observed movement when reported XYZ speed is wrong or keeps flipping.
    ['Resolver']           = {
        ['Enabled'] = true;                                                      -- Main on/off switch for this option.
    };

    -- Put normal mouse aim back after the script sends a shot point.
    ['Anti-AimViewer']     = {
        ['Enabled'] = true;                                                      -- Main on/off switch for this option.
    };

    -- Show your bullets going toward your mouse on YOUR screen. Keep the game's normal bullet style.
    ['Client Bullets']     = {
        ['Enabled'] = true;                                                      -- Main on/off switch for this option.
    };

    -- Help your shots aim at the chosen player.
    ['Silent Aim']         = {
        ['Enabled']    = true;                                                   -- Main on/off switch for this option.
        -- Predict XYZ movement from measured motion and ping. Auto chooses time; manual starts from Value.
        ['Prediction'] = {
            ['Enabled'] = true;                                                  -- Main on/off switch for this option.
            ['Auto']    = true;                                                  -- Choose prediction time for you.
            ['Value']   = 0.128;                                                 -- Manual baseline in seconds. Speed and later ping changes adapt it without changing this number.
        };
        ['Method']     = 'Auto';                                                 -- Auto keeps looking for a player. Target uses the player you pick.
        ['Ignore']     = false;                                                  -- Skip Silent Aim's FOV limit when true.
        ['Target']     = {
            ['BasePart'] = 'UpperTorso';                                         -- Body part to use when Closest is off.
            -- Choose the body part or point nearest your mouse.
            ['Closest']  = {
                ['Enabled']   = true;                                            -- Main on/off switch for this option.
                ['Raycast']   = false;                                           -- Use the exact body surface under your mouse when available.
                ['Selection'] = 'Part';                                          -- Part picks a part center. Point picks a point inside that part.
                ['Axis']      = 'Center';                                        -- Center moves the point up/down. All lets it move in every direction.
                ['Sharpness'] = 0.7;                                             -- 1 reacts right away. Smaller numbers move the point more slowly.
                ['Reduce']    = {
                    ['Center'] = 0.7;                                            -- 0 allows the edges. 1 keeps the point in the middle.
                    ['All']    = 0.7;                                            -- Same edge limit, used when Axis is All.
                };
            };
        };
        ['Fov']        = {
            ['Method']    = '2d-Box';                                            -- 2d-Box uses the player's box. 2d-Circle uses a circle around your mouse.
            ['2d-Circle'] = {
                ['Visible'] = false;                                             -- Show this shape on your screen.
                ['Size']    = 50;                                                -- Circle radius in screen pixels.
                ['Color']   = {255, 255, 255};                                   -- Red, green and blue, from 0 to 255.
            };
        };
        -- Turn Silent Aim on or off with a button. Default: P.
        ['Toggle']     = {
            ['Enabled'] = true;                                                  -- Use the on/off key for this feature.
            ['Holding'] = false;                                                 -- True means keep the button held. False means press once where this control allows it.
            ['Keybind'] = {'P', 'MouseButton2', 'Keyboard'};                     -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
        -- Auto can run by itself. Target uses this button to pick or hold a player.
        ['Activation'] = {
            ['Holding']       = false;                                           -- Auto: true needs this button held; false runs by itself. Target: true holds the lock.
            ['Unlock Method'] = 'Repeat';                                        -- Target only: Normal can unlock on the next press; Repeat picks again.
            ['Keybind']       = {'T', 'MouseButton2', 'Keyboard'};               -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
        -- Skip shot points that are too far from your normal aim line.
        ['AntiCurve']  = {
            ['Enabled']   = false;                                               -- Main on/off switch for this option.
            ['Method']    = '3d-angles';                                         -- 3d-angles uses studs. Endmath uses screen pixels.
            ['3d-angles'] = {
                ['Max'] = 2.2;                                                   -- Allowed distance from the aim line in studs. math.huge removes this limit.
            };
            ['Endmath']   = {
                ['Radius']    = 120;                                             -- Allowed distance from the aim line in screen pixels. math.huge removes this limit.
                ['WallCheck'] = true;                                            -- Reject an aim point blocked by a wall.
            };
        };
    };

    -- Gently move your camera or mouse toward the chosen player.
    ['Aim Assist']         = {
        ['Enabled']    = true;                                                   -- Main on/off switch for this option.
        -- Help the camera follow where a moving player is going.
        ['Prediction'] = {
            ['Enabled'] = true;                                                  -- Main on/off switch for this option.
            ['Auto']    = true;                                                  -- Choose prediction time for you.
            ['Value']   = 0.121;                                                 -- Manual baseline in seconds. Speed and later ping changes adapt it without changing this number.
        };
        ['Method']     = 'Auto';                                                 -- Auto keeps looking for a player. Target uses the player you pick.
        ['Follow']     = 'Camera';                                               -- Camera moves your view. Mouse moves your mouse.
        ['Smoothness'] = 0.0068;                                                 -- Smaller is gentler. Bigger catches up faster.
        ['Target']     = {
            ['BasePart'] = 'UpperTorso';                                         -- Body part to use when Closest is off.
            -- Choose the body part or point nearest your mouse.
            ['Closest']  = {
                ['Enabled']   = true;                                            -- Main on/off switch for this option.
                ['Raycast']   = false;                                           -- Use the exact body surface under your mouse when available.
                ['Selection'] = 'Part';                                          -- Part picks a part center. Point picks a point inside that part.
                ['Axis']      = 'Center';                                        -- Center moves the point up/down. All lets it move in every direction.
                ['Sharpness'] = 0.65;                                            -- 1 reacts right away. Smaller numbers move the point more slowly.
                ['Reduce']    = {
                    ['Center'] = 0.45;                                           -- 0 allows the edges. 1 keeps the point in the middle.
                    ['All']    = 0.45;                                           -- Same edge limit, used when Axis is All.
                };
            };
        };
        ['Fov']        = {
            ['Method']    = '2d-Box';                                            -- 2d-Box uses the player's box. 2d-Circle uses a circle around your mouse.
            ['2d-Circle'] = {
                ['Visible'] = false;                                             -- Show this shape on your screen.
                ['Size']    = 100;                                               -- Circle radius in screen pixels.
                ['Color']   = {255, 255, 255};                                   -- Red, green and blue, from 0 to 255.
            };
        };
        -- Turn Aim Assist on or off. Default: M.
        ['Toggle']     = {
            ['Enabled'] = true;                                                  -- Use the on/off key for this feature.
            ['Holding'] = false;                                                 -- True means keep the button held. False means press once where this control allows it.
            ['Keybind'] = {'M', 'MouseButton2', 'Keyboard'};                     -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
        -- Default: hold Q while you want help aiming.
        ['Activation'] = {
            ['Holding']       = true;                                            -- Auto: true needs this button held; false runs by itself. Target: true holds the lock.
            ['Unlock Method'] = 'Normal';                                        -- Target only: Normal can unlock on the next press; Repeat picks again.
            ['Keybind']       = {'Q', 'MouseButton2', 'Keyboard'};               -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
    };

    -- Press shoot when an allowed player is under your mouse or inside your chosen shape.
    ['Triggerbot']         = {
        ['Enabled']     = true;                                                  -- Main on/off switch for this option.
        -- Use the player's expected next position for Triggerbot checks.
        ['Prediction']  = {
            ['Enabled'] = true;                                                  -- Main on/off switch for this option.
            ['Auto']    = true;                                                  -- Choose prediction time for you.
            ['Value']   = 0.121;                                                 -- Manual baseline in seconds. Speed and later ping changes adapt it without changing this number.
        };
        ['TargetOnly']  = false;                                                 -- Only let Triggerbot shoot Silent Aim's selected player.
        ['Delay']       = 0.1;                                                   -- How long to hold shoot after starting a shot, in seconds.
        ['RandomDelay'] = {0.1, 0.12};                                           -- Pick the hold time between these two numbers.
        ['SmartDelay']  = false;                                                 -- Use Delay plus a little extra hold time for distant players.
        ['DelayMethod'] = 'Random';                                              -- Normal uses Delay. Random uses RandomDelay.
        -- Turn Triggerbot on or off. Default: V.
        ['Toggle']      = {
            ['Enabled'] = true;                                                  -- Use the on/off key for this feature.
            ['Holding'] = false;                                                 -- True means keep the button held. False means press once where this control allows it.
            ['Keybind'] = {'V', 'MouseButton2', 'Keyboard'};                     -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
        -- Default: hold the right mouse button to let Triggerbot shoot.
        ['Activation']  = {
            ['Enabled'] = true;                                                  -- Use an activation button. False lets it run whenever Triggerbot is enabled.
            ['Holding'] = true;                                                  -- True: hold the button to shoot. False: press it to switch shooting on/off.
            ['Keybind'] = {'Q', 'MouseButton2', 'Mouse'};                        -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
        ['Fov']         = {
            ['Enabled']   = false;                                               -- False checks the actual body with Character tolerance. True uses your chosen shape.
            ['Character'] = 1.2;                                                 -- With FOV off: 1 is normal body size; 1.2 is 20% more mouse tolerance. The real body stays the same.
            ['Method']    = '2d-Box';                                            -- Choose 2d-Box or 2d-Circle when FOV is enabled.
            ['2d-Circle'] = {
                ['Visible'] = false;                                             -- Show this shape on your screen.
                ['Size']    = 50;                                                -- Circle radius in screen pixels.
                ['Color']   = {255, 255, 255};                                   -- Red, green and blue, from 0 to 255.
            };
        };
    };

    -- An empty list allows everyone. Assign someone to start filtering players.
    ['Whitelist']          = {
        ['Enabled']   = false;                                                   -- Main on/off switch for this option.
        ['Method']    = 'Friend';                                                -- With names assigned: Friend skips them; Target only targets them. Empty allows everyone.
        ['Players']   = {};                                                      -- Put Roblox user IDs in this list.
        ['AssignKey'] = {
            ['Keybind'] = {'R', 'MouseButton2', 'Keyboard'};                     -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
    };

    -- Show simple player boxes and names. There is no distance limit.
    ['ESP']                = {
        ['Enabled']      = true;                                                 -- Main on/off switch for this option.
        ['VisibleCheck'] = false;                                                -- Only show players when there is a clear view.
        ['Names']        = true;                                                 -- Show player names.
        ['KnockedCheck'] = true;                                                 -- Hide knocked players.
        ['DeadCheck']    = true;                                                 -- Hide dead players.
        ['Toggle']       = {
            ['Enabled'] = true;                                                  -- Use the on/off key for this feature.
            ['Holding'] = false;                                                 -- True means keep the button held. False means press once where this control allows it.
            ['Keybind'] = {'Z', 'MouseButton2', 'Keyboard'};                     -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
    };

    -- Boxes with fixed Height and Width around each character. Near characters and their boxes grow together; far ones shrink together.
    ['2d-Box']             = {
        ['Silent Aim'] = {
            ['Visible'] = true;                                                  -- Show this shape on your screen.
            ['Name']    = {true, 'DisplayName'};                                 -- First value shows the name. Second chooses DisplayName, Name, or UserId.
            ['Color']   = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};              -- First color is the box; second is its outline.
            ['Size']    = {['Height'] = 4.3; ['Width'] = 5};                     -- Fixed Height/Width around the character. The drawing follows perspective.
        };
        ['Aim Assist'] = {
            ['Visible'] = false;                                                 -- Show this shape on your screen.
            ['Name']    = {false, 'DisplayName'};                                -- First value shows the name. Second chooses DisplayName, Name, or UserId.
            ['Color']   = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};              -- First color is the box; second is its outline.
            ['Size']    = {['Height'] = 4.3; ['Width'] = 5};                     -- Fixed Height/Width around the character. The drawing follows perspective.
        };
        ['Triggerbot'] = {
            ['Visible'] = false;                                                 -- Show this shape on your screen.
            ['Name']    = {false, 'DisplayName'};                                -- First value shows the name. Second chooses DisplayName, Name, or UserId.
            ['Color']   = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};              -- First color is the box; second is its outline.
            ['Size']    = {['Height'] = 4.3; ['Width'] = 5};                     -- Fixed Height/Width around the character. The drawing follows perspective.
        };
    };

    -- Extra controls and small helper features.
    ['Misc']               = {
        ['AntiAfk']     = true;                                                  -- Help stop the game kicking you for standing idle.
        ['AntiFling']   = true;                                                  -- Try to stop other players throwing you around.
        -- Run the short macro shot sequence when its checks allow it.
        ['Macro Abuse'] = {
            ['Enabled']          = false;                                        -- Main on/off switch for this option.
            ['Triggerbot check'] = false;                                        -- Let Triggerbot shots start Macro Abuse too.
            ['Macro Check']      = true;                                         -- Only allow it when your recent movement is fast enough.
        };
        -- Stop the script and clean up its controls and drawings. Default: E.
        ['Panic']       = {
            ['Enabled'] = true;                                                  -- Main on/off switch for this option.
            ['Keybind'] = {'E', 'MouseButton2', 'Keyboard'};                     -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
        -- Try a quick reply when the script detects an opponent firing. Default: hold C.
        ['Prefire']     = {
            ['Enabled'] = false;                                                 -- Main on/off switch for this option.
            ['Range']   = 100;                                                   -- Only Prefire's working range. ESP has no distance limit.
            ['Delay']   = 0.25;                                                  -- Wait this many seconds before the reply shot.
            ['Holding'] = true;                                                  -- True means keep the button held. False means press once where this control allows it.
            ['Keybind'] = {'C', 'MouseButton2', 'Keyboard'};                     -- Keyboard key, mouse button, then which one to use: Keyboard or Mouse.
        };
    };

    -- Pick box Height/Width for each gun at Close, Medium and Far distances. ESP uses the same size.
    ['Gun Specifications'] = {
        ['Enabled']          = false;                                            -- Main on/off switch for this option.
        ['Ranges']           = {
            ['Close']  = 15;                                                     -- Up to this distance uses Close.
            ['Medium'] = 30;                                                     -- Up to this distance uses Medium.
            ['Far']    = 90;                                                     -- Up to this distance uses Far. Beyond it uses the normal box.
        };
        ['Revolver']         = {
            ['Close']  = {['BoxSize'] = {['Height'] = 5.1; ['Width'] = 5.1}};    -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Medium'] = {['BoxSize'] = {['Height'] = 5.5; ['Width'] = 5.5}};    -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Far']    = {['BoxSize'] = {['Height'] = 4.5; ['Width'] = 5}};      -- Character-relative Height/Width for this gun in this range; switches instantly.
        };
        ['Double-Barrel SG'] = {
            ['Close']  = {['BoxSize'] = {['Height'] = 6; ['Width'] = 7}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Medium'] = {['BoxSize'] = {['Height'] = 5; ['Width'] = 6}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 5}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
        };
        ['TacticalShotgun']  = {
            ['Close']  = {['BoxSize'] = {['Height'] = 7; ['Width'] = 7}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Medium'] = {['BoxSize'] = {['Height'] = 6; ['Width'] = 6}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 5}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
        };
        ['Shotgun']          = {
            ['Close']  = {['BoxSize'] = {['Height'] = 7; ['Width'] = 7}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Medium'] = {['BoxSize'] = {['Height'] = 6; ['Width'] = 6}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 5}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
        };
        ['Usp']              = {
            ['Close']  = {['BoxSize'] = {['Height'] = 6; ['Width'] = 5}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Medium'] = {['BoxSize'] = {['Height'] = 6; ['Width'] = 5}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 4}};        -- Character-relative Height/Width for this gun in this range; switches instantly.
        };
    };
};

-- Execution starts here. Table edits reuse this client session; new builds load normally.
local neoperroEnvironment = getgenv()
local neoperroRuntime = neoperroEnvironment.__neoperroRuntimeV1
if type(neoperroRuntime) == 'table' and neoperroRuntime.Alive
    and neoperroRuntime.Version == '1.3.22'
    and neoperroRuntime.Distribution == 'FlowAuth' and type(neoperroRuntime.ApplyConfig) == 'function' then
    script_key = nil -- Configuration updates use the already-running session.
    neoperroRuntime:ApplyConfig(neoperroEnvironment.neoperro)
    print(string.format('[neoperro] Table updated in %.2f ms.', neoperroRuntime.LastConfigMs))
else
    local started = os.clock()
    local source = game:HttpGet('https://flowauth.net/v1/loaders/56265b6f33860b070090db29d343e59a.lua')
    local fetched = os.clock()
    local program = loadstring(source, '@neoperro-loader')
    assert(type(program) == 'function', '[neoperro] Loader could not compile.')
    source = nil
    local compiled = os.clock()
    program(script_key)
    local finished = os.clock()
    print(string.format('[neoperro] Startup: download %.0f ms, loader compile %.0f ms, loader return %.0f ms.',
        (fetched - started) * 1000, (compiled - fetched) * 1000, (finished - compiled) * 1000))
end
