local Core = dofile('neoperro-src/core.lua')
assert(Core.curveLimit(0,2.2)==0.000000001)
assert(Core.curveLimit(0.000000001,2.2)==0.000000001)
assert(Core.curveLimit(1e20,2.2)==1e20)
assert(Core.curveLimit(math.huge,2.2)==math.huge)
assert(Core.curveLimit(0/0,2.2)==2.2)
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
assert(#ids == 5 and ids[1] == 42 and ids[5] == 4)
do
    local many={};for i=1,1000 do many[i]=i end
    assert(#Core.ids(many)==1000,'Whitelist assignments have no four-player cap')
    assert(Core.whitelisted(true,'Target',many,1000,{[1000]=true}))
    assert(not Core.whitelisted(true,'Target',many,1001,{[1000]=true}))
end
assert(not Core.whitelisted(true, 'Friend', ids, 42))
assert(Core.whitelisted(true, 'Target', ids, 42))
assert(Core.whitelisted(false, 'Target', {}, 42))
assert(Core.whitelisted(true, 'Target', {}, 42), 'Empty target list allows everyone until someone is assigned')
assert(Core.whitelisted(true, 'Friend', {}, 42))
assert(not Core.whitelisted(true, 'Target', {7}, 42), 'Nonempty Target list limits eligibility')
assert(Core.whitelisted(true, 'Friend', {7}, 42))
near(Core.delay({DelayMethod = 'Random', RandomDelay = {0.12, 0.1}}, 0, 0.5), 0.11)
near(Core.delay({DelayMethod = 'Normal', Delay = 0.2}, 100, 0.5), 0.2)
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
    local look,up=V.new(0,0,-1),V.new(0,1,0)
    for _,ray in ipairs({V.new(0,0,-1),V.new(.2,.1,-1),V.new(-.3,.2,-1)})do
        ray=ray/ray.Magnitude
        for _,target in ipairs({V.new(.5,.3,-1),V.new(-2,1,-1),ray*-1})do
            target=target/target.Magnitude
            local aimedLook,aimedUp=Core.cursorOrientation(ray,target,look,up)
            local right=aimedLook:Cross(aimedUp)
            local actual=right*ray.X+aimedUp*ray.Y+aimedLook*(-ray.Z)
            near((actual-target).Magnitude,0,1e-7)
        end
    end
    assert(Core.cursorOrientation(V.new(0,0,0),look,look,up)==nil)
    for _,basis in ipairs({{V.new(1,0,0),V.new(0,1,0)},{V.new(0,1,0),V.new(0,0,1)}})do
        local startLook,startUp=basis[1],basis[2]
        local startRight=startLook:Cross(startUp)
        local ray=startLook+startRight*.2+startUp*.1;ray=ray/ray.Magnitude
        local target=V.new(5,-2,-3);target=target/target.Magnitude
        local newLook,newUp=Core.cursorOrientation(ray,target,startLook,startUp)
        local actual=newLook:Cross(newUp)*ray:Dot(startRight)+newUp*ray:Dot(startUp)+newLook*ray:Dot(startLook)
        near((actual-target).Magnitude,0,1e-7)
    end
end
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
    for _,d in ipairs({V.new(1,2,-3),V.new(-3,-2,1),V.new(0,4,0),V.new(0,-4,0)})do
        local target=V.new(5,7,9)+d*15
        local gap,_,depth=Core.rayDistance(target,V.new(5,7,9),d)
        near(gap,0);near(depth,15)
        assert(Core.rayDistance(target,V.new(5,7,9),d*-1)==nil,'Rearward rays cannot create an alignment')
    end
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
    -- Captured non-knocked remote fall: the old acceleration extrapolation led
    -- 2.695 studs upward before any ascent was observed.
    local braking={VerticalAcceleration=462.45916874964985,VerticalConfidence=.5440542127578352}
    local y,_,mode=Core.verticalLead(-8.994217872619629,-8.994217872619629,.1864221009532532,4,false,braking)
    assert(y<0 and mode=='braking-stop','Decelerating fall cannot invent an upward launch')
    near(Core.verticalLead(0,0,.2,4,false,braking),0)
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
        Core.resolveVelocity(samples,raw,Core.velocity(samples,raw,zero),V.new)
        model=Core.motion(samples,raw)
    end
    assert(model.TurnValidated and Core.motionTime(.121,model.TurnRate)<.121,'Validated curved motion shortens extrapolation')
end
-- A smooth raw velocity ramp alone does not establish real vertical acceleration.
do
    local samples={}
    for i=0,7 do
        local t=i*.02
        Core.sample(samples,V.new(22*t,30,0),t,V.new(22,28-200*t,0))
    end
    local model=Core.motion(samples,V.new(22,0,0),.14)
    assert(model.VerticalConfidence==0 and not model.VerticalValidated,
        'Raw gravity-like numbers cannot invent a fall while observed positions remain level')
end

-- Sampling phase is not replication latency. Perfect measured acceleration must
-- not flicker off between 60 Hz history samples in a faster render loop.
do
    for _,fps in ipairs({30,60,144,240})do
        for _,gravity in ipairs({100,196.2,300})do
            local samples,elapsed={},0
            for frame=0,math.floor(fps*.45)do
                local t=frame/fps;local raw=V.new(10,60-gravity*t,-10)
                elapsed=elapsed+1/fps
                if elapsed>=1/60 then
                    elapsed=elapsed%(1/60)
                    Core.sample(samples,V.new(10*t,30+60*t-.5*gravity*t*t,-10*t),t,raw)
                end
                if t>=.2 then
                    local model=Core.motion(samples,raw,t)
                    assert(model.VerticalConfidence>.999,'Sampling phase cannot erase a coherent measured curve at '..fps..' FPS')
                    near(model.VerticalAcceleration,-gravity,1e-6)
                    local held=Core.motion(samples,samples[#samples].raw,t)
                    assert(held.VerticalConfidence>.999,'A held replicated velocity is also inside the sample-time envelope')
                end
            end
            local last=samples[#samples]
            assert(Core.motion(samples,last.raw,last.t+.1).VerticalConfidence==0,'A stale model cannot use an unbounded timing envelope')
        end
    end
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
do
    local function estimate(samples,raw)
        local fit=Core.velocity(samples,raw,zero)
        local fallback,source=Core.resolveVelocity(samples,raw,fit,V.new)
        return Core.trueVelocity(samples,raw,fit,fallback,source,V.new)
    end
    for _,raw in ipairs({V.new(0,0,0),V.new(-60,0,80),V.new(4,0,-2)}) do
        local samples={}
        for i=0,7 do Core.sample(samples,V.new(22*i*.02,-15*i*.02,-8*i*.02),i*.02,raw) end
        local resolved,source=estimate(samples,raw)
        near(resolved.X,22);near(resolved.Y,-15);near(resolved.Z,-8)
        assert(source=='true-velocity','Coherent movement can correct a persistent replicated XYZ mismatch')
        local fresh=V.new(-22,40,8)
        Core.sample(samples,V.new(22*.16,-15*.16,-8*.16),.16,fresh)
        resolved=estimate(samples,fresh)
        near(resolved.X,-22);near(resolved.Y,40);near(resolved.Z,8)
    end
    local samples={}
    for i=0,7 do Core.sample(samples,V.new(22*i*.02+(i%2)*4,0,0),i*.02,zero) end
    local resolved,source=estimate(samples,zero)
    near(resolved.X,0);assert(source~='true-velocity','Irregular displacement cannot establish a stable movement estimate')
    Core.sample(samples,V.new(1000,0,0),.16,zero)
    resolved,source=estimate(samples,zero)
    near(resolved.Magnitude,0);assert(#samples==1 and source~='true-velocity','A teleport discards the previous correction')
end
Core.validate(defaults, defaults)
assert(defaults.EndMath==nil and defaults['Silent Aim'].EndMath==nil)
assert(defaults.Resolver.Enabled and defaults.Resolver.Method==nil)
assert(defaults['Silent Aim'].Resolver==nil and defaults['Silent Aim'].GroundShotCheck==nil)
assert(defaults['Aim Assist'].Ignore==nil and defaults.ESP.MaxDistance==nil)
for _,style in pairs(defaults['2d-Box']) do
    assert(style.Filled==nil and style.Transparency==nil and style['Predicted Position']==nil and style['Max Distance']==nil)
end
do
    local legacy={
        ['Silent Aim']={Mode='Target',Resolver={Enabled=false},GroundShotCheck=false,
            Target={Closest={Method='Point'}},['Keybind Mode']={['Unlock Mode']='Normal'},
            AntiCurve={Mode='endmath',endmath={Radius=9}}},
        ['Aim Assist']={Ignore=true,Mode='Auto'},['Y-Axis']={JumpOffset=2},
        Triggerbot={DelayMode='Normal'},Whitelist={Mode='Target'},ESP={MaxDistance=1},
        ['2d-Box']={['Silent Aim']={Filled=true,Transparency=0,['Predicted Position']=true,['Max Distance']=1}},
        Misc={['Macro Abuse']={['Work With TB']=true}},
    }
    local normalized=Core.normalizeConfig(legacy)
    assert(normalized['Silent Aim'].Method=='Target' and normalized['Silent Aim'].Mode==nil)
    assert(normalized['Silent Aim'].Target.Closest.Selection=='Point' and normalized['Silent Aim'].Target.Closest.Method==nil)
    assert(normalized['Silent Aim'].Activation['Unlock Method']=='Normal')
    assert(normalized.Resolver.Enabled==false and normalized.Checks.GroundShotCheck[1]==false and normalized.Checks.GroundShotCheck[2])
    assert(normalized['Y-Axis'].Offset==2 and normalized.Triggerbot.DelayMethod=='Normal' and normalized.Whitelist.Method=='Target')
    assert(normalized['Silent Aim'].AntiCurve.Method=='Endmath' and normalized['Silent Aim'].AntiCurve.Endmath.Radius==9)
    assert(normalized['Aim Assist'].Ignore==nil and normalized.ESP.MaxDistance==nil and next(normalized['2d-Box']['Silent Aim'])==nil)
    assert(normalized.Misc['Macro Abuse']['Triggerbot check'] and legacy['Silent Aim'].Mode=='Target','Migration must not mutate the supplied table')
    legacy['Silent Aim'].Method='Auto';legacy.Resolver={Enabled=true};legacy.Checks={GroundShotCheck={true,false,false}}
    legacy['Silent Aim'].Target.Closest.Selection='Part';legacy['Y-Axis'].Offset=3
    normalized=Core.normalizeConfig(legacy)
    assert(normalized['Silent Aim'].Method=='Auto' and normalized.Resolver.Enabled and normalized.Checks.GroundShotCheck[2]==false)
    assert(normalized['Silent Aim'].Target.Closest.Selection=='Part' and normalized['Y-Axis'].Offset==3,'Canonical fields win when both spellings exist')
end
assert(defaults['Silent Aim'].AntiCurve.Endmath and defaults['Silent Aim'].AntiCurve.endmath==nil)
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
    local time,limited=Core.fastLeadTime(.121,200,22)
    assert(limited and time*200<=.121*30+1e-8,'Fast-motion horizontal lead cannot grow unbounded')
    near(Core.fastLeadTime(.121,22,22),.121)
end
do
    local samples={}
    for i=0,7 do
        Core.sample(samples,V.new(i*.02*22,0,0),i*.02,V.new(22,0,0))
        local fit=Core.velocity(samples,V.new(22,0,0),V.new(0,0,0))
        Core.resolveVelocity(samples,V.new(22,0,0),fit,V.new)
    end
    local fit=Core.velocity(samples,V.new(22,0,0),V.new(0,0,0))
    local resolved,source=Core.resolveVelocity(samples,V.new(-22,0,0),fit,V.new)
    near(resolved.X,-22);assert(source=='raw-transition','A reversal must not keep old forward lead')
    resolved=Core.resolveVelocity(samples,V.new(0,0,0),fit,V.new);near(resolved.X,0)
    resolved,source=Core.resolveVelocity(samples,V.new(1000,0,0),fit,V.new)
    near(resolved.X,22);assert(source=='history-fallback')
    samples={}
    for i=0,7 do
        local raw=V.new(11,0,0)
        Core.sample(samples,V.new(i*.02*22,0,0),i*.02,raw)
        resolved,source=Core.resolveVelocity(samples,raw,Core.velocity(samples,raw,V.new(0,0,0)),V.new)
    end
    near(resolved.X,22);assert(source=='history-validated','History wins when its earlier forecasts actually fit arriving positions better')
end
near(Core.autoY(0,.128,1.6,false),0) -- Live Air + zero vertical motion must not invent -1.6 studs.
-- A fresh acute turn or same-sign vertical slowdown is still a transition.
-- Old, otherwise well-validated history cannot describe motion that just began.
do
    local h={}
    for i=0,7 do
        local raw=V.new(11,20,0)
        Core.sample(h,V.new(22*i*.02,40*i*.02,0),i*.02,raw)
        Core.resolveVelocity(h,raw,Core.velocity(h,raw,zero),V.new)
    end
    local fit=Core.velocity(h,V.new(11,20,0),zero)
    local stable=Core.resolveVelocity(h,V.new(11,20,0),fit,V.new)
    near(stable.X,22);near(stable.Y,40)
    local unobserved=Core.resolveVelocity(h,V.new(11,10,11),fit,V.new)
    near(unobserved.X,22);near(unobserved.Y,40);near(unobserved.Z,0)
    local fresh=V.new(11,10,11)
    Core.sample(h,h[#h].p+fresh*.02,.16,fresh)
    fit=Core.velocity(h,fresh,zero)
    local changed,source=Core.resolveVelocity(h,fresh,fit,V.new)
    near(changed.X,11);near(changed.Y,10);near(changed.Z,11)
    assert(source=='raw-transition','Fresh diagonal turn and vertical slowdown must not keep old fitted lead')
end
do
    local h={}
    for i=0,7 do
        Core.sample(h,V.new(22*i*.02,40*i*.02,0),i*.02,V.new(11,40,0))
        h[#h].fitted=V.new(22,20,0)
    end
    local v=Core.resolveVelocity(h,V.new(-22,40,0),V.new(22,40,0),V.new)
    near(v.X,-22);near(v.Y,40) -- Vertical motion cannot mask an XZ reversal.
    v=Core.resolveVelocity(h,V.new(.1,40,0),V.new(22,40,0),V.new)
    near(v.X,.1) -- Resting noise cannot retain a walking horizontal fit.
    v=Core.resolveVelocity(h,V.new(0,40,0),V.new(22,0,0),V.new)
    near(v.X,0);near(v.Y,40) -- Fresh jump onset must not retain a zero-Y fit.
    local source
    v,source=Core.resolveVelocity(h,V.new(11,40,0),V.new(22,20,0),V.new)
    near(v.X,22);near(v.Y,40);assert(source=='split-validated')
end
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
assert(defaults['Silent Aim'].AntiCurve['3d-angles'].MaxAngle==nil and defaults['Silent Aim'].AntiCurve.Endmath.MaxAngle==nil)
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

-- Box dimensions stay constant relative to projected character geometry.
for _,depth in ipairs({1,10,50,1000})do
    local x,y,width,height=Core.projectedBox(960,540,depth,5,4.3,1000)
    near(x+width/2,960);near(y+height/2,540)
    near(width*depth/1000,5);near(height*depth/1000,4.3)
    near(width/(2*1000/depth),2.5)
end
assert(Core.projectedBox(960,540,-1,5,4.3,1000)==nil)
assert(Core.projectedBox(960,540,0.1,5,4.3,1000)==nil)
do
    local migrated=Core.normalizeConfig({['Gun Specifications']={Revolver={Close={BoxSize={82,94}}}}})
    assert(migrated['Gun Specifications'].Revolver.Close.BoxSize.Width==82
        and migrated['Gun Specifications'].Revolver.Close.BoxSize.Height==94)
    local w,h=Core.boxDimensions({Width=0,Height=0/0},80,70)
    near(w,.01);near(h,70)
end

for _,resolution in ipairs({720,1080,1440,2160})do
    for _,fov in ipairs({45,70,90,110})do
        local focal=resolution/(2*math.tan(math.rad(fov)/2))
        local _,_,width,height=Core.projectedBox(960,540,50,5,4.3,focal)
        near(width*50/focal,5);near(height*50/focal,4.3)
    end
end
