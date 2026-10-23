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
    __index = function(a, key)
        if key == 'Magnitude' then return math.sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) end
        if key == 'Dot' then return function(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
        if key == 'Cross' then return function(a,b)return V.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
    end,
}
function V.new(x,y,z) return setmetatable({X=x,Y=y,Z=z}, mt) end
do
    local p=Core.closestRayBox(V.new(0,0,10),V.new(0,0,-1),V.new(1,1,1),V.new)
    near(p.X,0);near(p.Y,0);near(p.Z,1)
    p=Core.closestRayBox(V.new(4,3,10),V.new(0,0,-1),V.new(1,1,1),V.new)
    near(p.X,1);near(p.Y,1)
    p=Core.closestRayBox(V.new(3,2,10),V.new(-.2,0,-1),V.new(0,1,0),V.new)
    near(p.X,0);near(p.Y,1);near(p.Z,0)
    p=Core.closestRayBox(V.new(3,2,10),V.new(0,0,1),V.new(1,1,1),V.new)
    near(p.X,1);near(p.Y,1);near(p.Z,1)
end
local history, zero = {}, V.new(0,0,0)
do
    local gap,p,t=Core.rayDistance(V.new(3,0,-50),zero,V.new(0,0,-10))
    near(gap,3);near(p.Z,-50);near(t,5)
    assert(Core.rayDistance(V.new(0,0,1),zero,V.new(0,0,-1))==nil)
    assert(Core.rayDistance(zero,zero,zero)==nil)
    local samples={}
    for i=0,7 do
        local time=i*.02
        Core.sample(samples,V.new(22*time,40*time-100*time*time,0),time,V.new(22,40-200*time,0))
    end
    local raw=V.new(22,12,0)
    local model=Core.motion(samples,raw)
    near(model.VerticalAcceleration,-200);near(model.VerticalConfidence,1)
    local lead,correction=Core.verticalLead(26,12,.1,4,false,model)
    near(lead,.2);near(correction,-1)
    near(Core.verticalLead(26,12,.1,4,true,model),0)
    near(Core.motionTime(.121,model.TurnRate),.121)
    samples[#samples].raw=V.new(22,150,0)
    assert(Core.motion(samples,V.new(22,150,0)).VerticalConfidence==0,'A one-frame impulse is not a stable acceleration')
    for i=1,#samples do samples[i].raw=V.new(22,0,0) end
    model=Core.motion(samples,V.new(0,0,22))
    assert(model.MeasuredTurnRate>0 and model.TurnRate==0,'An unvalidated turn cannot shorten the horizon')
    near(Core.verticalLead(0,0,.1,4,false,model),0)
    samples={}
    for i=0,14 do
        local t=i*.02;local angle=t*10;local raw=V.new(-22*math.sin(angle),0,22*math.cos(angle))
        Core.sample(samples,V.new(2.2*math.cos(angle),0,2.2*math.sin(angle)),t,raw)
        Core.resolveVelocity(samples,raw,Core.velocity(samples,raw,zero),zero)
        model=Core.motion(samples,raw)
    end
    assert(model.TurnValidated and Core.motionTime(.121,model.TurnRate)<.121,'Validated curved motion shortens extrapolation')
end
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
do
    local cfg={Enabled=true,Auto=false,Value=.121}
    near(Core.predictionTime(cfg,0,0,0,0,nil,22,22),.121)
    local slow=Core.predictionTime(cfg,0,0,0,0,nil,5,22)
    local fast=Core.predictionTime(cfg,0,0,0,0,nil,100,22)
    assert(slow<.121 and slow>=.121*.75 and fast>.121 and fast<=.121*1.25)
    assert(cfg.Value==.121 and cfg.Dynamic==nil,'Dynamic behavior has no extra setting and does not mutate Value')
    cfg.Auto=true;near(Core.predictionTime(cfg,.1,.1,0,0,nil,22,22),.1)
    cfg.Value=1;near(Core.predictionTime(cfg,.1,.1,0,0,nil,22,22),.1)
    local time,limited=Core.silentLeadTime(.121,200,22)
    assert(limited and time*200<=.121*30+1e-8,'Fast-motion horizontal lead cannot grow unbounded')
    near(Core.silentLeadTime(.121,22,22),.121)
end
do
    local samples={}
    for i=0,7 do
        Core.sample(samples,V.new(i*.02*22,0,0),i*.02,V.new(22,0,0))
        local fit=Core.velocity(samples,V.new(22,0,0),V.new(0,0,0))
        Core.resolveVelocity(samples,V.new(22,0,0),fit,V.new(0,0,0))
    end
    local fit=Core.velocity(samples,V.new(22,0,0),V.new(0,0,0))
    local resolved,source=Core.resolveVelocity(samples,V.new(-22,0,0),fit,V.new(0,0,0))
    near(resolved.X,-22);assert(source=='raw-transition','A reversal must not keep old forward lead')
    resolved=Core.resolveVelocity(samples,V.new(0,0,0),fit,V.new(0,0,0));near(resolved.X,0)
    resolved,source=Core.resolveVelocity(samples,V.new(1000,0,0),fit,V.new(0,0,0))
    near(resolved.X,22);assert(source=='history-fallback')
    samples={}
    for i=0,7 do
        local raw=V.new(11,0,0)
        Core.sample(samples,V.new(i*.02*22,0,0),i*.02,raw)
        resolved,source=Core.resolveVelocity(samples,raw,Core.velocity(samples,raw,V.new(0,0,0)),V.new(0,0,0))
    end
    near(resolved.X,22);assert(source=='history-validated','History wins when its earlier forecasts actually fit arriving positions better')
end
near(Core.autoY(0,.128,1.6,false),0) -- Live Air + zero vertical motion must not invent -1.6 studs.
near(Core.autoY(-30,.128,1.6,true),0)
near(Core.autoY(-30,.128,1.6,false),-1.6)
near(Core.autoY(30,.128,1.6,false),3.2)
near(Core.autoVertical(9.3091507,-3.8926463),-3.8926463) -- Captured jump-apex disagreement.
near(Core.autoVertical(-12,20),20) -- New upward motion does not retain falling history.
near(Core.autoVertical(9,-1),9) -- Ignore resting noise.
near(Core.autoVertical(9,-1000),9) -- Do not trust an implausible raw spike.
near(Core.autoVertical(9,12),9) -- Preserve history when direction agrees.
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

assert(Core.rayBox({X=0,Y=0,Z=5},{X=0,Y=0,Z=-1},{X=1,Y=1,Z=1})==4)
assert(Core.rayBox({X=1.1,Y=0,Z=5},{X=0,Y=0,Z=-1},{X=1,Y=1,Z=1})==nil)
assert(Core.rayBox({X=1.1,Y=0,Z=5},{X=0,Y=0,Z=-1},{X=1.2,Y=1.2,Z=1.2})==3.8)
assert(Core.rayBox({X=0,Y=0,Z=5},{X=0,Y=0,Z=1},{X=1,Y=1,Z=1})==nil)

-- Rigid tracer rotation keeps spread/length and uses no substitute Beam style.
do
    local o=V.new(0,0,0);local from=V.new(0,0,-50);local to=V.new(50,0,0)
    local a,b=V.new(-2,1,-50),V.new(2,-1,-50)
    local ra=Core.redirectTracer(o,a,from,to,V.new)
    local rb=Core.redirectTracer(o,b,from,to,V.new)
    near(ra.Magnitude,a.Magnitude);near(rb.Magnitude,b.Magnitude)
    near(ra:Dot(rb),a:Dot(b));assert((ra-rb).Magnitude>4)
    local center=Core.redirectTracer(o,from,from,to,V.new)
    near(center.X,50);near(center.Y,0);near(center.Z,0)
    local reverse=Core.redirectTracer(o,a,from,from*-1,V.new)
    near(reverse.Magnitude,a.Magnitude)
    near(reverse:Dot(Core.redirectTracer(o,b,from,from*-1,V.new)),a:Dot(b))
    assert(Core.redirectTracer(o,a,o,to,V.new)==nil)
    assert(Core.redirectTracer(o,a,from,V.new(0/0,0,0),V.new)==nil)
end
assert(not Core.macroActive(V.new(16,0,0)))
assert(not Core.macroActive(V.new(30,100,0)))
assert(Core.macroActive(V.new(30.1,0,0)))
assert(Core.macroActive(V.new(22,0,22)))
assert(not Core.macroActive(V.new(0,200,0)))
assert(not Core.macroActive(V.new(0/0,0,0)))

assert(defaults.Misc['Macro Abuse']['Check Ammo']==nil,'Removed Macro Abuse ammo setting stays absent')
