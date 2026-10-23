return {

    -- Silent targeting and prediction.
    ['Silent Aim'] = {
        ['Enabled'] = true;
        ['Prediction'] = {
            ['Enabled'] = true;
            ['Auto']    = true;
            ['Value']   = 0.128;
        };
        ['Resolver'] = {
            ['Enabled'] = true;
        };
        ['GroundShotCheck'] = true;
        ['Mode']            = 'Auto';
        ['Ignore']          = false;
        ['Target'] = {
            ['BasePart'] = 'UpperTorso';
            ['Closest'] = {
                ['Enabled']   = true;
                ['Raycast']   = false;
                ['Method']    = 'Part';
                ['Axis']      = 'Center';
                ['Sharpness'] = 0.7;
                ['Reduce'] = {
                    ['Center'] = 0.7;
                    ['All']    = 0.7;
                };
            };
        };
        ['Fov'] = {
            ['Mode'] = '2d-Box';
            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size']    = 50;
                ['Color']   = {255, 255, 255};
            };
        };
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'P', 'MouseButton2', 'Keyboard'};
        };
        ['Activation'] = {
            ['Holding']     = false;
            ['Unlock Mode'] = 'Repeat';
            ['Keybind']     = {'T', 'MouseButton2', 'Keyboard'};
        };
        ['AntiCurve'] = {
            ['Enabled'] = false;
            ['Mode']    = '3d-angles';
            ['3d-angles'] = {
                ['Max'] = 2.2; -- Studs: 0.000000001 or larger; math.huge = unlimited.
            };
            ['Endmath'] = {
                ['Radius']    = 120; -- Pixels: 0.000000001 or larger; math.huge = unlimited.
                ['WallCheck'] = true;
            };
        };
    };

    -- Camera/mouse assistance; hold its Activation input in Auto.
    ['Aim Assist'] = {
        ['Enabled'] = true;
        ['Prediction'] = {
            ['Enabled'] = true;
            ['Auto']    = true;
            ['Value']   = 0.121;
        };
        ['Mode']   = 'Auto';
        ['Ignore'] = false;
        ['Follow']     = 'Camera';
        ['Smoothness'] = 0.0068;
        ['Target'] = {
            ['BasePart'] = 'UpperTorso';
            ['Closest'] = {
                ['Enabled']   = true;
                ['Raycast']   = false;
                ['Method']    = 'Part';
                ['Axis']      = 'Center';
                ['Sharpness'] = 0.65;
                ['Reduce'] = {
                    ['Center'] = 0.45;
                    ['All']    = 0.45;
                };
            };
        };
        ['Fov'] = {
            ['Mode'] = '2d-Box';
            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size']    = 100;
                ['Color']   = {255, 255, 255};
            };
        };
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'M', 'MouseButton2', 'Keyboard'};
        };
        ['Activation'] = {
            ['Holding']     = true;
            ['Unlock Mode'] = 'Normal';
            ['Keybind']     = {'Q', 'MouseButton2', 'Keyboard'};
        };
    };

    -- V arms/disarms; hold RMB. SmartDelay adds a distance-based hold, not a reaction delay.
    ['Triggerbot'] = {
        ['Enabled'] = true;
        ['Prediction'] = {
            ['Enabled'] = true;
            ['Auto']    = true;
            ['Value']   = 0.121;
        };
        ['TargetOnly'] = false;
        ['Delay']       = 0.1;
        ['RandomDelay'] = {0.1, 0.12};
        ['SmartDelay']  = false;
        ['DelayMode']   = 'Random';
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'V', 'MouseButton2', 'Keyboard'};
        };
        ['Activation'] = {
            ['Enabled'] = true;
            ['Holding'] = true;
            ['Keybind'] = {'Q', 'MouseButton2', 'Mouse'};
        };
        ['Fov'] = {
            ['Enabled']   = false;
            ['Character'] = 1.2; -- FOV off: 1 = native body/HB; 1.2 = 20% larger, 0.8 = 20% smaller. Local only.
            ['Mode'] = '2d-Box';
            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size']    = 50;
                ['Color']   = {255, 255, 255};
            };
        };
    };

    -- Silent vertical behavior. Auto ignores JumpOffset.
    ['Y-Axis'] = {
        ['Enabled']    = false;
        ['Mode']       = 'Auto';
        ['JumpOffset'] = 1.0;
        ['SilentAim']  = true;
    };

    -- Row order: Silent Aim, Aim Assist, Triggerbot.
    ['Checks'] = {
        ['Dead']       = {true, true, true};
        ['Knocked']    = {true, true, true};
        ['Wall']       = {true, true, true};
        ['ForceField'] = {true, true, false};
        ['Crew']       = {false, false, false};
        ['Tool']       = {false, true, true};
    };

    -- Friend excludes assigned players; Target includes only them.
    ['Whitelist'] = {
        ['Enabled'] = false;
        ['Mode']    = 'Friend';
        ['Players'] = {};
        ['AssignKey'] = {
            ['Keybind'] = {'R', 'MouseButton2', 'Keyboard'};
        };
    };

    -- Enable and equip a supported gun. Ranges are upper bounds; beyond Far uses general size.
    ['Gun Specifications'] = {
        ['Enabled'] = false;
        ['Ranges'] = {
            ['Close']  = 15;
            ['Medium'] = 30;
            ['Far']    = 90;
        };
        ['Revolver'] = {
            ['Close']  = {['BoxSize'] = {5.1, 5.1}};
            ['Medium'] = {['BoxSize'] = {5.5, 5.5}};
            ['Far']    = {['BoxSize'] = {5, 4.5}};
        };
        ['Double-Barrel SG'] = {
            ['Close']  = {['BoxSize'] = {7, 6}};
            ['Medium'] = {['BoxSize'] = {6, 5}};
            ['Far']    = {['BoxSize'] = {5, 5}};
        };
        ['TacticalShotgun'] = {
            ['Close']  = {['BoxSize'] = {7, 7}};
            ['Medium'] = {['BoxSize'] = {6, 6}};
            ['Far']    = {['BoxSize'] = {5, 5}};
        };
        ['Shotgun'] = {
            ['Close']  = {['BoxSize'] = {7, 7}};
            ['Medium'] = {['BoxSize'] = {6, 6}};
            ['Far']    = {['BoxSize'] = {5, 5}};
        };
        ['Usp'] = {
            ['Close']  = {['BoxSize'] = {5, 6}};
            ['Medium'] = {['BoxSize'] = {5, 6}};
            ['Far']    = {['BoxSize'] = {4, 5}};
        };
    };

    -- Player overlays; hide knocked/dead targets with the checks below.
    ['ESP'] = {
        ['Enabled']      = true;
        ['VisibleCheck'] = false;
        ['Names']        = true;
        ['KnockedCheck'] = true;
        ['DeadCheck']    = true;
        ['MaxDistance']  = 5050;
        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'Z', 'MouseButton2', 'Keyboard'};
        };
    };

    -- Feature box sizes in studs; visibility does not change selection.
    ['2d-Box'] = {
        ['Silent Aim'] = {
            ['Visible']            = true;
            ['Predicted Position'] = true;
            ['Name']               = {true, 'DisplayName'};
            ['Color']              = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size']               = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance']       = 5050;
            ['Filled']             = false;
            ['Transparency']       = 1;
        };
        ['Aim Assist'] = {
            ['Visible']            = false;
            ['Predicted Position'] = true;
            ['Name']               = {false, 'DisplayName'};
            ['Color']              = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size']               = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance']       = 5050;
            ['Filled']             = false;
            ['Transparency']       = 1;
        };
        ['Triggerbot'] = {
            ['Visible']            = false;
            ['Predicted Position'] = true;
            ['Name']               = {false, 'DisplayName'};
            ['Color']              = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size']               = {['Width'] = 5; ['Height'] = 4.3};
            ['Max Distance']       = 5050;
            ['Filled']             = false;
            ['Transparency']       = 1;
        };
    };

    -- Local native tracer appearance only.
    ['Client Bullets'] = {
        ['Enabled'] = true;
    };

    -- Keep the confirmed shot/restoration path.
    ['Anti-AimViewer'] = {
        ['Enabled'] = true;
    };

    -- Extra controls. Triggerbot check permits Macro Abuse after TB shots.
    ['Misc'] = {
        ['AntiAfk']   = true;
        ['AntiFling'] = true;
        ['Macro Abuse'] = {
            ['Enabled']      = false;
            ['Triggerbot check'] = false;
            ['Macro Check']  = true;
        };
        ['Panic'] = {
            ['Enabled'] = true;
            ['Keybind'] = {'E', 'MouseButton2', 'Keyboard'};
        };
        ['Prefire'] = {
            ['Enabled'] = false;
            ['Range']   = 100;
            ['Delay']   = 0.25;
            ['Holding'] = true;
            ['Keybind'] = {'C', 'MouseButton2', 'Keyboard'};
        };
    };
}
