-- // [[ test config ]] -- \\

getgenv()['goodnight'] = {

    ['Script Key'] = { "NSkGievVXcRvBQIRmEAxIXTDphxLqYHc" };

    ['Settings'] = {
        ['Webhook'] = "webhook_here";
        ['Web Configs'] = false; --[[ Will use your configs from the website dashboard ]]
        ['Performance Mode'] = {
            ['Enabled'] = true;
            ['Processing'] = false;
            ['ActiveGun'] = true;
        };
    };

    ['Silent Aim'] = {
        ['Enabled'] = true;
        ['Set As Aim Assist Target'] = false; -- [[ will set the Silent Aim's target to whatever aimassist is targetting ]]
        ['HitChance'] = {true, 16767676767};
        ['Prediction'] = {
            ['Enabled'] = true;
            ['Auto Prediction'] = false; --[[ will use your bullet speed, ping, client to server network delay to give the best prediction ]]
            ['Value'] = 0.122; --[[ ignore if you're using Auto Prediction ]]
        };
 
        ['Anti Aim Viewer'] = true;

        ['Target'] = {
            ['BasePart'] = 'UpperTorso';
            ['Closest'] = {
                ['Enabled'] = true;
                ['Raycast'] = false --[[ ignores Reduce and gives 1:1 position when mouse on target ]];
                ['Method'] = 'Part' --[[ 'Part' or 'Point']];
                ['Axis'] = 'Center' --[[ ('Center' = only y-axis) ('All' = xyz-axis) ]];
                ['Sharpness'] = 0.65 --[[Sharpness (1 = max) (0.5 = mid) (0.01 = slowest)]];
                ['Reduce'] = { --[[ how far from the edge do you want the point to stay (0 means it’ll stick to edges) ]]
                    ['Center'] = 0.7;
                    ['All'] = 0.7;
                }
            };
        };

        ['Toggle'] = { --[[ this will turn your silent on or off ]]
            ['Enabled'] = false;
            ['Need Holding'] = false;
            ['Input'] = {'P', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};

            ['Notification'] = {
                ['Enabled'] = true;  --[[ turn this off if you only want sound ]]
                ['Sound'] = true;
                ['Duration'] = 1;
                ['Volume'] = 0.5;
                ['Color'] = {188, 188, 188};
                ['Sound Id'] = {112910579737497, 4064874742} --[[ Enabled Sound, Disabled Sound ]]
            }
        };

        ['Keybind Mode'] = { --[[ this will turn your silent into toggle-mode which wont't lock automatically anymore ]]
            ['Enabled'] = false;
            ['Need Holding'] = false;
            ['Unlock Mode'] = 'Repeat'; --[[ ('Normal' = lock/unlock) ('Repeat' = only unlocks if outside of all boxs) ]]
            ['Input'] = {'T', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};

            ['Notification'] = {
                ['Enabled'] = false;
                ['Duration'] = 1;
                ['Color'] = {188, 188, 188};
            }
        };

        ['Fov'] = {
            ['Mode'] = '2d-Box' --[[ '2d-Box', '3d-Box', '2d-Circle' ]];

            ['2d-Circle'] = {
                ['Visible'] = true;
                ['Size'] = {50, 'Global' --[[ ('Normal' uses very precise) ('Global' uses same as all other fov's) ]]};
                ['Transparency'] = { ['Circle'] = 0.8, ['Outline'] = 0 };
                ['Color'] = {
                    ['Spin'] = {false, 5};
                    ['Circle'] = { {188, 188, 188}, {188, 188, 188} };
                    ['Outline'] = { {0, 0, 0}, {188, 188, 188}, {0, 0, 0} };
                };
                ['Text Information'] = {
                    ['Visible'] = false;
                    ['Transparency'] = 0;
                    ['Color'] = { {188, 188, 188}, {0, 0, 0} };
                    ['Size'] = {0.3, 0.15};
                    ['Position'] = {0.5, 0.75};
                    ['Configuration'] = {
                        ['Target'] = true;
                        ['Health'] = true;
                        ['Anti Lock'] = true --[[requires "Detection" resolver method]];
                    };
                };
            };

            ['2d-Box'] = {
                ['Visibility'] = 'Never'--[[ 'Always on', 'Only Targetting', 'Never']];
                ['Targetting Color'] = {3, 252, 111};
            };

            ['3d-Box'] = {
                ['Transparency'] = 0.7;
                ['Material'] = 'SmoothPlastic';
                ['Color'] = {129, 247, 140};
                ['Size'] = {
                    ['X'] = 4;
                    ['Y'] = 6;
                    ['Z'] = 2;
                };
            };

            ['HighLight'] = {
                ['Enabled'] = false;
                ['Color'] = { {161, 166, 190}, {188, 188, 188} };
                ['Transparency'] = { 0.4, 0 };
            };
        };

        ['Checks'] = {
            ['Anti Ground Shots'] = true;
            ['Visibility'] = true;
            ['Knocked'] = true;
            ['Crew Check'] = false;
            ['ForceField'] = true;
            ['Grabbed'] = true;
        };

        ['Anti Curve'] = {
            ['Enabled'] = false;
            ['Debug Output'] = false; --[[ prints the output in console ]]
            ['Use Closest Point'] = true; --[[ hardly recommended ]]
            ['Method'] = '3d-Angles'; --[[ '3d-Angles', 'Pixels', '1:1']]
            ['Angles'] = {
                ['Max'] = 4;
                ['Dynamic Distance'] = {
                    ['Enabled'] = false;
                    ['Distance'] = 30;
                    ['Min - Max'] = {6.5, 9.0}
                };
            };
        };
    };

    ['Aim Assist'] = {
        ['Enabled'] = true;
        ['Follow Mode'] = 'Camera';
        ['Smoothness'] = {true, 0.009152542};
        ['Prediction'] = {
            ['Enabled'] = true;
            ['Auto Prediction'] = true; 
            ['Value'] = 0.1223;
        };

        ['Target'] = {
            ['BasePart'] = 'UpperTorso';
            ['Closest'] = {
                ['Enabled'] = false;
                ['Raycast'] = false --[[ ignores Reduce and gives 1:1 position when mouse on target ]];
                ['Method'] = 'Part' --[[ 'Part' or 'Point']];
                ['Axis'] = 'Center' --[[ ('Center' = only y-axis) ('All' = xyz-axis) ]];
                ['Sharpness'] = 1 --[[Sharpness (1 = max) (0.5 = mid) (0.01 = slowest)]];
                ['Reduce'] = { --[[ how far from the edge do you want the point to stay (0 means it’ll stick to edges) ]]
                    ['Center'] = 0.45;
                    ['All'] = 0.7;
                }
            };
        };

        ['Keybind Mode'] = { --[[ this will turn your Aimassist into toggle-mode which wont't lock automatically anymore ]]
            ['Enabled'] = true;
            ['Need Holding'] = true;
            ['Input'] = {'Q', 'MouseButton2', ('Mouse'--[['Keyboard', 'Mouse']])};

            ['Notification'] = {
                ['Enabled'] = false;
                ['Duration'] = 1;
                ['Color'] = {188, 188, 188};
            }
        };

        ['Toggle'] = { --[[ this will turn your aimassist on or off ]]
            ['Enabled'] = false;
            ['Need Holding'] = false;
            ['Input'] = {'M', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};

            ['Notification'] = {
                ['Enabled'] = true;  --[[ turn this off if you only want sound ]]
                ['Sound'] = true;
                ['Duration'] = 1;
                ['Volume'] = 0.5;
                ['Color'] = {188, 188, 188};
                ['Sound Id'] = {112910579737497, 4064874742} --[[ Enabled Sound, Disabled Sound ]]
            }
        };

        ['Fov'] = {
            ['Mode'] = '2d-Circle';

            ['2d-Circle'] = {
                ['Visible'] = false;
                ['Size'] = {100, 'Global' --[[ ('Normal' uses very precise) ('Global' uses same as all other fov's) ]]};
                ['Transparency'] = { ['Circle'] = 0.8, ['Outline'] = 0 };
                ['Color'] = {
                    ['Spin'] = {false, 5};
                    ['Circle'] = { {172, 193, 232}, {172, 193, 232} };
                    ['Outline'] = { {0, 0, 0}, {172, 193, 232}, {0, 0, 0} };
                };
                ['Text Information'] = {
                    ['Visible'] = false;
                    ['Transparency'] = 0;
                    ['Color'] = { {172, 193, 232}, {0, 0, 0} };
                    ['Size'] = {0.3, 0.15};
                    ['Position'] = {0.5, 0.85};
                    ['Configuration'] = {
                        ['Target'] = true;
                        ['Health'] = true;
                        ['Anti Lock'] = true --[[requires "Detection" resolver method]];
                    };
                };
            };

            ['HighLight'] = {
                ['Enabled'] = false;
                ['Color'] = { {161, 166, 190}, {172, 193, 232} };
                ['Transparency'] = { 0.4, 0 };
            };
        };

        ['Checks'] = {
            ['First Person'] = true;
            ['Third Person'] = true;
            ['Visibility'] = true;
            ['Knocked'] = true;
            ['Crew Check'] = false;
            ['ForceField'] = true;
            ['Grabbed'] = true;
            ['Tool'] = true;
        };

        ['EasingStyle'] = {
            ['Position'] = {
                ['In'] = 'Sine';
                ['Out'] = 'Sine';
            };

            ['Rotation'] = {
                ['In'] = 'Linear';
                ['Out'] = 'Linear';
            };
        };

        ['Apply Shake'] = {
            ['Enabled'] = false;
            ['Randomized'] = false;
            ['Axis'] = {15, 15, 15};
        };
    };

    ['Rage Section'] = {
        ['Bullet Tp'] = false;
    };

    ['Resolver'] = {
        ['Enabled'] = true;
        ['Powerup'] = false --[[ use only if you need to resolve something crazy ]];
        ['Method'] = 'TrueVelocity' --[['Detection', 'TrueVelocity']];
    };

    ['Box Settings'] = {
        ['2d-Box'] = {
            ['Silent Aim'] = {
                ['Predicted Position'] = false;
                ['Name'] = {true, 'DisplayName' --[[ 'DisplayName' or 'Name']]};
                ['Color'] = { ['Box'] = {{255, 255, 255}, {0, 0, 0}} };
                ['Size'] = { ['Width'] = 5; ['Height'] = 4.3};
                ['Max Distance'] = 5050;
                ['Extras'] = { ['Filled'] = false; ['Transparency'] = 1 };
                ['Checks'] = {
                    ['Knocked'] = true;
                    ['WallCheck'] = true;
                    ['Crew Check'] = false;
                };
            };

            ['TriggerBot'] = {
                ['Predicted Position'] = false;
                ['Name'] = {true, 'DisplayName' --[[ 'DisplayName' or 'Name']]};
                ['Color'] = { ['Box'] = {{119, 52, 235}, {0, 0, 0}} };
                ['Size'] = { ['Width'] = 5; ['Height'] = 4};
                ['Max Distance'] = 150;
                ['Extras'] = { ['Filled'] = false; ['Transparency'] = 1 };
                ['Checks'] = {
                    ['Knocked'] = true;
                    ['WallCheck'] = true;
                    ['Crew Check'] = false;
                };
            };
        }
    };

    ['Raid Awareness'] = {
        ['Enabled'] = false;
        ['Target Mode'] = 'Multiple' --[[ 'Single', 'Multiple' ]];
        ['Modification'] = {
            ['Allies'] = {'Allies', {0, 153, 255}};
            ['Target'] = {'Target', {255, 0, 4}};
        };
        ['Toggle'] = { --[[ this will make it select targets ]]
            ['Enabled'] = true;
            ['Input'] = {'P', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};

            ['Notification'] = {
                ['Enabled'] = true;  --[[ turn this off if you only want sound ]]
                ['Sound'] = true;
                ['Duration'] = 1;
                ['Volume'] = 0.5;
                ['Color'] = {188, 188, 188};
                ['Sound Id'] = {112910579737497, 4064874742} --[[ Enabled Sound, Disabled Sound ]]
            }
        };
    };

    ['Endmath Modifier'] = {
        ['Velocity History'] = true; --[[ Records velocity history and gives better prediction ]]
        ['WallCheck'] = false;

        ['Anti Curve'] = {
            ['Enabled'] = true;
            ['Radius'] = 95;
        };

        ['Custom Y-Axis'] = {
            ['Enabled'] = true;
            ['Mode'] = 'Mid Legit'; --[[ 'Very Legit', 'Mid Legit' (RECOMMENDED), 'Normal Legit' ]]
            ['Jumping Offset'] = 0.87; --[[ does multiplication, 0.9 = it will shoot a bit under, 1.1 = shoots a bit over, 1 = default ]]
            ['Allowed'] = {
                ['Silent Aim'] = true;
                ['Aim Assist'] = false;
            }
        };

        ['Visualizer'] = {
            ['Enabled'] = false;
            ['Thickness'] = 2;
            ['Transparency'] = 1;
            ['Color'] = {200, 200, 200}
        };
    };

    ['TriggerBot'] = {
        ['Enabled'] = true;
        ['Prediction'] = {
            ['Value'] = 0.12;
        };
        ['Limits'] = {
            ['Target Only'] = {  -- [[ only fires when its detected target matches the Silent Aim/Aim Assist target ]]
                ['Enabled'] = false;
                ['Mode'] = 'Silent Aim'; --[[ 'Silent Aim', 'Aim Assist' ]]
            };
        };
        ['Fov'] = {
            ['Enabled'] = false --[[ this will determine if you wan't to use fov or normal character ]];

            ['2d-Box'] = {
                ['Visibility'] = 'Never'--[[ 'Always on', 'Only Targetting', 'Never']];
                ['Targetting Color'] = {52, 198, 235};
            };
        };
        ['Delay'] = {
            ['Enabled'] = false;
            ['Normal'] = 0.1;
            ['Randomized'] = {true, 0.1, 0.12}
        };
        ['Toggle'] = {
            ['Enabled'] = true;  --[[ turn this off if you only want sound ]]
            ['Need Holding'] = true;
            ['Input'] = {'Q', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};

            ['Notification'] = {
                ['Enabled'] = false;
                ['Sound'] = false;
                ['Duration'] = 1;
                ['Volume'] = 0.5;
                ['Color'] = {188, 188, 188};
                ['Sound Id'] = {112910579737497, 4064874742} --[[ Enabled Sound, Disabled Sound ]]
            }
        };
        ['Checks'] = {
            ['Visibility'] = true;
            ['Tools'] = true;
            ['Knife'] = true;
            ['Katana'] = true;
            ['Alive'] = true;
            ['Knocked'] = true;
            ['Wallet'] = true;
        };
    };

    ['Miscellaneous'] = {
        ['Anti Afk'] = true;
        ['Anti Fling'] = true;

        ['Inventory Sorter'] =  {
            ['Enabled'] = false;
            ['Hide Junk'] = true --[[ puts non-listed items in inventory ]];
            ['Activation Key'] = {
                ['Input'] = {'H', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            };
            ['Slots'] = {
                [1] = 'Revolver';
                [2] = 'Double Barrel';
                [3] = 'Tactical Shotgun';
                [4] = 'Shotgun';
                [5] = 'Knife';
                [6] = 'Katana';
                [7] = 'Chicken';
                [8] = 'Pizza';
                [9] = 'Cranberry'
            };
        };

        ['Ping Spike'] = {
            ['Enabled'] = false;
            ['Duration'] = 2;
            ['Activation Keybind'] = { --[[ requires holding ]]
                ['Input'] = {'N', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            };
        };

        ['Auto 360'] = {
            ['Enabled'] = false;
            ['Speed'] = 1;
            ['Rotation'] = 360;
            ['Activation Keybind'] = { --[[ requires holding ]]
                ['Input'] = {'J', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            };
        };

        ['Mod Notifier'] = {
            ['Enabled'] = false;
            ['Action'] = 'Notify'; --[[ 'Notify' or 'Crash' or 'Kick' ]]
            ['Groups'] = {996191638, 996191638, 996191638, 996191638, 996191638, 996191638, 996191638};
            ['Notify'] = {
                ['Method'] = 'Notification'; --[[ 'Webhook' or 'Notification']]
                ['Crash'] = false;
            };

            ['KeyBind Mode'] = {
                ['Enabled'] = false;
                ['Activation Keybind'] = {
                    ['Input'] = {'Y', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
                };
            }
        };

        ['Auto Armor'] = {
            ['Enabled'] = true;
            ['Mode'] = 'Keybind'; --[[ 'Keybind' or 'Auto' ]]
            ['Activation Keybind'] = {
                ['Input'] = {'G', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            };
        };

        ['1v1 Prefire'] = {
            ['Enabled'] = false;
            ['Range'] = 100;
            ['Delay'] = 0.25; --[[ 0.25 = shoots 0.25 seconds after it detects a bullet]]
            ['Activation Keybind'] = { --[[ requires holding ]]
                ['Input'] = {'C', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            };
        };

        ['Noclip Macro'] = {
            ['Enabled'] = false;
            ['Noclip Tool'] = 'Tactical Shotgun';
            ['Activation Keybind'] = { --[[ requires holding ]]
                ['Input'] = {'E', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            };
        };

        ['Panic Mode'] = {
            ['Enabled'] = false;
            ['Activation Keybind'] = {
                ['Input'] = {'E', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            };
        };

        ['Humanoid Modification'] = {
            ['WalkSpeed'] = {false, 100};
            ['JumpPower'] = {false, 100};
        };

        ['Macro'] = {
            ['Enabled'] = true;
            ['Activation Key'] = { 
                ['Enabled'] = true;
                ['Need Holding'] = false;
                ['Input'] = {'X', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            }
        };

        ['Flick'] = { 
            ['Enabled'] = true;
            ['Smoothness'] = 0.1;
            ['Delay'] = 0.2;
            ['Activation Key'] = { 
                ['Enabled'] = true;
                ['Input'] = {'E', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            }
        };

        ['Esp'] = { 
            ['Enabled'] = true;
            ['VisibleCheck'] = false;
            ['Override Raid Awareness Visibility'] = true; --[[ will also control the visibility of raid awareness ]]
            ['Toggle'] = { --[[ this will make the boxs visible/invisible ]]
                ['Enabled'] = true;
                ['Need Holding'] = false;
                ['Input'] = {'V', 'MouseButton2', ('Keyboard'--[['Keyboard', 'Mouse']])};
            }
        };

        ['Client Bullet Redirection'] = { --[[ will make ur bullets go towards your mouse (on your screen only) good for clips ]]
            ['Enabled'] = true;
            ['Allowed Guns'] = {'Usp', 'Tactical Shotgun', 'Double Barrel', 'Revolver'};
            ['Restrictions'] = {
                ['Enabled'] = true; --[[ bsically makes the functon only work when your silent aim or aimassist has a target]]
                ['Type'] = 'Silent Aim' --[[ 'Silent Aim' or 'Aim Assist']];
            }
        };

        ['Lighting'] = {
            ['Properties'] = {
                ['Enabled'] = false;
                ['Ambient'] = {127, 127, 127};
                ['Brightness'] = 2,
                ['ColorShift_Top'] = {0, 0, 0},
                ['ColorShift_Bottom'] = {0, 0, 0},
                ['EnvironmentDiffuseScale'] = 1, --[[ Controls how much ambient light affects surfaces ]]
                ['GlobalShadows'] = false; --[[ If you want shadows or not ]]
                ['OutdoorAmbient'] = {127, 127, 127},
                ['Technology'] = 'voxel', --[[ Selects lighting engine/rendering mode ( Compatibility, Future, Legacy, ShadowMap, Unified, Voxel ) ]]
                ['ExposureCompensation'] = 0, --[[ Adjusts overall scene brightness (camera exposure) ]]
                ['FogColor'] = {100, 87, 72};
                ['FogEnd'] = 500,
                ['FogStart'] = 0,
            };

            ['Sky'] = {
                ['Enabled'] = false;
                ['CelestialBodiesShown'] = false; --[[ Renders sun/moon/stars ]]
                ['StarCount'] = 3000;
                ['MoonTextureId'] = 'rbxasset://sky/moon.jpg';
                ['SunTextureId'] = 'rbxasset://sky/sun.jpg';
                ['SkyBox'] = {
                    ['Back'] = '';
                    ['Down'] = '';
                    ['Front'] = '';
                    ['Left'] = '';
                    ['Right'] = '';
                    ['Up'] = '';
                }
            };

            ['Atmosphere'] = {
                ['Enabled'] = false;
                ['Density'] = 0.3; --[[ Fog thickness ]]
                ['Offset'] = 0; --[[ Vertical shift ]]
                ['Color'] = {99, 199, 199}; --[[ Sky tint ]]
                ['Decay'] = {106, 112, 125}; --[[ Light absorption color ]]
                ['Glare'] = 0; --[[ Sun glare intensity ]]
                ['Haze'] = 0; --[[ Atmospheric blur ]]
            };
        };
    };

    ['0-delay'] = { 
        ['Invisible Bullets'] = false; 
        ['Duplicate Bullets'] = 1; 
        ['Modify Range'] = {false, 10000};

        ['Hitbox Modifier'] = {
            ['Enabled'] = false;
            ['Transparency'] = 1;
            ['Size'] = {15, 15, 15};
            ['Color'] = {218, 196, 255};
            ['Visualizer Settings'] = {
                ['Enabled'] = false;
                ['Color'] = { {218, 196, 255}, {225, 225, 225} };
                ['Transparency'] = { 0.6, 0 };
            }
        };

        ['Custom Bullet Spread'] = {
            ['Enabled'] = false;
            ['Method'] = 'Percentage';
            ['Double Barrel'] = {
                ['Percentage'] = 75;
            };
            ['Tactical Shotgun'] = {
                ['Percentage'] = 75;
            };
            ['Shotgun'] = {
                ['Percentage'] = 75;
            };
            ['Drum Shotgun'] = {
                ['Percentage'] = 75;
            };
            ['Other'] = {
                ['Percentage'] = 0;
            };
        };
    };

    ['Gun Specification'] = {
        ['Enabled'] = false;
        ['Range'] = {
            ['Enabled'] = false; --[[ if this is false it will only use ['Close'] ]]
            ['Target'] = 'Silent Aim'; --[[ 'Silent Aim' or 'Aim Assist' ]]
            ['Ranges'] = { ['Close'] = 20; ['Mid'] = 40; ['Far'] = 60; };
        };

        ['Revolver'] = {
            ['Close'] = function()
                --// Code Here
            end;

            ['Mid'] = function()
                --// Code Here
            end;

            ['Far'] = function()
                --// Code Here
            end;
        };

        ['Double Barrel'] = {
            ['Close'] = function()
                --// Code Here
            end;

            ['Mid'] = function()
                --// Code Here
            end;

            ['Far'] = function()
                --// Code Here
            end;
        }
    }
}

loadstring(game:HttpGet("https://www.goodnight.wtf/loader/goodnight.lua"))()

