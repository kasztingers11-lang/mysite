"""Exercise the generated upload with mock grants; never contact FlowAuth or read a key."""
from pathlib import Path
import argparse
import hashlib
import json
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--release', type=Path, default=root.parent / 'releases/neoperro-1.3.24')
args = parser.parse_args()
release = args.release.resolve()
upload = (release / 'neoperro-flowauth-upload.obfuscated.lua').read_text(encoding='utf-8')
payload = (release / 'neoperro-native.obfuscated.lua').read_text(encoding='utf-8')
metadata = json.loads((release / 'BUILD.json').read_text(encoding='utf-8'))
assert hashlib.sha256(payload.encode()).hexdigest() == metadata['native_payload_sha256']
assert hashlib.sha256(upload.encode()).hexdigest() == metadata['upload_sha256']


def hash_bytes(source, algorithm):
    assert algorithm == 'sha256'
    return hashlib.sha256(source.encode('utf-8')).hexdigest()


def run_guard(source, grant, crypt_present=True, compiler_ok=True, reuse=False):
    lua = LuaRuntime()
    lua.globals().__protected_hash = hash_bytes
    lua.globals().__protected_digest = metadata['native_payload_sha256']
    run = lua.eval('''function(source, grant, cryptPresent, compilerOK, reuse)
        local hash, compilations = __protected_hash, 0
        local environment = {error=error, type=type, pcall=pcall, os=os, LRM_IsUserPremium=grant,
            neoperro={marker='expected-configuration'}}
        environment.getgenv=function()return environment end
        if reuse then
            environment.__neoperroRuntimeV1={Alive=true,Distribution='FlowAuth',ProtectedBuild=__protected_digest,
                ApplyConfig=function()return 'configuration-updated'end}
        end
        if cryptPresent then environment.crypt={hash=function(s,a) return hash(s,a) end} end
        environment.loadstring=function()
            compilations=compilations+1
            if compilerOK then return function(config)
                assert(config==environment.neoperro,'Compiled payload must receive the captured configuration')
                return 'payload-started'
            end end
            return nil,'synthetic compile rejection'
        end
        local fn=assert(load(source,'protected-guard','t',environment))
        local ok,result=pcall(fn)
        return ok,result,compilations
    end''')
    return run(source, grant, crypt_present, compiler_ok, reuse)


for invalid in [None, False, 'true', 1]:
    ok, message, compiled = run_guard(upload, invalid)
    assert not ok and 'valid key' in message and compiled == 0
tampered = upload.replace(payload, payload + ' ', 1)
assert tampered != upload
ok, message, compiled = run_guard(tampered, True)
assert not ok and 'integrity check failed' in message and compiled == 0
ok, message, compiled = run_guard(upload, True, crypt_present=False)
assert not ok and 'SHA-256' in message and compiled == 0
ok, message, compiled = run_guard(upload, True, compiler_ok=False)
assert not ok and 'cannot compile' in message and compiled == 1
ok, message, compiled = run_guard(upload, True)
assert ok and message == 'payload-started' and compiled == 1
ok, message, compiled = run_guard(upload, True, reuse=True)
assert ok and message == 'configuration-updated' and compiled == 0
ok, message, compiled = run_guard(upload, False, reuse=True)
assert not ok and 'valid key' in message and compiled == 0
ok, message, compiled = run_guard(tampered, True, reuse=True)
assert not ok and 'integrity check failed' in message and compiled == 0
print('Protected entry: 4 denied mock grants, changed payload, missing hash, compile failure and valid integrity paths pass')

lua = LuaRuntime()
lua.globals().__protected_hash = hash_bytes
lua.globals().__protected_path = str(release / 'neoperro-flowauth-upload.obfuscated.lua').replace('\\', '/')
test = (root / 'tests/runtime.spec.lua').read_text(encoding='utf-8')
old = """local function loadRuntime(config, file)
    env.neoperro=Core.copy(config or Defaults)
    return assert(loadfile(file or 'neoperro-src/runtime.lua','t',env))()
end"""
new = """local protectedHash,protectedPath=__protected_hash,__protected_path
env.crypt={hash=function(s,a)return protectedHash(s,a)end}
env.LRM_IsUserPremium=true -- Local synthetic fixture; not a FlowAuth authorization result.
env.loadstring=function(source,name)return load(source,name,'t',env)end
local protectedLoads=0
local function loadRuntime(config, file)
    env.neoperro=Core.copy(config or Defaults)
    protectedLoads=protectedLoads+1
    if protectedLoads>1 then
        file=protectedPath
        -- This suite intentionally exercises full replacement; entry reuse is tested separately.
        if env.__neoperroRuntimeV1 then env.__neoperroRuntimeV1.ProtectedBuild=nil end
    end
    return assert(loadfile(file or 'neoperro-src/runtime.lua','t',env))()
end"""
assert test.count(old) == 1
lua.execute(test.replace(old, new))
print('Entire runtime suite passes against the protected upload after the initial mock intro fixture')

starter = (root / 'neoperro-flowauth.lua').read_text(encoding='utf-8')
assert starter.startswith('script_key = "FLOW-REPLACE-WITH-YOUR-KEY";')
assert 'raw.githubusercontent.com' not in starter
assert '56265b6f33860b070090db29d343e59a.lua' in starter and 'program(script_key)' in starter
LuaRuntime().eval('function(source)return assert(load(source))end')(starter)
lua = LuaRuntime()
lua.execute('function getgenv()return _G end')
lua.execute((root / 'neoperro-config.lua').read_text(encoding='utf-8'))
baseline = lua.globals().neoperro
table_source=starter.split('\n-- Execution starts here.', 1)[0]
lua.execute(table_source)
equal = lua.eval("dofile('neoperro-src/core.lua').equal")
assert equal(baseline, lua.globals().neoperro), 'Explanations must not change a single configuration value'
print('FlowAuth starter syntax/order/placeholder/public loader checks pass; provider authentication was not tested')

# Run the actual generated starter against a network/compiler stub, never FlowAuth.
tail=starter.split('-- Execution starts here.',1)[1]
lua.execute('''
__downloads=0;__applies=0;__authCalls=0
game={HttpGet=function(self,url)
    __downloads=__downloads+1
    return '__authCalls=__authCalls+1;return ...'
end}
loadstring=load
__neoperroRuntimeV1={Alive=true,Version='1.3.24',Distribution='FlowAuth',LastConfigMs=0,
    ApplyConfig=function(self,config)__applies=__applies+1 end}
''')
lua.execute(starter)
assert lua.globals().__downloads == 0 and lua.globals().__applies == 1
assert lua.globals().script_key is None, 'Fast config path must not retain the unused key global'
lua.globals().__neoperroRuntimeV1.Version='older'
lua.execute(starter)
assert lua.globals().__downloads == 1 and lua.globals().__authCalls == 1
lua.globals().__neoperroRuntimeV1.Alive=False
lua.execute(starter)
assert lua.globals().__downloads == 2 and lua.globals().__authCalls == 2
lua.globals().__neoperroRuntimeV1.Alive=True
lua.globals().__neoperroRuntimeV1.Version='1.3.24'
lua.globals().__neoperroRuntimeV1.Distribution='Development'
lua.execute(starter)
assert lua.globals().__downloads == 3 and lua.globals().__authCalls == 3
lua.globals().__neoperroRuntimeV1.Distribution='FlowAuth'
lua.execute("__neoperroRuntimeV1.ApplyConfig=function()error('invalid configuration')end")
try:
    lua.execute(starter)
except Exception:
    pass
else:
    raise AssertionError('A configuration error must be reported')
assert lua.globals().__downloads == 3, 'A bad table must not trigger another provider session'
print('Generated starter: same-build config performs zero HTTP/auth calls; old/stopped builds authenticate normally')
