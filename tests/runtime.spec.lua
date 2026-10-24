-- Behavioral tests against a small deterministic Roblox mock, not a live game test.
local Core = dofile('neoperro-src/core.lua')
local Defaults = dofile('neoperro-src/defaults.lua')
local Posture = dofile('neoperro-src/posture.lua')
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
    if k=='Cross' then return function(a,b)return V.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
end
local CF, CM = {}, {}
function CF.new(x,y,z) return setmetatable({Position=type(x)=='table' and x or V.new(x,y,z),LookVector=V.new(0,0,-1)},CM) end
function CF.lookAt(origin,target) local c=CF.new(origin); c.LookVector=(target-origin).Unit; return c end
CM.__index={
    PointToObjectSpace=function(a,p)return p-a.Position end,
    VectorToObjectSpace=function(a,p)return p end,
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
    e.GetEnumItems=function()
        local items={}
        local names=category=='UserInputType' and {'Keyboard','MouseButton1','MouseButton2','MouseButton3'} or {'P','M','V','Q','T','E','R','C','LeftShift','LeftControl','Space','F1'}
        for _,name in ipairs(names)do items[#items+1]=e[name] end
        return items
    end
    rawset(t,category,e);return e
end})
local services={}
local game={PlaceId=134196333708867}
function game:GetService(name)assert(services[name],name);return services[name]end
local World=obj('Workspace','Workspace'); World.Gravity=196.2
local camera=obj('Camera','Camera',World); camera.CFrame=CF.new(0,0,0); camera.ViewportSize=V.new(1920,1080); camera.FieldOfView=70
local function cameraFocal()return camera.ViewportSize.Y/(2*math.tan(math.rad(camera.FieldOfView)/2))end
function camera:ViewportPointToRay(x,y)return {Origin=self.CFrame.Position,Direction=V.new((x-self.ViewportSize.X/2)/cameraFocal(),-(y-self.ViewportSize.Y/2)/cameraFocal(),-1).Unit}end
function camera:WorldToViewportPoint(p)
    local relative=p-self.CFrame.Position
    local z=-relative.Z
    return V.new(self.ViewportSize.X/2+relative.X*cameraFocal()/math.max(z,0.01),self.ViewportSize.Y/2-relative.Y*cameraFocal()/math.max(z,0.01),z),z>0
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
local env=setmetatable({Core=Core,Posture=Posture,Defaults=Defaults,game=game,Enum=Enum,Vector3=V,Vector2=V,CFrame=CF,
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

local cfg=Core.copy(Defaults);cfg['Silent Aim'].Prediction.Enabled=false;cfg.ESP.Toggle.Keybind={'P','MouseButton2','Keyboard'}
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
assert(second.LastMousePayload==V.new(1,2,3),'Original dispatcher refreshes current runtime payload tracking')
key('MouseButton1',true);remote:FireServer('MOUSE',V.new(1,2,3));key('MouseButton1',false)
assert(packets[#packets][3]==V.new(1,2,3),'Continuous updates stay ordinary even while firing')
tool.Activated:Fire()
assert(second.Stats.AimRestores>0 and not second.PacketPoint and second.LastAimRestore.Returned,'Shot sends restore ordinary aim instead of holding a target override')
assert(second.LastShot.serverPoint==second.Points['Silent Aim'],'Local tracer keeps the actual shot point independently of restoration')
assert(second.ClientPoint==nil and second.LastShot.point==mouse.Hit.Position,'Local visual uses raw mouse without an index spoof')
assert(not hooks.__index,'Local visuals do not install a Mouse.Target/Hit hook')
local ownA=obj('Attachment','Start');ownA.WorldPosition=second.LastShot.origin
local ownB=obj('Attachment','End');ownB.Position=V.new();ownB.WorldPosition=second.LastShot.serverPoint
local nativeEndpoint=ownB.WorldPosition
local localBeam=obj('Beam','gb');localBeam.Color='native-yellow';localBeam.Width0=.002;localBeam.Width1=.1;localBeam.Texture='native-texture';localBeam.Attachment0=ownA;localBeam.Attachment1=ownB;localBeam.Parent=World
assert((ownB.WorldPosition-Core.redirectTracer(ownA.WorldPosition,nativeEndpoint,second.LastShot.serverPoint,mouse.Hit.Position,V.new)).Magnitude<1e-6,'Native ray rotates toward raw cursor')
assert(localBeam.Color=='native-yellow' and localBeam.Width0==.002 and localBeam.Width1==.1 and localBeam.Texture=='native-texture','Native Beam style is untouched')
local farA=obj('Attachment','Start');farA.WorldPosition=V.new(100,100,100)
local farB=obj('Attachment','End');farB.Position=V.new();farB.WorldPosition=V.new(999,0,0)
local foreignBeam=obj('Beam','gb');foreignBeam.Attachment0=farA;foreignBeam.Attachment1=farB;foreignBeam.Parent=World
assert(farB.WorldPosition==V.new(999,0,0),'Another muzzle is not rewritten')


-- Box selection follows character perspective; circle stays on the cursor.
moveEnemy(1,0,-50);step(0.04)
assert(second.Points['Silent Aim'].X==1,'Center point mode must not preserve incorrect mouse X')
second.Config['2d-Box']['Silent Aim'].Size.Width=0.1;step(0.04)
assert(second.Targets['Silent Aim']==nil,'Cursor is outside the small player box')
second.Config['Gun Specifications'].Enabled=true;step(0.04)
assert(second.Targets['Silent Aim']==enemy,'Weapon profile changes the selection box')
second.Config['Gun Specifications'].Enabled=false
second.Config['Silent Aim'].Fov.Method='2d-Circle';step(0.04)
assert(second.Targets['Silent Aim']==enemy,'Circle radius is independent of box width')
second.Config['Silent Aim'].Fov.Method='2d-Box';second.Config['2d-Box']['Silent Aim'].Size.Width=5
second.Config['Silent Aim'].Target.Closest.Selection='Point'
second.Config['Silent Aim'].Target.Closest.Raycast=true
second.Config['Silent Aim'].Target.Closest.Reduce.Center=1
rayHit={Instance=enemyTorso,Position=V.new(0.3,0.7,-49.5)};step(0.04)
assert(second.Points['Silent Aim']==rayHit.Position,'Raycast bypasses Reduce and Sharpness')
rayHit=nil;second.Config['Silent Aim'].Target.Closest.Raycast=false
second.Config['Silent Aim'].Target.Closest.Selection='Part'
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
-- Silent box hidden: standalone ESP follows weapon profiles and its own max distance.
second.Config['2d-Box']['Silent Aim'].Visible=false
second.Config['2d-Box']['Silent Aim']['Max Distance']=1
second.Config['Gun Specifications'].Enabled=true;step(0.04)
local standaloneSize
for _,d in ipairs(drawingObjects)do
    if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then standaloneSize=d.Size end
end
assert(standaloneSize and math.abs(standaloneSize.X-5*cameraFocal()/50)<1e-6,'Standalone ESP uses the active weapon profile')
second.Config.Whitelist.Enabled=false;step(0.04)
assert(#second.Whitelist==0)
key('R',true);key('R',false);assert(#second.Whitelist==0,'Assignment disabled with whitelist')
for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then assert(d.Color[2]==255,'Disabled whitelist removes marker colors')end end
enemyChar.props['attr:Knocked']=true;step(0.04);assert(not anyBoxVisible(),'Knocked check hides boxes and labels')
enemyChar.props['attr:Knocked']=false;step(0.04);assert(anyBoxVisible(),'Recovery restores eligible ESP')
enemyHum.Health=0;step(0.04);assert(not anyBoxVisible(),'Dead check hides boxes and labels')
enemyHum.Health=100;enemyTorso.Size=V.new(2,2,1);second:Destroy('test');clearInput()

-- Aim Assist Auto searches continuously only during its hold input.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false
    local rt=loadRuntime(cfg)
    Input.keys.Q=true;step(.04)
    assert(rt.Targets['Aim Assist']==enemy,'An already-held activation key works without a new InputBegan')
    local replacement=loadRuntime(cfg);step(.04)
    assert(replacement.Targets['Aim Assist']==enemy,'Re-execution resynchronizes a physically held activation')
    Input.keys.Q=false;step(.04)
    assert(not replacement.Targets['Aim Assist'],'A missed InputEnded cannot leave activation latched')
    replacement:Destroy('test');clearInput()
    cfg['Aim Assist']['Keybind Mode']=cfg['Aim Assist'].Activation;cfg['Aim Assist'].Activation=nil
    cfg.Misc['Macro Abuse']['Work With TB']=true;cfg.Misc['Macro Abuse']['Triggerbot check']=nil
    rt=loadRuntime(cfg)
    assert(rt.Config['Aim Assist'].Activation.Keybind[1]=='Q' and rt.Config['Aim Assist']['Keybind Mode']==nil,'Legacy activation names migrate to the canonical table')
    assert(rt.Config.Misc['Macro Abuse']['Triggerbot check'] and rt.Config.Misc['Macro Abuse']['Work With TB']==nil)
    rt:Destroy('test');clearInput()
end

-- Aim Assist Auto searches continuously only during its hold input.
do
    local cfg=Core.copy(Defaults);cfg.Whitelist.Enabled=true;cfg.Whitelist.Method='Friend'
    local old=loadRuntime(cfg);old.WhiteMode='Target';old.Whitelist={enemy.UserId};old.Version='1.3.4'
    local current=loadRuntime(cfg)
    assert(current.WhiteMode=='Target' and current.Whitelist[1]==enemy.UserId,'An unchanged configuration preserves valid whitelist state across runtime versions')
    cfg.Whitelist.Method='Target'
    current=loadRuntime(cfg)
    assert(current.WhiteMode=='Target','An explicit configuration mode still wins')
    current:Destroy('test');clearInput()
end

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

-- Deferred restoration coalesces, keeps the shot point and cancels after unload.
do
    local deferred={};local originalDefer=env.task.defer
    env.task.defer=function(f)deferred[#deferred+1]=f end
    local cfg=Core.copy(Defaults);cfg['Silent Aim'].Ignore=true
    local rt=loadRuntime(cfg);step(.04)
    local oldHit=mouse.Hit;mouse.Hit=CF.new(25,2,-50)
    tool.Activated:Fire();tool.Activated:Fire()
    assert(#deferred==2 and packets[#packets][3]==rt.Points['Silent Aim'])
    local count=#packets;deferred[1]()
    assert(#packets==count,'Superseded restore does not write stale aim')
    deferred[2]();assert(#packets==count+1 and packets[#packets][3]==mouse.Hit.Position)
    assert(rt.LastShot.serverPoint==rt.Points['Silent Aim'])
    tool.Activated:Fire();local pending=deferred[#deferred];rt:Destroy('test');count=#packets
    pending();assert(#packets==count,'Unload cancels pending restoration')
    env.task.defer=originalDefer;mouse.Hit=oldHit
    cfg['Anti-AimViewer'].Enabled=false
    rt=loadRuntime(cfg);step(.04);count=rt.Stats.AimRestores
    remote:FireServer('MOUSE',V.new(25,2,-50))
    assert(packets[#packets][3]==rt.Points['Silent Aim'],'Disabled setting retains continuous redirection mode')
    tool.Activated:Fire();assert(rt.Stats.AimRestores==count)
    rt:Destroy('test')
end

-- A native press can return before Tool.Activated. An earlier deferred restore
-- must not erase the routed shot before the weapon actually activates.
do
    local originalDefer,originalPress,oldHit=env.task.defer,env.mouse1press,mouse.Hit
    local savedAmmo=ammo.Value;ammo.Value=100
    for _,shaped in ipairs({false,true})do
        local deferred={};env.task.defer=function(f)deferred[#deferred+1]=f end
        env.mouse1press=function()Input.keys.MouseButton1=true end
        mouse.Hit=CF.new(25,2,-50);moveEnemy(0,0,-50)
        local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false
        cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Prediction.Enabled=false
        cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=shaped
        rayHit={Instance=enemyTorso,Position=enemyTorso.Position}
        local rt=loadRuntime(cfg);step(.04)
        assert(rt.MouseOwned and rt.Stats.Activations==0,'Fixture defers native weapon activation')
        for _,f in ipairs(deferred)do f()end;deferred={}
        assert(packets[#packets][3]==mouse.Hit.Position,'The pre-activation restore has already run')
        moveEnemy(.25,0,-50);rayHit.Position=enemyTorso.Position
        local before=rt.Stats.AimPackets;tool.Activated:Fire()
        assert(rt.Stats.AimPackets==before+1 and rt.LastSend.Point.X==rt.Points['Silent Aim'].X,
            'Native TB activation must freshly submit the eligible Silent redirection')
        assert(packets[#packets][3]==rt.Points['Silent Aim'] and rt.LastShot.serverPoint==rt.Points['Silent Aim'])
        assert(rt.LastShotRoute.AtActivation and rt.LastShotRoute.AimFeature=='Silent Aim')
        for _,f in ipairs(deferred)do f()end
        assert(packets[#packets][3]==mouse.Hit.Position,'Restoration follows the actual shot submission')
        rt:Destroy('test');clearInput()
    end
    env.task.defer,env.mouse1press,mouse.Hit=originalDefer,originalPress,oldHit
    rayHit=nil;ammo.Value=savedAmmo;moveEnemy(0,0,-50)
end

-- Point selection evaluates allowed part geometry; exact native HB hits bypass smoothing.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local s=cfg['Silent Aim'];s.Ignore=true;s.Prediction.Enabled=false
    s.Target.Closest.Selection='Point';s.Target.Closest.Axis='All';s.Target.Closest.Reduce.All=0;s.Target.Closest.Sharpness=1
    moveEnemy(2,0,-50)
    local raycast=World.Raycast
    World.Raycast=function(self,origin,direction,params)
        if (origin+direction).X>1.5 then return {Instance=World,Position=origin+direction*.5} end
        return raycast(self,origin,direction,params)
    end
    local rt=loadRuntime(cfg);step(.04)
    assert(rt.Points['Silent Aim'] and rt.Points['Silent Aim'].X<=1.5,'Visible allowed point can be selected when its part center is blocked')
    rt.Config['Silent Aim'].Prediction.Enabled=true;rt.Config['Silent Aim'].Prediction.Auto=false
    enemyRoot.AssemblyLinearVelocity=V.new(22,0,0);step(.04)
    assert(not rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].Reason=='predicted-wall','Wall checks follow final prediction rather than an earlier visible center')
    rt:Destroy('test');World.Raycast=raycast;moveEnemy(0,0,-50);enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Point selection evaluates allowed part geometry; exact native HB hits bypass smoothing.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local s=cfg['Silent Aim'];s.Ignore=true;s.Prediction.Enabled=false
    s.Target.Closest.Raycast=false;s.Target.Closest.Selection='Part';s.Target.Closest.Sharpness=1
    s.Target.Closest.Axis='All';s.Target.Closest.Reduce.All=0
    moveEnemy(2,0,-50)
    local leg=obj('Part','LeftUpperLeg',enemyChar);leg.Size=V.new(2,8,1);leg.Position=V.new(1.5,4,-50);leg.CFrame=CF.new(leg.Position)
    local rt=loadRuntime(cfg);step(.04)
    assert(rt.AimTrace['Silent Aim'].Part=='UpperTorso','Part retains nearest-center semantics')
    rt.Config['Silent Aim'].Target.Closest.Selection='Point';step(.04)
    assert(rt.AimTrace['Silent Aim'].Part=='LeftUpperLeg','Point compares nearest allowed points, not only part centers')
    local p=rt.AimTrace['Silent Aim'].BasePoint
    assert(p.X>=.5 and p.X<=2.5 and p.Y>=0 and p.Y<=8,'The selected point remains in the real part')
    local hb=obj('Part','HB',enemyChar);hb.CanQuery=true
    local hit=V.new(1.8,.7,-49.5);rayHit={Instance=hb,Position=hit}
    local closest=rt.Config['Silent Aim'].Target.Closest
    closest.Raycast=true;closest.Reduce.All=1;closest.Sharpness=.01;step(.04)
    assert(rt.AimTrace['Silent Aim'].SurfacePart=='HB' and rt.Points['Silent Aim']==hit,'Native HB exact surface bypasses Reduce and Sharpness')
    local accessory=obj('Accessory','Accessory',enemyChar);local accessoryHandle=obj('Part','Handle',accessory)
    local accessoryHit=V.new(1.7,.8,-49)
    rayHit={Instance=accessoryHandle,Position=accessoryHit};step(.04)
    assert(rt.Points['Silent Aim']==accessoryHit and rt.AimTrace['Silent Aim'].PointSource=='cursor-surface','The actual first accessory surface must not fall back to reduced limb points')
    assert(rt.AimTrace['Silent Aim'].Part~='Handle','Accessory size cannot replace body-part vertical geometry')
    accessory:Destroy();rayHit={Instance=hb,Position=hit}
    closest.Raycast=false;step(.04)
    assert(rt.Points['Silent Aim']~=hit,'Leaving raycast clears its smoothing state')
    rt:Destroy('test');leg:Destroy();hb:Destroy();rayHit=nil;moveEnemy(0,0,-50)
end

-- Closest Point must find the nearest point on translated predicted geometry,
-- rather than finding a current surface point and moving it away from the ray.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local s=cfg['Silent Aim'];s.Ignore=true;s.AntiCurve.Enabled=false
    s.Target.Closest.Raycast=false;s.Target.Closest.Selection='Point'
    s.Target.Closest.Axis='All';s.Target.Closest.Reduce.All=0;s.Target.Closest.Sharpness=1
    s.Prediction.Auto=false;s.Prediction.Value=.121
    local savedWalk=enemyHum.WalkSpeed
    for _,motion in ipairs({V.new(22,0,0),V.new(-14,6,14),V.new(0,-12,0),V.new(6,12,-14)})do
        local horizontal=math.sqrt(motion.X*motion.X+motion.Z*motion.Z)
        enemyHum.WalkSpeed=math.max(1,horizontal)
        local shift=motion*.121
        moveEnemy(-shift.X,-shift.Y,-50-shift.Z);enemyRoot.AssemblyLinearVelocity=motion
        enemyHum.FloorMaterial=Enum.Material.Air
        local rt=loadRuntime(cfg);step(.04)
        local point=rt.Points['Silent Aim']
        assert(point and math.abs(point.X)<1e-6 and math.abs(point.Y)<1e-6,
            'XYZ prediction must select the surface of the predicted part under the cursor')
        assert(rt.AimTrace['Silent Aim'].PointSource=='closest-point-predicted')
        local base=rt.AimTrace['Silent Aim'].BasePoint
        assert(math.abs(base.X-enemyTorso.Position.X)<=enemyTorso.Size.X/2+1e-8
            and math.abs(base.Y-enemyTorso.Position.Y)<=enemyTorso.Size.Y/2+1e-8,
            'The pre-lead point must remain inside actual part geometry')
        rt:Destroy('test')
    end
    enemyHum.WalkSpeed=savedWalk;enemyHum.FloorMaterial=Enum.Material.Plastic
    enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50);clearInput()
end

-- Silent acquisition accepts the current point or predicted point inside the
-- same configured circle. AntiCurve remains a separate final-coordinate limit.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local s=cfg['Silent Aim'];s.Target.Closest.Enabled=false;s.Prediction.Auto=false;s.Prediction.Value=.1
    s.Fov.Method='2d-Circle';s.Fov['2d-Circle'].Size=10
    enemyRoot.AssemblyLinearVelocity=V.new(20,0,0)
    local rt=loadRuntime(cfg);step(.02)
    assert(rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].FovReference=='base-point',
        'Ordinary lead must not discard a character already acquired inside the circle')
    moveEnemy(3,0,-50);step(.02);assert(not rt.Points['Silent Aim'],'Neither point inside means no acquisition')
    moveEnemy(0,0,-50);rt.Config['Silent Aim'].AntiCurve.Enabled=true
    rt.Config['Silent Aim'].AntiCurve['3d-angles'].Max=.25;step(.02)
    assert(not rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].Reason=='anti-curve-studs',
        'Less restrictive acquisition must not expand the configured AntiCurve limit')
    rt:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new();clearInput()
end

-- A projected center just outside the viewport can forecast into a visible FOV.
do
    local project,oldMouse,oldEnabled,oldWalk=camera.WorldToViewportPoint,Input.GetMouseLocation,tool.Enabled,enemyHum.WalkSpeed
    camera.WorldToViewportPoint=function(self,point)
        local p=project(self,point)
        return p,p.Z>0 and p.X>=0 and p.X<=1920 and p.Y>=0 and p.Y<=1080
    end
    Input.GetMouseLocation=function()return V.new(1910,540)end;tool.Enabled=false;enemyHum.WalkSpeed=10
    local edgeX=(1910-camera.ViewportSize.X/2)*50/cameraFocal()
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local cfg=Core.copy(Defaults)
        for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
            cfg[name].Enabled=name==feature;cfg[name].Activation.Holding=false
            cfg[name].Prediction.Auto=false;cfg[name].Prediction.Value=.1
            cfg[name].Fov.Method='2d-Circle';cfg[name].Fov['2d-Circle'].Size=15
        end
        cfg['Silent Aim'].Target.Closest.Enabled=false;cfg['Aim Assist'].Target.Closest.Enabled=false
        cfg['Aim Assist'].Follow='Mouse';cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=true
        moveEnemy(edgeX+1,0,-50);enemyRoot.AssemblyLinearVelocity=V.new(-10,0,0)
        local rt=loadRuntime(cfg);step(.02)
        assert(rt.Points[feature] and math.abs(rt.Points[feature].X-edgeX)<1e-6,
            'The final visible point must decide viewport eligibility for '..feature)
        rt:Destroy('test')
    end
    camera.WorldToViewportPoint=project;Input.GetMouseLocation=oldMouse;tool.Enabled=oldEnabled;enemyHum.WalkSpeed=oldWalk
    enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50);clearInput()
end

-- Exact third-person native hits retain their surface before any prediction.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local s=cfg['Silent Aim'];s.Ignore=true;s.Prediction.Enabled=false;s.Target.Closest.Raycast=true
    s.Target.Closest.Selection='Point';s.Target.Closest.Reduce.All=1;s.Target.Closest.Sharpness=.01
    local cast,hit=World.Raycast,mouse.Hit;handle.Position=V.new(5,1,0);mouse.Hit=CF.new(0,0,-100)
    moveEnemy(3,.6,-40);local surface=enemyTorso.Position+V.new(-.3,.2,.4)
    World.Raycast=function(self,origin,direction,params)
        if origin.X==0 then return {Instance=World,Position=V.new(0,0,-5)} end
        return {Instance=enemyTorso,Position=surface}
    end
    local rt=loadRuntime(cfg);step(.02)
    assert(rt.Points['Silent Aim']==surface and rt.AimTrace['Silent Aim'].PointSource=='native-surface',
        'A blocked camera ray must not discard a valid exact native muzzle surface')
    rt:Destroy('test');World.Raycast=cast;mouse.Hit=hit;handle.Position=V.new();moveEnemy(0,0,-50);clearInput()
end

-- A target hit before background cover is unobstructed; foreground cover rejects.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg.Checks.Wall[1]=false
    local s=cfg['Silent Aim'];s.Ignore=true;s.Prediction.Enabled=false;s.Target.Closest.Enabled=false
    s.AntiCurve.Enabled=true;s.AntiCurve.Method='Endmath'
    local cast=World.Raycast;local blocked=false;local queries=0
    World.Raycast=function(self,origin,direction,params)
        queries=queries+1
        if blocked then return {Instance=World,Position=V.new(0,0,-5)} end
        for _,part in ipairs(params.FilterDescendantsInstances or {})do
            if part==enemyChar then return {Instance=World,Position=V.new(0,0,-49.8)} end
        end
        return {Instance=enemyTorso,Position=V.new(0,0,-49.5)}
    end
    local rt=loadRuntime(cfg);step(.02)
    assert(rt.Points['Silent Aim'],'The real first target hit must not be rejected by background-only cover')
    assert(queries==2,'Cursor selection plus one final muzzle query must cover Endmath and mandatory wall checks')
    blocked=true;step(.02)
    assert(not rt.Points['Silent Aim'],'Foreground geometry must still block the final muzzle path')
    rt:Destroy('test');World.Raycast=cast;clearInput()
end

-- An accepted point can move inside the part faster than Sharpness catches up.
-- A stale smoothed point must not suppress a fresh valid point under hard limits.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local s=cfg['Silent Aim'];s.Ignore=true;s.Prediction.Enabled=false;s.AntiCurve.Enabled=true
    s.AntiCurve['3d-angles'].Max=.02;s.Target.Closest.Selection='Point';s.Target.Closest.Axis='All'
    s.Target.Closest.Reduce.All=0;s.Target.Closest.Sharpness=.01
    moveEnemy(1,0,-50);local rt=loadRuntime(cfg);step(.02);assert(rt.Points['Silent Aim'])
    moveEnemy(-1,0,-50);step(.02)
    assert(rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].SmoothingBypassed,
        'Fresh allowed geometry can recover from a rejected stale smoothing anchor')
    rt:Destroy('test');moveEnemy(0,0,-50);clearInput()
end

-- Reusing a hitscan forecast must rebase support diagnostics to the final local
-- point, including when the ground guard removes falling lead.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local s=cfg['Silent Aim'];s.Ignore=true;s.AntiCurve.Enabled=false
    s.Prediction.Auto=false;s.Prediction.Value=.121
    s.Target.Closest.Raycast=false;s.Target.Closest.Selection='Point';s.Target.Closest.Axis='All'
    s.Target.Closest.Reduce.All=0;s.Target.Closest.Sharpness=1
    local savedSize=enemyTorso.Size;enemyTorso.Size=V.new(2,4,1)
    moveEnemy(0,3,-50);groundY=0;enemyHum.FloorMaterial=Enum.Material.Air
    enemyRoot.AssemblyLinearVelocity=V.new(0,-12,0)
    local rt=loadRuntime(cfg);step(.02)
    local point,evidence=rt.Points['Silent Aim'],rt.AimTrace['Silent Aim']
    assert(point and point.Y==1 and evidence.GroundCorrected)
    assert(evidence.GroundMinimumY==evidence.BasePoint.Y and evidence.PredictedPoint.Y==point.Y,
        'Support trace must use the actual final selected point, not the provisional center')
    rt:Destroy('test');enemyTorso.Size=savedSize;groundY=nil;enemyRoot.AssemblyLinearVelocity=V.new()
    enemyHum.FloorMaterial=Enum.Material.Plastic;moveEnemy(0,0,-50);clearInput()
end

-- Expanded body tolerance does not resize the target and stops outside its margin.
-- Rotated native parts and both timing modes keep predicted XYZ geometry coherent
-- for every feature. Mouse follow is unavailable in this mock, so Assist cannot
-- make this pass by moving the camera/cursor after selection.
do
    local savedSize,savedWalk,savedEnabled=enemyTorso.Size,enemyHum.WalkSpeed,tool.Enabled
    local savedRaycast,groundQueries=World.Raycast,0
    World.Raycast=function(self,origin,direction,params)
        if params.RespectCanCollide then groundQueries=groundQueries+1 end
        return savedRaycast(self,origin,direction,params)
    end
    enemyTorso.Size=V.new(2,4,1);tool.Enabled=false
    local function frame(origin,right,up,look)
        return {Position=origin,RightVector=right,UpVector=up,LookVector=look,
            PointToObjectSpace=function(self,p)
                local d=p-self.Position
                return V.new(d:Dot(right),d:Dot(up),-d:Dot(look))
            end,
            VectorToObjectSpace=function(self,d)return V.new(d:Dot(right),d:Dot(up),-d:Dot(look))end,
            PointToWorldSpace=function(self,p)return self.Position+right*p.X+up*p.Y-look*p.Z end}
    end
    local diagonal=math.sqrt(.5)
    local bases={
        {V.new(1,0,0),V.new(0,1,0),V.new(0,0,-1)},
        {V.new(diagonal,0,diagonal),V.new(0,1,0),V.new(diagonal,0,-diagonal)},
        {V.new(0,1,0),V.new(-1,0,0),V.new(0,0,-1)},
    }
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        for _,auto in ipairs({false,true})do
            for _,basis in ipairs(bases)do
                local cfg=Core.copy(Defaults)
                for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
                    cfg[name].Enabled=name==feature;cfg[name].Toggle.Enabled=false
                    cfg[name].Activation.Holding=false
                    cfg[name].Fov.Method='2d-Circle';cfg[name].Fov['2d-Circle'].Size=300
                    cfg[name].Prediction.Auto=auto;cfg[name].Prediction.Value=.121
                end
                cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].AntiCurve.Enabled=false
                cfg['Aim Assist'].Follow='Mouse';cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=true
                local closest=(feature=='Aim Assist' and cfg['Aim Assist'] or cfg['Silent Aim']).Target.Closest
                closest.Raycast=false;closest.Selection='Point';closest.Axis='All'
                closest.Reduce.All=0;closest.Sharpness=1
                local motion=V.new(14,6,-14);enemyHum.WalkSpeed=math.sqrt(14*14*2)
                local horizon=auto and .18 or .121;local shift=motion*horizon
                moveEnemy(-shift.X,-shift.Y,-50-shift.Z)
                enemyTorso.CFrame=frame(enemyTorso.Position,basis[1],basis[2],basis[3])
                enemyRoot.AssemblyLinearVelocity=motion;enemyHum.FloorMaterial=Enum.Material.Air
                local rt=loadRuntime(cfg);rt.Network.RTT=.18;rt.Network.DataRTT=.18;rt.Network.NextSample=clock+10
                groundQueries=0
                step(.02)
                local point=rt.Points[feature]
                assert(point and math.abs(point.X)<1e-6 and math.abs(point.Y)<1e-6,
                    'Predicted rotated geometry must meet the cursor for '..feature)
                assert(groundQueries==1,'Closest prediction must use one support query per selection, not two')
                local base=rt.AimTrace[feature].BasePoint
                local localPoint=enemyTorso.CFrame:PointToObjectSpace(V.new(base.X,base.Y,base.Z))
                assert(math.abs(localPoint.X)<=1+1e-7 and math.abs(localPoint.Y)<=2+1e-7 and math.abs(localPoint.Z)<=.5+1e-7)
                -- Exact surfaces retain their original pre-lead point instead of
                -- being silently replaced with the translated Closest Point.
                closest=rt.Config[feature=='Aim Assist' and feature or 'Silent Aim'].Target.Closest
                closest.Raycast=true;closest.Reduce.All=1;closest.Sharpness=.01
                local surface=enemyTorso.Position+V.new(.1,.2,.1)
                rayHit={Instance=enemyTorso,Position=surface};step(.02)
                local evidence=rt.AimTrace[feature]
                assert(evidence.PointSource=='cursor-surface' and evidence.BasePoint.X==surface.X
                    and evidence.BasePoint.Y==surface.Y and evidence.BasePoint.Z==surface.Z,
                    'Raycast keeps exact pre-prediction surface semantics for '..feature)
                rt:Destroy('test');rayHit=nil
            end
        end
    end
    enemyTorso.Size=savedSize;enemyHum.WalkSpeed=savedWalk;tool.Enabled=savedEnabled
    World.Raycast=savedRaycast
    enemyRoot.AssemblyLinearVelocity=V.new();enemyHum.FloorMaterial=Enum.Material.Plastic
    moveEnemy(0,0,-50);clearInput()
end

-- Expanded body tolerance does not resize the target and stops outside its margin.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Fov.Method='2d-Circle';cfg['Silent Aim'].Fov['2d-Circle'].Visible=true
    cfg['Silent Aim'].Fov['2d-Circle'].Size=75;cfg['Silent Aim'].EndMath={Visualizer=true}
    local rt=loadRuntime(cfg);step(.04)
    local outline,circle,halo,dot=false,false,false,false
    for _,d in ipairs(drawingObjects) do if not d.removed and d.Visible and d.Kind=='Circle' then
        if d.Radius==75 and d.Thickness==3 then outline=true end
        if d.Radius==75 and d.Thickness==1 then circle=true end
        if d.Radius==4 and d.Filled then halo=true end
        if d.Radius==2 and d.Filled then dot=true end
    end end
    assert(outline and circle and not halo and not dot,'FOV keeps its outline; the removed final-point visualizer creates no marker')
    rt.Config['Silent Aim'].Enabled=false;step(.04)
    for _,d in ipairs(drawingObjects) do if not d.removed and d.Kind=='Circle' then assert(not d.Visible,'Disabling the feature hides both visual layers') end end
    rt:Destroy('test')
end

-- Expanded body tolerance does not resize the target and stops outside its margin.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false
    local rt=loadRuntime(cfg)
    moveEnemy(1.1,0,-50);rayHit=nil
    local size=enemyTorso.Size
    key('MouseButton2',true);local prior=shots;step(.04)
    assert(shots==prior+1 and enemyTorso.Size==size,'1.2x local tolerance accepts near edge without resizing')
    moveEnemy(2,0,-50);step(.04)
    assert(not rt.MouseOwned,'Leaving expanded body releases input')
    rt.Config.Triggerbot.Fov.Character=.8
    moveEnemy(.9,0,-50);rayHit={Instance=enemyTorso,Position=V.new(0,0,-49.5)};step(.15)
    assert(not rt.MouseOwned,'A real edge hit outside shrunken bounds is rejected')
    moveEnemy(.5,0,-50);step(.04)
    assert(rt.MouseOwned,'A ray inside shrunken bounds remains eligible')

    key('MouseButton2',false);rt:Destroy('test');clearInput();moveEnemy(0,0,-50)
end

-- A present-position nearest part can leave the circle after airborne lead while
-- another real part enters it. Fixed BasePart and exact surfaces stay fixed.
do
    local oldMouse,oldEnabled=Input.GetMouseLocation,tool.Enabled
    Input.GetMouseLocation=function()return V.new(960,500)end;tool.Enabled=false
    local head=obj('Part','Head',enemyChar);head.Size=V.new(2,2,1)
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        for _,y in ipairs({'Auto','Custom','Disabled'})do
            local cfg=Core.copy(Defaults)
            for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
                cfg[name].Enabled=name==feature;cfg[name].Activation.Holding=false
                cfg[name].Prediction.Auto=false;cfg[name].Prediction.Value=.1
                cfg[name].Fov.Method='2d-Circle';cfg[name].Fov['2d-Circle'].Size=10
            end
            cfg['Y-Axis'].Enabled=y~='Disabled';cfg['Y-Axis'].Method=y=='Custom' and 'Custom' or 'Auto'
            cfg['Silent Aim'].AntiCurve.Enabled=false;cfg['Aim Assist'].Follow='Mouse'
            cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=true
            moveEnemy(0,0,-50);head.Position=V.new(0,2,-50);head.CFrame=CF.new(head.Position)
            enemyRoot.AssemblyLinearVelocity=V.new(0,20,0)
            local rt=loadRuntime(cfg);step(.02)
            local point,trace=rt.Points[feature],rt.AimTrace[feature]
            if feature=='Silent Aim' then
                assert(point and math.abs(point.Y-4)<1e-6 and trace.Part=='Head' and trace.FovReference=='base-point',
                    'Silent retains the actual acquired part while prediction supplies its shot point')
            else
                assert(point and math.abs(point.Y-2)<1e-6 and trace.Part=='UpperTorso' and trace.CandidateAttempt>=2,
                    'Try a usable predicted body part before discarding '..feature..' with Y '..y)
            end
            local target=(feature=='Aim Assist' and rt.Config[feature] or rt.Config['Silent Aim']).Target
            target.Closest.Enabled=false;target.BasePart='Head';step(.02)
            assert(feature=='Silent Aim' and rt.AimTrace[feature].Part=='Head' and rt.AimTrace[feature].CandidateAttempt==1
                or feature~='Silent Aim' and not rt.Points[feature], 'Fixed BasePart must not silently switch to an easier part')
            target.Closest.Enabled=true;target.Closest.Raycast=true
            rayHit={Instance=head,Position=head.Position};step(.02)
            assert((feature=='Silent Aim' or not rt.Points[feature]) and rt.AimTrace[feature].SurfacePart=='Head'
                and rt.AimTrace[feature].CandidateAttempt==1,
                'Exact surface contract cannot be replaced by an alternate body point')
            rt:Destroy('test');rayHit=nil
        end
    end
    head:Destroy();Input.GetMouseLocation=oldMouse;tool.Enabled=oldEnabled
    enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50);clearInput()
end

-- Third-person Closest Point solves the translated XYZ part against the native
-- muzzle-to-mouse ray. It does not loosen tight AntiCurve or tunnel through cover.
do
    local savedHit,savedWalk,savedSize=mouse.Hit,enemyHum.WalkSpeed,enemyTorso.Size
    local savedRaycast=World.Raycast
    enemyHum.WalkSpeed=math.sqrt(200);enemyTorso.Size=V.new(2,4,1)
    for _,y in ipairs({'Auto','Custom','Disabled'})do
        for _,auto in ipairs({false,true})do
            for _,side in ipairs({-1,1})do
                local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
                local s=cfg['Silent Aim'];s.Ignore=true;s.AntiCurve.Enabled=true
                s.AntiCurve['3d-angles'].Max=.001;s.Prediction.Auto=auto;s.Prediction.Value=.1
                s.Target.Closest.Selection='Point';s.Target.Closest.Axis='All'
                s.Target.Closest.Reduce.All=0;s.Target.Closest.Sharpness=1
                cfg['Y-Axis'].Enabled=y~='Disabled';cfg['Y-Axis'].Method=y=='Custom' and 'Custom' or 'Auto'
                cfg.Checks.GroundShotCheck[1]=false
                handle.Position=V.new(5*side,2,0);mouse.Hit=CF.new(0,0,-100)
                local motion=V.new(-10*side,5,10);local horizon=auto and .18 or .1
                local center=V.new(3*side,1.2,-40)
                moveEnemy(center.X-motion.X*horizon,center.Y-motion.Y*horizon,center.Z-motion.Z*horizon)
                enemyRoot.AssemblyLinearVelocity=motion
                local rt=loadRuntime(cfg);rt.Network.RTT=.18;rt.Network.DataRTT=.18;rt.Network.NextSample=clock+10
                step(.02)
                local trace=rt.AimTrace['Silent Aim'];local point=rt.Points['Silent Aim']
                assert(point and trace.PointRay=='muzzle' and trace.AntiCurveDistance<.001,
                    'Third-person predicted XYZ point must retain native alignment for Y '..y)
                local base=V.new(trace.BasePoint.X,trace.BasePoint.Y,trace.BasePoint.Z)-enemyTorso.Position
                assert(math.abs(base.X)<=1+1e-6 and math.abs(base.Y)<=2+1e-6 and math.abs(base.Z)<=.5+1e-6)
                World.Raycast=function(self,origin,direction,params)
                    if params.RespectCanCollide then return nil end
                    if origin.X==handle.Position.X then return {Instance=World,Position=origin+direction*.2} end
                end
                step(.02);assert(not rt.Points['Silent Aim'],'Muzzle cover must still reject the native-aligned prediction')
                rt:Destroy('test');World.Raycast=savedRaycast
            end
        end
    end
    mouse.Hit=savedHit;enemyHum.WalkSpeed=savedWalk;enemyTorso.Size=savedSize
    handle.Position=V.new();enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50);clearInput()
end

-- Integrate measured jump physics, XYZ translation, arbitrary camera bases,
-- native muzzle alignment and the actual mocked MOUSE send at activation.
do
    local savedView,savedRay,savedProject=camera.CFrame,camera.ViewportPointToRay,camera.WorldToViewportPoint
    local savedHit,savedWalk,savedSize=mouse.Hit,enemyHum.WalkSpeed,enemyTorso.Size
    function camera:ViewportPointToRay(x,y)
        local c=self.CFrame
        local direction=c.LookVector+c.RightVector*((x-960)/1000)+c.UpVector*(-(y-540)/1000)
        return {Origin=c.Position,Direction=direction.Unit}
    end
    function camera:WorldToViewportPoint(p)
        local c=self.CFrame;local d=p-c.Position;local z=d:Dot(c.LookVector)
        return V.new(960+d:Dot(c.RightVector)*1000/math.max(z,.01),540-d:Dot(c.UpVector)*1000/math.max(z,.01),z),z>0
    end
    local bases={
        {V.new(1,0,0),V.new(0,1,0),V.new(0,0,-1)},
        {V.new(-1,0,0),V.new(0,1,0),V.new(0,0,1)},
        {V.new(0,0,1),V.new(0,1,0),V.new(1,0,0)},
        {V.new(1,0,0),V.new(0,.8,-.6),V.new(0,-.6,-.8)},
        {V.new(0,1,0),V.new(-1,0,0),V.new(0,0,-1)},
    }
    enemyHum.WalkSpeed=math.sqrt(164);enemyTorso.Size=V.new(2,4,1)
    for _,basis in ipairs(bases)do
        for _,y in ipairs({'Auto','Custom','Disabled'})do
            for _,auto in ipairs({false,true})do
                local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
                local s=cfg['Silent Aim'];s.Ignore=true;s.AntiCurve.Enabled=true;s.AntiCurve['3d-angles'].Max=.001
                s.Prediction.Auto=auto;s.Prediction.Value=.1
                s.Target.Closest.Selection='Point';s.Target.Closest.Axis='All'
                s.Target.Closest.Reduce.All=0;s.Target.Closest.Sharpness=1
                cfg['Y-Axis'].Enabled=y~='Disabled';cfg['Y-Axis'].Method=y=='Custom' and 'Custom' or 'Auto'
                cfg.Checks.GroundShotCheck[1]=false
                local right,up,look=basis[1],basis[2],basis[3];local origin=V.new(12,8,15)
                camera.CFrame={Position=origin,RightVector=right,UpVector=up,LookVector=look}
                handle.Position=origin+right*5+up*2;mouse.Hit=CF.new(origin+look*100)
                local horizon=auto and .18 or .1;local motion=V.new(10,12,-8)
                local lead=motion*horizon
                if y=='Auto' then lead=lead+V.new(0,-90*horizon*horizon,0) end
                local center=origin+look*40+right*3+up*1.2;local current=center-lead
                moveEnemy(current.X,current.Y,current.Z);enemyRoot.AssemblyLinearVelocity=motion
                local rt=loadRuntime(cfg);rt.Network.RTT=.18;rt.Network.DataRTT=.18;rt.Network.NextSample=clock+10
                local record=rt.Records[enemy];record.history={};record.sampledVelocity=nil
                for i=0,7 do
                    local t=(i-7)*.02
                    Core.sample(record.history,current+motion*t+V.new(0,-90*t*t,0),clock+t,motion+V.new(0,-180*t,0))
                end
                tool.Activated:Fire()
                local point,trace=rt.Points['Silent Aim'],rt.AimTrace['Silent Aim']
                assert(point and trace.PointRay=='muzzle' and trace.AntiCurveDistance<.001,
                    'Native XYZ alignment must survive side/rear/elevated/rolled camera bases')
                assert(trace.VerticalValidated and math.abs(trace.LeadAfterY.Y-lead.Y)<1e-6)
                assert((rt.LastSend.Point.X-point.X)^2+(rt.LastSend.Point.Y-point.Y)^2+(rt.LastSend.Point.Z-point.Z)^2<1e-12,
                    'The mock MOUSE payload must equal the validated final XYZ point')
                assert(rt.LastShot.serverPoint==point and rt.LastSend.Returned)
                rt:Destroy('test')
            end
        end
    end
    camera.CFrame=savedView;camera.ViewportPointToRay=savedRay;camera.WorldToViewportPoint=savedProject
    mouse.Hit=savedHit;enemyHum.WalkSpeed=savedWalk;enemyTorso.Size=savedSize
    handle.Position=V.new();enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50);clearInput()
end

-- Helper dimensions are selection geometry, not the real body's Y-motion limit.
do
    local cfg=Core.copy(Defaults);cfg['Silent Aim'].Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Character=1
    cfg['Y-Axis'].Enabled=true;cfg['Y-Axis'].Method='Auto';cfg.Checks.GroundShotCheck[3]=false
    cfg.Triggerbot.Prediction.Auto=false;cfg.Triggerbot.Prediction.Value=.1
    local oldSize,oldEnabled,oldMouse=enemyTorso.Size,tool.Enabled,Input.GetMouseLocation
    enemyTorso.Size=V.new(2,4,1);tool.Enabled=false
    Input.GetMouseLocation=function()return V.new(960,340)end
    moveEnemy(0,10,-50);enemyRoot.AssemblyLinearVelocity=V.new(0,-30,0)
    local hb=obj('Part','HB',enemyChar);hb.Position=enemyRoot.Position;hb.CFrame=CF.new(hb.Position)
    local rt=loadRuntime(cfg)
    for _,height in ipairs({1,40})do
        hb.Size=V.new(2,height,1);rayHit={Instance=hb,Position=V.new(0,10,-49.5)};step(.02)
        assert(rt.Points.Triggerbot and math.abs(rt.Points.Triggerbot.Y-7)<1e-6,
            'Helper size cannot change the same target\'s vertical shot lead')
        assert(rt.AimTrace.Triggerbot.Part=='UpperTorso' and rt.AimTrace.Triggerbot.SurfacePart=='HB')
    end
    rt:Destroy('test');hb:Destroy();rayHit=nil;enemyTorso.Size=oldSize;tool.Enabled=oldEnabled
    Input.GetMouseLocation=oldMouse;enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50);clearInput()
end

-- Camera selection failure must not suppress an independently eligible muzzle ray.
do
    local cfg=Core.copy(Defaults);cfg['Silent Aim'].Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Character=1;cfg.Triggerbot.Prediction.Enabled=false
    local rival=obj('Player','MuzzleCandidate',Players);rival.UserId=87;rival.DisplayName='MuzzleCandidate'
    local rivalChar,rivalRoot,rivalHum,rivalTorso=character(rival,-25)
    rivalRoot.Position=V.new(2.5,0,-25);rivalRoot.CFrame=CF.new(rivalRoot.Position)
    rivalTorso.Position=rivalRoot.Position;rivalTorso.CFrame=CF.new(rivalRoot.Position)
    local oldRaycast,oldEnabled=World.Raycast,tool.Enabled
    tool.Enabled=false;handle.Position=V.new(5,0,0);enemyChar.props['attr:Knocked']=true
    World.Raycast=function(self,origin,direction,params)
        if params.RespectCanCollide then return nil end
        local part=origin.X==5 and rivalTorso or enemyTorso
        return {Instance=part,Position=part.Position}
    end
    local rt=loadRuntime(cfg);step(.02)
    assert(rt.Targets.Triggerbot==rival and rt.AimTrace.Triggerbot.SelectionRay=='muzzle',
        'Rejected camera target cannot starve an eligible native muzzle target')
    rt:Destroy('test');World.Raycast=oldRaycast;tool.Enabled=oldEnabled;handle.Position=V.new()
    enemyChar.props['attr:Knocked']=nil;rivalChar:Destroy();rival:Destroy();clearInput()
end

-- Native trigger input: immediate press, configured hold, cancellation, optional FOV.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false
    local hb=obj('Part','HB',enemyChar);hb.Size=V.new(4,4,1);hb.CanQuery=true
    local rt=loadRuntime(cfg)
    local function place(x)
        moveEnemy(x,0,-50);hb.Position=enemyRoot.Position;hb.CFrame=CF.new(hb.Position)
    end
    place(2.1);rayHit=nil;rt.Config.Triggerbot.Fov.Character=1
    key('MouseButton2',true);step(.04);assert(not rt.MouseOwned)
    rt.Config.Triggerbot.Fov.Character=1.3;step(.04)
    assert(rt.MouseOwned and rt.AimTrace.Triggerbot.SurfacePart=='HB','Expand the actual native HB, not just smaller visible limbs')
    rt.Config.Triggerbot.Fov.Character=.8;place(1.8)
    rayHit={Instance=hb,Position=V.new(0,0,-49.5)};step(.04)
    assert(not rt.MouseOwned,'A native HB hit must still respect shrinking')
    place(1.4);step(.15);assert(rt.MouseOwned,'Shrunken HB interior remains eligible')
    rayHit={Instance=World,Position=V.new(0,0,-5)};step(.04)
    assert(not rt.MouseOwned,'Scaled selection cannot pass through a nearer wall')
    key('MouseButton2',false);rt:Destroy('test');hb:Destroy();clearInput();moveEnemy(0,0,-50);rayHit=nil
end

ammo.Value=20
local trigger=loadRuntime(Defaults)
trigger.Config.Triggerbot.Fov.Character=1 -- Exact-ray legacy mode; expanded mode is checked separately.
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
assert(shots==before,'Triggerbot Wall check also rejects a blocked muzzle')
isolated.Config.Checks.Wall[3]=false;step(.04)
assert(shots==before+1,'Disabling Triggerbot Wall remains independent of Silent final filters')
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
    local ownedVisuals=0;for _ in pairs(replacement.Visuals) do ownedVisuals=ownedVisuals+1 end
    assert(aliveDrawings==ownedVisuals,'No drawings left by replaced instances before first render')
end
replacement:Destroy('test');clearInput()

-- Table-only updates are atomic and never rebuild listeners, history or drawings.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false
    cfg['Aim Assist'].Activation.Holding=false
    local rt=loadRuntime(cfg);step(.04)
    local originalConfig=rt.Config
    local bad=Core.copy(cfg);bad['Aim Assist'].Smoothness='invalid'
    local beforeConnections,beforeRenders=activeConnections(),renderCount()
    local history=rt.Records[enemy].history
    local beforeVisuals=0;for _ in pairs(rt.Visuals)do beforeVisuals=beforeVisuals+1 end
    rt.ShotRelease=env.mouse1release;rt.MouseOwned=true;Input.keys.MouseButton1=true
    assert(not pcall(function()rt:ApplyConfig(bad)end),'Invalid config is rejected')
    assert(rt.Alive and rt.Config==originalConfig and rt.MouseOwned,'Validation must not partially change running state or owned input')
    rt.Toggles['Silent Aim']=false;rt.Locks['Aim Assist']=enemy.UserId
    cfg['Silent Aim'].Prediction.Value=.17
    cfg['2d-Box']['Silent Aim'].Size.Width=12
    rt.AutoPrediction.Features['Silent Aim']={Target=enemy.UserId,NextSample=math.huge}
    local returned=rt:ApplyConfig(cfg)
    assert(returned==rt and env.__neoperroRuntimeV1==rt and rt.Config~=originalConfig)
    assert(not rt.MouseOwned and not Input.keys.MouseButton1,'Table updates release owned firing input')
    assert(not rt.Toggles['Silent Aim'] and rt.Locks['Aim Assist']==enemy.UserId,'User toggles and valid locks survive')
    assert(rt.Config['Silent Aim'].Prediction.Value==.17 and rt.Config['2d-Box']['Silent Aim'].Size.Width==12)
    assert(next(rt.AutoPrediction.Features)==nil and next(rt.Points)==nil,'Forecast and selected-point caches are invalidated')
    assert(rt.Records[enemy].history==history,'Motion history stays warm')
    cfg['Silent Aim'].Toggle.Enabled=false
    rt:ApplyConfig(cfg);step(.04)
    assert(rt.Toggles['Silent Aim'] and rt.Targets['Silent Aim']==enemy,'Disabling the toggle restores an enabled feature without an inaccessible off latch')
    cfg.Whitelist.Enabled=true;rt:ApplyConfig(cfg)
    rt.Whitelist={enemy.UserId};rt:ApplyConfig(cfg)
    assert(#rt.Whitelist==1,'Unchanged whitelist config preserves assignments')
    cfg.Whitelist.Players={other.UserId};rt:ApplyConfig(cfg)
    assert(#rt.Whitelist==1 and rt.Whitelist[1]==other.UserId,'An edited list takes effect immediately')
    cfg.Whitelist.Enabled=false
    for i=1,50 do
        cfg['2d-Box']['Silent Aim'].Size.Width=5+i*.01
        rt:ApplyConfig(cfg);step(.04)
        assert(activeConnections()==beforeConnections and renderCount()==beforeRenders,'No listeners or render callbacks accumulate')
        assert(hooks.__namecall==hookBefore and rt.Records[enemy].history==history,'No extra hooks or discarded history')
        local count=0;for _ in pairs(rt.Visuals)do count=count+1 end
        assert(count==beforeVisuals,'No drawings accumulate from table edits')
    end
    assert(#rt.Whitelist==0 and rt.ConfigUpdates==55)
    rt:Destroy('test')
    assert(not pcall(function()rt:ApplyConfig(cfg)end),'A stopped runtime cannot accept a config update')
    clearInput()
end

-- An empty assignment list allows all three features; assignment and clearing take effect live.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg['Silent Aim'].Toggle.Keybind={'LeftShift','MouseButton2','Keyboard'}
    local rt=loadRuntime(cfg)
    key('LeftShift',true);key('LeftShift',true)
    assert(not rt.Toggles['Silent Aim'],'Repeated begins cannot toggle twice without a release')
    cfg['Silent Aim'].Toggle.Holding=true;cfg['Silent Aim'].Toggle.Keybind={' leftshift ','MouseButton2','keyboard'}
    rt:ApplyConfig(cfg);step(.04)
    assert(rt.Targets['Silent Aim']==enemy,'Changing toggle mode/binding cannot inherit a stale off latch')
    key('LeftShift',false);step(.04);assert(not rt.Targets['Silent Aim'])
    key('LeftShift',true,true);step(.04);assert(not rt.Targets['Silent Aim'],'Physical polling cannot bypass processed input')
    key('LeftShift',false);key('LeftShift',true);step(.04);assert(rt.Targets['Silent Aim']==enemy)
    key('LeftShift',false)
    cfg['Silent Aim'].Toggle.Holding=false;cfg['Aim Assist'].Enabled=true;cfg['Aim Assist'].Activation.Holding=false
    for _,name in ipairs({'Silent Aim','Aim Assist'})do cfg[name].Toggle.Keybind={'p','mousebutton2','mouse'} end
    rt:ApplyConfig(cfg);key('MouseButton2',true);key('MouseButton2',true);step(.04)
    assert(not rt.Toggles['Silent Aim'] and not rt.Toggles['Aim Assist'],'Shared mouse toggles dispatch once independently')
    key('MouseButton2',false);key('MouseButton2',true);step(.04)
    assert(rt.Targets['Silent Aim'] and rt.Targets['Aim Assist'])
    rt:Destroy('test');clearInput()
end

-- Replacing or editing the public table updates the current session. A rejected
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Method='Target';cfg['Silent Aim'].Activation.Holding=true
    Input.keys.T=true
    local rt=loadRuntime(cfg);step(.02)
    assert(rt.Targets['Silent Aim']==enemy,'A held Target binding can acquire even if the begin preceded execution')
    key('T',false);step(.02);assert(not rt.Targets['Silent Aim'])
    cfg['Silent Aim'].Method='Auto';cfg.Whitelist.Enabled=true
    rt=loadRuntime(cfg);key('R',true);key('R',false)
    assert(rt.Whitelist[1]==enemy.UserId,'Assignment before the first render captures a fresh view')
    rt:Destroy('test');clearInput()
end

-- Replacing or editing the public table updates the current session. A rejected
-- table leaves runtime/input ownership untouched and can be corrected in place.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false
    local rt=loadRuntime(cfg);step(.04)
    local count,render=activeConnections(),renderCount()
    local history=rt.Records[enemy].history
    env.neoperro=Core.copy(cfg);env.neoperro['2d-Box']['Silent Aim'].Size.Width=9
    step(.26)
    assert(rt.Config['2d-Box']['Silent Aim'].Size.Width==9 and rt.ConfigUpdates==1,'A new table applies without rejoining or reloading')
    env.neoperro['Silent Aim'].Prediction.Value=.18;step(.26)
    assert(rt.Config['Silent Aim'].Prediction.Value==.18 and rt.ConfigUpdates==2,'Nested edits are detected too')
    local previous=rt.Config
    env.neoperro['Aim Assist'].Smoothness='invalid';step(.26)
    assert(rt.Config==previous and rt.Alive and rt.LastConfigError and rt.ConfigUpdates==2)
    step(.26);assert(rt.ConfigUpdates==2,'The same rejected table cannot repeatedly reset the runtime')
    env.neoperro['Aim Assist'].Smoothness=.05;step(.26)
    assert(rt.ConfigUpdates==3 and not rt.LastConfigError)
    assert(activeConnections()==count and renderCount()==render and rt.Records[enemy].history==history,'Updates do not stack resources or discard history')
    rt:Destroy('test');clearInput()
end

do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Activation.Holding=false
    local rt=loadRuntime(cfg);key('MouseButton2',true);key('MouseButton2',false)
    assert(rt.Held['activation:Triggerbot'])
    cfg.Triggerbot.Delay=.15;rt:ApplyConfig(cfg)
    assert(rt.Held['activation:Triggerbot'],'Unrelated table edits preserve the activation latch')
    cfg.Triggerbot.Activation.Keybind={'F1','MouseButton3','Keyboard'};rt:ApplyConfig(cfg)
    assert(not rt.Held['activation:Triggerbot'],'Rebinding resets the old activation latch')
    rt:Destroy('test');clearInput()
end

-- An empty assignment list allows all three features; assignment and clearing take effect live.
do
    local savedAmmo=ammo.Value;ammo.Value=100;moveEnemy(0,0,-50)
    local otherParent,otherPosition=other.Parent,otherRoot.Position
    other.Parent=Players;otherRoot.Position=V.new(20,0,-50)
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'}) do
        local cfg=Core.copy(Defaults)
        cfg.Whitelist.Enabled=true;cfg.Whitelist.Method='Target';cfg.Whitelist.Players={}
        cfg['Aim Assist'].Activation.Holding=false
        cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=true
        for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'}) do
            cfg[name].Enabled=name==feature;cfg[name].Prediction.Enabled=false
        end
        local rt=loadRuntime(cfg);step(.12)
        assert(rt.Targets[feature]==enemy,'Empty Target whitelist allows '..feature)
        rt.Whitelist={other.UserId};step(.12)
        assert(rt.Targets[feature]~=enemy,'Assignment restricts '..feature)
        rt.Whitelist={};step(.12)
        assert(rt.Targets[feature]==enemy,'Clearing the Target list restores '..feature)
        rt.WhiteMode='Friend';rt.Whitelist={enemy.UserId};step(.12)
        assert(rt.Targets[feature]~=enemy,'Friend excludes assigned player for '..feature)
        rt.Whitelist={};step(.12)
        assert(rt.Targets[feature]==enemy,'Empty Friend list restores '..feature)
        rt:Destroy('test');clearInput()
    end
    other.Parent,otherRoot.Position=otherParent,otherPosition
    ammo.Value=savedAmmo
end

-- Offline assignments cannot strand Target mode. Roster changes invalidate the
-- cached membership even when the saved assignment list stays unchanged.
do
    local assigned=obj('Player','AssignedLeaving',Players);assigned.UserId=79
    local assignedChar,assignedRoot=character(assigned,-50);assignedRoot.Position=V.new(20,0,-50)
    local savedAmmo=ammo.Value;ammo.Value=100;moveEnemy(0,0,-50)
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        for _,mode in ipairs({'Target','Friend'})do
            assigned.Parent=Players
            local cfg=Core.copy(Defaults);cfg.Whitelist.Enabled=true;cfg.Whitelist.Method=mode
            cfg.Whitelist.Players={assigned.UserId,999999}
            cfg['Aim Assist'].Activation.Holding=false;cfg.Triggerbot.Activation.Enabled=false
            cfg.Triggerbot.Fov.Enabled=true
            for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
                cfg[name].Enabled=name==feature;cfg[name].Prediction.Enabled=false
            end
            local rt=loadRuntime(cfg);step(.12)
            assert(rt.WhiteActiveCount==1 and (rt.Targets[feature]==enemy)==(mode=='Friend'))
            Players.PlayerRemoving:Fire(assigned)
            step(.12)
            assert(rt.WhiteActiveCount==0 and rt.Targets[feature]==enemy,
                'Last assigned departure restores eligibility for '..feature..' in '..mode)
            assigned.Parent=nil;step(.12)
            assert(rt.Targets[feature]==enemy and #rt.Whitelist==2,'Saved offline IDs cannot block everyone')
            assigned.Parent=Players;Players.PlayerAdded:Fire(assigned);step(.12)
            assert(rt.WhiteActiveCount==1 and (rt.Targets[feature]==enemy)==(mode=='Friend'),
                'A returning assigned user restores the configured filtering')
            rt:Destroy('test');clearInput()
            assigned.Parent=nil
            rt=loadRuntime(cfg);step(.12)
            assert(rt.WhiteActiveCount==0 and rt.Targets[feature]==enemy,'An offline-only table allows everyone at startup')
            rt:ApplyConfig(cfg);step(.12)
            assert(rt.Targets[feature]==enemy,'Reapplying an offline-only table cannot relock targeting')
            rt:Destroy('test');clearInput()
        end
    end
    assignedChar:Destroy();assigned:Destroy();ammo.Value=savedAmmo
end

do
    local cfg=Core.copy(Defaults);cfg.Whitelist.Enabled=false;cfg.Whitelist.Players={other.UserId}
    local rt=loadRuntime(cfg)
    cfg.Whitelist.Enabled=true;rt:ApplyConfig(cfg)
    assert(rt.Whitelist[1]==other.UserId,'Re-enabling applies the configured list instead of preserving a disabled empty list')
    cfg.Whitelist.Enabled=false;rt=loadRuntime(cfg)
    cfg.Whitelist.Enabled=true;rt=loadRuntime(cfg)
    assert(rt.Whitelist[1]==other.UserId,'Full replacement also restores an explicitly configured list when re-enabled')
    rt:Destroy('test');clearInput()
end

-- A denied native press and denied virtual press may fall back without losing shot context.
local savedPress,savedRelease=env.mouse1press,env.mouse1release
env.mouse1press=function()error('native denied')end
ammo.Value=20
local fallback=loadRuntime(rc);key('MouseButton2',true);step(0.12)
assert(fallback.Capabilities.FireInput=='Tool.Activate fallback' and fallback.FiringSource=='Triggerbot' and fallback.ForcedPoint,'Fallback retains owned cycle and target')
fallback:Destroy('test');clearInput();env.mouse1press,env.mouse1release=savedPress,savedRelease

-- Disabled Macro Abuse ignores fast movement; enabled checks the game's speed gate.
myRoot.AssemblyLinearVelocity=V.new(45,0,0)
local disabled=loadRuntime(Defaults)
local eventCount=#keyEvents;tool.Activated:Fire();step(.3)
assert(tool.Parent==myChar and #keyEvents==eventCount,'Disabled Macro Abuse must do nothing')
disabled:Destroy('test');clearInput()
local mc=Core.copy(Defaults);mc.Misc['Macro Abuse'].Enabled=true
local macroRuntime=loadRuntime(mc)
myRoot.AssemblyLinearVelocity=V.new(16,0,0)
zoomMacro();tool.Activated:Fire();step(.3)
assert(tool.Parent==myChar,'Zoom keys with normal walking do not authorize a cycle')
myRoot.AssemblyLinearVelocity=V.new(0,100,0)
tool.Activated:Fire();step(.3);assert(tool.Parent==myChar,'Vertical jumping does not count as macro speed')
myRoot.AssemblyLinearVelocity=V.new(45,0,0)
local initialAmmo=ammo.Value
tool.Activated:Fire();step(.05);assert(tool.Parent==backpack,'Fast movement starts cycle without ammo confirmation')
step(.07);assert(Input.keys.LeftControl)
step(.08);assert(tool.Parent==myChar)
step(.08);assert(not Input.keys.LeftControl and ammo.Value==initialAmmo)
tool.Activated:Fire();step(.05);step(.07);assert(Input.keys.LeftControl)
env.neoperro.Misc['Macro Abuse'].Enabled=false;step(.01)
assert(not Input.keys.LeftControl and tool.Parent==myChar,'Disable cancels and restores tool')
env.neoperro.Misc['Macro Abuse'].Enabled=true
myRoot.AssemblyLinearVelocity=V.new(45,0,0);tool.Activated:Fire();step(.05)
myRoot.AssemblyLinearVelocity=V.new(16,0,0);step(.07)
assert(Input.keys.LeftControl,'Game shot slowdown does not cancel an already qualified bounded cycle')
step(.08);step(.08);assert(tool.Parent==myChar and not Input.keys.LeftControl)
local myHead=obj('Part','Head',myChar);myHead.AssemblyLinearVelocity=V.new(16,0,0)
myRoot.AssemblyLinearVelocity=V.new(50,0,0);step(.15);tool.Activated:Fire();step(.05)
assert(tool.Parent==myChar,'Head speed is authoritative when Head exists')
myHead.AssemblyLinearVelocity=V.new(45,0,0);myRoot.AssemblyLinearVelocity=V.new(16,0,0)
tool.Activated:Fire();step(.05);assert(tool.Parent==backpack,'Fast Head passes even when root is slower')
step(.07);step(.08);step(.08)
myHead.AssemblyLinearVelocity=V.new(45,0,0);step(.02)
myHead.AssemblyLinearVelocity=V.new();tool.Activated:Fire();step(.05)
assert(tool.Parent==backpack and macroRuntime.LastMacroCheck.Source=='recent-pre-shot-speed','Pre-shot speed survives game velocity reset before activation')
step(.07);step(.08);step(.08)
myHead.AssemblyLinearVelocity=V.new();step(.15);tool.Activated:Fire();step(.05)
assert(tool.Parent==myChar and not macroRuntime.LastMacroCheck.Detected,'Expired pre-shot speed cannot authorize a later stationary shot')
myHead:Destroy()
-- Long frames do not replay a stale macro or leave owned Ctrl/tool state stuck.
myRoot.AssemblyLinearVelocity=V.new(45,0,0)
tool.Activated:Fire();step(.05);step(.07);assert(Input.keys.LeftControl)
step(.8)
assert(not Input.keys.LeftControl and tool.Parent==myChar and macroRuntime.MacroStatus.Result=='stalled',
    'A stalled phase must release owned Ctrl and restore its tool at the next update')
local unequip=myHum.UnequipTools;local failures=0
myHum.UnequipTools=function()failures=failures+1;error('mock unequip rejection')end
tool.Activated:Fire();assert(pcall(step,.05));step(.05)
assert(failures==1 and not macroRuntime.MacroStatus.Active and macroRuntime.MacroStatus.Result=='unequip-failed',
    'A failed action cannot throw every frame and stall other features')
myHum.UnequipTools=unequip
local equip=myHum.EquipTool
tool.Activated:Fire();step(.05);step(.07);assert(Input.keys.LeftControl)
myHum.EquipTool=function()error('mock equip rejection')end
assert(pcall(step,.08))
assert(not Input.keys.LeftControl and not macroRuntime.MacroStatus.Active and macroRuntime.MacroStatus.Result=='equip-failed')
myHum.EquipTool=equip;myHum:EquipTool(tool)
macroRuntime.Config.Misc.Panic.Enabled=false
key('E',true);key('E',false);assert(macroRuntime.Alive,'Panic false honors its switch')
macroRuntime.Config.Misc.Panic.Enabled=true;key('E',true);key('E',false)
assert(not macroRuntime.Alive and activeConnections()==0 and renderCount()==0)
clearInput();myRoot.AssemblyLinearVelocity=V.new()

-- Prediction and the barrel-alignment filters.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Prediction.Enabled=false
    cfg['Silent Aim'].Target.Closest.Enabled=false;cfg['Silent Aim'].AntiCurve.Enabled=true
    cfg['Silent Aim'].AntiCurve.Method='3d-angles'
    local originalHit=mouse.Hit;mouse.Hit=CF.new(0,0,-5000)
    local rt=loadRuntime(cfg);step(.04)
    assert(rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].AntiCurveDistance<.01,'Background depth cannot manufacture a lateral curve')
    assert(rt.AimTrace['Silent Aim'].AntiCurveRawSurfaceDistance>4000,'Keep raw-surface evidence separately')
    moveEnemy(3,0,-50);step(.04)
    assert(not rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].Reason=='anti-curve-studs','The 2.2-stud lateral limit still rejects actual large redirects')
    rt.Config['Silent Aim'].AntiCurve['3d-angles'].Max=math.huge;step(.04)
    assert(rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].AntiCurveLimit==math.huge,'Unlimited only removes the distance threshold')
    rt.Config['Silent Aim'].AntiCurve['3d-angles'].Max=.000000001;moveEnemy(.000001,0,-50);step(.04)
    assert(not rt.Points['Silent Aim'],'Sub-nanostud tolerance is supported without an old fixed cap')
    rt.Config['Silent Aim'].AntiCurve['3d-angles'].Max=math.huge;rt.Config['Silent Aim'].Method='Target';rt.Locks['Silent Aim']=enemy.UserId
    moveEnemy(0,0,50);step(.04)
    assert(not rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].Reason=='anti-curve-direction','Unlimited cannot create a missing forward alignment')
    rt:Destroy('test');mouse.Hit=originalHit;moveEnemy(0,0,-50)
end

-- Third-person parallax: a valid muzzle corridor survives a blocked camera path.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Prediction.Enabled=false
    cfg['Silent Aim'].Target.Closest.Enabled=false;cfg['Silent Aim'].AntiCurve.Enabled=true
    cfg['Aim Assist'].Ignore=true;cfg['Aim Assist'].Prediction.Enabled=false
    local originalHit,raycast=mouse.Hit,World.Raycast
    handle.Position=V.new(5,0,0);mouse.Hit=CF.new(0,0,-100);moveEnemy(3,0,-40)
    World.Raycast=function(self,origin,direction,params)
        if origin.X==0 then return {Instance=World,Position=origin+direction*.1} end
        return nil
    end
    local rt=loadRuntime(cfg);key('Q',true);step(.04)
    assert(rt.Points['Silent Aim'] and not rt.Points['Aim Assist'],'Firing uses a clear muzzle while assistance respects its camera wall')
    assert(rt.AimTrace['Silent Aim'].AntiCurveCameraDistance>2.2 and rt.AimTrace['Silent Aim'].AntiCurveMuzzleDistance<.01)
    assert(rt.AimTrace['Silent Aim'].AntiCurveReference=='muzzle-to-mouse-ray')
    rt.Config['Silent Aim'].AntiCurve.Method='Endmath';rt.Config['Silent Aim'].AntiCurve.Endmath.Radius=10;step(.04)
    assert(rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].AntiCurveCameraPixels>10,'Pixel mode also accounts for native muzzle alignment')
    rt.Config.Triggerbot.Enabled=true;rt.Toggles.Triggerbot=true;rt.Config.Triggerbot.Fov.Character=1
    World.Raycast=function(self,origin,direction,params)
        if origin.X==0 then return {Instance=World,Position=origin+direction*.1} end
        return {Instance=enemyTorso,Position=enemyTorso.Position}
    end
    key('MouseButton2',true);step(.04)
    assert(rt.Targets.Triggerbot==enemy,'FOV-off Triggerbot recognizes a real muzzle ray hit in third person')
    World.Raycast=function()return {Instance=World,Position=V.new(0,0,-5)}end;step(.04)
    assert(not rt.Points['Silent Aim'] and not rt.Targets.Triggerbot and not rt.MouseOwned,'Muzzle obstruction still rejects both firing paths')
    rt:Destroy('test');clearInput();World.Raycast=raycast;mouse.Hit=originalHit
    handle.Position=V.new();moveEnemy(0,0,-50);camera.CFrame=CF.new()
end

-- Rendering and selection follow live part motion between history updates.
do
    local cfg=Core.copy(Defaults);cfg['Silent Aim'].Enabled=false;cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg.ESP.VisibleCheck=false;cfg['2d-Box']['Silent Aim'].Visible=true;cfg['2d-Box']['Silent Aim']['Predicted Position']=true
    cfg['Silent Aim'].Prediction.Auto=false;cfg['Silent Aim'].Prediction.Value=.1
    enemyRoot.AssemblyLinearVelocity=V.new(100,0,0)
    local rt=loadRuntime(cfg);step(.04)
    local box
    for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then box=d end end
    assert(box and not rt.Targets['Silent Aim'],'ESP remains available independently of selection')
    assert(math.abs(box.Position.X+box.Size.X/2-960)<1e-6,'Removed predicted-position input cannot move the visible box off the actual character')
    assert(rt:Forecast(enemy,'Silent Aim').X>enemyRoot.Position.X,'Disabling predicted box position does not disable shot prediction')
    rt:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Rendering and selection follow live part motion between history updates.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg['Silent Aim'].Prediction.Enabled=false
    cfg['Silent Aim'].Target.Closest.Enabled=false;cfg.ESP.VisibleCheck=false
    local rt=loadRuntime(cfg);step(.04)
    local updates=rt.Performance.Updates
    local aimUpdates=rt.Performance.AimUpdates
    local historyCount=#rt.Records[enemy].history
    local box
    for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible and d.Thickness==1 then box=d end end
    assert(box and box.Visible)
    local oldX=box.Position.X
    for _=1,4 do
        moveEnemy(enemyRoot.Position.X+.001,0,-50);clock=clock+1/240
        for _,callback in pairs(renders)do callback(1/240)end
    end
    assert(rt.Performance.Updates==updates and box.Position.X>oldX,'Subpixel box updates on render frames without a history tick')
    assert(rt.Performance.AimUpdates==aimUpdates+4 and #rt.Records[enemy].history==historyCount,'Aim selection follows every frame while history fitting keeps its own cadence')
    assert(rt.Points['Silent Aim'].X==enemyRoot.Position.X,'Final target point refreshes without waiting for the old 60 Hz sampler')
    rt:Destroy('test');moveEnemy(0,0,-50)
end

-- Prediction and the barrel-alignment filters.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    local silent=cfg['Silent Aim'];silent.Ignore=true;silent.Target.Closest.Enabled=false
    silent.EndMath={VelocityHistory=false,WallCheck=false,Visualizer=true}
    silent.AntiCurve.Method='endmath';silent.AntiCurve.endmath={Radius=91,WallCheck=true};silent.AntiCurve.Endmath=nil
    silent.Prediction.Auto=false;cfg['Y-Axis'].Enabled=true
    local rt=loadRuntime(cfg)
    assert(rt.Config['Silent Aim'].EndMath==nil and rt.Config.Resolver.Method==nil)
    assert(rt.Config['Silent Aim'].AntiCurve.Method=='Endmath' and rt.Config['Silent Aim'].AntiCurve.Endmath.Radius==91)
    enemyHum.FloorMaterial=Enum.Material.Air;enemyRoot.AssemblyLinearVelocity=V.new()
    for i=0,7 do moveEnemy(i*.44,3-i*.3,-50-i*.16);step(.02) end
    local evidence=rt.AimTrace['Silent Aim']
    assert(evidence.Resolver=='TrueVelocity' and evidence.VelocitySource=='true-velocity')
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'}) do
        local _,forecast=rt:Forecast(enemy,feature,'UpperTorso')
        assert(forecast.Resolver=='TrueVelocity' and forecast.VelocitySource=='true-velocity','The shared resolver applies to every prediction feature')
    end
    assert(math.abs(evidence.ResolvedVelocity.X-22)<1e-6 and math.abs(evidence.ResolvedVelocity.Y+15)<1e-6 and math.abs(evidence.ResolvedVelocity.Z+8)<1e-6,'Persistent zero replicated velocity cannot hide coherent XYZ movement')
    assert(rt.Points['Silent Aim'].X>enemyRoot.Position.X and rt.Points['Silent Aim'].Y<enemyRoot.Position.Y,'Auto Y retains the measured falling correction')
    rt.Config.Resolver.Enabled=false
    for _,callback in pairs(renders)do callback(1/240)end
    assert(rt.Points['Silent Aim']==enemyRoot.Position and rt.AimTrace['Silent Aim'].VelocitySource=='raw','Resolver toggle changes the next render without restarting')
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'}) do
        local _,forecast=rt:Forecast(enemy,feature,'UpperTorso');assert(forecast.Resolver=='Disabled' and forecast.VelocitySource=='raw')
    end
    rt.Config.Resolver.Enabled=true
    for _,callback in pairs(renders)do callback(1/240)end
    assert(rt.AimTrace['Silent Aim'].VelocitySource=='true-velocity')
    rt.Config.Checks.Wall[1]=false;rt.Config['Silent Aim'].EndMath={WallCheck=false}
    handle.Position=V.new(5,0,0);muzzleBlocked=true;step(.02)
    assert(not rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].Reason=='final-wall','The internal final wall check cannot be disabled through an old table')
    rt:Destroy('test');muzzleBlocked=false;handle.Position=V.new();enemyHum.FloorMaterial=Enum.Material.Plastic;moveEnemy(0,0,-50)
end

-- Global aim restoration and native client bullets cover every firing source with Silent disabled.
do
    local oldHit,oldAmmo=mouse.Hit,ammo.Value;mouse.Hit=CF.new(12,1,-50)
    local enemyGun=obj('Tool','[Revolver]',enemyChar);local enemyAmmo=obj('IntValue','Ammo',enemyGun)
    for _,source in ipairs({'Manual','Triggerbot','Prefire'})do
        for _,globalEnabled in ipairs({true,false})do
            ammo.Value=6;enemyAmmo.Value=6
            local cfg=Core.copy(Defaults);cfg['Silent Aim'].Enabled=false
            cfg.Triggerbot.Enabled=source=='Triggerbot';cfg.Triggerbot.Fov.Enabled=true;cfg.Triggerbot.Prediction.Enabled=false
            cfg.Misc.Prefire.Enabled=source=='Prefire'
            cfg['Anti-AimViewer'].Enabled=globalEnabled;cfg['Client Bullets'].Enabled=globalEnabled
            local rt=loadRuntime(cfg);step(.04)
            if source=='Manual' then tool.Activated:Fire()
            elseif source=='Triggerbot' then key('MouseButton2',true);step(.04)
            else key('C',true);enemyAmmo.Value=5;step(.04);step(.26) end
            assert(rt.LastShot and (source=='Manual' or rt.FiringSource==source),'Each source records its own shot without Silent Aim')
            assert((rt.LastShot.point~=nil)==globalEnabled,'Client Bullets uses its global switch for every source')
            if source~='Manual' then assert((rt.Stats.AimRestores>0)==globalEnabled,'Every predicted firing source obeys global aim restoration')end
            local a=obj('Attachment','Start');a.WorldPosition=rt.LastShot.origin
            local b=obj('Attachment','End');b.Position=V.new();b.WorldPosition=rt.LastShot.serverPoint+V.new(1,.2,-2)
            local before=b.WorldPosition
            local beam=obj('Beam','gb');beam.Color='native-yellow';beam.Width0=.002;beam.Width1=.1;beam.Texture='native-texture';beam.Attachment0=a;beam.Attachment1=b;beam.Parent=World
            local expected=globalEnabled and Core.redirectTracer(a.WorldPosition,before,rt.LastShot.serverPoint,mouse.Hit.Position,V.new) or before
            assert((b.WorldPosition-expected).Magnitude<1e-6,'Global Client Bullets only rotates this client\'s native ray')
            assert(beam.Color=='native-yellow' and beam.Width0==.002 and beam.Width1==.1 and beam.Texture=='native-texture')
            rt:Destroy('test');clearInput();beam:Destroy();a:Destroy();b:Destroy();camera.CFrame=CF.new()
        end
    end
    enemyGun:Destroy();mouse.Hit=oldHit;ammo.Value=oldAmmo
end

-- Fixed rendering controls ignore old values and live mutation; distance has no configurable cap.
do
    local cfg=Core.copy(Defaults);cfg['Silent Aim'].Enabled=false;cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg.ESP.MaxDistance=0;cfg.ESP.VisibleCheck=false
    local style=cfg['2d-Box']['Silent Aim'];style['Max Distance']=0;style.Filled=true;style.Transparency=0;style['Predicted Position']=true
    moveEnemy(0,0,-1000000)
    local rt=loadRuntime(cfg);step(.04)
    local visual=rt.Records[enemy].visuals['Silent Aim'].box
    assert(visual and rt.Config.ESP.MaxDistance==nil and rt.Config['2d-Box']['Silent Aim'].Filled==nil)
    local function checkBox()
        local found=false
        for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Square' and d.Visible then
            assert(d.Filled==false and d.Transparency==1,'Boxes remain unfilled and fully opaque')
            found=true
        end end
        assert(found,'An on-screen distant character stays visible without a distance limit')
    end
    checkBox()
    rt.Config.ESP.MaxDistance=0;rt.Config['2d-Box']['Silent Aim']['Max Distance']=0
    rt.Config['2d-Box']['Silent Aim'].Filled=true;rt.Config['2d-Box']['Silent Aim'].Transparency=0
    rt.Config['2d-Box']['Silent Aim']['Predicted Position']=true;step(.04);checkBox()
    rt:Destroy('test');moveEnemy(0,0,-50)
end

-- Assist cannot acquire the removed FOV-bypass option through an old or mutated table.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Aim Assist'].Ignore=true
    cfg['Silent Aim'].Prediction.Enabled=false;cfg['Aim Assist'].Prediction.Enabled=false
    moveEnemy(20,0,-50)
    local rt=loadRuntime(cfg);key('Q',true);step(.04)
    assert(rt.Targets['Silent Aim']==enemy and not rt.Targets['Aim Assist'] and rt.Config['Aim Assist'].Ignore==nil)
    rt.Config['Aim Assist'].Ignore=true;step(.04);assert(not rt.Targets['Aim Assist'],'Assist FOV remains enforced after live mutation')
    rt:Destroy('test');clearInput();camera.CFrame=CF.new();moveEnemy(0,0,-50)
end

-- Shared Y settings and per-feature ground checks use the reordered table.
do
    local cfg=Core.copy(Defaults);cfg.Resolver.Enabled=false
    cfg['Y-Axis'].Enabled=true;cfg['Y-Axis'].Method='Custom';cfg['Y-Axis'].Offset=2
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do cfg[feature].Prediction.Auto=false;cfg[feature].Prediction.Value=.1 end
    local rt=loadRuntime(cfg);enemyHum.FloorMaterial=Enum.Material.Air;enemyRoot.AssemblyLinearVelocity=V.new(0,10,0);step(.04)
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local point,evidence=rt:Forecast(enemy,feature,'UpperTorso')
        assert(math.abs(point.Y-2)<1e-6 and evidence.YMethod=='Custom','Shared Custom offset applies to each enabled feature')
    end
    rt.Config['Y-Axis']['Aim Assist']=false
    local point,evidence=rt:Forecast(enemy,'Aim Assist','UpperTorso');assert(math.abs(point.Y-1)<1e-6 and evidence.YMethod=='Disabled')
    rt.Config['Y-Axis']['Aim Assist']=true;rt.Config['Y-Axis'].Method='Auto';rt.Config['Y-Axis'].Offset=5
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        point,evidence=rt:Forecast(enemy,feature,'UpperTorso');assert(math.abs(point.Y-1)<1e-6 and evidence.YMethod=='Auto','Auto ignores Custom Offset for every feature')
    end
    rt.Config['Y-Axis'].Enabled=false;moveEnemy(0,3,-50);enemyRoot.AssemblyLinearVelocity=V.new(0,-30,0);groundY=0;step(.04)
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do point=rt:Forecast(enemy,feature,'UpperTorso');assert(point.Y==3,'Each shared ground check prevents the predicted point from falling through support')end
    rt.Config.Checks.GroundShotCheck[2]=false
    point=rt:Forecast(enemy,'Aim Assist','UpperTorso');assert(point.Y<3)
    point=rt:Forecast(enemy,'Silent Aim','UpperTorso');assert(point.Y==3)
    point=rt:Forecast(enemy,'Triggerbot','UpperTorso');assert(point.Y==3,'Ground-check columns remain independent')
    rt:Destroy('test');groundY=nil;enemyHum.FloorMaterial=Enum.Material.Plastic;enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50)
end

-- Prediction and the barrel-alignment filters.
local modes=Core.copy(Defaults);modes['Silent Aim'].Ignore=true;
modes['Silent Aim'].Prediction.Auto=false
modes['Silent Aim'].Target.Closest.Enabled=false
modes['Y-Axis'].Enabled=true;modes['Y-Axis'].Method='Custom';modes['Y-Axis'].Offset=2
enemyRoot.AssemblyLinearVelocity=V.new(0,10,0)
local filtered=loadRuntime(modes);step(0.04)
assert(math.abs(filtered.Points['Silent Aim'].Y-2.56)<1e-6)
filtered.Config['Y-Axis'].Method='Auto';step(0.04)
assert(math.abs(filtered.Points['Silent Aim'].Y-1.28)<1e-6,'Rising motion is not erased by a stale floor material')
enemyRoot.AssemblyLinearVelocity=V.new();step(0.04);assert(filtered.Points['Silent Aim'].Y==0)
filtered.Config['Y-Axis'].Enabled=false
filtered.Config['Silent Aim'].AntiCurve.Enabled=true
filtered.Config['Silent Aim'].AntiCurve.Method='Endmath'
filtered.Config['Silent Aim'].AntiCurve.Endmath.Radius=1
enemyRoot.AssemblyLinearVelocity=V.new(100,0,0);step(0.04)
assert(filtered.Points['Silent Aim']==nil,'Endmath rejects outside pixel radius instead of clamping prediction')
filtered.Config['Silent Aim'].AntiCurve.Endmath.Radius=300;step(0.04)
local acceptedLead=filtered.Points['Silent Aim'].X
assert(math.abs(acceptedLead-16)<1e-6 and not filtered.AimTrace['Silent Aim'].FastMotionLimited,
    'Macro speed keeps the complete forecast; AntiCurve only checks its final geometry')
assert(filtered.AimTrace['Silent Aim'].MacroRestriction=='anti-curve-final-geometry')
filtered.Config['Silent Aim'].AntiCurve.Enabled=false;step(.04)
assert(math.abs(filtered.Points['Silent Aim'].X-acceptedLead)<1e-6 and filtered.AimTrace['Silent Aim'].MacroRestriction==nil,
    'AntiCurve off leaves no hidden macro restriction')
filtered.Config['Silent Aim'].AntiCurve.Enabled=true
filtered.Config['Silent Aim'].AntiCurve.Method='3d-angles';step(0.04)
assert(filtered.Points['Silent Aim']==nil,'Reject world-space mouse-to-target distance')
filtered.Config['Silent Aim'].AntiCurve.Enabled=false
filtered.Config.Whitelist.Enabled=true;filtered.WhiteMode='Friend';filtered.Whitelist={2};step(0.04)
assert(filtered.Targets['Silent Aim']==nil)
filtered.WhiteMode='Target';step(0.04);assert(filtered.Targets['Silent Aim']==enemy)
filtered:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new()

-- Remote FloorMaterial and a future landing surface do not establish present
-- Full XYZ forecasts follow measured reference trajectories for every feature.
-- Changing torso size cannot shorten a correct constant-motion forecast.
do
    local savedSize=enemyTorso.Size
    for _,auto in ipairs({false,true})do
        for _,rate in ipairs({-3,3})do
            local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
            cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false
            cfg['Y-Axis'].Enabled=true;cfg['Y-Axis'].Method='Auto';cfg.Checks.GroundShotCheck={false,false,false}
            for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
                cfg[name].Prediction.Auto=auto;cfg[name].Prediction.Value=.12
            end
            local rt=loadRuntime(cfg);rt.Network.RTT=.12;rt.Network.DataRTT=.12;rt.Network.NextSample=clock+10
            local t
            for i=0,20 do
                t=i*.02;local angle=rate*t
                moveEnemy(22*(1-math.cos(angle))/rate,30+40*t-50*t*t,-50+22*math.sin(angle)/rate)
                enemyRoot.AssemblyLinearVelocity=V.new(22*math.sin(angle),40-100*t,22*math.cos(angle))
                step(.02)
            end
            local future=t+.12
            local expected=V.new(22*(1-math.cos(rate*future))/rate,30+40*future-50*future*future,-50+22*math.sin(rate*future)/rate)
            for _,size in ipairs({V.new(2,4,1),V.new(.1,.1,.1)})do
                enemyTorso.Size=size
                for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
                    local point,trace=rt:Forecast(enemy,name,'UpperTorso')
                    assert(trace.MotionModel=='validated-3d-turn' and trace.TurnValidated)
                    assert((point-expected).Magnitude<1e-6,'XYZ trajectory forecast must match for '..name)
                    assert(trace.PartDimensions.X==size.X and trace.PartDimensions.Y==size.Y)
                end
            end
            rt:Destroy('test');clearInput()
        end
    end
    enemyTorso.Size=savedSize;enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50)
end

-- Manual values calibrate to the first valid RTT, then track changes without
-- modifying Value. Reapplying unrelated settings preserves that calibration.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do cfg[name].Prediction.Auto=false;cfg[name].Prediction.Value=.12 end
    enemyRoot.AssemblyLinearVelocity=V.new(22,10,-8)
    local rt=loadRuntime(cfg);rt.Network.RTT=.1;rt.Network.DataRTT=.1;rt.Network.NextSample=clock+10
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local _,trace=rt:Forecast(enemy,name);assert(trace.BaseLeadTime==.12 and trace.ManualReferenceRTT==.1)
    end
    rt.Network.RTT=.16;rt.Network.DataRTT=.16
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local _,trace=rt:Forecast(enemy,name)
        assert(math.abs(trace.BaseLeadTime-.18)<1e-8 and math.abs(trace.PingAdjustment-.06)<1e-8)
        assert(rt.Config[name].Prediction.Value==.12)
    end
    cfg['2d-Box']['Silent Aim'].Size.Width=9;rt:ApplyConfig(cfg)
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local _,trace=rt:Forecast(enemy,name);assert(trace.ManualReferenceRTT==.1 and math.abs(trace.BaseLeadTime-.18)<1e-8)
    end
    rt:Destroy('test');clearInput();enemyRoot.AssemblyLinearVelocity=V.new()
end

-- A torso smaller than a valid jump lead is not a reason to cap that lead.
-- The optional ground correction still uses real support geometry afterward.
do
    local size=enemyTorso.Size;enemyTorso.Size=V.new(.2,.2,.2)
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false;cfg.Resolver.Enabled=false
    cfg['Y-Axis'].Enabled=true;cfg['Y-Axis'].Method='Auto'
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do cfg[name].Prediction.Auto=false;cfg[name].Prediction.Value=.2 end
    moveEnemy(0,20,-50);enemyRoot.AssemblyLinearVelocity=V.new(10,40,-10)
    local rt=loadRuntime(cfg)
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local point=rt:Forecast(enemy,name);assert(math.abs(point.Y-28)<1e-8,'Airborne linear lead must not be capped to torso height')
    end
    groundY=0;moveEnemy(0,4,-50);enemyRoot.AssemblyLinearVelocity=V.new(10,-40,-10)
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local point,trace=rt:Forecast(enemy,name);assert(point.Y==3 and trace.GroundCorrected,'Actual support still prevents a forecast through the floor')
    end
    rt:Destroy('test');groundY=nil;clearInput();enemyTorso.Size=size;enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50)
end

-- Endmath checks the forward final geometry even at the viewport edge, instead
-- of rejecting a partially visible target solely from an on-screen boolean.
do
    local oldProject,oldMouse,oldHit,oldHandle=camera.WorldToViewportPoint,Input.GetMouseLocation,mouse.Hit,handle.Position
    camera.WorldToViewportPoint=function(self,p)
        local v=oldProject(self,p)
        return v,v.Z>0 and v.X>=0 and v.X<=self.ViewportSize.X and v.Y>=0 and v.Y<=self.ViewportSize.Y
    end
    Input.GetMouseLocation=function()return V.new(1910,540)end
    local x=(1930-960)*50/cameraFocal();moveEnemy(x,0,-50);mouse.Hit=CF.new(enemyRoot.Position);handle.Position=V.new(5,1,0)
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false;cfg['Silent Aim'].Prediction.Enabled=false
    cfg['Silent Aim'].AntiCurve.Enabled=true;cfg['Silent Aim'].AntiCurve.Method='Endmath';cfg['Silent Aim'].AntiCurve.Endmath.Radius=.0001
    local rt=loadRuntime(cfg);step(.02)
    assert(rt.Points['Silent Aim'] and rt.AimTrace['Silent Aim'].AntiCurveReference=='muzzle-to-mouse-ray')
    assert(rt.AimTrace['Silent Aim'].AntiCurveMuzzlePixels<1e-6)
    rt:Destroy('test');clearInput()
    camera.WorldToViewportPoint,Input.GetMouseLocation,mouse.Hit,handle.Position=oldProject,oldMouse,oldHit,oldHandle
    moveEnemy(0,0,-50)
end

-- Remote FloorMaterial and a future landing surface do not establish present
-- support at a jump apex. The measured vertical curve must continue in Auto.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false
    cfg['Y-Axis'].Enabled=true;cfg['Y-Axis'].Method='Auto'
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        cfg[feature].Prediction.Auto=false;cfg[feature].Prediction.Value=.1
    end
    cfg.Checks.GroundShotCheck={false,false,false}
    local savedSize,savedWalk=enemyTorso.Size,enemyHum.WalkSpeed
    enemyTorso.Size=V.new(2,4,1);enemyHum.WalkSpeed=22
    moveEnemy(0,30,-50);enemyRoot.AssemblyLinearVelocity=V.new(22,0,0)
    enemyHum.FloorMaterial=Enum.Material.Plastic
    local rt=loadRuntime(cfg);step(.02)
    local record=rt.Records[enemy]
    local function apexHistory(phase)
        record.history={};record.sampledVelocity=nil
        for i=0,7 do
            local t=(i-7)*.02-(phase or 0)
            Core.sample(record.history,V.new(22*t,30-100*t*t,-50),clock+t,V.new(22,-200*t,0))
        end
    end
    for _,phase in ipairs({0,.004,.008,.0125})do
        apexHistory(phase)
        for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
            local point,evidence=rt:Forecast(enemy,feature,'UpperTorso')
            assert(math.abs(point.Y-29)<1e-6 and not evidence.GroundedByGeometry,
                'Stale FloorMaterial or sampling phase cannot erase the measured apex forecast for '..feature)
            assert(math.abs(evidence.VerticalModelSampleAge-phase)<1e-7 and evidence.VerticalConfidence>.999)
        end
    end
    local savedRaycast=World.Raycast
    World.Raycast=function(self,origin,direction,params)
        if params.RespectCanCollide then
            local floor=origin.X>1 and 27 or 0
            if origin.Y>=floor and origin.Y+direction.Y<=floor then
                return {Instance=World,Position=V.new(origin.X,floor,origin.Z),Normal=V.new(0,1,0)}
            end
            return nil
        end
        return savedRaycast(self,origin,direction,params)
    end
    apexHistory()
    local point,evidence=rt:Forecast(enemy,'Silent Aim','UpperTorso')
    assert(math.abs(point.Y-29)<1e-6 and not evidence.GroundedByGeometry,
        'A future raised landing surface cannot classify the current apex as grounded')
    assert(evidence.GroundContact.CurrentProbed and evidence.GroundContact.PredictedGroundY==27)
    rt.Config['Y-Axis'].Method='Custom';rt.Config['Y-Axis'].Offset=2
    record.history={};record.sampledVelocity=nil;enemyRoot.AssemblyLinearVelocity=V.new(22,10,0)
    point=rt:Forecast(enemy,'Silent Aim','UpperTorso')
    assert(math.abs(point.Y-32)<1e-6,'Custom retains its separate positive-lead multiplier')
    rt.Config['Y-Axis'].Method='Auto';rt.Config['Y-Axis'].Offset=5
    enemyRoot.AssemblyLinearVelocity=V.new(22,0,0);apexHistory(.0125)
    point=rt:Forecast(enemy,'Silent Aim','UpperTorso')
    assert(math.abs(point.Y-29)<1e-6,'Auto still ignores Custom Offset')
    rt:Destroy('test');World.Raycast=savedRaycast;enemyTorso.Size=savedSize;enemyHum.WalkSpeed=savedWalk
    enemyRoot.AssemblyLinearVelocity=V.new();enemyHum.FloorMaterial=Enum.Material.Plastic
    moveEnemy(0,0,-50);clearInput()
end

-- Current contact does not mean zero world-Y motion on a continuous ramp.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false
    cfg['Y-Axis'].Enabled=true;cfg['Y-Axis'].Method='Auto'
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        cfg[feature].Prediction.Auto=false;cfg[feature].Prediction.Value=.1
    end
    local savedRaycast,savedWalk,savedSize=World.Raycast,enemyHum.WalkSpeed,enemyTorso.Size
    enemyHum.WalkSpeed=22;enemyTorso.Size=V.new(2,4,1)
    local sx,sz=.09,0
    World.Raycast=function(self,origin,direction,params)
        if params.RespectCanCollide then
            local floor=sx*origin.X+sz*(origin.Z+50)
            if origin.Y>=floor and origin.Y+direction.Y<=floor then
                return {Instance=World,Position=V.new(origin.X,floor,origin.Z),Normal=V.new(-sx,1,-sz).Unit}
            end
            return nil
        end
        return savedRaycast(self,origin,direction,params)
    end
    for _,case in ipairs({{22,0,.09,0},{-22,0,.09,0},{0,22,0,.09},{0,-22,0,.09}})do
        sx,sz=case[3],case[4]
        moveEnemy(0,3,-50);enemyRoot.AssemblyLinearVelocity=V.new(case[1],sx*case[1]+sz*case[2],case[2])
        local rt=loadRuntime(cfg);step(.02)
        for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
            local point,evidence=rt:Forecast(enemy,feature,'UpperTorso')
            local expected=3+(sx*case[1]+sz*case[2])*.1
            assert(math.abs(point.Y-expected)<1e-6 and evidence.GroundedByGeometry,
                'Auto must follow continuous support in world XYZ for '..feature)
            assert(evidence.AccelerationMode=='support-follow')
        end
        rt:Destroy('test')
    end
    -- Equal normals on different horizontal heights are not a continuous plane.
    World.Raycast=function(self,origin,direction,params)
        if params.RespectCanCollide then
            local floor=origin.X>1 and 2 or 0
            if origin.Y+direction.Y<=floor then
                return {Instance=World,Position=V.new(origin.X,floor,origin.Z),Normal=V.new(0,1,0)}
            end
            return nil
        end
        return savedRaycast(self,origin,direction,params)
    end
    moveEnemy(0,3,-50);enemyRoot.AssemblyLinearVelocity=V.new(22,1,0)
    local rt=loadRuntime(cfg);step(.02)
    local point,evidence=rt:Forecast(enemy,'Silent Aim','UpperTorso')
    assert(point.Y==3 and evidence.GroundedByGeometry and evidence.GroundContact.SupportLead==nil,
        'A raised step cannot become an automatic upward offset')
    rt:Destroy('test')
    World.Raycast=savedRaycast;enemyHum.WalkSpeed=savedWalk;enemyTorso.Size=savedSize
    enemyRoot.AssemblyLinearVelocity=V.new();moveEnemy(0,0,-50);clearInput()
end

-- Raw-derived acceleration cannot be attached to a different vertical velocity
-- that TrueVelocity recovered from coherent position history.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false
    cfg['Y-Axis'].Enabled=true;cfg['Y-Axis'].Method='Auto'
    cfg.Checks.GroundShotCheck={false,false,false}
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        cfg[feature].Prediction.Auto=false;cfg[feature].Prediction.Value=.1
    end
    local savedSize=enemyTorso.Size;enemyTorso.Size=V.new(2,4,1)
    moveEnemy(0,30,-50);enemyRoot.AssemblyLinearVelocity=V.new(0,-7.2,0)
    local rt=loadRuntime(cfg);step(.02)
    local record=rt.Records[enemy];record.history={};record.sampledVelocity=nil
    for i=0,7 do
        local t=(i-7)*.02
        Core.sample(record.history,V.new(0,30+10*t,-50),clock+t,V.new(0,-10+20*(t+.14),0))
    end
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local point,evidence=rt:Forecast(enemy,feature,'UpperTorso')
        assert(evidence.VelocitySource=='true-velocity' and math.abs(evidence.ResolvedVelocity.Y-10)<1e-6)
        assert(math.abs(point.Y-31)<1e-6 and evidence.AppliedVerticalAcceleration==0,
            'A resolved constant climb cannot inherit the rejected raw acceleration for '..feature)
    end
    rt:Destroy('test');enemyTorso.Size=savedSize;enemyRoot.AssemblyLinearVelocity=V.new()
    moveEnemy(0,0,-50);clearInput()
end

-- Circle gating uses the final predicted point, including leads entering the circle.
do
    local cfg=Core.copy(Defaults)
    cfg['Silent Aim'].Target.Closest.Enabled=false

    cfg['Silent Aim'].Prediction.Auto=false;cfg['Silent Aim'].Prediction.Value=.1
    cfg['Silent Aim'].Fov.Method='2d-Circle';cfg['Silent Aim'].Fov['2d-Circle'].Size=10
    moveEnemy(2,0,-50);enemyRoot.AssemblyLinearVelocity=V.new(-20,0,0)
    local rt=loadRuntime(cfg);step(.04)
    assert(rt.Targets['Silent Aim']==enemy,'A predicted point entering FOV remains eligible')
    enemyRoot.AssemblyLinearVelocity=V.new(20,0,0);step(.04)
    assert(rt.Targets['Silent Aim']==nil,'A predicted point outside FOV is rejected')
    rt:Destroy('test');moveEnemy(0,0,-50);enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Activation reads a live point, not an old history point needing extra age.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false
    cfg['Silent Aim'].Prediction.Auto=true
    enemyRoot.AssemblyLinearVelocity=V.new(22,0,0)
    local rt=loadRuntime(cfg);rt.Network.RTT=.06;rt.Network.DataRTT=.06;rt.Network.NextSample=clock+10;step(.04)
    local baseline=rt.AimTrace['Silent Aim'].LeadTime
    clock=clock+.0125;tool.Activated:Fire()
    assert(rt.AimTrace['Silent Aim'].HistoryAge>.0124)
    assert(math.abs(rt.AimTrace['Silent Aim'].LeadTime-baseline)<1e-8,'Fresh activation points cannot add history sampler age to Auto again')
    rt:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Gun ranges use physical distance and only override Silent box dimensions.
do
    local cfg=Core.copy(Defaults);cfg['Gun Specifications'].Enabled=true
    cfg['Gun Specifications'].Ranges={Close=15,Medium=30,Far=90}
    cfg['Gun Specifications'].Revolver={Close={BoxSize={Height=5.1,Width=5.1}},
        Medium={BoxSize={Height=5.5,Width=5.5}},Far={BoxSize={Height=4.5,Width=5}}}
    cfg['2d-Box']['Silent Aim'].Size={Height=8,Width=7}
    cfg['2d-Box']['Silent Aim'].Visible=true
    cfg['2d-Box']['Aim Assist'].Visible=true
    local rt=loadRuntime(cfg)
    for _, case in ipairs({{10,'Close',5.1,5.1},{15,'Close',5.1,5.1},{15.01,'Medium',5.5,5.5},
        {20,'Medium',5.5,5.5},{30,'Medium',5.5,5.5},{30.01,'Far',5,4.5},{90,'Far',5,4.5},
        {90.01,false,7,8},{200,false,7,8},{30,'Medium',5.5,5.5},{15,'Close',5.1,5.1}}) do
        moveEnemy(0,0,-case[1]);step(.04)
        local info=rt:Diagnose().Boxes[tostring(enemy.UserId)]
        assert(info['Silent Aim'].Range==(case[2] or nil) and info['Silent Aim'].Width==case[3] and info['Silent Aim'].Height==case[4])
        assert(info['Silent Aim'].Units=='character-relative dimensions')
        local found=false
        for _,d in ipairs(drawingObjects)do
            if not d.removed and d.Visible and d.Kind=='Square' and math.abs(d.Size.X-case[3]*cameraFocal()/case[1])<1e-6 and math.abs(d.Size.Y-case[4]*cameraFocal()/case[1])<1e-6 then found=true end
        end
        assert(found,'ESP must display exactly the same pixel size as the selection profile')
        assert(info['Aim Assist'].Width==5 and info['Aim Assist'].Height==4.3,'Weapon box must not override Assist')
    end
    local name=tool.Name
    for _,weapon in ipairs({'Double-Barrel SG','TacticalShotgun','Shotgun','Usp'})do
        tool.Name='['..weapon..']';moveEnemy(0,0,-10);step(.02)
        local box=rt:Diagnose().Boxes[tostring(enemy.UserId)]['Silent Aim']
        local expected=rt.Config['Gun Specifications'][weapon].Close.BoxSize
        assert(box.Weapon==weapon and box.Width==expected.Width and box.Height==expected.Height)
    end
    tool.Name='[Unknown]';step(.02)
    assert(rt:Diagnose().Boxes[tostring(enemy.UserId)]['Silent Aim'].Width==7,'Unlisted weapons use the base dimensions')
    tool.Name=name;rt.Config['Gun Specifications'].Enabled=false
    local fov,viewport=camera.FieldOfView,camera.ViewportSize
    for _,case in ipairs({{10,45,720},{50,70,1080},{200,100,1440},{15,90,2160}})do
        camera.FieldOfView=case[2];camera.ViewportSize=V.new(viewport.X,case[3])
        moveEnemy(0,0,-case[1]);step(.02)
        local box=rt:Diagnose().Boxes[tostring(enemy.UserId)]['Silent Aim']
        assert(box.Width==7 and box.Height==8 and box.Range==nil,
            'Distance and camera zoom cannot change the configured physical dimensions')
        local bodyLeft=camera:WorldToViewportPoint(enemyRoot.Position-V.new(1,0,0))
        local bodyRight=camera:WorldToViewportPoint(enemyRoot.Position+V.new(1,0,0))
        local bodyWidth=bodyRight.X-bodyLeft.X
        assert(math.abs(box.PixelWidth/bodyWidth-3.5)<1e-6,
            'Box coverage relative to the character must stay constant across distance, zoom and resolution')
        assert(math.abs(box.PixelHeight*case[1]/cameraFocal()-8)<1e-6)
        local drawn=false
        for _,d in ipairs(drawingObjects)do
            if not d.removed and d.Visible and d.Kind=='Square' and d.Thickness==1 and math.abs(d.Size.X-box.PixelWidth)<1e-6 and math.abs(d.Size.Y-box.PixelHeight)<1e-6 then drawn=true end
        end
        assert(drawn,'Rendered box must use the same projection as selection')
    end
    camera.FieldOfView,camera.ViewportSize=fov,viewport
    rt:Destroy('test');moveEnemy(0,0,-50)
end

-- Auto continues to the next candidate after final prediction/filter rejection.
do
    local rival=obj('Player','NearerTriggerCandidate',Players);rival.UserId=78;rival.DisplayName='Nearer'
    local rivalChar=character(rival,-50)
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false
    cfg['Silent Aim'].Method='Target';cfg['Silent Aim'].Ignore=true
    cfg.Triggerbot.TargetOnly=true;cfg.Triggerbot.Fov.Enabled=true;cfg.Triggerbot.Prediction.Enabled=false
    local wasEnabled=tool.Enabled;tool.Enabled=false
    moveEnemy(1,0,-50)
    local rt=loadRuntime(cfg);rt.Locks['Silent Aim']=enemy.UserId;key('MouseButton2',true);step(.04)
    assert(rt.Targets['Silent Aim']==enemy and rt.Targets.Triggerbot==enemy,'TargetOnly filters candidates before choosing the nearest player')
    key('MouseButton2',false);rt:Destroy('test');rivalChar:Destroy();rival:Destroy();tool.Enabled=wasEnabled;moveEnemy(0,0,-50);clearInput()
end

-- Auto continues to the next candidate after final prediction/filter rejection.
do
    local second=obj('Player','SecondCandidate',Players);second.UserId=77;second.DisplayName='Second'
    local secondChar,secondRoot,secondHum,secondTorso=character(second,-50)
    secondRoot.Position=V.new(1,0,-50);secondRoot.CFrame=CF.new(secondRoot.Position)
    secondTorso.Position=secondRoot.Position;secondTorso.CFrame=CF.new(secondRoot.Position)
    local cfg=Core.copy(Defaults)
    cfg['Silent Aim'].Target.Closest.Enabled=false
    cfg['Silent Aim'].Prediction.Auto=false

    cfg['Silent Aim'].AntiCurve.Enabled=true
    cfg['Silent Aim'].AntiCurve.Method='Endmath'
    cfg['Silent Aim'].AntiCurve.Endmath.Radius=50
    enemyRoot.AssemblyLinearVelocity=V.new(100,0,0)
    local rt=loadRuntime(cfg);step(.04)
    assert(rt.Targets['Silent Aim']==second,'Auto must try the next candidate after a final filter rejects the nearest')
    rt.Config['Silent Aim'].Method='Target';rt.Locks['Silent Aim']=enemy.UserId;step(.04)
    assert(rt.Targets['Silent Aim']==nil,'Explicit target lock must not silently switch players')
    rt:Destroy('test');secondChar:Destroy();second:Destroy();enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Expired ping estimates cannot supply a stale forecast before the render-side
-- refresh runs. The same target/weapon's unexpired half-second cache is retained.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    enemyRoot.AssemblyLinearVelocity=V.new(22,0,0)
    local rt=loadRuntime(cfg);rt.Network.RTT=.2;rt.Network.DataRTT=.2
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        rt.AutoPrediction.Features[feature]={Target=enemy.UserId,ToolEpoch=rt.ToolEpoch,
            RTT=.06,DataRTT=.06,NextSample=clock+.1}
        local _,trace=rt:Forecast(enemy,feature);assert(math.abs(trace.BaseLeadTime-.06)<1e-6)
    end
    clock=clock+.11
    for _,feature in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        local _,trace=rt:Forecast(enemy,feature)
        assert(math.abs(trace.BaseLeadTime-.2)<1e-6,'Expired estimates must use current ping for '..feature)
    end
    rt:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new()
end

-- ESP does not retain an occlusion result after the camera/target moved to a
-- materially different ray, even within the normal 80ms static-cache interval.
do
    local cfg=Core.copy(Defaults);cfg['Silent Aim'].Enabled=false;cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg.ESP.VisibleCheck=true
    local cast,view=World.Raycast,camera.CFrame
    World.Raycast=function(self,origin,direction,params)
        if origin.X>1 or enemyRoot.Position.X>.5 then return {Instance=World,Position=V.new(0,0,-5)} end
    end
    local rt=loadRuntime(cfg);step(.02);assert(anyBoxVisible())
    camera.CFrame=CF.new(5,0,0);step(.005)
    assert(not anyBoxVisible(),'Camera movement invalidates stale visible ESP before the cache expires')
    camera.CFrame=view;step(.005);assert(anyBoxVisible())
    moveEnemy(.6,0,-50);step(.005)
    assert(not anyBoxVisible(),'Target movement invalidates stale visible ESP before the cache expires')
    rt:Destroy('test');World.Raycast=cast;camera.CFrame=view;moveEnemy(0,0,-50)
end

-- Live-observed adapter names, fresh cursor precedence, and per-feature prediction.
do
    local cfg=Core.copy(Defaults);cfg.Triggerbot.Enabled=false;cfg['Aim Assist'].Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Target.Closest.Enabled=false
    local rt=loadRuntime(cfg);rt.Network.RTT=.2;rt.Network.DataRTT=.2;rt.Network.NextSample=clock+10
    enemyRoot.AssemblyLinearVelocity=V.new(22,0,0);step(.04)
    local context=rt.AutoPrediction.Features['Silent Aim'];assert(context and context.Target==enemy.UserId and context.Ballistics=='hitscan' and context.TravelSeconds==0)
    assert(context.BulletSpeed==nil,'Hitscan never invents a finite projectile speed')
    local refreshes=rt.AutoPrediction.Refreshes;rt.Network.RTT=.3;rt.Network.DataRTT=.3;step(.2)
    assert(rt.AutoPrediction.Refreshes==refreshes and math.abs(rt.AimTrace['Silent Aim'].BaseLeadTime-.2)<1e-8,'Active estimates stay coherent between half-second refreshes')
    step(.31);step(.02)
    assert(rt.AutoPrediction.Refreshes==refreshes+1 and math.abs(rt.AimTrace['Silent Aim'].BaseLeadTime-.3)<1e-8,'Auto prediction adopts refreshed estimates after half a second')
    enemyRoot.AssemblyLinearVelocity=V.new();step(.02)
    assert(rt.AimTrace['Silent Aim'].HorizontalLeadTime==rt.AimTrace['Silent Aim'].LeadTime and rt.Points['Silent Aim'].X==enemyRoot.Position.X,'Stops remain immediate between estimate refreshes')
    rt.Config['Silent Aim'].Enabled=false;step(.04);assert(rt.AutoPrediction.Features['Silent Aim']==nil,'No active target means no retained target estimate')
    rt:Destroy('test');enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Live-observed adapter names, fresh cursor precedence, and per-feature prediction.
do
    ammo.Name='AMMO';ammo.Value=6
    local flare=obj('Attachment','Flare',handle);flare.WorldPosition=V.new(4,2,1)
    local checkCfg=Core.copy(Defaults)
    checkCfg['Silent Aim'].Target.Closest.Enabled=false
    checkCfg['Silent Aim'].Ignore=true


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
    rt.Config['Y-Axis'].Offset=5;step(.04)
    assert(rt.Points['Silent Aim'].Y==3,'Auto ignores Offset')
    groundY=nil;rt.Config.Checks.GroundShotCheck[1]=false
    rt.Config['Y-Axis'].Enabled=false;enemyRoot.AssemblyLinearVelocity=V.new(10,0,0)
    rt.Config['Silent Aim'].Prediction.Enabled=false;step(.04)
    assert(rt.Points['Silent Aim'].X==0,'Disabled prediction adds no lead')
    rt.Config['Silent Aim'].Prediction.Enabled=true;rt.Config['Silent Aim'].Prediction.Auto=true
    rt.Config['Silent Aim'].Prediction.Value=1
    rt.Network.RTT=.15;rt.Network.DataRTT=.2;rt.Network.NextSample=clock+10;step(.04)
    assert(math.abs(rt.Points['Silent Aim'].X-1.5)<1e-6,'Auto uses measured RTT and bounded horizontal speed scaling, not Value or summed ping')
    rt.Config['Silent Aim'].Prediction.Value=0;step(.04)
    assert(math.abs(rt.Points['Silent Aim'].X-1.5)<1e-6)
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
    assert(rt.ForcedPoint==rt.Points['Silent Aim'] and rt.LastShotRoute.AimFeature=='Silent Aim',
        'An eligible Silent point owns redirection while Triggerbot owns the click')
    key('MouseButton2',false);step(.2);ammo.Value=0;before=shots
    key('MouseButton2',true);step(.12);assert(shots==before,'Uppercase AMMO empty prevents trigger attempts')
    key('MouseButton2',false);ammo.Value=6
    rt:Destroy('test');flare:Destroy();ammo.Name='Ammo';mouse.Target=nil;rayHit=nil;groundY=nil
    enemyHum.FloorMaterial=Enum.Material.Plastic;clearInput()
end

-- Camera Assist must aim under an off-center cursor before Silent/TB run their shape checks.
do
    local oldMouse,oldProject,oldRay=Input.GetMouseLocation,camera.WorldToViewportPoint,camera.ViewportPointToRay
    local oldLookAt,oldLerp=CF.lookAt,CM.__index.Lerp
    local savedAmmo=ammo.Value;ammo.Value=100;moveEnemy(0,0,-50)
    Input.GetMouseLocation=function()return V.new(1060,540)end
    CF.lookAt=function(origin,target,up)
        local c=CF.new(origin);c.LookVector=(target-origin).Unit
        c.RightVector=c.LookVector:Cross(up or V.new(0,1,0)).Unit
        c.UpVector=c.RightVector:Cross(c.LookVector).Unit;return c
    end
    CM.__index.Lerp=function(a,b,t)
        return CF.lookAt(a.Position,a.Position+a.LookVector*(1-t)+b.LookVector*t,
            (a.UpVector or V.new(0,1,0))*(1-t)+(b.UpVector or V.new(0,1,0))*t)
    end
    camera.WorldToViewportPoint=function(self,point)
        local relative=point-self.CFrame.Position;local z=relative:Dot(self.CFrame.LookVector)
        return V.new(960+relative:Dot(self.CFrame.RightVector)*1000/math.max(z,.001),
            540-relative:Dot(self.CFrame.UpVector)*1000/math.max(z,.001),z),z>0
    end
    camera.ViewportPointToRay=function(self,x,y)
        return {Origin=self.CFrame.Position,Direction=(self.CFrame.LookVector+self.CFrame.RightVector*((x-960)/1000)
            +self.CFrame.UpVector*(-(y-540)/1000)).Unit}
    end
    local function run(legacy, characterOnly)
        camera.CFrame=CF.lookAt(V.new(),V.new(0,0,-1))
        if legacy then
            camera.CFrame=CF.lookAt(camera.CFrame.Position,enemyTorso.Position)
            local p=camera:WorldToViewportPoint(enemyTorso.Position)
            assert(not Core.fov(p.X-1060,p.Y-540,'2d-Circle',0,0,2),
                'The old camera-center transform leaves the body outside cursor-based checks')
            return
        end
        local cfg=Core.copy(Defaults);cfg['Aim Assist'].Activation.Holding=false;cfg['Aim Assist'].Smoothness=1
        cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=not characterOnly
        for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
            cfg[name].Prediction.Enabled=false;cfg[name].Fov.Method='2d-Circle'
            cfg[name].Fov['2d-Circle'].Size=name=='Aim Assist' and 150 or 2
        end
        local rt=loadRuntime(cfg);step(.02)
        local p=camera:WorldToViewportPoint(enemyTorso.Position)
        assert(math.abs(p.X-1060)<1e-6 and math.abs(p.Y-540)<1e-6,'Assist preserves the actual cursor projection')
        assert(rt.Targets['Silent Aim']==enemy and rt.Targets.Triggerbot==enemy and rt.Stats.TriggerAttempts==1,
            'Fresh post-Assist geometry lets Silent and TB accept the target on the same frame')
        rt:Destroy('test');clearInput()
    end
    run(true);run(false,false);run(false,true)
    Input.GetMouseLocation=oldMouse;camera.WorldToViewportPoint=oldProject;camera.ViewportPointToRay=oldRay
    CF.lookAt=oldLookAt;CM.__index.Lerp=oldLerp
    camera.CFrame=CF.new();ammo.Value=savedAmmo
end

-- A full bundle's default table cannot overwrite an explicitly supplied edited table.
do
    local edited=Core.copy(Defaults)
    edited.Misc.Panic.Enabled=false
    edited['Aim Assist'].Activation.Keybind={'Q','MouseButton2','Mouse'}
    edited.Triggerbot.Activation.Keybind={'Q','MouseButton2','Keyboard'}
    edited.ESP.Toggle.Keybind={'V','MouseButton2','Keyboard'}
    edited['Silent Aim'].Prediction.Auto=false;edited['Silent Aim'].Prediction.Value=.121
    for _,file in ipairs({'neoperro-full.lua','neoperro-runtime.lua'})do
        env.neoperro=Core.copy(Defaults)
        local rt=assert(loadfile(file,'t',env))(edited)
        assert(Core.equal(rt.Config,edited),'Explicit configuration wins in '..file)
        rt:Destroy('test')
    end
    clearInput()
end

-- User-supplied current place IDs all start the same Looten-derived remote path.
-- Generic track names resolve through the game's animation catalog; all aim paths share pose geometry.
do
    local savedAmmo,savedSize,savedFrame=ammo.Value,enemyTorso.Size,enemyTorso.CFrame
    ammo.Value=100;moveEnemy(0,0,-50)
    local folder=obj('Folder','Animations',storage)
    local crouch=obj('Animation','crouch',folder);crouch.AnimationId='rbxassetid://101'
    local dances=obj('Folder','dances',folder)
    local lay=obj('Animation','laying',dances);lay.AnimationId='rbxassetid://102'
    local dance=obj('Animation','the rossy',dances);dance.AnimationId='rbxassetid://103'
    local animator=obj('Animator','Animator',enemyHum)
    local generic=obj('Animation','Animation');generic.AnimationId=crouch.AnimationId
    local track={IsPlaying=true,WeightCurrent=1,Name='Animation',Animation=generic}
    animator.GetPlayingAnimationTracks=function()return {track}end
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Activation.Holding=false
    cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=true
    cfg['Silent Aim'].AntiCurve.Enabled=true;cfg['Silent Aim'].AntiCurve['3d-angles'].Max=math.huge
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do cfg[name].Prediction.Enabled=false end
    cfg['Silent Aim'].Target.Closest.Enabled=false;cfg['Aim Assist'].Target.Closest.Enabled=false
    local rt=loadRuntime(cfg);step(.04)
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        assert(rt.AimTrace[name].Posture=='Crouched' and rt.AimTrace[name].PostureSource=='game-animation')
    end
    local record=rt.Records[enemy]
    record.pointState={['Silent Aim']={part=enemyTorso,point=V.new(),time=clock}}
    generic.AnimationId=lay.AnimationId
    enemyTorso.Size=V.new(4,2,1)
    enemyTorso.CFrame.RightVector=V.new(0,1,0);enemyTorso.CFrame.UpVector=V.new(1,0,0);enemyTorso.CFrame.LookVector=V.new(0,0,1)
    step(.25)
    for _,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
        assert(rt.AimTrace[name].Posture=='Prone' and rt.AimTrace[name].PartWorldHeight==4,'Rotated body height is measured in world Y for '..name)
    end
    assert(record.pointState==nil and rt.PostureStats.Changes>=1,'Posture transitions discard old point smoothing')
    generic.AnimationId=dance.AnimationId;step(.25)
    assert(rt.AimTrace['Silent Aim'].Posture=='Emote' and rt.PostureStats.Changes>=2)
    rt:Destroy('test');folder:Destroy();animator:Destroy();generic:Destroy()
    enemyTorso.Size,enemyTorso.CFrame=savedSize,savedFrame;ammo.Value=savedAmmo;clearInput()
end

-- Discard out-of-box players before searching their body parts. Hidden drawings
-- have no repeated property writes after the visibility transition.
do
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Triggerbot.Enabled=false
    cfg['Silent Aim'].Ignore=false;cfg['Silent Aim'].Fov.Method='2d-Box'
    cfg['Silent Aim'].Target.Closest.Enabled=true;cfg['Gun Specifications'].Enabled=false
    cfg.ESP.Enabled=false
    moveEnemy(1000,0,-50)
    local rt=loadRuntime(cfg)
    local project=camera.WorldToViewportPoint
    local projections=0
    camera.WorldToViewportPoint=function(self,p)projections=projections+1;return project(self,p)end
    local population=0;for _ in pairs(rt.Records)do population=population+1 end
    for _=1,8 do clock=clock+1/240;for _,callback in pairs(renders)do callback(1/240)end end
    assert(not rt.Targets['Silent Aim'] and projections<=population*8+2,
        'Out-of-box population must not require per-limb projections')
    assert(rt.Performance.BoxPrefilterRejects>=8)
    camera.WorldToViewportPoint=project
    moveEnemy(0,0,-50);rt.Config.ESP.Enabled=true;step(.04)
    rt.Config['Silent Aim'].Enabled=false;rt.Toggles.ESP=false;step(.04)
    local writes=0
    for visual in pairs(rt.Visuals)do
        local original=visual.Set
        visual.Set=function(self,p)writes=writes+1;return original(self,p)end
    end
    for _=1,8 do clock=clock+1/240;for _,callback in pairs(renders)do callback(1/240)end end
    assert(writes==0,'Hidden ESP/circles must not be rewritten each render frame')
    rt.Toggles.ESP=true;step(.04);assert(anyBoxVisible(),'ESP must restore immediately after the hidden fast path')
    rt:Destroy('test');clearInput()
end

-- A rejected unused TB prediction cannot prevent a shot that will use the
-- eligible Silent point. Actual-character and independent KO checks still apply.
do
    local savedAmmo,cast=ammo.Value,World.Raycast;ammo.Value=100
    enemyRoot.AssemblyLinearVelocity=V.new(10,0,0);moveEnemy(0,0,-50)
    World.Raycast=function(self,origin,direction,params)
        if direction.Magnitude<1000 and direction.X>.2 then return {Instance=World,Position=origin+direction*.5} end
        return cast(self,origin,direction,params)
    end
    for _,shaped in ipairs({false,true})do
        local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false;cfg.Resolver.Enabled=false
        cfg['Silent Aim'].Enabled=false;cfg['Silent Aim'].Prediction.Enabled=false
        cfg['Silent Aim'].Target.Closest.Enabled=false;cfg['Silent Aim'].Ignore=true
        cfg.Triggerbot.Activation.Enabled=false;cfg.Triggerbot.Fov.Enabled=shaped;cfg.Triggerbot.Fov.Character=1
        cfg.Triggerbot.Prediction.Auto=false;cfg.Triggerbot.Prediction.Value=.5
        rayHit={Instance=enemyTorso,Position=enemyTorso.Position}
        local rt=loadRuntime(cfg);step(.04)
        assert(rt.Stats.TriggerAttempts==0,'Fixture must reject the independent TB prediction')
        cfg['Silent Aim'].Enabled=true;rt:ApplyConfig(cfg);step(.12)
        assert(rt.Stats.TriggerAttempts==1 and rt.LastShotRoute.AimFeature=='Silent Aim'
            and rt.ForcedPoint==rt.Points['Silent Aim'],'TB must fire using its eligible Silent route')
        assert(rt.AimTrace.Triggerbot.PointSource=='silent-cooperation')
        local attempts=rt.Stats.TriggerAttempts
        if not shaped then rayHit=nil;step(.12);assert(rt.Stats.TriggerAttempts==attempts,'Silent cannot bypass actual-body selection');rayHit={Instance=enemyTorso,Position=enemyTorso.Position}end
        rt.Config.Checks.Knocked[1]=false;enemyChar.props['attr:Knocked']=true;step(.12)
        assert(rt.Stats.TriggerAttempts==attempts,'Silent cannot bypass the independent TB knocked check')
        enemyChar.props['attr:Knocked']=false;rt:Destroy('test');clearInput()
    end
    World.Raycast=cast;ammo.Value=savedAmmo;enemyRoot.AssemblyLinearVelocity=V.new();rayHit=nil
end

-- All eight feature combinations accept a shared hold key; Silent owns eligible shot redirection.
do
    local savedAmmo=ammo.Value;ammo.Value=100;moveEnemy(0,0,-50)
    enemyRoot.AssemblyLinearVelocity=V.new(10,0,0)
    for mask=0,7 do
        camera.CFrame=CF.new(0,0,0)
        local cfg=Core.copy(Defaults);cfg.Resolver.Enabled=false
        cfg.Triggerbot.Fov.Enabled=true;cfg.Triggerbot.TargetOnly=false
        for index,name in ipairs({'Silent Aim','Aim Assist','Triggerbot'})do
            cfg[name].Enabled=math.floor(mask/2^(index-1))%2==1
            cfg[name].Toggle.Enabled=false
            cfg[name].Activation.Holding=true;cfg[name].Activation.Keybind={'Q','MouseButton2','Keyboard'}
            cfg[name].Prediction.Auto=false;cfg[name].Prediction.Value=index*.1
        end
        cfg.Triggerbot.Activation.Enabled=true
        local rt=loadRuntime(cfg);key('Q',true);step(.12)
        assert((rt.Targets['Silent Aim']~=nil)==cfg['Silent Aim'].Enabled)
        assert((rt.Targets['Aim Assist']~=nil)==cfg['Aim Assist'].Enabled)
        if cfg.Triggerbot.Enabled then
            assert(rt.Stats.TriggerAttempts==1 and rt.FiringSource=='Triggerbot')
            if cfg['Silent Aim'].Enabled then
                assert(rt.LastShotRoute.AimFeature=='Silent Aim' and rt.LastShot.serverPoint==rt.ForcedPoint)
                assert(rt.ForcedPoint==rt.Points['Silent Aim'],'Silent prediction owns the TB shot')
            else assert(rt.LastShotRoute.AimFeature=='Triggerbot' and rt.ForcedPoint==rt.Points.Triggerbot) end
        else assert(rt.Stats.TriggerAttempts==0) end
        key('Q',false);step(.2)
        assert(not rt.MouseOwned and not rt.Targets['Silent Aim'] and not rt.Targets['Aim Assist'],'Shared release stops each hold independently')
        rt:Destroy('test');clearInput()
    end
    enemyRoot.AssemblyLinearVelocity=V.new();ammo.Value=savedAmmo;camera.CFrame=CF.new(0,0,0)
end

-- Assignment grows beyond four; display-name text follows the live Humanoid tag.
do
    local savedAmmo=ammo.Value;ammo.Value=100;moveEnemy(0,0,-50)
    enemyRoot.AssemblyLinearVelocity=V.new(10,0,0)
    local cfg=Core.copy(Defaults);cfg['Aim Assist'].Enabled=false
    cfg.Triggerbot.Fov.Enabled=true;cfg.Triggerbot.Activation.Enabled=false
    cfg['Silent Aim'].Ignore=true;cfg['Silent Aim'].Prediction.Auto=false;cfg['Silent Aim'].Prediction.Value=.1
    cfg.Triggerbot.Prediction.Auto=false;cfg.Triggerbot.Prediction.Value=.3
    local rt=loadRuntime(cfg);step(.02)
    assert(rt.FiringSource=='Triggerbot' and rt.LastShotRoute.AimFeature=='Silent Aim')
    local attempts=rt.Stats.TriggerAttempts
    step(.02)
    assert(rt.Points.Triggerbot~=rt.Points['Silent Aim'],'Fixture requires distinct prediction settings')
    assert(rt.MouseOwned and rt.Stats.TriggerAttempts==attempts and rt.ForcedPoint==rt.Points['Silent Aim'],
        'Held TB input must keep the same eligible Silent route between activations')
    rt.Config['Silent Aim'].Enabled=false;step(.02)
    assert(rt.ForcedPoint==rt.Points.Triggerbot,'A held cycle falls back when Silent becomes ineligible')
    rt:Destroy('test');clearInput();ammo.Value=savedAmmo;enemyRoot.AssemblyLinearVelocity=V.new()
end

-- Assignment grows beyond four; display-name text follows the live Humanoid tag.
do
    local otherParent,oldOtherPosition=other.Parent,otherRoot.Position
    other.Parent=Players;otherRoot.Position=V.new(20,0,-50)
    local cfg=Core.copy(Defaults);cfg.Whitelist.Enabled=true;cfg.Whitelist.Method='Target';cfg.Whitelist.Players={101,102,103,104,105}
    cfg.Triggerbot.Enabled=false
    local rt=loadRuntime(cfg);step(.04)
    assert(#rt.Whitelist==5)
    key('R',true);key('R',false);assert(#rt.Whitelist==6 and rt.Whitelist[6]==enemy.UserId)
    step(.04);assert(rt.Targets['Silent Aim']==enemy)
    key('R',true);key('R',false);assert(#rt.Whitelist==5)
    moveEnemy(10,0,-50);otherRoot.Position=V.new(5,0,-50)
    key('R',true);key('R',false);assert(#rt.Whitelist==6)
    moveEnemy(0,0,-50);otherRoot.Position=V.new(20,0,-50);step(.04)
    assert(rt.Targets['Silent Aim']~=enemy,'Remove/add in one frame invalidates membership even when list length is unchanged')
    rt.Config.Whitelist.Enabled=false
    local oldDisplay=enemyHum.DisplayName;enemyHum.DisplayName='[WINTER] '..enemy.DisplayName;step(.04)
    local found=false
    for _,d in ipairs(drawingObjects)do if not d.removed and d.Kind=='Text' and d.Visible and d.Text==enemyHum.DisplayName then found=true end end
    assert(found,'ESP DisplayName includes the actual game tag from Humanoid.DisplayName')
    enemyHum.DisplayName=oldDisplay;rt:Destroy('test');clearInput()
    other.Parent,otherRoot.Position=otherParent,oldOtherPosition
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
