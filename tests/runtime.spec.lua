-- Behavioral tests against a small deterministic Roblox mock, not a live game test.
local Core = dofile('neoperro-src/core.lua')
local Defaults = dofile('neoperro-src/defaults.lua')
math.clamp = function(x, a, b) return math.max(a, math.min(b, x)) end
local clock, connections, renders, packets, keyEvents, hooks = 0, {}, {}, {}, {}, {}
local V, VM = {}, {}
function V.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},VM) end
VM.__add=function(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
VM.__sub=function(a,b)return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
VM.__mul=function(a,b)
    if type(b)=='number' then return V.new(a.X*b,a.Y*b,a.Z*b) end
    return V.new(a.X*b.X,a.Y*b.Y,a.Z*b.Z)
end
VM.__div=function(a,b)return V.new(a.X/b,a.Y/b,a.Z/b)end
VM.__eq=function(a,b)return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
VM.__index=function(a,k)
    if k=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=='Unit' then return a/a.Magnitude end
    if k=='Dot' then return function(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
end
local CF, CM = {}, {}
function CF.new(x,y,z) return setmetatable({Position=type(x)=='table' and x or V.new(x,y,z),LookVector=V.new(0,0,-1)},CM) end
function CF.lookAt(origin,target) local c=CF.new(origin); c.LookVector=(target-origin).Unit; return c end
CM.__index={
    PointToObjectSpace=function(a,p)return p-a.Position end,
    PointToWorldSpace=function(a,p)return p+a.Position end,
    Lerp=function(a,b,t)return CF.lookAt(a.Position,(a.LookVector*(1-t)+b.LookVector*t)+a.Position)end,
}
local function signal()
    local sig={items={}}
    function sig:Connect(callback)
        local c={Connected=true,callback=callback}
        function c:Disconnect()self.Connected=false end
        self.items[#self.items+1]=c; connections[#connections+1]=c
        return c
    end
    function sig:Fire(...)
        local list={table.unpack(self.items)}
        for _, c in ipairs(list) do if c.Connected then c.callback(...) end end
    end
    return sig
end
local methods, objects = {}, {}
local objectMeta={}
objectMeta.__index=function(o,k)
    if methods[k] then return methods[k] end
    return o.props[k]
end
objectMeta.__newindex=function(o,k,v)
    local old=o.props[k]
    if k=='Parent' and old~=v then
        if old then
            for i,item in ipairs(old.children) do if item==o then table.remove(old.children,i); break end end
            old.ChildRemoved:Fire(o)
        end
        o.props[k]=v
        if v then v.children[#v.children+1]=o; v.ChildAdded:Fire(o); v.DescendantAdded:Fire(o) end
        o.AncestryChanged:Fire(o,v)
    else o.props[k]=v end
end
local function obj(class,name,parent)
    local o=setmetatable({props={ClassName=class,Name=name or class},children={}},objectMeta)
    for _,key in ipairs({'ChildAdded','ChildRemoved','DescendantAdded','DescendantRemoving','AncestryChanged','Activated','CharacterAdded','CharacterRemoving','Idled'}) do o.props[key]=signal() end
    if class=='Part' then
        o.Position=V.new(); o.CFrame=CF.new(); o.Size=V.new(2,2,1)
        o.AssemblyLinearVelocity=V.new(); o.AssemblyAngularVelocity=V.new()
    end
    if class=='Tool' then o.Enabled=true end
    objects[#objects+1]=o
    if parent then o.Parent=parent end
    return o
end
function methods:IsA(class)
    if class==self.ClassName then return true end
    if class=='BasePart' then return self.ClassName=='Part' end
    if class=='ValueBase' then return self.ClassName=='IntValue' or self.ClassName=='NumberValue' or self.ClassName=='BoolValue' end
    return false
end
function methods:GetChildren()return {table.unpack(self.children)}end
function methods:GetDescendants()
    local all={}
    for _,c in ipairs(self.children) do all[#all+1]=c; for _,d in ipairs(c:GetDescendants()) do all[#all+1]=d end end
    return all
end
function methods:FindFirstChild(name)for _,c in ipairs(self.children)do if c.Name==name then return c end end end
function methods:WaitForChild(name)return self:FindFirstChild(name)end
function methods:FindFirstChildOfClass(class)for _,c in ipairs(self.children)do if c:IsA(class)then return c end end end
function methods:GetAttribute(name)return self.props['attr:'..name]end
function methods:IsDescendantOf(parent)local p=self.Parent; while p do if p==parent then return true end;p=p.Parent end;return false end
function methods:Destroy()self.Destroyed=true;self.Parent=nil;for _,c in ipairs(self:GetChildren())do c:Destroy()end end

local Enum=setmetatable({}, {__index=function(t,category)
    local e=setmetatable({}, {__index=function(e,key)local item={Name=key,Value=category=='RenderPriority' and 200 or 0};rawset(e,key,item);return item end})
    rawset(t,category,e);return e
end})
local services={}
local game={PlaceId=134196333708867}
function game:GetService(name)assert(services[name],name);return services[name]end
local World=obj('Workspace','Workspace'); World.Gravity=196.2
local camera=obj('Camera','Camera',World); camera.CFrame=CF.new(0,0,0); camera.ViewportSize=V.new(1920,1080); camera.FieldOfView=70
function camera:ViewportPointToRay(x,y)return {Origin=self.CFrame.Position,Direction=V.new((x-960)/1000,-(y-540)/1000,-1).Unit}end
function camera:WorldToViewportPoint(p)
    local z=-p.Z
    return V.new(960+p.X*1000/math.max(z,0.01),540-p.Y*1000/math.max(z,0.01),z),z>0
end
World.CurrentCamera=camera
local rayHit
function World:Raycast(origin,direction,params)
    if rayHit then
        for _,excluded in ipairs(params.FilterDescendantsInstances or {})do
            if rayHit.Instance==excluded or rayHit.Instance:IsDescendantOf(excluded)then return nil end
        end
    end
    return rayHit
end
services.Workspace=World
local Players=obj('Players','Players'); Players.PlayerAdded=signal(); Players.PlayerRemoving=signal()
services.Players=Players
local me=obj('Player','Local',Players); me.UserId=1; me.DisplayName='Local'; Players.LocalPlayer=me
local enemy=obj('Player','Target',Players); enemy.UserId=2; enemy.DisplayName='Target'
function Players:GetPlayers()return self:GetChildren()end
function Players:GetPlayerByUserId(id)for _,p in ipairs(self.children)do if p.UserId==id then return p end end end
function Players:GetPlayerFromCharacter(c)for _,p in ipairs(self.children)do if p.Character==c then return p end end end
local mouse={Hit=CF.new(0,0,-50)}
function me:GetMouse()return mouse end
obj('PlayerGui','PlayerGui',me)
local backpack=obj('Backpack','Backpack',me)
local function character(player,z)
    local c=obj('Model',player.Name,World)
    local root=obj('Part','HumanoidRootPart',c);root.Position=V.new(0,0,z);root.CFrame=CF.new(root.Position)
    local torso=obj('Part','UpperTorso',c);torso.Position=root.Position;torso.CFrame=CF.new(root.Position)
    local hum=obj('Humanoid','Humanoid',c);hum.Health=100;hum.FloorMaterial=Enum.Material.Plastic
    function hum:UnequipTools()for _,t in ipairs(c:GetChildren())do if t:IsA('Tool')then t.Parent=backpack end end end
    function hum:EquipTool(tool)tool.Parent=c end
    player.Character=c
    return c,root,hum,torso
end
local myChar,myRoot,myHum=character(me,0)
local enemyChar,enemyRoot,enemyHum,enemyTorso=character(enemy,-50)
local tool=obj('Tool','[Revolver]',myChar)
local handle=obj('Part','Handle',tool)
local ammo=obj('IntValue','Ammo',tool);ammo.Value=6
local shots=0
function tool:Activate()shots=shots+1;self.Activated:Fire()end
function tool:Deactivate()self.DeactivatedCount=(self.DeactivatedCount or 0)+1 end
local Input={InputBegan=signal(),InputEnded=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),TextBoxFocused=signal(),keys={}}
function Input:GetMouseLocation()return V.new(960,540)end
function Input:GetFocusedTextBox()return self.textbox end
function Input:IsMouseButtonPressed(item)return self.keys[item.Name] or false end
function Input:IsKeyDown(item)return self.keys[item.Name] or false end
services.UserInputService=Input
local Run={Heartbeat=signal()}
function Run:BindToRenderStep(name,priority,callback)renders[name]=callback end
function Run:UnbindFromRenderStep(name)renders[name]=nil end
services.RunService=Run
local storage=obj('ReplicatedStorage','ReplicatedStorage'); services.ReplicatedStorage=storage
local remote=obj('RemoteEvent','MAINEVENT',storage)
local function originalNamecall(object,...)
    packets[#packets+1]={object,...};return 'forwarded'
end
function remote:FireServer(...)return (hooks.__namecall or originalNamecall)(self,...)end
services.VirtualInputManager={SendKeyEvent=function(_,down,key)keyEvents[#keyEvents+1]={down,key.Name};Input.keys[key.Name]=down end}
services.VirtualUser={CaptureController=function()end,Button2Down=function()end,Button2Up=function()end}

local env=setmetatable({Core=Core,Defaults=Defaults,game=game,Enum=Enum,Vector3=V,Vector2=V,CFrame=CF,
    UDim2={fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end},UDim={new=function(...)return {...}end},
    Color3={new=function(...)return {...}end,fromRGB=function(...)return {...}end},
    RaycastParams={new=function()return {}end},Instance={new=function(class)return obj(class)end},
    Random={new=function()return {NextNumber=function()return 0.5 end}end},
    os={clock=function()return clock end},task={defer=function(f)f()end},
    warn=function()end,newcclosure=function(f)return f end,
    checkcaller=function()return false end,getnamecallmethod=function()return 'FireServer'end,
    typeof=function(v)return getmetatable(v)==VM and 'Vector3' or type(v)end,
    playIntro=function()return {Destroy=function(self)self.destroyed=true end}end,
}, {__index=_G})
env.getgenv=function()return env end
env.hookmetamethod=function(_,kind,callback)
    local old=hooks[kind] or (kind=='__namecall' and originalNamecall or function(o,k)return o[k]end)
    hooks[kind]=callback;return old
end
local drawingObjects={}
env.Drawing={new=function(kind)
    local d={Kind=kind,Remove=function(self)self.removed=true end};drawingObjects[#drawingObjects+1]=d;return d
end}
local function loadRuntime(config)
    env.neoperro=Core.copy(config or Defaults)
    return assert(loadfile('neoperro-src/runtime.lua','t',env))()
end
local function key(name,down,processed)
    local isMouse=name:match('MouseButton')~=nil
    Input.keys[name]=down
    local input={KeyCode=Enum.KeyCode[isMouse and 'Unknown' or name],UserInputType=Enum.UserInputType[isMouse and name or 'Keyboard']}
    (down and Input.InputBegan or Input.InputEnded):Fire(input,processed or false)
end
local function step(dt)
    clock=clock+dt;Run.Heartbeat:Fire(dt)
    for _,callback in pairs(renders)do callback(dt)end
end
local function activeConnections()local n=0;for _,c in ipairs(connections)do if c.Connected then n=n+1 end end;return n end
local function renderCount()local n=0;for _ in pairs(renders)do n=n+1 end;return n end

local cfg=Core.copy(Defaults);cfg.ESP.Toggle.Keybind={'P','MouseButton2','Keyboard'}
local first=loadRuntime(cfg)
step(0.04)
assert(first.Targets['Silent Aim']==enemy,'Auto selection')
local baseline=activeConnections()
key('P',true);key('P',false)
assert(first.Toggles['Silent Aim']==false and first.Toggles.ESP==false,'Shared keys dispatch both actions')
first.Whitelist={2};first.WhiteMode='Target';first.Locks['Aim Assist']=2
local hookBefore=hooks.__namecall
local second=loadRuntime(cfg)
assert(not first.Alive and first.Intro.destroyed)
assert(second.Toggles['Silent Aim']==false and second.Toggles.ESP==false)
assert(second.Whitelist[1]==2 and second.WhiteMode=='Target' and second.Locks['Aim Assist']==2)
assert(hooks.__namecall==hookBefore,'Must not stack hooks')
assert(activeConnections()==baseline and renderCount()==1,'Replacement leaks subscriptions')
key('P',true);key('P',false);step(0.04)
assert(second.Toggles['Silent Aim'])
local originalCount=#packets
remote:FireServer('OTHER',V.new(1,2,3),'tail')
assert(packets[#packets][2]=='OTHER' and packets[#packets][4]=='tail','Unrelated packets preserved')
remote:FireServer('MOUSE',V.new(1,2,3),'tail')
assert(packets[#packets][3]==second.ForwardPoint and packets[#packets][4]=='tail','Idle forwarding')
key('MouseButton1',true);remote:FireServer('MOUSE',V.new(1,2,3));key('MouseButton1',false)
assert(packets[#packets][3]==second.Points['Silent Aim'],'Shot window uses real aim')

-- Holding triggerbot, target changes during delay, and one pending shot.
rayHit={Instance=enemyTorso}
key('V',true);step(0.04)
rayHit=nil;step(0.2);assert(shots==0,'A departed crosshair target must cancel the delayed shot')
rayHit={Instance=enemyTorso};step(0.04);step(0.12)
assert(shots==1,'Expected one automatic activation')
key('V',false);step(0.2);assert(shots==1,'Hold release stops triggerbot')
rayHit=nil

-- Manual activation -> unequip -> Ctrl held -> equip -> release.
cfg.Misc['Macro Abuse'].Enabled=true
local third=loadRuntime(cfg);step(0.04)
tool.Activated:Fire();step(0.05)
assert(tool.Parent==backpack,'Macro unequip')
step(0.07);assert(Input.keys.LeftControl,'Macro Ctrl down')
step(0.08);assert(tool.Parent==myChar,'Macro equip')
step(0.08);assert(not Input.keys.LeftControl,'Macro Ctrl up')
tool.Activated:Fire();step(0.05);step(0.07)
assert(Input.keys.LeftControl)
key('E',true);key('E',false)
assert(not third.Alive and not Input.keys.LeftControl and tool.Parent==myChar,'Panic restores macro state')
assert(activeConnections()==0 and renderCount()==0,'Panic leaks callbacks')
local last=#packets;remote:FireServer('MOUSE',V.new(4,5,6))
assert(packets[#packets][3]==V.new(4,5,6),'Inactive hook must pass through')

-- Native GUI fallback, dead checks, processed input, focus loss and unsupported place guard.
env.Drawing=nil
local fourth=loadRuntime(Defaults);step(0.04)
enemyHum.Health=0;step(0.04);assert(fourth.Targets['Silent Aim']==nil,'Dead check')
enemyHum.Health=100;step(0.04);assert(fourth.Targets['Silent Aim']==enemy)
key('P',true,true);key('P',false);assert(fourth.Toggles['Silent Aim'],'Processed input ignored')
key('V',true);Input.WindowFocusReleased:Fire();assert(not fourth.Held['toggle:Triggerbot'])
Input.WindowFocused:Fire()
game.PlaceId=999
assert(not pcall(loadRuntime,Defaults) and fourth.Alive,'Unsupported place must not destroy current runtime')
game.PlaceId=134196333708867
fourth:Destroy('test')
assert(activeConnections()==0 and renderCount()==0)

-- Check prediction modes and the two AntiCurve bounds against moving targets.
local modes=Core.copy(Defaults)
modes.EndMath.VelocityHistory=false
modes['Silent Aim'].Axis='All'
modes['Y-Axis'].Enabled=true
modes['Y-Axis'].Mode='Custom';modes['Y-Axis'].JumpOffset=2
enemyRoot.AssemblyLinearVelocity=V.new(0,10,0)
local fifth=loadRuntime(modes);step(0.04)
assert(math.abs(fifth.Points['Silent Aim'].Y-2.56)<1e-6,'Custom jump offset')
fifth.Config['Y-Axis'].Mode='Auto';step(0.04)
assert(fifth.Points['Silent Aim'].Y==0,'Grounded Auto must ignore JumpOffset')
fifth.Config['Y-Axis'].Enabled=false
fifth.Config['Silent Aim'].AntiCurve.Enabled=true
fifth.Config['Silent Aim'].AntiCurve.Mode='endmath'
fifth.Config['Silent Aim'].AntiCurve.endmath.Radius=1
enemyRoot.AssemblyLinearVelocity=V.new(100,0,0);step(0.04)
assert(math.abs((fifth.Points['Silent Aim']-enemyTorso.Position).Magnitude-1)<1e-6,'Endmath bound')
fifth.Config['Silent Aim'].AntiCurve.Mode='3d-angles';step(0.04)
local direction=fifth.Points['Silent Aim'].Unit
local angle=math.deg(math.acos(math.clamp(direction:Dot(V.new(0,0,-1)),-1,1)))
assert(angle<=4.00001,'3D angle bound')
fifth.Config.Whitelist.Enabled=true;fifth.WhiteMode='Friend';fifth.Whitelist={2};step(0.04)
assert(fifth.Targets['Silent Aim']==nil,'Friend exclusion')
fifth.WhiteMode='Target';step(0.04);assert(fifth.Targets['Silent Aim']==enemy,'Target whitelist')
fifth:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new()

-- Prefire uses replicated ammo drops; no invented shooting remote.
local pf=Core.copy(Defaults);pf.Misc.Prefire.Enabled=true
local enemyGun=obj('Tool','[Revolver]',enemyChar)
local enemyAmmo=obj('IntValue','Ammo',enemyGun);enemyAmmo.Value=6
local sixth=loadRuntime(pf);key('C',true);step(0.04)
local before=shots;enemyAmmo.Value=5;step(0.04);step(0.26)
assert(shots==before+1,'Ammo drop triggers one prefire activation')
key('C',false);enemyAmmo.Value=4;step(0.3)
assert(shots==before+1,'Prefire release prevents later activations')
sixth:Destroy('test')

-- Respawn and player removal must retire the old character's callbacks/visuals.
local seventh=loadRuntime(Defaults);step(0.04)
local oldCount=activeConnections()
enemy.CharacterRemoving:Fire(enemyChar)
enemyChar,enemyRoot,enemyHum,enemyTorso=character(enemy,-50)
enemy.CharacterAdded:Fire(enemyChar);step(0.04)
assert(seventh.Targets['Silent Aim']==enemy and activeConnections()==oldCount,'Respawn callback count')
Players.PlayerRemoving:Fire(enemy);enemy.Parent=nil;step(0.04)
assert(seventh.Targets['Silent Aim']==nil,'Departed player target must clear')
seventh:Destroy('test')
assert(activeConnections()==0 and renderCount()==0)
print('Runtime: targeting, shared keys, preservation, nonstacking hooks, delayed-shot cancellation, macro, panic and GUI fallback passed')
