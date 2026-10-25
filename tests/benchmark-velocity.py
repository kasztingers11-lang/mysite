"""Synthetic Lua position-fit benchmark; not a Roblox FPS measurement."""
import json
from pathlib import Path
from lupa.lua54 import LuaRuntime
lua = LuaRuntime()
lua.globals().core_source = Path('neoperro-src/core.lua').read_text()
result = lua.execute(r"""
local Core=assert(load(core_source))()
local count=0
local V,mt={},{}
function V.new(x,y,z)count=count+1;return setmetatable({X=x,Y=y,Z=z},mt)end
mt.__add=function(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
mt.__sub=function(a,b)return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
mt.__mul=function(a,b)return V.new(a.X*b,a.Y*b,a.Z*b)end
mt.__div=function(a,b)return V.new(a.X/b,a.Y/b,a.Z/b)end
mt.__index=function(a,k)if k=='Magnitude'then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
local zero=V.new(0,0,0)
local h={}
for i=1,8 do h[i]={t=i/60,p=V.new(i*.2,i*.1,-i*.3)}end
local function prior(history,fallback,zero)
 local t,p=0,zero
 for _,v in ipairs(history)do t=t+v.t;p=p+v.p end
 t,p=t/#history,p/#history
 local n,d=zero,0
 for _,v in ipairs(history)do local dt=v.t-t;n=n+(v.p-p)*dt;d=d+dt*dt end
 return Core.limit(n/d,180)
end
local function bench(fn)
 local best=math.huge
 local allocations
 for run=1,3 do
  collectgarbage('collect');count=0
  local start=os.clock()
  for i=1,50000 do fn(h,zero,zero,V.new)end
  best=math.min(best,os.clock()-start);allocations=count/50000
 end
 return best*1000,allocations
end
local old,oldAlloc=bench(prior)
local current,currentAlloc=bench(Core.velocity)
return {iterations=50000,prior_ms=old,current_ms=current,prior_vectors_per_fit=oldAlloc,current_vectors_per_fit=currentAlloc}
""")
print(json.dumps(dict(result), indent=2))
