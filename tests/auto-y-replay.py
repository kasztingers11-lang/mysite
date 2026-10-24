from pathlib import Path
import argparse
import json
import subprocess
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description='Compare Auto Y against an analytical ballistic reference; no Roblox or FlowAuth calls.')
parser.add_argument('--baseline-ref', required=True, help='Git revision to compare; e.g. the published 1.3.15 commit.')
parser.add_argument('--output', type=Path, help='Optional JSON report path.')
args = parser.parse_args()
lua = LuaRuntime()
run = lua.eval('''function(Core)
    local V,MT={},{}
    function V.new(x,y,z)return setmetatable({X=x,Y=y,Z=z},MT)end
    MT.__add=function(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
    MT.__sub=function(a,b)return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
    MT.__mul=function(a,b)return V.new(a.X*b,a.Y*b,a.Z*b)end
    MT.__div=function(a,b)return V.new(a.X/b,a.Y/b,a.Z/b)end
    MT.__index=function(v,k)if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end end
    local rows={}
    for _,fps in ipairs({30,60,144,240})do
        local count,total,worst=0,0,0
        for _,g in ipairs({100,196.2,300})do
            local history,elapsed={},0
            for frame=0,math.floor(fps*.45)do
                local t=frame/fps
                local raw=V.new(10,60-g*t,-10)
                elapsed=elapsed+1/fps
                if elapsed>=1/60 then
                    elapsed=elapsed%(1/60)
                    Core.sample(history,V.new(10*t,30+60*t-.5*g*t*t,-10*t),t,raw)
                end
                if t>=.2 then
                    local model=Core.motion(history,raw,t)
                    for _,horizon in ipairs({.05,.1,.2,.35})do
                        local actual=Core.verticalLead(raw.Y,raw.Y,horizon,4,false,model)
                        local expected=math.max(-4,math.min(8,raw.Y*horizon-.5*g*horizon*horizon))
                        local error=math.abs(actual-expected)
                        count,total,worst=count+1,total+error,math.max(worst,error)
                    end
                end
            end
        end
        rows[#rows+1]={FPS=fps,Cases=count,MeanErrorStuds=total/count,MaxErrorStuds=worst}
    end
    return rows
end''')

def measure(source):
    rows = run(lua.execute(source))
    return [dict(row.items()) for _, row in rows.items()]

prior = subprocess.check_output(['git', '-C', str(root), 'show', args.baseline_ref + ':neoperro-src/core.lua'], text=True)
before = measure(prior)
after = measure((root/'neoperro-src/core.lua').read_text(encoding='utf-8'))
assert all(row['MaxErrorStuds'] < 1e-7 for row in after)
assert any(row['MaxErrorStuds'] > .2 for row in before)
report = {
    'description': 'Idealized ballistic velocity/position replay, separately paced history and render reads; no Roblox execution.',
    'baseline_ref': args.baseline_ref,
    'gravity_cases': [100,196.2,300],
    'forecast_horizons_seconds': [.05,.1,.2,.35],
    'reference': 'Analytic quadratic displacement, clamped to the same existing part-height bounds.',
    'before': before, 'after': after,
    'limits': 'No remote replication, noisy trajectory, server damage, hit-rate or physical FPS proof.',
}
if args.output:
    args.output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
