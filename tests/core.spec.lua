local Core = dofile('neoperro-src/core.lua')
local function near(a, b, epsilon) assert(math.abs(a - b) < (epsilon or 1e-8), tostring(a) .. ' != ' .. tostring(b)) end

-- One second's damping must agree at 30, 60, 120 and 240 FPS.
local expected = 1 - (1 - 0.0068) ^ 60
for _, fps in ipairs({30, 60, 120, 240}) do
    local x = 0
    for _ = 1, fps do x = x + (1 - x) * Core.alpha(0.0068, 1 / fps) end
    near(x, expected)
end
assert(Core.fov(50, 50, '2d-Box', 100, 100, 50))
assert(not Core.fov(50, 50, '2d-Circle', 100, 100, 50))
assert(Core.fov(30, 40, '2d-Circle', 100, 100, 50))
assert(not Core.fov(50.01, 0, '2d-Box', 100, 100, 50))
assert(Core.input({'P', 'MouseButton2', 'Keyboard'}, 'P', 'Keyboard'))
assert(not Core.input({'P', 'MouseButton2', 'Keyboard'}, 'Unknown', 'MouseButton2'))
assert(Core.input({'P', 'MouseButton2', 'Mouse'}, 'Unknown', 'MouseButton2'))
assert(Core.weapon('[DoubleBarrel] - $1000') == 'Double-Barrel SG')
assert(Core.weapon('[Tactical Shotgun]') == 'TacticalShotgun')
assert(Core.weapon('Wallet') == nil)
local spec = {Enabled = true, Ranges = {Close = 15, Medium = 30, Far = 90}, Revolver = {Close = 1, Medium = 2, Far = 3}}
assert(Core.profile(spec, 'Revolver', 15) == 1)
assert(Core.profile(spec, 'Revolver', 15.1) == 2)
assert(Core.profile(spec, 'Revolver', 90) == 3)
assert(Core.profile(spec, 'Revolver', 90.1) == nil)
assert(Core.restoreToggle(true, true, false) == false)
assert(Core.restoreToggle(false, true, true) == false)
assert(Core.restoreToggle(true, false, false) == true)
local ids = Core.ids({42, 42, 'bad', 1, 2, 3, 4, math.huge})
assert(#ids == 4 and ids[1] == 42 and ids[4] == 3)
assert(not Core.whitelisted(true, 'Friend', ids, 42))
assert(Core.whitelisted(true, 'Target', ids, 42))
assert(Core.whitelisted(false, 'Target', {}, 42))
near(Core.delay({DelayMode = 'Random', RandomDelay = {0.12, 0.1}}, 0, 0.5), 0.11)
near(Core.delay({DelayMode = 'Normal', Delay = 0.2}, 100, 0.5), 0.2)
assert(Core.delay({SmartDelay = true, Delay = 0.1}, 200, 0) > 0.1)

local V = {}
local mt = {
    __add = function(a, b) return V.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end,
    __sub = function(a, b) return V.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end,
    __mul = function(a, b) return V.new(a.X * b, a.Y * b, a.Z * b) end,
    __div = function(a, b) return V.new(a.X / b, a.Y / b, a.Z / b) end,
    __index = function(a, key) if key == 'Magnitude' then return math.sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) end end,
}
function V.new(x,y,z) return setmetatable({X=x,Y=y,Z=z}, mt) end
local history, zero = {}, V.new(0,0,0)
for i = 0, 7 do Core.sample(history, V.new(i * 16 / 30, 0, 0), i / 30) end
near(Core.velocity(history, zero, zero).X, 16)
assert(#history <= 8)
Core.sample(history, V.new(1000, 0, 0), 8 / 30)
assert(#history == 1, 'Teleport must reset the fit')
assert(not Core.sample(history, V.new(1001, 0, 0), 8 / 30 + 0.001))
for i = 9, 1000 do Core.sample(history, V.new(1000 + (i-8) / 30, 0, 0), i / 30) end
assert(#history <= 8)
near(Core.velocity(history, zero, zero).X, 1)
assert(not Core.finiteVector(V.new(0/0, 0, 0)))
assert(not Core.finiteVector(V.new(math.huge, 0, 0)))
local defaults = dofile('neoperro-src/defaults.lua')
Core.validate(defaults, defaults)
assert(defaults.EndMath==nil and defaults['Silent Aim'].EndMath~=nil)
assert(defaults.Prediction==nil and defaults.Triggerbot.Prediction.Value==0.121)
for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'}) do
    assert(defaults[feature].Prediction.Enabled and defaults[feature].Prediction.Auto)
end
assert(defaults['Y-Axis'].AimAssist==nil)
near(Core.predictionTime({Enabled=false,Auto=true,Value=1},.2,.25,0),0)
near(Core.predictionTime({Enabled=true,Auto=false,Value=.121},.2,.25,0),.121)
near(Core.predictionTime({Enabled=true,Auto=true,Value=1},.15,.2,.01),.21)
near(Core.predictionTime({Enabled=true,Auto=true,Value=0},.15,.2,.01),.21)
near(Core.predictionTime({Enabled=true,Auto=true,Value=1},nil,nil,0),.1)
near(Core.predictionTime({Enabled=true,Auto=true,Value=0},.2,.2,0,100,1000),.3)
near(Core.predictionTime({Enabled=true,Auto=true,Value=0},1,1,.1),.35)
near(Core.autoY(0,.128,1.6,false),0) -- Live Air + zero vertical motion must not invent -1.6 studs.
near(Core.autoY(-30,.128,1.6,true),0)
near(Core.autoY(-30,.128,1.6,false),-1.6)
near(Core.autoY(30,.128,1.6,false),3.2)
local reversed={{p=zero,t=2},{p=zero,t=3}}
Core.sample(reversed,zero,1); assert(#reversed==1 and reversed[1].t==1)
assert(defaults['Silent Aim'].AntiCurve['3d-angles'].MaxAngle==nil and defaults['Silent Aim'].AntiCurve.endmath.MaxAngle==nil)
assert(defaults.Misc.Intro == nil and defaults['Client Bullets'].RequireTarget == nil)
for name, value in pairs(defaults['Gun Specifications']) do
    if name ~= 'Ranges' and type(value) == 'table' then
        for _, range in ipairs({'Close','Medium','Far'}) do assert(value[range].Prediction == nil) end
    end
end
print('Core: damping, FOV, inputs, weapon ranges, state retention, delays and velocity history passed')
