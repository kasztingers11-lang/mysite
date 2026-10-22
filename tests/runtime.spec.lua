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
    else
        o.props[k]=v
        if old~=v and o.props.propertySignals and o.props.propertySignals[k] then o.props.propertySignals[k]:Fire() end
    end
end
local function obj(class,name,parent)
    local o=setmetatable({props={ClassName=class,Name=name or class,propertySignals={}},children={}},objectMeta)
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
function methods:GetPropertyChangedSignal(name)
    self.props.propertySignals[name]=self.props.propertySignals[name] or signal()
    return self.props.propertySignals[name]
end
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
local rayHit, muzzleBlocked, groundY
function World:Raycast(origin,direction,params)
    if params.RespectCanCollide and groundY and direction.Y < 0 and origin.Y >= groundY and origin.Y+direction.Y <= groundY then
        return {Instance=World,Position=V.new(origin.X,groundY,origin.Z),Normal=V.new(0,1,0)}
    end
    if muzzleBlocked and origin.X==5 then return {Instance=World,Position=V.new()} end
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
    local hum=obj('Humanoid','Humanoid',c);hum.Health=100;hum.MoveDirection=V.new(1,0,0);hum.FloorMaterial=Enum.Material.Plastic
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
local Input={InputBegan=signal(),InputEnded=signal(),InputChanged=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),TextBoxFocused=signal(),keys={}}
function Input:GetMouseLocation()return V.new(960,540)end
function Input:GetFocusedTextBox()return self.textbox end
function Input:IsMouseButtonPressed(item)return self.keys[item.Name] or false end
function Input:IsKeyDown(item)return self.keys[item.Name] or false end
services.UserInputService=Input
-- A top-bar inset must not be subtracted from raw mouse/viewport coordinates.
services.GuiService={GetGuiInset=function()return V.new(0,36)end}
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

local introPlays=0
local env=setmetatable({Core=Core,Defaults=Defaults,game=game,Enum=Enum,Vector3=V,Vector2=V,CFrame=CF,
    UDim2={fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end},UDim={new=function(...)return {...}end},
    Color3={new=function(...)return {...}end,fromRGB=function(...)return {...}end},
    RaycastParams={new=function()return {}end},Instance={new=function(class)return obj(class)end},
    Random={new=function()return {NextNumber=function()return 0.5 end}end},
    os={clock=function()return clock end},task={defer=function(f)f()end},
    warn=function()end,newcclosure=function(f)return f end,
    checkcaller=function()return false end,getnamecallmethod=function()return 'FireServer'end,
    typeof=function(v)return getmetatable(v)==VM and 'Vector3' or type(v)end,
    playIntro=function()introPlays=introPlays+1;return {Destroy=function(self)self.destroyed=true end}end,
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
local function loadRuntime(config, file)
    env.neoperro=Core.copy(config or Defaults)
    return assert(loadfile(file or 'neoperro-src/runtime.lua','t',env))()
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

-- Looten-style native input must work even when a gun does not listen to Tool:Activate.
local nativePresses,nativeReleases=0,0
env.mouse1press=function()
    nativePresses=nativePresses+1;shots=shots+1;Input.keys.MouseButton1=true
    tool.Activated:Fire()
    ammo.Value=ammo.Value-1
end
env.mouse1release=function()nativeReleases=nativeReleases+1;Input.keys.MouseButton1=false end
local function moveEnemy(x,y,z)
    enemyRoot.Position=V.new(x,y,z);enemyRoot.CFrame=CF.new(enemyRoot.Position)
    enemyTorso.Position=enemyRoot.Position;enemyTorso.CFrame=CF.new(enemyRoot.Position)
end
local function zoomMacro()
    for _,name in ipairs({'I','O','I','O'}) do key(name,true);key(name,false);step(0.025) end
end
local function clearInput()
    for name in pairs(Input.keys)do Input.keys[name]=false end
end
local function anyBoxVisible()
    for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible then return true end end
    return false
end

local cfg=Core.copy(Defaults);cfg.ESP.Toggle.Keybind={'P','MouseButton2','Keyboard'}
local first=loadRuntime(cfg);step(0.04)
assert(first.Targets['Silent Aim']==enemy,'Auto needs no selection input')
local baseline=activeConnections()
key('P',true);key('P',false)
assert(not first.Toggles['Silent Aim'] and not first.Toggles.ESP,'Shared input dispatch')
first.Whitelist={2};first.Locks['Aim Assist']=2
local hookBefore=hooks.__namecall
env.__neoperroIntroSeenV1=nil -- Simulate upgrading an old runtime without the new session flag.
local second=loadRuntime(cfg)
assert(not first.Alive and first.Intro.destroyed and second.Intro==nil and introPlays==1,'Intro runs once per session')
assert(not second.Toggles['Silent Aim'] and not second.Toggles.ESP,'Toggle preservation')
assert(#second.Whitelist==0 and second.Locks['Aim Assist']==2,'Disabled whitelist clears assignments; valid target lock survives')
assert(hooks.__namecall==hookBefore and activeConnections()==baseline and renderCount()==1,'Replacement cleanup')
key('P',true);key('P',false);step(0.04)
remote:FireServer('OTHER',V.new(1,2,3),'tail')
assert(packets[#packets][2]=='OTHER' and packets[#packets][4]=='tail')
remote:FireServer('MOUSE',V.new(1,2,3),'tail')
assert(packets[#packets][3]==V.new(1,2,3),'Anti-AimViewer leaves idle updates alone')
key('MouseButton1',true);remote:FireServer('MOUSE',V.new(1,2,3));key('MouseButton1',false)
assert(packets[#packets][3]==second.Points['Silent Aim'],'Shot packets use the fresh point')

-- Box selection is centered on a player and sizes are world units; circle stays on the cursor.
moveEnemy(1,0,-50);step(0.04)
assert(second.Points['Silent Aim'].X==1,'Center point mode must not preserve incorrect mouse X')
second.Config['2d-Box']['Silent Aim'].Size.Width=0.1;step(0.04)
assert(second.Targets['Silent Aim']==nil,'Cursor is outside the small player box')
second.Config['Gun Specifications'].Enabled=true;step(0.04)
assert(second.Targets['Silent Aim']==enemy,'Weapon profile changes the selection box')
second.Config['Gun Specifications'].Enabled=false
second.Config['Silent Aim'].Fov.Mode='2d-Circle';step(0.04)
assert(second.Targets['Silent Aim']==enemy,'Circle radius is independent of box width')
second.Config['Silent Aim'].Fov.Mode='2d-Box';second.Config['2d-Box']['Silent Aim'].Size.Width=5
second.Config['Silent Aim'].Target.Closest.Method='Point'
second.Config['Silent Aim'].Target.Closest.Raycast=true
second.Config['Silent Aim'].Target.Closest.Reduce.Center=1
rayHit={Instance=enemyTorso,Position=V.new(0.3,0.7,-49.5)};step(0.04)
assert(second.Points['Silent Aim']==rayHit.Position,'Raycast bypasses Reduce and Sharpness')
rayHit=nil;second.Config['Silent Aim'].Target.Closest.Raycast=false
second.Config['Silent Aim'].Target.Closest.Method='Part'
moveEnemy(0,0,-50)

-- Stable standalone ESP; colors apply only while whitelist is enabled.
second.Config.Whitelist.Enabled=true;second.Whitelist={2}
step(0.04);assert(anyBoxVisible())
local stableSize
for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then stableSize=d.Size;assert(d.Color[2]==230,'Assigned friend is green') end end
assert(stableSize)
enemyTorso.Size=V.new(30,50,40);step(0.04)
for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then assert(d.Size==stableSize,'Limb bounds must not change the box')end end
second.WhiteMode='Target';step(0.04)
for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then assert(d.Color[1]==255 and d.Color[2]==75,'Assigned target is red')end end
-- Silent box hidden: independent 6x6 ESP ignores weapon overrides and Silent max distance.
second.Config['2d-Box']['Silent Aim'].Visible=false
second.Config['2d-Box']['Silent Aim']['Max Distance']=1
second.Config['Gun Specifications'].Enabled=true;step(0.04)
local standaloneSize
for _,d in ipairs(drawingObjects)do
    if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then standaloneSize=d.Size end
end
assert(standaloneSize and math.abs(standaloneSize.X-6*1080/(2*math.tan(math.rad(70)/2))/50)<=0.5,'Standalone ESP uses fixed six-stud width rounded to a pixel')
second.Config.Whitelist.Enabled=false;step(0.04)
assert(#second.Whitelist==0)
key('R',true);key('R',false);assert(#second.Whitelist==0,'Assignment disabled with whitelist')
for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then assert(d.Color[2]==255,'Disabled whitelist removes marker colors')end end
enemyHum.Health=0;step(0.04);assert(not anyBoxVisible(),'Dead check hides boxes and labels')
enemyHum.Health=100;enemyTorso.Size=V.new(2,2,1);second:Destroy('test');clearInput()

-- Aim Assist Auto searches continuously only during its hold input.
local aim=loadRuntime(Defaults);step(0.04);assert(aim.Targets['Aim Assist']==nil)
key('Q',true);step(0.04);assert(aim.Targets['Aim Assist']==enemy)
local other=obj('Player','Other',Players);other.UserId=3;other.DisplayName='Other'
local otherChar,otherRoot,otherHum,otherTorso=character(other,-50)
Players.PlayerAdded:Fire(other)
moveEnemy(1,0,-50);step(0.04)
assert(aim.Targets['Aim Assist']==other,'Holding Auto must choose the current nearest player')
key('Q',false);step(0.04);assert(aim.Targets['Aim Assist']==nil)
-- A broken Drawing for one player cannot prevent the other player's rendering.
local damaged=aim.Records[enemy].visuals['Silent Aim'].box
local originalSet=damaged.Set
damaged.Set=function()error('injected drawing failure')end
step(0.04)
assert(aim.Warnings['draw-player:2'] and aim.Records[other].visuals['Silent Aim'],'Per-player rendering failures stay isolated')
damaged.Set=originalSet
Players.PlayerRemoving:Fire(other);other.Parent=nil
moveEnemy(0,0,-50);camera.CFrame=CF.new()
aim:Destroy('test');clearInput()

-- Camera assistance remains available with Silent Aim entirely disabled.
local cameraOnly=Core.copy(Defaults);cameraOnly['Silent Aim'].Enabled=false
local cameraRuntime=loadRuntime(cameraOnly);key('Q',true);step(0.04)
assert(cameraRuntime.Points['Silent Aim']==nil and cameraRuntime.Points['Aim Assist']~=nil)
cameraRuntime:Destroy('test');clearInput();camera.CFrame=CF.new()

-- Live Enabled is a hard gate even when a previous key toggle is still armed.
do
    local rt=loadRuntime(Defaults);key('Q',true);step(.04)
    assert(rt.Points['Silent Aim'] and rt.Points['Aim Assist'])
    rt.Config['Silent Aim'].Enabled=false;rt.Config['Aim Assist'].Enabled=false
    rt.Config.Triggerbot.Enabled=false;rayHit={Instance=enemyTorso,Position=enemyTorso.Position}
    local count=shots;key('MouseButton2',true);step(.04)
    assert(not rt.Points['Silent Aim'] and not rt.Points['Aim Assist'] and shots==count,'Live disable overrides armed toggles')
    rt.Config.Triggerbot.Enabled=true;step(.04)
    assert(shots==count+1,'An independently re-enabled Triggerbot still works')
    rt.Config.Triggerbot.Enabled=false;step(.01)
    assert(not rt.MouseOwned,'Live disable releases an owned press')
    rt:Destroy('test');clearInput();rayHit=nil;camera.CFrame=CF.new()
end

-- Recover a stale remote reference and record failures without duplicate retries.
do
    local rt=loadRuntime(Defaults);step(.04)
    local stale=obj('RemoteEvent','MAINEVENT')
    rt.Remote=stale;tool.Activated:Fire()
    assert(rt.Remote==remote and rt.LastSend.Returned,'Reacquire a stale remote before sending')
    local prior=rt.Stats.AimPackets
    local oldFire=methods.FireServer
    methods.FireServer=function()error('test transport failure')end
    tool.Activated:Fire()
    assert(rt.Stats.AimPackets==prior+1 and rt.Stats.AimSendErrors==1 and not rt.PacketPoint,'Failed send clears stale point and is not retried')
    methods.FireServer=oldFire
    remote.Parent=nil;prior=rt.Stats.AimPackets;tool.Activated:Fire()
    assert(rt.Stats.AimPackets==prior and rt.Stats.AimSendSkipped>0,'Missing remote is skipped')
    remote.Parent=storage;tool.Activated:Fire()
    assert(rt.LastSend.Returned,'Remote reappearance restores sends')
    rt:Destroy('test');stale:Destroy();clearInput()
end

-- Native trigger input: immediate press, configured hold, cancellation, optional FOV.
ammo.Value=20
local trigger=loadRuntime(Defaults)
rayHit={Instance=enemyTorso,Position=enemyTorso.Position}
local before=shots
key('MouseButton2',true);step(0.04)
assert(shots==before+1 and trigger.MouseOwned,'Press immediately; Delay controls hold, not reaction')
step(0.04);assert(shots==before+1 and trigger.MouseOwned,'Never overlap held firing cycles')
rayHit=nil;step(0.04)
assert(shots==before+1 and not trigger.MouseOwned,'Losing actual crosshair target releases owned input')
rayHit={Instance=enemyTorso,Position=enemyTorso.Position};step(0.04)
assert(shots==before+2 and nativePresses>0 and trigger.Capabilities.FireInput=='mouse1press','Use native input, not only Tool.Activate')
key('MouseButton2',false)
assert(not trigger.MouseOwned and not Input.keys.MouseButton1,'Release input immediately stops automation')
step(0.2);before=shots
rayHit=nil;key('MouseButton2',true);step(0.04);step(0.2)
assert(shots==before,'Fov false requires an actual character hit')
trigger.Config.Triggerbot.Fov.Enabled=true;step(0.04)
assert(shots==before+1,'Fov true permits a player-box candidate without a body hit')
key('MouseButton2',false);step(0.1)
trigger.Config.Triggerbot.Activation.Keybind={'Q','MouseButton2','Keyboard'}
key('Q',true);step(0.04)
assert(shots==before+2 and trigger.Targets['Aim Assist']==enemy,'Shared Q can activate Aim Assist and Triggerbot')
key('Q',false);step(0.1);trigger:Destroy('test');clearInput();camera.CFrame=CF.new()

-- Silent final muzzle wall check cannot suppress camera assist or independent Triggerbot.
local independent=Core.copy(Defaults);independent.Triggerbot.Fov.Enabled=true
handle.Position=V.new(5,0,0);muzzleBlocked=true
local isolated=loadRuntime(independent);key('Q',true);step(0.04)
assert(isolated.Points['Silent Aim']==nil and isolated.Points['Aim Assist']~=nil,'Silent final wall filter is feature-local')
key('MouseButton2',true);before=shots;step(0.04)
assert(shots==before+1,'Independent Triggerbot bypasses Silent-only final filters')
isolated:Destroy('test');clearInput();muzzleBlocked=false;handle.Position=V.new();camera.CFrame=CF.new()

-- Replacements during owned input release it and retain exactly one callback set.
local rc=Core.copy(Defaults);rc.Triggerbot.Fov.Enabled=true
local replacement=loadRuntime(rc);local replacementConnections=activeConnections()
for i=1,20 do
    key('MouseButton2',true);step(0.12)
    local old=replacement
    replacement=loadRuntime(rc, i%2==0 and 'neoperro-runtime.lua' or nil)
    assert(not old.Alive and not Input.keys.MouseButton1,'Replacement releases held mouse')
    assert(activeConnections()==replacementConnections and renderCount()==1 and hooks.__namecall==hookBefore,'Repeated replacement stays bounded')
    local aliveDrawings=0
    for _,d in ipairs(drawingObjects)do if not d.removed then aliveDrawings=aliveDrawings+1 end end
    assert(aliveDrawings==9,'No drawings left by replaced instances before first render')
end
replacement:Destroy('test');clearInput()

-- A denied native press and denied virtual press may fall back without losing shot context.
local savedPress,savedRelease=env.mouse1press,env.mouse1release
env.mouse1press=function()error('native denied')end
ammo.Value=20
local fallback=loadRuntime(rc);key('MouseButton2',true);step(0.12)
assert(fallback.Capabilities.FireInput=='Tool.Activate fallback' and fallback.FiringSource=='Triggerbot' and fallback.ForcedPoint,'Fallback retains owned cycle and target')
fallback:Destroy('test');clearInput();env.mouse1press,env.mouse1release=savedPress,savedRelease

-- Disabled means no macro operation even while a zoom macro is detected.
local disabled=loadRuntime(Defaults);zoomMacro()
local eventCount=#keyEvents
tool.Activated:Fire();ammo.Value=ammo.Value-1;step(0.3)
assert(tool.Parent==myChar and #keyEvents==eventCount,'Disabled Macro Abuse must do nothing')
disabled:Destroy('test');clearInput()

-- Normal walking is insufficient. A real shot and a detected macro are both required.
local mc=Core.copy(Defaults);mc.Misc['Macro Abuse'].Enabled=true
local macroRuntime=loadRuntime(mc)
tool.Activated:Fire();ammo.Value=ammo.Value-1;step(0.3)
assert(tool.Parent==myChar,'Walking alone must not trigger Macro Abuse')
zoomMacro();tool.Activated:Fire();step(0.05)
assert(tool.Parent==myChar,'Wait for ammo confirmation')
ammo.Value=ammo.Value-1;step(0.05);assert(tool.Parent==backpack)
step(0.07);assert(Input.keys.LeftControl)
step(0.08);assert(tool.Parent==myChar)
step(0.08);assert(not Input.keys.LeftControl)
zoomMacro();tool.Activated:Fire();step(0.05)
assert(tool.Parent==myChar,'A previous confirmed ammo drop cannot authorize another shot cycle')
macroRuntime.PendingMacro=nil
step(0.3);zoomMacro();tool.Activated:Fire();ammo.Value=ammo.Value-1;step(0.05);step(0.07)
assert(Input.keys.LeftControl)
env.neoperro.Misc['Macro Abuse'].Enabled=false;step(0.01)
assert(not Input.keys.LeftControl and tool.Parent==myChar,'Live disable cancels an in-progress cycle')
-- Cancelling cannot reuse an already consumed ammo confirmation within its freshness window.
env.neoperro.Misc['Macro Abuse'].Enabled=true
tool.Activated:Fire();step(0.05)
assert(tool.Parent==myChar,'A consumed ammo drop must not authorize the next activation')
macroRuntime.PendingMacro=nil
macroRuntime.Config.Misc.Panic.Enabled=false
key('E',true);key('E',false);assert(macroRuntime.Alive,'Panic false honors its switch')
macroRuntime.Config.Misc.Panic.Enabled=true;key('E',true);key('E',false)
assert(not macroRuntime.Alive and activeConnections()==0 and renderCount()==0)
clearInput()

-- Prediction and the barrel-alignment filters.
local modes=Core.copy(Defaults);modes['Silent Aim'].EndMath.VelocityHistory=false
modes['Silent Aim'].Prediction.Auto=false
modes['Silent Aim'].Target.Closest.Enabled=false
modes['Y-Axis'].Enabled=true;modes['Y-Axis'].Mode='Custom';modes['Y-Axis'].JumpOffset=2
enemyRoot.AssemblyLinearVelocity=V.new(0,10,0)
local filtered=loadRuntime(modes);step(0.04)
assert(math.abs(filtered.Points['Silent Aim'].Y-2.56)<1e-6)
filtered.Config['Y-Axis'].Mode='Auto';step(0.04)
assert(math.abs(filtered.Points['Silent Aim'].Y-1.28)<1e-6,'Rising motion is not erased by a stale floor material')
enemyRoot.AssemblyLinearVelocity=V.new();step(0.04);assert(filtered.Points['Silent Aim'].Y==0)
filtered.Config['Y-Axis'].Enabled=false
filtered.Config['Silent Aim'].AntiCurve.Enabled=true
filtered.Config['Silent Aim'].AntiCurve.Mode='endmath'
filtered.Config['Silent Aim'].AntiCurve.endmath.Radius=1
enemyRoot.AssemblyLinearVelocity=V.new(100,0,0);step(0.04)
assert(filtered.Points['Silent Aim']==nil,'Endmath rejects outside pixel radius instead of clamping prediction')
filtered.Config['Silent Aim'].AntiCurve.endmath.Radius=300;step(0.04)
assert(math.abs(filtered.Points['Silent Aim'].X-12.8)<1e-6,'Accepted lead is not clamped')
filtered.Config['Silent Aim'].AntiCurve.Mode='3d-angles';step(0.04)
assert(filtered.Points['Silent Aim']==nil,'Reject world-space mouse-to-target distance')
filtered.Config['Silent Aim'].AntiCurve.Enabled=false
filtered.Config.Whitelist.Enabled=true;filtered.WhiteMode='Friend';filtered.Whitelist={2};step(0.04)
assert(filtered.Targets['Silent Aim']==nil)
filtered.WhiteMode='Target';step(0.04);assert(filtered.Targets['Silent Aim']==enemy)
filtered:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new()

-- Auto continues to the next candidate after final prediction/filter rejection.
do
    local second=obj('Player','SecondCandidate',Players);second.UserId=77;second.DisplayName='Second'
    local secondChar,secondRoot,secondHum,secondTorso=character(second,-50)
    secondRoot.Position=V.new(1,0,-50);secondRoot.CFrame=CF.new(secondRoot.Position)
    secondTorso.Position=secondRoot.Position;secondTorso.CFrame=CF.new(secondRoot.Position)
    local cfg=Core.copy(Defaults)
    cfg['Silent Aim'].Target.Closest.Enabled=false
    cfg['Silent Aim'].Prediction.Auto=false
    cfg['Silent Aim'].EndMath.VelocityHistory=false
    cfg['Silent Aim'].AntiCurve.Enabled=true
    cfg['Silent Aim'].AntiCurve.Mode='endmath'
    cfg['Silent Aim'].AntiCurve.endmath.Radius=50
    enemyRoot.AssemblyLinearVelocity=V.new(100,0,0)
    local rt=loadRuntime(cfg);step(.04)
    assert(rt.Targets['Silent Aim']==second,'Auto must try the next candidate after a final filter rejects the nearest')
    rt.Config['Silent Aim'].Mode='Target';rt.Locks['Silent Aim']=enemy.UserId;step(.04)
    assert(rt.Targets['Silent Aim']==nil,'Explicit target lock must not silently switch players')
    rt:Destroy('test');secondChar:Destroy();second:Destroy();enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Live-observed adapter names, fresh cursor precedence, and per-feature prediction.
do
    ammo.Name='AMMO';ammo.Value=6
    local flare=obj('Attachment','Flare',handle);flare.WorldPosition=V.new(4,2,1)
    local checkCfg=Core.copy(Defaults)
    checkCfg['Silent Aim'].Target.Closest.Enabled=false
    checkCfg['Silent Aim'].Ignore=true
    checkCfg['Silent Aim'].EndMath.VelocityHistory=false
    checkCfg['Silent Aim'].EndMath.WallCheck=false
    checkCfg['Y-Axis'].Enabled=true
    checkCfg['Silent Aim'].Prediction.Auto=false
    local rt=loadRuntime(checkCfg)
    moveEnemy(0,3,-50);groundY=0;enemyHum.FloorMaterial=Enum.Material.Air
    enemyRoot.AssemblyLinearVelocity=V.new();step(.04)
    assert(rt.Points['Silent Aim'].Y==3,'Air with zero vertical velocity gets no artificial gravity')
    assert(rt.AimTrace['Silent Aim'].MuzzleOrigin.X==4,'Use observed Flare attachment')
    tool.Parent=backpack;step(.04)
    assert(rt.AimTrace['Silent Aim'].MuzzleOrigin.X~=4,'Unequipped muzzle cannot remain the final wall-check origin')
    tool.Parent=myChar;step(.04)
    enemyRoot.AssemblyLinearVelocity=V.new(0,-30,0);step(.04)
    assert(rt.Points['Silent Aim'].Y==3 and rt.AimTrace['Silent Aim'].GroundCorrected,'Falling point stops at rig-derived landing height')
    enemyRoot.AssemblyLinearVelocity=V.new(0,1,0);step(.04)
    assert(rt.Points['Silent Aim'].Y==3,'Grounded Auto does not invent upward movement')
    enemyRoot.AssemblyLinearVelocity=V.new(0,-30,0)
    rt.Config['Y-Axis'].JumpOffset=5;step(.04)
    assert(rt.Points['Silent Aim'].Y==3,'Auto ignores JumpOffset')
    groundY=nil;rt.Config['Silent Aim'].GroundShotCheck=false
    rt.Config['Y-Axis'].Enabled=false;enemyRoot.AssemblyLinearVelocity=V.new(10,0,0)
    rt.Config['Silent Aim'].Prediction.Enabled=false;step(.04)
    assert(rt.Points['Silent Aim'].X==0,'Disabled prediction adds no lead')
    rt.Config['Silent Aim'].Prediction.Enabled=true;rt.Config['Silent Aim'].Prediction.Auto=true
    rt.Config['Silent Aim'].Prediction.Value=1
    rt.Network.RTT=.15;rt.Network.DataRTT=.2;rt.Network.NextSample=clock+10;step(.04)
    assert(math.abs(rt.Points['Silent Aim'].X-2)<1e-6,'Auto uses measured RTT, not manual Value or summed ping')
    rt.Config['Silent Aim'].Prediction.Value=0;step(.04)
    assert(math.abs(rt.Points['Silent Aim'].X-2)<1e-6)
    rt:StartTrace(1,8);tool.Activated:Fire();ammo.Value=5;step(.04)
    assert(rt.Stats.AmmoDrops==1 and rt.LastSend.Returned and rt.Stats.AimSendReturns>0,'AMMO is observed and send return is separately counted')
    assert(rt.LastSend.Result:find('unverified'))
    for i=1,20 do step(.02) end
    assert(#rt:ReadTrace().Events<=8,'Trace is bounded')
    rt:StopTrace();local n=#rt:ReadTrace().Events;step(.04);assert(#rt:ReadTrace().Events==n)
    enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50)
    rt.Config.Triggerbot.Prediction.Enabled=false
    mouse.Target=World;rayHit={Instance=enemyTorso,Position=V.new(.2,.3,-49.5)}
    key('MouseButton2',true);before=shots;step(.12)
    assert(shots==before+1 and rt.AimTrace.Triggerbot.Part=='UpperTorso','Fresh character ray wins over stale native Mouse.Target')
    assert(rt.ForcedPoint==rayHit.Position,'FOV-off trigger uses actual cursor hit, independent of Silent closest')
    key('MouseButton2',false);step(.2);ammo.Value=0;before=shots
    key('MouseButton2',true);step(.12);assert(shots==before,'Uppercase AMMO empty prevents trigger attempts')
    key('MouseButton2',false);ammo.Value=6
    rt:Destroy('test');flare:Destroy();ammo.Name='Ammo';mouse.Target=nil;rayHit=nil;groundY=nil
    enemyHum.FloorMaterial=Enum.Material.Plastic;clearInput()
end

-- User-supplied current place IDs all start the same Looten-derived remote path.
for _,id in ipairs({134196333708867,71324444457408,139144803593140}) do
    game.PlaceId=id
    local current=loadRuntime(Defaults)
    step(0.04)
    assert(current.Capabilities.Remote and current.Targets['Silent Aim']==enemy,'Current place uses MAINEVENT/MOUSE workflow')
    current:Destroy('test')
end
game.PlaceId=134196333708867

-- Native GUI fallback, processed input, focus, replicated-shot prefire and respawn cleanup.
env.Drawing=nil
local pf=Core.copy(Defaults);pf.Misc.Prefire.Enabled=true
local enemyGun=obj('Tool','[Revolver]',enemyChar)
local enemyAmmo=obj('IntValue','Ammo',enemyGun);enemyAmmo.Value=6
local final=loadRuntime(pf);key('C',true);step(0.04)
before=shots;enemyAmmo.Value=5;step(0.04);step(0.26)
assert(shots==before+1,'Replicated ammo decrease triggers prefire')
key('C',false);step(0.05)
key('P',true,true);key('P',false);assert(final.Toggles['Silent Aim'])
key('MouseButton2',true);Input.WindowFocusReleased:Fire()
assert(not final.Held['activation:Triggerbot'] and not final.MouseOwned)
Input.WindowFocused:Fire();clearInput()
local count=activeConnections()
enemy.CharacterRemoving:Fire(enemyChar)
enemyChar,enemyRoot,enemyHum,enemyTorso=character(enemy,-50)
enemy.CharacterAdded:Fire(enemyChar);step(0.04)
assert(final.Targets['Silent Aim']==enemy and activeConnections()==count)
game.PlaceId=999;assert(not pcall(loadRuntime,Defaults) and final.Alive);game.PlaceId=134196333708867
Players.PlayerRemoving:Fire(enemy);enemy.Parent=nil;step(0.04);assert(final.Targets['Silent Aim']==nil)
final:Destroy('test')
assert(activeConnections()==0 and renderCount()==0 and introPlays==1)
for _,d in ipairs(drawingObjects)do assert(d.removed,'Final teardown removes every owned Drawing')end
print('Runtime v1.3: selection fallback, prediction, player boxes, native trigger input, macro/ammo guards, one-time intro and cleanup passed')
