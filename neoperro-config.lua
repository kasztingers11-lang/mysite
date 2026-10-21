getgenv()['neoperro'] = {

    ['Games'] = {
        ['Da Strike'] = 134196333708867;
        ['Da Uphill'] = 71324444457408;
        ['Da Downhill'] = 139144803593140;
    };

    ['Anti-AimViewer'] = {
        ['Enabled'] = true;
    };

    ['Y-Axis'] = {
        ['Enabled'] = false;
        ['Mode'] = 'Auto';
        ['JumpOffset'] = 1.0;
        ['SilentAim'] = true;
        ['AimAssist'] = false;
    };

    ['Checks'] = {
        ['Dead']       = {true, true, true};
        ['Knocked']    = {true, true, true};
        ['Wall']       = {true, true, true};
        ['ForceField'] = {true, true, false};
        ['Crew']       = {false, false, false};
        ['Tool']       = {false, true, true};
    };

    ['Silent Aim'] = {
        ['Enabled'] = true;
        ['Mode'] = 'Auto';
        ['Ignore'] = false;

        ['Part'] = 'UpperTorso';
        ['Method'] = 'Part';
        ['Axis'] = 'Center';
        ['PointReduction'] = 0.7;

        ['Fov'] = {
            ['Mode'] = '2d-Box';

            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size'] = 50;
                ['Color'] = {255, 255, 255};
            };

            ['2d-Box'] = {
                ['Visible'] = false;
                ['Size'] = {
                    ['X'] = 100;
                    ['Y'] = 100;
                };
                ['Color'] = {255, 255, 255};
            };
        };

        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'P', 'MouseButton2', 'Keyboard'};
        };

        ['Keybind Mode'] = {
            ['Holding'] = false;
            ['Unlock Mode'] = 'Repeat';
            ['Keybind'] = {'T', 'MouseButton2', 'Keyboard'};
        };

        ['AntiCurve'] = {
            ['Enabled'] = false;
            ['Mode'] = '3d-angles';

            ['3d-angles'] = {
                ['MaxAngle'] = 4;
            };

            ['endmath'] = {
                ['Radius'] = 120;
            };
        };
    };

    ['Aim Assist'] = {
        ['Enabled'] = true;
        ['Mode'] = 'Target';
        ['Ignore'] = false;

        ['Follow'] = 'Camera';
        ['Smoothness'] = 0.0068;

        ['Part'] = 'UpperTorso';
        ['Method'] = 'Part';
        ['Axis'] = 'Center';
        ['PointReduction'] = 0.45;

        ['Fov'] = {
            ['Mode'] = '2d-Box';

            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size'] = 100;
                ['Color'] = {255, 255, 255};
            };

            ['2d-Box'] = {
                ['Visible'] = false;
                ['Size'] = {
                    ['X'] = 200;
                    ['Y'] = 200;
                };
                ['Color'] = {255, 255, 255};
            };
        };

        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'M', 'MouseButton2', 'Keyboard'};
        };

        ['Keybind Mode'] = {
            ['Holding'] = false;
            ['Unlock Mode'] = 'Normal';
            ['Keybind'] = {'Q', 'MouseButton2', 'Keyboard'};
        };
    };

    ['Prediction'] = {
        ['SilentAim'] = 0.128;
        ['AimAssist'] = 0.121;
        ['Triggerbot'] = 0.132;
    };

    ['EndMath'] = {
        ['VelocityHistory'] = true;
        ['WallCheck'] = true;
        ['Visualizer'] = false;
    };

    ['Whitelist'] = {
        ['Enabled'] = false;
        ['Mode'] = 'Friend';
        ['Players'] = {};

        ['AssignKey'] = {
            ['Keybind'] = {'R', 'MouseButton2', 'Keyboard'};
        };

        ['ClearKey'] = {
            ['Keybind'] = {'F', 'MouseButton2', 'Keyboard'};
        };

        ['ToggleModeKey'] = {
            ['Keybind'] = {'B', 'MouseButton2', 'Keyboard'};
        };
    };

    ['Triggerbot'] = {
        ['Enabled'] = true;
        ['TargetOnly'] = false;

        ['Delay'] = 0.1;
        ['RandomDelay'] = {0.1, 0.12};
        ['SmartDelay'] = false;
        ['DelayMode'] = 'Random';

        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = true;
            ['Keybind'] = {'V', 'MouseButton2', 'Keyboard'};
        };
    };

    ['ESP'] = {
        ['Enabled'] = true;
        ['VisibleCheck'] = false;
        ['Names'] = true;
        ['MaxDistance'] = 5050;

        ['Toggle'] = {
            ['Enabled'] = true;
            ['Holding'] = false;
            ['Keybind'] = {'Z', 'MouseButton2', 'Keyboard'};
        };

        ['2d-Box'] = {
            ['Filled'] = false;
            ['Transparency'] = 1;
            ['PredictedPos'] = false;
        };
    };

    ['Gun Specifications'] = {
        ['Enabled'] = false;

        ['Ranges'] = {
            ['Close'] = 15;
            ['Medium'] = 30;
            ['Far'] = 90;
        };

        ['Revolver'] = {
            ['Close'] = {['BoxSize'] = {5, 6}; ['Prediction'] = 0.128};
            ['Medium'] = {['BoxSize'] = {5, 6}; ['Prediction'] = 0.130};
            ['Far'] = {['BoxSize'] = {4, 5}; ['Prediction'] = 0.135};
        };

        ['Double-Barrel SG'] = {
            ['Close'] = {['BoxSize'] = {7, 6}; ['Prediction'] = 0.132};
            ['Medium'] = {['BoxSize'] = {6, 5}; ['Prediction'] = 0.138};
            ['Far'] = {['BoxSize'] = {5, 5}; ['Prediction'] = 0.145};
        };

        ['TacticalShotgun'] = {
            ['Close'] = {['BoxSize'] = {7, 7}; ['Prediction'] = 0.128};
            ['Medium'] = {['BoxSize'] = {6, 6}; ['Prediction'] = 0.133};
            ['Far'] = {['BoxSize'] = {5, 5}; ['Prediction'] = 0.140};
        };

        ['Shotgun'] = {
            ['Close'] = {['BoxSize'] = {7, 7}; ['Prediction'] = 0.128};
            ['Medium'] = {['BoxSize'] = {6, 6}; ['Prediction'] = 0.133};
            ['Far'] = {['BoxSize'] = {5, 5}; ['Prediction'] = 0.140};
        };

        ['Usp'] = {
            ['Close'] = {['BoxSize'] = {5, 6}; ['Prediction'] = 0.122};
            ['Medium'] = {['BoxSize'] = {5, 6}; ['Prediction'] = 0.125};
            ['Far'] = {['BoxSize'] = {4, 5}; ['Prediction'] = 0.130};
        };
    };

    ['Client Bullets'] = {
        ['Enabled'] = false;
        ['RequireTarget'] = true;

        ['Guns'] = {
            'Usp';
            'TacticalShotgun';
            'Double-Barrel SG';
            'Revolver';
        };
    };

    ['Misc'] = {
        ['AntiAfk'] = true;
        ['AntiFling'] = true;

        ['Macro Abuse'] = {
            ['Enabled'] = false;
            ['Work With TB'] = false;
        };

        ['Panic'] = {
            ['Keybind'] = {'E', 'MouseButton2', 'Keyboard'};
        };

        ['Prefire'] = {
            ['Enabled'] = false;
            ['Range'] = 100;
            ['Delay'] = 0.25;
            ['Holding'] = true;
            ['Keybind'] = {'C', 'MouseButton2', 'Keyboard'};
        };
    };
};
