getgenv()['neoperro'] = {
    ['Checks']             = {
        ['Dead']            = {true, true, true};
        ['Knocked']         = {true, true, true};
        ['Wall']            = {true, true, true};
        ['ForceField']      = {true, true, false};
        ['Crew']            = {false, false, false};
        ['Tool']            = {false, true, true};
        ['GroundShotCheck'] = {true, true, true};
    };

    ['Y-Axis']             = {
        ['Enabled']    = false;
        ['Method']     = 'Auto';
        ['Offset']     = 1.0;
        ['SilentAim']  = true;
        ['Aim Assist'] = true;
        ['Triggerbot'] = true;
    };

    ['Resolver']           = {
        ['Enabled'] = true;
    };

    ['Anti-AimViewer']     = {
        ['Enabled'] = true;
    };

    ['Client Bullets']     = {
        ['Enabled'] = true;
    };

    ['Silent Aim']         = {
        ['Enabled']    = true;
        ['Prediction'] = {
            ['Enabled'] = true;
            ['Auto']    = true;
            ['Value']   = 0.128;
        };
        ['Method']     = 'Auto';
        ['Ignore']     = false;
        ['Target']     = {
            ['BasePart'] = 'UpperTorso';
            ['Closest']  = {
                ['Enabled']   = true;
                ['Raycast']   = false;
                ['Selection'] = 'Part';
                ['Axis']      = 'Center';
                ['Sharpness'] = 0.7;
                ['Reduce']    = {
                    ['Center'] = 0.7;
                    ['All']    = 0.7;
                };
            };
        };
        ['Fov']        = {
            ['Method']    = '2d-Box';
            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size']    = 50;
                ['Color']   = {255, 255, 255};
            };
        };
        ['Toggle']     = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'P', 'MouseButton2', 'Keyboard'};
        };
        ['Activation'] = {
            ['Holding']       = false;
            ['Unlock Method'] = 'Repeat';
            ['Keybind']       = {'T', 'MouseButton2', 'Keyboard'};
        };
        ['AntiCurve']  = {
            ['Enabled']   = false;
            ['Method']    = '3d-angles';
            ['3d-angles'] = {
                ['Max'] = 2.2;
            };
            ['Endmath']   = {
                ['Radius']    = 120;
                ['WallCheck'] = true;
            };
        };
    };

    ['Aim Assist']         = {
        ['Enabled']    = true;
        ['Prediction'] = {
            ['Enabled'] = true;
            ['Auto']    = true;
            ['Value']   = 0.121;
        };
        ['Method']     = 'Auto';
        ['Follow']     = 'Camera';
        ['Smoothness'] = 0.0068;
        ['Target']     = {
            ['BasePart'] = 'UpperTorso';
            ['Closest']  = {
                ['Enabled']   = true;
                ['Raycast']   = false;
                ['Selection'] = 'Part';
                ['Axis']      = 'Center';
                ['Sharpness'] = 0.65;
                ['Reduce']    = {
                    ['Center'] = 0.45;
                    ['All']    = 0.45;
                };
            };
        };
        ['Fov']        = {
            ['Method']    = '2d-Box';
            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size']    = 100;
                ['Color']   = {255, 255, 255};
            };
        };
        ['Toggle']     = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'M', 'MouseButton2', 'Keyboard'};
        };
        ['Activation'] = {
            ['Holding']       = true;
            ['Unlock Method'] = 'Normal';
            ['Keybind']       = {'Q', 'MouseButton2', 'Keyboard'};
        };
    };

    ['Triggerbot']         = {
        ['Enabled']     = true;
        ['Prediction']  = {
            ['Enabled'] = true;
            ['Auto']    = true;
            ['Value']   = 0.121;
        };
        ['TargetOnly']  = false;
        ['Delay']       = 0.1;
        ['RandomDelay'] = {0.1, 0.12};
        ['SmartDelay']  = false;
        ['DelayMethod'] = 'Random';
        ['Toggle']      = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'V', 'MouseButton2', 'Keyboard'};
        };
        ['Activation']  = {
            ['Enabled'] = true;
            ['Holding'] = true;
            ['Keybind'] = {'Q', 'MouseButton2', 'Mouse'};
        };
        ['Fov']         = {
            ['Enabled']   = false;
            ['Character'] = 1.2;
            ['Method']    = '2d-Box';
            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size']    = 50;
                ['Color']   = {255, 255, 255};
            };
        };
    };

    ['Whitelist']          = {
        ['Enabled']   = false;
        ['Method']    = 'Friend';
        ['Players']   = {};
        ['AssignKey'] = {
            ['Keybind'] = {'R', 'MouseButton2', 'Keyboard'};
        };
    };

    ['ESP']                = {
        ['Enabled']      = true;
        ['VisibleCheck'] = false;
        ['Names']        = true;
        ['KnockedCheck'] = true;
        ['DeadCheck']    = true;
        ['Toggle']       = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'Z', 'MouseButton2', 'Keyboard'};
        };
    };

    ['2d-Box']             = {
        ['Silent Aim'] = {
            ['Visible'] = true;
            ['Name']    = {true, 'DisplayName'};
            ['Color']   = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size']    = {['Height'] = 4.3; ['Width'] = 5};
        };
        ['Aim Assist'] = {
            ['Visible'] = false;
            ['Name']    = {false, 'DisplayName'};
            ['Color']   = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size']    = {['Height'] = 4.3; ['Width'] = 5};
        };
        ['Triggerbot'] = {
            ['Visible'] = false;
            ['Name']    = {false, 'DisplayName'};
            ['Color']   = {['Box'] = {{255, 255, 255}, {0, 0, 0}}};
            ['Size']    = {['Height'] = 4.3; ['Width'] = 5};
        };
    };

    ['Misc']               = {
        ['AntiAfk']     = true;
        ['AntiFling']   = true;
        ['Macro Abuse'] = {
            ['Enabled']          = false;
            ['Triggerbot check'] = false;
            ['Macro Check']      = true;
        };
        ['Panic']       = {
            ['Enabled'] = true;
            ['Keybind'] = {'E', 'MouseButton2', 'Keyboard'};
        };
        ['Prefire']     = {
            ['Enabled'] = false;
            ['Range']   = 100;
            ['Delay']   = 0.25;
            ['Holding'] = true;
            ['Keybind'] = {'C', 'MouseButton2', 'Keyboard'};
        };
    };

    ['Gun Specifications'] = {
        ['Enabled']          = false;
        ['Ranges']           = {
            ['Close']  = 15;
            ['Medium'] = 30;
            ['Far']    = 90;
        };
        ['Revolver']         = {
            ['Close']  = {['BoxSize'] = {['Height'] = 5.1; ['Width'] = 5.1}};
            ['Medium'] = {['BoxSize'] = {['Height'] = 5.5; ['Width'] = 5.5}};
            ['Far']    = {['BoxSize'] = {['Height'] = 4.5; ['Width'] = 5}};
        };
        ['Double-Barrel SG'] = {
            ['Close']  = {['BoxSize'] = {['Height'] = 6; ['Width'] = 7}};
            ['Medium'] = {['BoxSize'] = {['Height'] = 5; ['Width'] = 6}};
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 5}};
        };
        ['TacticalShotgun']  = {
            ['Close']  = {['BoxSize'] = {['Height'] = 7; ['Width'] = 7}};
            ['Medium'] = {['BoxSize'] = {['Height'] = 6; ['Width'] = 6}};
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 5}};
        };
        ['Shotgun']          = {
            ['Close']  = {['BoxSize'] = {['Height'] = 7; ['Width'] = 7}};
            ['Medium'] = {['BoxSize'] = {['Height'] = 6; ['Width'] = 6}};
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 5}};
        };
        ['Usp']              = {
            ['Close']  = {['BoxSize'] = {['Height'] = 6; ['Width'] = 5}};
            ['Medium'] = {['BoxSize'] = {['Height'] = 6; ['Width'] = 5}};
            ['Far']    = {['BoxSize'] = {['Height'] = 5; ['Width'] = 4}};
        };
    };
};
